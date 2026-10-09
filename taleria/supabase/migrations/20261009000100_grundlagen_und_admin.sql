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
