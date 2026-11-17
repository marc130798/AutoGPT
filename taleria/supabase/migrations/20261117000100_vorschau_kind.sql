-- Vorschau-Kind (Marcs Wunsch am 17.11.2026): Im Testprojekt kann ein
-- Kinder-Profil alles offen haben, damit Marc alle Inseln, Stationen und
-- Spiele ansehen kann, ohne sie der Reihe nach zu spielen. Jede Station läuft
-- trotzdem wie beim ersten Mal (Seemeilen, Orden, Kartenstück).
--
-- Doppelt gesichert: Es wirkt nur, wenn app_settings.test_purchases = true
-- ist. Den Eintrag setzt nur supabase/seed.sql, also nur im Testprojekt; in
-- der Live-Datenbank gibt es ihn nie. Mehrfach ausführbar.

alter table public.children add column if not exists preview_all boolean not null default false;

-- Ist das Kind ein Vorschau-Kind (und ist das hier das Testprojekt)?
create or replace function public.child_preview(p_child_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select c.preview_all from public.children c where c.id = p_child_id), false)
     and coalesce(
       (select s.value = 'true'::jsonb from public.app_settings s where s.key = 'test_purchases'), false
     );
$$;

-- Wie in 20261009001200_abo.sql, dazu: Vorschau-Kinder haben jede Insel offen.
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
     and (
       public.child_preview(p_child_id)
       or (
         -- Premium-Inseln nur mit Abo (Abo-Rechte hängen am Eltern-Konto).
         (
           coalesce((select i.content ->> 'access' from public.islands i where i.id = p_island_id), 'free') <> 'premium'
           or public.child_has_premium(p_child_id)
         )
         and (
           not exists (select 1 from previous)
           or exists (
             select 1 from public.island_completions c, previous p
             where c.child_id = p_child_id and c.island_id = p.id
           )
         )
       )
     );
$$;

-- Wie in 20261009000600_fortschritt.sql, dazu: Vorschau-Kinder müssen nichts der Reihe nach machen.
create or replace function public.station_unlocked(p_child_id uuid, p_station_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.stations s
    where s.id = p_station_id
      and public.island_unlocked(p_child_id, s.island_id)
      and (
        not s.is_required
        or public.child_preview(p_child_id)
        or not exists (
          select 1
          from public.stations earlier
          where earlier.island_id = s.island_id
            and earlier.is_required
            and earlier.sort_order < s.sort_order
            and public.is_content_visible(earlier.status, earlier.publish_at)
            and not public.station_done(p_child_id, earlier.id)
        )
      )
  );
$$;

-- Eltern schalten die Vorschau ein oder aus. Nur im Testprojekt. Beim
-- Einschalten gilt freie Fahrt (kein Wind nötig), beim Ausschalten wieder
-- 2 Stationen pro Woche (Montag und Donnerstag).
create or replace function public.set_child_preview(p_child_id uuid, p_on boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_parent_of_child(p_child_id) then
    raise exception 'Nur Eltern schalten die Vorschau' using errcode = '42501';
  end if;
  if not coalesce(
    (select s.value = 'true'::jsonb from public.app_settings s where s.key = 'test_purchases'), false
  ) then
    raise exception 'Vorschau gibt es nur im Testprojekt' using errcode = 'P0001';
  end if;
  update public.children
    set preview_all = coalesce(p_on, false),
        stations_per_week = case when coalesce(p_on, false) then null else 2 end,
        release_weekdays = '{1,4}'::smallint[]
    where id = p_child_id;
  -- Wie set_pace(): nach freier Fahrt startet der Wind mit einer vollen Woche.
  delete from public.pace_state where child_id = p_child_id;
end;
$$;

revoke execute on function public.child_preview(uuid) from public, anon, authenticated;
revoke execute on function public.set_child_preview(uuid, boolean) from public, anon;
grant execute on function public.set_child_preview(uuid, boolean) to authenticated;
