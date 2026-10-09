-- Supabase gibt anon und authenticated standardmäßig Rechte auf public.
-- Ob sie etwas sehen, entscheidet dann allein die Row Level Security.
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to anon, authenticated, service_role;
grant all on all functions in schema public to anon, authenticated, service_role;
