-- Tests für die Inhalts- und Admin-Regeln (Schritt 1).
-- Ausführen mit: tool/db_test.sh

-- ---------------------------------------------------------------------------
-- Testdaten (als Datenbank-Besitzer, ohne RLS)
-- ---------------------------------------------------------------------------

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'owner@test.invalid'),
  ('00000000-0000-0000-0000-00000000000b', 'editor@test.invalid'),
  ('00000000-0000-0000-0000-00000000000c', 'familie@test.invalid');

insert into public.admins (id, user_id, role) values
  ('10000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a', 'owner'),
  ('10000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000b', 'editor');

insert into public.islands (id, slug, sort_order, title_key, status) values
  ('20000000-0000-0000-0000-000000000001', 'hafen', 1, 'island.hafen.title', 'published'),
  ('20000000-0000-0000-0000-000000000002', 'tauschinsel', 2, 'island.tauschinsel.title', 'draft');

insert into public.islands (id, slug, sort_order, title_key, status, publish_at) values
  ('20000000-0000-0000-0000-000000000003', 'wunschinsel', 3, 'island.wunschinsel.title',
   'published', now() + interval '7 days');

insert into public.stations (id, island_id, sort_order, type, is_required, status) values
  ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', 1, 'quiz', true, 'published'),
  ('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 2, 'exam', true, 'published');

-- Insel 2 veröffentlichen, nachdem ihre Pflichtstationen angelegt sind.
update public.islands set status = 'published' where slug = 'tauschinsel';

insert into public.quiz_questions (id, station_id, question, answers, correct_index, status) values
  ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002',
   'Was ist ein Tausch?', '["A", "B", "C"]', 1, 'published');

-- ---------------------------------------------------------------------------
-- Regeln für Inhalte
-- ---------------------------------------------------------------------------

select test_helpers.expect_error(
  $$insert into public.stations (island_id, sort_order, type, is_required)
    values ('20000000-0000-0000-0000-000000000002', 3, 'quiz', true)$$,
  'müssen Bonus sein',
  'Neue Pflichtstation an veröffentlichter Insel wird abgelehnt');

insert into public.stations (id, island_id, sort_order, type, is_required, added_in_version)
values ('30000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000002', 3, 'quiz', false, 2);
select test_helpers.expect_equal(
  (select count(*) from public.stations where id = '30000000-0000-0000-0000-000000000003'),
  1, 'Bonus-Station (Flaschenpost) an veröffentlichter Insel ist erlaubt');

select test_helpers.expect_error(
  $$update public.stations set is_required = true where id = '30000000-0000-0000-0000-000000000003'$$,
  'keine Pflichtstation werden',
  'Bonus-Station kann nicht nachträglich Pflicht werden');

select test_helpers.expect_error(
  $$update public.stations set is_required = false where id = '30000000-0000-0000-0000-000000000001'$$,
  'bleiben Pflicht',
  'Pflichtstation kann nicht zur Bonus-Station werden');

select test_helpers.expect_error(
  $$delete from public.stations where id = '30000000-0000-0000-0000-000000000001'$$,
  'nicht gelöscht',
  'Pflichtstation einer veröffentlichten Insel kann nicht gelöscht werden');

select test_helpers.expect_error(
  $$update public.stations set status = 'draft' where id = '30000000-0000-0000-0000-000000000001'$$,
  'nicht zurückgezogen',
  'Pflichtstation einer veröffentlichten Insel kann nicht zurückgezogen werden');

update public.stations set content = '{"korrigiert": true}' where id = '30000000-0000-0000-0000-000000000001';
select test_helpers.expect_equal(
  (select count(*) from public.content_versions
   where entity_type = 'stations' and entity_id = '30000000-0000-0000-0000-000000000001'),
  1, 'Korrektur an Pflichtstation ist erlaubt und alte Fassung wird gesichert');

select test_helpers.expect_error(
  $$delete from public.quiz_questions where id = '40000000-0000-0000-0000-000000000001'$$,
  'nicht gelöscht',
  'Prüfungsfrage einer veröffentlichten Insel kann nicht gelöscht werden');

update public.quiz_questions set explanation = 'Erklärung korrigiert'
where id = '40000000-0000-0000-0000-000000000001';
select test_helpers.expect_equal(
  (select count(*) from public.content_versions
   where entity_type = 'quiz_questions' and entity_id = '40000000-0000-0000-0000-000000000001'),
  1, 'Korrektur an Prüfungsfrage ist erlaubt und wird gesichert');

select test_helpers.expect_error(
  $$delete from public.islands where id = '20000000-0000-0000-0000-000000000001'$$,
  'nicht gelöscht',
  'Veröffentlichte Insel kann nicht gelöscht werden');

select test_helpers.expect_error(
  $$insert into public.quiz_questions (station_id, question, answers, correct_index)
    values ('30000000-0000-0000-0000-000000000001', 'Frage?', '["A", "B"]', 2)$$,
  'quiz_questions_answers_check',
  'Richtige Antwort muss in der Antwortliste liegen');

select test_helpers.expect_error(
  $$insert into public.islands (slug, sort_order, title_key) values ('Falscher Slug', 9, 'x')$$,
  'islands_slug_check',
  'Slug muss klein und mit Bindestrichen geschrieben sein');

select test_helpers.expect_error(
  $$insert into public.islands (slug, stage, sort_order, title_key) values ('stufe-drei', 3, 9, 'x')$$,
  'islands_stage_check',
  'Nur Stufe 1 und 2 sind erlaubt');

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

-- Eine Familie (kein Admin) sieht nur sichtbare Inhalte.
select test_helpers.login('00000000-0000-0000-0000-00000000000c');
select test_helpers.expect_equal(
  (select count(*) from public.islands), 2,
  'Familie sieht nur veröffentlichte Inseln mit erreichtem Termin');
select test_helpers.expect_equal(
  (select count(*) from public.stations where id = '30000000-0000-0000-0000-000000000003'), 0,
  'Familie sieht keine Entwurfs-Station');
select test_helpers.expect_equal(
  (select count(*) from public.admins), 0,
  'Familie sieht keine Admins');
select test_helpers.expect_equal(
  (select count(*) from public.content_versions), 0,
  'Familie sieht keine früheren Fassungen');
select test_helpers.expect_error(
  $$insert into public.islands (slug, sort_order, title_key) values ('hack', 99, 'x')$$,
  'row-level security',
  'Familie kann keine Inseln anlegen');
select test_helpers.logout();

-- Ein Editor ohne Zwei-Faktor-Anmeldung ist kein Admin.
select test_helpers.login('00000000-0000-0000-0000-00000000000b', 'aal1');
select test_helpers.expect_equal(
  (select count(*) from public.islands), 2,
  'Editor ohne Zwei-Faktor sieht keine Entwürfe');
select test_helpers.expect_error(
  $$insert into public.islands (slug, sort_order, title_key) values ('ohne-mfa', 99, 'x')$$,
  'row-level security',
  'Editor ohne Zwei-Faktor kann nichts schreiben');
select test_helpers.logout();

-- Editor mit Zwei-Faktor-Anmeldung.
select test_helpers.login('00000000-0000-0000-0000-00000000000b', 'aal2');
select test_helpers.expect_equal(
  (select count(*) from public.islands), 3,
  'Editor mit Zwei-Faktor sieht auch geplante Inhalte');
insert into public.islands (slug, sort_order, title_key) values ('spar-insel', 4, 'island.spar-insel.title');
select test_helpers.expect_equal(
  (select count(*) from public.islands where slug = 'spar-insel'), 1,
  'Editor mit Zwei-Faktor legt Inseln an');
select test_helpers.expect_error(
  $$insert into public.admins (user_id, role) values ('00000000-0000-0000-0000-00000000000c', 'owner')$$,
  'row-level security',
  'Editor kann keine Admins anlegen');
select test_helpers.expect_equal(
  (select count(*) from public.admins), 1,
  'Editor sieht nur den eigenen Admin-Eintrag');
select test_helpers.expect_error(
  $$insert into public.admin_audit_log (admin_id, action, target_type, reason)
    values ('10000000-0000-0000-0000-00000000000a', 'test', 'parent', 'Test')$$,
  'row-level security',
  'Editor kann nicht unter fremdem Namen ins Audit-Log schreiben');
insert into public.admin_audit_log (admin_id, action, target_type, reason)
values ('10000000-0000-0000-0000-00000000000b', 'view', 'parent', 'Supportanfrage');
select test_helpers.expect_equal(
  (select count(*) from public.admin_audit_log), 0,
  'Editor kann das Audit-Log nicht lesen');
select test_helpers.logout();

-- Owner mit Zwei-Faktor-Anmeldung.
select test_helpers.login('00000000-0000-0000-0000-00000000000a', 'aal2');
select test_helpers.expect_equal(
  (select count(*) from public.admins), 2,
  'Owner sieht alle Admins');
select test_helpers.expect_equal(
  (select count(*) from public.admin_audit_log), 1,
  'Owner liest das Audit-Log');
select test_helpers.logout();

select test_helpers.expect_error(
  $$delete from public.admin_audit_log$$,
  'unveränderlich',
  'Audit-Log lässt sich auch mit vollen Rechten nicht löschen');

select test_helpers.expect_error(
  $$update public.admins set mfa_required = false$$,
  'admins_mfa_required_check',
  'Zwei-Faktor-Pflicht für Admins lässt sich nicht abschalten');

