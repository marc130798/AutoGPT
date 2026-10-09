-- Taleria, Schritt 6a: zentrales Fortschrittssystem
--
-- Enthält:
--   * ranks                    Ränge nach Seemeilen (Schiffsjunge bis Kapitän)
--   * badges, child_badges     Orden; der Orden einer Insel kommt mit ihrem Abschluss
--   * pace_state               Wind: wie viele neue Stationen das Kind gerade beginnen darf
--   * question_reviews         Wiederholungsplan pro Frage und Kind
--   * encounters, encounter_runs   Begegnungen auf See (Kontrollfahrten)
--   * child_streaks            Fahrtwind: Wochen in Folge an Bord, mit Pause
--   * child_stats()            Seemeilen, Rang, Fahrtwind, Wind und Wiederholungen in einem Aufruf
--   * submit_station()         jetzt mit Tempo, Wiederholungsplan, Fahrtwind, Rang und Orden
--   * record_answers()         Antworten aus „Weißt du noch?“ für den Wiederholungsplan
--   * next_encounter(), submit_encounter()   Begegnung auf See
--   * set_pace(), set_streak_pause()         Einstellungen der Eltern
--
-- Regeln aus CLAUDE.md, Abschnitt 8:
--   * Tempo: Standard 2 neue Stationen pro Woche (Montag und Donnerstag). Jeder
--     Freigabetag bringt Wind für eine neue Pflichtstation. Nicht genutzter Wind
--     sammelt sich bis zur Menge einer Woche. Wiederholen geht immer.
--   * Wiederholung: Zeitplan je Frage etwa 1 Tag, 1 Woche, 1 Monat (danach 3 Monate).
--     Falsche Antworten kommen am nächsten Tag wieder. Wer eine Frage vor ihrem
--     Termin richtig beantwortet, verschiebt den Plan nicht.
--   * Kontrollfahrten sind freiwillig und nie Voraussetzung für neue Stationen.
--     Seemeilen dafür gibt es einmal am Tag.
--   * Seemeilen, Orden und Ränge werden verdient, nie gekauft. Nur der Server bucht.
--
-- Alle Tage zählen in deutscher Zeit (Europe/Berlin).

-- ---------------------------------------------------------------------------
-- Kinder-Profil: Eltern ändern nur Spitzname, Geburtsjahr und Niveau direkt.
-- Tempo, Intro-Abschluss, Avatar und Schiffsname laufen über Server-Funktionen.
-- ---------------------------------------------------------------------------

revoke update on public.children from authenticated, anon;
grant update (nickname, birth_year, level_setting) on public.children to authenticated;

-- ---------------------------------------------------------------------------
-- Hilfen für Tage und Wochen
-- ---------------------------------------------------------------------------

create or replace function public.taleria_today()
returns date
language sql
stable
set search_path = ''
as $$
  select (now() at time zone 'Europe/Berlin')::date;
$$;

-- Montag der Woche eines Tages.
create or replace function public.week_start(p_day date)
returns date
language sql
immutable
set search_path = ''
as $$
  select p_day - (extract(isodow from p_day)::integer - 1);
$$;

-- Beginn eines Tages in deutscher Zeit.
create or replace function public.day_start(p_day date)
returns timestamptz
language sql
stable
set search_path = ''
as $$
  select p_day::timestamp at time zone 'Europe/Berlin';
$$;

-- ---------------------------------------------------------------------------
-- Ränge
-- ---------------------------------------------------------------------------

create table public.ranks (
  code text primary key check (code ~ '^[a-z]{3,20}$'),
  sort_order smallint not null unique,
  -- Ab so vielen Seemeilen gilt der Rang.
  min_xp integer not null check (min_xp >= 0),
  -- Kapitän wird man nur mit der Goldenen Schatzkarte (Schatzinsel abgeschlossen).
  requires_certificate boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger ranks_set_updated_at before update on public.ranks
  for each row execute function public.set_updated_at();

alter table public.ranks enable row level security;

create policy "Alle Angemeldeten sehen die Ränge"
  on public.ranks for select to authenticated
  using (true);

create policy "Owner ändern Ränge"
  on public.ranks for all to authenticated
  using (public.is_admin(array['owner']))
  with check (public.is_admin(array['owner']));

-- Vorschlag, mit Marc abzustimmen (CLAUDE.md Abschnitt 16, Schritt 6a).
-- Schiffsjunge nach Station 1 (Intro), Matrose etwa nach Insel 2,
-- Bootsmann etwa nach Insel 4, Steuermann etwa nach Insel 8.
insert into public.ranks (code, sort_order, min_xp, requires_certificate) values
  ('schiffsjunge', 1, 1, false),
  ('matrose', 2, 1500, false),
  ('bootsmann', 3, 4000, false),
  ('steuermann', 4, 8000, false),
  ('kapitaen', 5, 0, true);

-- ---------------------------------------------------------------------------
-- Orden
-- ---------------------------------------------------------------------------

create table public.badges (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9_-]{2,60}$'),
  -- island: Orden einer Insel, taleron: Siegel von Meister Taleron, special: alles andere
  kind text not null check (kind in ('island', 'taleron', 'special')),
  island_id uuid unique references public.islands (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 2 and 60),
  asset_key text not null check (asset_key ~ '^[a-z0-9_.-]{3,80}$'),
  sort_order integer not null default 0,
  status public.content_status not null default 'draft',
  publish_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint badges_island_kind check (kind <> 'island' or island_id is not null)
);

create trigger badges_set_updated_at before update on public.badges
  for each row execute function public.set_updated_at();

create table public.child_badges (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  badge_id uuid not null references public.badges (id) on delete cascade,
  earned_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint child_badges_once unique (child_id, badge_id)
);

create index child_badges_child_idx on public.child_badges (child_id);

alter table public.badges enable row level security;
alter table public.child_badges enable row level security;

create policy "Sichtbare Orden lesen"
  on public.badges for select to authenticated
  using (public.is_content_visible(status, publish_at) or public.is_admin());

create policy "Editoren schreiben Orden"
  on public.badges for all to authenticated
  using (public.is_admin(array['owner', 'editor']))
  with check (public.is_admin(array['owner', 'editor']));

-- Verliehen werden Orden nur vom Server.
create policy "Eltern und Kinder-Gerät sehen verdiente Orden"
  on public.child_badges for select to authenticated
  using (public.can_act_for_child(child_id));

-- Mit dem Abschluss einer Insel gibt es ihren Orden (genau einmal).
create or replace function public.award_island_badge()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.child_badges (child_id, badge_id)
  select new.child_id, b.id from public.badges b where b.island_id = new.island_id
  on conflict on constraint child_badges_once do nothing;
  return new;
end;
$$;

create trigger island_completions_award_badge
  after insert on public.island_completions
  for each row execute function public.award_island_badge();

-- ---------------------------------------------------------------------------
-- Seemeilen und Rang
-- ---------------------------------------------------------------------------

create or replace function public.child_xp(p_child_id uuid)
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum(e.amount), 0) from public.xp_events e where e.child_id = p_child_id;
$$;

-- Goldene Schatzkarte: die letzte Insel der Hauptroute ist abgeschlossen.
create or replace function public.has_certificate(p_child_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.children c
    join lateral (
      select i.id from public.islands i
      where i.stage = c.stage and i.route_type = 'main'
      order by i.sort_order desc
      limit 1
    ) last_island on true
    join public.island_completions ic on ic.child_id = c.id and ic.island_id = last_island.id
    where c.id = p_child_id
  );
$$;

-- Aktueller Rang (null, solange es noch keine Seemeilen gibt).
create or replace function public.child_rank(p_child_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select r.code
  from public.ranks r
  where r.min_xp <= public.child_xp(p_child_id)
    and public.child_xp(p_child_id) > 0
    and (not r.requires_certificate or public.has_certificate(p_child_id))
  order by r.sort_order desc
  limit 1;
$$;

-- ---------------------------------------------------------------------------
-- Tempo (Wind)
-- ---------------------------------------------------------------------------

create table public.pace_state (
  child_id uuid primary key references public.children (id) on delete cascade,
  -- So viele neue Pflichtstationen darf das Kind gerade beginnen.
  wind smallint not null check (wind >= 0),
  -- Bis zu diesem Tag sind die Freigabetage verrechnet.
  checked_on date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger pace_state_set_updated_at before update on public.pace_state
  for each row execute function public.set_updated_at();

alter table public.pace_state enable row level security;

create policy "Eltern und Kinder-Gerät sehen den Wind"
  on public.pace_state for select to authenticated
  using (public.can_act_for_child(child_id));

-- Verrechnet die Freigabetage seit dem letzten Mal und gibt den Wind zurück.
-- null = freie Fahrt. Beim ersten Mal startet das Kind mit dem Wind einer Woche.
create or replace function public.refresh_wind(p_child_id uuid)
returns smallint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_per_week smallint;
  v_days smallint[];
  v_today date := public.taleria_today();
  v_state record;
  v_wind integer;
begin
  select c.stations_per_week, c.release_weekdays
    into v_per_week, v_days
  from public.children c where c.id = p_child_id;
  if not found or v_per_week is null then
    return null;
  end if;

  insert into public.pace_state (child_id, wind, checked_on)
  values (p_child_id, v_per_week, v_today)
  on conflict (child_id) do nothing;

  select s.wind, s.checked_on into v_state
  from public.pace_state s where s.child_id = p_child_id
  for update;

  if v_state.checked_on >= v_today then
    return least(v_state.wind, v_per_week);
  end if;

  if v_today - v_state.checked_on > 14 then
    v_wind := v_per_week;
  else
    select v_state.wind + count(*)
      into v_wind
    from generate_series((v_state.checked_on + 1)::timestamp, v_today::timestamp, interval '1 day') d
    where extract(isodow from d)::smallint = any (v_days);
  end if;
  v_wind := least(v_wind, v_per_week);

  update public.pace_state set wind = v_wind, checked_on = v_today where child_id = p_child_id;
  return v_wind;
end;
$$;

-- Nächster Freigabetag nach heute (null bei freier Fahrt).
create or replace function public.next_release_day(p_child_id uuid)
returns date
language sql
stable
security definer
set search_path = ''
as $$
  select min(d)::date
  from public.children c,
       generate_series(
         (public.taleria_today() + 1)::timestamp,
         (public.taleria_today() + 7)::timestamp,
         interval '1 day'
       ) d
  where c.id = p_child_id
    and c.stations_per_week is not null
    and extract(isodow from d)::smallint = any (c.release_weekdays);
$$;

-- Eltern stellen das Tempo ein: 2, 3 oder 4 Stationen pro Woche, null = freie Fahrt.
create or replace function public.set_pace(p_child_id uuid, p_stations_per_week smallint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old smallint;
begin
  if not public.is_parent_of_child(p_child_id) then
    raise exception 'Nur für Eltern' using errcode = '42501';
  end if;
  if p_stations_per_week is not null and p_stations_per_week not in (2, 3, 4) then
    raise exception 'Tempo muss 2, 3 oder 4 Stationen pro Woche sein' using errcode = '22023';
  end if;

  select c.stations_per_week into v_old from public.children c where c.id = p_child_id for update;

  update public.children
  set stations_per_week = p_stations_per_week,
      release_weekdays = case p_stations_per_week
        when 3 then '{1,3,5}'::smallint[]
        when 4 then '{1,2,4,5}'::smallint[]
        else '{1,4}'::smallint[]
      end
  where id = p_child_id;

  if p_stations_per_week is null or v_old is null then
    -- Nach freier Fahrt startet der Wind wieder mit einer vollen Woche.
    delete from public.pace_state where child_id = p_child_id;
  else
    update public.pace_state set wind = least(wind, p_stations_per_week) where child_id = p_child_id;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Fahrtwind (Wochen in Folge an Bord)
-- ---------------------------------------------------------------------------

create table public.child_streaks (
  child_id uuid primary key references public.children (id) on delete cascade,
  weeks integer not null default 0 check (weeks >= 0),
  -- Montag der letzten Woche mit einer Station oder Kontrollfahrt.
  last_week date,
  -- Pause (zum Beispiel in den Ferien): Wochen ohne Fahrt brechen den Fahrtwind nicht.
  paused boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger child_streaks_set_updated_at before update on public.child_streaks
  for each row execute function public.set_updated_at();

alter table public.child_streaks enable row level security;

create policy "Eltern und Kinder-Gerät sehen den Fahrtwind"
  on public.child_streaks for select to authenticated
  using (public.can_act_for_child(child_id));

-- Merkt sich, dass das Kind in dieser Woche an Bord war.
create or replace function public.mark_activity(p_child_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_week date := public.week_start(public.taleria_today());
begin
  insert into public.child_streaks as s (child_id, weeks, last_week)
  values (p_child_id, 1, v_week)
  on conflict (child_id) do update
  set weeks = case
        when s.last_week >= v_week then s.weeks
        when s.last_week = v_week - 7 or s.paused then s.weeks + 1
        else 1
      end,
      last_week = greatest(s.last_week, v_week);
end;
$$;

-- Fahrtwind, wie er gerade gilt: 0, wenn eine ganze Woche ohne Fahrt vergangen ist.
create or replace function public.current_streak(p_child_id uuid)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select case
      when s.paused or s.last_week >= public.week_start(public.taleria_today()) - 7 then s.weeks
      else 0
    end
    from public.child_streaks s where s.child_id = p_child_id
  ), 0);
$$;

-- Eltern pausieren den Fahrtwind oder setzen ihn fort.
create or replace function public.set_streak_pause(p_child_id uuid, p_paused boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_week date := public.week_start(public.taleria_today());
begin
  if not public.is_parent_of_child(p_child_id) then
    raise exception 'Nur für Eltern' using errcode = '42501';
  end if;

  insert into public.child_streaks (child_id, weeks, last_week, paused)
  values (p_child_id, 0, null, p_paused)
  on conflict (child_id) do nothing;

  if p_paused then
    -- Ein schon abgerissener Fahrtwind wird durch die Pause nicht wiederbelebt.
    update public.child_streaks
    set weeks = public.current_streak(p_child_id), paused = true
    where child_id = p_child_id;
  else
    -- Nach der Pause hat das Kind die laufende Woche Zeit, weiterzufahren.
    update public.child_streaks
    set paused = false,
        last_week = case when weeks > 0 then greatest(last_week, v_week - 7) else last_week end
    where child_id = p_child_id;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Wiederholungsplan
-- ---------------------------------------------------------------------------

create table public.question_reviews (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  question_id uuid not null references public.quiz_questions (id) on delete cascade,
  due_at timestamptz not null,
  interval_days smallint not null check (interval_days between 1 and 365),
  -- Wie oft in Folge zum Termin richtig beantwortet.
  correct_streak smallint not null default 0 check (correct_streak >= 0),
  times_answered integer not null default 0 check (times_answered >= 0),
  times_wrong integer not null default 0 check (times_wrong >= 0),
  last_answered_at timestamptz not null,
  last_correct boolean not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint question_reviews_once unique (child_id, question_id)
);

create index question_reviews_due_idx on public.question_reviews (child_id, due_at);

create trigger question_reviews_set_updated_at before update on public.question_reviews
  for each row execute function public.set_updated_at();

alter table public.question_reviews enable row level security;

-- Eltern sehen daraus später den Lernstand (Schritt 8). Schreiben nur der Server.
create policy "Eltern und Kinder-Gerät sehen den Wiederholungsplan"
  on public.question_reviews for select to authenticated
  using (public.can_act_for_child(child_id));

-- Abstand bis zur nächsten Wiederholung: 1 Tag, 1 Woche, 1 Monat, danach 3 Monate.
create or replace function public.review_interval(p_streak integer)
returns smallint
language sql
immutable
set search_path = ''
as $$
  select case
    when p_streak <= 1 then 1
    when p_streak = 2 then 7
    when p_streak = 3 then 30
    else 90
  end::smallint;
$$;

-- Ist die Frage für Kinder sichtbar (Frage, Station und Insel)?
create or replace function public.question_visible(p_question_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.quiz_questions q
    join public.stations s on s.id = q.station_id
    join public.islands i on i.id = s.island_id
    where q.id = p_question_id
      and public.is_content_visible(q.status, null)
      and public.is_content_visible(s.status, s.publish_at)
      and public.is_content_visible(i.status, i.publish_at)
  );
$$;

-- Trägt eine Antwort in den Wiederholungsplan ein.
create or replace function public.record_answer(p_child_id uuid, p_question_id uuid, p_correct boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_today date := public.taleria_today();
begin
  insert into public.question_reviews as r
    (child_id, question_id, due_at, interval_days, correct_streak, times_answered, times_wrong,
     last_answered_at, last_correct)
  values (
    p_child_id, p_question_id, public.day_start(v_today + 1), 1,
    case when p_correct then 1 else 0 end, 1, case when p_correct then 0 else 1 end,
    now(), p_correct
  )
  on conflict on constraint question_reviews_once do update
  set correct_streak = case
        when not p_correct then 0
        when r.due_at <= now() then r.correct_streak + 1
        else r.correct_streak
      end,
      interval_days = case
        when not p_correct then 1
        when r.due_at <= now() then public.review_interval(r.correct_streak + 1)
        else r.interval_days
      end,
      due_at = case
        when not p_correct then public.day_start(v_today + 1)
        when r.due_at <= now() then public.day_start(v_today + public.review_interval(r.correct_streak + 1))
        else r.due_at
      end,
      times_answered = r.times_answered + 1,
      times_wrong = r.times_wrong + case when p_correct then 0 else 1 end,
      last_answered_at = now(),
      last_correct = p_correct;
end;
$$;

-- Liest [{"question_id": "...", "answer_index": 0}, ...] und prüft jede Antwort.
-- Nur Fragen, die das Kind schon kennt: aus erledigten Stationen oder schon im Plan.
create or replace function public.checked_review_answers(p_child_id uuid, p_answers jsonb)
returns table (question_id uuid, correct boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if jsonb_typeof(p_answers) <> 'array' then
    raise exception 'Antworten fehlen' using errcode = '22023';
  end if;
  if (select count(*) <> count(distinct a ->> 'question_id') from jsonb_array_elements(p_answers) a) then
    raise exception 'Jede Frage nur einmal' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_answers) a
    left join public.quiz_questions q on q.id = (a ->> 'question_id')::uuid
    where q.id is null
       or not public.question_visible(q.id)
       or not (
         public.station_done(p_child_id, q.station_id)
         or exists (
           select 1 from public.question_reviews r
           where r.child_id = p_child_id and r.question_id = q.id
         )
       )
  ) then
    raise exception 'Diese Frage kennt das Kind noch nicht' using errcode = '22023';
  end if;

  return query
  select q.id, (a ->> 'answer_index')::integer = q.correct_index
  from jsonb_array_elements(p_answers) a
  join public.quiz_questions q on q.id = (a ->> 'question_id')::uuid;
end;
$$;

-- „Weißt du noch?“ zu Beginn einer Station: fließt nur in den Wiederholungsplan,
-- ohne Seemeilen und ohne Wertung. Antwort: Anzahl richtiger Antworten.
create or replace function public.record_answers(p_child_id uuid, p_answers jsonb)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row record;
  v_correct integer := 0;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;
  if jsonb_typeof(p_answers) <> 'array' or jsonb_array_length(p_answers) not between 1 and 5 then
    raise exception 'Bitte 1 bis 5 Antworten' using errcode = '22023';
  end if;

  for v_row in select * from public.checked_review_answers(p_child_id, p_answers) loop
    perform public.record_answer(p_child_id, v_row.question_id, v_row.correct);
    if v_row.correct then
      v_correct := v_correct + 1;
    end if;
  end loop;
  return v_correct;
end;
$$;

-- ---------------------------------------------------------------------------
-- Begegnungen auf See
-- ---------------------------------------------------------------------------

create table public.encounters (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9_-]{2,60}$'),
  type text not null check (type in ('taleron', 'haendlerschiff', 'fischerboot', 'angeberschiff', 'tala_vergisst')),
  title text not null check (char_length(trim(title)) between 2 and 60),
  asset_key text not null check (asset_key ~ '^[a-z0-9_.-]{3,80}$'),
  question_count smallint not null default 3 check (question_count between 3 and 5),
  xp_reward integer not null default 20 check (xp_reward between 0 and 200),
  -- Erst nach dieser Insel unterwegs (zum Beispiel das Fischerboot ab der Taschengeld-Bucht).
  after_island_id uuid references public.islands (id) on delete set null,
  -- Szenen: first_scene (erste Begegnung), scene, success, wrong
  content jsonb not null default '{}'::jsonb check (jsonb_typeof(content) = 'object'),
  status public.content_status not null default 'draft',
  publish_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger encounters_set_updated_at before update on public.encounters
  for each row execute function public.set_updated_at();

create table public.encounter_runs (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  encounter_id uuid not null references public.encounters (id) on delete cascade,
  correct_count smallint not null check (correct_count >= 0),
  total smallint not null check (total > 0),
  finished_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index encounter_runs_child_idx on public.encounter_runs (child_id, encounter_id);

alter table public.encounters enable row level security;
alter table public.encounter_runs enable row level security;

create policy "Sichtbare Begegnungen lesen"
  on public.encounters for select to authenticated
  using (public.is_content_visible(status, publish_at) or public.is_admin());

create policy "Editoren schreiben Begegnungen"
  on public.encounters for all to authenticated
  using (public.is_admin(array['owner', 'editor']))
  with check (public.is_admin(array['owner', 'editor']));

create policy "Eltern und Kinder-Gerät sehen Begegnungen des Kindes"
  on public.encounter_runs for select to authenticated
  using (public.can_act_for_child(child_id));

-- Fällige Wiederholungen des Kindes (nur sichtbare Fragen).
create or replace function public.due_review_count(p_child_id uuid)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::integer
  from public.question_reviews r
  where r.child_id = p_child_id
    and r.due_at <= now()
    and public.question_visible(r.question_id);
$$;

-- Nächste Begegnung, wenn Wiederholungen fällig sind, sonst null.
-- Fällige Fragen kommen zuerst (die ältesten vorn), fehlende Plätze werden mit
-- den Fragen aufgefüllt, deren Termin als Nächstes kommt.
-- Antwort: {"encounter": {...}, "question_ids": [...], "first_meeting": true, "due_count": 7}
create or replace function public.next_encounter(p_child_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_due integer;
  v_encounter record;
  v_questions uuid[];
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  v_due := public.due_review_count(p_child_id);
  if v_due = 0 then
    return null;
  end if;

  select e.id, e.slug, e.type, e.title, e.asset_key, e.question_count, e.xp_reward, e.content
    into v_encounter
  from public.encounters e
  where public.is_content_visible(e.status, e.publish_at)
    and (
      e.after_island_id is null
      or exists (
        select 1 from public.island_completions c
        where c.child_id = p_child_id and c.island_id = e.after_island_id
      )
    )
  order by random()
  limit 1;
  if not found then
    return null;
  end if;

  select array_agg(x.question_id order by x.rank_due, x.due_at)
    into v_questions
  from (
    select r.question_id, r.due_at, case when r.due_at <= now() then 0 else 1 end as rank_due
    from public.question_reviews r
    where r.child_id = p_child_id and public.question_visible(r.question_id)
    order by case when r.due_at <= now() then 0 else 1 end, r.due_at, random()
    limit v_encounter.question_count
  ) x;

  if coalesce(cardinality(v_questions), 0) < v_encounter.question_count then
    return null;
  end if;

  return jsonb_build_object(
    'encounter', jsonb_build_object(
      'id', v_encounter.id,
      'slug', v_encounter.slug,
      'type', v_encounter.type,
      'title', v_encounter.title,
      'asset_key', v_encounter.asset_key,
      'question_count', v_encounter.question_count,
      'xp_reward', v_encounter.xp_reward,
      'content', v_encounter.content
    ),
    'question_ids', to_jsonb(v_questions),
    'first_meeting', not exists (
      select 1 from public.encounter_runs er
      where er.child_id = p_child_id and er.encounter_id = v_encounter.id
    ),
    'due_count', v_due
  );
end;
$$;

-- Begegnung abgeben. p_answers enthält die ERSTE Antwort je Frage (das Kind darf
-- danach so lange weiterprobieren, bis es stimmt; das zählt nicht).
-- Seemeilen gibt es einmal pro Tag für Kontrollfahrten und Begegnungen zusammen.
-- Antwort: {"correct": 2, "total": 3, "xp_awarded": 20, "rank_up": null, "streak_weeks": 3}
create or replace function public.submit_encounter(p_child_id uuid, p_encounter_id uuid, p_answers jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_encounter record;
  v_rank_before text;
  v_rank_after text;
  v_row record;
  v_correct integer := 0;
  v_total integer := 0;
  v_xp integer := 0;
  v_rows integer;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  select e.id, e.question_count, e.xp_reward into v_encounter
  from public.encounters e
  where e.id = p_encounter_id and public.is_content_visible(e.status, e.publish_at);
  if not found then
    raise exception 'Begegnung nicht gefunden' using errcode = 'P0002';
  end if;

  if jsonb_typeof(p_answers) <> 'array' or jsonb_array_length(p_answers) <> v_encounter.question_count then
    raise exception 'Falsche Anzahl an Antworten: % erwartet', v_encounter.question_count using errcode = '22023';
  end if;

  v_rank_before := public.child_rank(p_child_id);

  for v_row in select * from public.checked_review_answers(p_child_id, p_answers) loop
    perform public.record_answer(p_child_id, v_row.question_id, v_row.correct);
    v_total := v_total + 1;
    if v_row.correct then
      v_correct := v_correct + 1;
    end if;
  end loop;

  insert into public.encounter_runs (child_id, encounter_id, correct_count, total)
  values (p_child_id, p_encounter_id, v_correct, v_total);

  if v_encounter.xp_reward > 0 then
    insert into public.xp_events (child_id, source_type, source_id, amount)
    values (
      p_child_id, 'review',
      md5(p_child_id::text || '/review/' || public.taleria_today()::text)::uuid,
      v_encounter.xp_reward
    )
    on conflict on constraint xp_events_once do nothing;
    get diagnostics v_rows = row_count;
    if v_rows > 0 then
      v_xp := v_encounter.xp_reward;
    end if;
  end if;

  perform public.mark_activity(p_child_id);
  v_rank_after := public.child_rank(p_child_id);

  return jsonb_build_object(
    'correct', v_correct,
    'total', v_total,
    'xp_awarded', v_xp,
    'rank_up', case when v_rank_after is distinct from v_rank_before then v_rank_after end,
    'streak_weeks', public.current_streak(p_child_id)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Alles für die Startseite in einem Aufruf
-- ---------------------------------------------------------------------------

-- Antwort:
-- {"xp": 850, "rank": "schiffsjunge", "rank_min_xp": 1, "next_rank": "matrose",
--  "next_rank_xp": 1500, "next_rank_needs_certificate": false,
--  "streak_weeks": 2, "streak_paused": false, "badge_count": 1, "reviews_due": 4,
--  "pace": {"free": false, "stations_per_week": 2, "wind": 1, "next_release": "2026-10-12"}}
create or replace function public.child_stats(p_child_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_xp bigint;
  v_rank record;
  v_next record;
  v_per_week smallint;
  v_wind smallint;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  v_xp := public.child_xp(p_child_id);
  select r.code, r.sort_order, r.min_xp into v_rank
  from public.ranks r where r.code = public.child_rank(p_child_id);
  select r.code, r.min_xp, r.requires_certificate into v_next
  from public.ranks r
  where r.sort_order > coalesce(v_rank.sort_order, 0)
  order by r.sort_order
  limit 1;

  select c.stations_per_week into v_per_week from public.children c where c.id = p_child_id;
  v_wind := public.refresh_wind(p_child_id);

  return jsonb_build_object(
    'xp', v_xp,
    'rank', v_rank.code,
    'rank_min_xp', v_rank.min_xp,
    'next_rank', v_next.code,
    'next_rank_xp', case when v_next.requires_certificate then null else v_next.min_xp end,
    'next_rank_needs_certificate', coalesce(v_next.requires_certificate, false),
    'streak_weeks', public.current_streak(p_child_id),
    'streak_paused', coalesce((select s.paused from public.child_streaks s where s.child_id = p_child_id), false),
    'badge_count', (select count(*) from public.child_badges b where b.child_id = p_child_id),
    'reviews_due', public.due_review_count(p_child_id),
    'pace', jsonb_build_object(
      'free', v_per_week is null,
      'stations_per_week', v_per_week,
      'wind', v_wind,
      'next_release', case when v_wind = 0 then public.next_release_day(p_child_id) end
    )
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Station abgeben (ersetzt die Fassung aus Schritt 4b)
-- ---------------------------------------------------------------------------

-- Wie in Schritt 4b, dazu:
--   * Tempo: Eine neue Pflichtstation braucht Wind. Erledigt das Kind sie zum
--     ersten Mal, wird ein Wind verbraucht. Wiederholen kostet nichts.
--   * Jede Antwort fließt in den Wiederholungsplan.
--   * Fahrtwind: Die Woche zählt.
--   * Antwort zusätzlich: rank_up (neuer Rang oder null), badge (Orden der Insel
--     oder null), wind_left (null bei freier Fahrt).
create or replace function public.submit_station(
  p_child_id uuid,
  p_station_id uuid,
  p_answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_station record;
  v_island record;
  v_expected integer;
  v_review integer := 0;
  v_pass integer;
  v_total integer;
  v_distinct integer;
  v_correct integer;
  v_invalid integer;
  v_review_given integer;
  v_passed boolean;
  v_xp integer := 0;
  v_rows integer;
  v_island_completed boolean := false;
  v_first boolean;
  v_wind smallint;
  v_rank_before text;
  v_rank_after text;
  v_badge jsonb;
  v_answer record;
  v_checked jsonb;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  select s.id, s.island_id, s.type, s.xp_reward, s.content, s.status, s.publish_at, s.is_required
    into v_station
  from public.stations s where s.id = p_station_id;
  if not found then
    raise exception 'Station nicht gefunden' using errcode = 'P0002';
  end if;

  select i.id, i.stage, i.sort_order, i.status, i.publish_at
    into v_island
  from public.islands i where i.id = v_station.island_id;

  if not public.is_content_visible(v_station.status, v_station.publish_at)
     or not public.is_content_visible(v_island.status, v_island.publish_at) then
    raise exception 'Station nicht gefunden' using errcode = 'P0002';
  end if;
  if v_station.content ->> 'kind' = 'onboarding' then
    raise exception 'Das Intro wird über complete_onboarding() abgeschlossen' using errcode = '22023';
  end if;
  if not public.station_unlocked(p_child_id, p_station_id) then
    raise exception 'Station noch gesperrt' using errcode = 'P0001';
  end if;

  -- Tempo: neue Pflichtstationen brauchen Wind.
  v_first := not public.station_done(p_child_id, p_station_id);
  if v_first and v_station.is_required then
    v_wind := public.refresh_wind(p_child_id);
    if v_wind is not null and v_wind <= 0 then
      raise exception 'Das Schiff braucht Wind' using errcode = 'P0001';
    end if;
  end if;

  if jsonb_typeof(p_answers) <> 'array' then
    raise exception 'Antworten fehlen' using errcode = '22023';
  end if;

  -- Wie viele Antworten erwartet werden.
  if v_station.type = 'exam' then
    v_expected := coalesce((v_station.content -> 'exam' ->> 'show')::integer, 10);
    -- Rückblick nur, wenn es frühere Inseln mit Prüfungsfragen gibt.
    if exists (
      select 1 from public.islands i
      where i.stage = v_island.stage and i.route_type = 'main' and i.sort_order < v_island.sort_order
    ) then
      v_review := coalesce((v_station.content -> 'exam' ->> 'review')::integer, 0);
    end if;
    v_pass := coalesce((v_station.content -> 'exam' ->> 'pass')::integer, v_expected + v_review);
  else
    v_expected := coalesce((v_station.content -> 'quiz' ->> 'show')::integer, 0);
    v_pass := 0;
  end if;

  select count(*), count(distinct (a ->> 'question_id'))
    into v_total, v_distinct
  from jsonb_array_elements(p_answers) a;

  if v_total <> v_expected + v_review or v_distinct <> v_total then
    raise exception 'Falsche Anzahl an Antworten: % erwartet', v_expected + v_review using errcode = '22023';
  end if;

  -- Jede Frage muss zur Station gehören, Rückblick-Fragen zu Prüfungen früherer Inseln.
  with given as (
    select (a ->> 'question_id')::uuid as question_id, (a ->> 'answer_index')::integer as answer_index
    from jsonb_array_elements(p_answers) a
  ),
  checked as (
    select
      g.question_id,
      q.id is not null and g.answer_index = q.correct_index as correct,
      q.station_id = p_station_id as own,
      q.id is not null
        and public.is_content_visible(q.status, null)
        and (
          q.station_id = p_station_id
          or (
            v_station.type = 'exam'
            and exists (
              select 1
              from public.stations s
              join public.islands i on i.id = s.island_id
              where s.id = q.station_id
                and s.type = 'exam'
                and i.stage = v_island.stage
                and i.sort_order < v_island.sort_order
                and public.is_content_visible(s.status, s.publish_at)
            )
          )
        ) as allowed
    from given g
    left join public.quiz_questions q on q.id = g.question_id
  )
  select
    count(*) filter (where allowed and correct),
    count(*) filter (where not allowed),
    count(*) filter (where allowed and not own),
    coalesce(
      jsonb_agg(jsonb_build_object('question_id', question_id, 'correct', correct)) filter (where allowed),
      '[]'::jsonb
    )
  into v_correct, v_invalid, v_review_given, v_checked
  from checked;

  if v_invalid > 0 then
    raise exception 'Frage gehört nicht zu dieser Station' using errcode = '22023';
  end if;
  if v_review_given <> v_review then
    raise exception 'Falsche Anzahl an Rückblick-Fragen: % erwartet', v_review using errcode = '22023';
  end if;

  v_passed := v_correct >= v_pass;
  v_rank_before := public.child_rank(p_child_id);

  insert into public.station_progress as p
    (child_id, station_id, status, best_score, last_score, attempts, completed_at)
  values (
    p_child_id, p_station_id,
    case when v_passed then 'done' else 'open' end,
    v_correct, v_correct, 1,
    case when v_passed then now() end
  )
  on conflict on constraint station_progress_once do update
  set status = case when p.status = 'done' or v_passed then 'done' else 'open' end,
      best_score = greatest(p.best_score, excluded.best_score),
      last_score = excluded.last_score,
      attempts = p.attempts + 1,
      completed_at = coalesce(p.completed_at, excluded.completed_at);

  -- Wind verbrauchen, wenn die Pflichtstation zum ersten Mal erledigt ist.
  if v_first and v_passed and v_wind is not null then
    update public.pace_state set wind = greatest(wind - 1, 0) where child_id = p_child_id;
    v_wind := greatest(v_wind - 1, 0);
  end if;

  -- Wiederholungsplan und Fahrtwind.
  for v_answer in select * from jsonb_to_recordset(v_checked) as x(question_id uuid, correct boolean) loop
    perform public.record_answer(p_child_id, v_answer.question_id, v_answer.correct);
  end loop;
  perform public.mark_activity(p_child_id);

  if v_passed and v_station.xp_reward > 0 then
    insert into public.xp_events (child_id, source_type, source_id, amount)
    values (p_child_id, 'station', p_station_id, v_station.xp_reward)
    on conflict on constraint xp_events_once do nothing;
    get diagnostics v_rows = row_count;
    if v_rows > 0 then
      v_xp := v_station.xp_reward;
    end if;
  end if;

  -- Insel abschließen, wenn alle sichtbaren Pflichtstationen erledigt sind.
  -- Der Orden kommt über den Trigger island_completions_award_badge.
  if v_passed and not exists (
    select 1 from public.stations s
    where s.island_id = v_island.id
      and s.is_required
      and public.is_content_visible(s.status, s.publish_at)
      and not public.station_done(p_child_id, s.id)
  ) then
    insert into public.island_completions (child_id, island_id)
    values (p_child_id, v_island.id)
    on conflict on constraint island_completions_once do nothing;
    get diagnostics v_rows = row_count;
    v_island_completed := v_rows > 0;
  end if;

  if v_island_completed then
    select jsonb_build_object('id', b.id, 'slug', b.slug, 'title', b.title, 'asset_key', b.asset_key)
      into v_badge
    from public.badges b
    where b.island_id = v_island.id and public.is_content_visible(b.status, b.publish_at);
  end if;

  v_rank_after := public.child_rank(p_child_id);

  return jsonb_build_object(
    'correct', v_correct,
    'total', v_total,
    'passed', v_passed,
    'xp_awarded', v_xp,
    'island_completed', v_island_completed,
    'rank_up', case when v_rank_after is distinct from v_rank_before then v_rank_after end,
    'badge', v_badge,
    'wind_left', case when v_station.is_required then public.refresh_wind(p_child_id) end
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------

-- Interne Hilfen ohne eigene Rechteprüfung: nicht für die App.
revoke execute on function
  public.child_xp(uuid),
  public.has_certificate(uuid),
  public.child_rank(uuid),
  public.refresh_wind(uuid),
  public.next_release_day(uuid),
  public.mark_activity(uuid),
  public.current_streak(uuid),
  public.question_visible(uuid),
  public.record_answer(uuid, uuid, boolean),
  public.checked_review_answers(uuid, jsonb),
  public.due_review_count(uuid),
  public.award_island_badge()
from public, anon, authenticated;

revoke execute on function
  public.child_stats(uuid),
  public.record_answers(uuid, jsonb),
  public.next_encounter(uuid),
  public.submit_encounter(uuid, uuid, jsonb),
  public.set_pace(uuid, smallint),
  public.set_streak_pause(uuid, boolean)
from public, anon;

grant execute on function
  public.child_stats(uuid),
  public.record_answers(uuid, jsonb),
  public.next_encounter(uuid),
  public.submit_encounter(uuid, uuid, jsonb),
  public.set_pace(uuid, smallint),
  public.set_streak_pause(uuid, boolean)
to authenticated;
