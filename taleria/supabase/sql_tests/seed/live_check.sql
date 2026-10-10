-- Prüft den geprüften Import für die Live-Datenbank (supabase/inhalte_live.sql).
-- Läuft nach: Import als Entwurf (zweimal), dann die Variante „alles freigegeben“ (zweimal).

select test_helpers.expect_equal(
  (select count(*) from public.app_settings where key in ('content_preview', 'test_purchases')), 0,
  'Live-Import: keine Inhalts-Vorschau und kein Test-Abo');
select test_helpers.expect_equal((select count(*) from public.islands where status <> 'published'), 0,
  'Live-Import: freigegebene Inseln sind veröffentlicht');
select test_helpers.expect_equal((select count(*) from public.stations where status <> 'published'), 0,
  'Live-Import: Stationen freigegebener Inseln sind veröffentlicht');
select test_helpers.expect_equal((select count(*) from public.content_versions), 0,
  'Live-Import: erneuter Import ohne Änderung legt keine früheren Fassungen an');

-- Ein Kind in der Live-Datenbank sieht den Hafen mit Inhalt (ohne Vorschau).
insert into auth.users (id, email, raw_user_meta_data) values
  ('a6000000-0000-0000-0000-000000000001', 'live@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('d6000000-0000-0000-0000-000000000001', true);
insert into public.children (id, parent_id, nickname, birth_year)
select 'c6000000-0000-0000-0000-000000000001', p.id, 'Live', 2015 from public.parents p;
insert into public.child_devices (user_id, child_id)
values ('d6000000-0000-0000-0000-000000000001', 'c6000000-0000-0000-0000-000000000001');

select test_helpers.login('d6000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select has_content from public.map_islands(1::smallint) where slug = 'hafen'),
  'Live-Import: Kinder sehen freigegebene Inseln');
select test_helpers.expect_true(
  (select not has_content from public.map_islands(1::smallint) where slug = 'spar-insel'),
  'Live-Import: Inseln ohne Stationen bleiben im Nebel');
select test_helpers.logout();
