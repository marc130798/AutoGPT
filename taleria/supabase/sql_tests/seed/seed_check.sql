-- Prüft die Seed-Daten (supabase/seed.sql) in einer frischen Datenbank:
-- Ein Kind spielt den Hafen komplett durch und besteht die Prüfung der Tauschinsel.

select test_helpers.expect_equal((select count(*) from public.islands where stage = 1), 15,
  'Seed: 15 Inseln in Stufe 1');
select test_helpers.expect_equal((select count(*) from public.stations), 63,
  'Seed: 8 Stationen und 3 Ankerplätze auf Hafen, Tauschinsel, Wunschinsel, Spar-Insel und Taschengeld-Bucht, dazu 8 Stopps auf See');
select test_helpers.expect_true(
  (select array_agg(i.slug || ':' || s.sort_order order by i.sort_order, s.sort_order)
     = '{tauschinsel:1,tauschinsel:2,wunschinsel:1,wunschinsel:2,spar-insel:1,spar-insel:2,taschengeld-bucht:1,taschengeld-bucht:2}'
   from public.stations s join public.islands i on i.id = s.island_id
   where s.type = 'sea_stop'),
  'Seed: je zwei Stopps auf See vor Tauschinsel, Wunschinsel, Spar-Insel und Taschengeld-Bucht, vor ihrer ersten Station');
select test_helpers.expect_equal((select count(*) from public.collectibles), 15,
  'Seed: 15 Funde für die Unterwasser-Sammlung');
select test_helpers.expect_true(
  (select array_agg(s.sort_order order by s.sort_order) = '{25,45,65}'
   from public.stations s join public.islands i on i.id = s.island_id
   where i.slug = 'hafen' and s.type = 'review_stop'),
  'Seed: Ankerplätze im Hafen nach Station 2, 4 und 6');
select test_helpers.expect_equal((select count(*) from public.quiz_questions), 370,
  'Seed: 370 Fragen (322 auf den Inseln, 48 bei den Stopps auf See)');
select test_helpers.expect_true((select bool_and(status = 'draft') from public.islands),
  'Seed: alles sind Entwürfe');

insert into auth.users (id, email, raw_user_meta_data) values
  ('a5000000-0000-0000-0000-000000000001', 'seed@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('d5000000-0000-0000-0000-000000000001', true);
insert into public.children (id, parent_id, nickname, birth_year)
select 'c5000000-0000-0000-0000-000000000001', p.id, 'Seed', 2015 from public.parents p;
insert into public.child_devices (user_id, child_id)
values ('d5000000-0000-0000-0000-000000000001', 'c5000000-0000-0000-0000-000000000001');
-- Freie Fahrt, damit das Kind alle Stationen am Stück spielen kann.
update public.children set stations_per_week = null where id = 'c5000000-0000-0000-0000-000000000001';

-- Hilfsfunktion: richtige Antworten (Index 0) für die ersten n Fragen einer Station.
create function test_helpers.correct_answers(p_slug text, p_station int, p_count int)
returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object('question_id', q.id, 'answer_index', q.correct_index))
  from (
    select q.id, q.correct_index
    from public.quiz_questions q
    join public.stations s on s.id = q.station_id
    join public.islands i on i.id = s.island_id
    where i.slug = p_slug and s.sort_order = p_station * 10
    order by q.id
    limit p_count
  ) q;
$$;
grant execute on function test_helpers.correct_answers(text, int, int) to authenticated;

-- Spielt alle Stationen und Ankerplätze einer Insel bis vor die Prüfung, alles richtig.
-- Ankerplätze bekommen Fragen der Stationen seit dem letzten Ankerplatz.
create function test_helpers.play_island(p_child uuid, p_slug text)
returns integer language plpgsql as $$
declare
  v_station record;
  v_answers jsonb;
  v_result jsonb;
  v_prev integer := -1;
  v_played integer := 0;
begin
  for v_station in
    select s.id, s.sort_order, s.type, s.content
    from public.stations s join public.islands i on i.id = s.island_id
    where i.slug = p_slug and s.type <> 'exam' and coalesce(s.content ->> 'kind', '') <> 'onboarding'
    order by s.sort_order
  loop
    if v_station.type = 'sea_stop' then
      select jsonb_agg(jsonb_build_object('question_id', q.id, 'answer_index', q.correct_index))
        into v_answers
      from (
        select q.id, q.correct_index from public.quiz_questions q
        where q.station_id = v_station.id
        order by q.id
        limit (v_station.content -> 'quiz' ->> 'show')::int
      ) q;
    elsif v_station.type = 'review_stop' then
      select jsonb_agg(jsonb_build_object('question_id', q.id, 'answer_index', q.correct_index))
        into v_answers
      from (
        select q.id, q.correct_index
        from public.quiz_questions q join public.stations s on s.id = q.station_id
        where s.island_id = (select island_id from public.stations where id = v_station.id)
          and s.type not in ('exam', 'review_stop', 'sea_stop') and s.sort_order > v_prev and s.sort_order < v_station.sort_order
        order by q.id
        limit (v_station.content -> 'dive' ->> 'questions')::int
      ) q;
      v_prev := v_station.sort_order;
    else
      v_answers := test_helpers.correct_answers(p_slug, v_station.sort_order / 10,
        (v_station.content -> 'quiz' ->> 'show')::int);
    end if;
    v_result := public.submit_station(p_child, v_station.id, v_answers);
    if (v_result ->> 'passed')::boolean is not true then
      raise exception '% Station % nicht erledigt: %', p_slug, v_station.sort_order, v_result;
    end if;
    v_played := v_played + 1;
  end loop;
  return v_played;
end;
$$;
grant execute on function test_helpers.play_island(uuid, text) to authenticated;

select test_helpers.login('d5000000-0000-0000-0000-000000000001', 'aal1', true);

select test_helpers.expect_equal(
  (select count(*) from public.map_islands(1::smallint) where has_content), 5,
  'Seed: In der Vorschau sind Hafen, Tauschinsel, Wunschinsel, Spar-Insel und Taschengeld-Bucht spielbar');
select test_helpers.expect_equal(
  (select count(*) from public.map_islands(1::smallint) where not has_content), 10,
  'Seed: Inseln 6 bis 15 liegen im Nebel');

select test_helpers.expect_equal(public.complete_onboarding('c5000000-0000-0000-0000-000000000001'), 50,
  'Seed: Intro ist Station 1 des Hafens (50 Seemeilen)');

select test_helpers.expect_equal(test_helpers.play_island('c5000000-0000-0000-0000-000000000001', 'hafen'), 9,
  'Seed: Hafen Stationen 2 bis 7 und 3 Ankerplätze nacheinander gespielt');
select test_helpers.expect_equal(
  (select count(*) from public.station_progress where status = 'done'), 10,
  'Seed: Hafen-Stationen 1 bis 7 und 3 Ankerplätze erledigt');
select test_helpers.expect_true(
  (select (s ->> 'finds')::int = 3 and (s ->> 'pearls')::int = 12
   from public.child_stats('c5000000-0000-0000-0000-000000000001') s),
  'Seed: 3 Funde und 12 Perlen aus den Tauchgängen im Hafen');

select test_helpers.expect_true(
  (select r ->> 'passed' = 'true' and r ->> 'island_completed' = 'true'
      and r -> 'badge' ->> 'title' = 'Erster Landgang' and r -> 'badge' ->> 'asset_key' = 'badge.hafen'
   from (select public.submit_station('c5000000-0000-0000-0000-000000000001',
     (select s.id from public.stations s join public.islands i on i.id = s.island_id where i.slug = 'hafen' and s.type = 'exam'),
     test_helpers.correct_answers('hafen', 8, 10)) r) x),
  'Seed: Hafen-Prüfung (10 Fragen) bestanden, Hafen abgeschlossen, Orden „Erster Landgang“');

-- Tauschinsel: erst die 2 Stopps auf See, dann Stationen 1 bis 7 mit Ankerplätzen,
-- dann Prüfung mit 8 eigenen und 2 Rückblick-Fragen.
select test_helpers.expect_equal(test_helpers.play_island('c5000000-0000-0000-0000-000000000001', 'tauschinsel'), 12,
  'Seed: Tauschinsel 2 Stopps auf See, Stationen 1 bis 7 und 3 Ankerplätze gespielt');

select test_helpers.expect_true(
  (select r ->> 'passed' = 'true' and r ->> 'correct' = '10' and r ->> 'island_completed' = 'true'
   from (select public.submit_station('c5000000-0000-0000-0000-000000000001',
     (select s.id from public.stations s join public.islands i on i.id = s.island_id where i.slug = 'tauschinsel' and s.type = 'exam'),
     test_helpers.correct_answers('tauschinsel', 8, 8) || test_helpers.correct_answers('hafen', 8, 2)) r) x),
  'Seed: Tauschinsel-Prüfung mit 2 Rückblick-Fragen aus dem Hafen bestanden');

select test_helpers.expect_equal(
  (select sum(amount) from public.xp_events), 50 + 6 * 100 + 150 + 7 * 100 + 150 + 6 * 50 + 2 * 30,
  'Seed: Seemeilen aus Hafen und Tauschinsel, mit 6 Tauchgängen und 2 Stopps auf See');
select test_helpers.expect_true(
  (select s ->> 'rank' = 'matrose' and (s ->> 'badge_count')::int = 2 from public.child_stats('c5000000-0000-0000-0000-000000000001') s),
  'Seed: nach zwei Inseln Rang Matrose mit zwei Orden');
select test_helpers.logout();

-- Am nächsten Tag sind Wiederholungen fällig: Meister Taleron taucht auf.
update public.question_reviews set due_at = now() - interval '1 hour';
select test_helpers.login('d5000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select e -> 'encounter' ->> 'title' = 'Meister Taleron' and e ->> 'first_meeting' = 'true'
      and jsonb_array_length(e -> 'encounter' -> 'content' -> 'first_scene') > 0
   from (select public.next_encounter('c5000000-0000-0000-0000-000000000001') e) x),
  'Seed: erste Begegnung mit Meister Taleron');
select test_helpers.logout();

-- Meister Talerons Prüfung (Siegel A) nach der Spar-Insel (18.11.2026).
select test_helpers.logout();
insert into public.children (id, parent_id, nickname, birth_year)
select 'c5000000-0000-0000-0000-000000000002', p.id, 'Siegel', 2015 from public.parents p;
insert into auth.users (id, is_anonymous) values ('d5000000-0000-0000-0000-000000000002', true);
insert into public.child_devices (user_id, child_id)
values ('d5000000-0000-0000-0000-000000000002', 'c5000000-0000-0000-0000-000000000002');
-- Inseln 1 bis 3 fertig: noch keine Prüfung.
insert into public.station_progress (child_id, station_id, status, completed_at)
select 'c5000000-0000-0000-0000-000000000002', s.id, 'done', now()
from public.stations s join public.islands i on i.id = s.island_id
where i.slug in ('hafen', 'tauschinsel', 'wunschinsel', 'spar-insel');
insert into public.island_completions (child_id, island_id)
select 'c5000000-0000-0000-0000-000000000002', i.id from public.islands i
where i.slug in ('hafen', 'tauschinsel', 'wunschinsel');

select test_helpers.login('d5000000-0000-0000-0000-000000000002', 'aal1', true);
select test_helpers.expect_true(public.taleron_trial('c5000000-0000-0000-0000-000000000002') is null,
  'Prüfung: vor dem Abschluss der Spar-Insel wartet sie nicht');
select test_helpers.logout();
insert into public.island_completions (child_id, island_id)
select 'c5000000-0000-0000-0000-000000000002', i.id from public.islands i where i.slug = 'spar-insel';

select test_helpers.login('d5000000-0000-0000-0000-000000000002', 'aal1', true);
create temp table trial_offer as
select public.taleron_trial('c5000000-0000-0000-0000-000000000002') as o;
select test_helpers.expect_equal((select jsonb_array_length(o -> 'question_ids') from trial_offer), 12,
  'Prüfung: 12 Fragen');
select test_helpers.expect_true(
  (select bool_and(n = 3) from (
     select count(*) n from trial_offer, jsonb_array_elements_text(o -> 'question_ids') q
     join public.quiz_questions qq on qq.id = q::uuid
     join public.stations s on s.id = qq.station_id
     join public.islands i on i.id = s.island_id
     group by i.slug) x)
  and (select count(distinct q) from trial_offer, jsonb_array_elements_text(o -> 'question_ids') q) = 12,
  'Prüfung: je 3 verschiedene Fragen aus Hafen, Tauschinsel, Wunschinsel und Spar-Insel');
select test_helpers.expect_equal((select (o #>> '{trial,pass}')::int from trial_offer), 9, 'Prüfung: bestanden ab 9');
select test_helpers.expect_true(
  (select o #>> '{trial,badge,slug}' = 'taleron-siegel-a' from trial_offer), 'Prüfung: Siegel A als Orden');

-- 8 richtig: nicht bestanden, kein Orden, Prüfung bleibt.
create temp table trial_fail as
select public.submit_taleron_trial('c5000000-0000-0000-0000-000000000002', (o #>> '{encounter,id}')::uuid,
  (select jsonb_agg(jsonb_build_object('question_id', q.id,
     'answer_index', case when x.n <= 8 then q.correct_index else (q.correct_index + 1) % 3 end))
   from trial_offer, jsonb_array_elements_text(o -> 'question_ids') with ordinality x(id, n)
   join public.quiz_questions q on q.id = x.id::uuid)) as r
from trial_offer;
select test_helpers.expect_true((select not (r ->> 'passed')::boolean and r -> 'badge' = 'null'::jsonb
  and (r ->> 'xp_awarded')::int = 0 from trial_fail), 'Prüfung: 8 von 12 reichen nicht, kein Orden');
select test_helpers.expect_true(public.taleron_trial('c5000000-0000-0000-0000-000000000002') is not null,
  'Prüfung: Taleron wartet weiter');

-- Alle richtig: Siegel und 150 Seemeilen, danach keine Prüfung mehr.
create temp table trial_pass as
select public.submit_taleron_trial('c5000000-0000-0000-0000-000000000002', (o #>> '{encounter,id}')::uuid,
  (select jsonb_agg(jsonb_build_object('question_id', q.id, 'answer_index', q.correct_index))
   from trial_offer, jsonb_array_elements_text(o -> 'question_ids') x(id)
   join public.quiz_questions q on q.id = x.id::uuid)) as r
from trial_offer;
select test_helpers.expect_true((select (r ->> 'passed')::boolean and r #>> '{badge,slug}' = 'taleron-siegel-a'
  and (r ->> 'xp_awarded')::int = 150 from trial_pass), 'Prüfung: bestanden, Siegel A und 150 Seemeilen');
select test_helpers.expect_true(public.taleron_trial('c5000000-0000-0000-0000-000000000002') is null,
  'Prüfung: mit Siegel wartet sie nicht mehr');
select test_helpers.expect_error(
  $$select public.submit_taleron_trial('c5000000-0000-0000-0000-000000000002',
    (select (o #>> '{encounter,id}')::uuid from trial_offer),
    (select jsonb_agg(jsonb_build_object('question_id', q.id, 'answer_index', 0))
     from (select q.id from public.quiz_questions q join public.stations s on s.id = q.station_id
           join public.islands i on i.id = s.island_id where i.slug = 'taschengeld-bucht' limit 12) q))$$,
  'gehört nicht zur Prüfung', 'Prüfung: nur Fragen der vier Inseln');
select test_helpers.expect_true(
  coalesce(public.next_encounter('c5000000-0000-0000-0000-000000000002', true) #>> '{encounter,type}', '') <> 'taleron_trial',
  'Prüfung: Kontrollfahrten liefern nie die Prüfung');
select test_helpers.logout();
