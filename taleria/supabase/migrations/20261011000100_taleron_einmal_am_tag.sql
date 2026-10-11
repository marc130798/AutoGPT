-- Taleria: Meister Taleron kommt höchstens einmal am Tag (Marcs Test am
-- 11.10.2026).
--
-- Bisher tauchte eine Begegnung auf See auf, solange Wiederholungen fällig
-- waren. Sie stellt aber nur 3 Fragen; bei vielen fälligen Fragen kam
-- Meister Taleron nach seinen Fragen sofort wieder und blieb auf der Karte.
-- Jetzt gilt: Nach einer Begegnung (encounter_runs von heute) liefert
-- next_encounter() bis morgen nichts mehr. Die Übung bei Nebel voraus
-- (p_practice = true) bleibt jederzeit möglich. Seemeilen gab es für
-- Begegnungen ohnehin nur einmal am Tag.
--
-- Wie in 20261009001000_tauchgaenge.sql, nur mit der neuen Prüfung.
-- Mehrfach ausführbar.

create or replace function public.next_encounter(p_child_id uuid, p_practice boolean default false)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_due integer;
  v_encounter record;
  v_questions uuid[];
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  v_due := public.due_review_count(p_child_id);
  -- Übung (Nebel voraus): auch ohne fällige Wiederholungen, mit den nächsten Terminen.
  if v_due = 0 and not p_practice then
    return null;
  end if;

  -- Eine Kontrollfahrt am Tag: Nach ihren Fragen lässt die Figur das Schiff
  -- passieren und taucht ab. Offene Wiederholungen warten bis morgen.
  if not p_practice and exists (
    select 1 from public.encounter_runs er
    where er.child_id = p_child_id
      and er.finished_at >= public.day_start(public.taleria_today())
  ) then
    return null;
  end if;

  select e.id, e.slug, e.type, e.title, e.asset_key, e.question_count, e.xp_reward, e.content
    into v_encounter
  from public.encounters e
  where public.is_content_visible(e.status, e.publish_at)
    and (
      e.after_island_id is null
      or exists (
        select 1 from public.island_completions c
        where c.child_id = p_child_id and c.island_id = e.after_island_id
      )
    )
  order by random()
  limit 1;
  if not found then
    return null;
  end if;

  select array_agg(x.question_id order by x.rank_due, x.due_at)
    into v_questions
  from (
    select r.question_id, r.due_at, case when r.due_at <= now() then 0 else 1 end as rank_due
    from public.question_reviews r
    where r.child_id = p_child_id and public.question_visible(r.question_id)
    order by case when r.due_at <= now() then 0 else 1 end, r.due_at, random()
    limit v_encounter.question_count
  ) x;

  if coalesce(cardinality(v_questions), 0) < v_encounter.question_count then
    return null;
  end if;

  return jsonb_build_object(
    'encounter', jsonb_build_object(
      'id', v_encounter.id,
      'slug', v_encounter.slug,
      'type', v_encounter.type,
      'title', v_encounter.title,
      'asset_key', v_encounter.asset_key,
      'question_count', v_encounter.question_count,
      'xp_reward', v_encounter.xp_reward,
      'content', v_encounter.content
    ),
    'question_ids', to_jsonb(v_questions),
    'first_meeting', not exists (
      select 1 from public.encounter_runs er
      where er.child_id = p_child_id and er.encounter_id = v_encounter.id
    ),
    'due_count', v_due
  );
end;
$$;

revoke execute on function public.next_encounter(uuid, boolean) from public, anon;
grant execute on function public.next_encounter(uuid, boolean) to authenticated;
