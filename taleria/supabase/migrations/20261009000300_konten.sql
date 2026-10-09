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
