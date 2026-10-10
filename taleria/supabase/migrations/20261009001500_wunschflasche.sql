-- Taleria: Wunschflasche (CLAUDE.md Abschnitt 8, eingeführt auf der Wunschinsel, Station 3)
--
-- Enthält:
--   * wish_bottles           Wünsche, die das Kind erst eine Weile treiben lässt
--   * create_wish_bottle()   Wunsch in die Flasche stecken (klein: 1 Tag, groß: 7 Tage)
--   * decide_wish_bottle()   nach der Wartezeit: loslassen oder Wunschschatz daraus machen
--   * wish_bottle_status()   freigeschaltet? wie viele Flaschen sind angespült?
--   * open_wish_bottles()    offene Flaschen; ob sie angespült sind, sagt der Server (seine Uhr gilt)
--
-- Regeln:
--   * Nach 1 Tag (kleiner Wunsch) oder 7 Tagen (großer Wunsch) fragt die App nach.
--     Gezählt wird in deutscher Zeit ab dem nächsten Tagesbeginn. Keine Push-Nachricht:
--     Die App fragt, wenn das Kind sie öffnet (CLAUDE.md Abschnitt 10).
--   * Loslassen geht jederzeit, ein Wunschschatz erst nach der Wartezeit.
--   * Freigeschaltet mit der Station, deren Spiel die Wunschflasche ist; danach dauerhaft
--     in der Schatztruhe.

create table public.wish_bottles (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  -- Wie bei Wunschschätzen, damit daraus einer werden kann.
  title text not null check (char_length(trim(title)) between 2 and 40),
  -- Optional, virtueller Betrag in Cent (bis 10.000 €).
  price_cents integer check (price_cents is null or price_cents between 1 and 1000000),
  is_big boolean not null default false,
  remind_at timestamptz not null,
  decision text not null default 'open' check (decision in ('open', 'dropped', 'converted')),
  savings_goal_id uuid references public.savings_goals (id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint wish_bottles_decided check ((decision = 'open') = (decided_at is null))
);

create index wish_bottles_child_idx on public.wish_bottles (child_id, decision);

create trigger wish_bottles_set_updated_at before update on public.wish_bottles
  for each row execute function public.set_updated_at();

alter table public.wish_bottles enable row level security;

-- Lesen: Kind und Eltern. Schreiben nur über die Funktionen unten.
create policy "Kind und Eltern sehen die Wunschflaschen"
  on public.wish_bottles for select to authenticated
  using (public.can_act_for_child(child_id));

-- ---------------------------------------------------------------------------
-- Wunsch in die Flasche
-- ---------------------------------------------------------------------------

create or replace function public.create_wish_bottle(
  p_child_id uuid,
  p_title text,
  p_price_cents integer default null,
  p_big boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;
  if (
    select count(*) from public.wish_bottles b where b.child_id = p_child_id and b.decision = 'open'
  ) >= 10 then
    raise exception 'Höchstens 10 Wunschflaschen treiben gleichzeitig' using errcode = 'P0001';
  end if;

  insert into public.wish_bottles (child_id, title, price_cents, is_big, remind_at)
  values (
    p_child_id,
    trim(p_title),
    p_price_cents,
    coalesce(p_big, false),
    public.day_start(public.taleria_today() + case when coalesce(p_big, false) then 7 else 1 end)
  )
  returning id into v_id;
  return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Entscheiden: loslassen oder Wunschschatz
-- ---------------------------------------------------------------------------

-- p_keep = false: loslassen (jederzeit). p_keep = true: Wunschschatz daraus machen,
-- erst nach der Wartezeit. [p_target_cents] ersetzt den Preis (nötig, wenn keiner da ist).
-- Gibt die id des neuen Wunschschatzes zurück (sonst null).
create or replace function public.decide_wish_bottle(
  p_bottle_id uuid,
  p_keep boolean,
  p_target_cents integer default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_bottle record;
  v_target integer;
  v_goal uuid;
begin
  select b.* into v_bottle from public.wish_bottles b where b.id = p_bottle_id for update;
  if v_bottle.id is null or not public.can_act_for_child(v_bottle.child_id) then
    raise exception 'Wunschflasche nicht gefunden' using errcode = '42501';
  end if;
  if v_bottle.decision <> 'open' then
    raise exception 'Über diese Wunschflasche ist schon entschieden' using errcode = 'P0001';
  end if;

  if not coalesce(p_keep, false) then
    update public.wish_bottles set decision = 'dropped', decided_at = now() where id = p_bottle_id;
    return null;
  end if;

  if v_bottle.remind_at > now() then
    raise exception 'Die Wunschflasche treibt noch' using errcode = 'P0001';
  end if;
  v_target := coalesce(p_target_cents, v_bottle.price_cents);
  if v_target is null or v_target < 100 or v_target > 1000000 then
    raise exception 'Ein Wunschschatz braucht einen Preis zwischen 1 und 10.000 Euro' using errcode = '22023';
  end if;

  insert into public.savings_goals (child_id, title, target_cents)
  values (v_bottle.child_id, v_bottle.title, v_target)
  returning id into v_goal;
  update public.wish_bottles
  set decision = 'converted', decided_at = now(), savings_goal_id = v_goal
  where id = p_bottle_id;
  return v_goal;
end;
$$;

-- ---------------------------------------------------------------------------
-- Stand für Startseite und Schatztruhe
-- ---------------------------------------------------------------------------

-- {"unlocked": true, "due": 1}
create or replace function public.wish_bottle_status(p_child_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'unlocked',
    exists (select 1 from public.wish_bottles b where b.child_id = p_child_id)
      or exists (
        select 1 from public.station_progress p
        join public.stations s on s.id = p.station_id
        where p.child_id = p_child_id and p.status = 'done' and s.content -> 'game' ->> 'type' = 'wish_bottle'
      ),
    'due', (
      select count(*) from public.wish_bottles b
      where b.child_id = p_child_id and b.decision = 'open' and b.remind_at <= now()
    )
  );
end;
$$;

-- Offene Flaschen, neueste zuerst. due = angespült (die Wartezeit ist vorbei).
create or replace function public.open_wish_bottles(p_child_id uuid)
returns table (
  id uuid,
  title text,
  price_cents integer,
  is_big boolean,
  remind_at timestamptz,
  due boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;
  return query
  select b.id, b.title, b.price_cents, b.is_big, b.remind_at, b.remind_at <= now()
  from public.wish_bottles b
  where b.child_id = p_child_id and b.decision = 'open'
  order by b.created_at desc;
end;
$$;

revoke execute on function
  public.open_wish_bottles(uuid),
  public.create_wish_bottle(uuid, text, integer, boolean),
  public.decide_wish_bottle(uuid, boolean, integer),
  public.wish_bottle_status(uuid)
from public, anon;

grant execute on function
  public.open_wish_bottles(uuid),
  public.create_wish_bottle(uuid, text, integer, boolean),
  public.decide_wish_bottle(uuid, boolean, integer),
  public.wish_bottle_status(uuid)
to authenticated;
