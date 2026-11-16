-- Tests für die Lern-Belohnung (16.11.2026).
-- Ausführen mit: tool/db_test.sh

insert into auth.users (id, email, raw_user_meta_data) values
  ('a9500000-0000-0000-0000-000000000001', 'lernen1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('a9500000-0000-0000-0000-000000000002', 'lernen2@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('d9500000-0000-0000-0000-000000000001', true);

insert into public.children (id, parent_id, nickname, birth_year)
select 'c9500000-0000-0000-0000-000000000001', p.id, 'Mia', 2016
from public.parents p where p.user_id = 'a9500000-0000-0000-0000-000000000001';
insert into public.child_devices (user_id, child_id)
values ('d9500000-0000-0000-0000-000000000001', 'c9500000-0000-0000-0000-000000000001');

insert into public.islands (id, slug, stage, sort_order, title, status) values
  ('e9500000-0000-0000-0000-00000000000a', 'lern-insel', 2, 50, 'Lern-Insel', 'draft');
insert into public.stations (id, island_id, sort_order, type, xp_reward, content, status) values
  ('f9500000-0000-0000-0000-0000000000a1', 'e9500000-0000-0000-0000-00000000000a', 10, 'quiz', 100,
   '{"title": "Erste Station"}', 'draft'),
  ('f9500000-0000-0000-0000-0000000000a2', 'e9500000-0000-0000-0000-00000000000a', 15, 'review_stop', 50,
   '{"title": "Ankerplatz"}', 'draft'),
  ('f9500000-0000-0000-0000-0000000000a3', 'e9500000-0000-0000-0000-00000000000a', 20, 'exam', 150,
   '{"title": "Prüfung"}', 'draft');

create function test_helpers.learning_total() returns bigint language sql as $$
  select coalesce(sum(amount_cents), 0) from public.ledger_entries
  where child_id = 'c9500000-0000-0000-0000-000000000001' and entry_type = 'learning';
$$;

-- Nur Eltern legen fest, und nur für eigene Kinder.
select test_helpers.login('d9500000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_error(
  $$select public.set_learning_rewards('c9500000-0000-0000-0000-000000000001', 100, 1000)$$,
  'Nur Eltern', 'Kind kann sich keine Lern-Belohnung festlegen');
select test_helpers.logout();
select test_helpers.login('a9500000-0000-0000-0000-000000000002');
select test_helpers.expect_error(
  $$select public.set_learning_rewards('c9500000-0000-0000-0000-000000000001', 100, 1000)$$,
  'Nur Eltern', 'Fremde Eltern können nichts festlegen');
select test_helpers.logout();

-- Ohne Einstellung (aus) gibt es kein Geld.
insert into public.station_progress (child_id, station_id, status, completed_at)
values ('c9500000-0000-0000-0000-000000000001', 'f9500000-0000-0000-0000-0000000000a2', 'done', now());
select test_helpers.expect_equal(test_helpers.learning_total(), 0, 'Ohne Einstellung kein Geld');

select test_helpers.login('a9500000-0000-0000-0000-000000000001');
select test_helpers.expect_error(
  $$select public.set_learning_rewards('c9500000-0000-0000-0000-000000000001', -5, 0)$$,
  'Betrag nicht erlaubt', 'Kein negativer Betrag');
select public.set_learning_rewards('c9500000-0000-0000-0000-000000000001', 100, 1000);
select test_helpers.expect_equal(
  (select station_cents from public.learning_rewards where child_id = 'c9500000-0000-0000-0000-000000000001'),
  100, 'Eltern sehen ihre Einstellung');
select test_helpers.logout();

-- Station zum ersten Mal geschafft: 1 €. Nochmal schaffen: nichts.
insert into public.station_progress (child_id, station_id, status, completed_at)
values ('c9500000-0000-0000-0000-000000000001', 'f9500000-0000-0000-0000-0000000000a1', 'done', now());
select test_helpers.expect_equal(test_helpers.learning_total(), 100, 'Erste Station bringt 1 €');
update public.station_progress set attempts = attempts + 1, last_score = 3
where child_id = 'c9500000-0000-0000-0000-000000000001' and station_id = 'f9500000-0000-0000-0000-0000000000a1';
select test_helpers.expect_equal(test_helpers.learning_total(), 100, 'Wiederholen bringt kein Geld');

-- Ankerplatz und Prüfung bringen kein Stationsgeld.
insert into public.station_progress (child_id, station_id, status, completed_at)
values ('c9500000-0000-0000-0000-000000000001', 'f9500000-0000-0000-0000-0000000000a3', 'done', now());
select test_helpers.expect_equal(test_helpers.learning_total(), 100, 'Prüfung zählt nicht als Station');

-- Insel abgeschlossen: 10 €, genau einmal.
insert into public.island_completions (child_id, island_id)
values ('c9500000-0000-0000-0000-000000000001', 'e9500000-0000-0000-0000-00000000000a');
select test_helpers.expect_equal(test_helpers.learning_total(), 1100, 'Insel bringt 10 €');
select test_helpers.expect_equal(
  (select count(*) from public.ledger_entries
   where child_id = 'c9500000-0000-0000-0000-000000000001' and entry_type = 'learning' and pot = 'spend'),
  2, 'Beides landet im freien Geld');

-- Das Kind sieht die Einstellung (für den Hinweis im Ergebnis).
select test_helpers.login('d9500000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_equal(
  (select island_cents from public.learning_rewards where child_id = 'c9500000-0000-0000-0000-000000000001'),
  1000, 'Kinder-Gerät sieht die Lern-Belohnung');
select test_helpers.logout();
