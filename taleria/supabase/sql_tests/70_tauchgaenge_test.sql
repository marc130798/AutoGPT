-- Tests für Ankerplätze (Tauchgänge), Unterwasser-Sammlung und Übungs-Begegnung (Schritt 7).
-- Ausführen mit: tool/db_test.sh
--
-- Eigene Nebeninsel in Stufe 2 (Reihenfolge 0, also offen), damit die Inseln
-- aus 40_fortschritt_test.sql unverändert bleiben. Nutzt test_helpers.answers.

-- ---------------------------------------------------------------------------
-- Testdaten
-- ---------------------------------------------------------------------------

insert into auth.users (id, email, raw_user_meta_data) values
  ('a8000000-0000-0000-0000-000000000001', 'tauch1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('a8000000-0000-0000-0000-000000000002', 'tauch2@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('d8000000-0000-0000-0000-000000000001', true);

insert into public.children (id, parent_id, nickname, birth_year, stage)
select 'c8000000-0000-0000-0000-000000000001', p.id, 'Ben', 2014, 2
from public.parents p where p.user_id = 'a8000000-0000-0000-0000-000000000001';
insert into public.child_devices (user_id, child_id)
values ('d8000000-0000-0000-0000-000000000001', 'c8000000-0000-0000-0000-000000000001');

insert into public.islands (id, slug, stage, sort_order, title, route_type, status) values
  ('e8000000-0000-0000-0000-00000000000a', 'tauchinsel', 2, 0, 'Tauchinsel', 'side', 'draft');

-- Station 1, Station 2, Ankerplatz, Station 3, Ankerplatz, Prüfung
insert into public.stations (id, island_id, sort_order, type, xp_reward, content, status) values
  ('f8000000-0000-0000-0000-000000000010', 'e8000000-0000-0000-0000-00000000000a', 10, 'quiz', 100,
   '{"quiz": {"show": 1}}', 'published'),
  ('f8000000-0000-0000-0000-000000000020', 'e8000000-0000-0000-0000-00000000000a', 20, 'quiz', 100,
   '{"quiz": {"show": 1}}', 'published'),
  ('f8000000-0000-0000-0000-000000000025', 'e8000000-0000-0000-0000-00000000000a', 25, 'review_stop', 50,
   '{"kind": "dive", "dive": {"questions": 3}}', 'published'),
  ('f8000000-0000-0000-0000-000000000030', 'e8000000-0000-0000-0000-00000000000a', 30, 'quiz', 100,
   '{"quiz": {"show": 1}}', 'published'),
  ('f8000000-0000-0000-0000-000000000035', 'e8000000-0000-0000-0000-00000000000a', 35, 'review_stop', 50,
   '{"kind": "dive", "dive": {"questions": 2}}', 'published'),
  ('f8000000-0000-0000-0000-000000000040', 'e8000000-0000-0000-0000-00000000000a', 40, 'exam', 150,
   '{"exam": {"show": 1, "review": 0, "pass": 1}}', 'published');

insert into public.quiz_questions (id, station_id, question, answers, correct_index, status) values
  ('98000000-0000-0000-0000-000000000011', 'f8000000-0000-0000-0000-000000000010', 'S1 Frage 1', '["r", "f", "f"]', 0, 'published'),
  ('98000000-0000-0000-0000-000000000012', 'f8000000-0000-0000-0000-000000000010', 'S1 Frage 2', '["r", "f", "f"]', 0, 'published'),
  ('98000000-0000-0000-0000-000000000021', 'f8000000-0000-0000-0000-000000000020', 'S2 Frage 1', '["r", "f", "f"]', 0, 'published'),
  ('98000000-0000-0000-0000-000000000022', 'f8000000-0000-0000-0000-000000000020', 'S2 Frage 2', '["r", "f", "f"]', 0, 'published'),
  ('98000000-0000-0000-0000-000000000031', 'f8000000-0000-0000-0000-000000000030', 'S3 Frage 1', '["r", "f", "f"]', 0, 'published'),
  ('98000000-0000-0000-0000-000000000032', 'f8000000-0000-0000-0000-000000000030', 'S3 Frage 2', '["r", "f", "f"]', 0, 'published'),
  ('98000000-0000-0000-0000-000000000041', 'f8000000-0000-0000-0000-000000000040', 'P Frage 1', '["r", "f", "f"]', 0, 'published'),
  ('98000000-0000-0000-0000-000000000042', 'f8000000-0000-0000-0000-000000000040', 'P Frage 2', '["r", "f", "f"]', 0, 'published');

update public.islands set status = 'published' where id = 'e8000000-0000-0000-0000-00000000000a';

insert into public.collectibles (slug, kind, title, asset_key, station_id, status) values
  ('test-muenze', 'wreck_item', 'Alte Münze', 'collectible.wreck_item', 'f8000000-0000-0000-0000-000000000025', 'published'),
  ('test-kompass', 'wreck_item', 'Alter Kompass', 'collectible.wreck_item', 'f8000000-0000-0000-0000-000000000035', 'draft');

create function test_helpers.ben_stats() returns jsonb language sql as $$
  select public.child_stats('c8000000-0000-0000-0000-000000000001');
$$;
grant execute on function test_helpers.ben_stats() to authenticated;

-- ---------------------------------------------------------------------------
-- Ankerplatz nach zwei Stationen
-- ---------------------------------------------------------------------------

select test_helpers.login('d8000000-0000-0000-0000-000000000001', 'aal1', true);
select public.complete_onboarding('c8000000-0000-0000-0000-000000000001');

select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000010',
  test_helpers.answers('98000000-0000-0000-0000-000000000011:0'));
select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000020',
  test_helpers.answers('98000000-0000-0000-0000-000000000021:0'));
select test_helpers.expect_equal((test_helpers.ben_stats() -> 'pace' ->> 'wind')::int, 0,
  'Nach zwei neuen Stationen ist der Wind verbraucht');

select test_helpers.expect_error(
  $$select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000030',
      test_helpers.answers('98000000-0000-0000-0000-000000000031:0'))$$,
  'gesperrt', 'Station 3 wartet, bis der Ankerplatz geschafft ist');

select test_helpers.expect_error(
  $$select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000025',
      test_helpers.answers('98000000-0000-0000-0000-000000000011:0', '98000000-0000-0000-0000-000000000021:0'))$$,
  'Falsche Anzahl', 'Tauchgang braucht alle Fragen (hier 3)');
select test_helpers.expect_error(
  $$select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000025',
      test_helpers.answers('98000000-0000-0000-0000-000000000011:0', '98000000-0000-0000-0000-000000000021:0',
                           '98000000-0000-0000-0000-000000000031:0'))$$,
  'gehört nicht', 'Tauchgang nur mit Fragen der Stationen davor');
select test_helpers.expect_error(
  $$select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000025',
      test_helpers.answers('98000000-0000-0000-0000-000000000011:0', '98000000-0000-0000-0000-000000000021:0',
                           '98000000-0000-0000-0000-000000000041:0'))$$,
  'gehört nicht', 'Tauchgang ohne Prüfungsfragen');

select test_helpers.expect_true(
  (select r ->> 'passed' = 'true' and r ->> 'correct' = '2' and r ->> 'xp_awarded' = '50'
      and r -> 'find' ->> 'title' = 'Alte Münze' and r ->> 'wind_left' is null
   from (select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000025',
     test_helpers.answers('98000000-0000-0000-0000-000000000011:0', '98000000-0000-0000-0000-000000000012:2',
                          '98000000-0000-0000-0000-000000000022:0')) r) x),
  'Tauchgang ohne Wind: erledigt auch mit Fehlern, 50 Seemeilen, Fund „Alte Münze“');
select test_helpers.expect_true(
  (select (s ->> 'pearls')::int = 2 and (s ->> 'finds')::int = 1 from test_helpers.ben_stats() s),
  'Zwei richtige Antworten sind zwei Perlen, dazu ein Fund');
select test_helpers.expect_equal(
  (select count(*) from public.question_reviews where child_id = 'c8000000-0000-0000-0000-000000000001'
     and question_id = '98000000-0000-0000-0000-000000000012'), 1,
  'Antworten aus dem Tauchgang fließen in den Wiederholungsplan');

select test_helpers.expect_true(
  (select r ->> 'xp_awarded' = '0' and r ->> 'find' is null and r ->> 'correct' = '3'
   from (select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000025',
     test_helpers.answers('98000000-0000-0000-0000-000000000011:0', '98000000-0000-0000-0000-000000000012:0',
                          '98000000-0000-0000-0000-000000000021:0')) r) x),
  'Nochmal tauchen: keine Seemeilen und kein doppelter Fund');
select test_helpers.expect_true(
  (select (s ->> 'pearls')::int = 3 and (s ->> 'finds')::int = 1 from test_helpers.ben_stats() s),
  'Perlen zählen den besten Tauchgang');

select test_helpers.expect_error(
  $$select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000030',
      test_helpers.answers('98000000-0000-0000-0000-000000000031:0'))$$,
  'braucht Wind', 'Nach dem Ankerplatz braucht die nächste Station wieder Wind');
select test_helpers.logout();

-- Neuer Wind: Station 3, dann zweiter Ankerplatz nur mit Fragen von Station 3.
update public.pace_state set wind = 2 where child_id = 'c8000000-0000-0000-0000-000000000001';
select test_helpers.login('d8000000-0000-0000-0000-000000000001', 'aal1', true);
select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000030',
  test_helpers.answers('98000000-0000-0000-0000-000000000031:0'));
select test_helpers.expect_error(
  $$select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000035',
      test_helpers.answers('98000000-0000-0000-0000-000000000031:0', '98000000-0000-0000-0000-000000000021:0'))$$,
  'gehört nicht', 'Zweiter Ankerplatz: nur Stationen seit dem ersten');
select test_helpers.expect_true(
  (select r ->> 'passed' = 'true' and r ->> 'find' is null
   from (select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000035',
     test_helpers.answers('98000000-0000-0000-0000-000000000031:0', '98000000-0000-0000-0000-000000000032:0')) r) x),
  'Fund im Entwurf wird nicht verliehen');
select test_helpers.expect_true(
  (select r ->> 'island_completed' = 'true'
   from (select public.submit_station('c8000000-0000-0000-0000-000000000001', 'f8000000-0000-0000-0000-000000000040',
     test_helpers.answers('98000000-0000-0000-0000-000000000041:0')) r) x),
  'Mit beiden Ankerplätzen und der Prüfung ist die Insel abgeschlossen');

select test_helpers.expect_error(
  $$insert into public.child_collectibles (child_id, collectible_id)
    select 'c8000000-0000-0000-0000-000000000001', id from public.collectibles where slug = 'test-muenze'$$,
  'row-level security', 'Kinder-Gerät legt sich keine Funde selbst in die Sammlung');
select test_helpers.expect_equal((select count(*) from public.collectibles where slug = 'test-kompass'), 0,
  'Funde im Entwurf sind unsichtbar');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Begegnung zum Üben (Nebel voraus)
-- ---------------------------------------------------------------------------

update public.question_reviews set due_at = now() + interval '3 days'
where child_id = 'c8000000-0000-0000-0000-000000000001';
select test_helpers.login('d8000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(public.next_encounter('c8000000-0000-0000-0000-000000000001') is null,
  'Ohne fällige Wiederholungen keine Begegnung');
select test_helpers.expect_true(
  (select jsonb_array_length(e -> 'question_ids') = 3 and (e ->> 'due_count')::int = 0
   from (select public.next_encounter('c8000000-0000-0000-0000-000000000001', true) e) x),
  'Zum Üben gibt es trotzdem eine Begegnung mit bekannten Fragen');
select test_helpers.logout();

select test_helpers.login('a8000000-0000-0000-0000-000000000002');
select test_helpers.expect_equal((select count(*) from public.child_collectibles), 0,
  'Fremde Eltern sehen keine Sammlung');
select test_helpers.expect_error($$select public.next_encounter('c8000000-0000-0000-0000-000000000001', true)$$,
  'nicht gefunden', 'Fremde Eltern üben nicht für fremde Kinder');
select test_helpers.logout();
