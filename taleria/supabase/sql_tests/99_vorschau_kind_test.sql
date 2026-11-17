-- Tests für das Vorschau-Kind (17.11.2026).
-- Ausführen mit: tool/db_test.sh
--
-- Zwei eigene Inseln der Hauptroute in Stufe 2 ganz hinten (Reihenfolge 900
-- und 901), die zweite gehört zum Abo. Ohne Vorschau sind beide gesperrt.

insert into auth.users (id, email, raw_user_meta_data) values
  ('a9900000-0000-0000-0000-000000000001', 'vorschau1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('a9900000-0000-0000-0000-000000000002', 'vorschau2@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');

insert into public.children (id, parent_id, nickname, birth_year, stage)
select 'c9900000-0000-0000-0000-000000000001', p.id, 'Vorschau', 2015, 2
from public.parents p where p.user_id = 'a9900000-0000-0000-0000-000000000001';

insert into public.islands (id, slug, stage, sort_order, title, route_type, status, content) values
  ('e9900000-0000-0000-0000-00000000000a', 'vorschau-a', 2, 900, 'Vorschau A', 'main', 'draft', '{}'),
  ('e9900000-0000-0000-0000-00000000000b', 'vorschau-b', 2, 901, 'Vorschau B', 'main', 'draft', '{"access": "premium"}');
insert into public.stations (id, island_id, sort_order, type, xp_reward, content, status) values
  ('f9900000-0000-0000-0000-000000000010', 'e9900000-0000-0000-0000-00000000000b', 10, 'quiz', 100, '{"quiz": {"show": 1}}', 'published'),
  ('f9900000-0000-0000-0000-000000000020', 'e9900000-0000-0000-0000-00000000000b', 20, 'quiz', 100, '{"quiz": {"show": 1}}', 'published');

create function test_helpers.preview_open(p_station uuid) returns boolean language sql as $$
  select public.station_unlocked('c9900000-0000-0000-0000-000000000001', p_station);
$$;

select test_helpers.expect_true(
  not test_helpers.preview_open('f9900000-0000-0000-0000-000000000020'),
  'Ohne Vorschau ist die zweite Station gesperrt');

-- Ohne Test-Einstellung (wie in Live) geht die Vorschau nicht.
delete from public.app_settings where key = 'test_purchases';
select test_helpers.login('a9900000-0000-0000-0000-000000000001');
select test_helpers.expect_error(
  $$select public.set_child_preview('c9900000-0000-0000-0000-000000000001', true)$$,
  'nur im Testprojekt', 'In Live gibt es keine Vorschau');
select test_helpers.logout();

-- Selbst wenn die Spalte gesetzt wäre: ohne Test-Einstellung wirkt sie nicht.
update public.children set preview_all = true where id = 'c9900000-0000-0000-0000-000000000001';
select test_helpers.expect_true(
  not test_helpers.preview_open('f9900000-0000-0000-0000-000000000020'),
  'Vorschau wirkt nur im Testprojekt');
update public.children set preview_all = false where id = 'c9900000-0000-0000-0000-000000000001';

insert into public.app_settings (key, value) values ('test_purchases', 'true'::jsonb);

-- Fremde Eltern dürfen nicht schalten.
select test_helpers.login('a9900000-0000-0000-0000-000000000002');
select test_helpers.expect_error(
  $$select public.set_child_preview('c9900000-0000-0000-0000-000000000001', true)$$,
  'Nur Eltern', 'Fremde Eltern schalten keine Vorschau');
select test_helpers.logout();

select test_helpers.login('a9900000-0000-0000-0000-000000000001');
select public.set_child_preview('c9900000-0000-0000-0000-000000000001', true);
select test_helpers.logout();
select test_helpers.expect_true(
  test_helpers.preview_open('f9900000-0000-0000-0000-000000000020'),
  'Vorschau: Abo-Insel ohne Abo und ohne die Insel davor, Station ohne die davor');
select test_helpers.expect_true(
  (select stations_per_week is null from public.children where id = 'c9900000-0000-0000-0000-000000000001'),
  'Vorschau: freie Fahrt, kein Wind nötig');

-- Ausschalten: wieder normal, 2 Stationen pro Woche.
select test_helpers.login('a9900000-0000-0000-0000-000000000001');
select public.set_child_preview('c9900000-0000-0000-0000-000000000001', false);
select test_helpers.logout();
select test_helpers.expect_true(
  not test_helpers.preview_open('f9900000-0000-0000-0000-000000000020')
    and (select stations_per_week = 2 from public.children where id = 'c9900000-0000-0000-0000-000000000001'),
  'Vorschau aus: wieder gesperrt und 2 pro Woche');

delete from public.app_settings where key = 'test_purchases';
