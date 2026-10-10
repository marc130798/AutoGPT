-- Tests für Abo-Rechte (Schritt 9).
-- Ausführen mit: tool/db_test.sh

insert into auth.users (id, email, raw_user_meta_data) values
  ('a9000000-0000-0000-0000-000000000001', 'abo1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('a9000000-0000-0000-0000-000000000002', 'abo2@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('d9000000-0000-0000-0000-000000000001', true);

-- Premium-Nebeninsel in Stufe 2 (Reihenfolge 0, also sonst offen).
insert into public.islands (id, slug, stage, sort_order, title, route_type, status, content) values
  ('e9000000-0000-0000-0000-00000000000a', 'premiuminsel', 2, 0, 'Premiuminsel', 'side', 'draft',
   '{"access": "premium"}');
insert into public.stations (id, island_id, sort_order, type, xp_reward, content, status) values
  ('f9000000-0000-0000-0000-000000000010', 'e9000000-0000-0000-0000-00000000000a', 10, 'quiz', 100,
   '{"quiz": {"show": 1}}', 'published');
insert into public.quiz_questions (id, station_id, question, answers, correct_index, status) values
  ('99000000-0000-0000-0000-000000000011', 'f9000000-0000-0000-0000-000000000010', 'Premium-Frage', '["r", "f", "f"]', 0, 'published');
update public.islands set status = 'published' where id = 'e9000000-0000-0000-0000-00000000000a';

-- ---------------------------------------------------------------------------
-- Gratis: ein Kinder-Profil, keine Premium-Inseln
-- ---------------------------------------------------------------------------

select test_helpers.login('a9000000-0000-0000-0000-000000000001');
insert into public.children (id, parent_id, nickname, birth_year, stage)
values ('c9000000-0000-0000-0000-000000000001', public.current_parent_id(), 'Pia', 2015, 2);
update public.children set nickname = 'Pia' where id = 'c9000000-0000-0000-0000-000000000001';
select test_helpers.expect_error(
  $$insert into public.children (parent_id, nickname, birth_year) values (public.current_parent_id(), 'Max', 2016)$$,
  'mit dem Abo', 'Gratis: nur ein Kinder-Profil');
select test_helpers.expect_true(
  (select s ->> 'premium' = 'false' and s ->> 'test_purchases' = 'false' from public.my_subscription() s),
  'Ohne Abo: Basis, und ohne Testschalter kein Test-Abo');
select test_helpers.expect_error($$select public.set_test_premium(true)$$,
  'nur in der Testumgebung', 'Test-Abo gibt es nicht in der Live-Datenbank');
select test_helpers.expect_error(
  $$insert into public.entitlements (parent_id, source) values (public.current_parent_id(), 'manual')$$,
  'row-level security', 'Eltern schreiben sich kein Abo selbst');
select test_helpers.logout();

insert into public.child_devices (user_id, child_id)
values ('d9000000-0000-0000-0000-000000000001', 'c9000000-0000-0000-0000-000000000001');
update public.children set stations_per_week = null where id = 'c9000000-0000-0000-0000-000000000001';

select test_helpers.login('d9000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select access = 'premium' from public.map_islands(2::smallint) where slug = 'premiuminsel'),
  'Karte kennt den Zugang einer Insel');
select test_helpers.expect_true(
  (select access = 'free' from public.map_islands(2::smallint) where slug = 'insel-a'),
  'Ohne Angabe ist eine Insel gratis');
select test_helpers.expect_true(
  public.child_stats('c9000000-0000-0000-0000-000000000001') ->> 'premium' = 'false',
  'Statistik: Kind ohne Abo');
select test_helpers.expect_error(
  $$select public.submit_station('c9000000-0000-0000-0000-000000000001', 'f9000000-0000-0000-0000-000000000010',
      test_helpers.answers('99000000-0000-0000-0000-000000000011:0'))$$,
  'gesperrt', 'Premium-Insel ohne Abo gesperrt');
select test_helpers.expect_error($$select public.set_test_premium(true)$$,
  'Nur für Eltern', 'Kinder-Gerät kann kein Abo aktivieren');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Test-Abo in der Testumgebung
-- ---------------------------------------------------------------------------

insert into public.app_settings (key, value) values ('test_purchases', 'true'::jsonb);

select test_helpers.login('a9000000-0000-0000-0000-000000000001');
select public.set_test_premium(true);
select test_helpers.expect_true(
  (select s ->> 'premium' = 'true' and s ->> 'source' = 'test' from public.my_subscription() s),
  'Test-Abo ist aktiv');
insert into public.children (id, parent_id, nickname, birth_year)
values ('c9000000-0000-0000-0000-000000000002', public.current_parent_id(), 'Max', 2016);
select test_helpers.expect_equal((select count(*) from public.children), 2, 'Mit Abo: mehrere Kinder-Profile');
select test_helpers.logout();

select test_helpers.login('d9000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select r ->> 'passed' = 'true'
   from (select public.submit_station('c9000000-0000-0000-0000-000000000001', 'f9000000-0000-0000-0000-000000000010',
     test_helpers.answers('99000000-0000-0000-0000-000000000011:0')) r) x),
  'Mit Abo ist die Premium-Insel offen');
select test_helpers.logout();

-- Abo endet: Premium-Insel wieder gesperrt, fertige Abschlüsse bleiben.
select test_helpers.login('a9000000-0000-0000-0000-000000000001');
select public.set_test_premium(false);
select test_helpers.expect_true(
  (select s ->> 'premium' = 'false' from public.my_subscription() s), 'Test-Abo beendet');
select test_helpers.logout();

select test_helpers.login('d9000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_error(
  $$select public.submit_station('c9000000-0000-0000-0000-000000000001', 'f9000000-0000-0000-0000-000000000010',
      test_helpers.answers('99000000-0000-0000-0000-000000000011:0'))$$,
  'gesperrt', 'Nach dem Abo ist die Premium-Insel wieder gesperrt');
select test_helpers.expect_equal(
  (select count(*) from public.island_completions where island_id = 'e9000000-0000-0000-0000-00000000000a'), 1,
  'Der Insel-Abschluss bleibt erhalten');
select test_helpers.logout();

-- Abgelaufenes Abo zählt nicht.
insert into public.entitlements (parent_id, source, valid_until)
select id, 'revenuecat', now() - interval '1 day' from public.parents
where user_id = 'a9000000-0000-0000-0000-000000000001';
select test_helpers.login('a9000000-0000-0000-0000-000000000001');
select test_helpers.expect_true(
  (select s ->> 'premium' = 'false' from public.my_subscription() s), 'Abgelaufenes Abo zählt nicht');
select test_helpers.logout();

select test_helpers.login('a9000000-0000-0000-0000-000000000002');
select test_helpers.expect_equal((select count(*) from public.entitlements), 0, 'Fremde Eltern sehen kein Abo');
select test_helpers.logout();

delete from public.app_settings where key = 'test_purchases';
