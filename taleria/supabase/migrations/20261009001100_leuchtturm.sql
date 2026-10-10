-- Taleria, Schritt 8a: Leuchtturm (Lernstand für Eltern)
--
-- Enthält:
--   * learning_status()   Lernstand pro Station aus dem Wiederholungsplan, nur für Eltern
--   * child_stats()       zusätzlich last_active_at (zuletzt an Bord)
--
-- Lernstand (CLAUDE.md Abschnitt 8: „was das Kind sicher kann und wo es noch wackelt“),
-- je Frage aus question_reviews:
--   * wackelt:  die letzte Antwort war falsch
--   * sicher:   richtig und mindestens einmal zum Termin richtig wiederholt (correct_streak >= 2)
--   * geübt:    richtig, aber noch nicht wiederholt
-- Prüfungsfragen zählen zu der Station, die sie abdecken (covers_station). Wie daraus ein
-- Urteil pro Thema wird, entscheidet die App (lib/domain/learning_status.dart).

-- ---------------------------------------------------------------------------
-- Lernstand pro Station
-- ---------------------------------------------------------------------------

create or replace function public.learning_status(p_child_id uuid)
returns table (
  island_id uuid,
  station_id uuid,
  answered integer,
  secure integer,
  learning integer,
  shaky integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_parent_of_child(p_child_id) then
    raise exception 'Nur für Eltern' using errcode = '42501';
  end if;

  return query
  with answers as (
    select
      r.last_correct,
      r.correct_streak,
      case
        when own.type = 'exam' then (
          select topic.id
          from public.stations topic
          where topic.island_id = own.island_id
            and topic.type not in ('exam', 'review_stop')
            and (topic.content ->> 'number')::integer = q.covers_station
          limit 1
        )
        else own.id
      end as topic_id
    from public.question_reviews r
    join public.quiz_questions q on q.id = r.question_id
    join public.stations own on own.id = q.station_id
    where r.child_id = p_child_id
      and public.question_visible(q.id)
  )
  select
    s.island_id,
    s.id,
    count(*)::integer,
    count(*) filter (where a.last_correct and a.correct_streak >= 2)::integer,
    count(*) filter (where a.last_correct and a.correct_streak < 2)::integer,
    count(*) filter (where not a.last_correct)::integer
  from answers a
  join public.stations s on s.id = a.topic_id
  group by s.island_id, s.id;
end;
$$;

revoke execute on function public.learning_status(uuid) from public, anon;
grant execute on function public.learning_status(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Statistik mit „zuletzt an Bord“ (ersetzt die Fassung aus Schritt 7a)
-- ---------------------------------------------------------------------------

create or replace function public.child_stats(p_child_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_xp bigint;
  v_rank record;
  v_next record;
  v_per_week smallint;
  v_wind smallint;
begin
  if not public.can_act_for_child(p_child_id) then
    raise exception 'Kinder-Profil nicht gefunden' using errcode = '42501';
  end if;

  v_xp := public.child_xp(p_child_id);
  select r.code, r.sort_order, r.min_xp into v_rank
  from public.ranks r where r.code = public.child_rank(p_child_id);
  select r.code, r.min_xp, r.requires_certificate into v_next
  from public.ranks r
  where r.sort_order > coalesce(v_rank.sort_order, 0)
  order by r.sort_order
  limit 1;

  select c.stations_per_week into v_per_week from public.children c where c.id = p_child_id;
  v_wind := public.refresh_wind(p_child_id);

  return jsonb_build_object(
    'xp', v_xp,
    'rank', v_rank.code,
    'rank_min_xp', v_rank.min_xp,
    'next_rank', v_next.code,
    'next_rank_xp', case when v_next.requires_certificate then null else v_next.min_xp end,
    'next_rank_needs_certificate', coalesce(v_next.requires_certificate, false),
    'streak_weeks', public.current_streak(p_child_id),
    'streak_paused', coalesce((select s.paused from public.child_streaks s where s.child_id = p_child_id), false),
    'badge_count', (select count(*) from public.child_badges b where b.child_id = p_child_id),
    'reviews_due', public.due_review_count(p_child_id),
    'pearls', (
      select coalesce(sum(p.best_score), 0)
      from public.station_progress p
      join public.stations s on s.id = p.station_id
      where p.child_id = p_child_id and p.status = 'done' and s.type = 'review_stop'
    ),
    'finds', (select count(*) from public.child_collectibles c where c.child_id = p_child_id),
    'last_active_at', (
      select max(t) from (
        select max(p.updated_at) as t from public.station_progress p where p.child_id = p_child_id
        union all
        select max(r.finished_at) from public.encounter_runs r where r.child_id = p_child_id
        union all
        select max(q.last_answered_at) from public.question_reviews q where q.child_id = p_child_id
      ) x
    ),
    'pace', jsonb_build_object(
      'free', v_per_week is null,
      'stations_per_week', v_per_week,
      'wind', v_wind,
      'next_release', case when v_wind = 0 then public.next_release_day(p_child_id) end
    )
  );
end;
$$;
