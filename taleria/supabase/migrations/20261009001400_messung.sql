-- Taleria, Schritt 11: Messung und Fehlerprotokoll für die Beta
--
-- Enthält:
--   * analytics_events     eigene, sparsame Ereignis-Tabelle (CLAUDE.md Abschnitt 5)
--   * track_event()        App meldet „App geöffnet“ und „Station begonnen“
--   * app_errors           Fehlerprotokoll der App, ohne Nutzer und ohne Gerät
--   * report_app_error()   App meldet einen Fehler
--   * admin_overview()     zusätzlich Rückkehr nach 1 und 4 Wochen und Fehler der letzten 7 Tage
--   * admin_content_stats() zusätzlich „begonnen“ pro Station (für die Abbruchquote)
--   * admin_app_errors()   Fehlerprotokoll für den Owner
--
-- Datenschutz (CLAUDE.md Abschnitt 5 und 9):
--   * Kein Drittanbieter, keine Werbe-IDs, keine Geräte-Daten, keine Uhrzeit:
--     höchstens ein Eintrag pro Kind, Ereignis, Station und Tag.
--   * Niemand liest die Tabellen direkt. Admins sehen nur Summen.
--   * Ereignisse werden nach 400 Tagen gelöscht, Fehler nach 90 Tagen, und mit dem
--     Kinder-Profil verschwinden auch seine Ereignisse.

-- ---------------------------------------------------------------------------
-- Ereignisse
-- ---------------------------------------------------------------------------

create table public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  -- app_open: Kinderbereich geöffnet, station_start: Station oder Prüfung begonnen
  event_type text not null check (event_type in ('app_open', 'station_start')),
  station_id uuid references public.stations (id) on delete cascade,
  -- Nur der Tag (deutsche Zeit), keine Uhrzeit.
  day date not null default public.taleria_today(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint analytics_events_station check ((event_type = 'station_start') = (station_id is not null))
);

create unique index analytics_events_once
  on public.analytics_events (child_id, event_type, coalesce(station_id, '00000000-0000-0000-0000-000000000000'::uuid), day);
create index analytics_events_day_idx on public.analytics_events (day);
create index analytics_events_station_idx on public.analytics_events (station_id) where station_id is not null;

alter table public.analytics_events enable row level security;
-- Keine Richtlinien: Lesen und Schreiben nur über die Funktionen unten.

-- Meldet ein Ereignis. Mehrfache Meldungen am selben Tag zählen einmal.
create or replace function public.track_event(p_child_id uuid, p_event text, p_station_id uuid default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;
  if p_event is null or p_event not in ('app_open', 'station_start') then
    raise exception 'Unbekanntes Ereignis' using errcode = '22023';
  end if;
  if (p_event = 'station_start') <> (p_station_id is not null) then
    raise exception 'Station fehlt oder passt nicht zum Ereignis' using errcode = '22023';
  end if;
  if p_station_id is not null and not exists (select 1 from public.stations s where s.id = p_station_id) then
    raise exception 'Station nicht gefunden' using errcode = 'P0002';
  end if;

  insert into public.analytics_events (child_id, event_type, station_id)
  values (p_child_id, p_event, p_station_id)
  on conflict do nothing;

  -- Alte Ereignisse löschen (Datensparsamkeit).
  delete from public.analytics_events e where e.day < public.taleria_today() - 400;
end;
$$;

-- ---------------------------------------------------------------------------
-- Fehlerprotokoll
-- ---------------------------------------------------------------------------

create table public.app_errors (
  id uuid primary key default gen_random_uuid(),
  -- Gleicher Fehler am selben Tag = eine Zeile mit Zähler.
  fingerprint text not null,
  day date not null default public.taleria_today(),
  platform text not null check (platform in ('ios', 'android', 'web', 'other')),
  error text not null check (char_length(error) between 1 and 500),
  stack text check (stack is null or char_length(stack) <= 4000),
  count integer not null default 1 check (count >= 1),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint app_errors_once unique (fingerprint, day)
);

create index app_errors_day_idx on public.app_errors (day);

create trigger app_errors_set_updated_at before update on public.app_errors
  for each row execute function public.set_updated_at();

alter table public.app_errors enable row level security;
-- Keine Richtlinien: Schreiben nur über report_app_error(), Lesen nur über admin_app_errors().

-- Meldet einen Fehler der App. Speichert weder Nutzer noch Gerät. Höchstens 500
-- verschiedene Fehler pro Tag, damit niemand das Protokoll fluten kann.
create or replace function public.report_app_error(p_platform text, p_error text, p_stack text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_platform text := case when p_platform in ('ios', 'android', 'web') then p_platform else 'other' end;
  v_error text := left(trim(coalesce(p_error, '')), 500);
  v_stack text := nullif(left(coalesce(p_stack, ''), 4000), '');
  v_fingerprint text;
begin
  if auth.uid() is null then
    raise exception 'Nur mit Anmeldung' using errcode = '42501';
  end if;
  if v_error = '' then
    return;
  end if;
  v_fingerprint := md5(v_platform || '|' || v_error || '|' || coalesce(left(v_stack, 600), ''));

  if not exists (
    select 1 from public.app_errors a where a.fingerprint = v_fingerprint and a.day = public.taleria_today()
  ) and (select count(*) from public.app_errors a where a.day = public.taleria_today()) >= 500 then
    return;
  end if;

  insert into public.app_errors (fingerprint, platform, error, stack)
  values (v_fingerprint, v_platform, v_error, v_stack)
  on conflict on constraint app_errors_once do update
    set count = public.app_errors.count + 1, last_seen_at = now();

  delete from public.app_errors a where a.day < public.taleria_today() - 90;
end;
$$;

-- Fehler der letzten Tage, häufigste zuerst (nur owner).
create or replace function public.admin_app_errors(p_days integer default 14)
returns table (
  platform text,
  error text,
  stack text,
  total bigint,
  days integer,
  last_seen_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_admin(array['owner']);
  return query
  select
    a.platform,
    a.error,
    (array_agg(a.stack order by a.last_seen_at desc))[1],
    sum(a.count)::bigint,
    count(*)::integer,
    max(a.last_seen_at)
  from public.app_errors a
  where a.day >= public.taleria_today() - least(greatest(coalesce(p_days, 14), 1), 90) + 1
  group by a.fingerprint, a.platform, a.error
  order by sum(a.count) desc, max(a.last_seen_at) desc
  limit 100;
end;
$$;

-- ---------------------------------------------------------------------------
-- Statistik (ersetzt die Fassungen aus Schritt 10)
-- ---------------------------------------------------------------------------

create or replace function public.admin_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
  v_today date := public.taleria_today();
begin
  perform public.require_admin(array['owner']);

  with last_active as (select * from public.children_last_active()),
  first_days as (
    select e.child_id, min(e.day) as first_day from public.analytics_events e group by e.child_id
  ),
  valid_premium as (
    select e.parent_id, e.source
    from public.entitlements e
    where e.entitlement = 'premium' and (e.valid_until is null or e.valid_until > now())
  )
  select jsonb_build_object(
    'families', (select count(*) from public.parents),
    'families_new_7d', (select count(*) from public.parents p where p.created_at >= now() - interval '7 days'),
    'families_new_28d', (select count(*) from public.parents p where p.created_at >= now() - interval '28 days'),
    'children', (select count(*) from public.children),
    'children_onboarded', (select count(*) from public.children c where c.onboarding_completed_at is not null),
    'children_active_7d', (select count(*) from last_active l where l.last_active_at >= now() - interval '7 days'),
    'children_active_28d', (select count(*) from last_active l where l.last_active_at >= now() - interval '28 days'),
    'premium_families', (select count(distinct v.parent_id) from valid_premium v),
    'premium_revenuecat', (select count(distinct v.parent_id) from valid_premium v where v.source = 'revenuecat'),
    'premium_manual', (select count(distinct v.parent_id) from valid_premium v where v.source = 'manual'),
    'premium_test', (select count(distinct v.parent_id) from valid_premium v where v.source = 'test'),
    'children_with_allowance', (select count(*) from public.allowance_rules),
    'tasks_approved_28d', (
      select count(*) from public.tasks t
      where t.status = 'approved' and t.reviewed_at >= now() - interval '28 days'
    ),
    -- Rückkehr: erster Tag in der App, dann wieder da in Woche 2 (Tag 7 bis 13)
    -- oder in Woche 5 (Tag 28 bis 34). Gezählt nur, wer lange genug dabei ist.
    'return_week1_cohort', (select count(*) from first_days f where f.first_day <= v_today - 14),
    'return_week1_returned', (
      select count(*) from first_days f
      where f.first_day <= v_today - 14
        and exists (
          select 1 from public.analytics_events e
          where e.child_id = f.child_id and e.day between f.first_day + 7 and f.first_day + 13
        )
    ),
    'return_week4_cohort', (select count(*) from first_days f where f.first_day <= v_today - 35),
    'return_week4_returned', (
      select count(*) from first_days f
      where f.first_day <= v_today - 35
        and exists (
          select 1 from public.analytics_events e
          where e.child_id = f.child_id and e.day between f.first_day + 28 and f.first_day + 34
        )
    ),
    'app_errors_7d', (select coalesce(sum(a.count), 0) from public.app_errors a where a.day >= v_today - 6),
    'generated_at', now()
  ) into v_result;
  return v_result;
end;
$$;

create or replace function public.admin_content_stats(p_stage smallint default 1)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_onboarded bigint;
  v_children bigint;
  v_islands jsonb;
  v_hardest jsonb;
  v_easiest jsonb;
begin
  perform public.require_admin(array['owner', 'editor']);

  select count(*) into v_onboarded
  from public.children c
  where c.onboarding_completed_at is not null and c.stage = p_stage;
  select count(*) into v_children from public.children c where c.stage = p_stage;

  select coalesce(jsonb_agg(row_data order by route_order, sort_order), '[]'::jsonb) into v_islands
  from (
    select
      case i.route_type when 'main' then 0 when 'side' then 1 else 2 end as route_order,
      i.sort_order,
      jsonb_build_object(
        'id', i.id,
        'slug', i.slug,
        'title', i.title,
        'sort_order', i.sort_order,
        'route_type', i.route_type,
        'status', i.status,
        'publish_at', i.publish_at,
        'access', coalesce(i.content ->> 'access', 'free'),
        'questions', (
          select count(*) from public.quiz_questions q
          join public.stations s on s.id = q.station_id
          where s.island_id = i.id
        ),
        'reached', (
          select count(distinct p.child_id) from public.station_progress p
          join public.stations s on s.id = p.station_id
          where s.island_id = i.id and p.status = 'done'
        ),
        'completed', (select count(*) from public.island_completions ic where ic.island_id = i.id),
        'stations', (
          select coalesce(jsonb_agg(jsonb_build_object(
            'id', s.id,
            'number', (s.content ->> 'number')::integer,
            'title', s.content ->> 'title',
            'type', s.type,
            'status', s.status,
            'is_required', s.is_required,
            'questions', (select count(*) from public.quiz_questions q where q.station_id = s.id),
            'started', case
              when s.content ->> 'kind' = 'onboarding' then v_children
              else (
                select count(distinct e.child_id) from public.analytics_events e
                where e.station_id = s.id and e.event_type = 'station_start'
              )
            end,
            'done', case
              when s.content ->> 'kind' = 'onboarding' then v_onboarded
              else (
                select count(*) from public.station_progress p
                where p.station_id = s.id and p.status = 'done'
              )
            end
          ) order by s.sort_order), '[]'::jsonb)
          from public.stations s
          where s.island_id = i.id
        )
      ) as row_data
    from public.islands i
    where i.stage = p_stage
  ) x;

  with answers as (
    select
      q.id,
      q.question,
      i.title as island,
      (s.content ->> 'number')::integer as station_number,
      s.type as station_type,
      sum(r.times_answered) as answered,
      sum(r.times_wrong) as wrong
    from public.question_reviews r
    join public.quiz_questions q on q.id = r.question_id
    join public.stations s on s.id = q.station_id
    join public.islands i on i.id = s.island_id
    where i.stage = p_stage
    group by q.id, q.question, i.title, s.id
    having sum(r.times_answered) >= 5
  ),
  rated as (
    select a.*, round(a.wrong::numeric / a.answered, 2) as wrong_rate from answers a
  )
  select
    (select coalesce(jsonb_agg(to_jsonb(h) order by h.wrong_rate desc, h.answered desc), '[]'::jsonb)
     from (select * from rated order by wrong_rate desc, answered desc limit 10) h),
    (select coalesce(jsonb_agg(to_jsonb(e) order by e.wrong_rate, e.answered desc), '[]'::jsonb)
     from (select * from rated order by wrong_rate, answered desc limit 10) e)
  into v_hardest, v_easiest;

  return jsonb_build_object(
    'stage', p_stage,
    'children_onboarded', v_onboarded,
    'islands', v_islands,
    'hardest_questions', v_hardest,
    'easiest_questions', v_easiest,
    'generated_at', now()
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------

revoke execute on function
  public.track_event(uuid, text, uuid),
  public.report_app_error(text, text, text),
  public.admin_app_errors(integer)
from public, anon;

grant execute on function
  public.track_event(uuid, text, uuid),
  public.report_app_error(text, text, text),
  public.admin_app_errors(integer)
to authenticated;
