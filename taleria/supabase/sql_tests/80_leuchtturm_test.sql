-- Tests für den Lernstand im Leuchtturm (Schritt 8).
-- Ausführen mit: tool/db_test.sh
--
-- Nutzt Ben und die Tauchinsel aus 70_tauchgaenge_test.sql. Der Wiederholungsplan
-- wird als Datenbank-Besitzer gezielt eingestellt.

-- Stationsnummern wie in den Seed-Daten; die Prüfungsfrage deckt Station 3 ab.
update public.stations set content = content || jsonb_build_object('number', sort_order / 10)
where island_id = 'e8000000-0000-0000-0000-00000000000a' and type <> 'review_stop';
update public.quiz_questions set covers_station = 3 where id = '98000000-0000-0000-0000-000000000041';

update public.question_reviews r set last_correct = v.correct, correct_streak = v.streak
from (values
  ('98000000-0000-0000-0000-000000000011'::uuid, true, 2),
  ('98000000-0000-0000-0000-000000000012'::uuid, false, 0),
  ('98000000-0000-0000-0000-000000000021'::uuid, true, 1),
  ('98000000-0000-0000-0000-000000000022'::uuid, true, 3),
  ('98000000-0000-0000-0000-000000000031'::uuid, true, 1),
  ('98000000-0000-0000-0000-000000000032'::uuid, true, 1),
  ('98000000-0000-0000-0000-000000000041'::uuid, true, 1)
) as v(question_id, correct, streak)
where r.child_id = 'c8000000-0000-0000-0000-000000000001' and r.question_id = v.question_id;

create function test_helpers.ben_topic(p_station uuid)
returns text language sql as $$
  select format('%s/%s/%s/%s', answered, secure, learning, shaky)
  from public.learning_status('c8000000-0000-0000-0000-000000000001')
  where station_id = p_station;
$$;
grant execute on function test_helpers.ben_topic(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------

select test_helpers.login('d8000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_error($$select * from public.learning_status('c8000000-0000-0000-0000-000000000001')$$,
  'Nur für Eltern', 'Das Kind sieht seinen Lernstand nicht im Leuchtturm-Format');
select test_helpers.expect_true(
  (public.child_stats('c8000000-0000-0000-0000-000000000001') ->> 'last_active_at') is not null,
  'Statistik kennt den letzten Tag an Bord');
select test_helpers.logout();

select test_helpers.login('a8000000-0000-0000-0000-000000000002');
select test_helpers.expect_error($$select * from public.learning_status('c8000000-0000-0000-0000-000000000001')$$,
  'Nur für Eltern', 'Fremde Eltern sehen keinen Lernstand');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Lernstand pro Station (gefragt / sicher / geübt / wackelt)
-- ---------------------------------------------------------------------------

select test_helpers.login('a8000000-0000-0000-0000-000000000001');
select test_helpers.expect_true(test_helpers.ben_topic('f8000000-0000-0000-0000-000000000010') = '2/1/0/1',
  'Station 1: eine Frage sicher, eine wackelt');
select test_helpers.expect_true(test_helpers.ben_topic('f8000000-0000-0000-0000-000000000020') = '2/1/1/0',
  'Station 2: eine sicher, eine wird geübt');
select test_helpers.expect_true(test_helpers.ben_topic('f8000000-0000-0000-0000-000000000030') = '3/0/3/0',
  'Station 3: mit der Prüfungsfrage, die Station 3 abdeckt');
select test_helpers.expect_equal(
  (select count(*) from public.learning_status('c8000000-0000-0000-0000-000000000001')
   where station_id in (
     select id from public.stations where type in ('exam', 'review_stop')
   )), 0,
  'Prüfungen und Ankerplätze sind keine eigenen Themen');
select test_helpers.logout();
