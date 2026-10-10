-- Tests für die Admin-Grundversion (Schritt 10).
-- Ausführen mit: tool/db_test.sh

insert into auth.users (id, email) values
  ('ad000000-0000-0000-0000-00000000000a', 'chefin@test.invalid'),
  ('ad000000-0000-0000-0000-00000000000b', 'redaktion@test.invalid'),
  ('ad000000-0000-0000-0000-00000000000c', 'support@test.invalid');
insert into auth.users (id, email, raw_user_meta_data) values
  ('ad000000-0000-0000-0000-000000000001', 'Familie.Admin@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('ad000000-0000-0000-0000-0000000000d1', true);

-- ---------------------------------------------------------------------------
-- Admin-Konten anlegen (nur im SQL Editor)
-- ---------------------------------------------------------------------------

select public.grant_admin_role('chefin@test.invalid', 'owner');
select public.grant_admin_role('REDAKTION@test.invalid', 'editor');
select public.grant_admin_role('support@test.invalid', 'owner');
select public.grant_admin_role('support@test.invalid', 'support');
select test_helpers.expect_equal(
  (select count(*) from public.admins a join auth.users u on u.id = a.user_id
   where u.email like '%@test.invalid' and u.id::text like 'ad%'), 3,
  'grant_admin_role legt Admins an, ein zweiter Aufruf ändert nur die Rolle');
select test_helpers.expect_true(
  (select role = 'support' from public.admins where user_id = 'ad000000-0000-0000-0000-00000000000c'),
  'grant_admin_role ändert die Rolle');
select test_helpers.expect_error($$select public.grant_admin_role('niemand@test.invalid', 'owner')$$,
  'Kein Konto mit dieser E-Mail', 'grant_admin_role: unbekannte E-Mail');
select test_helpers.expect_error($$select public.grant_admin_role('chefin@test.invalid', 'boss')$$,
  'Rolle muss', 'grant_admin_role: unbekannte Rolle');
select test_helpers.expect_error($$select public.grant_admin_role('familie.admin@test.invalid', 'support')$$,
  'Eltern-Konto', 'Ein Eltern-Konto wird kein Admin');
select test_helpers.expect_error(
  $$insert into public.parents (user_id, consent_at, consent_version)
    values ('ad000000-0000-0000-0000-00000000000a', now(), '2026-10')$$,
  'Admin-Konten können kein Eltern-Konto', 'Ein Admin-Konto bekommt kein Eltern-Konto');

-- ---------------------------------------------------------------------------
-- Testdaten: Familie mit zwei Kindern, Insel in Stufe 2
-- ---------------------------------------------------------------------------

insert into public.children (id, parent_id, nickname, birth_year, stage, onboarding_completed_at)
select v.id, p.id, v.nickname, 2016, 2, now()
from public.parents p,
  (values ('cd000000-0000-0000-0000-000000000001'::uuid, 'Ada'),
          ('cd000000-0000-0000-0000-000000000002'::uuid, 'Bo')) v (id, nickname)
where p.user_id = 'ad000000-0000-0000-0000-000000000001';
insert into public.child_devices (user_id, child_id)
values ('ad000000-0000-0000-0000-0000000000d1', 'cd000000-0000-0000-0000-000000000001');

insert into public.islands (id, slug, stage, sort_order, title, status, content) values
  ('ed000000-0000-0000-0000-00000000000a', 'statistikinsel', 2, 50, 'Statistikinsel', 'draft', '{"access": "premium"}');
insert into public.stations (id, island_id, sort_order, type, content, status) values
  ('fd000000-0000-0000-0000-000000000010', 'ed000000-0000-0000-0000-00000000000a', 10, 'quiz',
   '{"number": 1, "title": "Erste Station"}', 'published'),
  ('fd000000-0000-0000-0000-000000000020', 'ed000000-0000-0000-0000-00000000000a', 20, 'quiz',
   '{"number": 2, "title": "Zweite Station"}', 'published');
insert into public.quiz_questions (id, station_id, question, answers, correct_index, status) values
  ('9d000000-0000-0000-0000-000000000011', 'fd000000-0000-0000-0000-000000000010', 'Schwere Frage',
   '["r", "f", "f"]', 0, 'published'),
  ('9d000000-0000-0000-0000-000000000012', 'fd000000-0000-0000-0000-000000000010', 'Leichte Frage',
   '["r", "f", "f"]', 0, 'published'),
  ('9d000000-0000-0000-0000-000000000013', 'fd000000-0000-0000-0000-000000000020', 'Selten gestellt',
   '["r", "f", "f"]', 0, 'published');

insert into public.station_progress (child_id, station_id, status, best_score, last_score, attempts, completed_at) values
  ('cd000000-0000-0000-0000-000000000001', 'fd000000-0000-0000-0000-000000000010', 'done', 2, 2, 1, now()),
  ('cd000000-0000-0000-0000-000000000002', 'fd000000-0000-0000-0000-000000000010', 'done', 1, 1, 2, now()),
  ('cd000000-0000-0000-0000-000000000001', 'fd000000-0000-0000-0000-000000000020', 'done', 1, 1, 1, now());

insert into public.question_reviews
  (child_id, question_id, due_at, interval_days, times_answered, times_wrong, last_answered_at, last_correct) values
  ('cd000000-0000-0000-0000-000000000001', '9d000000-0000-0000-0000-000000000011', now(), 1, 3, 3, now(), false),
  ('cd000000-0000-0000-0000-000000000002', '9d000000-0000-0000-0000-000000000011', now(), 1, 3, 2, now(), true),
  ('cd000000-0000-0000-0000-000000000001', '9d000000-0000-0000-0000-000000000012', now(), 1, 4, 0, now(), true),
  ('cd000000-0000-0000-0000-000000000002', '9d000000-0000-0000-0000-000000000012', now(), 1, 2, 0, now(), true),
  ('cd000000-0000-0000-0000-000000000001', '9d000000-0000-0000-0000-000000000013', now(), 1, 2, 2, now(), false);

-- ---------------------------------------------------------------------------
-- Nur Admins mit Zwei-Faktor
-- ---------------------------------------------------------------------------

select test_helpers.login('ad000000-0000-0000-0000-000000000001');
select test_helpers.expect_true(public.admin_whoami() is null, 'Eltern sind keine Admins');
select test_helpers.expect_error($$select public.admin_overview()$$, 'Nur für Admins', 'Eltern sehen keine Statistik');
select test_helpers.expect_error($$select public.grant_admin_role('familie.admin@test.invalid', 'owner')$$,
  'permission denied', 'Eltern machen sich nicht selbst zum Admin');
select test_helpers.logout();

select test_helpers.login('ad000000-0000-0000-0000-00000000000a', 'aal1');
select test_helpers.expect_true(
  (select w ->> 'role' = 'owner' and w ->> 'mfa' = 'false' and w ->> 'email' = 'chefin@test.invalid'
   from public.admin_whoami() w),
  'whoami: Admin ohne Zwei-Faktor kennt seine Rolle');
select test_helpers.expect_error($$select public.admin_overview()$$, 'Zwei-Faktor',
  'Ohne Zwei-Faktor keine Statistik');
select test_helpers.expect_error(
  $$select public.admin_find_family('familie.admin@test.invalid', 'Anfrage per E-Mail')$$,
  'Zwei-Faktor', 'Ohne Zwei-Faktor kein Support');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Statistik
-- ---------------------------------------------------------------------------

select set_config('test.family',
  (select id from public.parents where user_id = 'ad000000-0000-0000-0000-000000000001')::text, false);
-- Erwartete Zahlen vorher ohne Row Level Security zählen.
select set_config('test.families', (select count(*) from public.parents)::text, false);
select set_config('test.children', (select count(*) from public.children)::text, false);

select test_helpers.login('ad000000-0000-0000-0000-00000000000a', 'aal2');
select test_helpers.expect_true(public.admin_whoami() ->> 'mfa' = 'true', 'whoami: mit Zwei-Faktor');
select test_helpers.expect_true(
  (select (o ->> 'families')::bigint = current_setting('test.families')::bigint
      and (o ->> 'children')::bigint = current_setting('test.children')::bigint
      and (o ->> 'children_active_7d')::bigint >= 2
      and (o ->> 'children_active_28d')::bigint >= (o ->> 'children_active_7d')::bigint
      and o ? 'premium_revenuecat' and o ? 'tasks_approved_28d'
   from public.admin_overview() o),
  'Übersicht: Familien, Kinder und aktive Kinder');

select test_helpers.expect_true(
  (select i ->> 'status' = 'draft' and i ->> 'access' = 'premium' and (i ->> 'questions')::int = 3
      and (i ->> 'reached')::int = 2 and (i ->> 'completed')::int = 0
   from jsonb_array_elements(public.admin_content_stats(2::smallint) -> 'islands') i
   where i ->> 'slug' = 'statistikinsel'),
  'Inhalte: Status, Zugang, Fragen und erreichte Kinder pro Insel');
select test_helpers.expect_true(
  (select string_agg(s ->> 'done', ',' order by (s ->> 'number')::int) = '2,1'
   from jsonb_array_elements(public.admin_content_stats(2::smallint) -> 'islands') i,
        jsonb_array_elements(i -> 'stations') s
   where i ->> 'slug' = 'statistikinsel'),
  'Inhalte: geschafft pro Station');
select test_helpers.expect_true(
  (select public.admin_content_stats(2::smallint) -> 'hardest_questions' -> 0 ->> 'question' = 'Schwere Frage'),
  'Schwierigste Frage zuerst');
select test_helpers.expect_true(
  (select (e ->> 'wrong_rate')::numeric = 0 and (e ->> 'answered')::int = 6
   from jsonb_array_elements(public.admin_content_stats(2::smallint) -> 'easiest_questions') e
   where e ->> 'question' = 'Leichte Frage'),
  'Leichte Fragen mit Fehlerquote');
select test_helpers.expect_true(
  (select not exists (
     select 1 from jsonb_array_elements(public.admin_content_stats(2::smallint) -> 'hardest_questions') h
     where h ->> 'question' = 'Selten gestellt')),
  'Fragen mit weniger als 5 Antworten zählen nicht');
select test_helpers.expect_true(
  (select s::text not like '%Ada%' from public.admin_content_stats(2::smallint) s),
  'Statistik ohne Spitznamen');
select test_helpers.logout();

select test_helpers.login('ad000000-0000-0000-0000-00000000000b', 'aal2');
select test_helpers.expect_true(
  jsonb_typeof(public.admin_content_stats(2::smallint) -> 'islands') = 'array',
  'Redaktion sieht die Inhalts-Statistik');
select test_helpers.expect_error($$select public.admin_overview()$$, 'Nur für Admins',
  'Redaktion sieht keine Zahlen zu Familien und Abos');
select test_helpers.expect_error(
  $$select public.admin_find_family('familie.admin@test.invalid', 'Anfrage per E-Mail')$$,
  'Nur für Admins', 'Redaktion sucht keine Familien');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Support mit Grund und Audit-Log
-- ---------------------------------------------------------------------------

select test_helpers.login('ad000000-0000-0000-0000-00000000000c', 'aal2');
select test_helpers.expect_error($$select public.admin_overview()$$, 'Nur für Admins',
  'Support sieht keine Übersicht');
select test_helpers.expect_error($$select public.admin_content_stats(2::smallint)$$, 'Nur für Admins',
  'Support sieht keine Inhalts-Statistik');
select test_helpers.expect_error(
  $$select public.admin_find_family('familie.admin@test.invalid', '  ')$$,
  'Grund', 'Ohne Grund keine Suche');
select test_helpers.expect_true(
  (select f ->> 'email' = 'Familie.Admin@test.invalid' and (f ->> 'children')::int = 2
      and f ->> 'premium' = 'false' and f ? 'last_active_at' and not f ? 'nickname'
   from public.admin_find_family(' familie.admin@TEST.invalid ', 'Anfrage per E-Mail vom 10.10.') f),
  'Support findet die Familie per E-Mail, egal ob groß oder klein geschrieben');
select test_helpers.expect_true(
  public.admin_find_family('gibtsnicht@test.invalid', 'Anfrage per E-Mail') is null,
  'Suche ohne Treffer');
select test_helpers.expect_error(
  $$select public.admin_set_premium(
      current_setting('test.family')::uuid,
      true, null, 'Beta-Familie')$$,
  'Nur für Admins', 'Support vergibt kein Abo');
select test_helpers.expect_error(
  $$select public.admin_delete_family(
      current_setting('test.family')::uuid, 'Löschwunsch')$$,
  'Nur für Admins', 'Support löscht keine Konten');
select test_helpers.expect_error($$select * from public.admin_audit_recent()$$, 'Nur für Admins',
  'Support liest das Audit-Log nicht');
select test_helpers.logout();

select test_helpers.expect_equal(
  (select count(*) from public.admin_audit_log l join public.admins a on a.id = l.admin_id
   where a.user_id = 'ad000000-0000-0000-0000-00000000000c' and l.action = 'family.view'
     and l.target_id = current_setting('test.family')::uuid
     and l.reason = 'Anfrage per E-Mail vom 10.10.'), 1,
  'Audit-Log: Ansehen einer Familie mit Grund');
select test_helpers.expect_equal(
  (select count(*) from public.admin_audit_log l join public.admins a on a.id = l.admin_id
   where a.user_id = 'ad000000-0000-0000-0000-00000000000c' and l.action = 'family.search'
     and l.target_id is null), 1,
  'Audit-Log: Suche ohne Treffer, ohne gesuchte E-Mail');

-- Abo von Hand (owner)
select test_helpers.login('ad000000-0000-0000-0000-00000000000a', 'aal2');
select test_helpers.expect_error(
  $$select public.admin_set_premium(
      current_setting('test.family')::uuid,
      true, now() - interval '1 day', 'Beta-Familie')$$,
  'Vergangenheit', 'Abo nicht in der Vergangenheit');
select test_helpers.expect_true(
  public.admin_set_premium(
    current_setting('test.family')::uuid,
    true, now() + interval '90 days', 'Beta-Familie') ->> 'premium' = 'true',
  'Owner vergibt ein Abo von Hand');
select test_helpers.expect_true(
  (select (o ->> 'premium_manual')::int >= 1 from public.admin_overview() o),
  'Übersicht zählt Abos von Hand');
select test_helpers.expect_true(
  public.admin_set_premium(
    current_setting('test.family')::uuid,
    true, null, 'Beta verlängert') ->> 'premium' = 'true',
  'Abo von Hand ohne Ablauf');
select test_helpers.logout();
select test_helpers.expect_equal(
  (select count(*) from public.entitlements e join public.parents p on p.id = e.parent_id
   where p.user_id = 'ad000000-0000-0000-0000-000000000001' and e.source = 'manual' and e.valid_until is null), 1,
  'Ein Abo von Hand pro Familie, das zweite ersetzt das erste');

select test_helpers.login('ad000000-0000-0000-0000-000000000001');
select test_helpers.expect_true(
  (select s ->> 'premium' = 'true' and s ->> 'source' = 'manual' from public.my_subscription() s),
  'Eltern sehen das Abo von Hand');
select test_helpers.logout();

select test_helpers.login('ad000000-0000-0000-0000-00000000000a', 'aal2');
select test_helpers.expect_true(
  public.admin_set_premium(
    current_setting('test.family')::uuid,
    false, null, 'Beta beendet') ->> 'premium' = 'false',
  'Owner entfernt das Abo von Hand');
select test_helpers.expect_true(
  (select string_agg(r.action, ',' order by r.created_at, r.action) like '%premium.grant%premium.revoke%'
   from public.admin_audit_recent(20) r where r.admin_email = 'chefin@test.invalid'),
  'Audit-Log: Abo vergeben und entfernt');
select test_helpers.expect_true(
  (select count(*) >= 3 and bool_and(r.reason is not null) from public.admin_audit_recent(5) r),
  'Owner liest das Audit-Log');

-- Konto löschen (owner)
select test_helpers.expect_error(
  $$select public.admin_delete_family('00000000-0000-0000-0000-000000000000', 'Löschwunsch per E-Mail')$$,
  'nicht gefunden', 'Löschen: unbekanntes Konto');
select public.admin_delete_family(
  current_setting('test.family')::uuid, 'Löschwunsch per E-Mail');
select test_helpers.logout();

select test_helpers.expect_equal(
  (select count(*) from auth.users
   where id in ('ad000000-0000-0000-0000-000000000001', 'ad000000-0000-0000-0000-0000000000d1')), 0,
  'Löschen entfernt Eltern-Zugang und Kinder-Geräte');
select test_helpers.expect_equal(
  (select count(*) from public.children
   where id in ('cd000000-0000-0000-0000-000000000001', 'cd000000-0000-0000-0000-000000000002')), 0,
  'Löschen entfernt alle Kinder-Profile und ihren Fortschritt');
select test_helpers.expect_equal(
  (select count(*) from public.admin_audit_log where action = 'family.delete' and reason = 'Löschwunsch per E-Mail'), 1,
  'Audit-Log: Löschung bleibt mit Grund erhalten');

-- ---------------------------------------------------------------------------
-- Frühere Fassungen nur bei echter Änderung
-- ---------------------------------------------------------------------------

update public.islands set status = 'published' where id = 'ed000000-0000-0000-0000-00000000000a';
select test_helpers.expect_equal(
  (select count(*) from public.content_versions where entity_id = 'ed000000-0000-0000-0000-00000000000a'), 0,
  'Veröffentlichen eines Entwurfs legt keine frühere Fassung an');
update public.islands set title = 'Statistikinsel' where id = 'ed000000-0000-0000-0000-00000000000a';
select test_helpers.expect_equal(
  (select count(*) from public.content_versions where entity_id = 'ed000000-0000-0000-0000-00000000000a'), 0,
  'Unveränderter Import legt keine frühere Fassung an');
update public.islands set title = 'Zahleninsel' where id = 'ed000000-0000-0000-0000-00000000000a';
select test_helpers.expect_equal(
  (select count(*) from public.content_versions where entity_id = 'ed000000-0000-0000-0000-00000000000a'), 1,
  'Echte Änderung sichert die frühere Fassung');

-- Erneuter Import einer veröffentlichten Insel („insert … on conflict“) geht,
-- neue Pflichtstationen bleiben verboten.
insert into public.stations (id, island_id, sort_order, type, is_required, content, status)
values ('fd000000-0000-0000-0000-000000000010', 'ed000000-0000-0000-0000-00000000000a', 10, 'quiz', true,
  '{"number": 1, "title": "Erste Station"}', 'published')
on conflict (id) do update set content = excluded.content;
select test_helpers.expect_equal(
  (select count(*) from public.content_versions where entity_id = 'fd000000-0000-0000-0000-000000000010'), 0,
  'Erneuter Import einer veröffentlichten Station ohne Änderung');
select test_helpers.expect_error(
  $$insert into public.stations (id, island_id, sort_order, type, is_required, status)
    values ('fd000000-0000-0000-0000-000000000030', 'ed000000-0000-0000-0000-00000000000a', 30, 'quiz', true, 'draft')
    on conflict (id) do nothing$$,
  'müssen Bonus sein', 'Neue Pflichtstation an veröffentlichter Insel bleibt verboten');
