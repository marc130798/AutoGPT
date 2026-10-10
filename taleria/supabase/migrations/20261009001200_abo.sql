-- Taleria, Schritt 9a: Abo-Rechte (Gratis und Premium)
--
-- Enthält:
--   * entitlements          Abo eines Eltern-Kontos (CLAUDE.md Abschnitt 7)
--   * has_premium(), child_has_premium()   gilt das Abo gerade?
--   * island_unlocked()     Premium-Inseln nur mit Abo
--   * children_free_limit   Gratis: ein Kinder-Profil
--   * map_islands()         zusätzlich access (free, premium)
--   * child_stats()         zusätzlich premium
--   * my_subscription()     Abo-Stand für den Leuchtturm
--   * set_test_premium()    Abo zum Ausprobieren, NUR in der Testumgebung
--
-- Regeln aus CLAUDE.md, Abschnitt 8:
--   * Was freigeschaltet ist, hängt am Eltern-Konto, nicht am Kind.
--   * Gratis: Hafen und Tauschinsel (content.access = free), ein Kinder-Profil,
--     Aufgaben und Schatztruhe.
--   * Abgeschlossene Inseln bleiben abgeschlossen (eingefroren), auch ohne Abo.
--
-- Gekauft wird später über RevenueCat (Schritt 9b). Dann schreibt nur der Server
-- (Webhook mit dem geheimen Schlüssel) in entitlements, nie die App.

-- ---------------------------------------------------------------------------
-- Abo eines Eltern-Kontos
-- ---------------------------------------------------------------------------

create table public.entitlements (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.parents (id) on delete cascade,
  entitlement text not null default 'premium' check (entitlement in ('premium')),
  -- revenuecat: Kauf im Store, manual: vom Support vergeben, test: nur Testumgebung
  source text not null check (source in ('revenuecat', 'manual', 'test')),
  -- null = ohne Ablauf (nur manual und test)
  valid_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint entitlements_once unique (parent_id, entitlement, source)
);

create index entitlements_parent_idx on public.entitlements (parent_id);

create trigger entitlements_set_updated_at before update on public.entitlements
  for each row execute function public.set_updated_at();

alter table public.entitlements enable row level security;

-- Eltern sehen ihr eigenes Abo. Schreiben nur Server-Funktionen und Admins.
create policy "Eltern sehen ihr Abo"
  on public.entitlements for select to authenticated
  using (parent_id = public.current_parent_id() or public.is_admin(array['owner', 'support']));

create policy "Owner verwalten Abos"
  on public.entitlements for all to authenticated
  using (public.is_admin(array['owner']))
  with check (public.is_admin(array['owner']));

create or replace function public.has_premium(p_parent_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.entitlements e
    where e.parent_id = p_parent_id
      and e.entitlement = 'premium'
      and (e.valid_until is null or e.valid_until > now())
  );
$$;

create or replace function public.child_has_premium(p_child_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select public.has_premium(c.parent_id) from public.children c where c.id = p_child_id), false);
$$;

-- ---------------------------------------------------------------------------
-- Premium-Inseln (ersetzt die Fassung aus Schritt 4b)
-- ---------------------------------------------------------------------------

create or replace function public.island_unlocked(p_child_id uuid, p_island_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with target as (
    select i.id, i.stage, i.sort_order from public.islands i where i.id = p_island_id
  ),
  previous as (
    select i.id
    from public.islands i, target t
    where i.stage = t.stage
      and i.route_type = 'main'
      and i.sort_order < t.sort_order
    order by i.sort_order desc
    limit 1
  )
  select exists (select 1 from target)
     -- Premium-Inseln nur mit Abo (Abo-Rechte hängen am Eltern-Konto).
     and (
       coalesce((select i.content ->> 'access' from public.islands i where i.id = p_island_id), 'free') <> 'premium'
       or public.child_has_premium(p_child_id)
     )
     and (
       not exists (select 1 from previous)
       or exists (
         select 1 from public.island_completions c, previous p
         where c.child_id = p_child_id and c.island_id = p.id
       )
     );
$$;

-- ---------------------------------------------------------------------------
-- Gratis: ein Kinder-Profil
-- ---------------------------------------------------------------------------

-- Nach dem Einfügen geprüft, damit zuerst die normalen Regeln (Spitzname,
-- Geburtsjahr, Rechte) ihre eigenen Meldungen geben. Gilt für Eltern in der
-- App; Server und Support ohne Eltern-Sitzung sind ausgenommen.
create or replace function public.check_children_free_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.current_parent_id() = new.parent_id
     and not public.has_premium(new.parent_id)
     and (select count(*) from public.children c where c.parent_id = new.parent_id) > 1 then
    raise exception 'Weitere Kinder-Profile gibt es mit dem Abo' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger children_free_limit
  after insert on public.children
  for each row execute function public.check_children_free_limit();

-- ---------------------------------------------------------------------------
-- Karte mit Zugang (ersetzt die Fassung aus Schritt 4b)
-- ---------------------------------------------------------------------------

drop function public.map_islands(smallint);

create function public.map_islands(p_stage smallint)
returns table (
  id uuid,
  slug text,
  title text,
  island_group smallint,
  sort_order integer,
  map_x numeric,
  map_y numeric,
  route_type text,
  has_content boolean,
  access text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    i.id,
    i.slug,
    i.title,
    i.island_group,
    i.sort_order,
    i.map_x,
    i.map_y,
    i.route_type,
    public.is_content_visible(i.status, i.publish_at)
      and exists (
        select 1 from public.stations s
        where s.island_id = i.id
          and s.is_required
          and public.is_content_visible(s.status, s.publish_at)
      ) as has_content,
    coalesce(i.content ->> 'access', 'free') as access
  from public.islands i
  where auth.uid() is not null
    and i.stage = p_stage
    and i.route_type in ('main', 'side')
  order by i.sort_order;
$$;

revoke execute on function public.map_islands(smallint) from public, anon;
grant execute on function public.map_islands(smallint) to authenticated;

-- ---------------------------------------------------------------------------
-- Abo-Stand für den Leuchtturm
-- ---------------------------------------------------------------------------

-- Antwort: {"premium": true, "source": "test", "valid_until": null, "test_purchases": true}
create or replace function public.my_subscription()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_parent uuid := public.current_parent_id();
  v_entitlement record;
begin
  if v_parent is null then
    raise exception 'Nur für Eltern' using errcode = '42501';
  end if;
  select e.source, e.valid_until into v_entitlement
  from public.entitlements e
  where e.parent_id = v_parent and e.entitlement = 'premium'
    and (e.valid_until is null or e.valid_until > now())
  order by e.valid_until desc nulls first
  limit 1;
  return jsonb_build_object(
    'premium', v_entitlement.source is not null,
    'source', v_entitlement.source,
    'valid_until', v_entitlement.valid_until,
    'test_purchases', coalesce(
      (select s.value = 'true'::jsonb from public.app_settings s where s.key = 'test_purchases'), false
    )
  );
end;
$$;

-- Abo zum Ausprobieren. Geht NUR, wenn app_settings.test_purchases = true
-- (supabase/seed.sql, nur Testumgebung). In der Live-Datenbank gibt es den Eintrag nie.
create or replace function public.set_test_premium(p_active boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_parent uuid := public.current_parent_id();
begin
  if v_parent is null then
    raise exception 'Nur für Eltern' using errcode = '42501';
  end if;
  if not coalesce(
    (select s.value = 'true'::jsonb from public.app_settings s where s.key = 'test_purchases'), false
  ) then
    raise exception 'Test-Abo gibt es nur in der Testumgebung' using errcode = '42501';
  end if;

  if p_active then
    insert into public.entitlements (parent_id, entitlement, source)
    values (v_parent, 'premium', 'test')
    on conflict on constraint entitlements_once do update set valid_until = null;
  else
    delete from public.entitlements where parent_id = v_parent and source = 'test';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Statistik mit Abo (ersetzt die Fassung aus Schritt 8)
-- ---------------------------------------------------------------------------

create or replace function public.child_stats(p_child_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_xp bigint;
  v_rank record;
  v_next record;
  v_per_week smallint;
  v_wind smallint;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  v_xp := public.child_xp(p_child_id);
  select r.code, r.sort_order, r.min_xp into v_rank
  from public.ranks r where r.code = public.child_rank(p_child_id);
  select r.code, r.min_xp, r.requires_certificate into v_next
  from public.ranks r
  where r.sort_order > coalesce(v_rank.sort_order, 0)
  order by r.sort_order
  limit 1;

  select c.stations_per_week into v_per_week from public.children c where c.id = p_child_id;
  v_wind := public.refresh_wind(p_child_id);

  return jsonb_build_object(
    'xp', v_xp,
    'rank', v_rank.code,
    'rank_min_xp', v_rank.min_xp,
    'next_rank', v_next.code,
    'next_rank_xp', case when v_next.requires_certificate then null else v_next.min_xp end,
    'next_rank_needs_certificate', coalesce(v_next.requires_certificate, false),
    'streak_weeks', public.current_streak(p_child_id),
    'streak_paused', coalesce((select s.paused from public.child_streaks s where s.child_id = p_child_id), false),
    'badge_count', (select count(*) from public.child_badges b where b.child_id = p_child_id),
    'reviews_due', public.due_review_count(p_child_id),
    'pearls', (
      select coalesce(sum(p.best_score), 0)
      from public.station_progress p
      join public.stations s on s.id = p.station_id
      where p.child_id = p_child_id and p.status = 'done' and s.type = 'review_stop'
    ),
    'finds', (select count(*) from public.child_collectibles c where c.child_id = p_child_id),
    'premium', public.child_has_premium(p_child_id),
    'last_active_at', (
      select max(t) from (
        select max(p.updated_at) as t from public.station_progress p where p.child_id = p_child_id
        union all
        select max(r.finished_at) from public.encounter_runs r where r.child_id = p_child_id
        union all
        select max(q.last_answered_at) from public.question_reviews q where q.child_id = p_child_id
      ) x
    ),
    'pace', jsonb_build_object(
      'free', v_per_week is null,
      'stations_per_week', v_per_week,
      'wind', v_wind,
      'next_release', case when v_wind = 0 then public.next_release_day(p_child_id) end
    )
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------

revoke execute on function
  public.has_premium(uuid),
  public.child_has_premium(uuid),
  public.check_children_free_limit()
from public, anon, authenticated;

revoke execute on function public.my_subscription(), public.set_test_premium(boolean) from public, anon;
grant execute on function public.my_subscription(), public.set_test_premium(boolean) to authenticated;
