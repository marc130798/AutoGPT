-- Tests für „Gemeinsam“: Erklär's deinen Eltern und Crew-Abenteuer mit Eltern-Code (24.11.2026).
-- Ausführen mit: tool/db_test.sh

insert into auth.users (id, email, raw_user_meta_data) values
  ('a9a00000-0000-0000-0000-000000000001', 'crew1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('a9a00000-0000-0000-0000-000000000002', 'crew2@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('d9a00000-0000-0000-0000-000000000001', true);
insert into public.children (id, parent_id, nickname, birth_year)
select 'c9a00000-0000-0000-0000-000000000001', p.id, 'Ole', 2016
from public.parents p where p.user_id = 'a9a00000-0000-0000-0000-000000000001';
insert into public.child_devices (user_id, child_id)
values ('d9a00000-0000-0000-0000-000000000001', 'c9a00000-0000-0000-0000-000000000001');
insert into public.islands (id, slug, stage, sort_order, title, status) values
  ('e9a00000-0000-0000-0000-00000000000a', 'crew-insel', 2, 60, 'Crew-Insel', 'draft');

create function test_helpers.crew_xp() returns bigint language sql as $$
  select coalesce(sum(amount), 0) from public.xp_events
  where child_id = 'c9a00000-0000-0000-0000-000000000001' and source_type like 'crew_%';
$$;

-- Nur die eigenen Eltern rufen Codes ab.
select test_helpers.login('d9a00000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_error(
  $$select public.crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a', 'explain')$$,
  'Nur Eltern', 'Kind kann sich keinen Code holen');
select test_helpers.logout();
select test_helpers.login('a9a00000-0000-0000-0000-000000000002');
select test_helpers.expect_error(
  $$select public.crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a', 'explain')$$,
  'Nur Eltern', 'Fremde Eltern bekommen keinen Code');
select test_helpers.logout();

-- Erklären erst nach dem Insel-Abschluss.
select test_helpers.login('a9a00000-0000-0000-0000-000000000001');
select test_helpers.expect_error(
  $$select public.crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a', 'explain')$$,
  'Noch nicht dran', 'Erklären erst, wenn die Insel geschafft ist');
select test_helpers.logout();
insert into public.island_completions (child_id, island_id)
values ('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a');

select test_helpers.login('a9a00000-0000-0000-0000-000000000001');
create temp table crew_c as
select public.crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a', 'explain') as code;
select test_helpers.expect_true((select code ~ '^[0-9]{4}$' from crew_c), 'Code hat 4 Ziffern');
select test_helpers.logout();
select test_helpers.expect_equal((select count(*) from public.crew_codes where code_hash ~ '^[0-9]{4}$'), 0,
  'Gespeichert wird nur die Prüfsumme');

-- Kind gibt einen falschen, dann den richtigen Code ein.
select test_helpers.login('d9a00000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select r ->> 'status' = 'wrong' and (r ->> 'tries_left')::int = 4
   from (select public.redeem_crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a',
     'explain', (select case when code = '0000' then '0001' else '0000' end from crew_c)) r) x),
  'Falscher Code: noch 4 Versuche');
select test_helpers.expect_equal(test_helpers.crew_xp(), 0, 'Falscher Code bringt nichts');
select test_helpers.expect_true(
  (select r ->> 'status' = 'ok' and (r ->> 'xp_awarded')::int = 30 and (r ->> 'stars')::int = 1
   from (select public.redeem_crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a',
     'explain', (select code from crew_c)) r) x),
  'Richtiger Code: 30 Seemeilen und ein Crew-Stern');
select test_helpers.expect_true(
  (select public.redeem_crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a',
     'explain', (select code from crew_c)) ->> 'status' = 'done'),
  'Zweimal geht nicht');
select test_helpers.expect_equal(
  (select count(*) from public.crew_done where child_id = 'c9a00000-0000-0000-0000-000000000001'), 1,
  'Kinder-Gerät sieht seinen Crew-Stern');
select test_helpers.logout();
select test_helpers.expect_equal(test_helpers.crew_xp(), 30, 'Seemeilen genau einmal');

select test_helpers.login('a9a00000-0000-0000-0000-000000000001');
select test_helpers.expect_error(
  $$select public.crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a', 'explain')$$,
  'Schon geschafft', 'Für Geschafftes gibt es keinen neuen Code');
-- Crew-Abenteuer: nach 5 falschen Versuchen gesperrt, ein neuer Code hilft.
create temp table crew_a as
select public.crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a', 'adventure') as code;
select test_helpers.logout();
select test_helpers.login('d9a00000-0000-0000-0000-000000000001', 'aal1', true);
select public.redeem_crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a',
  'adventure', (select case when code = '9999' then '9998' else '9999' end from crew_a))
from generate_series(1, 5);
select test_helpers.expect_true(
  (select public.redeem_crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a',
     'adventure', (select code from crew_a)) ->> 'status' = 'locked'),
  'Nach 5 falschen Versuchen hilft auch der richtige Code nicht');
select test_helpers.logout();
select test_helpers.login('a9a00000-0000-0000-0000-000000000001');
create temp table crew_a2 as
select public.crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a', 'adventure') as code;
select test_helpers.logout();
update public.crew_codes set expires_at = now() - interval '1 minute' where kind = 'adventure';
select test_helpers.login('d9a00000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select public.redeem_crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a',
     'adventure', (select code from crew_a2)) ->> 'status' = 'expired'),
  'Nach 24 Stunden gilt der Code nicht mehr');
select test_helpers.logout();
update public.crew_codes set expires_at = now() + interval '1 hour' where kind = 'adventure';
select test_helpers.login('d9a00000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select r ->> 'status' = 'ok' and (r ->> 'xp_awarded')::int = 50 and (r ->> 'stars')::int = 2
   from (select public.redeem_crew_code('c9a00000-0000-0000-0000-000000000001', 'e9a00000-0000-0000-0000-00000000000a',
     'adventure', ' ' || (select code from crew_a2) || ' ') r) x),
  'Crew-Abenteuer: 50 Seemeilen, zweiter Stern (Leerzeichen egal)');
select test_helpers.logout();
