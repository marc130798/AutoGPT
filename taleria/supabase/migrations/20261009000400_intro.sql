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
