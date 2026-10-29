-- Eine Schatztruhe statt drei Truhen (entschieden mit Marc am 29.10.2026).
--
-- Kinder kamen mit Bordkasse, Schatztruhe und Glückstruhe durcheinander. Jetzt
-- hat jedes Kind eine Schatztruhe mit zwei Teilen:
--   - frei (pot = 'spend'): davon darf es sich etwas kaufen,
--   - zurückgelegt (pot = 'save'): Geld, das für einen bestimmten Wunschschatz
--     beiseitegelegt ist (ledger_entries.savings_goal_id).
-- Die Glückstruhe ('give') gibt es nicht mehr. Ihr Guthaben und Geld in der
-- Schatztruhe ohne Wunschschatz kommen zum freien Geld.
-- Mehrfach ausführbar.

alter table public.ledger_entries add column if not exists savings_goal_id uuid;

-- Kein Fremdschlüssel: Das Kassenbuch wird nie geändert, auch nicht beim Löschen
-- eines Wunschschatzes. Beim Löschen bucht ein Trigger das Geld zurück (unten).
create index if not exists ledger_entries_goal_idx
  on public.ledger_entries (savings_goal_id) where savings_goal_id is not null;

comment on column public.ledger_entries.savings_goal_id is
  'Für welchen Wunschschatz das Geld zurückgelegt ist (nur bei pot = save).';

-- Zurückgelegtes Geld eines Wunschschatzes. Intern, ohne Rechteprüfung.
create or replace function public.goal_saved(p_goal_id uuid)
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum(e.amount_cents), 0)
  from public.ledger_entries e
  where e.savings_goal_id = p_goal_id and e.pot = 'save';
$$;

-- Zurückgelegtes Geld je Wunschschatz. Nur für Eltern und das Kinder-Gerät.
create or replace function public.savings_goal_balances(p_child_id uuid)
returns table (goal_id uuid, saved_cents bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select g.id, public.goal_saved(g.id)
  from public.savings_goals g
  where g.child_id = p_child_id and public.can_act_for_child(p_child_id);
$$;

-- Geld für einen Wunschschatz zurücklegen (positiv) oder wieder frei machen
-- (negativ). Zurückgelegt wird höchstens, was zum Wunschschatz noch fehlt.
create or replace function public.move_goal_savings(p_goal_id uuid, p_amount_cents integer)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_goal record;
  v_saved bigint;
  v_reference uuid := gen_random_uuid();
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
  if p_amount_cents is null or p_amount_cents = 0 then
    raise exception 'Der Betrag muss größer als 0 sein' using errcode = '22023';
  end if;

  perform public.lock_child_for_booking(v_goal.child_id);
  v_saved := public.goal_saved(v_goal.id);
  if p_amount_cents > 0 then
    if public.pot_balance(v_goal.child_id, 'spend') < p_amount_cents then
      raise exception 'Nicht genug Guthaben in der Truhe' using errcode = 'P0001';
    end if;
    if v_saved + p_amount_cents > v_goal.target_cents then
      raise exception 'Mehr braucht dieser Wunschschatz nicht' using errcode = 'P0001';
    end if;
  elsif v_saved + p_amount_cents < 0 then
    raise exception 'Nicht genug Guthaben in der Truhe' using errcode = 'P0001';
  end if;

  insert into public.ledger_entries
    (child_id, pot, amount_cents, entry_type, reference_id, savings_goal_id, note, created_by)
  values
    (v_goal.child_id, 'spend', -p_amount_cents, 'transfer', v_reference, null, left(v_goal.title, 80), auth.uid()),
    (v_goal.child_id, 'save', p_amount_cents, 'transfer', v_reference, v_goal.id, left(v_goal.title, 80), auth.uid());
end;
$$;

-- Einlösen: Das zurückgelegte Geld dieses Wunschschatzes wird ausgegeben.
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
  if public.goal_saved(v_goal.id) < v_goal.target_cents then
    raise exception 'Nicht genug Guthaben in der Truhe' using errcode = 'P0001';
  end if;

  insert into public.ledger_entries
    (child_id, pot, amount_cents, entry_type, reference_id, savings_goal_id, note, created_by)
  values (v_goal.child_id, 'save', -v_goal.target_cents, 'goal', v_goal.id, v_goal.id, left(v_goal.title, 80), auth.uid());
  update public.savings_goals set reached_at = now() where id = v_goal.id;
end;
$$;

-- Wird ein offener Wunschschatz gelöscht, ist sein Geld wieder frei.
-- Beim Löschen des ganzen Kinder-Profils gibt es nichts zurückzubuchen.
create or replace function public.free_goal_savings()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_saved bigint;
  v_reference uuid := gen_random_uuid();
begin
  if not exists (select 1 from public.children c where c.id = old.child_id) then
    return old;
  end if;
  v_saved := public.goal_saved(old.id);
  if v_saved > 0 then
    insert into public.ledger_entries
      (child_id, pot, amount_cents, entry_type, reference_id, savings_goal_id, note, created_by)
    values
      (old.child_id, 'save', -v_saved, 'transfer', v_reference, old.id, left(old.title, 80), auth.uid()),
      (old.child_id, 'spend', v_saved, 'transfer', v_reference, null, left(old.title, 80), auth.uid());
  end if;
  return old;
end;
$$;

drop trigger if exists savings_goals_free_money on public.savings_goals;
create trigger savings_goals_free_money
  before delete on public.savings_goals
  for each row execute function public.free_goal_savings();

-- Ausgeben nur noch vom freien Geld.
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
  if p_pot is distinct from 'spend' then
    raise exception 'Ausgaben nur vom freien Geld' using errcode = '22023';
  end if;
  if p_amount_cents is null or p_amount_cents <= 0 then
    raise exception 'Der Betrag muss größer als 0 sein' using errcode = '22023';
  end if;

  perform public.lock_child_for_booking(p_child_id);
  if public.pot_balance(p_child_id, 'spend') < p_amount_cents then
    raise exception 'Nicht genug Guthaben in der Truhe' using errcode = 'P0001';
  end if;

  insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, note, created_by)
  values (p_child_id, 'spend', -p_amount_cents, 'purchase', nullif(left(trim(p_note), 80), ''), auth.uid());
end;
$$;

-- Korrekturen der Eltern nur noch beim freien Geld.
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
  if p_pot is distinct from 'spend' or coalesce(p_amount_cents, 0) = 0 then
    raise exception 'Ungültige Buchung' using errcode = '22023';
  end if;

  perform public.lock_child_for_booking(p_child_id);
  if public.pot_balance(p_child_id, 'spend') + p_amount_cents < 0 then
    raise exception 'Nicht genug Guthaben in der Truhe' using errcode = 'P0001';
  end if;

  insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, note, created_by)
  values (p_child_id, 'spend', p_amount_cents, 'manual', nullif(left(trim(p_note), 80), ''), auth.uid());
end;
$$;

-- Freies und zurückgelegtes Geld. Die Glückstruhe gibt es nicht mehr.
create or replace function public.pot_balances(p_child_id uuid)
returns table (pot text, balance_cents bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select p.pot, public.pot_balance(p_child_id, p.pot)
  from (values ('spend'), ('save')) as p (pot)
  where public.can_act_for_child(p_child_id);
$$;

-- Umbuchen zwischen Truhen gibt es nicht mehr (zurücklegen geht nur für einen Wunschschatz).
revoke execute on function public.move_between_pots(uuid, text, text, integer) from public, anon, authenticated;

-- Bestehendes Geld zusammenführen: Glückstruhe und Schatztruhe ohne Wunschschatz
-- werden frei. Läuft beim zweiten Mal ins Leere, weil dann nichts mehr übrig ist.
do $$
declare
  r record;
  v_reference uuid;
begin
  for r in
    select e.child_id, e.pot, sum(e.amount_cents) as cents
    from public.ledger_entries e
    where e.pot = 'give' or (e.pot = 'save' and e.savings_goal_id is null)
    group by e.child_id, e.pot
    having sum(e.amount_cents) > 0
  loop
    v_reference := gen_random_uuid();
    insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, reference_id, note)
    values
      (r.child_id, r.pot, -r.cents, 'transfer', v_reference, 'Eine Schatztruhe'),
      (r.child_id, 'spend', r.cents, 'transfer', v_reference, 'Eine Schatztruhe');
  end loop;
end;
$$;

revoke execute on function
  public.savings_goal_balances(uuid),
  public.move_goal_savings(uuid, integer)
from public, anon;

grant execute on function
  public.savings_goal_balances(uuid),
  public.move_goal_savings(uuid, integer)
to authenticated;

revoke execute on function
  public.goal_saved(uuid),
  public.free_goal_savings()
from public, anon, authenticated;
