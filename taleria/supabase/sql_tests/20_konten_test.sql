-- Tests für Konten und Rollen (Schritt 2).
-- Ausführen mit: tool/db_test.sh

-- ---------------------------------------------------------------------------
-- Registrierung
-- ---------------------------------------------------------------------------

insert into auth.users (id, email, raw_user_meta_data) values
  ('a0000000-0000-0000-0000-000000000001', 'eltern1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10", "marketing_consent": true, "locale": "de"}'),
  ('a0000000-0000-0000-0000-000000000002', 'eltern2@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10", "marketing_consent": false}');

insert into auth.users (id, is_anonymous) values
  ('d0000000-0000-0000-0000-000000000001', true),
  ('d0000000-0000-0000-0000-000000000002', true),
  ('d0000000-0000-0000-0000-000000000003', true);

select test_helpers.expect_equal(
  (select count(*) from public.parents where user_id::text like 'a0000000%'), 2,
  'Registrierung legt Eltern-Eintrag mit Einwilligung an');
select test_helpers.expect_equal(
  (select count(*) from public.parents where user_id::text like 'd0000000%'), 0,
  'Anonyme Kinder-Geräte bekommen keinen Eltern-Eintrag');
select test_helpers.expect_true(
  (select consent_at is not null and consent_version = '2026-10' and marketing_consent_at is not null
   from public.parents where user_id = 'a0000000-0000-0000-0000-000000000001'),
  'Einwilligung und Newsletter-Einwilligung werden mit Zeitpunkt gespeichert');
select test_helpers.expect_true(
  (select marketing_consent_at is null from public.parents where user_id = 'a0000000-0000-0000-0000-000000000002'),
  'Ohne Häkchen keine Newsletter-Einwilligung');
select test_helpers.expect_error(
  $$insert into auth.users (email, raw_user_meta_data) values ('ohne@test.invalid', '{"taleria_role": "parent"}')$$,
  'ohne Einwilligung',
  'Registrierung ohne Einwilligung wird abgelehnt');

-- ---------------------------------------------------------------------------
-- Eltern 1: Konto, Kinder-Profil, PIN
-- ---------------------------------------------------------------------------

select test_helpers.login('a0000000-0000-0000-0000-000000000001');

select test_helpers.expect_equal((select count(*) from public.parents), 1,
  'Eltern sehen nur ihr eigenes Konto');
select test_helpers.expect_error($$select parent_pin_hash from public.parents$$,
  'permission denied', 'PIN-Prüfsumme ist für die App nicht lesbar');

insert into public.children (id, parent_id, nickname, birth_year)
values ('c0000000-0000-0000-0000-000000000001', public.current_parent_id(), 'Mila', 2015);
select test_helpers.expect_equal((select count(*) from public.children), 1,
  'Eltern legen ein Kinder-Profil an');
select test_helpers.expect_true(
  (select stage = 1 and stations_per_week = 2 and release_weekdays = '{1,4}'::smallint[]
   from public.children where id = 'c0000000-0000-0000-0000-000000000001'),
  'Kinder-Profil startet mit Stufe 1, 2 Stationen pro Woche, Montag und Donnerstag');

select test_helpers.expect_error(
  $$insert into public.children (parent_id, nickname, birth_year)
    values ((select id from public.parents where user_id = 'a0000000-0000-0000-0000-000000000002'), 'Fremd', 2015)$$,
  'row-level security', 'Eltern können keine Kinder für andere Familien anlegen');
select test_helpers.expect_error(
  $$insert into public.children (parent_id, nickname, birth_year) values (public.current_parent_id(), 'X', 2015)$$,
  'children_nickname_check', 'Spitzname braucht mindestens 2 Zeichen');
-- Ohne Delete-Policy löscht ein direktes DELETE einfach nichts.
delete from public.children where id = 'c0000000-0000-0000-0000-000000000001';
select test_helpers.expect_equal((select count(*) from public.children), 1,
  'Direktes Löschen eines Kinder-Profils wirkt nicht (nur über delete_child)');

select test_helpers.expect_error($$select public.set_parent_pin('12')$$,
  '4 bis 6 Ziffern', 'PIN mit zu wenigen Ziffern wird abgelehnt');
select test_helpers.expect_error($$select public.set_parent_pin('12ab')$$,
  '4 bis 6 Ziffern', 'PIN mit Buchstaben wird abgelehnt');
select public.set_parent_pin('2468');
select test_helpers.expect_true((select has_parent_pin from public.parents), 'PIN ist gesetzt');
select test_helpers.expect_true((select status = 'ok' from public.verify_parent_pin('2468')),
  'Richtige PIN wird angenommen');
select test_helpers.expect_true((select status = 'wrong' from public.verify_parent_pin('0000')),
  'Falsche PIN wird abgelehnt');
select public.verify_parent_pin('0000');
select public.verify_parent_pin('0000');
select public.verify_parent_pin('0000');
select test_helpers.expect_true(
  (select status = 'locked' and locked_until > now() from public.verify_parent_pin('0000')),
  'Nach 5 falschen Versuchen ist die PIN gesperrt');
select test_helpers.expect_true((select status = 'locked' from public.verify_parent_pin('2468')),
  'Während der Sperre hilft auch die richtige PIN nicht');
select test_helpers.logout();

-- Sperre aufheben (wie nach Ablauf der 5 Minuten).
update public.parents set parent_pin_locked_until = now() - interval '1 second'
where user_id = 'a0000000-0000-0000-0000-000000000001';

select test_helpers.login('a0000000-0000-0000-0000-000000000001');
select test_helpers.expect_true((select status = 'ok' from public.verify_parent_pin('2468')),
  'Nach Ablauf der Sperre funktioniert die richtige PIN wieder');

-- ---------------------------------------------------------------------------
-- Anmelde-Code erzeugen
-- ---------------------------------------------------------------------------

select set_config('test.code', login_code, false)
from public.create_child_login_code('c0000000-0000-0000-0000-000000000001');
select test_helpers.expect_true(current_setting('test.code') ~ '^[A-HJKMNP-Z2-9]{8}$',
  'Code hat 8 gut lesbare Zeichen');
select test_helpers.expect_equal((select count(*) from public.child_login_codes), 0,
  'Codes sind für die App nicht direkt lesbar');
select test_helpers.expect_error(
  $$select * from public.redeem_child_login_code(current_setting('test.code'))$$,
  'nur auf Kinder-Geräten', 'Eltern-Sitzung kann keinen Code einlösen');
select test_helpers.logout();

select test_helpers.expect_true(
  (select code_hash <> current_setting('test.code') and length(code_hash) = 64
   from public.child_login_codes where child_id = 'c0000000-0000-0000-0000-000000000001'),
  'Code wird nur als Prüfsumme gespeichert');

-- Eltern 2 dürfen für fremde Kinder keinen Code erzeugen.
select test_helpers.login('a0000000-0000-0000-0000-000000000002');
select test_helpers.expect_error(
  $$select * from public.create_child_login_code('c0000000-0000-0000-0000-000000000001')$$,
  'nicht gefunden', 'Fremde Eltern können keinen Code für mein Kind erzeugen');
select test_helpers.expect_equal((select count(*) from public.children), 0,
  'Fremde Eltern sehen mein Kind nicht');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Code auf dem Kinder-Gerät einlösen
-- ---------------------------------------------------------------------------

select test_helpers.login('d0000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_equal((select count(*) from public.children), 0,
  'Kinder-Gerät sieht vor dem Einlösen kein Profil');
select test_helpers.expect_equal(
  (select count(*) from public.redeem_child_login_code('ABCD2345')), 0,
  'Falscher Code wird abgelehnt');
select test_helpers.expect_true(
  (select nickname = 'Mila' from public.redeem_child_login_code(
     lower(substr(current_setting('test.code'), 1, 4) || '-' || substr(current_setting('test.code'), 5)))),
  'Richtiger Code funktioniert, auch klein geschrieben und mit Bindestrich');
select test_helpers.expect_equal((select count(*) from public.children), 1,
  'Kinder-Gerät sieht danach genau sein eigenes Profil');
update public.children set nickname = 'Gehackt';
select test_helpers.expect_equal((select count(*) from public.children where nickname = 'Mila'), 1,
  'Kinder-Gerät kann sein Profil nicht ändern');
select test_helpers.expect_error(
  $$insert into public.children (parent_id, nickname, birth_year)
    values ((select parent_id from public.children limit 1), 'Neu', 2015)$$,
  'row-level security', 'Kinder-Gerät kann keine Profile anlegen');
select test_helpers.expect_equal((select count(*) from public.parents), 0,
  'Kinder-Gerät sieht kein Eltern-Konto');
select test_helpers.expect_error($$select public.set_parent_pin('1234')$$,
  'Nur für Eltern', 'Kinder-Gerät kann keine Eltern-PIN setzen');
select test_helpers.expect_error($$select public.delete_child('c0000000-0000-0000-0000-000000000001')$$,
  'nicht gefunden', 'Kinder-Gerät kann sein Profil nicht löschen');
select test_helpers.expect_error(
  $$select * from public.create_child_login_code('c0000000-0000-0000-0000-000000000001')$$,
  'nicht gefunden', 'Kinder-Gerät kann keine Codes erzeugen');
select test_helpers.logout();

select test_helpers.login('d0000000-0000-0000-0000-000000000002', 'aal1', true);
select test_helpers.expect_equal(
  (select count(*) from public.redeem_child_login_code(current_setting('test.code'))), 0,
  'Ein Code funktioniert nur einmal');
select test_helpers.logout();

-- Ohne Sitzung gar nichts.
select test_helpers.login_anon();
select test_helpers.expect_equal((select count(*) from public.children), 0,
  'Ohne Anmeldung keine Kinder-Profile');
select test_helpers.expect_error(
  $$select * from public.redeem_child_login_code('ABCD2345')$$,
  'permission denied', 'Ohne Anmeldung kein Code einlösen');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Abgelaufene und ersetzte Codes
-- ---------------------------------------------------------------------------

select test_helpers.login('a0000000-0000-0000-0000-000000000001');
select set_config('test.code_alt', login_code, false)
from public.create_child_login_code('c0000000-0000-0000-0000-000000000001');
select set_config('test.code_neu', login_code, false)
from public.create_child_login_code('c0000000-0000-0000-0000-000000000001');
select test_helpers.logout();

select test_helpers.login('d0000000-0000-0000-0000-000000000002', 'aal1', true);
select test_helpers.expect_equal(
  (select count(*) from public.redeem_child_login_code(current_setting('test.code_alt'))), 0,
  'Ein neuer Code macht den alten ungültig');
select test_helpers.logout();

update public.child_login_codes set expires_at = now() - interval '1 minute'
where child_id = 'c0000000-0000-0000-0000-000000000001' and used_at is null;

select test_helpers.login('d0000000-0000-0000-0000-000000000002', 'aal1', true);
select test_helpers.expect_equal(
  (select count(*) from public.redeem_child_login_code(current_setting('test.code_neu'))), 0,
  'Abgelaufener Code wird abgelehnt');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Geräte abmelden, Profil löschen, Konto löschen
-- ---------------------------------------------------------------------------

select test_helpers.login('a0000000-0000-0000-0000-000000000001');
select test_helpers.expect_equal((select count(*) from public.child_devices), 1,
  'Eltern sehen das angemeldete Gerät ihres Kindes');
select public.sign_out_child_devices('c0000000-0000-0000-0000-000000000001');
select test_helpers.expect_equal((select count(*) from public.child_devices), 0,
  'Eltern melden alle Geräte des Kindes ab');
select test_helpers.logout();
select test_helpers.expect_equal(
  (select count(*) from auth.users where id = 'd0000000-0000-0000-0000-000000000001'), 0,
  'Abgemeldetes Gerät verliert seine Sitzung');

-- Neues Gerät verbinden, dann Profil löschen.
select test_helpers.login('a0000000-0000-0000-0000-000000000001');
select set_config('test.code', login_code, false)
from public.create_child_login_code('c0000000-0000-0000-0000-000000000001');
select test_helpers.logout();
select test_helpers.login('d0000000-0000-0000-0000-000000000002', 'aal1', true);
select public.redeem_child_login_code(current_setting('test.code'));
select test_helpers.logout();

select test_helpers.login('a0000000-0000-0000-0000-000000000001');
select public.delete_child('c0000000-0000-0000-0000-000000000001');
select test_helpers.expect_equal((select count(*) from public.children), 0,
  'Eltern löschen ein Kinder-Profil');
select test_helpers.logout();
select test_helpers.expect_equal(
  (select count(*) from auth.users where id = 'd0000000-0000-0000-0000-000000000002'), 0,
  'Beim Löschen des Profils wird auch das Kinder-Gerät abgemeldet');

-- Ganzes Konto löschen.
select test_helpers.login('a0000000-0000-0000-0000-000000000001');
insert into public.children (id, parent_id, nickname, birth_year)
values ('c0000000-0000-0000-0000-000000000002', public.current_parent_id(), 'Ben', 2014);
select set_config('test.code', login_code, false)
from public.create_child_login_code('c0000000-0000-0000-0000-000000000002');
select test_helpers.logout();
select test_helpers.login('d0000000-0000-0000-0000-000000000003', 'aal1', true);
select public.redeem_child_login_code(current_setting('test.code'));
select test_helpers.logout();

select test_helpers.login('a0000000-0000-0000-0000-000000000001');
select public.delete_my_account();
select test_helpers.logout();
select test_helpers.expect_equal(
  (select count(*) from auth.users
   where id in ('a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000003')), 0,
  'Konto löschen entfernt Eltern-Zugang und Kinder-Geräte');
select test_helpers.expect_equal(
  (select count(*) from public.children where id = 'c0000000-0000-0000-0000-000000000002'), 0,
  'Konto löschen entfernt alle Kinder-Profile');

-- Admins löschen sich nicht über die App.
insert into public.admins (user_id, role) values ('a0000000-0000-0000-0000-000000000002', 'support');
select test_helpers.login('a0000000-0000-0000-0000-000000000002');
select test_helpers.expect_error($$select public.delete_my_account()$$,
  'Admin-Konten', 'Admin-Konten werden nicht über die App gelöscht');
select test_helpers.logout();
