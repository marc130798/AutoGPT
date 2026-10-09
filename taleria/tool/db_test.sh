#!/usr/bin/env bash
# Testet die Datenbank-Migrationen mit einem frischen, lokalen Postgres.
#
# Startet einen leeren Postgres in einem temporären Ordner, spielt den
# Supabase-Nachbau, alle Migrationen und die Tests ein und räumt danach auf.
# Braucht Postgres 15 oder neuer (initdb, pg_ctl, psql).
# Wenn die Programme nicht im PATH liegen: PG_BIN=/pfad/zu/postgres/bin setzen.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

if [[ -z "${PG_BIN:-}" ]]; then
  PG_BIN="$(dirname "$(command -v initdb 2>/dev/null || ls -d /usr/lib/postgresql/*/bin/initdb 2>/dev/null | sort -V | tail -1)")"
fi

WORK="$(mktemp -d)"
PORT="${PG_TEST_PORT:-54329}"

# Postgres startet nicht als root. In Containern als Nutzer "postgres" ausführen.
run() {
  if [[ "$(id -u)" == "0" ]]; then
    runuser -u postgres -- "$@"
  else
    "$@"
  fi
}

cleanup() {
  run "$PG_BIN/pg_ctl" -D "$WORK/data" -m immediate stop >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

[[ "$(id -u)" == "0" ]] && chown postgres "$WORK"

run "$PG_BIN/initdb" -D "$WORK/data" -U postgres --auth=trust >/dev/null
run "$PG_BIN/pg_ctl" -D "$WORK/data" -o "-p $PORT -k $WORK -c listen_addresses=''" -w start >/dev/null

PSQL=(run "$PG_BIN/psql" -h "$WORK" -p "$PORT" -U postgres -d postgres -v ON_ERROR_STOP=1 -q -t -A)

cat "$ROOT/supabase/sql_tests/00_supabase_stub.sql" | "${PSQL[@]}"
for f in "$ROOT"/supabase/migrations/*.sql; do
  echo "Migration: $(basename "$f")"
  cat "$f" | "${PSQL[@]}"
done
cat "$ROOT/supabase/sql_tests/01_grants.sql" | "${PSQL[@]}"
# set -o pipefail sorgt dafür, dass ein Fehler in psql das Skript abbricht.
cat "$ROOT/supabase/sql_tests/10_regeln_test.sql" | "${PSQL[@]}" 2>&1 | sed -e "s/^NOTICE:  //" -e "/^$/d"
