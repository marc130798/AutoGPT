-- Taleria, Schritt 4c: Inhalte erweitert
--
--   * islands.content         Lernziel, Ankunftsszene, Orden, Auftrag fürs echte Leben, Zugang
--   * quiz_questions.covers_station
--                             Zu welcher Station eine Prüfungsfrage gehört. Die App wählt
--                             damit mindestens eine Frage pro Station aus (INSELN.md).

alter table public.islands
  add column content jsonb not null default '{}'::jsonb,
  add constraint islands_content_check check (jsonb_typeof(content) = 'object');

alter table public.quiz_questions
  add column covers_station smallint check (covers_station between 1 and 20);
