-- Taleria, Schritt 4b: Fortschritt auf der Inselkarte
--
-- Enthält:
--   * app_settings          Einstellungen der Umgebung, z. B. Inhalts-Vorschau (nur Test)
--   * station_progress      erledigte Stationen pro Kind
--   * island_completions    abgeschlossene Inseln pro Kind (eingefroren, CLAUDE.md Abschnitt 8)
--   * map_islands()         Inseln für die Karte, auch die im Nebel
--   * submit_station()      Station abgeben: Server prüft Antworten, bucht Seemeilen,
--                           schließt die Insel ab
--
-- Freischalten (CLAUDE.md Abschnitt 8):
--   * Die erste Insel der Hauptroute ist offen. Jede weitere öffnet sich, sobald die
--     vorherige abgeschlossen ist.
--   * Auf einer Insel öffnet sich jede Pflichtstation, sobald alle Pflichtstationen
--     davor erledigt sind. Bonus-Stationen (Flaschenpost) sind offen, sobald die Insel offen ist.
--   * Das Tempo (2 Stationen pro Woche) kommt in Schritt 6 dazu.

-- ---------------------------------------------------------------------------
-- Einstellungen der Umgebung
-- ---------------------------------------------------------------------------

create table public.app_settings (
  id uuid primary key default gen_random_uuid(),
  key text not null unique check (key ~ '^[a-z_]+$'),
  value jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger app_settings_set_updated_at before update on public.app_settings
  for each row execute function public.set_updated_at();

alter table public.app_settings enable row level security;

create policy "Admins sehen Einstellungen"
  on public.app_settings for select to authenticated
  using (public.is_admin());

create policy "Owner ändern Einstellungen"
  on public.app_settings for all to authenticated
  using (public.is_admin(array['owner']))
  with check (public.is_admin(array['owner']));

-- Inhalts-Vorschau: Kinder sehen auch Entwürfe. NUR in der Testumgebung
-- einschalten (supabase/seed.sql), damit Marc Entwürfe durchspielen kann.
-- In der Live-Datenbank gibt es diesen Eintrag nicht.
create or replace function public.content_preview_enabled()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select s.value = 'true'::jsonb from public.app_settings s where s.key = 'content_preview'),
    false
  );
$$;

-- Sichtbar für Kinder: veröffentlicht und Termin erreicht, oder Vorschau an.
create or replace function public.is_content_visible(
  p_status public.content_status,
  p_publish_at timestamptz
)
returns boolean
language sql
stable
as $$
  select (p_status = 'published' and (p_publish_at is null or p_publish_at <= now()))
      or public.content_preview_enabled();
$$;

-- Quizfragen und Kombüsen-Fragen folgen derselben Regel (auch in der Vorschau).
drop policy "Sichtbare Quizfragen lesen" on public.quiz_questions;
create policy "Sichtbare Quizfragen lesen"
  on public.quiz_questions for select to authenticated
  using (
    public.is_admin()
    or (
      public.is_content_visible(status, null)
      and exists (
        select 1
        from public.stations s
        join public.islands i on i.id = s.island_id
        where s.id = station_id
          and public.is_content_visible(s.status, s.publish_at)
          and public.is_content_visible(i.status, i.publish_at)
      )
    )
  );

drop policy "Sichtbare Kombüsen-Fragen lesen" on public.conversation_prompts;
create policy "Sichtbare Kombüsen-Fragen lesen"
  on public.conversation_prompts for select to authenticated
  using (
    public.is_admin()
    or (
      public.is_content_visible(status, null)
      and exists (
        select 1 from public.islands i
        where i.id = island_id
          and public.is_content_visible(i.status, i.publish_at)
      )
    )
  );

-- ---------------------------------------------------------------------------
-- Fortschritt
-- ---------------------------------------------------------------------------

create table public.station_progress (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  station_id uuid not null references public.stations (id) on delete cascade,
  status text not null default 'open' check (status in ('open', 'done')),
  -- Richtige Antworten im besten und im letzten Durchgang.
  best_score smallint,
  last_score smallint,
  attempts integer not null default 0,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint station_progress_once unique (child_id, station_id),
  constraint station_progress_done_has_date check (status <> 'done' or completed_at is not null)
);

create index station_progress_child_idx on public.station_progress (child_id);

create trigger station_progress_set_updated_at before update on public.station_progress
  for each row execute function public.set_updated_at();

create table public.island_completions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  island_id uuid not null references public.islands (id) on delete cascade,
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint island_completions_once unique (child_id, island_id)
);

create index island_completions_child_idx on public.island_completions (child_id);

-- Ein Insel-Abschluss wird nie geändert oder neu berechnet.
create or replace function public.prevent_island_completion_change()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Ein Insel-Abschluss ist eingefroren und wird nicht geändert'
    using errcode = 'P0001';
end;
$$;

create trigger island_completions_frozen
  before update on public.island_completions
  for each row execute function public.prevent_island_completion_change();

alter table public.station_progress enable row level security;
alter table public.island_completions enable row level security;

-- Lesen dürfen Eltern und Kind. Schreiben nur submit_station() und complete_onboarding().
create policy "Eltern und Kinder-Gerät sehen Stationsfortschritt"
  on public.station_progress for select to authenticated
  using (public.can_act_for_child(child_id));

create policy "Eltern und Kinder-Gerät sehen Insel-Abschlüsse"
  on public.island_completions for select to authenticated
  using (public.can_act_for_child(child_id));

-- ---------------------------------------------------------------------------
-- Regeln zum Freischalten
-- ---------------------------------------------------------------------------

-- Ist die Station für das Kind erledigt? Die Intro-Station des Hafens gilt
-- als erledigt, sobald das Intro abgeschlossen ist (auch wenn das Intro vor
-- den Seed-Daten gespielt wurde).
create or replace function public.station_done(p_child_id uuid, p_station_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.station_progress p
    where p.child_id = p_child_id and p.station_id = p_station_id and p.status = 'done'
  )
  or exists (
    select 1
    from public.stations s, public.children c
    where s.id = p_station_id
      and c.id = p_child_id
      and s.content ->> 'kind' = 'onboarding'
      and c.onboarding_completed_at is not null
  );
$$;

-- Ist die Insel für das Kind offen? Erste Insel der Hauptroute oder die
-- vorherige Insel der Hauptroute ist abgeschlossen.
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
       not exists (select 1 from previous)
       or exists (
         select 1 from public.island_completions c, previous p
         where c.child_id = p_child_id and c.island_id = p.id
       )
     );
$$;

-- Ist die Station für das Kind offen?
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

-- ---------------------------------------------------------------------------
-- Karte
-- ---------------------------------------------------------------------------

-- Alle Inseln einer Stufe für die Karte, auch solche, deren Inhalte noch
-- nicht veröffentlicht sind (Nebel). Von Inseln im Nebel gibt es nur Name
-- und Position, keine Stationen.
create or replace function public.map_islands(p_stage smallint)
returns table (
  id uuid,
  slug text,
  title text,
  island_group smallint,
  sort_order integer,
  map_x numeric,
  map_y numeric,
  route_type text,
  has_content boolean
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
      ) as has_content
  from public.islands i
  where auth.uid() is not null
    and i.stage = p_stage
    and i.route_type in ('main', 'side')
  order by i.sort_order;
$$;

-- ---------------------------------------------------------------------------
-- Station abgeben
-- ---------------------------------------------------------------------------

-- p_answers: [{"question_id": "...", "answer_index": 0}, ...]
--   answer_index ist die Stelle in der gespeicherten Antwortliste (vor dem Mischen).
--
-- Stations-Check und Quiz: genau content.quiz.show Antworten aus dem Pool der
-- Station. Erledigt ist die Station nach dem Durchgang, Fehler kosten nichts.
-- Abschlussprüfung: content.exam.show Fragen der Insel plus content.exam.review
-- Rückblick-Fragen aus Prüfungen früherer Inseln, bestanden ab content.exam.pass.
-- Seemeilen gibt es einmal pro Station (stations.xp_reward).
--
-- Antwort: {"correct": 4, "total": 5, "passed": true, "xp_awarded": 100, "island_completed": false}
create or replace function public.submit_station(
  p_child_id uuid,
  p_station_id uuid,
  p_answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_station record;
  v_island record;
  v_expected integer;
  v_review integer := 0;
  v_pass integer;
  v_total integer;
  v_distinct integer;
  v_correct integer;
  v_invalid integer;
  v_review_given integer;
  v_passed boolean;
  v_xp integer := 0;
  v_rows integer;
  v_island_completed boolean := false;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  select s.id, s.island_id, s.type, s.xp_reward, s.content, s.status, s.publish_at
    into v_station
  from public.stations s where s.id = p_station_id;
  if not found then
    raise exception 'Station nicht gefunden' using errcode = 'P0002';
  end if;

  select i.id, i.stage, i.sort_order, i.status, i.publish_at
    into v_island
  from public.islands i where i.id = v_station.island_id;

  if not public.is_content_visible(v_station.status, v_station.publish_at)
     or not public.is_content_visible(v_island.status, v_island.publish_at) then
    raise exception 'Station nicht gefunden' using errcode = 'P0002';
  end if;
  if v_station.content ->> 'kind' = 'onboarding' then
    raise exception 'Das Intro wird über complete_onboarding() abgeschlossen' using errcode = '22023';
  end if;
  if not public.station_unlocked(p_child_id, p_station_id) then
    raise exception 'Station noch gesperrt' using errcode = 'P0001';
  end if;

  if jsonb_typeof(p_answers) <> 'array' then
    raise exception 'Antworten fehlen' using errcode = '22023';
  end if;

  -- Wie viele Antworten erwartet werden.
  if v_station.type = 'exam' then
    v_expected := coalesce((v_station.content -> 'exam' ->> 'show')::integer, 10);
    -- Rückblick nur, wenn es frühere Inseln mit Prüfungsfragen gibt.
    if exists (
      select 1 from public.islands i
      where i.stage = v_island.stage and i.route_type = 'main' and i.sort_order < v_island.sort_order
    ) then
      v_review := coalesce((v_station.content -> 'exam' ->> 'review')::integer, 0);
    end if;
    v_pass := coalesce((v_station.content -> 'exam' ->> 'pass')::integer, v_expected + v_review);
  else
    v_expected := coalesce((v_station.content -> 'quiz' ->> 'show')::integer, 0);
    v_pass := 0;
  end if;

  select count(*), count(distinct (a ->> 'question_id'))
    into v_total, v_distinct
  from jsonb_array_elements(p_answers) a;

  if v_total <> v_expected + v_review or v_distinct <> v_total then
    raise exception 'Falsche Anzahl an Antworten: % erwartet', v_expected + v_review using errcode = '22023';
  end if;

  -- Jede Frage muss zur Station gehören, Rückblick-Fragen zu Prüfungen früherer Inseln.
  with given as (
    select (a ->> 'question_id')::uuid as question_id, (a ->> 'answer_index')::integer as answer_index
    from jsonb_array_elements(p_answers) a
  ),
  checked as (
    select
      g.answer_index,
      q.correct_index,
      q.station_id = p_station_id as own,
      q.id is not null
        and public.is_content_visible(q.status, null)
        and (
          q.station_id = p_station_id
          or (
            v_station.type = 'exam'
            and exists (
              select 1
              from public.stations s
              join public.islands i on i.id = s.island_id
              where s.id = q.station_id
                and s.type = 'exam'
                and i.stage = v_island.stage
                and i.sort_order < v_island.sort_order
                and public.is_content_visible(s.status, s.publish_at)
            )
          )
        ) as allowed
    from given g
    left join public.quiz_questions q on q.id = g.question_id
  )
  select
    count(*) filter (where allowed and answer_index = correct_index),
    count(*) filter (where not allowed),
    count(*) filter (where allowed and not own)
  into v_correct, v_invalid, v_review_given
  from checked;

  if v_invalid > 0 then
    raise exception 'Frage gehört nicht zu dieser Station' using errcode = '22023';
  end if;
  if v_review_given <> v_review then
    raise exception 'Falsche Anzahl an Rückblick-Fragen: % erwartet', v_review using errcode = '22023';
  end if;

  v_passed := v_correct >= v_pass;

  insert into public.station_progress as p
    (child_id, station_id, status, best_score, last_score, attempts, completed_at)
  values (
    p_child_id, p_station_id,
    case when v_passed then 'done' else 'open' end,
    v_correct, v_correct, 1,
    case when v_passed then now() end
  )
  on conflict on constraint station_progress_once do update
  set status = case when p.status = 'done' or v_passed then 'done' else 'open' end,
      best_score = greatest(p.best_score, excluded.best_score),
      last_score = excluded.last_score,
      attempts = p.attempts + 1,
      completed_at = coalesce(p.completed_at, excluded.completed_at);

  if v_passed and v_station.xp_reward > 0 then
    insert into public.xp_events (child_id, source_type, source_id, amount)
    values (p_child_id, 'station', p_station_id, v_station.xp_reward)
    on conflict on constraint xp_events_once do nothing;
    get diagnostics v_rows = row_count;
    if v_rows > 0 then
      v_xp := v_station.xp_reward;
    end if;
  end if;

  -- Insel abschließen, wenn alle sichtbaren Pflichtstationen erledigt sind.
  if v_passed and not exists (
    select 1 from public.stations s
    where s.island_id = v_island.id
      and s.is_required
      and public.is_content_visible(s.status, s.publish_at)
      and not public.station_done(p_child_id, s.id)
  ) then
    insert into public.island_completions (child_id, island_id)
    values (p_child_id, v_island.id)
    on conflict on constraint island_completions_once do nothing;
    get diagnostics v_rows = row_count;
    v_island_completed := v_rows > 0;
  end if;

  return jsonb_build_object(
    'correct', v_correct,
    'total', v_total,
    'passed', v_passed,
    'xp_awarded', v_xp,
    'island_completed', v_island_completed
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Intro: Seemeilen aus der Station, Fortschritt eintragen
-- ---------------------------------------------------------------------------

create or replace function public.complete_onboarding(p_child_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_station_id uuid;
  v_station_xp integer;
  v_amount integer := 50;
  v_inserted integer;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  -- Intro-Station der Stufe des Kindes (Hafen, Station 1), wenn es sie schon gibt.
  select s.id, s.xp_reward
    into v_station_id, v_station_xp
  from public.stations s
  join public.islands i on i.id = s.island_id
  join public.children c on c.id = p_child_id and c.stage = i.stage
  where s.content ->> 'kind' = 'onboarding'
  order by i.sort_order, s.sort_order
  limit 1;
  if v_station_id is not null then
    v_amount := v_station_xp;
  end if;

  update public.children
  set onboarding_completed_at = coalesce(onboarding_completed_at, now())
  where id = p_child_id;

  if v_station_id is not null then
    insert into public.station_progress (child_id, station_id, status, attempts, completed_at)
    values (p_child_id, v_station_id, 'done', 1, now())
    on conflict on constraint station_progress_once do nothing;
  end if;

  insert into public.xp_events (child_id, source_type, source_id, amount)
  values (p_child_id, 'onboarding', p_child_id, v_amount)
  on conflict on constraint xp_events_once do nothing;

  get diagnostics v_inserted = row_count;
  return case when v_inserted > 0 then v_amount else 0 end;
end;
$$;

revoke execute on function
  public.submit_station(uuid, uuid, jsonb),
  public.map_islands(smallint)
from public, anon;

grant execute on function
  public.submit_station(uuid, uuid, jsonb),
  public.map_islands(smallint)
to authenticated;
