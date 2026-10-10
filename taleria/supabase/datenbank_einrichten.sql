-- Taleria: Datenbank in einem NEUEN, LEEREN Supabase-Projekt einrichten.
-- Automatisch erzeugt aus supabase/migrations/ mit: dart run tool/build_setup_sql.dart
-- Nicht von Hand ändern. Nur einmal pro Projekt ausführen.
--
-- So geht es: Im Supabase-Dashboard den SQL Editor öffnen, den ganzen Inhalt
-- dieser Datei einfügen und auf „Run“ klicken. Läuft etwas schief, wird nichts
-- gespeichert (alles in einem Durchgang).

begin;

-- ===========================================================================
-- Migration 20261009000100_grundlagen_und_admin.sql
-- ===========================================================================

-- Taleria, Schritt 1: Grundlagen und Admin-Tabellen
--
-- Enthält:
--   * Hilfsfunktion für updated_at
--   * Inhalts-Status (draft, review, published)
--   * admins, admin_audit_log, content_versions (CLAUDE.md, Abschnitt 7 und 10)
--
-- Regeln:
--   * Jede Tabelle hat id uuid, created_at, updated_at.
--   * Row Level Security ist auf jeder Tabelle eingeschaltet.
--   * Admin-Rechte gelten nur mit Zwei-Faktor-Anmeldung (aal2).

-- ---------------------------------------------------------------------------
-- Hilfsfunktionen
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Status für alle Inhalte: Entwürfe landen nie bei Kindern.
create type public.content_status as enum ('draft', 'review', 'published');

-- Ein Inhalt ist sichtbar, wenn er veröffentlicht ist und sein geplanter
-- Veröffentlichungstermin (publish_at) erreicht ist.
create or replace function public.is_content_visible(
  p_status public.content_status,
  p_publish_at timestamptz
)
returns boolean
language sql
stable
as $$
  select p_status = 'published' and (p_publish_at is null or p_publish_at <= now());
$$;

-- ---------------------------------------------------------------------------
-- Admins
-- ---------------------------------------------------------------------------

create table public.admins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  role text not null check (role in ('owner', 'editor', 'support')),
  -- Zwei-Faktor-Anmeldung ist Pflicht und lässt sich nicht abschalten.
  mfa_required boolean not null default true check (mfa_required),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger admins_set_updated_at
  before update on public.admins
  for each row execute function public.set_updated_at();

-- Prüft, ob die aktuelle Anmeldung ein Admin mit einer der Rollen ist.
-- Nur mit Zwei-Faktor-Anmeldung (aal2) gilt jemand als Admin.
-- security definer, damit die Prüfung nicht an der RLS von admins hängen bleibt.
create or replace function public.is_admin(
  p_roles text[] default array['owner', 'editor', 'support']
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(auth.jwt() ->> 'aal', '') = 'aal2'
     and exists (
       select 1
       from public.admins a
       where a.user_id = auth.uid()
         and a.role = any (p_roles)
     );
$$;

-- id des Admins der aktuellen Anmeldung (oder null).
create or replace function public.current_admin_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select a.id from public.admins a where a.user_id = auth.uid();
$$;

alter table public.admins enable row level security;

create policy "Admins sehen ihren eigenen Eintrag, Owner sehen alle"
  on public.admins for select
  to authenticated
  using (public.is_admin(array['owner']) or (user_id = auth.uid() and public.is_admin()));

create policy "Nur Owner legen Admins an"
  on public.admins for insert
  to authenticated
  with check (public.is_admin(array['owner']));

create policy "Nur Owner ändern Admins"
  on public.admins for update
  to authenticated
  using (public.is_admin(array['owner']))
  with check (public.is_admin(array['owner']));

create policy "Nur Owner entfernen Admins"
  on public.admins for delete
  to authenticated
  using (public.is_admin(array['owner']));

-- ---------------------------------------------------------------------------
-- Audit-Log: jeder Zugriff auf ein Familienkonto und jede Löschung
-- ---------------------------------------------------------------------------

create table public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.admins (id) on delete restrict,
  action text not null check (length(trim(action)) > 0),
  target_type text not null check (length(trim(target_type)) > 0),
  target_id uuid,
  -- Jeder Zugriff braucht einen Grund.
  reason text not null check (length(trim(reason)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index admin_audit_log_admin_id_idx on public.admin_audit_log (admin_id);
create index admin_audit_log_target_idx on public.admin_audit_log (target_type, target_id);

-- Das Audit-Log ist nur zum Anhängen da: keine Änderungen, keine Löschungen,
-- auch nicht mit dem Server-Schlüssel.
create or replace function public.prevent_audit_log_change()
returns trigger
language plpgsql
as $$
begin
  raise exception 'admin_audit_log ist unveränderlich (% nicht erlaubt)', tg_op
    using errcode = 'P0001';
end;
$$;

create trigger admin_audit_log_no_update
  before update or delete on public.admin_audit_log
  for each row execute function public.prevent_audit_log_change();

alter table public.admin_audit_log enable row level security;

create policy "Admins schreiben Einträge nur unter eigenem Namen"
  on public.admin_audit_log for insert
  to authenticated
  with check (public.is_admin() and admin_id = public.current_admin_id());

create policy "Nur Owner lesen das Audit-Log"
  on public.admin_audit_log for select
  to authenticated
  using (public.is_admin(array['owner']));

-- ---------------------------------------------------------------------------
-- Frühere Fassungen von Inhalten
-- ---------------------------------------------------------------------------

create table public.content_versions (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  snapshot jsonb not null,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index content_versions_entity_idx
  on public.content_versions (entity_type, entity_id, created_at desc);

alter table public.content_versions enable row level security;

-- Geschrieben wird nur über den Trigger in der Inhalts-Migration.
create policy "Owner und Editor sehen frühere Fassungen"
  on public.content_versions for select
  to authenticated
  using (public.is_admin(array['owner', 'editor']));

-- ===========================================================================
-- Migration 20261009000200_inhalte.sql
-- ===========================================================================

-- Taleria, Schritt 1: Inhalts-Tabellen
--
-- Inseln, Stationen, Quizfragen, Expeditionen und Kombüsen-Fragen.
-- Die Inhalte selbst (Seed-Daten aus INSELN.md) kommen in Schritt 4.
--
-- Feste Regeln aus CLAUDE.md, Abschnitt 8 und 10, werden hier in der
-- Datenbank erzwungen, nicht nur in der Oberfläche:
--   * Neue Stationen an veröffentlichten Inseln sind immer Bonus (is_required = false).
--   * Pflichtstationen und Prüfungsfragen veröffentlichter Inseln dürfen
--     korrigiert, aber nicht entfernt werden.
--   * Jede Änderung an veröffentlichten Inhalten wird in content_versions gesichert.
--
-- is_published ist eine abgeleitete Spalte aus status, damit es nur eine
-- Wahrheit gibt. Ob ein Inhalt bei Kindern ankommt, entscheidet
-- is_content_visible(status, publish_at).

-- ---------------------------------------------------------------------------
-- Expeditionen (zeitlich begrenzte Event-Inseln)
-- ---------------------------------------------------------------------------

create table public.expeditions (
  id uuid primary key default gen_random_uuid(),
  title_key text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status public.content_status not null default 'draft',
  is_published boolean generated always as (status = 'published') stored,
  publish_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint expeditions_dates_check check (ends_at > starts_at)
);

-- ---------------------------------------------------------------------------
-- Inseln
-- ---------------------------------------------------------------------------

create table public.islands (
  id uuid primary key default gen_random_uuid(),
  slug text not null check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  -- Stufe 1 (10 bis 14) oder später Stufe 2 (15 bis 18).
  stage smallint not null default 1 check (stage in (1, 2)),
  island_group smallint,
  sort_order integer not null,
  -- Position auf der senkrechten Karte, jeweils 0 bis 1.
  map_x numeric(5, 4) check (map_x between 0 and 1),
  map_y numeric(5, 4) check (map_y between 0 and 1),
  route_type text not null default 'main' check (route_type in ('main', 'side', 'event')),
  expedition_id uuid references public.expeditions (id) on delete set null,
  title_key text not null,
  intro_video_url text,
  status public.content_status not null default 'draft',
  is_published boolean generated always as (status = 'published') stored,
  publish_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint islands_stage_slug_key unique (stage, slug),
  constraint islands_event_needs_expedition
    check (route_type <> 'event' or expedition_id is not null)
);

create index islands_stage_sort_idx on public.islands (stage, sort_order);

-- ---------------------------------------------------------------------------
-- Stationen
-- ---------------------------------------------------------------------------

create table public.stations (
  id uuid primary key default gen_random_uuid(),
  island_id uuid not null references public.islands (id) on delete restrict,
  sort_order integer not null,
  type text not null check (type in ('video', 'quiz', 'game', 'practice', 'review_stop', 'exam')),
  is_required boolean not null default true,
  -- Inhalts-Version, in der die Station dazukam (1 = Start).
  added_in_version integer not null default 1 check (added_in_version >= 1),
  xp_reward integer not null default 0 check (xp_reward >= 0),
  content jsonb not null default '{}'::jsonb,
  status public.content_status not null default 'draft',
  is_published boolean generated always as (status = 'published') stored,
  publish_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint stations_island_sort_key unique (island_id, sort_order)
);

-- ---------------------------------------------------------------------------
-- Quizfragen
-- ---------------------------------------------------------------------------

create table public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  station_id uuid not null references public.stations (id) on delete restrict,
  question text not null check (length(trim(question)) > 0),
  answers jsonb not null,
  correct_index smallint not null,
  explanation text,
  status public.content_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint quiz_questions_answers_check check (
    jsonb_typeof(answers) = 'array'
    and jsonb_array_length(answers) >= 2
    and correct_index >= 0
    and correct_index < jsonb_array_length(answers)
  )
);

create index quiz_questions_station_idx on public.quiz_questions (station_id);

-- ---------------------------------------------------------------------------
-- Kombüsen-Fragen (nur im Elternbereich sichtbar)
-- ---------------------------------------------------------------------------

create table public.conversation_prompts (
  id uuid primary key default gen_random_uuid(),
  island_id uuid not null references public.islands (id) on delete cascade,
  text text not null check (length(trim(text)) > 0),
  status public.content_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index conversation_prompts_island_idx on public.conversation_prompts (island_id);

-- ---------------------------------------------------------------------------
-- updated_at automatisch setzen
-- ---------------------------------------------------------------------------

create trigger expeditions_set_updated_at before update on public.expeditions
  for each row execute function public.set_updated_at();
create trigger islands_set_updated_at before update on public.islands
  for each row execute function public.set_updated_at();
create trigger stations_set_updated_at before update on public.stations
  for each row execute function public.set_updated_at();
create trigger quiz_questions_set_updated_at before update on public.quiz_questions
  for each row execute function public.set_updated_at();
create trigger conversation_prompts_set_updated_at before update on public.conversation_prompts
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Regel: Pflichtstationen veröffentlichter Inseln
-- ---------------------------------------------------------------------------

create or replace function public.island_is_published(p_island_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select i.status = 'published' from public.islands i where i.id = p_island_id),
    false
  );
$$;

create or replace function public.guard_station_rules()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    if new.is_required and public.island_is_published(new.island_id) then
      raise exception 'Neue Stationen an einer veröffentlichten Insel müssen Bonus sein (is_required = false)'
        using errcode = 'P0001';
    end if;
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if public.island_is_published(old.island_id) then
      if new.is_required and not old.is_required then
        raise exception 'Eine Bonus-Station einer veröffentlichten Insel kann keine Pflichtstation werden'
          using errcode = 'P0001';
      end if;
      if old.is_required and not new.is_required then
        raise exception 'Pflichtstationen einer veröffentlichten Insel bleiben Pflicht'
          using errcode = 'P0001';
      end if;
      if new.island_id <> old.island_id and old.is_required then
        raise exception 'Pflichtstationen einer veröffentlichten Insel können nicht verschoben werden'
          using errcode = 'P0001';
      end if;
      if old.is_required and old.status = 'published' and new.status <> 'published' then
        raise exception 'Pflichtstationen einer veröffentlichten Insel können nicht zurückgezogen werden'
          using errcode = 'P0001';
      end if;
    end if;
    if new.island_id <> old.island_id
       and new.is_required
       and public.island_is_published(new.island_id) then
      raise exception 'Neue Stationen an einer veröffentlichten Insel müssen Bonus sein (is_required = false)'
        using errcode = 'P0001';
    end if;
    return new;
  end if;

  -- DELETE
  if old.is_required and public.island_is_published(old.island_id) then
    raise exception 'Pflichtstationen einer veröffentlichten Insel dürfen nicht gelöscht werden'
      using errcode = 'P0001';
  end if;
  return old;
end;
$$;

create trigger stations_guard_rules
  before insert or update or delete on public.stations
  for each row execute function public.guard_station_rules();

-- Prüfungsfragen veröffentlichter Inseln dürfen korrigiert, aber nicht
-- entfernt oder zurückgezogen werden.
create or replace function public.guard_exam_question_rules()
returns trigger
language plpgsql
as $$
declare
  v_is_protected boolean;
begin
  select s.type = 'exam' and i.status = 'published'
    into v_is_protected
  from public.stations s
  join public.islands i on i.id = s.island_id
  where s.id = old.station_id;

  if coalesce(v_is_protected, false) then
    if tg_op = 'DELETE' then
      raise exception 'Prüfungsfragen einer veröffentlichten Insel dürfen nicht gelöscht werden'
        using errcode = 'P0001';
    end if;
    if new.station_id <> old.station_id then
      raise exception 'Prüfungsfragen einer veröffentlichten Insel können nicht verschoben werden'
        using errcode = 'P0001';
    end if;
    if old.status = 'published' and new.status <> 'published' then
      raise exception 'Prüfungsfragen einer veröffentlichten Insel können nicht zurückgezogen werden'
        using errcode = 'P0001';
    end if;
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger quiz_questions_guard_exam
  before update or delete on public.quiz_questions
  for each row execute function public.guard_exam_question_rules();

-- Eine veröffentlichte Insel kann nicht gelöscht werden.
create or replace function public.guard_island_delete()
returns trigger
language plpgsql
as $$
begin
  if old.status = 'published' then
    raise exception 'Veröffentlichte Inseln dürfen nicht gelöscht werden'
      using errcode = 'P0001';
  end if;
  return old;
end;
$$;

create trigger islands_guard_delete
  before delete on public.islands
  for each row execute function public.guard_island_delete();

-- ---------------------------------------------------------------------------
-- Frühere Fassungen sichern
-- ---------------------------------------------------------------------------

-- Bevor ein veröffentlichter Inhalt geändert oder gelöscht wird, landet die
-- alte Fassung in content_versions.
create or replace function public.snapshot_published_content()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.status = 'published' then
    insert into public.content_versions (entity_type, entity_id, snapshot, created_by)
    values (tg_table_name, old.id, to_jsonb(old), auth.uid());
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger expeditions_snapshot after update or delete on public.expeditions
  for each row execute function public.snapshot_published_content();
create trigger islands_snapshot after update or delete on public.islands
  for each row execute function public.snapshot_published_content();
create trigger stations_snapshot after update or delete on public.stations
  for each row execute function public.snapshot_published_content();
create trigger quiz_questions_snapshot after update or delete on public.quiz_questions
  for each row execute function public.snapshot_published_content();
create trigger conversation_prompts_snapshot after update or delete on public.conversation_prompts
  for each row execute function public.snapshot_published_content();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
--
-- Lesen: Angemeldete Nutzer sehen nur sichtbare Inhalte (veröffentlicht und
-- Termin erreicht), und nur, wenn die übergeordnete Insel ebenfalls sichtbar ist.
-- Die genauen Regeln für Kinder- und Eltern-Sitzungen kommen in Schritt 2.
-- Admins (owner, editor, support) sehen alles, auch Entwürfe.
-- Schreiben: nur owner und editor.

alter table public.expeditions enable row level security;
alter table public.islands enable row level security;
alter table public.stations enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.conversation_prompts enable row level security;

-- Expeditionen
create policy "Sichtbare Expeditionen lesen"
  on public.expeditions for select to authenticated
  using (public.is_content_visible(status, publish_at) or public.is_admin());
create policy "Editoren schreiben Expeditionen"
  on public.expeditions for all to authenticated
  using (public.is_admin(array['owner', 'editor']))
  with check (public.is_admin(array['owner', 'editor']));

-- Inseln
create policy "Sichtbare Inseln lesen"
  on public.islands for select to authenticated
  using (public.is_content_visible(status, publish_at) or public.is_admin());
create policy "Editoren schreiben Inseln"
  on public.islands for all to authenticated
  using (public.is_admin(array['owner', 'editor']))
  with check (public.is_admin(array['owner', 'editor']));

-- Stationen
create policy "Sichtbare Stationen lesen"
  on public.stations for select to authenticated
  using (
    public.is_admin()
    or (
      public.is_content_visible(status, publish_at)
      and exists (
        select 1 from public.islands i
        where i.id = island_id
          and public.is_content_visible(i.status, i.publish_at)
      )
    )
  );
create policy "Editoren schreiben Stationen"
  on public.stations for all to authenticated
  using (public.is_admin(array['owner', 'editor']))
  with check (public.is_admin(array['owner', 'editor']));

-- Quizfragen
create policy "Sichtbare Quizfragen lesen"
  on public.quiz_questions for select to authenticated
  using (
    public.is_admin()
    or (
      status = 'published'
      and exists (
        select 1
        from public.stations s
        join public.islands i on i.id = s.island_id
        where s.id = station_id
          and public.is_content_visible(s.status, s.publish_at)
          and public.is_content_visible(i.status, i.publish_at)
      )
    )
  );
create policy "Editoren schreiben Quizfragen"
  on public.quiz_questions for all to authenticated
  using (public.is_admin(array['owner', 'editor']))
  with check (public.is_admin(array['owner', 'editor']));

-- Kombüsen-Fragen
create policy "Sichtbare Kombüsen-Fragen lesen"
  on public.conversation_prompts for select to authenticated
  using (
    public.is_admin()
    or (
      status = 'published'
      and exists (
        select 1 from public.islands i
        where i.id = island_id
          and public.is_content_visible(i.status, i.publish_at)
      )
    )
  );
create policy "Editoren schreiben Kombüsen-Fragen"
  on public.conversation_prompts for all to authenticated
  using (public.is_admin(array['owner', 'editor']))
  with check (public.is_admin(array['owner', 'editor']));

-- ===========================================================================
-- Migration 20261009000300_konten.sql
-- ===========================================================================

-- Taleria, Schritt 2: Konten und Rollen
--
-- Enthält:
--   * parents        Eltern-Konto, verknüpft mit auth.users, mit Einwilligung und Eltern-PIN
--   * children       Kinder-Profile (nur Spitzname, Geburtsjahr, Niveau, Avatar, Schiffsname)
--   * child_login_codes  kurzlebige Codes, mit denen ein Kinder-Gerät sich anmeldet
--   * child_devices  welches Kinder-Gerät (anonyme Supabase-Sitzung) zu welchem Kind gehört
--
-- Ablauf:
--   1. Eltern registrieren sich mit E-Mail und Passwort. Die Einwilligung wird
--      bei der Registrierung mitgeschickt; ein Trigger legt den Eintrag in
--      parents mit Zeitpunkt an. Ohne Einwilligung keine Registrierung.
--   2. Eltern legen Kinder-Profile an und erzeugen einen Anmelde-Code.
--   3. Das Kinder-Gerät meldet sich anonym an und löst den Code ein.
--      Ab dann darf diese Sitzung nur auf dieses eine Kinder-Profil zugreifen.
--
-- Codes und PIN werden nur als Prüfsumme gespeichert. Löschen läuft über
-- Funktionen, damit auch die Kinder-Geräte abgemeldet werden.

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- Tabellen
-- ---------------------------------------------------------------------------

create table public.parents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  -- Einwilligung zur Datenverarbeitung: Zeitpunkt und Fassung des Textes.
  consent_at timestamptz not null,
  consent_version text not null check (length(trim(consent_version)) > 0),
  locale text not null default 'de',
  parent_pin_hash text,
  has_parent_pin boolean generated always as (parent_pin_hash is not null) stored,
  parent_pin_failed_attempts smallint not null default 0,
  parent_pin_locked_until timestamptz,
  -- Newsletter und Push (MARKETING.md, Abschnitt 5).
  marketing_consent_at timestamptz,
  marketing_confirmed_at timestamptz,
  marketing_unsubscribed_at timestamptz,
  push_consent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.children (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.parents (id) on delete cascade,
  -- Nur ein Spitzname, kein Klarname.
  nickname text not null check (char_length(trim(nickname)) between 2 and 20),
  birth_year smallint not null check (birth_year between 2000 and 2100),
  level_setting text not null default 'beginner' check (level_setting in ('beginner', 'advanced')),
  stage smallint not null default 1 check (stage in (1, 2)),
  avatar jsonb not null default '{}'::jsonb,
  ship_name text check (ship_name is null or char_length(trim(ship_name)) between 2 and 30),
  -- Tempo: Stationen pro Woche, null = freie Fahrt.
  stations_per_week smallint default 2 check (stations_per_week is null or stations_per_week between 1 and 7),
  -- Wochentage für neue Stationen (1 = Montag … 7 = Sonntag).
  release_weekdays smallint[] not null default '{1,4}'
    check (cardinality(release_weekdays) >= 1 and release_weekdays <@ '{1,2,3,4,5,6,7}'::smallint[]),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index children_parent_idx on public.children (parent_id);

create table public.child_login_codes (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  -- SHA-256 des Codes. Der Code selbst wird nur einmal angezeigt.
  code_hash text not null unique,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index child_login_codes_child_idx on public.child_login_codes (child_id);

create table public.child_devices (
  id uuid primary key default gen_random_uuid(),
  -- Die anonyme Supabase-Sitzung des Kinder-Geräts.
  user_id uuid not null unique references auth.users (id) on delete cascade,
  child_id uuid not null references public.children (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index child_devices_child_idx on public.child_devices (child_id);

create trigger parents_set_updated_at before update on public.parents
  for each row execute function public.set_updated_at();
create trigger children_set_updated_at before update on public.children
  for each row execute function public.set_updated_at();
create trigger child_login_codes_set_updated_at before update on public.child_login_codes
  for each row execute function public.set_updated_at();
create trigger child_devices_set_updated_at before update on public.child_devices
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Wer bin ich?
-- ---------------------------------------------------------------------------

create or replace function public.current_parent_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select p.id from public.parents p where p.user_id = auth.uid();
$$;

create or replace function public.current_child_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select d.child_id from public.child_devices d where d.user_id = auth.uid();
$$;

create or replace function public.is_anonymous_session()
returns boolean
language sql
stable
as $$
  select coalesce(auth.jwt() ->> 'is_anonymous', 'false') = 'true';
$$;

-- ---------------------------------------------------------------------------
-- Registrierung: Eltern-Eintrag mit Einwilligung anlegen
-- ---------------------------------------------------------------------------

-- Die App schickt bei der Registrierung mit:
--   { "taleria_role": "parent", "consent_version": "...", "marketing_consent": true|false, "locale": "de" }
-- Anonyme Kinder-Sitzungen und Konten ohne taleria_role (z. B. Admins) bekommen
-- keinen Eltern-Eintrag.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
begin
  if new.is_anonymous or coalesce(v_meta ->> 'taleria_role', '') <> 'parent' then
    return new;
  end if;

  if coalesce(trim(v_meta ->> 'consent_version'), '') = '' then
    raise exception 'Registrierung ohne Einwilligung ist nicht möglich'
      using errcode = 'P0001';
  end if;

  insert into public.parents (user_id, consent_at, consent_version, locale, marketing_consent_at)
  values (
    new.id,
    now(),
    trim(v_meta ->> 'consent_version'),
    coalesce(nullif(trim(v_meta ->> 'locale'), ''), 'de'),
    case when v_meta ->> 'marketing_consent' = 'true' then now() end
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- ---------------------------------------------------------------------------
-- Eltern-PIN
-- ---------------------------------------------------------------------------

create or replace function public.set_parent_pin(p_pin text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_parent uuid := public.current_parent_id();
begin
  if v_parent is null then
    raise exception 'Nur für Eltern' using errcode = '42501';
  end if;
  if p_pin is null or p_pin !~ '^[0-9]{4,6}$' then
    raise exception 'Die PIN muss aus 4 bis 6 Ziffern bestehen' using errcode = '22023';
  end if;
  update public.parents
  set parent_pin_hash = extensions.crypt(p_pin, extensions.gen_salt('bf', 8)),
      parent_pin_failed_attempts = 0,
      parent_pin_locked_until = null
  where id = v_parent;
end;
$$;

-- Prüft die PIN. Nach 5 falschen Versuchen ist die PIN 5 Minuten gesperrt.
-- Antwort: status = ok | wrong | locked | not_set
create or replace function public.verify_parent_pin(p_pin text)
returns table (status text, locked_until timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_parent record;
  v_attempts smallint;
begin
  select p.id, p.parent_pin_hash, p.parent_pin_failed_attempts, p.parent_pin_locked_until
    into v_parent
  from public.parents p
  where p.user_id = auth.uid()
  for update;

  if not found then
    raise exception 'Nur für Eltern' using errcode = '42501';
  end if;
  if v_parent.parent_pin_hash is null then
    return query select 'not_set'::text, null::timestamptz;
    return;
  end if;
  if v_parent.parent_pin_locked_until is not null and v_parent.parent_pin_locked_until > now() then
    return query select 'locked'::text, v_parent.parent_pin_locked_until;
    return;
  end if;

  if p_pin is not null and extensions.crypt(p_pin, v_parent.parent_pin_hash) = v_parent.parent_pin_hash then
    update public.parents
    set parent_pin_failed_attempts = 0, parent_pin_locked_until = null
    where id = v_parent.id;
    return query select 'ok'::text, null::timestamptz;
    return;
  end if;

  v_attempts := v_parent.parent_pin_failed_attempts + 1;
  if v_attempts >= 5 then
    update public.parents
    set parent_pin_failed_attempts = 0, parent_pin_locked_until = now() + interval '5 minutes'
    where id = v_parent.id;
    return query select 'locked'::text, now() + interval '5 minutes';
  else
    update public.parents
    set parent_pin_failed_attempts = v_attempts, parent_pin_locked_until = null
    where id = v_parent.id;
    return query select 'wrong'::text, null::timestamptz;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Anmelde-Codes für Kinder-Geräte
-- ---------------------------------------------------------------------------

-- Erzeugt einen neuen Code (8 Zeichen, 15 Minuten gültig, einmal nutzbar).
-- Ältere, noch nicht benutzte Codes desselben Kindes werden ungültig.
-- Ohne die leicht verwechselbaren Zeichen I, L, O, 0 und 1.
create or replace function public.create_child_login_code(p_child_id uuid)
returns table (login_code text, valid_until timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_bytes bytea := extensions.gen_random_bytes(8);
  v_code text := '';
  v_valid_until timestamptz := now() + interval '15 minutes';
begin
  if not exists (
    select 1 from public.children c
    where c.id = p_child_id and c.parent_id = public.current_parent_id()
  ) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  delete from public.child_login_codes c
  where c.child_id = p_child_id and c.used_at is null;

  for i in 0..7 loop
    v_code := v_code || substr(v_alphabet, (get_byte(v_bytes, i) % length(v_alphabet)) + 1, 1);
  end loop;

  insert into public.child_login_codes (child_id, code_hash, expires_at)
  values (p_child_id, encode(extensions.digest(v_code, 'sha256'), 'hex'), v_valid_until);

  return query select v_code, v_valid_until;
end;
$$;

-- Löst einen Code auf einem Kinder-Gerät ein. Nur anonyme Sitzungen dürfen das.
-- Falscher, abgelaufener oder benutzter Code: leere Antwort.
create or replace function public.redeem_child_login_code(p_code text)
returns table (child_id uuid, nickname text)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid();
  v_code text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  v_login record;
begin
  if v_uid is null then
    raise exception 'Nicht angemeldet' using errcode = '42501';
  end if;
  if not public.is_anonymous_session() then
    raise exception 'Codes werden nur auf Kinder-Geräten eingelöst' using errcode = '42501';
  end if;

  select c.id, c.child_id
    into v_login
  from public.child_login_codes c
  where c.code_hash = encode(extensions.digest(v_code, 'sha256'), 'hex')
    and c.used_at is null
    and c.expires_at > now()
  for update;

  if not found then
    return;
  end if;

  update public.child_login_codes set used_at = now() where id = v_login.id;

  insert into public.child_devices (user_id, child_id)
  values (v_uid, v_login.child_id)
  on conflict (user_id) do update set child_id = excluded.child_id;

  return query
    select ch.id, ch.nickname from public.children ch where ch.id = v_login.child_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Abmelden und Löschen
-- ---------------------------------------------------------------------------

-- Meldet alle Geräte eines Kindes ab (z. B. wenn ein Handy verloren ging).
create or replace function public.sign_out_child_devices(p_child_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.children c
    where c.id = p_child_id and c.parent_id = public.current_parent_id()
  ) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  delete from auth.users u
  where u.id in (select d.user_id from public.child_devices d where d.child_id = p_child_id);
end;
$$;

-- Löscht ein Kinder-Profil mit allen Daten und meldet seine Geräte ab.
create or replace function public.delete_child(p_child_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.sign_out_child_devices(p_child_id);
  delete from public.children c where c.id = p_child_id;
end;
$$;

-- Löscht das ganze Eltern-Konto mit allen Kindern und Daten.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_parent uuid := public.current_parent_id();
begin
  if v_parent is null then
    raise exception 'Nur für Eltern' using errcode = '42501';
  end if;
  if exists (select 1 from public.admins a where a.user_id = v_uid) then
    raise exception 'Admin-Konten werden nicht über die App gelöscht' using errcode = '42501';
  end if;

  delete from auth.users u
  where u.id in (
    select d.user_id
    from public.child_devices d
    join public.children c on c.id = d.child_id
    where c.parent_id = v_parent
  );
  -- Löscht über "on delete cascade" auch parents, children und alles, was daran hängt.
  delete from auth.users u where u.id = v_uid;
end;
$$;

-- Nur angemeldete Sitzungen dürfen die Konto-Funktionen aufrufen.
revoke execute on function
  public.set_parent_pin(text),
  public.verify_parent_pin(text),
  public.create_child_login_code(uuid),
  public.redeem_child_login_code(text),
  public.sign_out_child_devices(uuid),
  public.delete_child(uuid),
  public.delete_my_account()
from public, anon;

grant execute on function
  public.set_parent_pin(text),
  public.verify_parent_pin(text),
  public.create_child_login_code(uuid),
  public.redeem_child_login_code(text),
  public.sign_out_child_devices(uuid),
  public.delete_child(uuid),
  public.delete_my_account()
to authenticated;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.parents enable row level security;
alter table public.children enable row level security;
alter table public.child_login_codes enable row level security;
alter table public.child_devices enable row level security;

-- Eltern: nur das eigene Konto lesen. Ändern nur über Funktionen.
create policy "Eltern sehen ihr eigenes Konto"
  on public.parents for select to authenticated
  using (user_id = auth.uid());

-- PIN-Prüfsumme und Fehlversuche verlassen nie die Datenbank.
revoke all on public.parents from anon, authenticated;
grant select (
  id, user_id, consent_at, consent_version, locale, has_parent_pin, parent_pin_locked_until,
  marketing_consent_at, marketing_confirmed_at, marketing_unsubscribed_at, push_consent_at,
  created_at, updated_at
) on public.parents to authenticated;

-- Kinder-Profile: Eltern sehen und pflegen ihre Kinder, ein Kinder-Gerät sieht
-- nur sein eigenes Profil. Löschen nur über delete_child().
create policy "Eltern und Kinder-Gerät sehen das Profil"
  on public.children for select to authenticated
  using (parent_id = public.current_parent_id() or id = public.current_child_id());

create policy "Eltern legen Kinder-Profile an"
  on public.children for insert to authenticated
  with check (parent_id = public.current_parent_id());

create policy "Eltern ändern Kinder-Profile"
  on public.children for update to authenticated
  using (parent_id = public.current_parent_id())
  with check (parent_id = public.current_parent_id());

-- Anmelde-Codes: kein direkter Zugriff, nur über die Funktionen oben.

-- Kinder-Geräte: Eltern sehen die Geräte ihrer Kinder, ein Gerät sich selbst.
create policy "Eltern und Gerät sehen Geräte-Zuordnung"
  on public.child_devices for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.children c
      where c.id = child_id and c.parent_id = public.current_parent_id()
    )
  );

-- ===========================================================================
-- Migration 20261009000400_intro.sql
-- ===========================================================================

-- Taleria, Schritt 3: Intro
--
-- Enthält:
--   * Avatar, Schiffsname und Abschluss des Intros am Kinder-Profil
--   * savings_goals  Wunschschätze (Sparziele) des Kindes
--   * xp_events      Kassenbuch der Seemeilen; der Rang wird später daraus berechnet
--
-- Das Intro ist Station 1 des Hafens („Willkommen an Bord“, INSELN.md).
-- Kinder-Geräte dürfen ihr Profil nicht direkt ändern. Avatar und Schiffsname
-- laufen deshalb über update_child_look(), der Abschluss über complete_onboarding().
-- Seemeilen bucht nur der Server, nie die App.

-- ---------------------------------------------------------------------------
-- Kinder-Profil
-- ---------------------------------------------------------------------------

alter table public.children
  add column onboarding_completed_at timestamptz,
  add constraint children_avatar_check
    check (jsonb_typeof(avatar) = 'object' and pg_column_size(avatar) <= 1024);

-- Darf die aktuelle Sitzung für dieses Kind handeln?
-- Ja für die Eltern des Kindes und für das angemeldete Kinder-Gerät.
create or replace function public.can_act_for_child(p_child_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.children c
    where c.id = p_child_id
      and (c.parent_id = public.current_parent_id() or c.id = public.current_child_id())
  );
$$;

-- Avatar und/oder Schiffsname setzen. null = unverändert lassen.
create or replace function public.update_child_look(
  p_child_id uuid,
  p_avatar jsonb default null,
  p_ship_name text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;
  update public.children
  set avatar = coalesce(p_avatar, avatar),
      ship_name = coalesce(nullif(trim(p_ship_name), ''), ship_name)
  where id = p_child_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Wunschschätze
-- ---------------------------------------------------------------------------

create table public.savings_goals (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 2 and 40),
  -- Virtueller Betrag in Cent: 1 € bis 10.000 €.
  target_cents integer not null check (target_cents between 100 and 1000000),
  reached_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index savings_goals_child_idx on public.savings_goals (child_id);

create trigger savings_goals_set_updated_at before update on public.savings_goals
  for each row execute function public.set_updated_at();

alter table public.savings_goals enable row level security;

create policy "Eltern und Kinder-Gerät sehen Wunschschätze"
  on public.savings_goals for select to authenticated
  using (public.can_act_for_child(child_id));

-- Anlegen darf das Kind selbst. Ändern und Löschen kommen mit Schritt 5.
create policy "Eltern und Kinder-Gerät legen Wunschschätze an"
  on public.savings_goals for insert to authenticated
  with check (public.can_act_for_child(child_id) and reached_at is null);

-- ---------------------------------------------------------------------------
-- Seemeilen
-- ---------------------------------------------------------------------------

create table public.xp_events (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  -- Wofür: onboarding, station, exam, dive, review, encounter, task …
  source_type text not null check (source_type ~ '^[a-z_]{3,30}$'),
  source_id uuid not null,
  amount integer not null check (amount > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Seemeilen gibt es für jede Sache nur einmal.
  constraint xp_events_once unique (child_id, source_type, source_id)
);

create index xp_events_child_idx on public.xp_events (child_id);

alter table public.xp_events enable row level security;

-- Lesen dürfen Eltern und Kind. Schreiben nur Server-Funktionen.
create policy "Eltern und Kinder-Gerät sehen Seemeilen"
  on public.xp_events for select to authenticated
  using (public.can_act_for_child(child_id));

-- ---------------------------------------------------------------------------
-- Intro abschließen
-- ---------------------------------------------------------------------------

-- Schließt das Intro (Station 1 des Hafens) ab und schreibt die Seemeilen gut.
-- Mehrfach aufrufbar, die Seemeilen gibt es aber nur einmal.
-- Antwort: gutgeschriebene Seemeilen (0, wenn schon vorher abgeschlossen).
--
-- Die 50 Seemeilen stammen aus INSELN.md (Hafen, Station 1). Sobald die
-- Stationen in Schritt 4 als Inhalte in der Datenbank liegen, kommt der Wert
-- von dort.
create or replace function public.complete_onboarding(p_child_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_amount constant integer := 50;
  v_inserted integer;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  update public.children
  set onboarding_completed_at = coalesce(onboarding_completed_at, now())
  where id = p_child_id;

  insert into public.xp_events (child_id, source_type, source_id, amount)
  values (p_child_id, 'onboarding', p_child_id, v_amount)
  on conflict on constraint xp_events_once do nothing;

  get diagnostics v_inserted = row_count;
  return case when v_inserted > 0 then v_amount else 0 end;
end;
$$;

revoke execute on function
  public.update_child_look(uuid, jsonb, text),
  public.complete_onboarding(uuid)
from public, anon;

grant execute on function
  public.update_child_look(uuid, jsonb, text),
  public.complete_onboarding(uuid)
to authenticated;

-- ===========================================================================
-- Migration 20261009000500_titel_in_datenbank.sql
-- ===========================================================================

-- Taleria, Schritt 4a: Namen von Inseln und Expeditionen stehen in der Datenbank
--
-- Entscheidung mit Marc (09.10.2026): Inhaltstexte kommen aus der Datenbank,
-- nicht aus den Übersetzungsdateien der App. So braucht eine neue Insel oder
-- Expedition kein App-Update (CLAUDE.md, Abschnitt 10).

alter table public.islands rename column title_key to title;
alter table public.islands
  add constraint islands_title_check check (char_length(trim(title)) between 1 and 60);

alter table public.expeditions rename column title_key to title;
alter table public.expeditions
  add constraint expeditions_title_check check (char_length(trim(title)) between 1 and 60);

-- ===========================================================================
-- Migration 20261009000600_fortschritt.sql
-- ===========================================================================

-- Taleria, Schritt 4b: Fortschritt auf der Inselkarte
--
-- Enthält:
--   * app_settings          Einstellungen der Umgebung, z. B. Inhalts-Vorschau (nur Test)
--   * station_progress      erledigte Stationen pro Kind
--   * island_completions    abgeschlossene Inseln pro Kind (eingefroren, CLAUDE.md Abschnitt 8)
--   * map_islands()         Inseln für die Karte, auch die im Nebel
--   * submit_station()      Station abgeben: Server prüft Antworten, bucht Seemeilen,
--                           schließt die Insel ab
--
-- Freischalten (CLAUDE.md Abschnitt 8):
--   * Die erste Insel der Hauptroute ist offen. Jede weitere öffnet sich, sobald die
--     vorherige abgeschlossen ist.
--   * Auf einer Insel öffnet sich jede Pflichtstation, sobald alle Pflichtstationen
--     davor erledigt sind. Bonus-Stationen (Flaschenpost) sind offen, sobald die Insel offen ist.
--   * Das Tempo (2 Stationen pro Woche) kommt in Schritt 6 dazu.

-- ---------------------------------------------------------------------------
-- Einstellungen der Umgebung
-- ---------------------------------------------------------------------------

create table public.app_settings (
  id uuid primary key default gen_random_uuid(),
  key text not null unique check (key ~ '^[a-z_]+$'),
  value jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger app_settings_set_updated_at before update on public.app_settings
  for each row execute function public.set_updated_at();

alter table public.app_settings enable row level security;

create policy "Admins sehen Einstellungen"
  on public.app_settings for select to authenticated
  using (public.is_admin());

create policy "Owner ändern Einstellungen"
  on public.app_settings for all to authenticated
  using (public.is_admin(array['owner']))
  with check (public.is_admin(array['owner']));

-- Inhalts-Vorschau: Kinder sehen auch Entwürfe. NUR in der Testumgebung
-- einschalten (supabase/seed.sql), damit Marc Entwürfe durchspielen kann.
-- In der Live-Datenbank gibt es diesen Eintrag nicht.
create or replace function public.content_preview_enabled()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select s.value = 'true'::jsonb from public.app_settings s where s.key = 'content_preview'),
    false
  );
$$;

-- Sichtbar für Kinder: veröffentlicht und Termin erreicht, oder Vorschau an.
create or replace function public.is_content_visible(
  p_status public.content_status,
  p_publish_at timestamptz
)
returns boolean
language sql
stable
as $$
  select (p_status = 'published' and (p_publish_at is null or p_publish_at <= now()))
      or public.content_preview_enabled();
$$;

-- Quizfragen und Kombüsen-Fragen folgen derselben Regel (auch in der Vorschau).
drop policy "Sichtbare Quizfragen lesen" on public.quiz_questions;
create policy "Sichtbare Quizfragen lesen"
  on public.quiz_questions for select to authenticated
  using (
    public.is_admin()
    or (
      public.is_content_visible(status, null)
      and exists (
        select 1
        from public.stations s
        join public.islands i on i.id = s.island_id
        where s.id = station_id
          and public.is_content_visible(s.status, s.publish_at)
          and public.is_content_visible(i.status, i.publish_at)
      )
    )
  );

drop policy "Sichtbare Kombüsen-Fragen lesen" on public.conversation_prompts;
create policy "Sichtbare Kombüsen-Fragen lesen"
  on public.conversation_prompts for select to authenticated
  using (
    public.is_admin()
    or (
      public.is_content_visible(status, null)
      and exists (
        select 1 from public.islands i
        where i.id = island_id
          and public.is_content_visible(i.status, i.publish_at)
      )
    )
  );

-- ---------------------------------------------------------------------------
-- Fortschritt
-- ---------------------------------------------------------------------------

create table public.station_progress (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  station_id uuid not null references public.stations (id) on delete cascade,
  status text not null default 'open' check (status in ('open', 'done')),
  -- Richtige Antworten im besten und im letzten Durchgang.
  best_score smallint,
  last_score smallint,
  attempts integer not null default 0,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint station_progress_once unique (child_id, station_id),
  constraint station_progress_done_has_date check (status <> 'done' or completed_at is not null)
);

create index station_progress_child_idx on public.station_progress (child_id);

create trigger station_progress_set_updated_at before update on public.station_progress
  for each row execute function public.set_updated_at();

create table public.island_completions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  island_id uuid not null references public.islands (id) on delete cascade,
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint island_completions_once unique (child_id, island_id)
);

create index island_completions_child_idx on public.island_completions (child_id);

-- Ein Insel-Abschluss wird nie geändert oder neu berechnet.
create or replace function public.prevent_island_completion_change()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Ein Insel-Abschluss ist eingefroren und wird nicht geändert'
    using errcode = 'P0001';
end;
$$;

create trigger island_completions_frozen
  before update on public.island_completions
  for each row execute function public.prevent_island_completion_change();

alter table public.station_progress enable row level security;
alter table public.island_completions enable row level security;

-- Lesen dürfen Eltern und Kind. Schreiben nur submit_station() und complete_onboarding().
create policy "Eltern und Kinder-Gerät sehen Stationsfortschritt"
  on public.station_progress for select to authenticated
  using (public.can_act_for_child(child_id));

create policy "Eltern und Kinder-Gerät sehen Insel-Abschlüsse"
  on public.island_completions for select to authenticated
  using (public.can_act_for_child(child_id));

-- ---------------------------------------------------------------------------
-- Regeln zum Freischalten
-- ---------------------------------------------------------------------------

-- Ist die Station für das Kind erledigt? Die Intro-Station des Hafens gilt
-- als erledigt, sobald das Intro abgeschlossen ist (auch wenn das Intro vor
-- den Seed-Daten gespielt wurde).
create or replace function public.station_done(p_child_id uuid, p_station_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.station_progress p
    where p.child_id = p_child_id and p.station_id = p_station_id and p.status = 'done'
  )
  or exists (
    select 1
    from public.stations s, public.children c
    where s.id = p_station_id
      and c.id = p_child_id
      and s.content ->> 'kind' = 'onboarding'
      and c.onboarding_completed_at is not null
  );
$$;

-- Ist die Insel für das Kind offen? Erste Insel der Hauptroute oder die
-- vorherige Insel der Hauptroute ist abgeschlossen.
create or replace function public.island_unlocked(p_child_id uuid, p_island_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with target as (
    select i.id, i.stage, i.sort_order from public.islands i where i.id = p_island_id
  ),
  previous as (
    select i.id
    from public.islands i, target t
    where i.stage = t.stage
      and i.route_type = 'main'
      and i.sort_order < t.sort_order
    order by i.sort_order desc
    limit 1
  )
  select exists (select 1 from target)
     and (
       not exists (select 1 from previous)
       or exists (
         select 1 from public.island_completions c, previous p
         where c.child_id = p_child_id and c.island_id = p.id
       )
     );
$$;

-- Ist die Station für das Kind offen?
create or replace function public.station_unlocked(p_child_id uuid, p_station_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.stations s
    where s.id = p_station_id
      and public.island_unlocked(p_child_id, s.island_id)
      and (
        not s.is_required
        or not exists (
          select 1
          from public.stations earlier
          where earlier.island_id = s.island_id
            and earlier.is_required
            and earlier.sort_order < s.sort_order
            and public.is_content_visible(earlier.status, earlier.publish_at)
            and not public.station_done(p_child_id, earlier.id)
        )
      )
  );
$$;

-- ---------------------------------------------------------------------------
-- Karte
-- ---------------------------------------------------------------------------

-- Alle Inseln einer Stufe für die Karte, auch solche, deren Inhalte noch
-- nicht veröffentlicht sind (Nebel). Von Inseln im Nebel gibt es nur Name
-- und Position, keine Stationen.
create or replace function public.map_islands(p_stage smallint)
returns table (
  id uuid,
  slug text,
  title text,
  island_group smallint,
  sort_order integer,
  map_x numeric,
  map_y numeric,
  route_type text,
  has_content boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    i.id,
    i.slug,
    i.title,
    i.island_group,
    i.sort_order,
    i.map_x,
    i.map_y,
    i.route_type,
    public.is_content_visible(i.status, i.publish_at)
      and exists (
        select 1 from public.stations s
        where s.island_id = i.id
          and s.is_required
          and public.is_content_visible(s.status, s.publish_at)
      ) as has_content
  from public.islands i
  where auth.uid() is not null
    and i.stage = p_stage
    and i.route_type in ('main', 'side')
  order by i.sort_order;
$$;

-- ---------------------------------------------------------------------------
-- Station abgeben
-- ---------------------------------------------------------------------------

-- p_answers: [{"question_id": "...", "answer_index": 0}, ...]
--   answer_index ist die Stelle in der gespeicherten Antwortliste (vor dem Mischen).
--
-- Stations-Check und Quiz: genau content.quiz.show Antworten aus dem Pool der
-- Station. Erledigt ist die Station nach dem Durchgang, Fehler kosten nichts.
-- Abschlussprüfung: content.exam.show Fragen der Insel plus content.exam.review
-- Rückblick-Fragen aus Prüfungen früherer Inseln, bestanden ab content.exam.pass.
-- Seemeilen gibt es einmal pro Station (stations.xp_reward).
--
-- Antwort: {"correct": 4, "total": 5, "passed": true, "xp_awarded": 100, "island_completed": false}
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
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  select s.id, s.island_id, s.type, s.xp_reward, s.content, s.status, s.publish_at
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
      g.answer_index,
      q.correct_index,
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
    count(*) filter (where allowed and answer_index = correct_index),
    count(*) filter (where not allowed),
    count(*) filter (where allowed and not own)
  into v_correct, v_invalid, v_review_given
  from checked;

  if v_invalid > 0 then
    raise exception 'Frage gehört nicht zu dieser Station' using errcode = '22023';
  end if;
  if v_review_given <> v_review then
    raise exception 'Falsche Anzahl an Rückblick-Fragen: % erwartet', v_review using errcode = '22023';
  end if;

  v_passed := v_correct >= v_pass;

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

  return jsonb_build_object(
    'correct', v_correct,
    'total', v_total,
    'passed', v_passed,
    'xp_awarded', v_xp,
    'island_completed', v_island_completed
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Intro: Seemeilen aus der Station, Fortschritt eintragen
-- ---------------------------------------------------------------------------

create or replace function public.complete_onboarding(p_child_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_station_id uuid;
  v_station_xp integer;
  v_amount integer := 50;
  v_inserted integer;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  -- Intro-Station der Stufe des Kindes (Hafen, Station 1), wenn es sie schon gibt.
  select s.id, s.xp_reward
    into v_station_id, v_station_xp
  from public.stations s
  join public.islands i on i.id = s.island_id
  join public.children c on c.id = p_child_id and c.stage = i.stage
  where s.content ->> 'kind' = 'onboarding'
  order by i.sort_order, s.sort_order
  limit 1;
  if v_station_id is not null then
    v_amount := v_station_xp;
  end if;

  update public.children
  set onboarding_completed_at = coalesce(onboarding_completed_at, now())
  where id = p_child_id;

  if v_station_id is not null then
    insert into public.station_progress (child_id, station_id, status, attempts, completed_at)
    values (p_child_id, v_station_id, 'done', 1, now())
    on conflict on constraint station_progress_once do nothing;
  end if;

  insert into public.xp_events (child_id, source_type, source_id, amount)
  values (p_child_id, 'onboarding', p_child_id, v_amount)
  on conflict on constraint xp_events_once do nothing;

  get diagnostics v_inserted = row_count;
  return case when v_inserted > 0 then v_amount else 0 end;
end;
$$;

revoke execute on function
  public.submit_station(uuid, uuid, jsonb),
  public.map_islands(smallint)
from public, anon;

grant execute on function
  public.submit_station(uuid, uuid, jsonb),
  public.map_islands(smallint)
to authenticated;

-- ===========================================================================
-- Migration 20261009000700_inhalte_erweitert.sql
-- ===========================================================================

-- Taleria, Schritt 4c: Inhalte erweitert
--
--   * islands.content         Lernziel, Ankunftsszene, Orden, Auftrag fürs echte Leben, Zugang
--   * quiz_questions.covers_station
--                             Zu welcher Station eine Prüfungsfrage gehört. Die App wählt
--                             damit mindestens eine Frage pro Station aus (INSELN.md).

alter table public.islands
  add column content jsonb not null default '{}'::jsonb,
  add constraint islands_content_check check (jsonb_typeof(content) = 'object');

alter table public.quiz_questions
  add column covers_station smallint check (covers_station between 1 and 20);

-- ===========================================================================
-- Migration 20261009000800_budget.sql
-- ===========================================================================

-- Taleria, Schritt 5: Budget und Aufgaben (alles virtuell)
--
-- Enthält:
--   * allowance_rules   Heuer (Taschengeld): Betrag, Rhythmus, nächste Zahlung
--   * tasks             Aufträge der Eltern
--   * ledger_entries    Kassenbuch der drei Truhen (spend = Bordkasse, save = Schatztruhe,
--                       give = Glückstruhe). Guthaben = Summe der Einträge, nie überschreiben.
--   * savings_goals     Ändern, Löschen und Einlösen von Wunschschätzen
--
-- Feste Regeln (CLAUDE.md Abschnitt 8):
--   * Gutschriften nur durch Eltern: Aufträge werden erst nach Bestätigung gutgeschrieben.
--     Das Kind kann sich nichts selbst buchen.
--   * Geld in Cent als ganze Zahl.
--   * Keine Truhe wird negativ.
-- Alle Buchungen laufen über Server-Funktionen. Die App kann das Kassenbuch nur lesen.

-- ---------------------------------------------------------------------------
-- Heuer
-- ---------------------------------------------------------------------------

create table public.allowance_rules (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null unique references public.children (id) on delete cascade,
  amount_cents integer not null check (amount_cents between 1 and 100000),
  interval text not null check (interval in ('weekly', 'monthly')),
  next_run_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger allowance_rules_set_updated_at before update on public.allowance_rules
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Aufträge
-- ---------------------------------------------------------------------------

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.parents (id) on delete cascade,
  child_id uuid not null references public.children (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 2 and 60),
  reward_cents integer not null default 0 check (reward_cents between 0 and 10000),
  -- Pflicht ohne Geld (z. B. Zimmer aufräumen).
  is_chore boolean not null default false,
  status text not null default 'open' check (status in ('open', 'submitted', 'approved', 'rejected')),
  photo_path text,
  due_at timestamptz,
  -- Kurze Nachricht der Eltern, z. B. beim Ablehnen.
  parent_note text check (parent_note is null or char_length(parent_note) <= 200),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tasks_chore_without_money check (not is_chore or reward_cents = 0)
);

create index tasks_child_idx on public.tasks (child_id, status);

create trigger tasks_set_updated_at before update on public.tasks
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Kassenbuch
-- ---------------------------------------------------------------------------

create table public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  pot text not null check (pot in ('spend', 'save', 'give')),
  -- Positiv = Eingang, negativ = Ausgang. Nie 0.
  amount_cents integer not null check (amount_cents <> 0 and abs(amount_cents) <= 1000000),
  -- allowance: Heuer, task: Auftrag, transfer: Umbuchung zwischen Truhen,
  -- manual: Korrektur der Eltern, goal: Wunschschatz eingelöst,
  -- purchase: Ausgabe aus der Bordkasse, donation: Geschenk aus der Glückstruhe
  entry_type text not null check (entry_type in ('allowance', 'task', 'transfer', 'manual', 'goal', 'purchase', 'donation')),
  reference_id uuid,
  note text check (note is null or char_length(note) <= 80),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index ledger_entries_child_idx on public.ledger_entries (child_id, created_at desc);

-- Heuer-Zahlungen, Auftrags-Belohnungen und Wunschschätze gibt es je Vorgang nur einmal.
create unique index ledger_entries_once
  on public.ledger_entries (entry_type, reference_id)
  where entry_type in ('allowance', 'task', 'goal');

-- Das Kassenbuch ist nur zum Anhängen da.
create or replace function public.prevent_ledger_change()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Das Kassenbuch wird nicht geändert, nur ergänzt' using errcode = 'P0001';
end;
$$;

create trigger ledger_entries_append_only
  before update on public.ledger_entries
  for each row execute function public.prevent_ledger_change();

-- ---------------------------------------------------------------------------
-- Hilfsfunktionen
-- ---------------------------------------------------------------------------

create or replace function public.is_parent_of_child(p_child_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.children c
    where c.id = p_child_id and c.parent_id = public.current_parent_id()
  );
$$;

create or replace function public.pot_balance(p_child_id uuid, p_pot text)
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum(e.amount_cents), 0)
  from public.ledger_entries e
  where e.child_id = p_child_id and e.pot = p_pot;
$$;

-- Guthaben der drei Truhen. Nur für Eltern und das Kinder-Gerät des Kindes.
create or replace function public.pot_balances(p_child_id uuid)
returns table (pot text, balance_cents bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select p.pot, public.pot_balance(p_child_id, p.pot)
  from (values ('spend'), ('save'), ('give')) as p (pot)
  where public.can_act_for_child(p_child_id);
$$;

-- Sperrt das Kind für die Dauer der Buchung, damit zwei gleichzeitige
-- Buchungen keine Truhe ins Minus bringen.
create or replace function public.lock_child_for_booking(p_child_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform 1 from public.children c where c.id = p_child_id for update;
end;
$$;

-- ---------------------------------------------------------------------------
-- Heuer festlegen und auszahlen
-- ---------------------------------------------------------------------------

-- Eltern legen die Heuer fest. Betrag null oder 0 beendet sie.
create or replace function public.set_allowance(
  p_child_id uuid,
  p_amount_cents integer,
  p_interval text,
  p_first_payout timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_parent_of_child(p_child_id) then
    raise exception 'Nur für Eltern dieses Kindes' using errcode = '42501';
  end if;
  if coalesce(p_amount_cents, 0) = 0 then
    delete from public.allowance_rules where child_id = p_child_id;
    return;
  end if;
  insert into public.allowance_rules (child_id, amount_cents, interval, next_run_at)
  values (p_child_id, p_amount_cents, p_interval, coalesce(p_first_payout, now()))
  on conflict (child_id) do update
  set amount_cents = excluded.amount_cents,
      interval = excluded.interval,
      next_run_at = coalesce(p_first_payout, public.allowance_rules.next_run_at);
end;
$$;

-- Bucht alle fälligen Heuer-Zahlungen, auch nachträglich. Wird beim Öffnen
-- der App aufgerufen. Jede Zahlung gibt es nur einmal. Antwort: Anzahl der Zahlungen.
create or replace function public.process_due_allowances(p_child_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rule record;
  v_paid integer := 0;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  select r.id, r.amount_cents, r.interval, r.next_run_at
    into v_rule
  from public.allowance_rules r
  where r.child_id = p_child_id
  for update;
  if not found then
    return 0;
  end if;

  -- Höchstens 60 Zahlungen auf einmal (gut ein Jahr wöchentlich).
  while v_rule.next_run_at <= now() and v_paid < 60 loop
    insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, reference_id)
    values (
      p_child_id, 'spend', v_rule.amount_cents, 'allowance',
      md5(v_rule.id::text || v_rule.next_run_at::text)::uuid
    )
    on conflict do nothing;
    v_paid := v_paid + 1;
    v_rule.next_run_at := v_rule.next_run_at
      + case when v_rule.interval = 'weekly' then interval '7 days' else interval '1 month' end;
  end loop;

  update public.allowance_rules set next_run_at = v_rule.next_run_at where id = v_rule.id;
  return v_paid;
end;
$$;

-- ---------------------------------------------------------------------------
-- Aufträge
-- ---------------------------------------------------------------------------

-- Kind meldet: erledigt. Danach müssen die Eltern bestätigen.
create or replace function public.submit_task(p_task_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_task record;
begin
  select t.id, t.child_id, t.status into v_task from public.tasks t where t.id = p_task_id for update;
  if not found or not public.can_act_for_child(v_task.child_id) then
    raise exception 'Auftrag nicht gefunden' using errcode = '42501';
  end if;
  if v_task.status not in ('open', 'rejected') then
    raise exception 'Dieser Auftrag wartet schon auf die Eltern oder ist erledigt' using errcode = 'P0001';
  end if;
  update public.tasks set status = 'submitted', submitted_at = now() where id = p_task_id;
end;
$$;

-- Eltern bestätigen oder lehnen ab. Bestätigen schreibt die Belohnung in die Bordkasse.
create or replace function public.review_task(p_task_id uuid, p_approve boolean, p_note text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_task record;
begin
  select t.id, t.parent_id, t.child_id, t.status, t.reward_cents, t.title
    into v_task
  from public.tasks t where t.id = p_task_id for update;
  if not found or v_task.parent_id is distinct from public.current_parent_id() then
    raise exception 'Auftrag nicht gefunden' using errcode = '42501';
  end if;

  if p_approve then
    -- Auch ohne Meldung des Kindes bestätigbar (z. B. vergessen anzutippen).
    if v_task.status not in ('open', 'submitted') then
      raise exception 'Dieser Auftrag kann nicht bestätigt werden' using errcode = 'P0001';
    end if;
    update public.tasks
    set status = 'approved', reviewed_at = now(), parent_note = nullif(trim(p_note), '')
    where id = p_task_id;
    if v_task.reward_cents > 0 then
      insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, reference_id, note, created_by)
      values (v_task.child_id, 'spend', v_task.reward_cents, 'task', v_task.id, left(v_task.title, 80), auth.uid());
    end if;
  else
    if v_task.status <> 'submitted' then
      raise exception 'Nur gemeldete Aufträge können abgelehnt werden' using errcode = 'P0001';
    end if;
    update public.tasks
    set status = 'rejected', reviewed_at = now(), parent_note = nullif(trim(p_note), '')
    where id = p_task_id;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Truhen
-- ---------------------------------------------------------------------------

-- Umbuchen zwischen den eigenen Truhen (zum Beispiel Bordkasse → Schatztruhe).
create or replace function public.move_between_pots(
  p_child_id uuid,
  p_from text,
  p_to text,
  p_amount_cents integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reference uuid := gen_random_uuid();
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;
  if p_from = p_to or p_from not in ('spend', 'save', 'give') or p_to not in ('spend', 'save', 'give') then
    raise exception 'Ungültige Truhen' using errcode = '22023';
  end if;
  if p_amount_cents is null or p_amount_cents <= 0 then
    raise exception 'Der Betrag muss größer als 0 sein' using errcode = '22023';
  end if;

  perform public.lock_child_for_booking(p_child_id);
  if public.pot_balance(p_child_id, p_from) < p_amount_cents then
    raise exception 'Nicht genug Guthaben in der Truhe' using errcode = 'P0001';
  end if;

  insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, reference_id, created_by) values
    (p_child_id, p_from, -p_amount_cents, 'transfer', v_reference, auth.uid()),
    (p_child_id, p_to, p_amount_cents, 'transfer', v_reference, auth.uid());
end;
$$;

-- Ausgabe aus der Bordkasse oder Geschenk aus der Glückstruhe eintragen.
create or replace function public.record_spending(
  p_child_id uuid,
  p_pot text,
  p_amount_cents integer,
  p_note text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;
  if p_pot not in ('spend', 'give') then
    raise exception 'Ausgaben nur aus Bordkasse oder Glückstruhe' using errcode = '22023';
  end if;
  if p_amount_cents is null or p_amount_cents <= 0 then
    raise exception 'Der Betrag muss größer als 0 sein' using errcode = '22023';
  end if;

  perform public.lock_child_for_booking(p_child_id);
  if public.pot_balance(p_child_id, p_pot) < p_amount_cents then
    raise exception 'Nicht genug Guthaben in der Truhe' using errcode = 'P0001';
  end if;

  insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, note, created_by)
  values (
    p_child_id, p_pot, -p_amount_cents,
    case when p_pot = 'spend' then 'purchase' else 'donation' end,
    nullif(left(trim(p_note), 80), ''), auth.uid()
  );
end;
$$;

-- Korrektur durch die Eltern (Eingang oder Ausgang), nie unter 0.
create or replace function public.book_manual(
  p_child_id uuid,
  p_pot text,
  p_amount_cents integer,
  p_note text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_parent_of_child(p_child_id) then
    raise exception 'Nur für Eltern dieses Kindes' using errcode = '42501';
  end if;
  if p_pot not in ('spend', 'save', 'give') or coalesce(p_amount_cents, 0) = 0 then
    raise exception 'Ungültige Buchung' using errcode = '22023';
  end if;

  perform public.lock_child_for_booking(p_child_id);
  if public.pot_balance(p_child_id, p_pot) + p_amount_cents < 0 then
    raise exception 'Nicht genug Guthaben in der Truhe' using errcode = 'P0001';
  end if;

  insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, note, created_by)
  values (p_child_id, p_pot, p_amount_cents, 'manual', nullif(left(trim(p_note), 80), ''), auth.uid());
end;
$$;

-- ---------------------------------------------------------------------------
-- Wunschschätze
-- ---------------------------------------------------------------------------

-- Wunschschatz einlösen: Betrag geht aus der Schatztruhe, der Wunsch ist erfüllt.
create or replace function public.redeem_savings_goal(p_goal_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_goal record;
begin
  select g.id, g.child_id, g.title, g.target_cents, g.reached_at
    into v_goal
  from public.savings_goals g where g.id = p_goal_id;
  if not found or not public.can_act_for_child(v_goal.child_id) then
    raise exception 'Wunschschatz nicht gefunden' using errcode = '42501';
  end if;
  if v_goal.reached_at is not null then
    raise exception 'Dieser Wunschschatz ist schon eingelöst' using errcode = 'P0001';
  end if;

  perform public.lock_child_for_booking(v_goal.child_id);
  if public.pot_balance(v_goal.child_id, 'save') < v_goal.target_cents then
    raise exception 'Nicht genug Guthaben in der Truhe' using errcode = 'P0001';
  end if;

  insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, reference_id, note, created_by)
  values (v_goal.child_id, 'save', -v_goal.target_cents, 'goal', v_goal.id, left(v_goal.title, 80), auth.uid());
  update public.savings_goals set reached_at = now() where id = v_goal.id;
end;
$$;

-- Offene Wunschschätze darf das Kind ändern und löschen. Erreicht wird ein
-- Wunschschatz nur über redeem_savings_goal().
create policy "Eltern und Kinder-Gerät ändern offene Wunschschätze"
  on public.savings_goals for update to authenticated
  using (public.can_act_for_child(child_id) and reached_at is null)
  with check (public.can_act_for_child(child_id) and reached_at is null);

create policy "Eltern und Kinder-Gerät löschen offene Wunschschätze"
  on public.savings_goals for delete to authenticated
  using (public.can_act_for_child(child_id) and reached_at is null);

-- ---------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------

alter table public.allowance_rules enable row level security;
alter table public.tasks enable row level security;
alter table public.ledger_entries enable row level security;

create policy "Eltern und Kinder-Gerät sehen die Heuer"
  on public.allowance_rules for select to authenticated
  using (public.can_act_for_child(child_id));

create policy "Eltern und Kinder-Gerät sehen Aufträge"
  on public.tasks for select to authenticated
  using (public.can_act_for_child(child_id));

-- Eltern legen Aufträge für ihre Kinder an. Status ändern nur submit_task() und review_task().
create policy "Eltern legen Aufträge an"
  on public.tasks for insert to authenticated
  with check (
    parent_id = public.current_parent_id()
    and public.is_parent_of_child(child_id)
    and status = 'open'
    and submitted_at is null
    and reviewed_at is null
  );

-- Bestätigte Aufträge bleiben als Beleg zur Buchung im Kassenbuch erhalten.
create policy "Eltern löschen nicht bestätigte Aufträge"
  on public.tasks for delete to authenticated
  using (parent_id = public.current_parent_id() and status <> 'approved');

create policy "Eltern und Kinder-Gerät sehen das Kassenbuch"
  on public.ledger_entries for select to authenticated
  using (public.can_act_for_child(child_id));

revoke execute on function
  public.set_allowance(uuid, integer, text, timestamptz),
  public.process_due_allowances(uuid),
  public.submit_task(uuid),
  public.review_task(uuid, boolean, text),
  public.move_between_pots(uuid, text, text, integer),
  public.record_spending(uuid, text, integer, text),
  public.book_manual(uuid, text, integer, text),
  public.redeem_savings_goal(uuid),
  public.pot_balances(uuid),
  public.lock_child_for_booking(uuid)
from public, anon;

grant execute on function
  public.set_allowance(uuid, integer, text, timestamptz),
  public.process_due_allowances(uuid),
  public.submit_task(uuid),
  public.review_task(uuid, boolean, text),
  public.move_between_pots(uuid, text, text, integer),
  public.record_spending(uuid, text, integer, text),
  public.book_manual(uuid, text, integer, text),
  public.redeem_savings_goal(uuid),
  public.pot_balances(uuid)
to authenticated;

-- Interne Hilfsfunktionen prüfen keine Rechte und sind deshalb nicht direkt
-- aufrufbar. Server-Funktionen nutzen sie weiter (sie laufen als Besitzer).
revoke execute on function
  public.pot_balance(uuid, text),
  public.lock_child_for_booking(uuid),
  public.station_done(uuid, uuid),
  public.island_unlocked(uuid, uuid),
  public.station_unlocked(uuid, uuid)
from public, anon, authenticated;

-- ===========================================================================
-- Migration 20261009000900_fortschrittssystem.sql
-- ===========================================================================

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

-- ===========================================================================
-- Migration 20261009001000_tauchgaenge.sql
-- ===========================================================================

-- Taleria, Schritt 7a: Tauchgänge (Ankerplätze) und Unterwasser-Sammlung
--
-- Enthält:
--   * collectibles, child_collectibles   Funde für die Unterwasser-Sammlung (nur Optik, nie kaufbar)
--   * submit_station()   Ankerplätze (stations.type = review_stop): Fragen der Stationen seit dem
--                        letzten Ankerplatz, erledigt nach dem Durchgang, kein Wind nötig, Fund
--   * child_stats()      zusätzlich Perlen und Funde
--   * next_encounter()   mit Übungsmodus, wenn die nächste Insel im Nebel liegt
--
-- Regeln aus CLAUDE.md, Abschnitt 8:
--   * Ankerplatz nach jeder zweiten Station, Pflicht für den Insel-Abschluss.
--   * 3 bis 4 Wiederholungsfragen zu den beiden Stationen davor (Perlentauchen: richtige
--     Antwort = Perle) und eine Anwendungsaufgabe im Wrack (wertet die App, ohne Punkte).
--   * Funde sind rein kosmetisch und nie kaufbar.
--   * Perlen = richtige Antworten im besten Tauchgang je Ankerplatz (station_progress.best_score).

-- ---------------------------------------------------------------------------
-- Unterwasser-Sammlung
-- ---------------------------------------------------------------------------

create table public.collectibles (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9_-]{2,60}$'),
  kind text not null check (kind in ('pearl', 'shell', 'wreck_item')),
  title text not null check (char_length(trim(title)) between 2 and 60),
  asset_key text not null check (asset_key ~ '^[a-z0-9_.-]{3,80}$'),
  -- Nur Optik, ändert nichts am Spiel.
  rarity text not null default 'common' check (rarity in ('common', 'rare')),
  -- Der Ankerplatz, an dem der Fund liegt.
  station_id uuid references public.stations (id) on delete cascade,
  sort_order integer not null default 0,
  status public.content_status not null default 'draft',
  publish_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index collectibles_station_idx on public.collectibles (station_id);

create trigger collectibles_set_updated_at before update on public.collectibles
  for each row execute function public.set_updated_at();

create table public.child_collectibles (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  collectible_id uuid not null references public.collectibles (id) on delete cascade,
  source_station_id uuid references public.stations (id) on delete set null,
  found_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint child_collectibles_once unique (child_id, collectible_id)
);

create index child_collectibles_child_idx on public.child_collectibles (child_id);

alter table public.collectibles enable row level security;
alter table public.child_collectibles enable row level security;

create policy "Sichtbare Funde lesen"
  on public.collectibles for select to authenticated
  using (public.is_content_visible(status, publish_at) or public.is_admin());

create policy "Editoren schreiben Funde"
  on public.collectibles for all to authenticated
  using (public.is_admin(array['owner', 'editor']))
  with check (public.is_admin(array['owner', 'editor']));

-- Gefunden wird nur über submit_station().
create policy "Eltern und Kinder-Gerät sehen die Sammlung"
  on public.child_collectibles for select to authenticated
  using (public.can_act_for_child(child_id));

-- ---------------------------------------------------------------------------
-- Station abgeben (ersetzt die Fassung aus Schritt 6a)
-- ---------------------------------------------------------------------------

-- Wie in Schritt 6a, dazu Ankerplätze (review_stop):
--   * Antworten: content.dive.questions Fragen (Standard 4) aus den Stationen der
--     Insel zwischen dem letzten Ankerplatz und diesem (ohne Prüfung).
--   * Erledigt nach dem Durchgang, Fehler kosten nichts. Kein Wind nötig.
--   * Antwort zusätzlich: find (neuer Fund oder null).
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
  v_is_dive boolean;
  v_prev_dive integer := -1;
  v_find jsonb;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  select s.id, s.island_id, s.type, s.xp_reward, s.content, s.status, s.publish_at, s.is_required, s.sort_order
    into v_station
  from public.stations s where s.id = p_station_id;
  if not found then
    raise exception 'Station nicht gefunden' using errcode = 'P0002';
  end if;

  v_is_dive := v_station.type = 'review_stop';

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

  -- Tempo: neue Pflichtstationen brauchen Wind. Ankerplätze nicht: Sie
  -- gehören zu den beiden Stationen davor (CLAUDE.md Abschnitt 8).
  v_first := not public.station_done(p_child_id, p_station_id);
  if v_first and v_station.is_required and not v_is_dive then
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
  elsif v_is_dive then
    -- Tauchgang: Fragen der Stationen seit dem letzten Ankerplatz, erledigt nach dem Durchgang.
    v_expected := coalesce((v_station.content -> 'dive' ->> 'questions')::integer, 4);
    v_pass := 0;
    select coalesce(max(s.sort_order), -1)
      into v_prev_dive
    from public.stations s
    where s.island_id = v_island.id and s.type = 'review_stop' and s.sort_order < v_station.sort_order;
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
      q.station_id = p_station_id or v_is_dive as own,
      q.id is not null
        and public.is_content_visible(q.status, null)
        and (
          q.station_id = p_station_id
          or (
            v_is_dive
            and exists (
              select 1
              from public.stations s
              where s.id = q.station_id
                and s.island_id = v_island.id
                and s.type not in ('exam', 'review_stop')
                and s.sort_order > v_prev_dive
                and s.sort_order < v_station.sort_order
                and public.is_content_visible(s.status, s.publish_at)
            )
          )
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

  -- Tauchgang: Fund für die Unterwasser-Sammlung (genau einmal).
  if v_is_dive and v_passed then
    with found as (
      insert into public.child_collectibles (child_id, collectible_id, source_station_id)
      select p_child_id, c.id, p_station_id
      from public.collectibles c
      where c.station_id = p_station_id and public.is_content_visible(c.status, c.publish_at)
      on conflict on constraint child_collectibles_once do nothing
      returning collectible_id
    )
    select jsonb_build_object('id', c.id, 'slug', c.slug, 'kind', c.kind, 'title', c.title, 'asset_key', c.asset_key)
      into v_find
    from found f
    join public.collectibles c on c.id = f.collectible_id
    limit 1;
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
    'wind_left', case when v_station.is_required and not v_is_dive then public.refresh_wind(p_child_id) end,
    'find', v_find
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Statistik mit Perlen und Funden (ersetzt die Fassung aus Schritt 6a)
-- ---------------------------------------------------------------------------

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
    'pearls', (
      select coalesce(sum(p.best_score), 0)
      from public.station_progress p
      join public.stations s on s.id = p.station_id
      where p.child_id = p_child_id and p.status = 'done' and s.type = 'review_stop'
    ),
    'finds', (select count(*) from public.child_collectibles c where c.child_id = p_child_id),
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
-- Begegnung auf See, auch zum Üben (Nebel voraus)
-- ---------------------------------------------------------------------------

drop function public.next_encounter(uuid);

create function public.next_encounter(p_child_id uuid, p_practice boolean default false)
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
  -- Übung (Nebel voraus): auch ohne fällige Wiederholungen, mit den nächsten Terminen.
  if v_due = 0 and not p_practice then
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

revoke execute on function public.next_encounter(uuid, boolean) from public, anon;
grant execute on function public.next_encounter(uuid, boolean) to authenticated;

-- ===========================================================================
-- Migration 20261009001100_leuchtturm.sql
-- ===========================================================================

-- Taleria, Schritt 8a: Leuchtturm (Lernstand für Eltern)
--
-- Enthält:
--   * learning_status()   Lernstand pro Station aus dem Wiederholungsplan, nur für Eltern
--   * child_stats()       zusätzlich last_active_at (zuletzt an Bord)
--
-- Lernstand (CLAUDE.md Abschnitt 8: „was das Kind sicher kann und wo es noch wackelt“),
-- je Frage aus question_reviews:
--   * wackelt:  die letzte Antwort war falsch
--   * sicher:   richtig und mindestens einmal zum Termin richtig wiederholt (correct_streak >= 2)
--   * geübt:    richtig, aber noch nicht wiederholt
-- Prüfungsfragen zählen zu der Station, die sie abdecken (covers_station). Wie daraus ein
-- Urteil pro Thema wird, entscheidet die App (lib/domain/learning_status.dart).

-- ---------------------------------------------------------------------------
-- Lernstand pro Station
-- ---------------------------------------------------------------------------

create or replace function public.learning_status(p_child_id uuid)
returns table (
  island_id uuid,
  station_id uuid,
  answered integer,
  secure integer,
  learning integer,
  shaky integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_parent_of_child(p_child_id) then
    raise exception 'Nur für Eltern' using errcode = '42501';
  end if;

  return query
  with answers as (
    select
      r.last_correct,
      r.correct_streak,
      case
        when own.type = 'exam' then (
          select topic.id
          from public.stations topic
          where topic.island_id = own.island_id
            and topic.type not in ('exam', 'review_stop')
            and (topic.content ->> 'number')::integer = q.covers_station
          limit 1
        )
        else own.id
      end as topic_id
    from public.question_reviews r
    join public.quiz_questions q on q.id = r.question_id
    join public.stations own on own.id = q.station_id
    where r.child_id = p_child_id
      and public.question_visible(q.id)
  )
  select
    s.island_id,
    s.id,
    count(*)::integer,
    count(*) filter (where a.last_correct and a.correct_streak >= 2)::integer,
    count(*) filter (where a.last_correct and a.correct_streak < 2)::integer,
    count(*) filter (where not a.last_correct)::integer
  from answers a
  join public.stations s on s.id = a.topic_id
  group by s.island_id, s.id;
end;
$$;

revoke execute on function public.learning_status(uuid) from public, anon;
grant execute on function public.learning_status(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Statistik mit „zuletzt an Bord“ (ersetzt die Fassung aus Schritt 7a)
-- ---------------------------------------------------------------------------

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
    'pearls', (
      select coalesce(sum(p.best_score), 0)
      from public.station_progress p
      join public.stations s on s.id = p.station_id
      where p.child_id = p_child_id and p.status = 'done' and s.type = 'review_stop'
    ),
    'finds', (select count(*) from public.child_collectibles c where c.child_id = p_child_id),
    'last_active_at', (
      select max(t) from (
        select max(p.updated_at) as t from public.station_progress p where p.child_id = p_child_id
        union all
        select max(r.finished_at) from public.encounter_runs r where r.child_id = p_child_id
        union all
        select max(q.last_answered_at) from public.question_reviews q where q.child_id = p_child_id
      ) x
    ),
    'pace', jsonb_build_object(
      'free', v_per_week is null,
      'stations_per_week', v_per_week,
      'wind', v_wind,
      'next_release', case when v_wind = 0 then public.next_release_day(p_child_id) end
    )
  );
end;
$$;

-- ===========================================================================
-- Liste der Supabase CLI: diese Migrationen sind eingespielt
-- ===========================================================================

create schema if not exists supabase_migrations;
create table if not exists supabase_migrations.schema_migrations (version text not null primary key);
alter table supabase_migrations.schema_migrations add column if not exists statements text[];
alter table supabase_migrations.schema_migrations add column if not exists name text;
insert into supabase_migrations.schema_migrations (version, name) values
  ('20261009000100', 'grundlagen_und_admin'),
  ('20261009000200', 'inhalte'),
  ('20261009000300', 'konten'),
  ('20261009000400', 'intro'),
  ('20261009000500', 'titel_in_datenbank'),
  ('20261009000600', 'fortschritt'),
  ('20261009000700', 'inhalte_erweitert'),
  ('20261009000800', 'budget'),
  ('20261009000900', 'fortschrittssystem'),
  ('20261009001000', 'tauchgaenge'),
  ('20261009001100', 'leuchtturm')
on conflict (version) do nothing;

commit;
