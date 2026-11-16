-- Lern-Belohnung (Marcs Wunsch am 16.11.2026): Eltern können freiwillig
-- festlegen, dass ihr Kind für jede neu geschaffte Station und/oder jede
-- abgeschlossene Insel einen virtuellen Betrag in die Schatztruhe bekommt
-- (frei zum Ausgeben). Am Anfang ist alles aus (0 Cent).
--
-- Regeln:
-- - Station: nur beim ersten Schaffen einer Pflichtstation (Quiz, Spiel,
--   Übung). Nicht für Tauchgänge (Ankerplätze), Stopps auf See, das Intro
--   und die Abschlussprüfung (dafür gibt es die Insel-Belohnung).
-- - Insel: wenn die Insel abgeschlossen ist (Prüfung bestanden), genau einmal.
-- - Wiederholen bringt nie Geld. Der Server bucht selbst, das Kind kann
--   nichts buchen. Mehrfach ausführbar.

create table if not exists public.learning_rewards (
  child_id uuid primary key references public.children (id) on delete cascade,
  station_cents integer not null default 0 check (station_cents between 0 and 10000),
  island_cents integer not null default 0 check (island_cents between 0 and 100000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists learning_rewards_set_updated_at on public.learning_rewards;
create trigger learning_rewards_set_updated_at before update on public.learning_rewards
  for each row execute function public.set_updated_at();

alter table public.learning_rewards enable row level security;

drop policy if exists "Eltern und Kinder-Gerät sehen die Lern-Belohnung" on public.learning_rewards;
create policy "Eltern und Kinder-Gerät sehen die Lern-Belohnung"
  on public.learning_rewards for select to authenticated
  using (public.can_act_for_child(child_id));

-- Neue Buchungsart „learning“ im Kassenbuch.
alter table public.ledger_entries drop constraint if exists ledger_entries_entry_type_check;
alter table public.ledger_entries add constraint ledger_entries_entry_type_check
  check (entry_type in ('allowance', 'task', 'transfer', 'manual', 'goal', 'purchase', 'donation', 'learning'));

-- Jede Station und jede Insel bringt einem Kind höchstens einmal Geld.
create unique index if not exists ledger_entries_learning_once
  on public.ledger_entries (child_id, reference_id)
  where entry_type = 'learning';

-- Eltern legen die Beträge fest (0 = aus).
create or replace function public.set_learning_rewards(p_child_id uuid, p_station_cents integer, p_island_cents integer)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_parent_of_child(p_child_id) then
    raise exception 'Nur Eltern legen die Lern-Belohnung fest' using errcode = '42501';
  end if;
  if p_station_cents is null or p_station_cents < 0 or p_station_cents > 10000
     or p_island_cents is null or p_island_cents < 0 or p_island_cents > 100000 then
    raise exception 'Betrag nicht erlaubt' using errcode = '22023';
  end if;
  insert into public.learning_rewards (child_id, station_cents, island_cents)
  values (p_child_id, p_station_cents, p_island_cents)
  on conflict (child_id) do update
    set station_cents = excluded.station_cents, island_cents = excluded.island_cents;
end;
$$;

-- Bucht die Belohnung für eine neu geschaffte Station.
create or replace function public.learning_reward_for_station()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cents integer;
  v_station public.stations;
begin
  if new.completed_at is null or (tg_op = 'UPDATE' and old.completed_at is not null) then
    return new;
  end if;
  select station_cents into v_cents from public.learning_rewards where child_id = new.child_id;
  if coalesce(v_cents, 0) <= 0 then
    return new;
  end if;
  select * into v_station from public.stations where id = new.station_id;
  if not v_station.is_required
     or v_station.type in ('review_stop', 'sea_stop', 'exam')
     or coalesce(v_station.content ->> 'kind', '') = 'onboarding' then
    return new;
  end if;
  insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, reference_id, note)
  values (
    new.child_id, 'spend', v_cents, 'learning', new.station_id,
    left(coalesce(v_station.content ->> 'title', 'Station'), 80)
  )
  on conflict (child_id, reference_id) where entry_type = 'learning' do nothing;
  return new;
end;
$$;

drop trigger if exists station_progress_learning_reward on public.station_progress;
create trigger station_progress_learning_reward
  after insert or update of completed_at on public.station_progress
  for each row execute function public.learning_reward_for_station();

-- Bucht die Belohnung für eine abgeschlossene Insel.
create or replace function public.learning_reward_for_island()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cents integer;
begin
  select island_cents into v_cents from public.learning_rewards where child_id = new.child_id;
  if coalesce(v_cents, 0) <= 0 then
    return new;
  end if;
  insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, reference_id, note)
  select new.child_id, 'spend', v_cents, 'learning', i.id, left(i.title, 80)
  from public.islands i
  where i.id = new.island_id
  on conflict (child_id, reference_id) where entry_type = 'learning' do nothing;
  return new;
end;
$$;

drop trigger if exists island_completions_learning_reward on public.island_completions;
create trigger island_completions_learning_reward
  after insert on public.island_completions
  for each row execute function public.learning_reward_for_island();

revoke execute on function public.set_learning_rewards(uuid, integer, integer) from public, anon;
grant execute on function public.set_learning_rewards(uuid, integer, integer) to authenticated;
revoke execute on function
  public.learning_reward_for_station(),
  public.learning_reward_for_island()
from public, anon, authenticated;
