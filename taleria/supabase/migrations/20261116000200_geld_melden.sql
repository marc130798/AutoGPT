-- Geld melden (Marcs Wunsch am 16.11.2026): Das Kind trägt ein, dass es Geld
-- bekommen hat (zum Beispiel von Oma), die Eltern bestätigen oder lehnen ab.
-- Erst die Bestätigung bucht ins freie Geld (Regel aus CLAUDE.md: Gutschriften
-- nur durch Eltern). Mehrfach ausführbar.

create table if not exists public.money_reports (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  amount_cents integer not null check (amount_cents between 1 and 100000),
  note text check (note is null or char_length(note) <= 60),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists money_reports_child_idx on public.money_reports (child_id, created_at desc);

drop trigger if exists money_reports_set_updated_at on public.money_reports;
create trigger money_reports_set_updated_at before update on public.money_reports
  for each row execute function public.set_updated_at();

alter table public.money_reports enable row level security;

drop policy if exists "Eltern und Kinder-Gerät sehen gemeldetes Geld" on public.money_reports;
create policy "Eltern und Kinder-Gerät sehen gemeldetes Geld"
  on public.money_reports for select to authenticated
  using (public.can_act_for_child(child_id));

-- Neue Buchungsart „gift“ (Geld bekommen) im Kassenbuch.
alter table public.ledger_entries drop constraint if exists ledger_entries_entry_type_check;
alter table public.ledger_entries add constraint ledger_entries_entry_type_check
  check (entry_type in ('allowance', 'task', 'transfer', 'manual', 'goal', 'purchase', 'donation', 'learning', 'gift'));

create unique index if not exists ledger_entries_gift_once
  on public.ledger_entries (reference_id)
  where entry_type = 'gift';

-- Kind (oder Eltern auf dem Eltern-Gerät) meldet Geld. Höchstens 5 warten gleichzeitig.
create or replace function public.report_money(p_child_id uuid, p_amount_cents integer, p_note text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kein Zugriff auf dieses Kind' using errcode = '42501';
  end if;
  if p_amount_cents is null or p_amount_cents < 1 or p_amount_cents > 100000 then
    raise exception 'Betrag nicht erlaubt' using errcode = '22023';
  end if;
  if (select count(*) from public.money_reports where child_id = p_child_id and status = 'pending') >= 5 then
    raise exception 'Zu viele Meldungen warten' using errcode = 'P0001';
  end if;
  insert into public.money_reports (child_id, amount_cents, note)
  values (p_child_id, p_amount_cents, nullif(left(trim(coalesce(p_note, '')), 60), ''))
  returning id into v_id;
  return v_id;
end;
$$;

-- Eltern bestätigen (bucht ins freie Geld, genau einmal) oder lehnen ab.
create or replace function public.review_money_report(p_report_id uuid, p_approve boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_report public.money_reports;
begin
  select * into v_report from public.money_reports where id = p_report_id for update;
  if v_report.id is null or not public.is_parent_of_child(v_report.child_id) then
    raise exception 'Nur Eltern bestätigen gemeldetes Geld' using errcode = '42501';
  end if;
  if v_report.status <> 'pending' then
    raise exception 'Schon entschieden' using errcode = 'P0001';
  end if;
  update public.money_reports
    set status = case when p_approve then 'approved' else 'rejected' end, reviewed_at = now()
    where id = p_report_id;
  if p_approve then
    insert into public.ledger_entries (child_id, pot, amount_cents, entry_type, reference_id, note, created_by)
    values (v_report.child_id, 'spend', v_report.amount_cents, 'gift', v_report.id, v_report.note, auth.uid())
    on conflict (reference_id) where entry_type = 'gift' do nothing;
  end if;
end;
$$;

revoke execute on function
  public.report_money(uuid, integer, text),
  public.review_money_report(uuid, boolean)
from public, anon;
grant execute on function
  public.report_money(uuid, integer, text),
  public.review_money_report(uuid, boolean)
to authenticated;
