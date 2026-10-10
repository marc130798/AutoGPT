-- Tests für Stopps auf See (Pflicht vor der ersten Station einer Insel).
-- Ausführen mit: tool/db_test.sh
--
-- Eigene Nebeninsel in Stufe 2 (Reihenfolge 0, also offen), damit die anderen
-- Testinseln unverändert bleiben.

insert into auth.users (id, email, raw_user_meta_data) values
  ('ab000000-0000-0000-0000-000000000001', 'see1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('db000000-0000-0000-0000-000000000001', true);

insert into public.children (id, parent_id, nickname, birth_year, stage)
select 'cb000000-0000-0000-0000-000000000001', p.id, 'Ida', 2014, 2
from public.parents p where p.user_id = 'ab000000-0000-0000-0000-000000000001';
insert into public.child_devices (user_id, child_id)
values ('db000000-0000-0000-0000-000000000001', 'cb000000-0000-0000-0000-000000000001');

insert into public.islands (id, slug, stage, sort_order, title, route_type, status) values
  ('eb000000-0000-0000-0000-00000000000a', 'stoppinsel', 2, 0, 'Stoppinsel', 'side', 'draft');

-- Zwei Stopps auf See, dann die erste Station der Insel.
insert into public.stations (id, island_id, sort_order, type, xp_reward, content, status) values
  ('fb000000-0000-0000-0000-000000000001', 'eb000000-0000-0000-0000-00000000000a', 1, 'sea_stop', 30,
   '{"kind": "sea_stop", "quiz": {"show": 1}}', 'published'),
  ('fb000000-0000-0000-0000-000000000002', 'eb000000-0000-0000-0000-00000000000a', 2, 'sea_stop', 30,
   '{"kind": "sea_stop", "quiz": {"show": 1}}', 'published'),
  ('fb000000-0000-0000-0000-000000000010', 'eb000000-0000-0000-0000-00000000000a', 10, 'quiz', 100,
   '{"quiz": {"show": 1}}', 'published');

insert into public.quiz_questions (id, station_id, question, answers, correct_index, status) values
  ('9b000000-0000-0000-0000-000000000011', 'fb000000-0000-0000-0000-000000000001', 'See 1', '["r", "f", "f"]', 0, 'published'),
  ('9b000000-0000-0000-0000-000000000021', 'fb000000-0000-0000-0000-000000000002', 'See 2', '["r", "f", "f"]', 0, 'published'),
  ('9b000000-0000-0000-0000-000000000101', 'fb000000-0000-0000-0000-000000000010', 'Station 1', '["r", "f", "f"]', 0, 'published');

update public.islands set status = 'published' where id = 'eb000000-0000-0000-0000-00000000000a';

create function test_helpers.ida_wind() returns int language sql as $$
  select (public.child_stats('cb000000-0000-0000-0000-000000000001') -> 'pace' ->> 'wind')::int;
$$;
grant execute on function test_helpers.ida_wind() to authenticated;

select test_helpers.login('db000000-0000-0000-0000-000000000001', 'aal1', true);
select public.complete_onboarding('cb000000-0000-0000-0000-000000000001');

select test_helpers.expect_error(
  $$select public.submit_station('cb000000-0000-0000-0000-000000000001', 'fb000000-0000-0000-0000-000000000010',
      test_helpers.answers('9b000000-0000-0000-0000-000000000101:0'))$$,
  'gesperrt', 'Die erste Station wartet, bis die Stopps auf See geschafft sind');
select test_helpers.expect_error(
  $$select public.submit_station('cb000000-0000-0000-0000-000000000001', 'fb000000-0000-0000-0000-000000000002',
      test_helpers.answers('9b000000-0000-0000-0000-000000000021:0'))$$,
  'gesperrt', 'Die Stopps kommen der Reihe nach');

create temp table ida_wind_before as select test_helpers.ida_wind() as wind;

-- Auch mit einer falschen Antwort ist der Stopp geschafft (Fehler kosten nichts).
select test_helpers.expect_true(
  (public.submit_station('cb000000-0000-0000-0000-000000000001', 'fb000000-0000-0000-0000-000000000001',
     test_helpers.answers('9b000000-0000-0000-0000-000000000011:1')) ->> 'passed')::boolean,
  'Stopp auf See ist nach dem Durchgang geschafft');
select test_helpers.expect_equal(
  (public.submit_station('cb000000-0000-0000-0000-000000000001', 'fb000000-0000-0000-0000-000000000002',
     test_helpers.answers('9b000000-0000-0000-0000-000000000021:0')) ->> 'xp_awarded')::int,
  30, 'Stopp auf See bringt Seemeilen');
select test_helpers.expect_equal(test_helpers.ida_wind(), (select wind from ida_wind_before),
  'Stopps auf See brauchen keinen Wind');

select test_helpers.expect_true(
  (public.submit_station('cb000000-0000-0000-0000-000000000001', 'fb000000-0000-0000-0000-000000000010',
     test_helpers.answers('9b000000-0000-0000-0000-000000000101:0')) ->> 'passed')::boolean,
  'Nach den Stopps geht es auf der Insel weiter');
select test_helpers.expect_equal(test_helpers.ida_wind(), (select wind from ida_wind_before) - 1,
  'Die erste Station der Insel braucht wie immer Wind');

select test_helpers.logout();

select test_helpers.expect_error(
  $$insert into public.stations (island_id, sort_order, type, is_required, content)
    values ('eb000000-0000-0000-0000-00000000000a', 3, 'piratenstopp', false, '{}')$$,
  'stations_type_check', 'Unbekannte Stationstypen bleiben verboten');

do $$ begin raise notice 'ok: Stopps auf See'; end $$;
