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
