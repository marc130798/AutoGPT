# Taleria

Lern-App, mit der Kinder (10 bis 14) spielerisch den Umgang mit Geld lernen.
Alle Regeln und Entscheidungen stehen in [`CLAUDE.md`](CLAUDE.md).

## Was es nach Schritt 1 gibt

- Flutter-App für iOS und Android (nur Hochformat auf dem Handy, Tablet auch quer)
- Startbildschirm mit Talo und Tala als Platzhalter, Intro-Film als Platzhalter („Film folgt“ + Weiter)
- Übersicht aller Grafiken und Filme mit Zähler, wie viele echte Dateien schon da sind (nur Testumgebung)
- Farben und Schriften aus einem austauschbaren Theme, alle Texte in `lib/l10n/app_de.arb`
- Asset-Manifest `assets/asset_manifest.json`: jeder Schlüssel (z. B. `character.talo`) mit Datei und Platzhalter
- Supabase-Datenbank: Admin-Tabellen, Inhalts-Tabellen, Regeln und Row Level Security
- Getrennte Zugangsdaten für Test und Live, die nie im Git landen

## Ordner

| Ordner | Inhalt |
| --- | --- |
| `lib/core/` | Grundlagen: Einstellungen, Theme, Grafiken und Platzhalter, Server-Verbindung |
| `lib/features/` | Bildschirme, ein Ordner pro Bereich |
| `lib/l10n/` | Texte der App (zuerst Deutsch) |
| `assets/` | Grafiken, Animationen, Ton und das Asset-Manifest |
| `supabase/migrations/` | Aufbau der Datenbank, Schritt für Schritt |
| `supabase/sql_tests/` | Tests für die Regeln in der Datenbank |
| `env/` | Vorlagen für die Zugangsdaten (`*.example.json`) |
| `test/` | Tests der App |

## Einmalig einrichten

### 1. Flutter installieren

Anleitung: <https://docs.flutter.dev/get-started/install>. Danach im Terminal:

```bash
cd taleria
flutter pub get
```

### 2. Zwei Supabase-Projekte anlegen (Test und Live)

Auf <https://supabase.com> zwei Projekte anlegen, beide mit der Region
**Central EU (Frankfurt)**:

- `taleria-test` – zum Entwickeln und Ausprobieren
- `taleria-live` – nur für die echte App, hier wird nie direkt gearbeitet

Für jedes Projekt unter *Project Settings → API Keys* die **Project URL** und den
**Publishable key** (beginnt mit `sb_publishable_`) kopieren.
Den **Secret key** nie in die App und nie ins Git.

### 3. Zugangsdaten eintragen

```bash
cp env/test.example.json env/test.json
cp env/live.example.json env/live.json
```

Dann in beiden Dateien Adresse und Schlüssel eintragen. Die Dateien
`env/test.json` und `env/live.json` stehen in `.gitignore` und landen nie im Git.

### 4. Datenbank aufbauen (zuerst nur Test)

Mit der [Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
npx supabase login
npx supabase link --project-ref DEINE-TEST-PROJEKT-ID
npx supabase db push
```

Für Live später genauso, aber erst, wenn alles in Test geprüft ist.

## App starten

Ohne Server (geht sofort, alles läuft mit Platzhaltern):

```bash
flutter run
```

Mit dem Test-Server:

```bash
flutter run --dart-define-from-file=env/test.json
```

Oben auf dem Startbildschirm steht dann „Testumgebung · Server verbunden, Datenbank bereit“.

## Was du ausprobieren kannst

1. App starten: Talo (oranger Kreis) und Tala (rosa Kreis) erscheinen als Platzhalter.
2. „Intro ansehen“: Standbild mit „Film folgt“, „Weiter“ führt zurück.
3. „Alle Platzhalter ansehen“: alle Grafiken der App, geordnet nach Art, mit Zähler.
4. Handy drehen: Die App bleibt im Hochformat. Auf dem Tablet darf sie sich drehen.
5. Grafik austauschen: Bild als PNG unter `assets/images/<Schlüssel>.png` ablegen
   (z. B. `assets/images/brand.logo.png`), App neu starten, der Platzhalter ist weg.
   Vorher Rechte in `ASSETS_LICENSES.md` eintragen.

## Tests

```bash
flutter analyze        # Code-Prüfung
flutter test           # Tests der App
tool/db_test.sh        # Tests der Datenbank-Regeln (braucht Postgres 15 oder neuer)
```
