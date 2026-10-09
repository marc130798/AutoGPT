-- Hilfsfunktionen für die Datenbank-Tests (nur lokal, tool/db_test.sh).

set client_min_messages = warning;

-- ---------------------------------------------------------------------------
-- Testhilfen
-- ---------------------------------------------------------------------------

create schema test_helpers;
grant usage on schema test_helpers to authenticated, anon;

-- Meldet sich als Nutzer an (wie ein Supabase-JWT). aal2 = Zwei-Faktor.
create function test_helpers.login(p_user uuid, p_aal text default 'aal1', p_anonymous boolean default false)
returns void language plpgsql as $$
begin
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', p_user, 'role', 'authenticated', 'aal', p_aal, 'is_anonymous', p_anonymous)::text,
    false
  );
  execute 'set role authenticated';
end;
$$;

create function test_helpers.logout() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', false);
end;
$$;

-- Meldet sich ohne Sitzung an (Rolle anon).
create function test_helpers.login_anon() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role": "anon"}', false);
  execute 'set role anon';
end;
$$;

-- Erwartet, dass ein SQL-Befehl mit einer Fehlermeldung scheitert, die p_like enthält.
create function test_helpers.expect_error(p_sql text, p_like text, p_name text)
returns void language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlerrm not like '%' || p_like || '%' then
      raise exception 'FEHLER in "%": falsche Meldung: %', p_name, sqlerrm;
    end if;
    raise notice 'ok: %', p_name;
    return;
  end;
  raise exception 'FEHLER in "%": Befehl hätte scheitern müssen', p_name;
end;
$$;

create function test_helpers.expect_equal(p_actual bigint, p_expected bigint, p_name text)
returns void language plpgsql as $$
begin
  if p_actual is distinct from p_expected then
    raise exception 'FEHLER in "%": erwartet %, bekommen %', p_name, p_expected, p_actual;
  end if;
  raise notice 'ok: %', p_name;
end;
$$;

create function test_helpers.expect_true(p_value boolean, p_name text)
returns void language plpgsql as $$
begin
  if p_value is distinct from true then
    raise exception 'FEHLER in "%": Bedingung nicht erfüllt', p_name;
  end if;
  raise notice 'ok: %', p_name;
end;
$$;

grant execute on all functions in schema test_helpers to authenticated, anon;


set client_min_messages = notice;
