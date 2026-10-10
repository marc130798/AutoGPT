-- Taleria, Schritt 10a: Admin-Grundversion
--
-- Enthält:
--   * Admin- und Eltern-Konten bleiben getrennt (CLAUDE.md Abschnitt 6)
--   * grant_admin_role()       Admin-Konto anlegen, nur im SQL Editor von Supabase
--   * admin_whoami()           Rolle und Zwei-Faktor-Stand der eigenen Anmeldung
--   * admin_overview()         Familien, Kinder, aktive Kinder, Abos (owner)
--   * admin_content_stats()    Inhalte: Status, Fortschritt pro Station, schwierigste Fragen (owner, editor)
--   * admin_find_family()      Eltern-Konto per E-Mail suchen (owner, support)
--   * admin_set_premium()      Abo von Hand vergeben oder entfernen (owner)
--   * admin_delete_family()    Eltern-Konto mit allen Daten löschen (owner)
--   * admin_audit_recent()     letzte Einträge im Audit-Log (owner)
--   * snapshot_published_content()   frühere Fassung nur bei einer echten Änderung
--   * guard_station_rules()    erneuter Import veröffentlichter Inseln möglich
--
-- Regeln aus CLAUDE.md Abschnitt 10:
--   * Admin-Rechte nur mit Zwei-Faktor-Anmeldung (is_admin prüft aal2).
--   * Rollen: owner (alles), editor (nur Inhalte), support (Konten einsehen im Supportfall).
--   * Statistiken nur als zusammengefasste Zahlen, keine Einzelprofile von Kindern.
--   * Jeder Zugriff auf ein Familienkonto braucht einen Grund und landet im admin_audit_log.

-- ---------------------------------------------------------------------------
-- Admin- und Eltern-Konten getrennt
-- ---------------------------------------------------------------------------

-- Admins nutzen nur den Adminbereich, nie die Eltern-App. Ein Konto ist
-- deshalb entweder Admin oder Eltern, nie beides.
create or replace function public.guard_admin_parent_separation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_table_name = 'admins' then
    if exists (select 1 from public.parents p where p.user_id = new.user_id) then
      raise exception 'Dieses Konto ist ein Eltern-Konto. Für den Adminbereich braucht es ein eigenes Konto.'
        using errcode = 'P0001';
    end if;
  elsif exists (select 1 from public.admins a where a.user_id = new.user_id) then
    raise exception 'Admin-Konten können kein Eltern-Konto haben' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger admins_not_parent
  before insert or update of user_id on public.admins
  for each row execute function public.guard_admin_parent_separation();

create trigger parents_not_admin
  before insert or update of user_id on public.parents
  for each row execute function public.guard_admin_parent_separation();

-- ---------------------------------------------------------------------------
-- Admin-Konto anlegen (nur im SQL Editor, nie aus einer App)
-- ---------------------------------------------------------------------------

-- Das Konto muss vorher unter Authentication → Users angelegt sein.
-- Aufruf im SQL Editor: select public.grant_admin_role('name@beispiel.de', 'owner');
create or replace function public.grant_admin_role(p_email text, p_role text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid;
begin
  if p_role is null or p_role not in ('owner', 'editor', 'support') then
    raise exception 'Rolle muss owner, editor oder support sein' using errcode = '22023';
  end if;
  select u.id into v_user from auth.users u where lower(u.email) = lower(trim(p_email));
  if v_user is null then
    raise exception 'Kein Konto mit dieser E-Mail. Bitte zuerst unter Authentication → Users anlegen.'
      using errcode = 'P0001';
  end if;
  insert into public.admins (user_id, role) values (v_user, p_role)
  on conflict (user_id) do update set role = excluded.role;
end;
$$;

-- ---------------------------------------------------------------------------
-- Interne Hilfen
-- ---------------------------------------------------------------------------

-- Bricht ab, wenn die Anmeldung kein Admin mit einer der Rollen ist (mit Zwei-Faktor).
create or replace function public.require_admin(p_roles text[])
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin(p_roles) then
    raise exception 'Nur für Admins mit Zwei-Faktor-Anmeldung' using errcode = '42501';
  end if;
  return public.current_admin_id();
end;
$$;

-- Schreibt einen Eintrag ins Audit-Log. Ohne Grund geht nichts.
create or replace function public.write_admin_audit(
  p_admin_id uuid,
  p_action text,
  p_target_type text,
  p_target_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if char_length(trim(coalesce(p_reason, ''))) < 5 then
    raise exception 'Bitte einen Grund angeben (mindestens 5 Zeichen)' using errcode = '22023';
  end if;
  insert into public.admin_audit_log (admin_id, action, target_type, target_id, reason)
  values (p_admin_id, p_action, p_target_type, p_target_id, trim(p_reason));
end;
$$;

-- Zuletzt an Bord, für alle Kinder (gleiche Regel wie child_stats: Station,
-- Begegnung oder Wiederholung).
create or replace function public.children_last_active()
returns table (child_id uuid, last_active_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select x.child_id, max(x.t)
  from (
    select p.child_id, max(p.updated_at) as t from public.station_progress p group by p.child_id
    union all
    select r.child_id, max(r.finished_at) from public.encounter_runs r group by r.child_id
    union all
    select q.child_id, max(q.last_answered_at) from public.question_reviews q group by q.child_id
  ) x
  group by x.child_id;
$$;

-- ---------------------------------------------------------------------------
-- Wer bin ich?
-- ---------------------------------------------------------------------------

-- null, wenn die Anmeldung kein Admin ist. Sonst Rolle und ob die
-- Zwei-Faktor-Anmeldung schon erfolgt ist (erst dann gelten die Admin-Rechte).
create or replace function public.admin_whoami()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'role', a.role,
    'mfa', coalesce(auth.jwt() ->> 'aal', '') = 'aal2',
    'email', u.email
  )
  from public.admins a
  left join auth.users u on u.id = a.user_id
  where a.user_id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- Statistik: Übersicht (nur owner)
-- ---------------------------------------------------------------------------

create or replace function public.admin_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  perform public.require_admin(array['owner']);

  with last_active as (select * from public.children_last_active()),
  valid_premium as (
    select e.parent_id, e.source
    from public.entitlements e
    where e.entitlement = 'premium' and (e.valid_until is null or e.valid_until > now())
  )
  select jsonb_build_object(
    'families', (select count(*) from public.parents),
    'families_new_7d', (select count(*) from public.parents p where p.created_at >= now() - interval '7 days'),
    'families_new_28d', (select count(*) from public.parents p where p.created_at >= now() - interval '28 days'),
    'children', (select count(*) from public.children),
    'children_onboarded', (select count(*) from public.children c where c.onboarding_completed_at is not null),
    'children_active_7d', (select count(*) from last_active l where l.last_active_at >= now() - interval '7 days'),
    'children_active_28d', (select count(*) from last_active l where l.last_active_at >= now() - interval '28 days'),
    'premium_families', (select count(distinct v.parent_id) from valid_premium v),
    'premium_revenuecat', (select count(distinct v.parent_id) from valid_premium v where v.source = 'revenuecat'),
    'premium_manual', (select count(distinct v.parent_id) from valid_premium v where v.source = 'manual'),
    'premium_test', (select count(distinct v.parent_id) from valid_premium v where v.source = 'test'),
    'children_with_allowance', (select count(*) from public.allowance_rules),
    'tasks_approved_28d', (
      select count(*) from public.tasks t
      where t.status = 'approved' and t.reviewed_at >= now() - interval '28 days'
    ),
    'generated_at', now()
  ) into v_result;
  return v_result;
end;
$$;

-- ---------------------------------------------------------------------------
-- Statistik: Inhalte (owner, editor)
-- ---------------------------------------------------------------------------

-- Pro Insel: Status, Zahl der Stationen und Fragen, wie viele Kinder sie
-- erreicht und abgeschlossen haben, und pro Station, wie viele Kinder sie
-- geschafft haben (der Rückgang von Station zu Station zeigt, wo Kinder aufhören).
-- Dazu die 10 schwierigsten und 10 leichtesten Fragen (ab 5 Antworten).
create or replace function public.admin_content_stats(p_stage smallint default 1)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_onboarded bigint;
  v_islands jsonb;
  v_hardest jsonb;
  v_easiest jsonb;
begin
  perform public.require_admin(array['owner', 'editor']);

  select count(*) into v_onboarded
  from public.children c
  where c.onboarding_completed_at is not null and c.stage = p_stage;

  select coalesce(jsonb_agg(row_data order by route_order, sort_order), '[]'::jsonb) into v_islands
  from (
    select
      case i.route_type when 'main' then 0 when 'side' then 1 else 2 end as route_order,
      i.sort_order,
      jsonb_build_object(
        'id', i.id,
        'slug', i.slug,
        'title', i.title,
        'sort_order', i.sort_order,
        'route_type', i.route_type,
        'status', i.status,
        'publish_at', i.publish_at,
        'access', coalesce(i.content ->> 'access', 'free'),
        'questions', (
          select count(*) from public.quiz_questions q
          join public.stations s on s.id = q.station_id
          where s.island_id = i.id
        ),
        'reached', (
          select count(distinct p.child_id) from public.station_progress p
          join public.stations s on s.id = p.station_id
          where s.island_id = i.id and p.status = 'done'
        ),
        'completed', (select count(*) from public.island_completions ic where ic.island_id = i.id),
        'stations', (
          select coalesce(jsonb_agg(jsonb_build_object(
            'id', s.id,
            'number', (s.content ->> 'number')::integer,
            'title', s.content ->> 'title',
            'type', s.type,
            'status', s.status,
            'is_required', s.is_required,
            'questions', (select count(*) from public.quiz_questions q where q.station_id = s.id),
            'done', case
              when s.content ->> 'kind' = 'onboarding' then v_onboarded
              else (
                select count(*) from public.station_progress p
                where p.station_id = s.id and p.status = 'done'
              )
            end
          ) order by s.sort_order), '[]'::jsonb)
          from public.stations s
          where s.island_id = i.id
        )
      ) as row_data
    from public.islands i
    where i.stage = p_stage
  ) x;

  with answers as (
    select
      q.id,
      q.question,
      i.title as island,
      (s.content ->> 'number')::integer as station_number,
      s.type as station_type,
      sum(r.times_answered) as answered,
      sum(r.times_wrong) as wrong
    from public.question_reviews r
    join public.quiz_questions q on q.id = r.question_id
    join public.stations s on s.id = q.station_id
    join public.islands i on i.id = s.island_id
    where i.stage = p_stage
    group by q.id, q.question, i.title, s.id
    having sum(r.times_answered) >= 5
  ),
  rated as (
    select a.*, round(a.wrong::numeric / a.answered, 2) as wrong_rate from answers a
  )
  select
    (select coalesce(jsonb_agg(to_jsonb(h) order by h.wrong_rate desc, h.answered desc), '[]'::jsonb)
     from (select * from rated order by wrong_rate desc, answered desc limit 10) h),
    (select coalesce(jsonb_agg(to_jsonb(e) order by e.wrong_rate, e.answered desc), '[]'::jsonb)
     from (select * from rated order by wrong_rate, answered desc limit 10) e)
  into v_hardest, v_easiest;

  return jsonb_build_object(
    'stage', p_stage,
    'children_onboarded', v_onboarded,
    'islands', v_islands,
    'hardest_questions', v_hardest,
    'easiest_questions', v_easiest,
    'generated_at', now()
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Support (immer mit Grund im Audit-Log)
-- ---------------------------------------------------------------------------

-- Sucht ein Eltern-Konto per E-Mail. Auch eine Suche ohne Treffer landet im Audit-Log.
-- Liefert nur, was der Support braucht: keine Spitznamen, keine Lerndaten.
create or replace function public.admin_find_family(p_email text, p_reason text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := public.require_admin(array['owner', 'support']);
  v_parent record;
begin
  select p.id, p.created_at, p.consent_at, p.consent_version, p.marketing_consent_at, u.email
    into v_parent
  from auth.users u
  join public.parents p on p.user_id = u.id
  where lower(u.email) = lower(trim(coalesce(p_email, '')));

  perform public.write_admin_audit(
    v_admin,
    case when v_parent.id is null then 'family.search' else 'family.view' end,
    'parent',
    v_parent.id,
    p_reason
  );

  if v_parent.id is null then
    return null;
  end if;

  return jsonb_build_object(
    'parent_id', v_parent.id,
    'email', v_parent.email,
    'created_at', v_parent.created_at,
    'consent_at', v_parent.consent_at,
    'consent_version', v_parent.consent_version,
    'marketing_consent', v_parent.marketing_consent_at is not null,
    'children', (select count(*) from public.children c where c.parent_id = v_parent.id),
    'last_active_at', (
      select max(l.last_active_at) from public.children_last_active() l
      join public.children c on c.id = l.child_id
      where c.parent_id = v_parent.id
    ),
    'premium', public.has_premium(v_parent.id),
    'entitlements', (
      select coalesce(jsonb_agg(jsonb_build_object('source', e.source, 'valid_until', e.valid_until)
        order by e.source), '[]'::jsonb)
      from public.entitlements e
      where e.parent_id = v_parent.id
    )
  );
end;
$$;

-- Abo von Hand vergeben (zum Beispiel für Beta-Familien) oder entfernen.
-- p_valid_until = null: ohne Ablauf. Käufe aus dem Store (revenuecat) bleiben unberührt.
create or replace function public.admin_set_premium(
  p_parent_id uuid,
  p_active boolean,
  p_valid_until timestamptz,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := public.require_admin(array['owner']);
begin
  if not exists (select 1 from public.parents p where p.id = p_parent_id) then
    raise exception 'Eltern-Konto nicht gefunden' using errcode = 'P0002';
  end if;

  if p_active then
    if p_valid_until is not null and p_valid_until <= now() then
      raise exception 'Das Datum liegt in der Vergangenheit' using errcode = '22023';
    end if;
    perform public.write_admin_audit(v_admin, 'premium.grant', 'parent', p_parent_id, p_reason);
    insert into public.entitlements (parent_id, entitlement, source, valid_until)
    values (p_parent_id, 'premium', 'manual', p_valid_until)
    on conflict on constraint entitlements_once do update set valid_until = excluded.valid_until;
  else
    perform public.write_admin_audit(v_admin, 'premium.revoke', 'parent', p_parent_id, p_reason);
    delete from public.entitlements e where e.parent_id = p_parent_id and e.source = 'manual';
  end if;

  return jsonb_build_object('premium', public.has_premium(p_parent_id));
end;
$$;

-- Löscht ein Eltern-Konto mit allen Kindern, Daten und Kinder-Geräten
-- (zum Beispiel auf Wunsch per E-Mail). Der Eintrag im Audit-Log bleibt.
create or replace function public.admin_delete_family(p_parent_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := public.require_admin(array['owner']);
  v_user uuid;
begin
  select p.user_id into v_user from public.parents p where p.id = p_parent_id;
  if v_user is null then
    raise exception 'Eltern-Konto nicht gefunden' using errcode = 'P0002';
  end if;

  perform public.write_admin_audit(v_admin, 'family.delete', 'parent', p_parent_id, p_reason);

  delete from auth.users u
  where u.id in (
    select d.user_id
    from public.child_devices d
    join public.children c on c.id = d.child_id
    where c.parent_id = p_parent_id
  );
  -- Löscht über "on delete cascade" auch parents, children und alles, was daran hängt.
  delete from auth.users u where u.id = v_user;
end;
$$;

-- ---------------------------------------------------------------------------
-- Audit-Log lesen (nur owner)
-- ---------------------------------------------------------------------------

create or replace function public.admin_audit_recent(p_limit integer default 100)
returns table (
  created_at timestamptz,
  admin_email text,
  admin_role text,
  action text,
  target_type text,
  target_id uuid,
  reason text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_admin(array['owner']);
  return query
  select l.created_at, u.email::text, a.role, l.action, l.target_type, l.target_id, l.reason
  from public.admin_audit_log l
  join public.admins a on a.id = l.admin_id
  left join auth.users u on u.id = a.user_id
  order by l.created_at desc
  limit least(greatest(coalesce(p_limit, 100), 1), 500);
end;
$$;

-- ---------------------------------------------------------------------------
-- Frühere Fassungen nur bei echter Änderung sichern
-- ---------------------------------------------------------------------------

-- Ein erneuter Import derselben Inhalte erzeugt keine neuen Fassungen.
create or replace function public.snapshot_published_content()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.status = 'published'
     and (tg_op = 'DELETE' or (to_jsonb(old) - 'updated_at') is distinct from (to_jsonb(new) - 'updated_at')) then
    insert into public.content_versions (entity_type, entity_id, snapshot, created_by)
    values (tg_table_name, old.id, to_jsonb(old), auth.uid());
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Import veröffentlichter Inseln (ersetzt die Fassung aus Schritt 1)
-- ---------------------------------------------------------------------------

-- Postgres ruft BEFORE-INSERT-Trigger auch bei "insert … on conflict do update" auf.
-- Ohne diese Ausnahme ließe sich eine veröffentlichte Insel nie erneut importieren.
create or replace function public.guard_station_rules()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    -- Trifft ein Insert auf eine vorhandene Station (Import mit "on conflict"),
    -- wird daraus eine Änderung. Die prüft der Zweig für UPDATE.
    if new.is_required
       and public.island_is_published(new.island_id)
       and not exists (select 1 from public.stations s where s.id = new.id) then
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

-- ---------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------

-- Nur im SQL Editor (Datenbank-Besitzer), nie aus einer App.
revoke execute on function public.grant_admin_role(text, text) from public, anon, authenticated;

-- Interne Hilfen ohne eigene Rechteprüfung.
revoke execute on function
  public.require_admin(text[]),
  public.write_admin_audit(uuid, text, text, uuid, text),
  public.children_last_active()
from public, anon, authenticated;

-- Admin-Funktionen prüfen Rolle und Zwei-Faktor selbst.
revoke execute on function
  public.admin_whoami(),
  public.admin_overview(),
  public.admin_content_stats(smallint),
  public.admin_find_family(text, text),
  public.admin_set_premium(uuid, boolean, timestamptz, text),
  public.admin_delete_family(uuid, text),
  public.admin_audit_recent(integer)
from public, anon;

grant execute on function
  public.admin_whoami(),
  public.admin_overview(),
  public.admin_content_stats(smallint),
  public.admin_find_family(text, text),
  public.admin_set_premium(uuid, boolean, timestamptz, text),
  public.admin_delete_family(uuid, text),
  public.admin_audit_recent(integer)
to authenticated;
