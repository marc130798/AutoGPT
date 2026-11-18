-- Taleria: Meister Talerons Prüfung (Siegel A nach der Spar-Insel, 18.11.2026).
--
-- CLAUDE.md Abschnitt 8 und INSELN.md „Meister Taleron: Siegel A“: Am Ende
-- jeder Inselgruppe wartet Meister Taleron mit einer großen Wiederholung
-- (12 Fragen aus allen Inseln der Gruppe). Bestehen ist keine Voraussetzung
-- für die nächste Insel, bringt aber einen besonderen Orden (Taleron-Siegel).
--
-- Umsetzung als Begegnung der neuen Art `taleron_trial`:
-- - Sie erscheint auf der Karte, sobald die Insel aus `after_island_id`
--   abgeschlossen ist, und bleibt, bis das Kind das Siegel hat.
-- - content.trial = {"islands": [Slugs], "pass": 9, "badge": "<Slug des Ordens>"}.
-- - Fragen: gleichmäßig aus den Stationen der genannten Inseln, die das Kind
--   geschafft hat (Stations-Checks, Prüfungen, Stopps auf See), zufällig.
-- - Wie bei allen Begegnungen darf das Kind nach einem Fehler nochmal probieren;
--   gewertet wird die erste Antwort je Frage. Ab `pass` richtigen gibt es den
--   Orden und einmalig die Seemeilen der Begegnung.
-- - Normale Kontrollfahrten (next_encounter) liefern Prüfungen nie.
--
-- Mehrfach ausführbar.

alter table public.encounters drop constraint if exists encounters_type_check;
alter table public.encounters add constraint encounters_type_check
  check (type in ('taleron', 'haendlerschiff', 'fischerboot', 'angeberschiff', 'tala_vergisst', 'taleron_trial'));

alter table public.encounters drop constraint if exists encounters_question_count_check;
alter table public.encounters add constraint encounters_question_count_check
  check (question_count between 3 and 12);

-- ---------------------------------------------------------------------------
-- Kontrollfahrten: wie in 20261011000100_taleron_einmal_am_tag.sql, nur ohne Prüfungen.
-- ---------------------------------------------------------------------------

create or replace function public.next_encounter(p_child_id uuid, p_practice boolean default false)
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
  if v_due = 0 and not p_practice then
    return null;
  end if;

  if not p_practice and exists (
    select 1 from public.encounter_runs er
    join public.encounters e on e.id = er.encounter_id
    where er.child_id = p_child_id
      and e.type <> 'taleron_trial'
      and er.finished_at >= public.day_start(public.taleria_today())
  ) then
    return null;
  end if;

  select e.id, e.slug, e.type, e.title, e.asset_key, e.question_count, e.xp_reward, e.content
    into v_encounter
  from public.encounters e
  where public.is_content_visible(e.status, e.publish_at)
    and e.type <> 'taleron_trial'
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

-- ---------------------------------------------------------------------------
-- Meister Talerons Prüfung
-- ---------------------------------------------------------------------------

-- Fragen, die in einer Prüfung vorkommen dürfen: sichtbar, aus einer Station
-- der genannten Inseln, die das Kind geschafft hat. (Intern, für Apps gesperrt.)
create or replace function public.trial_question_pool(p_child_id uuid, p_islands jsonb)
returns table (question_id uuid, island_slug text)
language sql
stable
security definer
set search_path = ''
as $$
  select q.id, i.slug
  from public.quiz_questions q
  join public.stations s on s.id = q.station_id
  join public.islands i on i.id = s.island_id
  where i.slug in (select jsonb_array_elements_text(p_islands))
    and public.question_visible(q.id)
    and public.station_done(p_child_id, s.id);
$$;

revoke execute on function public.trial_question_pool(uuid, jsonb) from public, anon, authenticated;

-- Die Prüfung, die gerade auf das Kind wartet, sonst null. Antwort wie
-- next_encounter(), dazu "trial": {"pass": 9, "badge": {"slug", "title", "asset_key"}}.
create or replace function public.taleron_trial(p_child_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_encounter record;
  v_badge record;
  v_islands jsonb;
  v_per integer;
  v_extra integer;
  v_questions uuid[] := '{}';
  v_slug text;
  v_n integer := 0;
  v_take integer;
  v_part uuid[];
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  for v_encounter in
    select e.id, e.slug, e.type, e.title, e.asset_key, e.question_count, e.xp_reward, e.content
    from public.encounters e
    left join public.islands ai on ai.id = e.after_island_id
    where e.type = 'taleron_trial'
      and public.is_content_visible(e.status, e.publish_at)
      and e.after_island_id is not null
      and exists (
        select 1 from public.island_completions c
        where c.child_id = p_child_id and c.island_id = e.after_island_id
      )
    order by ai.sort_order
  loop
    select b.id, b.slug, b.title, b.asset_key into v_badge
    from public.badges b
    where b.slug = v_encounter.content #>> '{trial,badge}' and public.is_content_visible(b.status, b.publish_at);
    if not found then
      continue;
    end if;
    -- Schon bestanden: Diese Prüfung wartet nicht mehr.
    if exists (select 1 from public.child_badges cb where cb.child_id = p_child_id and cb.badge_id = v_badge.id) then
      continue;
    end if;

    v_islands := coalesce(v_encounter.content #> '{trial,islands}', '[]'::jsonb);
    if jsonb_array_length(v_islands) = 0 then
      continue;
    end if;

    -- Gleich viele Fragen je Insel, der Rest geht an die ersten Inseln.
    v_per := v_encounter.question_count / jsonb_array_length(v_islands);
    v_extra := v_encounter.question_count % jsonb_array_length(v_islands);
    v_questions := '{}';
    v_n := 0;
    for v_slug in select jsonb_array_elements_text(v_islands) loop
      v_take := v_per + case when v_n < v_extra then 1 else 0 end;
      v_n := v_n + 1;
      select coalesce(array_agg(p.question_id), '{}') into v_part
      from (
        select t.question_id from public.trial_question_pool(p_child_id, jsonb_build_array(v_slug)) t
        order by random()
        limit v_take
      ) p;
      v_questions := v_questions || v_part;
    end loop;

    -- Fehlen Fragen einer Insel, mit Fragen der anderen auffüllen.
    if cardinality(v_questions) < v_encounter.question_count then
      select v_questions || coalesce(array_agg(p.question_id), '{}') into v_questions
      from (
        select t.question_id from public.trial_question_pool(p_child_id, v_islands) t
        where t.question_id <> all (v_questions)
        order by random()
        limit v_encounter.question_count - cardinality(v_questions)
      ) p;
    end if;
    if cardinality(v_questions) < v_encounter.question_count then
      continue;
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
      'due_count', 0,
      'trial', jsonb_build_object(
        'pass', coalesce((v_encounter.content #>> '{trial,pass}')::integer, v_encounter.question_count),
        'badge', jsonb_build_object('slug', v_badge.slug, 'title', v_badge.title, 'asset_key', v_badge.asset_key)
      )
    );
  end loop;
  return null;
end;
$$;

revoke execute on function public.taleron_trial(uuid) from public, anon;
grant execute on function public.taleron_trial(uuid) to authenticated;

-- Prüfung abgeben. Antwort wie submit_encounter(), dazu "passed", "pass" und
-- "badge" (nur, wenn das Siegel mit diesem Durchgang neu verliehen wurde).
create or replace function public.submit_taleron_trial(p_child_id uuid, p_encounter_id uuid, p_answers jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_encounter record;
  v_badge record;
  v_islands jsonb;
  v_pass integer;
  v_rank_before text;
  v_rank_after text;
  v_row record;
  v_correct integer := 0;
  v_total integer := 0;
  v_xp integer := 0;
  v_rows integer;
  v_badge_json jsonb;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  select e.id, e.question_count, e.xp_reward, e.content into v_encounter
  from public.encounters e
  where e.id = p_encounter_id
    and e.type = 'taleron_trial'
    and public.is_content_visible(e.status, e.publish_at)
    and exists (
      select 1 from public.island_completions c
      where c.child_id = p_child_id and c.island_id = e.after_island_id
    );
  if not found then
    raise exception 'Prüfung nicht gefunden' using errcode = 'P0002';
  end if;

  if jsonb_typeof(p_answers) <> 'array' or jsonb_array_length(p_answers) <> v_encounter.question_count then
    raise exception 'Falsche Anzahl an Antworten: % erwartet', v_encounter.question_count using errcode = '22023';
  end if;

  v_islands := coalesce(v_encounter.content #> '{trial,islands}', '[]'::jsonb);
  v_pass := coalesce((v_encounter.content #>> '{trial,pass}')::integer, v_encounter.question_count);

  -- Nur Fragen aus den Inseln der Prüfung.
  if exists (
    select 1 from jsonb_array_elements(p_answers) a
    where (a ->> 'question_id')::uuid not in (
      select t.question_id from public.trial_question_pool(p_child_id, v_islands) t
    )
  ) then
    raise exception 'Diese Frage gehört nicht zur Prüfung' using errcode = '22023';
  end if;

  v_rank_before := public.child_rank(p_child_id);

  for v_row in select * from public.checked_review_answers(p_child_id, p_answers) loop
    perform public.record_answer(p_child_id, v_row.question_id, v_row.correct);
    v_total := v_total + 1;
    if v_row.correct then
      v_correct := v_correct + 1;
    end if;
  end loop;

  insert into public.encounter_runs (child_id, encounter_id, correct_count, total)
  values (p_child_id, p_encounter_id, v_correct, v_total);

  if v_correct >= v_pass then
    select b.id, b.slug, b.title, b.asset_key into v_badge
    from public.badges b
    where b.slug = v_encounter.content #>> '{trial,badge}';
    if found then
      insert into public.child_badges (child_id, badge_id)
      values (p_child_id, v_badge.id)
      on conflict on constraint child_badges_once do nothing;
      get diagnostics v_rows = row_count;
      if v_rows > 0 then
        v_badge_json := jsonb_build_object('slug', v_badge.slug, 'title', v_badge.title, 'asset_key', v_badge.asset_key);
      end if;
    end if;

    if v_encounter.xp_reward > 0 then
      insert into public.xp_events (child_id, source_type, source_id, amount)
      values (p_child_id, 'taleron_trial', p_encounter_id, v_encounter.xp_reward)
      on conflict on constraint xp_events_once do nothing;
      get diagnostics v_rows = row_count;
      if v_rows > 0 then
        v_xp := v_encounter.xp_reward;
      end if;
    end if;
  end if;

  perform public.mark_activity(p_child_id);
  v_rank_after := public.child_rank(p_child_id);

  return jsonb_build_object(
    'correct', v_correct,
    'total', v_total,
    'xp_awarded', v_xp,
    'rank_up', case when v_rank_after is distinct from v_rank_before then v_rank_after end,
    'streak_weeks', public.current_streak(p_child_id),
    'passed', v_correct >= v_pass,
    'pass', v_pass,
    'badge', v_badge_json
  );
end;
$$;

revoke execute on function public.submit_taleron_trial(uuid, uuid, jsonb) from public, anon;
grant execute on function public.submit_taleron_trial(uuid, uuid, jsonb) to authenticated;
