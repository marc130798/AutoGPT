-- Taleria: Fragen für Einsteiger mit ganzen Zahlen (mit Marc entschieden am
-- 11.10.2026).
--
-- Pro Kind gibt es die Einstellung „Einsteiger“ oder „Fortgeschritten“
-- (children.level_setting). Einsteiger rechnen nur mit ganzen Euro oder
-- ganzen Cent, Fortgeschrittene auch mit Komma (3,50 €). Jede Frage mit
-- Kommazahl bekommt dafür eine Zwillingsfrage ohne Komma. Die App zeigt sie
-- Einsteigern statt der normalen Frage.
--
-- beginner: {"question": "…", "answers": ["…", "…", "…"], "correct_index": 0,
--            "explanation": "…"} oder null. Die richtige Antwort steht an
-- derselben Stelle wie in der normalen Frage, damit die Auswertung auf dem
-- Server gleich bleibt.
--
-- Mehrfach ausführbar.

alter table public.quiz_questions add column if not exists beginner jsonb;

alter table public.quiz_questions drop constraint if exists quiz_questions_beginner_check;
alter table public.quiz_questions add constraint quiz_questions_beginner_check check (
  beginner is null or (
    jsonb_typeof(beginner) = 'object'
    and jsonb_typeof(beginner -> 'answers') = 'array'
    and jsonb_array_length(beginner -> 'answers') = jsonb_array_length(answers)
    and (beginner ->> 'correct_index')::int = correct_index
    and length(trim(coalesce(beginner ->> 'question', ''))) > 0
  )
);

comment on column public.quiz_questions.beginner is
  'Zwillingsfrage mit ganzen Zahlen für Einsteiger (children.level_setting = beginner), sonst null.';
