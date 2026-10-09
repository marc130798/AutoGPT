# Taleria

Lern-App, mit der Kinder (10 bis 14) spielerisch den Umgang mit Geld lernen.
Alle Regeln und Entscheidungen stehen in [`CLAUDE.md`](CLAUDE.md).

## Was es nach Schritt 3 gibt

- Beim ersten Start im Kinderbereich läuft das Intro (Station 1 des Hafens):
  Intro-Film (Platzhalter), Talo und Tala erzählen die Geschichte, „Willst du in unsere Crew?“
- Avatar-Baukasten: Hautfarbe, Frisur, Haarfarbe, Jacke, Kopfbedeckung
- Schiffstaufe mit Namensvorschlägen
- Rundgang: Karte, Schatztruhe, Logbuch
- Erster Wunschschatz (Titel und ungefährer Preis), kann übersprungen werden
- Abschluss: Rang Schiffsjunge, +50 Seemeilen, die Karte rollt sich auf
- Danach zeigt der Kinderbereich Avatar und Schiffsname, im Leuchtturm sehen Eltern beides
- Alles wird sofort gespeichert; Seemeilen bucht nur der Server, und nur einmal

## Was es seit Schritt 2 gibt

- Start: „Ich habe einen Code“ (Kind) oder „Für Eltern“
- Eltern registrieren sich mit E-Mail, Passwort (mindestens 10 Zeichen) und Pflicht-Einwilligung;
  der Newsletter ist ein eigenes, nicht vorausgewähltes Kästchen
- Danach legen Eltern eine Eltern-PIN fest (4 bis 6 Ziffern, nicht 1111 oder 1234)
- Leuchtturm (Elternbereich): Kinder-Profile anlegen, bearbeiten, löschen; Konto löschen; PIN ändern
- Anmeldecode für das Gerät des Kindes (8 Zeichen, 15 Minuten gültig, nur einmal nutzbar)
- Oder „Gerät an Kind übergeben“: Das Kind spielt auf dem Eltern-Gerät, zurück in den Leuchtturm nur mit PIN
- Nach 5 Minuten im Hintergrund ist der Leuchtturm wieder gesperrt
- Eltern können alle Geräte eines Kindes abmelden
- Die Datenbank erzwingt alle Rechte: Ein Kinder-Gerät sieht nur sein eigenes Profil

## Was es seit Schritt 1 gibt

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
| `lib/domain/` | Datenmodelle und Prüfregeln (z. B. PIN, Spitzname, Code) |
| `lib/data/` | Zugriff auf Supabase und auf Einstellungen des Geräts |
| `lib/services/` | Logik: Sitzung, Eltern-Sperre, Leuchtturm |
| `lib/features/` | Bildschirme, ein Ordner pro Bereich |
| `lib/l10n/` | Texte der App (zuerst Deutsch) |
| `assets/` | Grafiken, Animationen, Ton und das Asset-Manifest |
| `supabase/migrations/` | Aufbau der Datenbank, Schritt für Schritt |
| `supabase/sql_tests/` | Tests für die Regeln in der Datenbank |
| `content/stufe1/` | Inhalte der Inseln (Stationen, Szenen, Fragen), Quelle für `supabase/seed.sql` |
| `tool/` | Werkzeuge: Datenbank-Tests, Seed-Datei erzeugen |
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

### 4. Anmeldung im Supabase-Dashboard einstellen (Test und Live)

Unter *Authentication → Sign In / Providers*:

- **Allow anonymous sign-ins** einschalten (so melden sich Kinder-Geräte an, ganz ohne E-Mail)
- **Confirm email** eingeschaltet lassen (Eltern bestätigen ihre E-Mail-Adresse)

Unter *Authentication → Policies → Password*: Mindestlänge **10**.

Unter *Authentication → URL Configuration*: **Site URL** auf die spätere Website von Taleria
setzen. Dorthin führt der Bestätigungslink aus der E-Mail. Danach meldet man sich in der App an.

### 5. Datenbank aufbauen (zuerst nur Test)

Mit der [Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
npx supabase login
npx supabase link --project-ref DEINE-TEST-PROJEKT-ID
npx supabase db push
```

Für Live später genauso, aber erst, wenn alles in Test geprüft ist.

### 6. Inhalte in die Testdatenbank laden (nur Test, nie Live)

Die Inhalte der Inseln stehen in `content/stufe1/` (eine Datei pro Insel). Daraus entsteht
`supabase/seed.sql`. Nach einer Änderung an den Inhalten:

```bash
dart run tool/build_seed.dart
```

In die Testdatenbank laden: im Supabase-Dashboard des **Testprojekts** den *SQL Editor* öffnen,
den Inhalt von `supabase/seed.sql` einfügen und ausführen. Die Datei schaltet auch die
Inhalts-Vorschau ein, damit Kinder in der Testumgebung die Entwürfe sehen.

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

## Was du ausprobieren kannst (Schritt 3, mit Test-Server)

1. Im Leuchtturm ein neues Kinder-Profil anlegen und auf einem Kinder-Gerät mit Code anmelden
   (oder „Gerät an … übergeben“).
2. Das Intro startet: Film-Platzhalter, „Weiter“, dann erzählen Talo und Tala.
3. Avatar gestalten und „So sehe ich aus!“ – die Vorschau ändert sich bei jedem Tipp.
4. Schiff taufen: Ein Name mit nur einem Buchstaben wird abgelehnt, ein Vorschlag lässt sich antippen.
5. Rundgang durchtippen, dann einen Wunschschatz anlegen (zum Beispiel „Fahrradhelm“, 40 €)
   oder „Weiß ich noch nicht“.
6. Abschluss: „Dein Rang: Schiffsjunge“ und „+50 Seemeilen“, dann „Karte öffnen“ und „Los geht's“.
7. App schließen und neu öffnen: Das Intro kommt nicht noch einmal.
8. Im Leuchtturm stehen jetzt Avatar und Schiffsname beim Kind.
9. In der Supabase-Tabellenansicht: `savings_goals` enthält den Wunschschatz in Cent (4000),
   `xp_events` genau einen Eintrag mit 50 Seemeilen.

Auf dem Eltern-Gerät führt der Leuchtturm-Knopf auch während des Intros zur PIN-Abfrage.

## Was du ausprobieren kannst (Schritt 2, mit Test-Server)

1. App mit `--dart-define-from-file=env/test.json` starten, „Für Eltern“ wählen und registrieren.
   Ohne Häkchen bei der Einwilligung geht es nicht weiter.
2. E-Mail bestätigen, in der App anmelden, Eltern-PIN festlegen.
3. Im Leuchtturm ein Kinder-Profil anlegen (nur Spitzname, Geburtsjahr, Niveau).
4. Profil antippen, „Anmeldecode erzeugen“. Auf einem zweiten Gerät „Ich habe einen Code“ wählen
   und den Code eingeben: Dort steht „Willkommen an Bord, …!“.
5. Denselben Code ein zweites Mal eingeben: Er wird abgelehnt.
6. Auf dem Eltern-Gerät „Gerät an … übergeben“: Der Kinderbereich öffnet sich. Oben rechts der
   Leuchtturm fragt nach der PIN, „Zurück an Bord“ führt ohne PIN zurück.
7. App schließen und neu öffnen: Es geht direkt in den Kinderbereich, ohne PIN.
8. Im Leuchtturm „Alle Geräte abmelden“: Das zweite Gerät landet wieder auf dem Startbildschirm.
9. Kinder-Profil löschen und Konto löschen: Beides fragt vorher nach.

In der Supabase-Tabellenansicht (Testprojekt) siehst du in `parents` den Zeitpunkt der
Einwilligung (`consent_at`). Die PIN steht dort nur als unlesbare Prüfsumme.

## Was du ausprobieren kannst (Schritt 1, ohne Server)

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
