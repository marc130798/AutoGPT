#!/usr/bin/env bash
# Baut die Kinder- und Eltern-App als Webseite, damit Marc und Beta-Familien sie
# ohne App Store auf dem iPhone testen können (Safari → Teilen → „Zum Home-Bildschirm“).
#
# Nur für die TESTUMGEBUNG. Die Zugangsdaten kommen aus env/test.json (nicht im Git).
# Ergebnis: build/web_test/ und build/taleria_test_web.zip (zum Hochladen, zum Beispiel
# bei Netlify Drop). Die Adresse nur an Tester weitergeben.
#
# Aufruf im Ordner taleria/:  bash tool/build_test_web.sh [env/test.json]
set -euo pipefail

cd "$(dirname "$0")/.."

ENV_FILE="${1:-env/test.json}"
OUT="build/web_test"
ZIP="build/taleria_test_web.zip"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Fehlt: $ENV_FILE (Vorlage: env/test.example.json)" >&2
  exit 1
fi
if ! grep -Eq '"TALERIA_ENV"[[:space:]]*:[[:space:]]*"test"' "$ENV_FILE"; then
  echo "Abbruch: Die Web-Testversion gibt es nur für die Testumgebung (TALERIA_ENV = test)." >&2
  exit 1
fi

# --no-web-resources-cdn: Alles kommt vom eigenen Server, keine Anfragen an fremde Dienste.
flutter build web -t lib/main.dart --release --no-web-resources-cdn \
  --dart-define-from-file="$ENV_FILE" -o "$OUT"

# Der Ordner web/ ist für den Adminbereich gedacht. Für die Testversion bekommt die
# Seite ihren eigenen Namen, damit auf dem iPhone „Taleria“ unter dem Symbol steht.
sed -i \
  -e 's|<meta name="description" content="[^"]*">|<meta name="description" content="Taleria Testversion">|' \
  -e 's|<meta name="apple-mobile-web-app-title" content="[^"]*">|<meta name="apple-mobile-web-app-title" content="Taleria">\n  <meta name="apple-mobile-web-app-capable" content="yes">|' \
  -e 's|<title>[^<]*</title>|<title>Taleria (Test)</title>|' \
  "$OUT/index.html"

cat > "$OUT/manifest.json" <<'JSON'
{
  "name": "Taleria (Test)",
  "short_name": "Taleria",
  "start_url": ".",
  "display": "standalone",
  "orientation": "portrait",
  "background_color": "#24476B",
  "theme_color": "#24476B",
  "description": "Taleria Testversion",
  "prefer_related_applications": false,
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icons/Icon-maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable" },
    { "src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
JSON

if ! grep -q '<title>Taleria (Test)</title>' "$OUT/index.html"; then
  echo "Abbruch: index.html ließ sich nicht anpassen." >&2
  exit 1
fi

rm -f "$ZIP"
(cd "$OUT" && zip -qr "../$(basename "$ZIP")" .)
echo "Fertig: $OUT und $ZIP"
