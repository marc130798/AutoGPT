-- Tests für die Wunschflasche.
-- Ausführen mit: tool/db_test.sh

insert into auth.users (id, email, raw_user_meta_data) values
  ('af000000-0000-0000-0000-000000000001', 'flasche@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('af000000-0000-0000-0000-000000000002', 'flasche-andere@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('af000000-0000-0000-0000-0000000000d1', true);

insert into public.children (id, parent_id, nickname, birth_year, stage)
select v.id, p.id, v.nickname, 2015, 2
from public.parents p,
  (values ('cf000000-0000-0000-0000-000000000001'::uuid, 'Flo'),
          ('cf000000-0000-0000-0000-000000000002'::uuid, 'Gil')) v (id, nickname)
where p.user_id = 'af000000-0000-0000-0000-000000000001';
insert into public.child_devices (user_id, child_id)
values ('af000000-0000-0000-0000-0000000000d1', 'cf000000-0000-0000-0000-000000000001');

-- Station mit dem Spiel „Wunschflasche“ (schaltet die Wunschflaschen frei).
insert into public.islands (id, slug, stage, sort_order, title, status) values
  ('ef000000-0000-0000-0000-00000000000a', 'flascheninsel', 2, 70, 'Flascheninsel', 'draft');
insert into public.stations (id, island_id, sort_order, type, content, status) values
  ('ff000000-0000-0000-0000-000000000010', 'ef000000-0000-0000-0000-00000000000a', 10, 'game',
   '{"number": 1, "title": "Die Warte-Regel", "game": {"type": "wish_bottle", "title": "Wunschflasche"}}', 'draft');

-- ---------------------------------------------------------------------------
-- Wunsch in die Flasche
-- ---------------------------------------------------------------------------

select test_helpers.login('af000000-0000-0000-0000-0000000000d1', 'aal1', true);
select test_helpers.expect_true(
  (select s ->> 'unlocked' = 'false' and (s ->> 'due')::int = 0
   from public.wish_bottle_status('cf000000-0000-0000-0000-000000000001') s),
  'Ohne Station und ohne Flasche noch nicht freigeschaltet');
select set_config('test.small',
  public.create_wish_bottle('cf000000-0000-0000-0000-000000000001', ' Comic ', 450, false)::text, false);
select set_config('test.big',
  public.create_wish_bottle('cf000000-0000-0000-0000-000000000001', 'Fahrrad', null, true)::text, false);
select test_helpers.expect_true(
  (select title = 'Comic' and price_cents = 450 and not is_big and decision = 'open'
      and remind_at = public.day_start(public.taleria_today() + 1)
   from public.wish_bottles where id = current_setting('test.small')::uuid),
  'Kleiner Wunsch: die App fragt ab morgen nach');
select test_helpers.expect_true(
  (select is_big and price_cents is null and remind_at = public.day_start(public.taleria_today() + 7)
   from public.wish_bottles where id = current_setting('test.big')::uuid),
  'Großer Wunsch: die App fragt nach einer Woche nach');
select test_helpers.expect_true(
  (select s ->> 'unlocked' = 'true' and (s ->> 'due')::int = 0
   from public.wish_bottle_status('cf000000-0000-0000-0000-000000000001') s),
  'Mit einer Flasche freigeschaltet, noch keine angespült');
select test_helpers.expect_error(
  $$select public.decide_wish_bottle(current_setting('test.small')::uuid, true, null)$$,
  'treibt noch', 'Wunschschatz erst nach der Wartezeit');
select test_helpers.expect_error(
  $$select public.create_wish_bottle('cf000000-0000-0000-0000-000000000002', 'Ball', null, false)$$,
  'nicht gefunden', 'Kinder-Gerät nur für das eigene Kind');
select test_helpers.expect_error(
  $$insert into public.wish_bottles (child_id, title, remind_at)
    values ('cf000000-0000-0000-0000-000000000001', 'Trick', now())$$,
  'row-level security', 'Flaschen nur über die Funktion');
select test_helpers.expect_error(
  $$select public.create_wish_bottle('cf000000-0000-0000-0000-000000000001', 'X', null, false)$$,
  'check', 'Titel braucht mindestens 2 Zeichen');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Nach der Wartezeit
-- ---------------------------------------------------------------------------

update public.wish_bottles set remind_at = now() - interval '1 minute'
where id in (current_setting('test.small')::uuid, current_setting('test.big')::uuid);

select test_helpers.login('af000000-0000-0000-0000-0000000000d1', 'aal1', true);
select test_helpers.expect_true(
  (select (s ->> 'due')::int = 2 from public.wish_bottle_status('cf000000-0000-0000-0000-000000000001') s),
  'Zwei Flaschen sind angespült');
select test_helpers.expect_true(
  (select count(*) = 2 and bool_and(due) from public.open_wish_bottles('cf000000-0000-0000-0000-000000000001')),
  'Offene Flaschen mit „angespült“ vom Server');
select test_helpers.expect_error(
  $$select public.decide_wish_bottle(current_setting('test.big')::uuid, true, null)$$,
  'Preis', 'Ohne Preis kein Wunschschatz');
select set_config('test.goal',
  public.decide_wish_bottle(current_setting('test.big')::uuid, true, 15000)::text, false);
select test_helpers.expect_true(
  (select g.title = 'Fahrrad' and g.target_cents = 15000 and g.reached_at is null
   from public.savings_goals g where g.id = current_setting('test.goal')::uuid),
  'Aus der Flasche wird ein Wunschschatz mit dem eingegebenen Preis');
select test_helpers.expect_true(
  (select decision = 'converted' and decided_at is not null and savings_goal_id = current_setting('test.goal')::uuid
   from public.wish_bottles where id = current_setting('test.big')::uuid),
  'Die Flasche merkt sich den Wunschschatz');
select test_helpers.expect_error(
  $$select public.decide_wish_bottle(current_setting('test.small')::uuid, true, 50)$$,
  'Preis', 'Wunschschatz ab 1 Euro');
select test_helpers.expect_true(
  public.decide_wish_bottle(current_setting('test.small')::uuid, false) is null,
  'Loslassen');
select test_helpers.expect_error(
  $$select public.decide_wish_bottle(current_setting('test.small')::uuid, true, null)$$,
  'schon entschieden', 'Entschieden ist entschieden');
select test_helpers.expect_true(
  (select (s ->> 'due')::int = 0 from public.wish_bottle_status('cf000000-0000-0000-0000-000000000001') s),
  'Keine Flasche mehr angespült');
select set_config('test.early',
  public.create_wish_bottle('cf000000-0000-0000-0000-000000000001', 'Kino', 900, false)::text, false);
select test_helpers.expect_true(
  public.decide_wish_bottle(current_setting('test.early')::uuid, false) is null,
  'Loslassen geht auch vor der Wartezeit');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Grenzen, fremde Familien, Freischalten über die Station
-- ---------------------------------------------------------------------------

select test_helpers.login('af000000-0000-0000-0000-000000000001');
select public.create_wish_bottle('cf000000-0000-0000-0000-000000000002', 'Wunsch ' || g, null, false)
from generate_series(1, 10) g;
select test_helpers.expect_error(
  $$select public.create_wish_bottle('cf000000-0000-0000-0000-000000000002', 'Elfter', null, false)$$,
  'Höchstens 10', 'Höchstens 10 Flaschen treiben gleichzeitig');
select test_helpers.logout();

select test_helpers.login('af000000-0000-0000-0000-000000000002');
select test_helpers.expect_equal(
  (select count(*) from public.wish_bottles where child_id = 'cf000000-0000-0000-0000-000000000001'), 0,
  'Fremde Eltern sehen keine Flaschen');
select test_helpers.expect_error(
  $$select public.decide_wish_bottle(current_setting('test.big')::uuid, false)$$,
  'nicht gefunden', 'Fremde Eltern entscheiden nichts');
select test_helpers.expect_error(
  $$select * from public.open_wish_bottles('cf000000-0000-0000-0000-000000000001')$$,
  'nicht gefunden', 'Fremde Eltern lesen keine Flaschen');
select test_helpers.logout();

delete from public.wish_bottles where child_id = 'cf000000-0000-0000-0000-000000000002';
insert into public.station_progress (child_id, station_id, status, completed_at)
values ('cf000000-0000-0000-0000-000000000002', 'ff000000-0000-0000-0000-000000000010', 'done', now());
select test_helpers.login('af000000-0000-0000-0000-000000000001');
select test_helpers.expect_true(
  (select s ->> 'unlocked' = 'true' from public.wish_bottle_status('cf000000-0000-0000-0000-000000000002') s),
  'Nach der Station mit der Wunschflasche dauerhaft freigeschaltet, auch ohne Flasche');
select test_helpers.logout();
