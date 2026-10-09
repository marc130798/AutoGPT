-- Taleria, Schritt 4a: Namen von Inseln und Expeditionen stehen in der Datenbank
--
-- Entscheidung mit Marc (09.10.2026): Inhaltstexte kommen aus der Datenbank,
-- nicht aus den Übersetzungsdateien der App. So braucht eine neue Insel oder
-- Expedition kein App-Update (CLAUDE.md, Abschnitt 10).

alter table public.islands rename column title_key to title;
alter table public.islands
  add constraint islands_title_check check (char_length(trim(title)) between 1 and 60);

alter table public.expeditions rename column title_key to title;
alter table public.expeditions
  add constraint expeditions_title_check check (char_length(trim(title)) between 1 and 60);
