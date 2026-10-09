-- Prüft die Seed-Daten (supabase/seed.sql) in einer frischen Datenbank:
-- Ein Kind spielt den Hafen komplett durch und besteht die Prüfung der Tauschinsel.

select test_helpers.expect_equal((select count(*) from public.islands where stage = 1), 15,
  'Seed: 15 Inseln in Stufe 1');
select test_helpers.expect_equal((select count(*) from public.stations), 24,
  'Seed: 8 Stationen auf Hafen, Tauschinsel und Wunschinsel');
select test_helpers.expect_equal((select count(*) from public.quiz_questions), 184,
  'Seed: 184 Fragen');
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

-- Hilfsfunktion: richtige Antworten (Index 0) für die ersten n Fragen einer Station.
create function test_helpers.correct_answers(p_slug text, p_station int, p_count int)
returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object('question_id', q.id, 'answer_index', q.correct_index))
  from (
    select q.id, q.correct_index
    from public.quiz_questions q
    join public.stations s on s.id = q.station_id
    join public.islands i on i.id = s.island_id
    where i.slug = p_slug and s.sort_order = p_station
    order by q.id
    limit p_count
  ) q;
$$;
grant execute on function test_helpers.correct_answers(text, int, int) to authenticated;

select test_helpers.login('d5000000-0000-0000-0000-000000000001', 'aal1', true);

select test_helpers.expect_equal(
  (select count(*) from public.map_islands(1::smallint) where has_content), 3,
  'Seed: In der Vorschau sind Hafen, Tauschinsel und Wunschinsel spielbar');
select test_helpers.expect_equal(
  (select count(*) from public.map_islands(1::smallint) where not has_content), 12,
  'Seed: Inseln 4 bis 15 liegen im Nebel');

select test_helpers.expect_equal(public.complete_onboarding('c5000000-0000-0000-0000-000000000001'), 50,
  'Seed: Intro ist Station 1 des Hafens (50 Seemeilen)');

do $$
declare
  v_result jsonb;
  v_station int;
  v_show int;
  v_station_id uuid;
begin
  for v_station in 2..7 loop
    select s.id, (s.content -> 'quiz' ->> 'show')::int into v_station_id, v_show
    from public.stations s join public.islands i on i.id = s.island_id
    where i.slug = 'hafen' and s.sort_order = v_station;
    v_result := public.submit_station('c5000000-0000-0000-0000-000000000001', v_station_id,
      test_helpers.correct_answers('hafen', v_station, v_show));
    if (v_result ->> 'passed')::boolean is not true then
      raise exception 'Hafen Station % nicht erledigt: %', v_station, v_result;
    end if;
  end loop;
end;
$$;
select test_helpers.expect_equal(
  (select count(*) from public.station_progress where status = 'done'), 7,
  'Seed: Hafen-Stationen 1 bis 7 nacheinander erledigt');

select test_helpers.expect_true(
  (select r ->> 'passed' = 'true' and r ->> 'island_completed' = 'true'
   from (select public.submit_station('c5000000-0000-0000-0000-000000000001',
     (select s.id from public.stations s join public.islands i on i.id = s.island_id where i.slug = 'hafen' and s.type = 'exam'),
     test_helpers.correct_answers('hafen', 8, 10)) r) x),
  'Seed: Hafen-Prüfung (10 Fragen) bestanden, Hafen abgeschlossen');

-- Tauschinsel: Stationen 1 bis 7, dann Prüfung mit 8 eigenen und 2 Rückblick-Fragen aus dem Hafen.
do $$
declare
  v_result jsonb;
  v_station int;
  v_station_id uuid;
begin
  for v_station in 1..7 loop
    select s.id into v_station_id
    from public.stations s join public.islands i on i.id = s.island_id
    where i.slug = 'tauschinsel' and s.sort_order = v_station;
    v_result := public.submit_station('c5000000-0000-0000-0000-000000000001', v_station_id,
      test_helpers.correct_answers('tauschinsel', v_station, 3));
    if (v_result ->> 'passed')::boolean is not true then
      raise exception 'Tauschinsel Station % nicht erledigt: %', v_station, v_result;
    end if;
  end loop;
end;
$$;

select test_helpers.expect_true(
  (select r ->> 'passed' = 'true' and r ->> 'correct' = '10' and r ->> 'island_completed' = 'true'
   from (select public.submit_station('c5000000-0000-0000-0000-000000000001',
     (select s.id from public.stations s join public.islands i on i.id = s.island_id where i.slug = 'tauschinsel' and s.type = 'exam'),
     test_helpers.correct_answers('tauschinsel', 8, 8) || test_helpers.correct_answers('hafen', 8, 2)) r) x),
  'Seed: Tauschinsel-Prüfung mit 2 Rückblick-Fragen aus dem Hafen bestanden');

select test_helpers.expect_equal(
  (select sum(amount) from public.xp_events), 50 + 6 * 100 + 150 + 7 * 100 + 150,
  'Seed: Seemeilen aus Hafen und Tauschinsel');
select test_helpers.logout();
