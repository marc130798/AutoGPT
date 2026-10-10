-- Taleria: Stopps auf See (Pflicht zwischen den Inseln), entschieden mit Marc
-- am 10.10.2026.
--
-- Auf der Route vor einer Insel liegen Stopps auf See (zum Beispiel ein
-- Händlerschiff). Sie sind Pflichtstationen dieser Insel mit dem Typ
-- sea_stop und kommen vor ihrer ersten Station (sort_order 1, 2, ...). Damit
-- gelten die bestehenden Regeln: Pflichtstationen der Reihe nach
-- (station_unlocked), Abo über island_unlocked, Insel-Abschluss erst, wenn
-- alles erledigt ist. Neu ist nur:
--   * stations.type erlaubt sea_stop
--   * submit_station(): Stopps auf See brauchen wie Ankerplätze keinen Wind
--
-- Mehrfach ausführbar.

alter table public.stations drop constraint if exists stations_type_check;
alter table public.stations add constraint stations_type_check
  check (type in ('video', 'quiz', 'game', 'practice', 'review_stop', 'exam', 'sea_stop'));

-- Wie in 20261009001000_tauchgaenge.sql, nur ohne Wind für Stopps auf See.
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
  v_no_wind boolean;
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
  -- Ankerplätze und Stopps auf See brauchen keinen Wind.
  v_no_wind := v_station.type in ('review_stop', 'sea_stop');

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

  -- Tempo: neue Pflichtstationen brauchen Wind. Ankerplätze nicht (sie
  -- gehören zu den beiden Stationen davor) und Stopps auf See nicht (sie
  -- wiederholen die Insel davor).
  v_first := not public.station_done(p_child_id, p_station_id);
  if v_first and v_station.is_required and not v_no_wind then
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
    'wind_left', case when v_station.is_required and not v_no_wind then public.refresh_wind(p_child_id) end,
    'find', v_find
  );
end;
$$;
