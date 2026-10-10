-- Tests für Seemeilen, Ränge, Orden, Tempo, Wiederholung und Fahrtwind (Schritt 6).
-- Ausführen mit: tool/db_test.sh
--
-- Nutzt die Inseln A, B, C (Stufe 2) und die Hilfe test_helpers.answers aus
-- 40_fortschritt_test.sql. Zeit wird simuliert, indem die Tests als Datenbank-
-- Besitzer gespeicherte Tage zurückdrehen.

-- ---------------------------------------------------------------------------
-- Testdaten
-- ---------------------------------------------------------------------------

insert into auth.users (id, email, raw_user_meta_data) values
  ('a7000000-0000-0000-0000-000000000001', 'fahrt1@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}'),
  ('a7000000-0000-0000-0000-000000000002', 'fahrt2@test.invalid',
   '{"taleria_role": "parent", "consent_version": "2026-10"}');
insert into auth.users (id, is_anonymous) values ('d7000000-0000-0000-0000-000000000001', true);

insert into public.children (id, parent_id, nickname, birth_year, stage)
select 'c7000000-0000-0000-0000-000000000001', p.id, 'Lou', 2015, 2
from public.parents p where p.user_id = 'a7000000-0000-0000-0000-000000000001';
insert into public.child_devices (user_id, child_id)
values ('d7000000-0000-0000-0000-000000000001', 'c7000000-0000-0000-0000-000000000001');

insert into public.badges (slug, kind, island_id, title, asset_key, status) values
  ('test-orden-a', 'island', 'e4000000-0000-0000-0000-00000000000a', 'Test-Orden A', 'badge.test-a', 'published'),
  ('test-orden-b', 'island', 'e4000000-0000-0000-0000-00000000000b', 'Test-Orden B', 'badge.test-b', 'draft');

insert into public.encounters (id, slug, type, title, asset_key, question_count, xp_reward, after_island_id, status)
values
  ('87000000-0000-0000-0000-000000000001', 'test-taleron', 'taleron', 'Meister Taleron', 'character.taleron',
   3, 20, null, 'published'),
  ('87000000-0000-0000-0000-000000000002', 'test-fischer', 'fischerboot', 'Fischerboot', 'character.taleron',
   3, 20, 'e4000000-0000-0000-0000-00000000000b', 'published');

create function test_helpers.lou_stats() returns jsonb language sql as $$
  select public.child_stats('c7000000-0000-0000-0000-000000000001');
$$;
grant execute on function test_helpers.lou_stats() to authenticated;

create function test_helpers.lou_review(p_question uuid)
returns public.question_reviews language sql as $$
  select * from public.question_reviews
  where child_id = 'c7000000-0000-0000-0000-000000000001' and question_id = p_question;
$$;
grant execute on function test_helpers.lou_review(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------

select test_helpers.login_anon();
select test_helpers.expect_error($$select public.child_stats('c7000000-0000-0000-0000-000000000001')$$,
  'permission denied', 'Ohne Anmeldung keine Statistik');
select test_helpers.logout();

select test_helpers.login('a7000000-0000-0000-0000-000000000002');
select test_helpers.expect_error($$select public.child_stats('c7000000-0000-0000-0000-000000000001')$$,
  'nicht gefunden', 'Fremde Eltern sehen keine Statistik');
select test_helpers.expect_error($$select public.set_pace('c7000000-0000-0000-0000-000000000001', null)$$,
  'Nur für Eltern', 'Fremde Eltern ändern kein Tempo');
select test_helpers.expect_error($$select public.next_encounter('c7000000-0000-0000-0000-000000000001')$$,
  'nicht gefunden', 'Fremde Eltern starten keine Begegnung');
select test_helpers.logout();

select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_error($$select public.child_rank('c7000000-0000-0000-0000-000000000001')$$,
  'permission denied', 'Interne Rang-Berechnung ist gesperrt');
select test_helpers.expect_error(
  $$select public.record_answer('c7000000-0000-0000-0000-000000000001', '94000000-0000-0000-0000-0000000000a1', true)$$,
  'permission denied', 'Wiederholungsplan nur über Server-Funktionen');
select test_helpers.expect_error($$select public.refresh_wind('c7000000-0000-0000-0000-000000000001')$$,
  'permission denied', 'Wind nur über Server-Funktionen');
select test_helpers.expect_error($$select public.mark_activity('c7000000-0000-0000-0000-000000000001')$$,
  'permission denied', 'Fahrtwind nur über Server-Funktionen');
select test_helpers.expect_error($$select public.set_pace('c7000000-0000-0000-0000-000000000001', null)$$,
  'Nur für Eltern', 'Kind kann sein Tempo nicht ändern');
select test_helpers.expect_error($$select public.set_streak_pause('c7000000-0000-0000-0000-000000000001', true)$$,
  'Nur für Eltern', 'Kind kann den Fahrtwind nicht pausieren');

select test_helpers.expect_true(
  (select s ->> 'rank' is null and (s ->> 'xp')::int = 0 and s ->> 'next_rank' = 'schiffsjunge'
   from test_helpers.lou_stats() s),
  'Vor dem Intro: keine Seemeilen, kein Rang');

-- ---------------------------------------------------------------------------
-- Rang nach dem Intro, Wind zum Start
-- ---------------------------------------------------------------------------

select public.complete_onboarding('c7000000-0000-0000-0000-000000000001');
select test_helpers.expect_true(
  (select s ->> 'rank' = 'schiffsjunge' and (s ->> 'xp')::int = 50 and s ->> 'next_rank' = 'matrose'
      and (s ->> 'next_rank_xp')::int = 1500 and (s ->> 'rank_min_xp')::int = 1
   from test_helpers.lou_stats() s),
  'Nach dem Intro: Schiffsjunge mit 50 Seemeilen, Matrose ab 1500');
select test_helpers.expect_true(
  (select s -> 'pace' ->> 'free' = 'false' and (s -> 'pace' ->> 'wind')::int = 2
      and (s -> 'pace' ->> 'stations_per_week')::int = 2 and s -> 'pace' ->> 'next_release' is null
   from test_helpers.lou_stats() s),
  'Start mit Wind für eine Woche (2 Stationen)');

-- ---------------------------------------------------------------------------
-- Tempo und Wiederholungsplan beim Abgeben
-- ---------------------------------------------------------------------------

select test_helpers.expect_true(
  (select r ->> 'passed' = 'true' and (r ->> 'wind_left')::int = 1
   from (select public.submit_station('c7000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
     test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0', '94000000-0000-0000-0000-0000000000a2:1')) r) x),
  'Neue Station verbraucht einen Wind');
select test_helpers.expect_equal(
  (select count(*) from public.question_reviews where child_id = 'c7000000-0000-0000-0000-000000000001'), 2,
  'Beide Antworten stehen im Wiederholungsplan');
select test_helpers.expect_true(
  (select bool_and(due_at = public.day_start(public.taleria_today() + 1) and interval_days = 1)
   from public.question_reviews where child_id = 'c7000000-0000-0000-0000-000000000001'),
  'Erste Wiederholung am nächsten Tag');
select test_helpers.expect_true(
  (select correct_streak = 1 and last_correct
   from test_helpers.lou_review('94000000-0000-0000-0000-0000000000a1')),
  'Richtig beantwortet: Serie 1');
select test_helpers.expect_true(
  (select correct_streak = 0 and not last_correct and times_wrong = 1
   from test_helpers.lou_review('94000000-0000-0000-0000-0000000000a2')),
  'Falsch beantwortet: Serie 0');
select test_helpers.expect_equal((test_helpers.lou_stats() ->> 'streak_weeks')::int, 1,
  'Fahrtwind: erste Woche an Bord');

select test_helpers.expect_true(
  (select (r ->> 'wind_left')::int = 1 and r ->> 'xp_awarded' = '0'
   from (select public.submit_station('c7000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
     test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0', '94000000-0000-0000-0000-0000000000a3:0')) r) x),
  'Station wiederholen kostet keinen Wind');
select test_helpers.expect_true(
  (select correct_streak = 1 and interval_days = 1 and times_answered = 2
   from test_helpers.lou_review('94000000-0000-0000-0000-0000000000a1')),
  'Richtig vor dem Termin: der Plan bleibt, wie er ist');

select test_helpers.expect_true(
  (select r ->> 'passed' = 'false' and (r ->> 'wind_left')::int = 1
   from (select public.submit_station('c7000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a3',
     test_helpers.answers('94000000-0000-0000-0000-0000000000e1:0', '94000000-0000-0000-0000-0000000000e2:0')) r) x),
  'Nicht bestandene Prüfung kostet keinen Wind');
select test_helpers.expect_true(
  (select r ->> 'passed' = 'true' and (r ->> 'wind_left')::int = 0 and r ->> 'island_completed' = 'true'
      and r -> 'badge' ->> 'title' = 'Test-Orden A' and r -> 'badge' ->> 'asset_key' = 'badge.test-a'
   from (select public.submit_station('c7000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a3',
     test_helpers.answers('94000000-0000-0000-0000-0000000000e1:1', '94000000-0000-0000-0000-0000000000e3:1')) r) x),
  'Prüfung bestanden: letzter Wind verbraucht, Orden der Insel');
select test_helpers.expect_equal(
  (select count(*) from public.child_badges cb join public.badges b on b.id = cb.badge_id), 1,
  'Kinder-Gerät sieht den verdienten Orden');
select test_helpers.expect_equal((test_helpers.lou_stats() ->> 'badge_count')::int, 1, 'Statistik zählt den Orden');

select test_helpers.expect_error(
  $$select public.submit_station('c7000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000b1',
      test_helpers.answers('94000000-0000-0000-0000-0000000000b1:0'))$$,
  'braucht Wind', 'Ohne Wind keine neue Station');
select test_helpers.expect_true(
  (select (s -> 'pace' ->> 'wind')::int = 0
      and (s -> 'pace' ->> 'next_release')::date > public.taleria_today()
      and extract(isodow from (s -> 'pace' ->> 'next_release')::date) in (1, 4)
   from test_helpers.lou_stats() s),
  'Ohne Wind: der nächste Freigabetag ist ein Montag oder Donnerstag');
select test_helpers.expect_true(
  (select r ->> 'passed' = 'true'
   from (select public.submit_station('c7000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
     test_helpers.answers('94000000-0000-0000-0000-0000000000a3:0', '94000000-0000-0000-0000-0000000000a4:0')) r) x),
  'Ohne Wind darf das Kind fertige Stationen wiederholen');

update public.pace_state set wind = 9 where child_id = 'c7000000-0000-0000-0000-000000000001';
select test_helpers.expect_equal((test_helpers.lou_stats() -> 'pace' ->> 'wind')::int, 0,
  'Kinder-Gerät kann sich keinen Wind geben');
select test_helpers.expect_error(
  $$insert into public.question_reviews (child_id, question_id, due_at, interval_days, last_answered_at, last_correct)
    values ('c7000000-0000-0000-0000-000000000001', '94000000-0000-0000-0000-0000000000f1', now(), 1, now(), true)$$,
  'row-level security', 'Kinder-Gerät schreibt nicht selbst in den Wiederholungsplan');
select test_helpers.expect_error(
  $$insert into public.child_badges (child_id, badge_id)
    select 'c7000000-0000-0000-0000-000000000001', id from public.badges where slug = 'test-orden-a'$$,
  'row-level security', 'Kinder-Gerät verleiht sich keine Orden');
select test_helpers.expect_equal((select count(*) from public.badges where slug = 'test-orden-b'), 0,
  'Orden im Entwurf ist unsichtbar');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Wind über die Zeit
-- ---------------------------------------------------------------------------

update public.pace_state set checked_on = checked_on - 7 where child_id = 'c7000000-0000-0000-0000-000000000001';
select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_equal((test_helpers.lou_stats() -> 'pace' ->> 'wind')::int, 2,
  'Nach einer Woche: Wind für 2 neue Stationen (Montag und Donnerstag)');
select test_helpers.logout();

update public.pace_state set checked_on = checked_on - 30, wind = 1
where child_id = 'c7000000-0000-0000-0000-000000000001';
select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_equal((test_helpers.lou_stats() -> 'pace' ->> 'wind')::int, 2,
  'Wind sammelt sich höchstens für eine Woche');
select test_helpers.logout();

update public.pace_state set checked_on = public.taleria_today() - 1, wind = 0
where child_id = 'c7000000-0000-0000-0000-000000000001';
select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_equal((test_helpers.lou_stats() -> 'pace' ->> 'wind')::int,
  case when extract(isodow from public.taleria_today()) in (1, 4) then 1 else 0 end,
  'Ein neuer Tag bringt nur an Freigabetagen Wind');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Tempo einstellen (Eltern)
-- ---------------------------------------------------------------------------

select test_helpers.login('a7000000-0000-0000-0000-000000000001');
select test_helpers.expect_error($$select public.set_pace('c7000000-0000-0000-0000-000000000001', 5::smallint)$$,
  '2, 3 oder 4', 'Tempo nur 2, 3 oder 4 Stationen oder freie Fahrt');
select test_helpers.expect_error(
  $$update public.children set stations_per_week = 7 where id = 'c7000000-0000-0000-0000-000000000001'$$,
  'permission denied', 'Tempo nur über set_pace, nicht direkt');
update public.children set nickname = 'Louis' where id = 'c7000000-0000-0000-0000-000000000001';
select test_helpers.expect_true(
  (select nickname = 'Louis' from public.children where id = 'c7000000-0000-0000-0000-000000000001'),
  'Spitznamen ändern Eltern weiter direkt');

select public.set_pace('c7000000-0000-0000-0000-000000000001', 3::smallint);
select test_helpers.expect_true(
  (select stations_per_week = 3 and release_weekdays = '{1,3,5}'
   from public.children where id = 'c7000000-0000-0000-0000-000000000001'),
  'Tempo 3: Montag, Mittwoch, Freitag');
select public.set_pace('c7000000-0000-0000-0000-000000000001', null);
select test_helpers.expect_true(
  (select s -> 'pace' ->> 'free' = 'true' and s -> 'pace' ->> 'wind' is null from test_helpers.lou_stats() s),
  'Freie Fahrt: kein Wind nötig');
select test_helpers.logout();

select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select r ->> 'passed' = 'true' and r ->> 'wind_left' is null
   from (select public.submit_station('c7000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000b1',
     test_helpers.answers('94000000-0000-0000-0000-0000000000b1:0')) r) x),
  'Freie Fahrt: neue Station ohne Wind');
select test_helpers.logout();

select test_helpers.login('a7000000-0000-0000-0000-000000000001');
select public.set_pace('c7000000-0000-0000-0000-000000000001', 2::smallint);
select test_helpers.expect_equal((test_helpers.lou_stats() -> 'pace' ->> 'wind')::int, 2,
  'Nach freier Fahrt startet der Wind mit einer vollen Woche');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Wiederholungsplan: „Weißt du noch?“
-- ---------------------------------------------------------------------------

update public.question_reviews set due_at = now() - interval '1 hour'
where child_id = 'c7000000-0000-0000-0000-000000000001';

select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_equal((test_helpers.lou_stats() ->> 'reviews_due')::int, 8,
  'Fällige Wiederholungen werden gezählt');
select test_helpers.expect_equal(
  public.record_answers('c7000000-0000-0000-0000-000000000001',
    test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0')), 1,
  'Weißt du noch: richtige Antwort wird gezählt');
select test_helpers.expect_true(
  (select correct_streak = 2 and interval_days = 7 and due_at = public.day_start(public.taleria_today() + 7)
   from test_helpers.lou_review('94000000-0000-0000-0000-0000000000a1')),
  'Richtig zum Termin: nächste Wiederholung in einer Woche');
select test_helpers.expect_equal(
  public.record_answers('c7000000-0000-0000-0000-000000000001',
    test_helpers.answers('94000000-0000-0000-0000-0000000000a3:2')), 0,
  'Weißt du noch: falsche Antwort ohne Strafe');
select test_helpers.expect_true(
  (select correct_streak = 0 and interval_days = 1 and due_at = public.day_start(public.taleria_today() + 1)
   from test_helpers.lou_review('94000000-0000-0000-0000-0000000000a3')),
  'Falsch: morgen kommt die Frage wieder');
select test_helpers.expect_error(
  $$select public.record_answers('c7000000-0000-0000-0000-000000000001',
      test_helpers.answers('94000000-0000-0000-0000-0000000000f1:0'))$$,
  'kennt das Kind noch nicht', 'Nur Fragen, die das Kind schon kennt');
select test_helpers.expect_error(
  $$select public.record_answers('c7000000-0000-0000-0000-000000000001', '[]'::jsonb)$$,
  '1 bis 5', 'Mindestens eine Antwort');
select test_helpers.logout();

update public.question_reviews set due_at = now() - interval '1 minute'
where child_id = 'c7000000-0000-0000-0000-000000000001' and question_id = '94000000-0000-0000-0000-0000000000a1';
select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select public.record_answers('c7000000-0000-0000-0000-000000000001',
  test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0'));
select test_helpers.expect_equal(
  (select interval_days from test_helpers.lou_review('94000000-0000-0000-0000-0000000000a1')), 30,
  'Danach in einem Monat');
select test_helpers.logout();

update public.question_reviews set due_at = now() - interval '1 minute'
where child_id = 'c7000000-0000-0000-0000-000000000001' and question_id = '94000000-0000-0000-0000-0000000000a1';
select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select public.record_answers('c7000000-0000-0000-0000-000000000001',
  test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0'));
select test_helpers.expect_equal(
  (select interval_days from test_helpers.lou_review('94000000-0000-0000-0000-0000000000a1')), 90,
  'Sicher gewusst: alle 3 Monate');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Begegnung mit Meister Taleron
-- ---------------------------------------------------------------------------

-- Seemeilen knapp unter Matrose: 400 aus Stationen + 1090 = 1490.
insert into public.xp_events (child_id, source_type, source_id, amount)
values ('c7000000-0000-0000-0000-000000000001', 'test', gen_random_uuid(), 1090);

select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select e -> 'encounter' ->> 'slug' = 'test-taleron' and jsonb_array_length(e -> 'question_ids') = 3
      and e ->> 'first_meeting' = 'true' and (e ->> 'due_count')::int = 6
   from (select public.next_encounter('c7000000-0000-0000-0000-000000000001') e) x),
  'Begegnung mit Meister Taleron: 3 Fragen, erste Begegnung');
select test_helpers.expect_true(
  (select bool_and(public.next_encounter('c7000000-0000-0000-0000-000000000001') -> 'encounter' ->> 'slug' = 'test-taleron')
   from generate_series(1, 10)),
  'Das Fischerboot taucht erst nach Insel B auf');
select test_helpers.expect_true(
  (with offer as materialized (
     select public.next_encounter('c7000000-0000-0000-0000-000000000001') as e
   )
   select count(*) = 3 and bool_and(r.due_at <= now())
   from offer, jsonb_array_elements_text(offer.e -> 'question_ids') q(id)
   join public.question_reviews r
     on r.question_id = q.id::uuid and r.child_id = 'c7000000-0000-0000-0000-000000000001'),
  'Fällige Fragen kommen zuerst');

select test_helpers.expect_error(
  $$select public.submit_encounter('c7000000-0000-0000-0000-000000000001', '87000000-0000-0000-0000-000000000001',
      test_helpers.answers('94000000-0000-0000-0000-0000000000a2:0'))$$,
  'Falsche Anzahl', 'Begegnung braucht alle Antworten');
select test_helpers.expect_error(
  $$select public.submit_encounter('c7000000-0000-0000-0000-000000000001', '87000000-0000-0000-0000-000000000009',
      test_helpers.answers('94000000-0000-0000-0000-0000000000a2:0'))$$,
  'nicht gefunden', 'Unbekannte Begegnung');
select test_helpers.expect_error(
  $$select public.submit_encounter('c7000000-0000-0000-0000-000000000001', '87000000-0000-0000-0000-000000000001',
      test_helpers.answers('94000000-0000-0000-0000-0000000000f1:0', '94000000-0000-0000-0000-0000000000f2:0',
                           '94000000-0000-0000-0000-0000000000f3:0'))$$,
  'kennt das Kind noch nicht', 'Begegnung nur mit bekannten Fragen');

select test_helpers.expect_true(
  (select r ->> 'correct' = '2' and r ->> 'total' = '3' and r ->> 'xp_awarded' = '20'
      and r ->> 'rank_up' = 'matrose' and (r ->> 'streak_weeks')::int = 1
   from (select public.submit_encounter('c7000000-0000-0000-0000-000000000001', '87000000-0000-0000-0000-000000000001',
     test_helpers.answers('94000000-0000-0000-0000-0000000000a2:0', '94000000-0000-0000-0000-0000000000a4:0',
                          '94000000-0000-0000-0000-0000000000e1:0')) r) x),
  'Begegnung: 2 von 3 richtig, 20 Seemeilen, neuer Rang Matrose');
select test_helpers.expect_true(
  (select r ->> 'xp_awarded' = '0' and r ->> 'rank_up' is null
   from (select public.submit_encounter('c7000000-0000-0000-0000-000000000001', '87000000-0000-0000-0000-000000000001',
     test_helpers.answers('94000000-0000-0000-0000-0000000000e2:1', '94000000-0000-0000-0000-0000000000e3:1',
                          '94000000-0000-0000-0000-0000000000b1:0')) r) x),
  'Seemeilen für Begegnungen nur einmal am Tag');
select test_helpers.expect_equal((select count(*) from public.encounter_runs), 2, 'Begegnungen werden gespeichert');
select test_helpers.expect_true(public.next_encounter('c7000000-0000-0000-0000-000000000001') is null,
  'Ohne fällige Wiederholungen keine Begegnung');
select test_helpers.logout();

update public.question_reviews set due_at = now() - interval '1 minute'
where child_id = 'c7000000-0000-0000-0000-000000000001';
select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  public.next_encounter('c7000000-0000-0000-0000-000000000001') ->> 'first_meeting' = 'false',
  'Danach ist es keine erste Begegnung mehr');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Fahrtwind
-- ---------------------------------------------------------------------------

update public.child_streaks set weeks = 3, last_week = public.week_start(public.taleria_today()) - 7
where child_id = 'c7000000-0000-0000-0000-000000000001';
select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select public.submit_station('c7000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
  test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0', '94000000-0000-0000-0000-0000000000a2:0'));
select test_helpers.expect_equal((test_helpers.lou_stats() ->> 'streak_weeks')::int, 4,
  'Fahrtwind: die Woche in Folge zählt dazu');
select test_helpers.logout();

update public.child_streaks set last_week = public.week_start(public.taleria_today()) - 21
where child_id = 'c7000000-0000-0000-0000-000000000001';
select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_equal((test_helpers.lou_stats() ->> 'streak_weeks')::int, 0,
  'Fahrtwind reißt nach einer ganzen Woche ohne Fahrt');
select public.submit_station('c7000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
  test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0', '94000000-0000-0000-0000-0000000000a2:0'));
select test_helpers.expect_equal((test_helpers.lou_stats() ->> 'streak_weeks')::int, 1,
  'Eine neue Fahrt startet den Fahrtwind neu');
select test_helpers.logout();

update public.child_streaks set weeks = 5, last_week = public.week_start(public.taleria_today())
where child_id = 'c7000000-0000-0000-0000-000000000001';
select test_helpers.login('a7000000-0000-0000-0000-000000000001');
select public.set_streak_pause('c7000000-0000-0000-0000-000000000001', true);
select test_helpers.logout();
update public.child_streaks set last_week = last_week - 28
where child_id = 'c7000000-0000-0000-0000-000000000001';

select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select (s ->> 'streak_weeks')::int = 5 and s ->> 'streak_paused' = 'true' from test_helpers.lou_stats() s),
  'Pause: Ferienwochen brechen den Fahrtwind nicht');
select public.submit_station('c7000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-0000000000a2',
  test_helpers.answers('94000000-0000-0000-0000-0000000000a1:0', '94000000-0000-0000-0000-0000000000a2:0'));
select test_helpers.expect_equal((test_helpers.lou_stats() ->> 'streak_weeks')::int, 6,
  'In der Pause zählt die nächste Fahrt weiter');
select test_helpers.logout();

select test_helpers.login('a7000000-0000-0000-0000-000000000001');
select public.set_streak_pause('c7000000-0000-0000-0000-000000000001', false);
select test_helpers.expect_true(
  (select (s ->> 'streak_weeks')::int = 6 and s ->> 'streak_paused' = 'false' from test_helpers.lou_stats() s),
  'Nach der Pause bleibt der Fahrtwind');
select test_helpers.logout();

update public.child_streaks set weeks = 5, last_week = public.week_start(public.taleria_today()) - 28, paused = false
where child_id = 'c7000000-0000-0000-0000-000000000001';
select test_helpers.login('a7000000-0000-0000-0000-000000000001');
select public.set_streak_pause('c7000000-0000-0000-0000-000000000001', true);
select test_helpers.expect_equal((test_helpers.lou_stats() ->> 'streak_weeks')::int, 0,
  'Eine Pause belebt keinen abgerissenen Fahrtwind');
select public.set_streak_pause('c7000000-0000-0000-0000-000000000001', false);
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Ränge bis Kapitän
-- ---------------------------------------------------------------------------

-- 1510 Seemeilen bisher, + 6490 = 8000.
insert into public.xp_events (child_id, source_type, source_id, amount)
values ('c7000000-0000-0000-0000-000000000001', 'test', gen_random_uuid(), 6490);
select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select s ->> 'rank' = 'steuermann' and s ->> 'next_rank' = 'kapitaen' and s ->> 'next_rank_xp' is null
      and s ->> 'next_rank_needs_certificate' = 'true'
   from test_helpers.lou_stats() s),
  'Steuermann ab 8000 Seemeilen; Kapitän nur mit der Goldenen Schatzkarte');
select test_helpers.logout();

-- Letzte Insel der Hauptroute (Insel C) abgeschlossen.
insert into public.island_completions (child_id, island_id)
values ('c7000000-0000-0000-0000-000000000001', 'e4000000-0000-0000-0000-00000000000c');
select test_helpers.login('d7000000-0000-0000-0000-000000000001', 'aal1', true);
select test_helpers.expect_true(
  (select s ->> 'rank' = 'kapitaen' and s ->> 'next_rank' is null from test_helpers.lou_stats() s),
  'Mit der Goldenen Schatzkarte wird das Kind Kapitän');
select test_helpers.logout();

-- ---------------------------------------------------------------------------
-- Fremde Eltern
-- ---------------------------------------------------------------------------

select test_helpers.login('a7000000-0000-0000-0000-000000000002');
select test_helpers.expect_equal((select count(*) from public.child_badges), 0, 'Fremde Eltern sehen keine Orden');
select test_helpers.expect_equal((select count(*) from public.question_reviews), 0,
  'Fremde Eltern sehen keinen Wiederholungsplan');
select test_helpers.expect_equal((select count(*) from public.encounter_runs), 0,
  'Fremde Eltern sehen keine Begegnungen');
select test_helpers.logout();
