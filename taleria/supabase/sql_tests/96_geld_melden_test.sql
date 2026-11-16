-- Tests für „Geld melden“ (16.11.2026).
-- Ausführen mit: tool/db_test.sh

insert into auth.users (id, email, raw_user_meta_data) values
  ('a9600000-0000-0000-0000-000000000001', 'melden1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('a9600000-0000-0000-0000-000000000002', 'melden2@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('d9600000-0000-0000-0000-000000000001', true);

insert into public.children (id, parent_id, nickname, birth_year)
select 'c9600000-0000-0000-0000-000000000001', p.id, 'Ben', 2016
from public.parents p where p.user_id = 'a9600000-0000-0000-0000-000000000001';
insert into public.child_devices (user_id, child_id)
values ('d9600000-0000-0000-0000-000000000001', 'c9600000-0000-0000-0000-000000000001');

create function test_helpers.gift_total() returns bigint language sql as $$
  select coalesce(sum(amount_cents), 0) from public.ledger_entries
  where child_id = 'c9600000-0000-0000-0000-000000000001' and entry_type = 'gift';
$$;

-- Kind meldet 5 € von Oma; das bucht noch nichts.
select test_helpers.login('d9600000-0000-0000-0000-000000000001', 'aal1', true);
select public.report_money('c9600000-0000-0000-0000-000000000001', 500, 'Von Oma');
select test_helpers.expect_error(
  $$select public.report_money('c9600000-0000-0000-0000-000000000001', 0, 'nichts')$$,
  'Betrag nicht erlaubt', 'Kein Betrag von 0');
select test_helpers.expect_error(
  $$select public.review_money_report((select id from public.money_reports limit 1), true)$$,
  'Nur Eltern', 'Kind kann sich nichts selbst bestätigen');
select test_helpers.logout();
select test_helpers.expect_equal(test_helpers.gift_total(), 0, 'Gemeldetes Geld ist noch nicht gebucht');

-- Fremde Eltern dürfen nicht bestätigen.
select test_helpers.login('a9600000-0000-0000-0000-000000000002');
select test_helpers.expect_error(
  $$select public.review_money_report((select id from public.money_reports limit 1), true)$$,
  'Nur Eltern', 'Fremde Eltern bestätigen nichts');
select test_helpers.logout();

-- Eltern bestätigen: 5 € im freien Geld, genau einmal.
select test_helpers.login('a9600000-0000-0000-0000-000000000001');
select public.review_money_report(
  (select id from public.money_reports where child_id = 'c9600000-0000-0000-0000-000000000001'), true);
select test_helpers.expect_equal(test_helpers.gift_total(), 500, 'Bestätigt: 5 € gebucht');
select test_helpers.expect_error(
  $$select public.review_money_report((select id from public.money_reports limit 1), true)$$,
  'Schon entschieden', 'Nicht doppelt bestätigen');
select test_helpers.logout();

-- Abgelehnt bucht nichts.
select test_helpers.login('d9600000-0000-0000-0000-000000000001', 'aal1', true);
select public.report_money('c9600000-0000-0000-0000-000000000001', 9999, 'Lotto');
select test_helpers.logout();
select test_helpers.login('a9600000-0000-0000-0000-000000000001');
select public.review_money_report(
  (select id from public.money_reports where note = 'Lotto'), false);
select test_helpers.expect_equal(test_helpers.gift_total(), 500, 'Abgelehnt: nichts dazugekommen');
select test_helpers.logout();
