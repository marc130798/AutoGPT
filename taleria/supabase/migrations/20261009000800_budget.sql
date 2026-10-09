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
