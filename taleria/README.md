# Taleria

Lern-App, mit der Kinder (10 bis 14) spielerisch den Umgang mit Geld lernen.
Alle Regeln und Entscheidungen stehen in [`CLAUDE.md`](CLAUDE.md).

## Was es nach Schritt 7 gibt

- Ankerplätze nach Station 2, 4 und 6 jeder Insel: Perlentauchen und eine Aufgabe im Wrack
- Unterwasser-Sammlung mit Perlen und einem Fund pro Ankerplatz
- Zwei Mini-Spiele mit echter Mechanik: Sortieren (Körbe) und Reihenfolge, in 6 Stationen
- Nebel voraus: Hinweis auf der Karte und Kontrollfahrt zum Üben statt Warten

## Was es seit Schritt 6 gibt

- Startseite des Kindes: Rang, Seemeilen, Weg zum nächsten Rang, Fahrtwind (Wochen in Folge)
- „Meine Orden“: ein Orden pro Insel, mit Schatzkarten-Effekt beim Insel-Abschluss
- Tempo: 2 neue Stationen pro Woche (Montag und Donnerstag), erzählt als Wind, nie als Countdown
- Wiederholung: Jede Antwort kommt in einen Wiederholungsplan (1 Tag, 1 Woche, 1 Monat)
- Begegnung auf See: Meister Taleron taucht auf der Karte auf und stellt 3 Rätsel
- Leuchtturm: Tempo einstellen (2, 3, 4 oder Frei) und die Serie pausieren

## Was es seit Schritt 5 gibt

- Kinderbereich: „Schatztruhe“ mit Bordkasse, Schatztruhe und Glückstruhe, Umbuchen,
  Ausgaben und Geschenke eintragen, Wunschschätze sparen und einlösen, Kassenbuch
- Kinderbereich: „Aufträge“ melden, Antwort der Eltern sehen, erneut melden
- Leuchtturm: Taschengeld festlegen (wöchentlich oder monatlich), Aufgaben anlegen, bestätigen
  oder ablehnen, Kontostand und Korrekturen
- Alle Beträge sind virtuell: Die App zählt mit, das echte Geld zahlen die Eltern selbst aus

## Was es seit Schritt 4 gibt

- Inselkarte mit allen 15 Inseln: Hafen offen, weitere Inseln mit Schloss, Inseln 4 bis 15 im Nebel
- Hafen, Tauschinsel und Wunschinsel komplett spielbar: Ankunft, 7 Stationen, Abschlussprüfung
- Jede Station: „Weißt du noch?“, Film (Platzhalter), Szene mit Talo, Tala und Inselbewohnern,
  Erklärung, Spiel (Platzhalter bis Schritt 7), Stations-Check, Seemeilen
- Abschlussprüfung: 10 Fragen (ab Insel 2 mit 2 Rückblick-Fragen), bestanden ab 8,
  danach öffnet sich die nächste Insel
- Alle Inhalte stehen in `content/stufe1/` und sind Entwürfe zur Prüfung durch Marc

## Was es seit Schritt 3 gibt

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
| `lib/services/` | Logik: Sitzung, Eltern-Sperre, Leuchtturm, Intro, Karte, Insel, Station |
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

## Was du ausprobieren kannst (Schritt 7, mit Test-Server)

Vorher die Datenbank aktualisieren (`npx supabase db push`) und die Inhalte neu laden
(`supabase/seed.sql` im SQL Editor des Testprojekts ausführen). Danach gibt es die Ankerplätze.
Zum schnellen Durchspielen im Leuchtturm das Tempo auf „Frei“ stellen.

1. Hafen öffnen: Zwischen den Stationen liegen drei Ankerplätze (Taucher-Symbol).
2. Nach Station 2 den ersten Ankerplatz spielen: Perlentauchen mit 4 Fragen, dann das Wrack.
   Im Wrack ruhig zuerst falsch antworten: Es kommt die Erklärung und „Nochmal versuchen“.
   Am Ende: Perlen, Seemeilen und der Fund „Alte Handelsmünze“.
3. Station 3 („Geld früher und heute“): Das Spiel ist jetzt ein Zeitstrahl. Dinge der Reihe nach
   antippen, von früher bis heute.
4. Station 5 (Berufe zuordnen) und Station 7 (Preise schätzen) sind ebenfalls echte Spiele.
   Auf der Tauschinsel Station 7 (faire Tausche), auf der Wunschinsel Station 1 (zwei Körbe) und 4
   (Gruppendruck).
5. Startseite: „Unterwasser-Sammlung“ zeigt Perlen und Funde.
6. Wenn Hafen, Tauschinsel und Wunschinsel geschafft sind: Oben auf der Karte steht
   „Die nächste Insel liegt noch im Nebel“ mit „Kontrollfahrt starten“.

## Was du ausprobieren kannst (Schritt 6, mit Test-Server)

Vorher die Datenbank aktualisieren (`npx supabase db push`) und die Inhalte neu laden
(Abschnitt 6 oben: `supabase/seed.sql` im SQL Editor des Testprojekts ausführen), damit es
Orden und Meister Taleron gibt.

1. Kinderbereich: Oben steht der Rang „Schiffsjunge“ mit Seemeilen und „Noch … Seemeilen bis Matrose“.
2. „Meine Orden“: drei Orden, alle noch blass mit „Noch nicht gefunden“.
3. „Zur Karte“, Hafen, Station 2 und 3 spielen. Danach steht oben „Das Schiff braucht Wind.
   Die nächste Station erreichst du am …“, und Station 4 zeigt „Wartet auf Wind“.
   Fertige Stationen kannst du trotzdem wiederholen.
4. Eltern-Gerät: Leuchtturm, Kind antippen, Karte „Tempo und Serie“: „Frei“ wählen.
   Zurück im Kinderbereich ist Station 4 offen.
5. Meister Taleron erscheint, sobald Wiederholungen fällig sind (am nächsten Tag). Zum Ausprobieren
   sofort, nur im Testprojekt, im SQL Editor:
   `update public.question_reviews set due_at = now();`
   Dann die Karte neu öffnen: Taleron taucht neben dem Schiff auf. Antippen, Vorstellung ansehen,
   ein Rätsel absichtlich falsch beantworten: Er erklärt es, „Nochmal versuchen“.
6. Hafen-Prüfung bestehen: Das Kartenstück leuchtet auf, der Orden „Erster Landgang“ erscheint.
   Nach der Tauschinsel wirst du Matrose.
7. Eltern-Gerät: „Serie pausieren“ einschalten. Im Kinderbereich steht „Fahrtwind macht gerade Pause“.

## Was du ausprobieren kannst (Schritt 5, mit Test-Server)

Vorher die Datenbank aktualisieren (`npx supabase db push`). Am besten zwei Geräte benutzen:
eines für die Eltern, eines für das Kind (Anmeldung per Code wie in Schritt 2).

1. Eltern-Gerät: Leuchtturm öffnen, Kind antippen, „Taschengeld und Aufgaben“.
2. „Taschengeld festlegen“: z. B. 5 € wöchentlich, erste Zahlung heute.
3. „Aufgabe anlegen“: z. B. „Rasen mähen“ mit 3 € Belohnung. Eine zweite als „Pflicht ohne Belohnung“.
4. Kinder-Gerät: Startseite zeigt „Aufträge“ mit der Zahl der offenen Aufträge.
   „Aufträge“ öffnen und bei „Rasen mähen“ auf „Erledigt!“ tippen.
5. Kinder-Gerät: „Schatztruhe“ öffnen. Die Heuer von 5 € liegt in der Bordkasse.
6. „Umbuchen“: 2 € von der Bordkasse in die Schatztruhe. Versuch auch mal 20 €:
   Dann kommt „So viel ist nicht in der Truhe.“
7. „Neuer Wunschschatz“ mit 2 €: Der Balken ist voll, „Einlösen“ tippen. Im Kassenbuch steht die Buchung.
8. Eltern-Gerät: Beim Kind steht „1 Aufgabe wartet auf Bestätigung“. „Bestätigen“ tippen:
   Die 3 € kommen in die Bordkasse. Oder „Ablehnen“ mit einer Nachricht: Das Kind sieht sie
   und kann „Nochmal melden“.
9. Eltern-Gerät: „Korrektur buchen“, z. B. -1 € aus der Bordkasse. Ein Abzug, der die Truhe
   ins Minus bringen würde, wird abgelehnt.

## Was du ausprobieren kannst (Schritt 4, mit Test-Server)

Vorher die Datenbank aktualisieren (`npx supabase db push`) und die Inhalte laden
(Abschnitt 6 oben: `supabase/seed.sql` im SQL Editor des Testprojekts ausführen).

1. Im Kinderbereich „Zur Karte“: unten der Hafen (leuchtet), darüber die Tauschinsel mit Schloss,
   ganz oben die Inseln im Nebel mit Fragezeichen. Antippen zeigt jeweils einen Hinweis.
2. Hafen antippen: Station 1 ist erledigt (Intro), Station 2 offen, die anderen gesperrt.
3. Station 2 spielen: Film-Platzhalter, Szene am Hafenkontor, Erklärung, Spiel-Platzhalter,
   5 Fragen mit Erklärung nach jeder Antwort, dann „Station geschafft!“ und +100 Seemeilen.
4. Station 3 beginnt mit „Weißt du noch?“: 2 Fragen zur Station davor.
5. Station 2 noch einmal spielen: andere Fragen, und keine Seemeilen mehr.
6. Nach Station 7 die Abschlussprüfung: absichtlich falsch antworten, dann „Noch nicht ganz“
   und „Noch einmal versuchen“ mit neuen Fragen. Mit 8 richtigen: „Kartenstück gefunden!“.
7. Zurück auf der Karte ist die Tauschinsel offen. Beim ersten Besuch kommt die Ankunft mit Bruno und Olga.
8. Die Prüfung der Tauschinsel enthält 2 Fragen aus dem Hafen.
9. Inhalte ändern: Datei in `content/stufe1/` bearbeiten, `dart run tool/build_seed.dart`,
   `supabase/seed.sql` erneut im SQL Editor ausführen.

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
