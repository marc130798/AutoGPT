-- Tests für Budget und Aufgaben (Schritt 5).
-- Ausführen mit: tool/db_test.sh

insert into auth.users (id, email, raw_user_meta_data) values
  ('a6000000-0000-0000-0000-000000000001', 'geld1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('a6000000-0000-0000-0000-000000000002', 'geld2@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('d6000000-0000-0000-0000-000000000001', true);

insert into public.children (id, parent_id, nickname, birth_year)
select 'c6000000-0000-0000-0000-000000000001', p.id, 'Lea', 2015
from public.parents p where p.user_id = 'a6000000-0000-0000-0000-000000000001';
insert into public.children (id, parent_id, nickname, birth_year)
select 'c6000000-0000-0000-0000-000000000002', p.id, 'Tom', 2014
from public.parents p where p.user_id = 'a6000000-0000-0000-0000-000000000002';
insert into public.child_devices (user_id, child_id)
values ('d6000000-0000-0000-0000-000000000001', 'c6000000-0000-0000-0000-000000000001');

create function test_helpers.balance(p_pot text) returns bigint language sql as $$
  select balance_cents from public.pot_balances('c6000000-0000-0000-0000-000000000001') where pot = p_pot;
$$;
grant execute on function test_helpers.balance(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Heuer
-- ---------------------------------------------------------------------------

select test_helpers.login('d6000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_error(
  $$select public.set_allowance('c6000000-0000-0000-0000-000000000001', 500, 'weekly')$$,
  'Nur für Eltern', 'Kind kann sich keine Heuer festlegen');
select test_helpers.logout();

select test_helpers.login('a6000000-0000-0000-0000-000000000002');
select test_helpers.expect_error(
  $$select public.set_allowance('c6000000-0000-0000-0000-000000000001', 500, 'weekly')$$,
  'Nur für Eltern', 'Fremde Eltern können keine Heuer festlegen');
select test_helpers.logout();

-- Erste Zahlung vor drei Wochen und einem Tag: 4 Zahlungen sind fällig.
select test_helpers.login('a6000000-0000-0000-0000-000000000001');
select public.set_allowance('c6000000-0000-0000-0000-000000000001', 500, 'weekly',
  now() - interval '21 days' - interval '1 day');
select test_helpers.expect_equal(public.process_due_allowances('c6000000-0000-0000-0000-000000000001'), 4,
  'Heuer: alle fälligen Wochen werden nachgezahlt');
select test_helpers.expect_equal(public.process_due_allowances('c6000000-0000-0000-0000-000000000001'), 0,
  'Heuer: zweiter Aufruf zahlt nichts doppelt');
select test_helpers.expect_equal(test_helpers.balance('spend'), 2000,
  'Heuer landet in der Bordkasse (4 × 5 €)');
select test_helpers.expect_true(
  (select next_run_at > now() and next_run_at < now() + interval '7 days' from public.allowance_rules),
  'Nächste Zahlung liegt in der nächsten Woche');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Aufträge
-- ---------------------------------------------------------------------------

select test_helpers.login('a6000000-0000-0000-0000-000000000001');
insert into public.tasks (id, parent_id, child_id, title, reward_cents)
values ('76000000-0000-0000-0000-000000000001', public.current_parent_id(),
        'c6000000-0000-0000-0000-000000000001', 'Rasen mähen', 300);
insert into public.tasks (id, parent_id, child_id, title, is_chore)
values ('76000000-0000-0000-0000-000000000002', public.current_parent_id(),
        'c6000000-0000-0000-0000-000000000001', 'Zimmer aufräumen', true);
select test_helpers.expect_error(
  $$insert into public.tasks (parent_id, child_id, title, reward_cents, is_chore)
    values (public.current_parent_id(), 'c6000000-0000-0000-0000-000000000001', 'Pflicht mit Geld', 100, true)$$,
  'tasks_chore_without_money', 'Pflichtaufgaben bringen kein Geld');
select test_helpers.expect_error(
  $$insert into public.tasks (parent_id, child_id, title, reward_cents)
    values (public.current_parent_id(), 'c6000000-0000-0000-0000-000000000002', 'Fremdes Kind', 100)$$,
  'row-level security', 'Eltern können keine Aufträge für fremde Kinder anlegen');
select test_helpers.expect_error(
  $$insert into public.tasks (parent_id, child_id, title, reward_cents, status)
    values (public.current_parent_id(), 'c6000000-0000-0000-0000-000000000001', 'Gleich erledigt', 100, 'approved')$$,
  'row-level security', 'Aufträge starten immer offen');
select test_helpers.logout();

select test_helpers.login('d6000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_equal((select count(*) from public.tasks), 2, 'Kind sieht seine Aufträge');
select test_helpers.expect_error(
  $$insert into public.tasks (parent_id, child_id, title, reward_cents)
    values ((select parent_id from public.children limit 1), 'c6000000-0000-0000-0000-000000000001', 'Selbst ausgedacht', 9999)$$,
  'row-level security', 'Kind kann sich keine Aufträge anlegen');
update public.tasks set status = 'approved';
select test_helpers.expect_equal((select count(*) from public.tasks where status = 'approved'), 0,
  'Kind kann den Status nicht direkt ändern');
select test_helpers.expect_error(
  $$select public.review_task('76000000-0000-0000-0000-000000000001', true)$$,
  'nicht gefunden', 'Kind kann seinen Auftrag nicht selbst bestätigen');
select public.submit_task('76000000-0000-0000-0000-000000000001');
select test_helpers.expect_true(
  (select status = 'submitted' and submitted_at is not null from public.tasks
   where id = '76000000-0000-0000-0000-000000000001'),
  'Kind meldet den Auftrag als erledigt');
select test_helpers.expect_error(
  $$select public.submit_task('76000000-0000-0000-0000-000000000001')$$,
  'wartet schon', 'Ein gemeldeter Auftrag wird nicht doppelt gemeldet');
select test_helpers.expect_equal(test_helpers.balance('spend'), 2000,
  'Gemeldet heißt noch nicht gutgeschrieben');
select test_helpers.logout();

select test_helpers.login('a6000000-0000-0000-0000-000000000001');
select public.review_task('76000000-0000-0000-0000-000000000001', false, 'Bitte noch die Kanten schneiden');
select test_helpers.expect_true(
  (select status = 'rejected' and parent_note = 'Bitte noch die Kanten schneiden' from public.tasks
   where id = '76000000-0000-0000-0000-000000000001'),
  'Eltern lehnen mit Nachricht ab');
select test_helpers.logout();

select test_helpers.login('d6000000-0000-0000-0000-000000000001', 'aal1', true);
select public.submit_task('76000000-0000-0000-0000-000000000001');
select test_helpers.logout();

select test_helpers.login('a6000000-0000-0000-0000-000000000001');
select public.review_task('76000000-0000-0000-0000-000000000001', true);
select test_helpers.expect_equal(test_helpers.balance('spend'), 2300,
  'Bestätigter Auftrag: Belohnung in der Bordkasse');
select test_helpers.expect_error(
  $$select public.review_task('76000000-0000-0000-0000-000000000001', true)$$,
  'kann nicht bestätigt', 'Ein Auftrag wird nur einmal bezahlt');
select public.review_task('76000000-0000-0000-0000-000000000002', true);
select test_helpers.expect_equal(test_helpers.balance('spend'), 2300,
  'Pflichtaufgabe: bestätigt, aber kein Geld');
-- Ohne passende Delete-Policy löscht ein DELETE einfach nichts.
delete from public.tasks where id = '76000000-0000-0000-0000-000000000001';
select test_helpers.expect_equal(
  (select count(*) from public.tasks where id = '76000000-0000-0000-0000-000000000001'), 1,
  'Bestätigte Aufträge bleiben als Beleg erhalten');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Truhen
-- ---------------------------------------------------------------------------

select test_helpers.login('d6000000-0000-0000-0000-000000000001', 'aal1', true);
select public.move_between_pots('c6000000-0000-0000-0000-000000000001', 'spend', 'save', 1000);
select public.move_between_pots('c6000000-0000-0000-0000-000000000001', 'spend', 'give', 200);
select test_helpers.expect_true(
  test_helpers.balance('spend') = 1100 and test_helpers.balance('save') = 1000 and test_helpers.balance('give') = 200,
  'Umbuchen: Bordkasse 11 €, Schatztruhe 10 €, Glückstruhe 2 €');
select test_helpers.expect_error(
  $$select public.move_between_pots('c6000000-0000-0000-0000-000000000001', 'give', 'spend', 500)$$,
  'Nicht genug', 'Keine Truhe geht ins Minus');
select test_helpers.expect_error(
  $$select public.move_between_pots('c6000000-0000-0000-0000-000000000001', 'spend', 'save', -500)$$,
  'größer als 0', 'Negative Umbuchung ist nicht erlaubt');

select public.record_spending('c6000000-0000-0000-0000-000000000001', 'spend', 350, 'Eis mit Freunden');
select public.record_spending('c6000000-0000-0000-0000-000000000001', 'give', 200, 'Spende Tierheim');
select test_helpers.expect_true(
  test_helpers.balance('spend') = 750 and test_helpers.balance('give') = 0,
  'Ausgabe und Geschenk werden abgezogen');
select test_helpers.expect_error(
  $$select public.record_spending('c6000000-0000-0000-0000-000000000001', 'save', 100, 'Heimlich')$$,
  'nur aus Bordkasse', 'Aus der Schatztruhe wird nicht direkt ausgegeben');
select test_helpers.expect_error(
  $$select public.record_spending('c6000000-0000-0000-0000-000000000001', 'spend', 100000, 'Zu viel')$$,
  'Nicht genug', 'Ausgabe größer als die Bordkasse wird abgelehnt');

select test_helpers.expect_error(
  $$select public.book_manual('c6000000-0000-0000-0000-000000000001', 'spend', 10000, 'Selbst gebucht')$$,
  'Nur für Eltern', 'Kind kann sich nichts selbst gutschreiben');
select test_helpers.expect_error(
  $$insert into public.ledger_entries (child_id, pot, amount_cents, entry_type)
    values ('c6000000-0000-0000-0000-000000000001', 'spend', 10000, 'manual')$$,
  'row-level security', 'Kind kann nicht direkt ins Kassenbuch schreiben');
select test_helpers.expect_error(
  $$select public.pot_balance('c6000000-0000-0000-0000-000000000002', 'spend')$$,
  'permission denied', 'Interne Guthaben-Funktion ist nicht direkt aufrufbar');

-- ---------------------------------------------------------------------------
-- Wunschschätze
-- ---------------------------------------------------------------------------

insert into public.savings_goals (id, child_id, title, target_cents)
values ('86000000-0000-0000-0000-000000000001', 'c6000000-0000-0000-0000-000000000001', 'Fußball', 1500);
select test_helpers.expect_error(
  $$select public.redeem_savings_goal('86000000-0000-0000-0000-000000000001')$$,
  'Nicht genug', 'Wunschschatz erst einlösbar, wenn genug in der Schatztruhe ist');
update public.savings_goals set target_cents = 1000 where id = '86000000-0000-0000-0000-000000000001';
select test_helpers.expect_error(
  $$update public.savings_goals set reached_at = now() where id = '86000000-0000-0000-0000-000000000001'$$,
  'row-level security', 'Kind kann einen Wunschschatz nicht selbst als erreicht markieren');
select test_helpers.expect_true(
  (select target_cents = 1000 and reached_at is null from public.savings_goals
   where id = '86000000-0000-0000-0000-000000000001'),
  'Kind ändert den Betrag eines offenen Wunschschatzes');
select public.redeem_savings_goal('86000000-0000-0000-0000-000000000001');
select test_helpers.expect_true(
  (select reached_at is not null from public.savings_goals where id = '86000000-0000-0000-0000-000000000001')
  and test_helpers.balance('save') = 0,
  'Wunschschatz eingelöst: Betrag aus der Schatztruhe, Wunsch erfüllt');
select test_helpers.expect_error(
  $$select public.redeem_savings_goal('86000000-0000-0000-0000-000000000001')$$,
  'schon eingelöst', 'Ein Wunschschatz wird nur einmal eingelöst');
delete from public.savings_goals where id = '86000000-0000-0000-0000-000000000001';
select test_helpers.expect_equal(
  (select count(*) from public.savings_goals where id = '86000000-0000-0000-0000-000000000001'), 1,
  'Eingelöste Wunschschätze bleiben erhalten');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Eltern, fremde Familien, Kassenbuch
-- ---------------------------------------------------------------------------

select test_helpers.login('a6000000-0000-0000-0000-000000000001');
select public.book_manual('c6000000-0000-0000-0000-000000000001', 'spend', -250, 'Korrektur');
select test_helpers.expect_equal(test_helpers.balance('spend'), 500, 'Eltern buchen eine Korrektur');
select test_helpers.expect_error(
  $$select public.book_manual('c6000000-0000-0000-0000-000000000001', 'spend', -10000, 'Zu viel')$$,
  'Nicht genug', 'Auch Korrekturen bringen keine Truhe ins Minus');
select test_helpers.logout();

select test_helpers.login('a6000000-0000-0000-0000-000000000002');
select test_helpers.expect_equal((select count(*) from public.ledger_entries), 0,
  'Fremde Eltern sehen kein Kassenbuch');
select test_helpers.expect_equal(
  (select count(*) from public.pot_balances('c6000000-0000-0000-0000-000000000001')), 0,
  'Fremde Eltern sehen kein Guthaben');
select test_helpers.expect_error(
  $$select public.move_between_pots('c6000000-0000-0000-0000-000000000001', 'spend', 'save', 100)$$,
  'nicht gefunden', 'Fremde Eltern können nicht umbuchen');
select test_helpers.logout();

select test_helpers.expect_error(
  $$update public.ledger_entries set amount_cents = 999999$$,
  'nur ergänzt', 'Das Kassenbuch lässt sich nicht ändern');
select test_helpers.expect_equal(
  (select sum(amount_cents) from public.ledger_entries where child_id = 'c6000000-0000-0000-0000-000000000001'),
  500, 'Guthaben ist die Summe aller Einträge');
