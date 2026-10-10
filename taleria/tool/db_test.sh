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

# Alle Testdateien laufen nacheinander in einer Sitzung.
# set -o pipefail sorgt dafür, dass ein Fehler in psql das Skript abbricht.
cat "$ROOT/supabase/sql_tests/05_test_helpers.sql" "$ROOT"/supabase/sql_tests/[1-9]*_test.sql \
  | "${PSQL[@]}" 2>&1 | sed -n -e "s/^NOTICE:  //p" -e "/ERROR/p"

# Seed-Daten in einer frischen Datenbank prüfen.
echo "Seed-Daten:"
run "$PG_BIN/createdb" -h "$WORK" -p "$PORT" -U postgres seedcheck
SEED_PSQL=(run "$PG_BIN/psql" -h "$WORK" -p "$PORT" -U postgres -d seedcheck -v ON_ERROR_STOP=1 -q -t -A)
cat "$ROOT/supabase/sql_tests/00_supabase_stub.sql" "$ROOT"/supabase/migrations/*.sql "$ROOT/supabase/seed.sql" \
  | "${SEED_PSQL[@]}" 2>&1 | sed -e "/already exists, skipping/d"
cat "$ROOT/supabase/sql_tests/05_test_helpers.sql" "$ROOT/supabase/sql_tests/seed/seed_check.sql" \
  | "${SEED_PSQL[@]}" 2>&1 | sed -n -e "s/^NOTICE:  //p" -e "/ERROR/p"

# Einrichtung ohne Kommandozeile: alle Migrationen in einer Datei, dann die Seed-Daten.
echo "Einrichtung in einem Durchgang:"
run "$PG_BIN/createdb" -h "$WORK" -p "$PORT" -U postgres setupcheck
SETUP_PSQL=(run "$PG_BIN/psql" -h "$WORK" -p "$PORT" -U postgres -d setupcheck -v ON_ERROR_STOP=1 -q -t -A)
cat "$ROOT/supabase/sql_tests/00_supabase_stub.sql" "$ROOT/supabase/datenbank_einrichten.sql" "$ROOT/supabase/seed.sql" \
  | "${SETUP_PSQL[@]}" 2>&1 | sed -e "/already exists, skipping/d"
MIGRATIONS="$(ls "$ROOT"/supabase/migrations/*.sql | wc -l)"
RECORDED="$("${SETUP_PSQL[@]}" -c "select count(*) from supabase_migrations.schema_migrations")"
if [[ "$MIGRATIONS" != "$RECORDED" ]]; then
  echo "FEHLER: $MIGRATIONS Migrationen, aber $RECORDED in der Liste der Supabase CLI"
  exit 1
fi
echo "ok: datenbank_einrichten.sql richtet die Datenbank ein und trägt $RECORDED Migrationen ein"

# Geprüfter Import für die Live-Datenbank: ohne Test-Einstellungen, beliebig oft einspielbar.
# Danach dieselbe Datei mit allem „freigegeben“: veröffentlichen klappt, ein erneuter Import
# ändert nichts, und zurück auf Entwurf lehnt die Datenbank ab.
echo "Live-Import:"
run "$PG_BIN/createdb" -h "$WORK" -p "$PORT" -U postgres livecheck
LIVE_PSQL=(run "$PG_BIN/psql" -h "$WORK" -p "$PORT" -U postgres -d livecheck -v ON_ERROR_STOP=1 -q -t -A)
cat "$ROOT/supabase/sql_tests/00_supabase_stub.sql" "$ROOT/supabase/datenbank_einrichten.sql" \
  "$ROOT/supabase/inhalte_live.sql" "$ROOT/supabase/inhalte_live.sql" \
  | "${LIVE_PSQL[@]}" 2>&1 | sed -e "/already exists, skipping/d"
NOT_DRAFT="$("${LIVE_PSQL[@]}" -c "select count(*) from public.islands where status <> 'draft'")"
if [[ "$NOT_DRAFT" != "0" ]]; then
  echo "FEHLER: Der Live-Import enthält freigegebene Inseln, obwohl in den Dateien nichts freigegeben ist"
  exit 1
fi
echo "ok: inhalte_live.sql läuft zweimal hintereinander, alles bleibt Entwurf"
sed "s/'draft'/'published'/g" "$ROOT/supabase/inhalte_live.sql" > "$WORK/alles_freigegeben.sql"
cat "$WORK/alles_freigegeben.sql" "$WORK/alles_freigegeben.sql" | "${LIVE_PSQL[@]}" >/dev/null
cat "$ROOT/supabase/sql_tests/05_test_helpers.sql" "$ROOT/supabase/sql_tests/seed/live_check.sql" \
  | "${LIVE_PSQL[@]}" 2>&1 | sed -n -e "s/^NOTICE:  //p" -e "/ERROR/p"
if WITHDRAW="$("${LIVE_PSQL[@]}" -f "$ROOT/supabase/inhalte_live.sql" 2>&1)"; then
  echo "FEHLER: Veröffentlichte Pflichtstationen ließen sich wieder auf Entwurf setzen"
  exit 1
fi
if [[ "$WITHDRAW" != *"nicht zurückgezogen werden"* ]]; then
  echo "FEHLER: Zurückziehen scheitert mit einer unerwarteten Meldung: $WITHDRAW"
  exit 1
fi
echo "ok: Veröffentlichte Inhalte lassen sich nicht zurückziehen"

echo "Alle Datenbank-Tests bestanden."
