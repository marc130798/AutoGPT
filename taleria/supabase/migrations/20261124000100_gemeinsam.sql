-- Taleria: „Gemeinsam“ (Marcs Wunsch am 24.11.2026): Kind und Eltern lernen zusammen.
--
-- Zwei Arten pro Insel:
-- - explain: „Erklär's deinen Eltern“, sobald die Insel geschafft ist. Das Kind
--   erklärt 3 Punkte (islands.content.together.explain).
-- - adventure: Crew-Abenteuer, sobald die Insel offen ist (der Auftrag fürs echte
--   Leben, islands.content.real_life_task). Kind und Eltern machen es gemeinsam.
--
-- Damit niemand schummelt: Die Eltern rufen im Leuchtturm einen Code ab
-- (crew_code, nur Eltern), das Kind gibt ihn ein (redeem_crew_code). Der Code
-- hat 4 Ziffern, gilt 24 Stunden, nur für dieses Kind und diese Aufgabe, und
-- nach 5 falschen Versuchen nicht mehr (dann einen neuen abrufen). Gespeichert
-- wird nur die Prüfsumme.
--
-- Belohnung, genau einmal je Insel und Art: 30 Seemeilen (explain) oder
-- 50 Seemeilen (adventure) und ein Crew-Stern (eine Zeile in crew_done).
-- Die Crew-Sterne schalten in der Werft besondere Teile frei (die App zählt sie).
--
-- Mehrfach ausführbar.

create table if not exists public.crew_done (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  island_id uuid not null references public.islands (id) on delete cascade,
  kind text not null check (kind in ('explain', 'adventure')),
  done_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint crew_done_once unique (child_id, island_id, kind)
);

create table if not exists public.crew_codes (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  island_id uuid not null references public.islands (id) on delete cascade,
  kind text not null check (kind in ('explain', 'adventure')),
  code_hash text not null,
  expires_at timestamptz not null,
  failed_attempts smallint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint crew_codes_one unique (child_id, island_id, kind)
);

alter table public.crew_done enable row level security;
alter table public.crew_codes enable row level security;

drop policy if exists "Eltern und Kinder-Gerät sehen Crew-Sterne" on public.crew_done;
create policy "Eltern und Kinder-Gerät sehen Crew-Sterne"
  on public.crew_done for select to authenticated
  using (public.can_act_for_child(child_id));
-- crew_codes: keine Lese-Regel. Codes gibt es nur über crew_code().

-- Darf das Kind diese Aufgabe gerade machen? (Intern, für Apps gesperrt.)
create or replace function public.crew_task_open(p_child_id uuid, p_island_id uuid, p_kind text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case p_kind
    when 'explain' then exists (
      select 1 from public.island_completions c where c.child_id = p_child_id and c.island_id = p_island_id)
    when 'adventure' then public.island_unlocked(p_child_id, p_island_id)
      or exists (select 1 from public.island_completions c where c.child_id = p_child_id and c.island_id = p_island_id)
    else false
  end;
$$;

revoke execute on function public.crew_task_open(uuid, uuid, text) from public, anon, authenticated;

-- Eltern: neuen Code abrufen (ersetzt einen alten). Antwort: die 4 Ziffern.
create or replace function public.crew_code(p_child_id uuid, p_island_id uuid, p_kind text)
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_code text;
begin
  if not public.is_parent_of_child(p_child_id) then
    raise exception 'Nur Eltern rufen den Code ab' using errcode = '42501';
  end if;
  if p_kind not in ('explain', 'adventure') then
    raise exception 'Unbekannte Art' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.crew_done d
    where d.child_id = p_child_id and d.island_id = p_island_id and d.kind = p_kind
  ) then
    raise exception 'Schon geschafft' using errcode = 'P0001';
  end if;
  if not public.crew_task_open(p_child_id, p_island_id, p_kind) then
    raise exception 'Noch nicht dran' using errcode = 'P0001';
  end if;

  v_code := lpad((('x' || encode(extensions.gen_random_bytes(4), 'hex'))::bit(32)::bigint % 10000)::text, 4, '0');
  insert into public.crew_codes (child_id, island_id, kind, code_hash, expires_at, failed_attempts)
  values (
    p_child_id, p_island_id, p_kind,
    encode(extensions.digest(p_child_id::text || '/' || v_code, 'sha256'), 'hex'),
    now() + interval '24 hours', 0
  )
  on conflict on constraint crew_codes_one do update set
    code_hash = excluded.code_hash, expires_at = excluded.expires_at, failed_attempts = 0, updated_at = now();
  return v_code;
end;
$$;

revoke execute on function public.crew_code(uuid, uuid, text) from public, anon;
grant execute on function public.crew_code(uuid, uuid, text) to authenticated;

-- Kind (oder Eltern auf dem Eltern-Gerät): Code eingeben.
-- Antwort: {"status": "ok" | "wrong" | "expired" | "locked" | "none" | "done",
--           "xp_awarded": 30, "stars": 3, "tries_left": 4, "rank_up": "matrose"}
create or replace function public.redeem_crew_code(p_child_id uuid, p_island_id uuid, p_kind text, p_code text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_row public.crew_codes;
  v_xp integer;
  v_rank_before text;
  v_rank_after text;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;
  if exists (
    select 1 from public.crew_done d
    where d.child_id = p_child_id and d.island_id = p_island_id and d.kind = p_kind
  ) then
    return jsonb_build_object('status', 'done');
  end if;

  select * into v_row from public.crew_codes c
  where c.child_id = p_child_id and c.island_id = p_island_id and c.kind = p_kind
  for update;
  if v_row.id is null then
    return jsonb_build_object('status', 'none');
  end if;
  if v_row.expires_at < now() then
    return jsonb_build_object('status', 'expired');
  end if;
  if v_row.failed_attempts >= 5 then
    return jsonb_build_object('status', 'locked');
  end if;

  if v_row.code_hash <> encode(
    extensions.digest(p_child_id::text || '/' || regexp_replace(coalesce(p_code, ''), '\s', '', 'g'), 'sha256'), 'hex'
  ) then
    update public.crew_codes set failed_attempts = failed_attempts + 1, updated_at = now() where id = v_row.id;
    return jsonb_build_object(
      'status', case when v_row.failed_attempts + 1 >= 5 then 'locked' else 'wrong' end,
      'tries_left', greatest(0, 4 - v_row.failed_attempts)
    );
  end if;

  v_rank_before := public.child_rank(p_child_id);
  delete from public.crew_codes where id = v_row.id;
  insert into public.crew_done (child_id, island_id, kind) values (p_child_id, p_island_id, p_kind)
  on conflict on constraint crew_done_once do nothing;
  v_xp := case p_kind when 'explain' then 30 else 50 end;
  insert into public.xp_events (child_id, source_type, source_id, amount)
  values (p_child_id, 'crew_' || p_kind, p_island_id, v_xp)
  on conflict on constraint xp_events_once do nothing;
  perform public.mark_activity(p_child_id);
  v_rank_after := public.child_rank(p_child_id);

  return jsonb_build_object(
    'status', 'ok',
    'xp_awarded', v_xp,
    'stars', (select count(*) from public.crew_done d where d.child_id = p_child_id),
    'rank_up', case when v_rank_after is distinct from v_rank_before then v_rank_after end
  );
end;
$$;

revoke execute on function public.redeem_crew_code(uuid, uuid, text, text) from public, anon;
grant execute on function public.redeem_crew_code(uuid, uuid, text, text) to authenticated;
