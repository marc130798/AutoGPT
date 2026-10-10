-- Tests für das Intro (Schritt 3).
-- Ausführen mit: tool/db_test.sh

insert into auth.users (id, email, raw_user_meta_data) values
  ('a3000000-0000-0000-0000-000000000001', 'intro1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('a3000000-0000-0000-0000-000000000002', 'intro2@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('d3000000-0000-0000-0000-000000000001', true);

insert into public.children (id, parent_id, nickname, birth_year)
select 'c3000000-0000-0000-0000-000000000001', p.id, 'Ida', 2015
from public.parents p where p.user_id = 'a3000000-0000-0000-0000-000000000001';
insert into public.children (id, parent_id, nickname, birth_year)
select 'c3000000-0000-0000-0000-000000000002', p.id, 'Ole', 2014
from public.parents p where p.user_id = 'a3000000-0000-0000-0000-000000000002';
insert into public.child_devices (user_id, child_id)
values ('d3000000-0000-0000-0000-000000000001', 'c3000000-0000-0000-0000-000000000001');

-- ---------------------------------------------------------------------------
-- Kinder-Gerät gestaltet Avatar und Schiff
-- ---------------------------------------------------------------------------

select test_helpers.login('d3000000-0000-0000-0000-000000000001', 'aal1', true);

select public.update_child_look('c3000000-0000-0000-0000-000000000001', '{"skin": "s3", "hat": "captain"}', null);
select public.update_child_look('c3000000-0000-0000-0000-000000000001', null, '  Seestern ');
select test_helpers.expect_true(
  (select avatar ->> 'hat' = 'captain' and ship_name = 'Seestern' from public.children),
  'Kinder-Gerät speichert Avatar und Schiffsname');

select test_helpers.expect_error(
  $$select public.update_child_look('c3000000-0000-0000-0000-000000000001', null, 'X')$$,
  'children_ship_name_check', 'Schiffsname braucht mindestens 2 Zeichen');
select test_helpers.expect_error(
  $$select public.update_child_look('c3000000-0000-0000-0000-000000000001', '["kein", "Objekt"]', null)$$,
  'children_avatar_check', 'Avatar muss ein Objekt sein');
select test_helpers.expect_error(
  $$select public.update_child_look('c3000000-0000-0000-0000-000000000001',
      jsonb_build_object('x', repeat('a', 2000)), null)$$,
  'children_avatar_check', 'Avatar darf nicht riesig sein');
select test_helpers.expect_error(
  $$select public.update_child_look('c3000000-0000-0000-0000-000000000002', '{}', 'Fremd')$$,
  'nicht gefunden', 'Kinder-Gerät kann fremde Profile nicht ändern');

-- Form der Rang-Namen (Schiffsjunge oder Schiffsmädchen)
select test_helpers.expect_true(
  (select rank_form is null from public.children), 'Neues Kind: Form der Rang-Namen noch nicht gewählt');
select public.update_child_look('c3000000-0000-0000-0000-000000000001', null, null, 'maedchen');
select test_helpers.expect_true(
  (select rank_form = 'maedchen' and ship_name = 'Seestern' and avatar ->> 'hat' = 'captain' from public.children),
  'Kinder-Gerät wählt die Form der Rang-Namen, Avatar und Schiff bleiben');
select public.update_child_look('c3000000-0000-0000-0000-000000000001', null, 'Seestern');
select test_helpers.expect_true(
  (select rank_form = 'maedchen' from public.children), 'Ohne Angabe bleibt die gewählte Form');
select test_helpers.expect_error(
  $$select public.update_child_look('c3000000-0000-0000-0000-000000000001', null, null, 'pirat')$$,
  'children_rank_form_check', 'Nur junge oder maedchen');
select test_helpers.expect_error(
  $$select public.update_child_look('c3000000-0000-0000-0000-000000000002', null, null, 'junge')$$,
  'nicht gefunden', 'Kinder-Gerät ändert die Form nicht bei fremden Kindern');
select test_helpers.expect_error(
  $$update public.children set rank_form = 'junge'$$,
  'permission denied', 'Direkt ändern geht nicht, nur über update_child_look');

select test_helpers.login('a3000000-0000-0000-0000-000000000001');
select public.update_child_look('c3000000-0000-0000-0000-000000000001', null, null, 'junge');
select test_helpers.expect_true(
  (select rank_form = 'junge' from public.children where id = 'c3000000-0000-0000-0000-000000000001'),
  'Eltern ändern die Form im Leuchtturm');
select public.update_child_look('c3000000-0000-0000-0000-000000000001', null, null, 'maedchen');
select test_helpers.login('d3000000-0000-0000-0000-000000000001', 'aal1', true);

-- ---------------------------------------------------------------------------
-- Erster Wunschschatz
-- ---------------------------------------------------------------------------

insert into public.savings_goals (child_id, title, target_cents)
values ('c3000000-0000-0000-0000-000000000001', 'Fahrradhelm', 4000);
select test_helpers.expect_equal((select count(*) from public.savings_goals), 1,
  'Kinder-Gerät legt einen Wunschschatz an');
select test_helpers.expect_error(
  $$insert into public.savings_goals (child_id, title, target_cents)
    values ('c3000000-0000-0000-0000-000000000002', 'Fremd', 1000)$$,
  'row-level security', 'Kein Wunschschatz für fremde Kinder');
select test_helpers.expect_error(
  $$insert into public.savings_goals (child_id, title, target_cents)
    values ('c3000000-0000-0000-0000-000000000001', 'Zu billig', 50)$$,
  'savings_goals_target_cents_check', 'Wunschschatz kostet mindestens 1 Euro');
select test_helpers.expect_error(
  $$insert into public.savings_goals (child_id, title, target_cents, reached_at)
    values ('c3000000-0000-0000-0000-000000000001', 'Schon erreicht', 1000, now())$$,
  'row-level security', 'Kind kann einen Wunschschatz nicht selbst als erreicht anlegen');

-- ---------------------------------------------------------------------------
-- Intro abschließen und Seemeilen
-- ---------------------------------------------------------------------------

select test_helpers.expect_error(
  $$insert into public.xp_events (child_id, source_type, source_id, amount)
    values ('c3000000-0000-0000-0000-000000000001', 'cheat', gen_random_uuid(), 9999)$$,
  'row-level security', 'Kind kann sich keine Seemeilen selbst buchen');

select test_helpers.expect_equal(
  public.complete_onboarding('c3000000-0000-0000-0000-000000000001'), 50,
  'Intro abschließen bringt 50 Seemeilen');
select test_helpers.expect_equal(
  public.complete_onboarding('c3000000-0000-0000-0000-000000000001'), 0,
  'Ein zweites Mal gibt es keine Seemeilen');
select test_helpers.expect_equal(
  (select sum(amount) from public.xp_events), 50,
  'Kind sieht seine Seemeilen');
select test_helpers.expect_true(
  (select onboarding_completed_at is not null from public.children),
  'Intro ist als abgeschlossen gespeichert');
select test_helpers.expect_error(
  $$select public.complete_onboarding('c3000000-0000-0000-0000-000000000002')$$,
  'nicht gefunden', 'Kinder-Gerät kann kein fremdes Intro abschließen');
select test_helpers.logout();

-- Eltern sehen Seemeilen und Wunschschätze ihres Kindes, aber nicht fremde.
select test_helpers.login('a3000000-0000-0000-0000-000000000001');
select test_helpers.expect_equal((select count(*) from public.savings_goals), 1,
  'Eltern sehen den Wunschschatz ihres Kindes');
select test_helpers.expect_equal((select coalesce(sum(amount), 0) from public.xp_events), 50,
  'Eltern sehen die Seemeilen ihres Kindes');
select test_helpers.logout();

select test_helpers.login('a3000000-0000-0000-0000-000000000002');
select test_helpers.expect_equal((select count(*) from public.savings_goals), 0,
  'Fremde Eltern sehen keine Wunschschätze');
select test_helpers.expect_equal((select count(*) from public.xp_events), 0,
  'Fremde Eltern sehen keine Seemeilen');
-- Eltern können das Intro ihres eigenen Kindes abschließen (Kind spielt auf dem Eltern-Gerät).
select test_helpers.expect_equal(
  public.complete_onboarding('c3000000-0000-0000-0000-000000000002'), 50,
  'Eltern-Gerät schließt das Intro des eigenen Kindes ab');
select test_helpers.logout();
