-- Tests für Messung und Fehlerprotokoll (Schritt 11).
-- Ausführen mit: tool/db_test.sh

insert into auth.users (id, email) values
  ('ae000000-0000-0000-0000-00000000000a', 'messung-owner@test.invalid'),
  ('ae000000-0000-0000-0000-00000000000b', 'messung-redaktion@test.invalid');
select public.grant_admin_role('messung-owner@test.invalid', 'owner');
select public.grant_admin_role('messung-redaktion@test.invalid', 'editor');

insert into auth.users (id, email, raw_user_meta_data) values
  ('ae000000-0000-0000-0000-000000000001', 'messung@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('ae000000-0000-0000-0000-000000000002', 'messung-andere@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('ae000000-0000-0000-0000-0000000000d1', true);

insert into public.children (id, parent_id, nickname, birth_year, stage)
select v.id, p.id, v.nickname, 2015, 2
from public.parents p,
  (values ('ce000000-0000-0000-0000-000000000001'::uuid, 'Anna'),
          ('ce000000-0000-0000-0000-000000000002'::uuid, 'Ben'),
          ('ce000000-0000-0000-0000-000000000003'::uuid, 'Cem'),
          ('ce000000-0000-0000-0000-000000000004'::uuid, 'Dora')) v (id, nickname)
where p.user_id = 'ae000000-0000-0000-0000-000000000001';
insert into public.child_devices (user_id, child_id)
values ('ae000000-0000-0000-0000-0000000000d1', 'ce000000-0000-0000-0000-000000000001');

insert into public.islands (id, slug, stage, sort_order, title, status) values
  ('ee000000-0000-0000-0000-00000000000a', 'messinsel', 2, 60, 'Messinsel', 'draft');
insert into public.stations (id, island_id, sort_order, type, content, status) values
  ('fe000000-0000-0000-0000-000000000010', 'ee000000-0000-0000-0000-00000000000a', 10, 'quiz',
   '{"number": 1, "title": "Messstation"}', 'draft');

-- ---------------------------------------------------------------------------
-- Ereignisse melden
-- ---------------------------------------------------------------------------

select test_helpers.login('ae000000-0000-0000-0000-0000000000d1', 'aal1', true);
select public.track_event('ce000000-0000-0000-0000-000000000001', 'app_open');
select public.track_event('ce000000-0000-0000-0000-000000000001', 'app_open');
select public.track_event('ce000000-0000-0000-0000-000000000001', 'station_start',
  'fe000000-0000-0000-0000-000000000010');
select test_helpers.expect_error(
  $$select public.track_event('ce000000-0000-0000-0000-000000000002', 'app_open')$$,
  'nicht gefunden', 'Kinder-Gerät meldet nur für sein eigenes Kind');
select test_helpers.expect_error(
  $$select public.track_event('ce000000-0000-0000-0000-000000000001', 'werbung_gesehen')$$,
  'Unbekanntes Ereignis', 'Nur bekannte Ereignisse');
select test_helpers.expect_error(
  $$select public.track_event('ce000000-0000-0000-0000-000000000001', 'station_start')$$,
  'Station fehlt', 'Station begonnen braucht eine Station');
select test_helpers.expect_equal((select count(*) from public.analytics_events), 0,
  'Niemand liest die Ereignisse direkt');
select test_helpers.expect_error(
  $$insert into public.analytics_events (child_id, event_type) values ('ce000000-0000-0000-0000-000000000001', 'app_open')$$,
  'row-level security', 'Niemand schreibt Ereignisse direkt');
select test_helpers.logout();

select test_helpers.expect_equal(
  (select count(*) from public.analytics_events where child_id = 'ce000000-0000-0000-0000-000000000001'), 2,
  'Höchstens ein Eintrag pro Kind, Ereignis, Station und Tag');
select test_helpers.expect_true(
  (select bool_and(day = public.taleria_today()) from public.analytics_events
   where child_id = 'ce000000-0000-0000-0000-000000000001'),
  'Ereignisse speichern nur den Tag');

select test_helpers.login('ae000000-0000-0000-0000-000000000002');
select test_helpers.expect_error(
  $$select public.track_event('ce000000-0000-0000-0000-000000000003', 'app_open')$$,
  'nicht gefunden', 'Fremde Eltern melden nichts für fremde Kinder');
select test_helpers.logout();

-- Alte Ereignisse verschwinden beim nächsten Melden.
insert into public.analytics_events (child_id, event_type, day)
values ('ce000000-0000-0000-0000-000000000002', 'app_open', public.taleria_today() - 401);
select test_helpers.login('ae000000-0000-0000-0000-000000000001');
select public.track_event('ce000000-0000-0000-0000-000000000002', 'app_open');
select test_helpers.logout();
select test_helpers.expect_equal(
  (select count(*) from public.analytics_events where day < public.taleria_today() - 400), 0,
  'Ereignisse älter als 400 Tage werden gelöscht');

-- ---------------------------------------------------------------------------
-- Rückkehr nach 1 und 4 Wochen
-- ---------------------------------------------------------------------------

-- Anna: heute zum ersten Mal da (zählt noch nicht).
-- Ben:  vor 20 Tagen zum ersten Mal, in Woche 2 wieder da.
-- Cem:  vor 20 Tagen zum ersten Mal, danach nicht mehr.
-- Dora: vor 40 Tagen zum ersten Mal, in Woche 5 wieder da.
delete from public.analytics_events where child_id = 'ce000000-0000-0000-0000-000000000002';
insert into public.analytics_events (child_id, event_type, day) values
  ('ce000000-0000-0000-0000-000000000002', 'app_open', public.taleria_today() - 20),
  ('ce000000-0000-0000-0000-000000000002', 'app_open', public.taleria_today() - 12),
  ('ce000000-0000-0000-0000-000000000003', 'app_open', public.taleria_today() - 20),
  ('ce000000-0000-0000-0000-000000000004', 'app_open', public.taleria_today() - 40),
  ('ce000000-0000-0000-0000-000000000004', 'app_open', public.taleria_today() - 10);

select test_helpers.login('ae000000-0000-0000-0000-00000000000a', 'aal2');
select test_helpers.expect_true(
  (select (o ->> 'return_week1_cohort')::int = 3 and (o ->> 'return_week1_returned')::int = 1
      and (o ->> 'return_week4_cohort')::int = 1 and (o ->> 'return_week4_returned')::int = 1
   from public.admin_overview() o),
  'Rückkehr nach 1 Woche (1 von 3) und nach 4 Wochen (1 von 1)');
select test_helpers.expect_true(
  (select (s ->> 'started')::int = 1 and (s ->> 'done')::int = 0
   from jsonb_array_elements(public.admin_content_stats(2::smallint) -> 'islands') i,
        jsonb_array_elements(i -> 'stations') s
   where i ->> 'slug' = 'messinsel'),
  'Inhalte: begonnen und geschafft pro Station');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Fehlerprotokoll
-- ---------------------------------------------------------------------------

select test_helpers.login_anon();
select test_helpers.expect_error($$select public.report_app_error('ios', 'Fehler', null)$$,
  'permission denied', 'Ohne Anmeldung keine Fehlermeldung');
select test_helpers.logout();

select test_helpers.login('ae000000-0000-0000-0000-0000000000d1', 'aal1', true);
select public.report_app_error('ios', 'Null check operator used on a null value', '#0 MapScreen.build');
select public.report_app_error('ios', 'Null check operator used on a null value', '#0 MapScreen.build');
select public.report_app_error('handy', repeat('x', 900), repeat('y', 9000));
select public.report_app_error('android', '   ', null);
select test_helpers.expect_equal((select count(*) from public.app_errors), 0,
  'Niemand liest das Fehlerprotokoll direkt');
select test_helpers.logout();

select test_helpers.expect_equal((select count(*) from public.app_errors), 2,
  'Gleicher Fehler am selben Tag zählt hoch, leere Meldungen fallen weg');
select test_helpers.expect_true(
  (select count = 2 from public.app_errors where error like 'Null check%'),
  'Zähler für den gleichen Fehler');
select test_helpers.expect_true(
  (select platform = 'other' and char_length(error) = 500 and char_length(stack) = 4000
   from public.app_errors where error like 'xxx%'),
  'Unbekannte Plattform und zu lange Texte werden gekürzt');
select test_helpers.expect_true(
  (select not exists (
     select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'app_errors'
       and column_name in ('user_id', 'child_id', 'parent_id', 'device', 'ip'))),
  'Fehlerprotokoll ohne Nutzer und ohne Gerät');

-- Höchstens 500 verschiedene Fehler pro Tag.
insert into public.app_errors (fingerprint, platform, error)
select 'flut' || g, 'ios', 'Flut ' || g from generate_series(1, 498) g;
select test_helpers.login('ae000000-0000-0000-0000-0000000000d1', 'aal1', true);
select public.report_app_error('ios', 'Fehler Nummer 501', null);
select public.report_app_error('ios', 'Null check operator used on a null value', '#0 MapScreen.build');
select test_helpers.logout();
select test_helpers.expect_equal((select count(*) from public.app_errors where day = public.taleria_today()), 500,
  'Höchstens 500 verschiedene Fehler pro Tag');
select test_helpers.expect_true((select count = 3 from public.app_errors where error like 'Null check%'),
  'Bekannte Fehler zählen auch nach der Grenze weiter');
delete from public.app_errors where fingerprint like 'flut%';

select test_helpers.login('ae000000-0000-0000-0000-00000000000a', 'aal2');
select test_helpers.expect_true(
  (select e.error like 'Null check%' and e.total = 3 and e.days = 1 and e.stack = '#0 MapScreen.build'
   from public.admin_app_errors() e limit 1),
  'Owner sieht die häufigsten Fehler zuerst');
select test_helpers.expect_true(
  (select (o ->> 'app_errors_7d')::int = 4 from public.admin_overview() o),
  'Übersicht zählt die Fehler der letzten 7 Tage');
select test_helpers.logout();

select test_helpers.login('ae000000-0000-0000-0000-00000000000b', 'aal2');
select test_helpers.expect_error($$select * from public.admin_app_errors()$$, 'Nur für Admins',
  'Redaktion sieht das Fehlerprotokoll nicht');
select test_helpers.logout();

-- Mit dem Kinder-Profil verschwinden seine Ereignisse.
delete from public.children where id = 'ce000000-0000-0000-0000-000000000004';
select test_helpers.expect_equal(
  (select count(*) from public.analytics_events where child_id = 'ce000000-0000-0000-0000-000000000004'), 0,
  'Kinder-Profil löschen löscht seine Ereignisse');
