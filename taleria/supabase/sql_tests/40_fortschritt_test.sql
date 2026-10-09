-- Tests für Fortschritt, Freischalten und Inselkarte (Schritt 4b).
-- Ausführen mit: tool/db_test.sh
--
-- Eigene Inseln in Stufe 2, damit die Testdaten aus 10_regeln_test.sql
-- (Stufe 1) nicht stören.

-- ---------------------------------------------------------------------------
-- Testdaten
-- ---------------------------------------------------------------------------

insert into auth.users (id, email, raw_user_meta_data) values
  ('a4000000-0000-0000-0000-000000000001', 'karte1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('a4000000-0000-0000-0000-000000000002', 'karte2@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('d4000000-0000-0000-0000-000000000001', true);

insert into public.children (id, parent_id, nickname, birth_year, stage)
select 'c4000000-0000-0000-0000-000000000001', p.id, 'Kim', 2015, 2
from public.parents p where p.user_id = 'a4000000-0000-0000-0000-000000000001';
insert into public.child_devices (user_id, child_id)
values ('d4000000-0000-0000-0000-000000000001', 'c4000000-0000-0000-0000-000000000001');

-- Insel A (offen), Insel B (offen), Insel C (Entwurf, also Nebel)
insert into public.islands (id, slug, stage, sort_order, title, status) values
  ('e4000000-0000-0000-0000-00000000000a', 'insel-a', 2, 1, 'Insel A', 'published'),
  ('e4000000-0000-0000-0000-00000000000b', 'insel-b', 2, 2, 'Insel B', 'published'),
  ('e4000000-0000-0000-0000-00000000000c', 'insel-c', 2, 3, 'Insel C', 'draft');

-- Stationen müssen vor dem Veröffentlichen der Insel angelegt sein (Regel aus Schritt 1),
-- deshalb Inseln kurz auf Entwurf setzen.
update public.islands set status = 'draft' where slug in ('insel-a', 'insel-b');

insert into public.stations (id, island_id, sort_order, type, xp_reward, content, status) values
  ('f4000000-0000-0000-0000-0000000000a1', 'e4000000-0000-0000-0000-00000000000a', 1, 'practice', 50,
   '{"kind": "onboarding"}', 'published'),
  ('f4000000-0000-0000-0000-0000000000a2', 'e4000000-0000-0000-0000-00000000000a', 2, 'quiz', 100,
   '{"quiz": {"show": 2}}', 'published'),
  ('f4000000-0000-0000-0000-0000000000a3', 'e4000000-0000-0000-0000-00000000000a', 3, 'exam', 150,
   '{"exam": {"show": 2, "review": 1, "pass": 2}}', 'published'),
  ('f4000000-0000-0000-0000-0000000000b1', 'e4000000-0000-0000-0000-00000000000b', 1, 'video', 100,
   '{"quiz": {"show": 1}}', 'published'),
  ('f4000000-0000-0000-0000-0000000000b2', 'e4000000-0000-0000-0000-00000000000b', 2, 'exam', 150,
   '{"exam": {"show": 2, "review": 1, "pass": 3}}', 'published'),
  ('f4000000-0000-0000-0000-0000000000c1', 'e4000000-0000-0000-0000-00000000000c', 1, 'video', 100,
   '{"quiz": {"show": 1}}', 'draft');

insert into public.quiz_questions (id, station_id, question, answers, correct_index, status) values
  ('94000000-0000-0000-0000-0000000000a1', 'f4000000-0000-0000-0000-0000000000a2', 'A2 Frage 1', '["r", "f", "f"]', 0, 'published'),
  ('94000000-0000-0000-0000-0000000000a2', 'f4000000-0000-0000-0000-0000000000a2', 'A2 Frage 2', '["r", "f", "f"]', 0, 'published'),
  ('94000000-0000-0000-0000-0000000000a3', 'f4000000-0000-0000-0000-0000000000a2', 'A2 Frage 3', '["r", "f", "f"]', 0, 'published'),
  ('94000000-0000-0000-0000-0000000000a4', 'f4000000-0000-0000-0000-0000000000a2', 'A2 Frage 4', '["r", "f", "f"]', 0, 'published'),
  ('94000000-0000-0000-0000-0000000000e1', 'f4000000-0000-0000-0000-0000000000a3', 'A Prüfung 1', '["f", "r", "f"]', 1, 'published'),
  ('94000000-0000-0000-0000-0000000000e2', 'f4000000-0000-0000-0000-0000000000a3', 'A Prüfung 2', '["f", "r", "f"]', 1, 'published'),
  ('94000000-0000-0000-0000-0000000000e3', 'f4000000-0000-0000-0000-0000000000a3', 'A Prüfung 3', '["f", "r", "f"]', 1, 'published'),
  ('94000000-0000-0000-0000-0000000000b1', 'f4000000-0000-0000-0000-0000000000b1', 'B1 Frage 1', '["r", "f", "f"]', 0, 'published'),
  ('94000000-0000-0000-0000-0000000000b2', 'f4000000-0000-0000-0000-0000000000b1', 'B1 Frage 2', '["r", "f", "f"]', 0, 'published'),
  ('94000000-0000-0000-0000-0000000000f1', 'f4000000-0000-0000-0000-0000000000b2', 'B Prüfung 1', '["r", "f", "f"]', 0, 'published'),
  ('94000000-0000-0000-0000-0000000000f2', 'f4000000-0000-0000-0000-0000000000b2', 'B Prüfung 2', '["r", "f", "f"]', 0, 'published'),
  ('94000000-0000-0000-0000-0000000000f3', 'f4000000-0000-0000-0000-0000000000b2', 'B Prüfung 3', '["r", "f", "f"]', 0, 'published');

update public.islands set status = 'published' where slug in ('insel-a', 'insel-b');

-- Hilfsfunktion: Antworten als JSON
create function test_helpers.answers(variadic p_pairs text[])
returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object('question_id', split_part(x, ':', 1), 'answer_index', split_part(x, ':', 2)::int))
  from unnest(p_pairs) x;
$$;
grant execute on function test_helpers.answers(text[]) to authenticated;

-- ---------------------------------------------------------------------------
-- Karte
-- ---------------------------------------------------------------------------

select test_helpers.login('d4000000-0000-0000-0000-000000000001', 'aal1', true);

select test_helpers.expect_equal((select count(*) from public.map_islands(2::smallint)), 3,
  'Karte zeigt alle Inseln der Stufe, auch die im Nebel');
select test_helpers.expect_true(
  (select not has_content and title = 'Insel C' from public.map_islands(2::smallint) where slug = 'insel-c'),
  'Insel im Entwurf liegt im Nebel (Name ja, Inhalt nein)');
select test_helpers.expect_true(
  (select bool_and(has_content) from public.map_islands(2::smallint) where slug in ('insel-a', 'insel-b')),
  'Veröffentlichte Inseln haben Inhalt');
select test_helpers.expect_equal(
  (select count(*) from public.stations where island_id = 'e4000000-0000-0000-0000-00000000000c'), 0,
  'Stationen einer Insel im Nebel sind nicht sichtbar');
select test_helpers.expect_equal((select count(*) from public.app_settings), 0,
  'Kinder-Gerät sieht keine Einstellungen');

-- ---------------------------------------------------------------------------
-- Stationen der Reihe nach
-- ---------------------------------------------------------------------------

select test_helpers.expect_error(
  $$select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
      test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0', '94000000-0000-0000-0000-0000000000a2:0'))$$,
  'gesperrt', 'Station 2 ist vor dem Intro gesperrt');

select test_helpers.expect_equal(
  public.complete_onboarding('c4000000-0000-0000-0000-000000000001'), 50,
  'Intro bringt die Seemeilen aus der Intro-Station');
select test_helpers.expect_true(
  public.station_done('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a1'),
  'Intro-Station ist danach erledigt');

select test_helpers.expect_error(
  $$select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a1', '[]')$$,
  'complete_onboarding', 'Intro-Station wird nicht über submit_station abgegeben');
select test_helpers.expect_error(
  $$select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
      test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0'))$$,
  'Falsche Anzahl', 'Zu wenige Antworten werden abgelehnt');
select test_helpers.expect_error(
  $$select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
      test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0', '94000000-0000-0000-0000-0000000000a1:0'))$$,
  'Falsche Anzahl', 'Dieselbe Frage zweimal zählt nicht');
select test_helpers.expect_error(
  $$select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
      test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0', '94000000-0000-0000-0000-0000000000e1:1'))$$,
  'gehört nicht', 'Fragen anderer Stationen werden abgelehnt');

select test_helpers.expect_true(
  (select r ->> 'correct' = '1' and r ->> 'passed' = 'true' and r ->> 'xp_awarded' = '100'
   from (select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
     test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0', '94000000-0000-0000-0000-0000000000a2:2')) r) x),
  'Stations-Check: erledigt auch mit Fehlern, 100 Seemeilen, Server zählt die richtigen');
select test_helpers.expect_true(
  (select r ->> 'xp_awarded' = '0'
   from (select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
     test_helpers.answers('94000000-0000-0000-0000-0000000000a3:0', '94000000-0000-0000-0000-0000000000a4:0')) r) x),
  'Seemeilen gibt es pro Station nur einmal');

select test_helpers.expect_error(
  $$select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000b1',
      test_helpers.answers('94000000-0000-0000-0000-0000000000b1:0'))$$,
  'gesperrt', 'Nächste Insel ist vor dem Abschluss der vorherigen gesperrt');

-- ---------------------------------------------------------------------------
-- Abschlussprüfung
-- ---------------------------------------------------------------------------

select test_helpers.expect_true(
  (select r ->> 'passed' = 'false' and r ->> 'xp_awarded' = '0' and r ->> 'island_completed' = 'false'
   from (select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a3',
     test_helpers.answers('94000000-0000-0000-0000-0000000000e1:1', '94000000-0000-0000-0000-0000000000e2:0')) r) x),
  'Prüfung nicht bestanden: keine Seemeilen, Insel nicht abgeschlossen');
select test_helpers.expect_true(
  (select status = 'open' and attempts = 1 and last_score = 1 from public.station_progress
   where station_id = 'f4000000-0000-0000-0000-0000000000a3'),
  'Nicht bestandene Prüfung bleibt offen und darf wiederholt werden');

select test_helpers.expect_error(
  $$insert into public.station_progress (child_id, station_id, status, completed_at)
    values ('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a3', 'done', now())$$,
  'row-level security', 'Kind kann eine Station nicht selbst als erledigt eintragen');

select test_helpers.expect_true(
  (select r ->> 'passed' = 'true' and r ->> 'xp_awarded' = '150' and r ->> 'island_completed' = 'true'
   from (select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a3',
     test_helpers.answers('94000000-0000-0000-0000-0000000000e1:1', '94000000-0000-0000-0000-0000000000e3:1')) r) x),
  'Prüfung bestanden: 150 Seemeilen und Insel abgeschlossen');
select test_helpers.expect_equal((select count(*) from public.island_completions), 1,
  'Insel-Abschluss ist gespeichert');

-- Insel B ist jetzt offen.
select test_helpers.expect_true(
  (select r ->> 'passed' = 'true'
   from (select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000b1',
     test_helpers.answers('94000000-0000-0000-0000-0000000000b2:1')) r) x),
  'Nach dem Abschluss öffnet sich die nächste Insel');

-- Prüfung mit Rückblick: 2 eigene Fragen plus 1 aus der Prüfung von Insel A.
select test_helpers.expect_error(
  $$select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000b2',
      test_helpers.answers('94000000-0000-0000-0000-0000000000f1:0', '94000000-0000-0000-0000-0000000000f2:0'))$$,
  'Falsche Anzahl', 'Prüfung ab Insel 2 braucht die Rückblick-Fragen');
select test_helpers.expect_error(
  $$select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000b2',
      test_helpers.answers('94000000-0000-0000-0000-0000000000f1:0', '94000000-0000-0000-0000-0000000000f2:0',
                           '94000000-0000-0000-0000-0000000000f3:0'))$$,
  'Rückblick', 'Rückblick-Fragen müssen von früheren Inseln stammen');
select test_helpers.expect_error(
  $$select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000b2',
      test_helpers.answers('94000000-0000-0000-0000-0000000000f1:0', '94000000-0000-0000-0000-0000000000f2:0',
                           '94000000-0000-0000-0000-0000000000a1:0'))$$,
  'gehört nicht', 'Rückblick nur aus Prüfungen, nicht aus Stations-Checks');
select test_helpers.expect_true(
  (select r ->> 'passed' = 'true' and r ->> 'correct' = '3' and r ->> 'island_completed' = 'true'
   from (select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000b2',
     test_helpers.answers('94000000-0000-0000-0000-0000000000f1:0', '94000000-0000-0000-0000-0000000000f2:0',
                          '94000000-0000-0000-0000-0000000000e1:1')) r) x),
  'Prüfung mit Rückblick bestanden, Insel B abgeschlossen');

select test_helpers.expect_equal(
  (select sum(amount) from public.xp_events where child_id = 'c4000000-0000-0000-0000-000000000001'), 550,
  'Seemeilen: 50 Intro + 100 + 150 + 100 + 150');

select test_helpers.expect_error(
  $$select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000c1',
      test_helpers.answers('94000000-0000-0000-0000-0000000000b1:0'))$$,
  'nicht gefunden', 'Stationen im Nebel lassen sich nicht abgeben');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Fremde Familien, eingefrorener Abschluss, Vorschau
-- ---------------------------------------------------------------------------

select test_helpers.login('a4000000-0000-0000-0000-000000000002');
select test_helpers.expect_error(
  $$select public.submit_station('c4000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000b1',
      test_helpers.answers('94000000-0000-0000-0000-0000000000b1:0'))$$,
  'nicht gefunden', 'Fremde Eltern können nichts für mein Kind abgeben');
select test_helpers.expect_equal((select count(*) from public.station_progress), 0,
  'Fremde Eltern sehen keinen Fortschritt');
select test_helpers.logout();

select test_helpers.login('a4000000-0000-0000-0000-000000000001');
select test_helpers.expect_equal((select count(*) from public.island_completions), 2,
  'Eltern sehen die abgeschlossenen Inseln ihres Kindes');
select test_helpers.logout();

select test_helpers.expect_error(
  $$update public.island_completions set completed_at = now()$$,
  'eingefroren', 'Insel-Abschluss lässt sich nicht ändern');

-- Vorschau einschalten (nur Testumgebung): Entwürfe werden für Kinder sichtbar.
insert into public.app_settings (key, value) values ('content_preview', 'true');
select test_helpers.login('d4000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select has_content from public.map_islands(2::smallint) where slug = 'insel-c'),
  'Mit Vorschau ist die Entwurfs-Insel spielbar');
select test_helpers.expect_equal(
  (select count(*) from public.stations where island_id = 'e4000000-0000-0000-0000-00000000000c'), 1,
  'Mit Vorschau sind Entwurfs-Stationen sichtbar');
select test_helpers.logout();
delete from public.app_settings where key = 'content_preview';

select test_helpers.login('d4000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_equal(
  (select count(*) from public.stations where island_id = 'e4000000-0000-0000-0000-00000000000c'), 0,
  'Ohne Vorschau sind Entwürfe wieder unsichtbar');
select test_helpers.logout();
