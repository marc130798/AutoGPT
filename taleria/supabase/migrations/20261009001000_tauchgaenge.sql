-- Taleria, Schritt 7a: Tauchgänge (Ankerplätze) und Unterwasser-Sammlung
--
-- Enthält:
--   * collectibles, child_collectibles   Funde für die Unterwasser-Sammlung (nur Optik, nie kaufbar)
--   * submit_station()   Ankerplätze (stations.type = review_stop): Fragen der Stationen seit dem
--                        letzten Ankerplatz, erledigt nach dem Durchgang, kein Wind nötig, Fund
--   * child_stats()      zusätzlich Perlen und Funde
--   * next_encounter()   mit Übungsmodus, wenn die nächste Insel im Nebel liegt
--
-- Regeln aus CLAUDE.md, Abschnitt 8:
--   * Ankerplatz nach jeder zweiten Station, Pflicht für den Insel-Abschluss.
--   * 3 bis 4 Wiederholungsfragen zu den beiden Stationen davor (Perlentauchen: richtige
--     Antwort = Perle) und eine Anwendungsaufgabe im Wrack (wertet die App, ohne Punkte).
--   * Funde sind rein kosmetisch und nie kaufbar.
--   * Perlen = richtige Antworten im besten Tauchgang je Ankerplatz (station_progress.best_score).

-- ---------------------------------------------------------------------------
-- Unterwasser-Sammlung
-- ---------------------------------------------------------------------------

create table public.collectibles (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9_-]{2,60}$'),
  kind text not null check (kind in ('pearl', 'shell', 'wreck_item')),
  title text not null check (char_length(trim(title)) between 2 and 60),
  asset_key text not null check (asset_key ~ '^[a-z0-9_.-]{3,80}$'),
  -- Nur Optik, ändert nichts am Spiel.
  rarity text not null default 'common' check (rarity in ('common', 'rare')),
  -- Der Ankerplatz, an dem der Fund liegt.
  station_id uuid references public.stations (id) on delete cascade,
  sort_order integer not null default 0,
  status public.content_status not null default 'draft',
  publish_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index collectibles_station_idx on public.collectibles (station_id);

create trigger collectibles_set_updated_at before update on public.collectibles
  for each row execute function public.set_updated_at();

create table public.child_collectibles (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  collectible_id uuid not null references public.collectibles (id) on delete cascade,
  source_station_id uuid references public.stations (id) on delete set null,
  found_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint child_collectibles_once unique (child_id, collectible_id)
);

create index child_collectibles_child_idx on public.child_collectibles (child_id);

alter table public.collectibles enable row level security;
alter table public.child_collectibles enable row level security;

create policy "Sichtbare Funde lesen"
  on public.collectibles for select to authenticated
  using (public.is_content_visible(status, publish_at) or public.is_admin());

create policy "Editoren schreiben Funde"
  on public.collectibles for all to authenticated
  using (public.is_admin(array['owner', 'editor']))
  with check (public.is_admin(array['owner', 'editor']));

-- Gefunden wird nur über submit_station().
create policy "Eltern und Kinder-Gerät sehen die Sammlung"
  on public.child_collectibles for select to authenticated
  using (public.can_act_for_child(child_id));

-- ---------------------------------------------------------------------------
-- Station abgeben (ersetzt die Fassung aus Schritt 6a)
-- ---------------------------------------------------------------------------

-- Wie in Schritt 6a, dazu Ankerplätze (review_stop):
--   * Antworten: content.dive.questions Fragen (Standard 4) aus den Stationen der
--     Insel zwischen dem letzten Ankerplatz und diesem (ohne Prüfung).
--   * Erledigt nach dem Durchgang, Fehler kosten nichts. Kein Wind nötig.
--   * Antwort zusätzlich: find (neuer Fund oder null).
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
  v_first boolean;
  v_wind smallint;
  v_rank_before text;
  v_rank_after text;
  v_badge jsonb;
  v_answer record;
  v_checked jsonb;
  v_is_dive boolean;
  v_prev_dive integer := -1;
  v_find jsonb;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  select s.id, s.island_id, s.type, s.xp_reward, s.content, s.status, s.publish_at, s.is_required, s.sort_order
    into v_station
  from public.stations s where s.id = p_station_id;
  if not found then
    raise exception 'Station nicht gefunden' using errcode = 'P0002';
  end if;

  v_is_dive := v_station.type = 'review_stop';

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

  -- Tempo: neue Pflichtstationen brauchen Wind. Ankerplätze nicht: Sie
  -- gehören zu den beiden Stationen davor (CLAUDE.md Abschnitt 8).
  v_first := not public.station_done(p_child_id, p_station_id);
  if v_first and v_station.is_required and not v_is_dive then
    v_wind := public.refresh_wind(p_child_id);
    if v_wind is not null and v_wind <= 0 then
      raise exception 'Das Schiff braucht Wind' using errcode = 'P0001';
    end if;
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
  elsif v_is_dive then
    -- Tauchgang: Fragen der Stationen seit dem letzten Ankerplatz, erledigt nach dem Durchgang.
    v_expected := coalesce((v_station.content -> 'dive' ->> 'questions')::integer, 4);
    v_pass := 0;
    select coalesce(max(s.sort_order), -1)
      into v_prev_dive
    from public.stations s
    where s.island_id = v_island.id and s.type = 'review_stop' and s.sort_order < v_station.sort_order;
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
      g.question_id,
      q.id is not null and g.answer_index = q.correct_index as correct,
      q.station_id = p_station_id or v_is_dive as own,
      q.id is not null
        and public.is_content_visible(q.status, null)
        and (
          q.station_id = p_station_id
          or (
            v_is_dive
            and exists (
              select 1
              from public.stations s
              where s.id = q.station_id
                and s.island_id = v_island.id
                and s.type not in ('exam', 'review_stop')
                and s.sort_order > v_prev_dive
                and s.sort_order < v_station.sort_order
                and public.is_content_visible(s.status, s.publish_at)
            )
          )
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
    count(*) filter (where allowed and correct),
    count(*) filter (where not allowed),
    count(*) filter (where allowed and not own),
    coalesce(
      jsonb_agg(jsonb_build_object('question_id', question_id, 'correct', correct)) filter (where allowed),
      '[]'::jsonb
    )
  into v_correct, v_invalid, v_review_given, v_checked
  from checked;

  if v_invalid > 0 then
    raise exception 'Frage gehört nicht zu dieser Station' using errcode = '22023';
  end if;
  if v_review_given <> v_review then
    raise exception 'Falsche Anzahl an Rückblick-Fragen: % erwartet', v_review using errcode = '22023';
  end if;

  v_passed := v_correct >= v_pass;
  v_rank_before := public.child_rank(p_child_id);

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

  -- Wind verbrauchen, wenn die Pflichtstation zum ersten Mal erledigt ist.
  if v_first and v_passed and v_wind is not null then
    update public.pace_state set wind = greatest(wind - 1, 0) where child_id = p_child_id;
    v_wind := greatest(v_wind - 1, 0);
  end if;

  -- Wiederholungsplan und Fahrtwind.
  for v_answer in select * from jsonb_to_recordset(v_checked) as x(question_id uuid, correct boolean) loop
    perform public.record_answer(p_child_id, v_answer.question_id, v_answer.correct);
  end loop;
  perform public.mark_activity(p_child_id);

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
  -- Der Orden kommt über den Trigger island_completions_award_badge.
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

  if v_island_completed then
    select jsonb_build_object('id', b.id, 'slug', b.slug, 'title', b.title, 'asset_key', b.asset_key)
      into v_badge
    from public.badges b
    where b.island_id = v_island.id and public.is_content_visible(b.status, b.publish_at);
  end if;

  -- Tauchgang: Fund für die Unterwasser-Sammlung (genau einmal).
  if v_is_dive and v_passed then
    with found as (
      insert into public.child_collectibles (child_id, collectible_id, source_station_id)
      select p_child_id, c.id, p_station_id
      from public.collectibles c
      where c.station_id = p_station_id and public.is_content_visible(c.status, c.publish_at)
      on conflict on constraint child_collectibles_once do nothing
      returning collectible_id
    )
    select jsonb_build_object('id', c.id, 'slug', c.slug, 'kind', c.kind, 'title', c.title, 'asset_key', c.asset_key)
      into v_find
    from found f
    join public.collectibles c on c.id = f.collectible_id
    limit 1;
  end if;

  v_rank_after := public.child_rank(p_child_id);

  return jsonb_build_object(
    'correct', v_correct,
    'total', v_total,
    'passed', v_passed,
    'xp_awarded', v_xp,
    'island_completed', v_island_completed,
    'rank_up', case when v_rank_after is distinct from v_rank_before then v_rank_after end,
    'badge', v_badge,
    'wind_left', case when v_station.is_required and not v_is_dive then public.refresh_wind(p_child_id) end,
    'find', v_find
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Statistik mit Perlen und Funden (ersetzt die Fassung aus Schritt 6a)
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
-- Begegnung auf See, auch zum Üben (Nebel voraus)
-- ---------------------------------------------------------------------------

drop function public.next_encounter(uuid);

create function public.next_encounter(p_child_id uuid, p_practice boolean default false)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_due integer;
  v_encounter record;
  v_questions uuid[];
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  v_due := public.due_review_count(p_child_id);
  -- Übung (Nebel voraus): auch ohne fällige Wiederholungen, mit den nächsten Terminen.
  if v_due = 0 and not p_practice then
    return null;
  end if;

  select e.id, e.slug, e.type, e.title, e.asset_key, e.question_count, e.xp_reward, e.content
    into v_encounter
  from public.encounters e
  where public.is_content_visible(e.status, e.publish_at)
    and (
      e.after_island_id is null
      or exists (
        select 1 from public.island_completions c
        where c.child_id = p_child_id and c.island_id = e.after_island_id
      )
    )
  order by random()
  limit 1;
  if not found then
    return null;
  end if;

  select array_agg(x.question_id order by x.rank_due, x.due_at)
    into v_questions
  from (
    select r.question_id, r.due_at, case when r.due_at <= now() then 0 else 1 end as rank_due
    from public.question_reviews r
    where r.child_id = p_child_id and public.question_visible(r.question_id)
    order by case when r.due_at <= now() then 0 else 1 end, r.due_at, random()
    limit v_encounter.question_count
  ) x;

  if coalesce(cardinality(v_questions), 0) < v_encounter.question_count then
    return null;
  end if;

  return jsonb_build_object(
    'encounter', jsonb_build_object(
      'id', v_encounter.id,
      'slug', v_encounter.slug,
      'type', v_encounter.type,
      'title', v_encounter.title,
      'asset_key', v_encounter.asset_key,
      'question_count', v_encounter.question_count,
      'xp_reward', v_encounter.xp_reward,
      'content', v_encounter.content
    ),
    'question_ids', to_jsonb(v_questions),
    'first_meeting', not exists (
      select 1 from public.encounter_runs er
      where er.child_id = p_child_id and er.encounter_id = v_encounter.id
    ),
    'due_count', v_due
  );
end;
$$;

revoke execute on function public.next_encounter(uuid, boolean) from public, anon;
grant execute on function public.next_encounter(uuid, boolean) to authenticated;
