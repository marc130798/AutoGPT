-- Taleria: Rang-Namen für Mädchen und Jungen
--
-- Das Kind wählt in der Einführung, wie seine Ränge heißen:
--   junge     Schiffsjunge, Matrose, Bootsmann, Steuermann, Kapitän
--   maedchen  Schiffsmädchen, Matrosin, Bootsfrau, Steuerfrau, Kapitänin
-- null = noch nicht gewählt (die App fragt dann einmal auf der Startseite).
-- Kein Geschlecht, nur die Wahl des Kindes, wie es genannt werden möchte.
-- Ändern dürfen das Kinder-Gerät und die Eltern, wie beim Avatar über
-- update_child_look(). Die Ränge selbst (Tabelle ranks) bleiben gleich.
--
-- Die Datei lässt sich gefahrlos mehrfach ausführen (zum Beispiel im SQL Editor
-- eines Testprojekts, das schon eingerichtet ist).

alter table public.children
  add column if not exists rank_form text;

do $$
begin
  alter table public.children
    add constraint children_rank_form_check check (rank_form in ('junge', 'maedchen'));
exception
  when duplicate_object then null;
end;
$$;

-- Neue Fassung mit p_rank_form. Die alte (drei Werte) wird entfernt, damit
-- Aufrufe eindeutig bleiben.
drop function if exists public.update_child_look(uuid, jsonb, text);

-- Avatar, Schiffsname und/oder Form der Rang-Namen setzen. null = unverändert lassen.
create or replace function public.update_child_look(
  p_child_id uuid,
  p_avatar jsonb default null,
  p_ship_name text default null,
  p_rank_form text default null
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
  update public.children
  set avatar = coalesce(p_avatar, avatar),
      ship_name = coalesce(nullif(trim(p_ship_name), ''), ship_name),
      rank_form = coalesce(p_rank_form, rank_form)
  where id = p_child_id;
end;
$$;

revoke execute on function public.update_child_look(uuid, jsonb, text, text) from public, anon;
grant execute on function public.update_child_look(uuid, jsonb, text, text) to authenticated;
