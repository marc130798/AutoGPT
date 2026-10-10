# CLAUDE.md – Projekt Taleria

Diese Datei ist das Gedächtnis des Projekts. Lies sie zu Beginn jeder Sitzung vollständig.
Wenn sich eine Entscheidung ändert, aktualisiere diese Datei im selben Schritt.

---

## 1. Arbeitsweise mit Marc

- Marc ist Gründer, kein Entwickler. Erkläre jeden Schritt kurz und in einfachem Deutsch: was du baust, warum, und wie er es testen kann.
- Arbeite in kleinen Schritten. Ein Schritt = eine Funktion, die man ausprobieren kann.
- Frage nach, bevor du die Architektur, das Datenmodell oder eine Bibliothek grundlegend änderst.
- Nach jedem funktionierenden Schritt: Git-Commit mit einer verständlichen deutschen Commit-Nachricht.
- Niemals Passwörter, API-Schlüssel oder Zugangsdaten committen. Geheimnisse gehören in `.env`-Dateien, die in `.gitignore` stehen.
- Schreibe Tests für die Geschäftslogik (Seemeilen, Ränge, virtuelles Guthaben, Freischalten von Inseln, Abo-Rechte).
- Test- und Live-Umgebung immer getrennt halten. Nie direkt auf der Live-Datenbank entwickeln.
- Wenn etwas unklar ist: nachfragen statt raten.

---

## 2. Was Taleria ist

Eine Lern-App, mit der Kinder spielerisch den Umgang mit Geld lernen.

- **Nutzer:** Kinder, empfohlen ab 10 Jahren. Eltern können selbst entscheiden, ab wann ihr Kind startet.
- **Kunden:** die Eltern. Nur sie zahlen und verwalten das Abo.
- **Umfang:** Gebaut wird NUR Stufe 1 (10 bis 14). Stufe 2 (15 bis 18) wird nicht gebaut, keine Inhalte, keine Bildschirme, keine Texte.
- **Vorbereitung für Stufe 2:** Die Technik bleibt offen dafür: Feld `stage` bei Kindern und Inseln, austauschbares Theme, Inhalte aus der Datenbank. Stufe 2 soll später durch neue Inhalte und ein neues Theme hinzukommen, ohne Umbau des Codes. Überall, wo heute nur Stufe 1 gilt, wird trotzdem nach `stage` gefiltert.
- **Welt:** Das Meer von Taleria. Die Figuren Talo (Fuchs, Kapitän) und Tala (Schwein, weiblich, Zahlmeisterin) suchen als Schatzsucher die Teile einer zerrissenen Schatzkarte. Das Kind ist neues Crewmitglied. Meister Taleron, ein uraltes, weises und freundliches Seeungeheuer, ist der Hüter des Meeres: Er hat die Schatzkarte einst selbst zerrissen und die Teile auf den Inseln verteilt, damit nur eine kluge Crew den Schatz findet. Er prüft die Crew unterwegs mit Rätselfragen.
- **Fortschritt:** Eine Inselkarte. Jede Insel ist ein Thema mit mehreren Stationen. Erledigte Inseln öffnen die nächste, weitere Inseln tragen ein Schloss.

### Was Taleria NICHT ist

- Keine echten Zahlungen, keine Bankverbindung, keine Bezahlkarte. Alle Beträge in der App sind virtuell.
- Keine Anlageberatung, keine Kaufempfehlungen, keine Links zu Finanzanbietern.
- Keine Werbung, keine Tracking-Dienste von Drittanbietern.
- Keine Käufe durch das Kind. Bezahlen nur im Elternbereich.

---

## 3. Die vier Säulen

1. **Lernen:** fester Lernpfad (der Kern). Inseln mit Stationen: Video, Quiz, Mini-Spiel, Praxisaufgabe, Abschlussprüfung. Am Ende von Stufe 1 die Goldene Schatzkarte (Zertifikat: Finanzführerschein Stufe 1).
2. **Budget und Aufgaben:** virtuelles Taschengeld (Heuer), Aufträge der Eltern, drei Truhen, Sparziele (Wunschschätze).
3. **Spiele:** Mini-Spiele mit Talern als Spielwährung, Seemeilen als Erfahrungspunkte, Ränge.
4. **Familie:** Elternbereich (Leuchtturm) mit Fortschritt, Aufgaben, Kombüsen-Fragen, Abo.

Alle Säulen teilen sich ein Konto-, Fortschritts- und Inhaltssystem.

---

## 4. Glossar (Code, Kinderbereich, Elternbereich)

Im Code verwenden wir englische Namen. Die Texte in der App kommen aus diesem Glossar.

| Code | Kinderbereich | Elternbereich |
| --- | --- | --- |
| `task` | Auftrag | Aufgabe |
| `allowance` | Taschengeld (bis 10.10.2026 „Heuer“, Kinder verstanden das Wort nicht) | Taschengeld |
| `pot_spend` | Bordkasse | Ausgeben |
| `pot_save` | Schatztruhe | Sparen |
| `pot_give` | Glückstruhe | Verschenken |
| `savings_goal` | Wunschschatz | Sparziel |
| `coin` | Taler | Taler |
| `xp` | Seemeilen | Fortschritt |
| `rank` | Rang in der Form, die das Kind wählt: Schiffsjunge, Matrose, Bootsmann, Steuermann, Kapitän oder Schiffsmädchen, Matrosin, Bootsfrau, Steuerfrau, Kapitänin | Level |
| `badge` | Orden | Abzeichen |
| `streak` | Fahrtwind | Serie |
| `certificate` | Goldene Schatzkarte | Finanzführerschein Stufe 1 |
| `expedition` (Season) | Expedition | Zusatz-Abenteuer |
| `bonus_station` | Flaschenpost | Neue Inhalte |
| `review_trip` | Kontrollfahrt | Wiederholung |
| `review_stop` | Ankerplatz (Tauchgang) | Wiederholungs-Station |
| `collectible` | Unterwasser-Sammlung (Perlen, Muscheln, Fundstücke) | Sammlung |
| `fog` | Nebel („Diese Insel taucht bald auf“) | Inhalt folgt |
| `encounter` | Begegnung auf See (Seeungeheuer, Händlerschiff …) | Wiederholung |
| `pace` | Wind („die nächste Station erreichst du am …“) | Tempo (Stationen pro Woche) |
| `parent_area` | (nicht sichtbar) | Leuchtturm / Elternbereich |
| `conversation_prompt` | (nicht sichtbar) | Kombüsen-Fragen |
| `family_challenge` | Crew-Abenteuer | Familien-Challenge |

Alle sichtbaren Texte der App-Oberfläche liegen in Übersetzungsdateien (zuerst Deutsch), nie fest im Code. Inhaltstexte (Namen von Inseln und Expeditionen, Stationstexte, Fragen) stehen in der Datenbank (entschieden mit Marc am 09.10.2026), damit neue Inhalte kein App-Update brauchen.

---

## 5. Technik (Vorschlag, bei Bedarf mit Marc anpassen)

- **App:** Flutter (eine Codebasis für iOS und Android).
- **Backend:** Supabase, Region EU (Frankfurt), mit Postgres, Auth, Storage und Row Level Security.
- **Abos:** RevenueCat für In-App-Abos über Apple und Google.
- **Videos:** in Supabase Storage oder einem EU-Videodienst, nur abgespielt, nicht öffentlich auffindbar.
- **Analyse:** nur datenschutzfreundlich und ohne Drittanbieter-Tracking (eigene Ereignis-Tabelle).

### Architektur-Regeln

- **Getrennte Schichten:** Oberfläche (Widgets), Logik (Services), Daten (Repositories). Die Logik kennt kein Aussehen.
- **Austauschbares Aussehen:** Farben, Schriften, Figuren und Texte kommen aus einem Theme und den Übersetzungsdateien. So kann später eine zweite App (Stufe 2) dieselbe Technik mit anderem Look nutzen.
- **Inhalte in der Datenbank, nicht im Code:** Inseln, Stationen, Quizfragen, Kombüsen-Fragen werden aus Supabase geladen. Neue Inhalte brauchen kein App-Update.
- **Rechte in der Datenbank erzwingen:** Row Level Security auf allen Tabellen. Die Oberfläche allein ist kein Schutz.
- **Geld als ganze Zahlen:** Beträge immer in Cent (`integer`), nie als Kommazahl.

---

## 6. Konten und Rollen

- **Eltern-Konto:** Anmeldung mit E-Mail und Passwort über Supabase Auth. Einwilligung zur Datenverarbeitung wird mit Zeitpunkt gespeichert.
- **Kinder-Profile:** gehören zu einem Eltern-Konto, ohne eigene E-Mail. Gespeichert werden nur Spitzname, Geburtsjahr, Niveau, Avatar, Schiffsname.
- **Anmeldung des Kindes:** über einen Code oder QR-Code aus dem Elternbereich. Das Gerät des Kindes bekommt eine Sitzung, die nur auf dieses eine Kinder-Profil zugreifen darf.
- **Eltern-Sperre:** Der Elternbereich ist auf dem Gerät nur über eine Eltern-PIN oder eine Rechenaufgabe erreichbar.
- **Kinderbereich:** keine Preise, keine Kauf-Buttons, keine Links nach außen, keine Chats.
- **Löschen:** Eltern können ein Kinder-Profil und ihr ganzes Konto mit allen Daten löschen.
- **Admin:** Eigene Rolle nur für Marc (und später sein Team). Admins nutzen ausschließlich den Adminbereich (Abschnitt 10), nie die Kinder- oder Eltern-App.

---

## 7. Datenmodell (erste Fassung)

Alle Tabellen mit `id uuid`, `created_at`, `updated_at`.

**Konten**
- `parents` – verknüpft mit `auth.users`; `consent_at`, `consent_version`, `locale`, `parent_pin_hash` (bcrypt, für die App nicht lesbar), `has_parent_pin`, `parent_pin_failed_attempts`, `parent_pin_locked_until`, `marketing_consent_at`, `marketing_confirmed_at`, `marketing_unsubscribed_at`, `push_consent_at` (Regeln für E-Mails und Push in `MARKETING.md`, Abschnitt 5)
- `children` – `parent_id`, `nickname`, `birth_year`, `level_setting` (Einsteiger, Fortgeschritten), `stage` (1 oder 2), `avatar` (JSON, höchstens 1 KB), `ship_name`, `onboarding_completed_at` (Intro abgeschlossen), `stations_per_week` (Standard 2, `null` = freie Fahrt), `release_weekdays` (Standard Montag und Donnerstag)
- `child_login_codes` – `child_id`, `code_hash` (nur SHA-256, der Code wird einmal angezeigt), `expires_at`, `used_at`
- `child_devices` – `user_id` (anonyme Sitzung des Kinder-Geräts), `child_id`

**Inhalte**
- `islands` – `slug`, `stage`, `island_group`, `sort_order`, `map_x`, `map_y`, `route_type` (main, side, event), `expedition_id` (optional), `title` (Name direkt in der Datenbank), `content` (Lernziel, Ankunftsszene, Orden, Auftrag, Zugang), `intro_video_url`, `is_published`
- `stations` – `island_id`, `sort_order`, `type` (video, quiz, game, practice, review_stop, exam), `is_required`, `added_in_version`, `xp_reward`, `content` (jsonb), `is_published`
- `quiz_questions` – `station_id`, `question`, `answers` (jsonb), `correct_index`, `explanation`, `covers_station` (bei Prüfungsfragen: zu welcher Station)
- `expeditions` – `title`, `starts_at`, `ends_at`
- `conversation_prompts` – `island_id`, `text`

**Fortschritt**
- `station_progress` – `child_id`, `station_id`, `status` (open, done), `best_score`, `last_score`, `attempts`, `completed_at`
- `island_completions` – `child_id`, `island_id`, `completed_at`
- `xp_events` – `child_id`, `source_type`, `source_id`, `amount` (ein Kassenbuch der Seemeilen; der Rang wird daraus berechnet)
- `ranks` – `code` (schiffsjunge … kapitaen), `sort_order`, `min_xp`, `requires_certificate` (Kapitän nur mit Goldener Schatzkarte)
- `badges` – `slug`, `kind` (island, taleron, special), `island_id`, `title`, `asset_key`, `sort_order`, `status`; `child_badges` – `child_id`, `badge_id`, `earned_at`
- `question_reviews` – `child_id`, `question_id`, `due_at`, `interval_days`, `correct_streak`, `times_answered`, `times_wrong`, `last_answered_at`, `last_correct` (Zeitplan der Wiederholung pro Frage und Kind)
- `encounters` – `slug`, `type` (taleron, haendlerschiff, fischerboot, angeberschiff, tala_vergisst), `title`, `asset_key`, `question_count`, `xp_reward`, `after_island_id`, `content` (Szenen), `status` (Vorlagen für Begegnungen auf See)
- `encounter_runs` – `child_id`, `encounter_id`, `correct_count`, `total`, `finished_at`
- `pace_state` – `child_id`, `wind` (neue Stationen, die das Kind gerade beginnen darf), `checked_on`
- `child_streaks` – `child_id`, `weeks`, `last_week`, `paused` (Fahrtwind)
- `collectibles` – `slug`, `kind` (pearl, shell, wreck_item), `title`, `asset_key`, `rarity` (nur Optik), `station_id` (Ankerplatz, an dem der Fund liegt), `sort_order`, `status`
- `child_collectibles` – `child_id`, `collectible_id`, `found_at`, `source_station_id`

**Budget und Aufgaben (alles virtuell)**
- `tasks` – `parent_id`, `child_id`, `title`, `reward_cents`, `is_chore` (Pflicht ohne Geld), `status` (open, submitted, approved, rejected), `photo_path` (optional), `due_at`, `parent_note`, `submitted_at`, `reviewed_at`
- `allowance_rules` – `child_id`, `amount_cents`, `interval` (weekly, monthly), `next_run_at`
- `ledger_entries` – `child_id`, `pot` (spend, save, give), `amount_cents`, `entry_type` (allowance, task, transfer, manual, goal, purchase, donation), `reference_id`, `note`, `created_by` (Kassenbuch; Guthaben = Summe, nie direkt überschreiben)
- `savings_goals` – `child_id`, `title`, `target_cents`, `reached_at`
- `wish_bottles` – `child_id`, `title`, `price_cents` (optional), `is_big` (großer Wunsch), `remind_at`, `decision` (open, dropped, converted), `decided_at`, `savings_goal_id` (bei Umwandlung)

**Abo**
- `entitlements` – `parent_id`, `entitlement` (premium), `source` (revenuecat, manual, test), `valid_until` (`null` = ohne Ablauf)

**Messung (Schritt 11)**
- `analytics_events` – `child_id`, `event_type` (app_open, station_start), `station_id`, `day` (nur der Tag, keine Uhrzeit; höchstens ein Eintrag pro Kind, Ereignis, Station und Tag; nach 400 Tagen gelöscht)
- `app_errors` – `fingerprint`, `day`, `platform`, `error`, `stack`, `count`, `last_seen_at` (Fehlerprotokoll ohne Nutzer und ohne Gerät; nach 90 Tagen gelöscht)

**Admin**
- `admins` – verknüpft mit `auth.users`; `role` (owner, editor, support), `mfa_required` (immer true)
- `admin_audit_log` – `admin_id`, `action`, `target_type`, `target_id`, `reason`, `created_at` (jeder Zugriff auf ein Familienkonto und jede Löschung wird protokolliert)
- `app_settings` – `key`, `value` (Einstellungen der Umgebung, z. B. `content_preview` nur in der Testumgebung)
- `content_versions` – `entity_type`, `entity_id`, `snapshot` (jsonb), `created_by`, `created_at` (frühere Fassungen von Inseln und Stationen, damit man Änderungen zurückholen kann)
- Inhalte haben zusätzlich `status` (draft, review, published), damit Entwürfe nie versehentlich bei Kindern landen.

---

## 8. Feste Regeln der Spiellogik

- **Insel-Abschluss ist eingefroren:** Eine Insel gilt als abgeschlossen, wenn alle Pflichtstationen erledigt sind. Der Abschluss wird in `island_completions` gespeichert und später NIE neu berechnet.
- **Neue Inhalte:** Später ergänzte Stationen sind immer `is_required = false` (Bonus, im Kinderbereich „Flaschenpost“). Sie öffnen eine fertige Insel nicht wieder.
- **Freischalten:** Die nächste Insel der Hauptroute öffnet sich, sobald die vorherige abgeschlossen ist. Nebeninseln und Event-Inseln haben eigene Regeln.
- **Gutschriften nur durch Eltern:** Aufträge werden erst gutgeschrieben, wenn die Eltern bestätigen. Das Kind kann sich nichts selbst buchen.
- **Belohnungen:** Seemeilen, Orden und Kosmetik (Schiffsteile, Outfits) werden verdient, nie gekauft.
- **Quiz zufällig:** Fragen kommen aus einem Pool (mindestens doppelt so groß wie die gezeigte Anzahl). Auswahl, Reihenfolge der Fragen und Reihenfolge der Antworten werden bei jedem Durchgang neu gemischt. Dieselbe Zusammenstellung nie zweimal hintereinander. Details in `INSELN.md`, Abschnitt Quiz-Regeln.
- **Tempo:** Standard sind 2 neue Stationen pro Woche (zum Beispiel montags und donnerstags freigeschaltet). Eltern können das Tempo im Leuchtturm ändern (2, 3, 4 pro Woche oder „freie Fahrt“, etwa in den Ferien). Im Kinderbereich wird das als Geschichte erzählt („Das Schiff braucht Wind, die nächste Station erreichst du am Donnerstag“), nie als Sperre mit Countdown. Bei 2 pro Woche dauert Stufe 1 etwa ein Jahr.
- **Ankerplatz mit Tauchgang nach jeder zweiten Station:** Nach jeweils 2 neuen Stationen wirft das Schiff Anker, und das Kind taucht in die Unterwasserwelt (Pflicht für den Insel-Abschluss, 5 bis 8 Minuten). Die Wiederholung der beiden Stationen steckt in Mini-Spielen unter Wasser, die sich abwechseln: Perlentauchen (richtige Antwort = Perle), Wrack erkunden (neue Anwendungsaufgabe, die beide Themen in einer Alltagssituation verbindet), Schatztruhe knacken (Antworten ergeben den Code), Fischschwarm sortieren (Zuordnen), Muscheln zählen (Rechnen). Jeder Tauchgang enthält 3 bis 4 Wiederholungsfragen und eine neue Anwendungsaufgabe. Funde (Perlen, Muscheln, Fundstücke aus Wracks) landen in der Unterwasser-Sammlung des Kindes, rein kosmetisch, nie kaufbar. Meister Taleron lebt in der Tiefe und ist bei Tauchgängen manchmal kurz im Hintergrund zu sehen, ohne zu prüfen. Auf jeder Insel nach Station 2, 4 und 6; nach Station 7 übernimmt die Abschlussprüfung diese Rolle. Die Schatzinsel hat keine Ankerplätze. Im Wochenrhythmus liegt der Ankerplatz am Samstag, damit Stufe 1 bei 2 Stationen pro Woche weiterhin etwa ein Jahr dauert.
- **Wiederholung zu Beginn jeder Station:** Ab der zweiten Station beginnt jede Station mit „Weißt du noch?“: 2 kurze Fragen zur vorherigen Station (gelegentlich aus früheren Inseln). Unter 1 Minute, zählt in den Wiederholungsplan, keine Strafe bei falschen Antworten.
- **Wiederholung (Kontrollfahrt):** An Tagen ohne neue Station gibt es kurze Wiederholungen (2 bis 3 Minuten, 3 bis 5 Fragen zu früheren Stationen). Zeitplan je Frage: etwa nach 1 Tag, 1 Woche, 1 Monat. Falsch beantwortete Fragen kommen früher wieder, sicher gewusste seltener. Immer freiwillig, nie Voraussetzung für neue Stationen, mit Seemeilen und Fahrtwind belohnt.
- **Begegnungen auf See:** Wiederholungen erscheinen als Begegnungen auf der Karte, nicht als nüchternes Quiz. Beispiele: Meister Taleron (das freundliche Seeungeheuer) taucht auf und lässt das Schiff nach 3 Rätselfragen passieren, ein Händlerschiff fragt nach Preisen, ein Fischerboot braucht Hilfe beim Rechnen, das Angeber-Schiff des Pfaus prahlt und das Kind entlarvt ihn, Tala hat etwas vergessen und das Kind hilft. Falsche Antworten haben keine Strafe: Die Figur erklärt die Lösung, das Kind darf es gleich noch einmal versuchen. Das Seeungeheuer ist freundlich und nicht gruselig.
- **Wunschflasche:** Das Kind kann einen Wunsch in eine Wunschflasche legen (Titel, optional Preis). Nach 1 Tag bei kleinen und 7 Tagen bei großen Wünschen fragt die App, ob es den Wunsch noch will. Dann kann es ihn verwerfen oder in einen Wunschschatz umwandeln. Eingeführt auf der Wunschinsel, danach dauerhaft in der Schatztruhe verfügbar.
- **Urkunde:** Nach der Schatzinsel steht im Leuchtturm eine Urkunde „Finanzführerschein Stufe 1“ mit Spitzname und Datum als PDF zum Herunterladen bereit.
- **Nebel:** Inseln, deren Inhalte noch nicht veröffentlicht sind, liegen auf der Karte im Nebel („Diese Insel taucht bald auf“). Erreicht ein Kind eine Insel im Nebel, gibt es Kontrollfahrten, Tauchgänge und Spiele statt einer Fehlermeldung. So kann Stufe 1 mit den Inseln 1 bis 3 starten und die weiteren Inseln werden laufend nachgeliefert.
- **Abschlussprüfungen mit Rückblick:** Ab Insel 2 stammen 2 der 10 Prüfungsfragen von früheren Inseln. Die Schatzinsel enthält eine große Wiederholung über alle Inseln.
- **Meister Talerons Prüfung:** Am Ende jeder Inselgruppe (nach Insel 4, 8 und 12) wartet Meister Taleron mit einer großen Wiederholung über die ganze Gruppe (etwa 10 Minuten, 12 Fragen aus allen Inseln der Gruppe). Bestehen ist keine Voraussetzung für die nächste Insel, bringt aber einen besonderen Orden. Seine letzte Prüfung findet auf der Schatzinsel statt.
- **Lernstand für Eltern:** Der Leuchtturm zeigt pro Thema, was das Kind sicher kann und wo es noch wackelt (aus den Wiederholungen berechnet).
- **Kein Druck:** keine Countdown-Timer, keine Zufallsboxen, keine Kauf-Pop-ups. Fahrtwind (Serie) mit Pausenfunktion.
- **Abo-Rechte:** Was freigeschaltet ist, hängt am Eltern-Konto, nicht am Kind. Gratis: Hafen und Tauschinsel, ein Kinder-Profil, Aufgaben und Schatztruhe in der Basisversion.

---

## 9. Datenschutz und Recht

- Hosting und Datenverarbeitung in der EU.
- So wenige Kinderdaten wie möglich. Kein Klarname, keine Adresse, kein Standort.
- Einwilligung der Eltern bei der Registrierung, mit Zeitstempel gespeichert.
- Fotos von Aufgaben nur freiwillig, privat gespeichert und nur für die eigenen Eltern sichtbar.
- Hinweis „keine Finanzberatung“ in App und Website.
- Regeln von Apple und Google für Kinder-Apps einhalten (Eltern-Sperre, keine Drittanbieter-Werbung).
- Impressum, Datenschutzerklärung und AGB vor dem Start rechtlich prüfen lassen.

---

## 10. Adminbereich

Eine eigene Webseite nur für Marc (und später sein Team), getrennt von der Kinder- und Eltern-App.

### Zugang und Sicherheit
- Eigene Web-App unter einer separaten Adresse (zum Beispiel `admin.` vor der Domain), nicht in der Store-App enthalten.
- Anmeldung nur für Konten in `admins`, immer mit Zwei-Faktor-Anmeldung.
- Rollen: `owner` (alles), `editor` (nur Inhalte), `support` (Konten einsehen im Supportfall).
- Admin-Rechte werden in der Datenbank per Row Level Security geprüft, nie nur in der Oberfläche.
- Alle Schreibzugriffe mit Schlüsseln, die nur auf dem Server liegen. Der Admin-Schlüssel kommt nie in eine App.

### Funktionen
1. **Inhalte pflegen:** Inseln, Stationen, Quizfragen, Videos und Kombüsen-Fragen anlegen und bearbeiten. Ablauf: Entwurf → Vorschau so, wie das Kind es sieht → Veröffentlichen. Frühere Fassungen bleiben erhalten.
2. **Kartenansicht:** Inseln auf der Karte platzieren (Position, Hauptroute, Nebeninsel, Event-Insel), Bonus-Stationen (Flaschenpost) hinzufügen. Pflichtstationen einer veröffentlichten Insel können nicht nachträglich hinzugefügt werden (Regel aus Abschnitt 8).
3. **Expeditionen:** Start- und Enddatum, zugehörige Event-Inseln.
4. **Statistiken:** Familien, aktive Kinder, zahlende Abos, Rückkehr nach 1 und 4 Wochen, Abbruchquote pro Station, beliebteste und schwierigste Quizfragen. Nur zusammengefasste Zahlen, keine Einzelprofile von Kindern.
5. **Support:** Eltern-Konto per E-Mail suchen, Abo-Status prüfen, Konto auf Wunsch löschen. Jeder Zugriff braucht einen Grund und landet im `admin_audit_log`.

### Neue Inhalte nach dem Start ergänzen
Ablauf für jede Ergänzung: Entwurf anlegen → in der Testumgebung durchspielen → fachlich prüfen → Status `review` → Veröffentlichen, sofort oder zu einem geplanten Datum (`publish_at`).

| Art | Was es ist | Braucht ein App-Update? |
| --- | --- | --- |
| Flaschenpost | einzelne Bonus-Station an einer bestehenden Insel | nein |
| Neue Fragen, Tauchgang-Aufgaben, Kombüsen-Fragen | Ergänzung bestehender Pools | nein |
| Nebeninsel | kleine Insel neben der Hauptroute mit eigenen Stationen | nein |
| Expedition | zeitlich begrenzte Event-Insel (zum Beispiel Weihnachten, Ferien) | nein |
| Neue Begegnung mit bekannter Spielart | neue Figur oder neues Schiff mit vorhandenem Spieltyp | nein |
| Neue Spielart (neues Mini-Spiel, neuer Tauchgang-Typ) | neuer Code | ja |

Regeln:
- Neue Stationen an veröffentlichten Inseln sind immer Bonus (`is_required = false`) und öffnen keine abgeschlossene Insel (Abschnitt 8).
- Neue Inhalte erscheinen im Kinderbereich mit einem Hinweis auf der Karte (Flaschenpost treibt an, Nebeninsel taucht aus dem Nebel auf). Eltern sehen im Leuchtturm „Neue Inhalte“. Keine Push-Nachrichten an Kinder.
- Bearbeitungen veröffentlichter Inhalte werden in `content_versions` gesichert. Pflichtstationen und Prüfungsfragen veröffentlichter Inseln dürfen korrigiert, aber nicht entfernt werden.
- Die App unterstützt von Anfang an alle Spielarten über einen festen Typ pro Station, damit neue Inhalte meist nur Daten sind.
- Felder `publish_at` (geplante Veröffentlichung) bei `islands`, `stations` und `expeditions`.

### Ausbaustufen
- **MVP:** Inhalte über die eingebaute Tabellenansicht von Supabase pflegen (nur Testumgebung frei bearbeiten, Live nur über geprüfte Importe), dazu eine kleine Statistik-Seite.
- **Danach:** eigener Adminbereich mit Formularen, Vorschau und Statistiken wie oben beschrieben.

---

## 11. Grafiken, Animationen und Inhalte

### Grundsatz
Die App muss jederzeit testbar sein, auch wenn Grafiken, Animationen und Filme noch fehlen. Fehlende Dateien werden durch Platzhalter ersetzt, nie durch einen Absturz.

### Bildschirmformat
- **Smartphone: nur Hochformat (entschieden).** Alle Bildschirme, Stationen, Spiele und Tauchgänge sind für Hochformat gebaut und mit einer Hand bedienbar. Auch Spiele mit Zeitstrahl oder Reihen werden senkrecht gestaltet. Eine Querformat-Ausnahme für ein einzelnes Spiel nur, wenn Tests zeigen, dass es quer deutlich besser funktioniert, und nur nach Rücksprache mit Marc.
- **Inselkarte:** scrollt senkrecht, die Route führt von unten (Hafen) nach oben (Schatzinsel).
- **Tablet:** Hochformat als Hauptlayout, Querformat zusätzlich unterstützt (Inhalt zentriert mit maritimem Hintergrund links und rechts, Karte und Elternbereich nutzen die Breite). Vor dem Start die aktuellen Vorgaben von Apple für iPad-Apps zu Ausrichtungen prüfen.
- **Filme (Intro, Ankunftsfilme):** im Format 9:16 (Hochformat), damit sie auf dem Handy den ganzen Bildschirm füllen und sich auch für Reels und TikTok verwenden lassen. Auf Tablets zentriert mit Hintergrund.
- **Mindestgrößen:** Antippbare Elemente mindestens 48 × 48 Punkte, Texte gut lesbar für 10-Jährige.

### Was im Code entsteht (baut Claude Code)
- Bewegung auf der Karte: Schiff fährt zur nächsten Insel, Schloss springt auf, Insel leuchtet.
- Effekte: Taler fliegen in die Schatztruhe, Konfetti beim neuen Rang, Übergänge zwischen Bildschirmen.
- Diese Animationen nutzen Flutter selbst und brauchen keine fremden Dateien.

### Was von außen kommt (Illustration, Animation, Ton)
| Was | Format | Ort |
| --- | --- | --- |
| Talo und Tala, beweglich | Einzelbilder je Zustand (PNG, freigestellt: idle, talk, happy, sad, wave), Bewegung im Code; Rive entfällt (3D-Look, siehe Abschnitt 16) | `assets/images/` |
| Kleine Effekte (Flaschenpost, Möwe) | Lottie (`.json`) | `assets/lottie/` |
| Karte, Inseln, Hintergründe | PNG im 3D-Animationsfilm-Look (Liste und Gemini-Texte in `BILDER.md`) | `assets/images/` |
| Ankunftsfilme und Intro | MP4 (H.264), 9:16 Hochformat, kurz | Supabase Storage, Pfad in der Datenbank |
| Sprecherstimmen, Musik, Sounds | AAC oder MP3 | Supabase Storage oder `assets/audio/` |

### Platzhalter-Regeln
- Jede Grafik, Animation und jeder Film wird über einen festen Schlüssel geladen (zum Beispiel `character.talo`, `island.hafen.background`, `video.intro`). Eine zentrale Liste (`asset_manifest`) ordnet Schlüssel und Datei zu.
- Fehlt eine Datei, zeigt die App einen gut erkennbaren Platzhalter: farbige Form mit Namen (zum Beispiel ein oranger Kreis „Talo“), bei Filmen ein Standbild mit Text „Film folgt“ und Weiter-Button.
- Austausch = neue Datei hochladen und im Manifest eintragen. Kein Umbau im Code.
- Alle Lizenzen und Nutzungsrechte der Dateien werden in `ASSETS_LICENSES.md` festgehalten (Urheber, Datum, Rechte).

### Lerninhalte (Missionen, Stationen, Quizfragen)
- `INSELN.md` enthält alle 15 Inseln mit Geschichte, Bewohnern, Ankunftsfilm, 7 Stationen, Tauchgängen, Prüfungsfragen, Aufträgen und Kombüsen-Fragen. Claude Code übernimmt diese Inhalte als Seed-Daten.
- Claude Code ergänzt daraus die noch fehlenden Teile als **Entwürfe**: ausformulierte Stationstexte und Dialoge von Talo und Tala, Stations-Check-Pools (mindestens 6 Fragen je Station) und Tauchgang-Fragen, jeweils im Stil der vorhandenen Fragen.
- Alle Entwürfe haben `status = draft` und werden als Seed-Daten in der Testumgebung geladen, damit Marc die App sofort durchspielen kann.
- Vor dem Veröffentlichen prüft Marc jeden Inhalt, fachliche Aussagen werden zusätzlich von einer Fachperson geprüft. Keine Zahlen, Gesetze oder Steuerregeln ohne Quelle.
- Inhalte sind neutral: Konzepte erklären, keine Produkte, Banken oder Anbieter empfehlen.

---

## 12. Reihenfolge für das MVP

Jeder Schritt ist erst fertig, wenn Marc ihn auf einem echten Gerät ausprobiert hat.

1. **Projekt aufsetzen:** Flutter-Projekt, Supabase (Test und Live getrennt), Git, Theme, Übersetzungsdateien, Asset-Manifest mit Platzhaltern.
2. **Konten und Rollen:** Eltern-Registrierung mit Einwilligung, Kinder-Profil, Anmeldung des Kindes per Code, Eltern-Sperre, Row Level Security.
3. **Intro:** Intro-Film, Avatar wählen, Schiff taufen, erste Station, erster Wunschschatz, Karte öffnet sich.
4. **Inselkarte und Lernen:** Karte mit Hafen, Tauschinsel und Wunschinsel komplett, weitere Inseln sichtbar mit Schloss. Stationen vom Typ Video und Quiz. Dazu Seed-Daten für alle 15 Inseln aus `INSELN.md` (Inseln 4 bis 15 zunächst im Nebel, Abschnitt 8).
5. **Budget und Aufgaben:** Heuer, Aufträge mit Bestätigung durch die Eltern, drei Truhen, Wunschschätze.
6. **Seemeilen, Ränge, Orden, Tempo und Wiederholung:** zentrales Fortschrittssystem für alle Säulen, Freischalten nach Tempo (2 pro Woche), Kontrollfahrten mit Zeitplan, erste Begegnung (Seeungeheuer) mit Platzhalter-Grafik.
7. **Mini-Spiele und Tauchgang:** ein bis zwei Spiele auf den Inseln (zum Beispiel Sparziel-Reise, Marktplatz), dazu der Ankerplatz mit zwei Tauchgang-Spielen (Perlentauchen, Wrack erkunden) und der Unterwasser-Sammlung. Nebel für noch nicht veröffentlichte Inseln.
8. **Elternbereich (Leuchtturm):** Fortschritt pro Kind, Lernstand pro Thema, Tempo einstellen, offene Aufgaben, Kombüsen-Fragen.
9. **Abo:** RevenueCat, Gratis- und Premium-Rechte.
10. **Admin, Grundversion:** Admin-Rolle mit Zwei-Faktor-Anmeldung, Inhalte mit Status Entwurf/Veröffentlicht, Pflege über Supabase, einfache Statistik-Seite, Audit-Log.
11. **Beta-Vorbereitung:** Fehler beheben, datenschutzfreundliche Messung (Rückkehr nach 1 und 4 Wochen).
12. **Nach der Beta:** eigener Adminbereich mit Formularen, Vorschau, Kartenansicht und Statistiken (Abschnitt 10).

Hinweis: Die Admin-Tabellen und der Inhalts-Status werden schon in Schritt 1 und 2 angelegt, damit später nichts umgebaut werden muss.

---

## 13. Inselkarte Stufe 1 (Hauptroute)

Die ausführlichen Inhalte jeder Insel (Layout, Stationen, Effekte, Aufträge) stehen in `INSELN.md`. Diese Datei ist die Vorlage für Seed-Daten und Bildschirme.

| Nr. | Slug | Insel | Thema |
| --- | --- | --- | --- |
| 1 | `hafen` | Hafen | Start und Was ist Geld? |
| 2 | `tauschinsel` | Tauschinsel | Tauschen und Wert |
| 3 | `wunschinsel` | Wunschinsel | Brauchen oder Wollen |
| 4 | `spar-insel` | Spar-Insel | Sparen |
| 5 | `taschengeld-bucht` | Taschengeld-Bucht | Taschengeld einteilen |
| 6 | `marktinsel` | Marktinsel | Einkaufen |
| 7 | `werbe-riff` | Werbe-Riff | Werbung durchschauen |
| 8 | `verdienst-insel` | Verdienst-Insel | Geld verdienen |
| 9 | `bank-insel` | Bank-Insel | Bank und Konto |
| 10 | `zins-insel` | Zins-Insel | Zinsen und Inflation |
| 11 | `leih-lagune` | Leih-Lagune | Leihen und Schulden |
| 12 | `sicherheits-festung` | Sicherheits-Festung | Sicher mit Geld |
| 13 | `risiko-klippen` | Risiko-Klippen | Risiko und Vorsorge |
| 14 | `zukunftsinsel` | Zukunftsinsel | Planen und Investieren als Idee |
| 15 | `schatzinsel` | Schatzinsel | Abschluss und Goldene Schatzkarte |

Jede Insel: Ankunftsfilm, 7 Stationen mit 3 Ankerplätzen dazwischen (Schatzinsel: 4 Stationen, keine Ankerplätze), Abschlussprüfung. Jede Station dauert mindestens 5 und höchstens 10 Minuten. Im MVP sind die Inseln 1 bis 3 komplett gefüllt.

---

## 14. Weitere Projektdateien

- `INSELN.md` – Inhalte jeder Insel, Quiz-Regeln, Tauchgänge
- `MARKETING.md` – Inhaltskalender, Ankündigungen, E-Mail-Marketing (für Claude Code nur Abschnitt 5 relevant)
- `FIGUREN.md` – alle Figuren, Stil und Illustrations-Briefing (für Platzhalter-Namen und Asset-Schlüssel relevant)
- `BILDER.md` – Bildliste für die Karte mit den Texten für Gemini

---

## 15. Offene Punkte

- Rolle von Tala als Zahlmeisterin ist ein Vorschlag.
- Aussehen von Meister Taleron: erledigt, Bild von Marc (`character.taleron`, Abschnitt 16).
- Preis: Startannahme 4,99 bis 6,99 € pro Monat oder 39 bis 59 € pro Jahr pro Familie, noch zu testen.
- Bilder von Talo, Tala und der Karte: erledigt (Stand in `BILDER.md`). Wo noch ein Bild fehlt, zeigt die App weiter den Platzhalter.
- Technik-Stack ist ein Vorschlag und wird vor Projektstart bestätigt.

---

## 16. Umsetzungsentscheidungen (laufend ergänzt)

**Schritt 1 (Projekt aufsetzen), umgesetzt am 09.10.2026:**
- Das Projekt liegt im Ordner `taleria/` des Repositorys. Alle Befehle laufen in diesem Ordner.
- Zugangsdaten: `env/test.json` und `env/live.json` (nicht im Git, Vorlagen `env/*.example.json`), Start mit `flutter run --dart-define-from-file=env/test.json`. Ohne Datei startet die App in der Testumgebung ohne Server. Die Live-Umgebung startet nie ohne Server-Daten.
- In die App kommt nur der öffentliche `publishable key` von Supabase. Der `secret key` bleibt auf dem Server.
- Kein Zusatzpaket für App-Zustand (State Management): `AppScope` reicht für Schritt 1. Vor Einführung eines Pakets mit Marc sprechen.
- Bilder liegen unter `assets/images/<Asset-Schlüssel>.png`. Rive, Lottie, Filme und Ton zeigen bis zur ersten echten Datei immer den Platzhalter; das passende Paket kommt dann dazu.
- `is_published` ist in der Datenbank aus `status` abgeleitet (nur eine Wahrheit). Ob Kinder einen Inhalt sehen, entscheidet `is_content_visible(status, publish_at)`.
- Admin-Rechte gelten in der Datenbank nur mit Zwei-Faktor-Anmeldung (`aal2`). Das Audit-Log ist unveränderlich.
- Regeln aus Abschnitt 8 und 10 (Pflichtstationen veröffentlichter Inseln, Prüfungsfragen, frühere Fassungen) erzwingt die Datenbank per Trigger, getestet in `supabase/sql_tests/`.

**Schritt 2 (Konten und Rollen), umgesetzt am 09.10.2026:**
- Kinder-Geräte melden sich mit einer **anonymen Supabase-Sitzung** an und lösen dann einen Code ein (`redeem_child_login_code`). Die Zuordnung steht in `child_devices`; per Row Level Security sieht die Sitzung nur dieses eine Kinder-Profil. In Supabase müssen anonyme Anmeldungen eingeschaltet sein.
- Anmelde-Code: 8 Zeichen ohne I, L, O, 0, 1, 15 Minuten gültig, einmal nutzbar; ein neuer Code macht den alten ungültig. QR-Code folgt später (braucht Kamera-Paket, vorher mit Marc sprechen).
- Registrierung: Die App schickt `taleria_role`, `consent_version`, `marketing_consent` und `locale` mit; der Trigger `handle_new_auth_user` legt `parents` mit Zeitstempel an. Ohne `consent_version` keine Registrierung. Die Fassung des Einwilligungstextes steht in `consentVersion` (`lib/services/session_controller.dart`) und muss bei jeder Textänderung hochgezählt werden.
- Eltern-PIN: 4 bis 6 Ziffern, keine gleichen Ziffern und keine Reihen (1111, 1234, 9876). Gespeichert als bcrypt-Prüfsumme, geprüft nur in der Datenbank (`verify_parent_pin`). Nach 5 Fehlversuchen 5 Minuten gesperrt. Die Rechenaufgabe als Alternative ist nicht gebaut; die PIN erfüllt die Eltern-Sperre.
- Eltern-Sperre im Ablauf: Frische Anmeldung mit Passwort öffnet den Leuchtturm. Bei jedem App-Start und nach 5 Minuten im Hintergrund fragt die App nach der PIN. PIN vergessen = mit Passwort neu anmelden.
- „Gerät an Kind übergeben“: Auf dem Eltern-Gerät kann ein Kind spielen (`active_child_id` in `shared_preferences`). Die Sitzung bleibt die der Eltern; die PIN schützt den Leuchtturm.
- Löschen von Kinder-Profilen und Konten nur über Datenbank-Funktionen (`delete_child`, `delete_my_account`), damit auch die Kinder-Geräte abgemeldet werden. Admin-Konten können sich darüber nicht löschen.
- Zusätzliches Paket: `shared_preferences` (vom Flutter-Team, war schon über `supabase_flutter` dabei).
- Offen für später: Passwort zurücksetzen (braucht einen Link zurück in die App), Newsletter-Bestätigung per Double-Opt-in, Schutz vor massenhaften anonymen Anmeldungen (Captcha), Gratis-Grenze von einem Kinder-Profil (kommt mit dem Abo in Schritt 9).

**Schritt 3 (Intro), umgesetzt am 09.10.2026:**
- Das Intro ist Station 1 des Hafens („Willkommen an Bord“): Intro-Film (Platzhalter) → Talo und Tala erzählen → „Willst du in unsere Crew?“ → Avatar → Schiffstaufe → Rundgang (Karte, Schatztruhe, Logbuch) → erster Wunschschatz (darf übersprungen werden) → Abschluss mit Rang Schiffsjunge und 50 Seemeilen → die Karte rollt sich auf.
- Jeder Abschnitt wird sofort gespeichert. Kinder-Geräte ändern ihr Profil nur über `update_child_look()`, den Abschluss bucht `complete_onboarding()` (Seemeilen nur einmal, eindeutiger Eintrag in `xp_events`). `can_act_for_child()` prüft, ob Eltern oder das Kinder-Gerät handeln dürfen.
- Die 50 Seemeilen stehen bis Schritt 4 als Wert in `complete_onboarding()`. Sobald die Stationen als Inhalte in der Datenbank liegen, kommt der Wert aus `stations.xp_reward`.
- Neue Tabellen: `savings_goals` (Kind darf anlegen, Ändern und Löschen folgen in Schritt 5) und `xp_events` (nur Server-Funktionen schreiben).
- Avatar-Baukasten: Mensch mit 6 Hautfarben, 5 Frisuren, 5 Haarfarben, 6 Jackenfarben, 4 Kopfbedeckungen. Gespeichert als kleines JSON mit Formatversion. Bis die Rive-Datei `character.avatar` da ist, zeichnet die App den Avatar aus einfachen Formen.
- Alle Sätze von Talo und Tala sind Entwürfe und stehen in `lib/l10n/app_de.arb` (Beschreibung „ENTWURF“).
- Auf dem Eltern-Gerät hat auch das Intro den Leuchtturm-Knopf (PIN-Abfrage), auf dem Kinder-Gerät nicht.
- Die Karte zeigt bis Schritt 4 nur Hintergrund, Schiff und Hafen als Platzhalter.

**Schritt 4a (Tier-Avatare, Namen aus der Datenbank), umgesetzt am 09.10.2026:**
- Entschieden mit Marc: Der Avatar darf auch ein Tier sein (Katze, Hund, Bär, Hase, Maus). Tiere haben Fellfarbe statt Hautfarbe und keine Frisur; Jacke und Kopfbedeckung gibt es für alle. Ältere Avatare ohne Angabe sind Menschen.
- Entschieden mit Marc: Namen von Inseln und Expeditionen stehen in der Datenbank (`title` statt `title_key`). Das gilt auch für spätere Inhalte wie Begegnungen und Sammelstücke.

**Schritt 4b (Fortschritt in der Datenbank), umgesetzt am 09.10.2026:**
- **Inhalts-Vorschau:** In der Testumgebung steht in `app_settings` der Eintrag `content_preview = true`. Dann sehen Kinder auch Inhalte mit Status `draft` und `review`, damit Marc Entwürfe durchspielen kann. In der Live-Datenbank gibt es diesen Eintrag nie.
- **Nebel:** `map_islands(stage)` liefert alle Inseln der Hauptroute und Nebeninseln, auch die ohne sichtbare Inhalte (nur Name und Position, `has_content = false`). Stationen und Fragen von Inseln im Nebel bleiben unsichtbar.
- **Abgeben:** `submit_station(child, station, answers)` prüft auf dem Server, ob die Station offen ist, ob die Fragen zur Station gehören und wie viele richtig sind. Die App schickt die Antwort als Stelle in der gespeicherten Antwortliste (vor dem Mischen). Seemeilen (`stations.xp_reward`) gibt es pro Station nur einmal.
- **Stations-Check:** erledigt nach dem Durchgang, auch mit Fehlern (INSELN.md: Falsche Antworten kosten nichts). Anzahl der Fragen steht in `content.quiz.show`.
- **Abschlussprüfung:** `content.exam.show` Fragen der Insel plus `content.exam.review` Rückblick-Fragen aus Prüfungen früherer Inseln (ab Insel 2), bestanden ab `content.exam.pass`. Für Stufe 1: 8 + 2 = 10 Fragen, bestanden ab 8 (CLAUDE.md Abschnitt 8: „2 der 10 Prüfungsfragen von früheren Inseln“).
- **Freischalten:** Erste Insel der Hauptroute offen, jede weitere nach Abschluss der vorherigen. Pflichtstationen der Reihe nach, Bonus-Stationen sobald die Insel offen ist. Die Intro-Station (`content.kind = onboarding`) gilt als erledigt, sobald das Intro abgeschlossen ist.
- **Insel-Abschluss:** Sobald alle sichtbaren Pflichtstationen erledigt sind, schreibt der Server `island_completions`. Der Eintrag lässt sich nicht mehr ändern.

**Schritt 4c (Inhalte als Seed-Daten), umgesetzt am 09.10.2026:**
- Quelle der Inhalte sind Dateien in `content/stufe1/` (eine pro Insel, deutsche Feldnamen, für Marc lesbar). `dart run tool/build_seed.dart` prüft sie und erzeugt `supabase/seed.sql`. Ein Test schlägt fehl, wenn die Seed-Datei nicht zur Inhaltsdatei passt.
- Automatisch geprüft: genau 3 Antworten pro Frage mit Erklärung, Pool mindestens doppelt so groß wie die gezeigten Fragen, mindestens 6 Fragen pro Stations-Check, jede Prüfung deckt alle Stationen ab, Rückblick erst ab Insel 2, nur bekannte Figuren und Filme aus dem Asset-Manifest.
- Hafen, Tauschinsel und Wunschinsel sind komplett: Szenen, Erklärungen und Abschlüsse von Talo, Tala und den Inselbewohnern, 6 Fragen pro Stations-Check (Entwürfe von Claude) und die Prüfungsfragen aus INSELN.md. Inseln 4 bis 15 haben nur Name, Position und Gruppe (Nebel).
- Widerspruch in INSELN.md aufgelöst: „Pool mindestens doppelt so groß“ und „Quiz-Station 5 aus mindestens 8“ passen nicht zusammen. Der Quiz-Pool von Hafen Station 2 hat deshalb 10 Fragen (2 neue Entwürfe).
- Stationen, deren Mini-Spiel erst in Schritt 7 kommt, sind trotzdem spielbar: Szene, Erklärung, Platzhalter für das Spiel, Stations-Check.
- Ankerplätze (Tauchgänge) werden in Schritt 7 als Pflichtstationen ergänzt. Das ist erlaubt, weil die Inseln bis dahin Entwürfe sind.
- Alle Inhalte haben `status = draft`. Die Seed-Datei schaltet in der Testumgebung die Inhalts-Vorschau ein. **Die Seed-Datei nie in die Live-Datenbank einspielen.**

**Schritt 4d (Inselkarte und Lernen in der App), umgesetzt am 09.10.2026:**
- **Karte:** scrollt senkrecht, startet unten beim Hafen. Offene Inseln leuchten, gesperrte tragen ein Schloss, Inseln im Nebel zeigen ihren Namen mit Fragezeichen („Diese Insel taucht bald auf“). Das Schiff liegt an der ersten offenen Insel der Hauptroute.
- **Insel:** Beim ersten Besuch läuft die Ankunft (Film-Platzhalter und Szene), gemerkt pro Gerät. Beim Hafen entfällt sie, weil sein Ankunftsfilm der Intro-Film ist. Danach die Stationen der Reihe nach, die Intro-Station ist erledigt.
- **Station:** „Weißt du noch?“ (2 Fragen der Station davor, ab der dritten Station des Hafens, ohne Wertung) → Film (Platzhalter) → Szene → Erklärung → Spiel (Platzhalter bis Schritt 7) → Stations-Check → Ergebnis mit Seemeilen und Abschlusssatz.
- **Abschlussprüfung:** Szene → Fragen → Ergebnis. Nicht bestanden: neue Auswahl ohne Strafe. Bestanden und Insel fertig: „Kartenstück gefunden!“, Name des Ordens, zurück zur Karte, die nächste Insel ist offen. Orden und Schatzkarten-Effekt als Animation kommen in Schritt 6.
- **Quiz in der App:** Auswahl und Reihenfolge zufällig, Antworten gemischt, die letzte Zusammenstellung je Station wird auf dem Gerät gemerkt und nie direkt wiederholt. Nach jeder Antwort: richtig oder nicht und die Erklärung. Die App schickt nur die Antworten, der Server wertet aus.
- **Freischalten in der App** folgt denselben Regeln wie der Server (`lib/domain/progress_logic.dart`), damit die Karte stimmt, auch bevor der Server gefragt wird.
- Die Aufwärmfragen („Weißt du noch?“) fließen ab Schritt 6 in den Wiederholungsplan.

**Schritt 5a (Budget und Aufgaben in der Datenbank), umgesetzt am 09.10.2026:**
- **Heuer:** Eltern legen Betrag und Rhythmus (wöchentlich, monatlich) mit `set_allowance()` fest. Die Heuer landet in der Bordkasse. `process_due_allowances()` bucht beim Öffnen der App alle fälligen Zahlungen nach, jede nur einmal (eindeutige Referenz pro Zahltag). Ein Zeitplan auf dem Server (pg_cron) ist dafür nicht nötig.
- **Aufträge:** Eltern legen sie an (Belohnung bis 100 € oder Pflicht ohne Geld). Das Kind meldet mit `submit_task()`, nur Eltern bestätigen oder lehnen mit `review_task()` ab (mit Nachricht). Erst die Bestätigung schreibt die Belohnung in die Bordkasse, genau einmal. Bestätigte Aufträge bleiben als Beleg erhalten.
- **Truhen:** Umbuchen zwischen den eigenen Truhen (`move_between_pots`), Ausgaben aus der Bordkasse und Geschenke aus der Glückstruhe (`record_spending`), Korrekturen nur durch Eltern (`book_manual`). Keine Truhe geht ins Minus; jede Buchung sperrt kurz das Kinder-Profil, damit gleichzeitige Buchungen nicht doppelt abbuchen.
- **Wunschschätze:** Offene darf das Kind ändern und löschen. Einlösen nur mit `redeem_savings_goal()`, wenn genug in der Schatztruhe ist.
- **Kassenbuch:** nur Server-Funktionen schreiben, Einträge sind unveränderlich.
- Interne Hilfsfunktionen ohne Rechteprüfung (`pot_balance`, `station_done`, `island_unlocked`, `station_unlocked`) sind für die App gesperrt.
- Verschoben: Fotos zu Aufträgen (braucht Kamera-Zugriff und ein Zusatzpaket, vorher mit Marc sprechen), automatische Aufteilung der Heuer auf die Truhen, Wunschflasche (kommt mit den Spielen der Wunschinsel).

**Schritt 5b (Budget und Aufgaben in der App), umgesetzt am 09.10.2026:**
- **Geld in der App:** Beträge werden als Euro mit Komma eingegeben („2,50“, auch „2.50“) und sofort in ganze Cent umgerechnet (`lib/domain/money.dart`). Höchstbetrag pro Eingabe 1.000 €. Angezeigt wird immer im deutschen Format („2,50 €“).
- **Kinderbereich:** Auf der Startseite gibt es „Schatztruhe“ und „Aufträge“ (mit Zahl der offenen Aufträge).
  - *Deine Truhen:* Bordkasse, Schatztruhe, Glückstruhe mit Stand. Umbuchen zwischen den Truhen, Ausgabe (aus der Bordkasse) oder Geschenk (aus der Glückstruhe) eintragen. Darunter Heuer, Wunschschätze mit Fortschrittsbalken (Einlösen, sobald genug in der Schatztruhe ist; Löschen solange offen) und das Kassenbuch.
  - *Aufträge:* getrennt nach Offen, „Wartet auf deine Eltern“ und Erledigt. „Erledigt!“ meldet einen Auftrag; abgelehnte zeigen die Nachricht der Eltern und „Nochmal melden“.
  - Hinweis im Kinderbereich: Alle Beträge sind virtuell, das echte Geld kommt von den Eltern.
- **Leuchtturm:** In der Kinderliste und auf der Kinderseite steht, wie viele Aufgaben auf Bestätigung warten. Die neue Seite „Taschengeld und Aufgaben“ hat: Aufgaben bestätigen, ablehnen (mit freiwilliger Nachricht) oder löschen, neue Aufgabe anlegen (mit Belohnung oder als Pflicht), Taschengeld festlegen, ändern oder beenden (Betrag, wöchentlich oder monatlich, Datum der ersten Zahlung), Kontostand der drei Truhen, Korrektur buchen (mit Minus ein Abzug) und das Kassenbuch.
- **Fällige Heuer** bucht die App beim Öffnen der Truhen oder der Elternseite nach (`process_due_allowances`).
- **Nicht genug Guthaben** wird schon in der App geprüft und vom Server noch einmal; die Meldung ist „So viel ist nicht in der Truhe.“
- Die Oberfläche benutzt im Kinderbereich die Kinderwörter (Aufträge, Truhen) und im Leuchtturm die Elternwörter (Aufgaben), wie im Glossar. Taschengeld heißt seit 10.10.2026 in beiden Bereichen „Taschengeld“.

**Schritt 6a (Fortschrittssystem in der Datenbank), umgesetzt am 09.10.2026:**
- **Alle Tage zählen in deutscher Zeit** (Europe/Berlin), auch Freigabetage, Wiederholungstermine und Fahrtwind-Wochen.
- **Ränge (Vorschlag, mit Marc abstimmen):** Schiffsjunge ab der ersten Seemeile (also nach dem Intro), Matrose ab 1.500 (etwa nach Insel 2), Bootsmann ab 4.000 (etwa nach Insel 4), Steuermann ab 8.000 (etwa nach Insel 8), Kapitän nur mit der Goldenen Schatzkarte (letzte Insel der Hauptroute abgeschlossen). Die Grenzen stehen in der Tabelle `ranks` und lassen sich ohne App-Update ändern. Der Rang wird immer aus den Seemeilen berechnet, nie gespeichert.
- **Orden:** Jede Insel mit Inhalt hat einen Orden (`orden` in der Inhaltsdatei, Bild `badge.<slug>`). Der Server verleiht ihn automatisch mit dem Insel-Abschluss (Trigger), genau einmal. Taleron-Siegel kommen mit Talerons Prüfungen nach Insel 4.
- **Tempo als Wind:** Jeder Freigabetag (Standard Montag und Donnerstag) bringt Wind für eine neue Pflichtstation. Nicht genutzter Wind sammelt sich höchstens für eine Woche (bei 2 pro Woche also 2). Ein neues Kind startet mit dem Wind einer Woche, damit es nach dem Intro gleich weiterspielen kann. Die Abschlussprüfung zählt wie eine Station; eine nicht bestandene Prüfung kostet keinen Wind. Wiederholen fertiger Stationen und Bonus-Stationen (Flaschenpost) kosten nie Wind.
- **Tempo einstellen** nur über `set_pace()` (Eltern): 2 (Mo, Do), 3 (Mo, Mi, Fr), 4 (Mo, Di, Do, Fr) oder freie Fahrt. Samstag bleibt frei für den Ankerplatz (Schritt 7). Eltern dürfen am Kinder-Profil direkt nur noch Spitzname, Geburtsjahr und Niveau ändern.
- **Wiederholungsplan:** Jede Antwort aus Stations-Checks, Prüfungen, „Weißt du noch?“ und Begegnungen landet in `question_reviews`. Richtig zum Termin: nächster Termin nach 1 Tag, 1 Woche, 1 Monat, danach alle 3 Monate. Falsch: am nächsten Tag wieder. Richtig vor dem Termin ändert den Plan nicht.
- **Begegnung auf See (Kontrollfahrt):** Sobald Wiederholungen fällig sind, taucht eine Begegnung auf (`next_encounter`). Fällige Fragen kommen zuerst, fehlende Plätze werden mit den nächsten Terminen aufgefüllt. Es zählt die erste Antwort je Frage; danach darf das Kind weiterprobieren, bis es stimmt. Seemeilen (Standard 20) gibt es einmal am Tag. Die erste Begegnung ist Meister Taleron mit 3 Rätseln (`content/begegnungen.json`, Entwurf). Er zeigt sich dabei nur halb und erzählt seine Geschichte erst nach Insel 4 (INSELN.md).
- **Fahrtwind (Vorschlag, mit Marc abstimmen):** zählt **Wochen** in Folge mit mindestens einer Station oder Begegnung, nicht Tage. So passt er zum Tempo von 2 Stationen pro Woche und macht keinen täglichen Druck. Er reißt erst nach einer ganzen Woche ohne Fahrt. Eltern können ihn pausieren (`set_streak_pause`, zum Beispiel in den Ferien); nach der Pause hat das Kind die laufende Woche Zeit, weiterzufahren.
- **`child_stats()`** liefert alles für die Startseite in einem Aufruf: Seemeilen, Rang und nächster Rang, Fahrtwind, Zahl der Orden, fällige Wiederholungen und den Wind mit dem nächsten Freigabetag.
- **`submit_station()`** meldet jetzt zusätzlich `rank_up` (neuer Rang), `badge` (Orden der Insel) und `wind_left`.

**Schritt 6b (Fortschrittssystem in der App), umgesetzt am 09.10.2026:**
- **Startseite des Kindes:** Karte mit Rang (Bild `rank.<code>`), Seemeilen, Balken bis zum nächsten Rang („Noch 650 Seemeilen bis Matrose“, vor Kapitän: „Finde die Goldene Schatzkarte“), Fahrtwind in Wochen. Darunter „Zur Karte“ und „Meine Orden“. Die Werte laden neu, wenn das Kind von der Karte zurückkommt.
- **Orden-Sammlung:** Verdiente Orden leuchten mit Datum, die anderen sind blass mit Schloss und „Noch nicht gefunden“. Die Namen sind sichtbar, damit das Kind weiß, was es noch entdecken kann.
- **Wind in der App:** Ohne Wind steht oben auf der Karte und auf der Insel „Das Schiff braucht Wind. Die nächste Station erreichst du am Donnerstag.“ und was das Kind bis dahin tun kann. Die nächste neue Station zeigt „Wartet auf Wind“ statt eines Schlosses. Kein Countdown, keine Uhrzeit.
- **Begegnung auf See:** Sind Wiederholungen fällig, taucht Meister Taleron neben dem Schiff auf der Karte auf (einmal, ohne Dauerbewegung). Beim ersten Mal stellt er sich vor, danach eine kurze Begrüßung. Nach einer falschen Antwort sagt er etwas Freundliches, die Erklärung erscheint, und „Nochmal versuchen“ mischt die Antworten neu. Danach: Ergebnis (erster Versuch), Seemeilen oder der Hinweis „einmal am Tag“, neuer Rang und Fahrtwind.
- **Feiern im Code (ohne fremde Dateien):** Schatzkarten-Effekt beim Insel-Abschluss (Kartenstück erscheint, leuchtet golden, Funken, etwa 3,5 Sekunden), danach springt der Orden hervor; beim neuen Rang springt das Rang-Abzeichen hervor. Bei „Bewegungen reduzieren“ im Gerät ist alles sofort da. Konfetti und Ton folgen später, wenn die Grafiken und Töne kommen.
- **„Weißt du noch?“** schickt die Antworten nach dem Aufwärmen an `record_answers()` (nur Wiederholungsplan, keine Wertung). Ein Fehler dabei stört das Kind nicht.
- **Leuchtturm:** Auf der Kinderseite die Karte „Tempo und Serie“ mit Level und Rang, Fortschritt in Seemeilen, Abzeichen, Serie, Tempo (2, 3, 4 oder Frei) und dem Schalter „Serie pausieren“ (Elternwörter laut Glossar).
- Die App prüft Wind und Freischalten vorab mit denselben Regeln wie der Server; der Server lehnt trotzdem ab, wenn kein Wind da ist (Meldung „Das Schiff braucht Wind.“).

**Schritt 7a (Tauchgänge, Sammlung und Spiel-Daten in Datenbank und Inhalten), umgesetzt am 10.10.2026:**
- **Ankerplätze sind Pflichtstationen** (`type = review_stop`) nach Station 2, 4 und 6 jeder Insel. Damit sie zwischen die Stationen passen, ist die Reihenfolge jetzt Stationsnummer × 10 (Station 3 = 30), Ankerplätze liegen dazwischen (25, 45, 65). Die angezeigte Nummer steht in `content.number`. Die IDs der Stationen bleiben gleich, Fortschritt geht nicht verloren.
- **Tauchgang:** Fragen nur aus den Stationen seit dem letzten Ankerplatz (ohne Prüfung), Anzahl in `content.dive.questions` (Inseln 1 bis 3: 4). Erledigt nach dem Durchgang, Fehler kosten nichts, 50 Seemeilen einmalig. Die Wrack-Aufgabe (`content.dive.wreck`) wertet die App ohne Punkte: Das Kind probiert, bis es stimmt, und bekommt die Erklärung.
- **Ankerplätze brauchen keinen Wind.** Sie gehören zu den beiden Stationen davor. Damit bleibt es bei etwa einem Jahr für Stufe 1, ohne dass das Kind bis Samstag warten muss. Der Samstag aus Abschnitt 8 ist damit eine Empfehlung, keine Sperre.
- **Unterwasser-Sammlung:** Jeder Ankerplatz hat einen Fund (`collectibles`, Fundstück aus dem Wrack), den das Kind beim ersten Tauchgang bekommt. **Perlen** sind die richtigen Antworten im besten Tauchgang je Ankerplatz (höchstens 4 pro Ankerplatz). `child_stats()` liefert `pearls` und `finds`.
- **Tauch-Spielarten:** In den Inhaltsdateien steht für jeden Tauchgang die Spielart aus INSELN.md (Perlentauchen, Schatztruhe knacken, Fischschwarm sortieren, Muscheln zählen). Gebaut sind in Schritt 7 Perlentauchen und das Wrack; die anderen Spielarten zeigen bis zu ihrem Bau das Perlentauchen.
- **Mini-Spiele als Daten:** zwei Spielarten mit eigener Mechanik, „Sortieren“ (`sort`, Dinge in 2 bis 4 Körbe, Dinge „dazwischen“ passen in jeden Korb und haben einen Hinweis) und „Reihenfolge“ (`order`, 3 bis 7 Dinge von … bis …). Damit spielen 6 Stationen ein echtes Spiel: Hafen 3 (Zeitstrahl), 5 (Berufe zuordnen), 7 (Preise schätzen), Tauschinsel 7 (faire Tausche), Wunschinsel 1 (zwei Körbe), 4 (Gruppendruck). Die anderen Spiele zeigen weiter den Platzhalter. Neue Spiele dieser beiden Arten brauchen kein App-Update.
- **Preise schätzen (Hafen 7):** statt „Handy“ ein Fußball, weil sich die Preisspannen von Handy und Fahrrad überschneiden und die Reihenfolge sonst nicht eindeutig wäre. Alle Preisspannen sind Entwürfe und müssen vor dem Start geprüft werden.
- **Übungs-Begegnung:** `next_encounter(child, practice)` liefert mit `practice = true` auch ohne fällige Wiederholungen eine Begegnung. Das nutzt die App, wenn die nächste Insel im Nebel liegt.
- Alle Wrack-Aufgaben, Funde und Spiel-Texte sind Entwürfe von Claude (Status `draft`).

**Schritt 7b (Spiele, Tauchgang, Sammlung und Nebel in der App), umgesetzt am 10.10.2026:**
- **Inselliste:** Ankerplätze stehen zwischen den Stationen mit Taucher-Symbol und „Ankerplatz“. Die Station danach öffnet sich erst nach dem Tauchgang. Nummern kommen aus `content.number`.
- **Tauchgang:** Perlentauchen (Fragen wie im Stations-Check, „Jede richtige Antwort ist eine Perle“, abwechselnd aus den Stationen davor) → Wrack (Szene, Aufgabe, nach einer falschen Antwort Erklärung und „Nochmal versuchen“, dann „Wieder auftauchen“) → Ergebnis mit Perlen, Seemeilen und dem Fund, der hervorspringt. Kein „Weißt du noch?“ und kein Film am Ankerplatz. „Weißt du noch?“ an der Station nach dem Ankerplatz fragt die Station vor dem Ankerplatz ab.
- **Sortieren:** eine Karte nach der anderen, darunter die Körbe als große Knöpfe. Falscher Korb: „Passt nicht ganz“ und „Nochmal versuchen“. Dinge „dazwischen“ passen in jeden Korb und zeigen ihren Hinweis.
- **Reihenfolge:** Die Dinge liegen gemischt untereinander, das Kind tippt sie der Reihe nach an. Gelegte Dinge wandern mit Nummer und kurzer Erklärung nach oben, ein falscher Tipp zeigt „Noch nicht. Was kommt davor?“. Senkrecht und mit einer Hand bedienbar, wie Abschnitt 11 verlangt.
- Erst wenn ein Spiel gelöst ist, geht es weiter zum Stations-Check. Spiele ohne eigene Mechanik zeigen weiter den Platzhalter.
- **Unterwasser-Sammlung:** Knopf auf der Startseite mit Zahl der Funde. Die Seite zeigt die Perlen und alle Funde: gefundene mit Datum, die anderen blass mit „Noch nicht gefunden“.
- **Nebel voraus:** Sind alle offenen Inseln geschafft und liegt die nächste im Nebel, steht oben auf der Karte „Die nächste Insel liegt noch im Nebel“ mit dem Knopf „Kontrollfahrt starten“ (Begegnung zum Üben). Fertige Inseln, Tauchgänge und Spiele bleiben wiederholbar.

**Schritt 8 (Elternbereich Leuchtturm), umgesetzt am 10.10.2026:**
- **Startseite des Leuchtturms:** Oben „Wartet auf deine Bestätigung“ mit allen Kindern, bei denen Aufgaben gemeldet sind (direkt zu „Taschengeld und Aufgaben“). In der Kinderliste pro Kind Level und „Zuletzt aktiv am …“.
- **Kinderseite:** neue Einträge „Fortschritt und Lernstand“ und „Kombüsen-Fragen“, dazu wie bisher Tempo und Serie, Taschengeld und Aufgaben.
- **Fortschritt und Lernstand:** Übersicht (Level, Fortschritt in Seemeilen, Abzeichen, Serie, Sammlung, zuletzt aktiv) und alle Inseln: abgeschlossen mit Datum, in Arbeit mit „x von y Stationen geschafft“ (Ankerplätze zählen mit), noch gesperrt oder „Inhalt folgt“ (Nebel). Erreichte Inseln klappen auf und zeigen jedes Thema (jede Station) mit Lernstand.
- **Lernstand (Vorschlag, mit Marc abstimmen):** `learning_status()` (nur für Eltern) zählt pro Station aus dem Wiederholungsplan, welche Fragen sicher sind (auch nach Tagen richtig), geübt werden (richtig, noch nicht wiederholt) oder wackeln (zuletzt falsch). Prüfungsfragen zählen zu der Station, die sie abdecken. Urteil pro Thema in `lib/domain/learning_status.dart`: „Wackelt noch“, wenn mindestens ein Drittel zuletzt falsch war; „Sicher“, wenn mindestens zwei Drittel auch nach Tagen gewusst wurden; sonst „Wird geübt“; ohne Antworten „Noch nicht dran“.
- **Kombüsen-Fragen:** Gesprächsideen der Inseln, die das Kind erreicht hat, die aktuelle Insel oben („Gerade dran“). Darunter der Auftrag fürs echte Leben der Insel mit „Als Aufgabe anlegen“: Der Aufgaben-Dialog öffnet sich mit dem Titel vorausgefüllt, die Belohnung legen die Eltern selbst fest (INSELN.md).
- `child_stats()` liefert zusätzlich `last_active_at` (letzte Station, Begegnung oder Wiederholung).
- Noch nicht gebaut: Urkunde „Finanzführerschein Stufe 1“ als PDF (kommt mit der Schatzinsel), „Neue Inhalte“-Hinweis für Eltern (kommt mit dem Adminbereich), Häkchen „haben wir besprochen“ bei Kombüsen-Fragen.

**Schritt 9a (Abo-Rechte ohne Kauf), umgesetzt am 10.10.2026:**
- Auf Wunsch von Marc zuerst ohne RevenueCat und ohne Store-Konten gebaut. Kaufen (RevenueCat-Paket, Produkte in App Store Connect und Google Play, Webhook auf dem Server) folgt als Schritt 9b, sobald Marc die Konten und Preise hat.
- **Regeln in der Datenbank:** Das Abo hängt am Eltern-Konto (`entitlements`, nur Server und Admins schreiben). Premium-Inseln (`content.access = premium`, alle außer Hafen und Tauschinsel) öffnen sich nur mit Abo (`island_unlocked`). Gratis gibt es ein Kinder-Profil; ein zweites lehnt die Datenbank ohne Abo ab. Aufgaben, Taschengeld, Schatztruhe, Wiederholungen und Begegnungen sind gratis.
- **Ohne Abo bleibt Fertiges fertig:** Abgeschlossene Inseln, Orden, Seemeilen und Funde bleiben. Premium-Inseln lassen sich ohne Abo aber nicht wiederholen. Bestehende weitere Kinder-Profile bleiben, nur neue gehen nicht.
- **Kinderbereich ohne Kauf:** Die nächste Premium-Insel trägt ein Schloss mit dem Hinweis „Deine Eltern können sie im Leuchtturm freischalten“. Oben auf der Karte steht dann wie beim Nebel, was das Kind bis dahin tun kann, mit Kontrollfahrt. Keine Preise, kein Kauf-Knopf (Abschnitt 6).
- **Leuchtturm:** neuer Eintrag „Abo“ unter Konto: Stand (Basis oder aktiv), was kostenlos dabei ist, was das Abo bringt, „Abo abschließen“ ausgegraut mit Hinweis. „Kinder-Profil anlegen“ zeigt ohne Abo beim zweiten Kind einen Hinweis mit „Zum Abo“. Im Fortschritt steht bei Premium-Inseln „Mit dem Abo“.
- **Test-Abo:** Nur wenn `app_settings.test_purchases = true` (setzt `supabase/seed.sql`, also nur im Testprojekt) gibt es auf der Abo-Seite den Schalter „Abo testweise aktiv“ (`set_test_premium`). In der Live-Datenbank gibt es den Eintrag nie.
- Noch offen für Marc: Preise, ob es Monats- und Jahresabo gibt, Probezeit, und was „Aufgaben und Schatztruhe in der Basisversion“ genau einschränken soll (heute ist alles davon gratis).

**Schritt 10 (Admin, Grundversion), umgesetzt am 10.10.2026:**
- **Adminbereich als eigene Web-App** im selben Flutter-Projekt: eigener Einstieg `lib/main_admin.dart`, Code unter `lib/admin/`. Die Store-App (`lib/main.dart`) erreicht keine Datei daraus (ein Test prüft das), der Admin-Code kommt also nie in die App. Der Ordner `web/` ist nur für den Adminbereich. Die Texte stehen in `lib/admin/admin_texts.dart` (nur Deutsch, nur fürs Team), nicht in `app_de.arb`. Wo die Seite später liegt (zum Beispiel `admin.` vor der Domain), ist noch offen.
- **Anmeldung:** E-Mail und Passwort, danach immer Zwei-Faktor mit einer Authenticator-App (TOTP von Supabase). Beim ersten Mal richtet die Seite die App ein: Schlüssel zum Abtippen und `otpauth`-Link (ein QR-Code bräuchte ein Zusatzpaket). Konten ohne Admin-Eintrag sehen „Kein Admin-Zugang“ und werden sofort abgemeldet, ohne Zwei-Faktor einzurichten.
- **Admin-Konten** legt der Owner im SQL Editor an: Konto unter Authentication → Users anlegen, dann `select public.grant_admin_role('…', 'owner');`. Die Funktion ist für Apps gesperrt. Admin- und Eltern-Konten sind getrennt: Ein Eltern-Konto wird kein Admin und ein Admin-Konto bekommt kein Eltern-Konto (Trigger).
- **Rollen:** owner sieht Übersicht, Inhalte, Support und Protokoll und darf Abos von Hand vergeben und Konten löschen. editor sieht nur Inhalte. support darf Familien suchen, aber nichts ändern. Geprüft wird in der Datenbank (`require_admin`), die Seite blendet nur aus.
- **Übersicht (owner):** Familien (neu in 7 und 28 Tagen), Kinder-Profile, Intro abgeschlossen, aktive Kinder in 7 und 28 Tagen (Station, Begegnung oder Wiederholung), Abos nach Herkunft (Store, von Hand, Test), Taschengeld eingerichtet, bestätigte Aufgaben. Nur Summen, keine Einzelprofile. Rückkehr nach 1 und 4 Wochen kommt mit der Messung in Schritt 11.
- **Inhalte (owner, editor):** pro Insel Status, Gratis oder Abo, Zahl der Fragen, wie viele Kinder sie erreicht und abgeschlossen haben, pro Station „geschafft von N“ mit dem Rückgang zur Station davor. Das ersetzt vorerst die Abbruchquote, weil der Start einer Station noch nicht gemessen wird. Dazu die 10 schwierigsten und die 10 leichtesten Fragen (ab 5 Antworten, aus dem Wiederholungsplan).
- **Support (owner, support):** Eltern-Konto per E-Mail suchen (Groß- und Kleinschreibung egal). Gezeigt werden nur Anlage-Datum, Einwilligung, Newsletter, Zahl der Kinder, zuletzt aktiv und Abo, keine Spitznamen und keine Lerndaten. Nur owner: Abo von Hand vergeben (1 Monat, 3 Monate, 1 Jahr oder ohne Ablauf, `source = manual`, zum Beispiel für Beta-Familien) oder entfernen, und das Konto löschen (die E-Mail-Adresse muss zur Bestätigung eingetippt werden).
- **Audit-Log:** Jede Suche (auch ohne Treffer, dann ohne die gesuchte E-Mail), jedes Ansehen, jede Abo-Änderung und jede Löschung braucht einen Grund (mindestens 5 Zeichen) und steht im Protokoll. Das Protokoll sieht nur owner, ändern lässt es sich nicht.
- **Warnung:** Oben steht TESTUMGEBUNG oder LIVE. Hat eine Live-Datenbank Test-Einstellungen (Inhalts-Vorschau, Test-Abo), erscheint ein roter Alarm.
- **Inhalte pflegen (Grundversion):** Die Inhaltsdateien bleiben die einzige Quelle. Neu ist `"status"` pro Insel und Begegnung (`entwurf`, `pruefung`, `freigegeben`, ohne Angabe `entwurf`); er gilt für alles auf der Insel. `dart run tool/build_seed.dart` erzeugt `supabase/seed.sql` (Test) und `supabase/inhalte_live.sql` (geprüfter Import für Live, ohne Test-Einstellungen). Geprüft wird: Inseln im Nebel bleiben Entwurf, eine Insel der Hauptroute wird erst freigegeben, wenn alle Inseln davor freigegeben sind. Änderungen im Tabellen-Editor des Testprojekts überschreibt der nächste Seed; Dauerhaftes gehört in die Dateien.
- **Schutz beim Import:** Beide Dateien dürfen beliebig oft laufen. Eine Insel wird erst veröffentlicht, wenn ihre Stationen da sind. Frühere Fassungen (`content_versions`) entstehen nur bei echten Änderungen. Ein erneuter Import veröffentlichter Inseln klappt jetzt (Postgres ruft den Insert-Trigger auch bei „on conflict“ auf); neue Pflichtstationen an veröffentlichten Inseln und das Zurückziehen veröffentlichter Pflichtstationen lehnt die Datenbank weiter ab. `tool/db_test.sh` prüft das mit der echten Import-Datei.
- Noch nicht gebaut (Schritt 12, eigener Adminbereich): Formulare zum Bearbeiten, Vorschau, Kartenansicht, Expeditionen, geplantes Veröffentlichen (`publish_at`) aus den Dateien, „Neue Inhalte“-Hinweis für Eltern, Admins auf der Seite verwalten.

**Schritt 11 (Beta-Vorbereitung), umgesetzt am 10.10.2026:**
- **Messung ohne Drittanbieter (Abschnitt 5):** eigene Tabelle `analytics_events`. Die App meldet nur zwei Dinge: „Kinderbereich geöffnet“ (`app_open`) und „Station begonnen“ (`station_start`). Gespeichert wird nur der Tag, höchstens ein Eintrag pro Kind, Ereignis, Station und Tag, ohne Uhrzeit, Gerät oder Werbe-ID. Niemand liest die Tabelle direkt; Admins sehen nur Summen. Ereignisse werden nach 400 Tagen gelöscht und verschwinden mit dem Kinder-Profil. Fehler beim Melden stören das Kind nie.
- **Rückkehr nach 1 und 4 Wochen (Abschnitt 10):** Erster Tag = erstes Öffnen des Kinderbereichs. „Nach 1 Woche“ = wieder da an Tag 7 bis 13, gezählt unter allen Kindern, deren erster Tag mindestens 14 Tage her ist. „Nach 4 Wochen“ = wieder da an Tag 28 bis 34, unter allen, die mindestens 35 Tage dabei sind. Steht in der Admin-Übersicht in Prozent.
- **Abbruchquote:** Die Inhalts-Statistik zeigt pro Station „begonnen von X · geschafft von Y“. Begonnen, aber nicht geschafft heißt: abgebrochen oder noch dabei.
- **Fehlerprotokoll für die Beta (`app_errors`):** Die App meldet unerwartete Fehler selbst (Flutter-Fehler, Fehler im Hintergrund, unerwartete Daten vom Server): Fehlertext (bis 500 Zeichen), gekürzter Stack (25 Zeilen) und Plattform. Kein Nutzer, kein Gerät. Gleicher Fehler am selben Tag = eine Zeile mit Zähler, höchstens 500 verschiedene Fehler pro Tag, jeder Fehler höchstens einmal pro App-Start, gelöscht nach 90 Tagen. Nur mit Anmeldung. In der Admin-Seite unter „Fehler“ (nur owner) und als Zahl in der Übersicht.
- **Fehler behoben:** Ein Hinweis unten am Bildschirm (SnackBar) blieb nach dem Öffnen einer neuen Seite stehen und verdeckte dort ein paar Sekunden den „Weiter“-Knopf. Jetzt verschwindet er bei jeder neuen Seite. Unerwartete Daten vom Server führen zu „Das hat nicht geklappt“ mit „Nochmal versuchen“ statt zu einem endlosen Ladekreis, eine Station ohne sichtbare Fragen ebenso.
- **Für Marc vor der Beta:** Die Messung und das Fehlerprotokoll gehören in die Datenschutzerklärung (Abschnitt 9, rechtlich prüfen lassen). Schutz vor massenhaften anonymen Anmeldungen (Captcha) kommt vor dem öffentlichen Start, für eine kleine Beta ist er nicht nötig.

**Wunschflasche (Beta-Inseln vervollständigen), umgesetzt am 10.10.2026:**
- Schritt 12 ist laut Plan erst nach der Beta dran. Bis dahin werden die Inseln 1 bis 3 für die Beta vervollständigt, zuerst mit der Wunschflasche (Abschnitt 8, in Schritt 5 verschoben).
- **Datenbank:** `wish_bottles` mit `create_wish_bottle()`, `decide_wish_bottle()`, `open_wish_bottles()` und `wish_bottle_status()`. Schreiben nur über die Funktionen, lesen dürfen Kind und Eltern. Höchstens 10 Flaschen treiben gleichzeitig.
- **Warten:** kleiner Wunsch bis zum nächsten Tagesbeginn, großer 7 Tage (deutsche Zeit). Ob eine Flasche „angespült“ ist, entscheidet die Uhr des Servers. Loslassen geht jederzeit, ein Wunschschatz erst nach der Wartezeit. Ohne Preis (oder unter 1 €) fragt die App beim Umwandeln nach dem Preis.
- **Groß oder klein (Vorschlag, mit Marc abstimmen):** Das Kind wählt selbst. Ab 20 € schlägt die App „großer Wunsch“ vor.
- **Station 3 der Wunschinsel:** Das Spiel ist jetzt echt: Wunsch, ungefährer Preis (freiwillig), klein oder groß, „In die Flasche stecken“. Überspringen geht auch. Danach sind die Wunschflaschen dauerhaft in der Schatztruhe freigeschaltet, auch wenn das Kind übersprungen hat.
- **Schatztruhe:** Bereich „Wunschflaschen“ unter den Wunschschätzen: angespülte Flaschen mit „Willst du … noch?“, „Ja, Wunschschatz daraus machen“ und „Loslassen“, treibende Flaschen mit „Treibt noch bis …“, dazu „Neue Wunschflasche“.
- **Startseite:** Keine Push-Nachricht an Kinder (Abschnitt 10). Ist eine Flasche angespült, zeigt der Knopf „Schatztruhe“ eine Zahl und darunter „Eine Wunschflasche ist angespült!“.

**Alle Mini-Spiele der Inseln 1 bis 3, umgesetzt am 10.10.2026:**
- **Vier neue Spielarten, alle reine Daten** (neue Spiele dieser Arten brauchen kein App-Update, Abschnitt 10):
  - `choice` (Entscheidungen): Runden mit Szene, Frage und 2 bis 4 Möglichkeiten, jede mit Rückmeldung. Eine weniger gute Wahl zeigt warum, dann „Nochmal versuchen“. Mehrere Möglichkeiten dürfen gut sein (zum Beispiel „Was ist mir etwas wert?“: Die Rückmeldung zeigt, worauf man verzichtet). Die Möglichkeiten werden gemischt.
  - `coins` (Münzen legen): Euro-Münzen und -Scheine antippen, bis der Betrag stimmt, auch Wechselgeld. Antippen in der Ablage nimmt eine Münze weg. Geht es mit weniger Münzen, sagt die App das freundlich, ohne Strafe.
  - `pick` (Auswählen, in Talern): Modus `genau` (Preis-Säule: die richtigen Teile ergeben genau den Preis, ein falsches Teil zeigt seinen Hinweis) oder `hoechstens` (Rucksack: das Wichtige muss rein, das Budget darf nicht überschritten werden, Extras sind erlaubt).
  - `number` (Rechnen): Zahl eintippen. Nach einem falschen Versuch gibt es den Tipp und „Lösung zeigen“ mit Erklärung.
- **Zuordnung:** Hafen 2 (Tausch-Spiel), Tauschinsel 1, 2, 3, 4, 6 und Wunschinsel 5, 6, 7 sind `choice`; Hafen 4 ist `coins`; Hafen 6 und Wunschinsel 2 sind `pick`; Tauschinsel 5 ist `number`. Der Eisstand (Tauschinsel 4) ist als Entscheidungen gebaut, nicht als freie Simulation. Die Wunschliste (Wunschinsel 7) ist ein Entscheidungs-Spiel; einen eigenen Wunschschatz legt das Kind in der Schatztruhe an.
- **Tauchgänge:** „Schatztruhe knacken“ (jede Antwort verrät eine Ziffer des Zahlenschlosses, fest pro Ankerplatz; am Ende springt die Truhe auf) und „Fischschwarm“ (jede Antwort schwimmt als Fisch) sind gebaut. Die Fragen und die Wertung (Perlen) sind dieselben wie beim Perlentauchen. „Muscheln zählen“ zeigt bis zu seinem Bau das Perlentauchen (kommt erst ab Insel 4 vor).
- Alle Spieltexte sind Entwürfe von Claude und müssen vor dem Start geprüft werden. Die Inhaltsprüfung (`tool/build_seed.dart`) prüft jede Spielart: zum Beispiel mindestens eine gute Möglichkeit pro Runde, Beträge bis 50 €, richtige Teile ergeben genau den Preis.

**Web-Testversion fürs iPhone, umgesetzt am 10.10.2026:**
- Marc hat keinen Mac und kein Apple-Entwicklerkonto. Zum Testen läuft die Kinder- und Eltern-App deshalb auch als Webseite: `bash tool/build_test_web.sh` baut sie mit `env/test.json` und packt sie als `build/taleria_test_web.zip`. Hochladen zum Beispiel bei Netlify Drop, auf dem iPhone in Safari „Zum Home-Bildschirm“.
- Nur für die Testumgebung: Das Skript bricht ab, wenn `TALERIA_ENV` nicht `test` ist. Die Store-Apps für iOS und Android bleiben das Ziel; die Webseite ist kein Produkt.
- Alles kommt vom eigenen Server (`--no-web-resources-cdn`), nur die Schrift Roboto lädt Flutter im Browser von Google. Vor einer Beta mit fremden Familien eine eigene Schrift einbinden oder die Store-Apps nutzen.
- Die Adresse der Webseite nur an Tester weitergeben.

**Design: 3D-Look mit Bildern aus Gemini, entschieden am 10.10.2026:**
- Marc möchte einen 3D-Animationsfilm-Look wie auf seinen Beispielbildern (Schiff mit Talo und Tala auf See). Den kann der Code nicht selbst zeichnen. Deshalb: **Bilder im 3D-Stil, Bewegung im Code** (Nebel, Wolken, Wellen, Glitzern, segelndes Schiff, Schloss, Flagge). Echtes 3D in der App (Modelle, Spiel-Engine) ist für das MVP zu aufwendig und kommt nicht.
- Die Bilder erstellt Marc mit Gemini. Welche Bilder, in welchem Format und mit welchem Text steht in `BILDER.md`. Inseln und Schiff entstehen auf pinkem Hintergrund, Wolken auf schwarzem; Claude Code stellt sie frei und baut sie ein.
- Rive entfällt für die Figuren, weil es nicht zum 3D-Look passt. Stattdessen Einzelbilder pro Zustand und kurze Filme für besondere Momente (`FIGUREN.md`).
- Beim Beispielbild beachten: Talo darf nicht wie Nick Wilde aus „Zoomania“ aussehen, auf dem Schiff keine Kanonen, Tala ohne Krone und Prinzessinnenkleid.
- Vor dem Start klären: Nutzungsbedingungen von Gemini für App, Werbung und Merchandise; Schutz von Logo und Hauptfiguren mit einer Fachperson besprechen.

**Bewegte Karte, umgesetzt am 10.10.2026:**
- Die Inselkarte ist eine Szene: Meer mit Verlauf, Tiefen, schimmernden Wellen und Glitzern; um jede Insel flaches Wasser, Gischt und Brandung; gepunktete Route (gold bis zum Schiff, weiß voraus mit wandernden Punkten, blass in den Nebel); geschaffte Inseln mit wehender Flagge; die Insel mit dem Schiff leuchtet; gesperrte Inseln sind blasser mit Schloss; über Inseln im Nebel ziehen Wolken. Inseln liegen größer als vorher (gut halbe Bildschirmbreite), jede mit Namensband.
- **Nebel-Start:** Beim Öffnen der Karte liegen Wolken über allem (auch während des Ladens) und ziehen nach etwa 2,5 Sekunden auseinander, die Kamera sinkt dabei leicht herab. Antippen überspringt.
- **Fahrt:** Das Gerät merkt sich, an welcher Insel das Schiff zuletzt lag (`LocalSettings.lastShipIsland`). Ist seitdem eine neue Insel offen, segelt das Schiff nach dem Nebel-Start entlang der Route dorthin (etwa 3,5 Sekunden, mit Kielwasser), danach springt das Schloss auf.
- Bilder aus `BILDER.md` ersetzen Inseln (`map.island.<slug>`), Schiff (`ship.crew`), Wolke (`map.cloud.1`, nur die längliche, gespiegelt und verschieden groß; runde Wolken wollte Marc nicht) und Meer (`map.background`, als Kachel). Fehlt ein Bild, zeichnet der Code einen Ersatz im selben Aufbau. Freistellen mit `tool/bilder_freistellen.py`.
- Bei „Bewegung reduzieren“ steht alles still, ohne Nebel-Start und ohne Fahrt. In Widget-Tests ist die Bewegung aus (`AppServices.sceneMotion`), eigene Tests prüfen sie mit `pump` und Zeitangabe.

**Startseite des Kindes im 3D-Look, umgesetzt am 10.10.2026:**
- Hintergrund ist Marcs Bild vom Schiffsdeck (`home.background`). Oben rechts der Leuchtturm als Bild mit „Leuchtturm“ darunter (`parent.lighthouse`, auf dem Eltern-Gerät PIN, auf dem Kinder-Gerät Hinweis wie bisher).
- Darunter Talo links, der Avatar des Kindes im Bullauge in der Mitte, Tala rechts. Begrüßung und „Dein Schiff: …“ mit dem Schiffsbild auf einer Papierkarte, darunter Rang und Seemeilen.
- Große Bild-Kacheln statt schlichter Knöpfe (Vorschlag von Claude, Bilder von Marc): „Zur Karte“ (dunkelblau, das Wichtigste), Schatztruhe und Aufträge (korallenrote Zahl, wenn etwas wartet), Orden und Sammlung (goldene Zahl). Bildschlüssel `icon.map`, `icon.treasure`, `icon.tasks`, `icon.badges`, `icon.collection`.
- Talo und Tala sind jetzt Bilder (`character.talo`, `character.tala`). Tala in der von Marc gewählten Fassung: gleich alt wie Talo, mit Schleife, Halstuch, Weste, Rock und Stiefeln (`FIGUREN.md`). In Sprechblasen zeigt die App nur Kopf und Schultern im runden Rahmen. Der Platzhalter bleibt der farbige Kreis.
- Bilder mit grünem Hintergrund (Tala, weil sie selbst rosa ist) stellt `tool/bilder_freistellen.py` genauso frei; der grüne Schimmer am Rand wird herausgerechnet.

**Insel von innen, umgesetzt am 10.10.2026:**
- Die Insel füllt den Bildschirm als Bild im Hochformat (`island.<slug>.background`; Hafen, Tauschinsel und Wunschinsel sind da). Darauf liegen alle Pflichtstationen (auch Ankerplätze und Prüfung) als runde Wegmarken in gleichen Abständen auf dem Weg vom Steg nach oben, abwechselnd etwas links und rechts daneben, damit sie sich nicht berühren.
- Wegmarken: geschafft goldener Haken; die nächste Station weiß mit Nummer, sie leuchtet und pulsiert leicht; gesperrt grau mit Nummer, Anker oder Flagge und kleinem Schloss; ohne Wind mit kleinem Wind-Zeichen. Antippen wie bisher: öffnen oder Hinweis.
- Der Weg gehört zum Bild und steht im Asset-Manifest (`route`, Punkte von 0 bis 1). Fehlt das Bild, zeigt die App einen grünen Grund mit gezeichnetem Sandweg und einem Standard-Weg.
- Oben sagt Talo, was als Nächstes dran ist (oder dass die Insel geschafft ist), darunter bei Bedarf der Wind-Hinweis. Unter dem Bild stehen wie bisher Lernziel und die Liste „Stationen“ mit allen Titeln; Bonus-Stationen (Flaschenpost) stehen nur in der Liste.

**Posen von Talo und Tala, umgesetzt am 10.10.2026:**
- Beide gibt es in drei Posen als Bild: winkt, freut sich, denkt nach (`character.talo.wave`, `.happy`, `.think`, genauso für Tala; BILDER.md Abschnitt 4c). Fehlt das Bild einer Pose, zeigt die App das Grundbild der Figur (`CharacterImage`).
- Verwendet: Startseite (beide winken), Begrüßung in der Einführung (winken), Insel von innen (Talo denkt nach beim Tipp, freut sich, wenn die Insel geschafft ist). Später auch in den Stationen.
- Freistellen von Figuren (`--art figur`): Der farbige Hintergrund wirft Licht auf das ganze Fell, das wird überall herausgerechnet; der Rand wird ein wenig nach innen gezogen und Lücken zwischen Arm und Kopf werden durchsichtig.

**Rang-Abzeichen, umgesetzt am 10.10.2026:**
- Die fünf Ränge haben Bilder von Marc (`rank.schiffsjunge` Holz, `rank.matrose` Bronze, `rank.bootsmann` Silber, `rank.steuermann` Gold, `rank.kapitaen` Gold mit Edelsteinen). Sie erscheinen ohne Code-Änderung überall, wo der Rang gezeigt wird: Startseite (Rang und Seemeilen), neuer Rang nach einer Station oder Begegnung, Einführung.
- Die Orden der ersten drei Inseln haben Bilder von Marc (`badge.hafen`, `badge.tauschinsel`, `badge.wunschinsel`): goldener Orden mit blauem Band, im Hochformat. In der Orden-Sammlung und bei der Feier nach einer geschafften Insel wird er ganz gezeigt (nicht mehr rund ausgeschnitten).

**Figuren auf den Inseln, begonnen am 10.10.2026 (BILDER.md Abschnitt 4d):**
- Hafen fertig: Händler (Walross), Verkäuferin am Fischbrötchen-Stand (Seehündin), Bootsbauer (Biber). Tauschinsel fertig: Bruno, Greta, Otti, Olga. Wunschinsel fertig: Elsa, Moritz. Meister Taleron ist jetzt ein Bild (vorher im Manifest als `rive`). Sie erscheinen ohne Code-Änderung in den Sprechblasen der Stationen. Die Perle (`collectible.pearl`) ist dasselbe Bild wie die Muschel mit Perle auf der Startseite. Unterwasserwelt (`underwater.background`, Hochformat) und Fundstück (`collectible.wreck_item`, zweite Fassung mit Anker) sind da.
- Freistellen von Gegenständen (`--art gegenstand`) jetzt wie bei Figuren: eingeschlossene Lücken und Schatten werden durchsichtig. Helle, zarte Farben bleiben auch bei blasserem Pink-Hintergrund deckend (durchsichtig wird nur, was bloß hellere oder dunklere Hintergrundfarbe ist).

**Stationen im neuen Look, umgesetzt am 10.10.2026:**
- Hintergrund jeder Station ist das Bild der Insel von innen, beim Tauchgang die Unterwasserwelt (nach oben geschoben, damit oben das Wrack mit den Fischen zu sehen ist). Fehlt das Bild, ein Verlauf von Meer zu Sand.
- Oben steht eine Bühne vor dem Hintergrund, darunter liegt der Inhalt auf Papier mit goldenem Rand (`lib/features/station/station_stage.dart`).
- Szene und Erklärung: Wer schon gesprochen hat, steht auf der Bühne (höchstens drei, die zuletzt sprachen), wer gerade spricht, ist vorn und größer. Talo und Tala winken bei der ersten Zeile.
- Fragen (Aufwärmen, Check, Prüfung): Talo denkt nach, Tala hört zu; nach einer richtigen Antwort freuen sich beide. Nach dem Antippen rollt die Liste von selbst zur Rückmeldung („Richtig!“ und Erklärung), damit Kinder sie auch auf kleinen Bildschirmen sofort sehen.
- Mini-Spiel: Tala überlegt, Talo steht daneben. Ergebnis: beide freuen sich (bei nicht bestandener Prüfung denken beide nach).
- Unter Wasser bleibt die Bühne leer, damit man die Unterwasserwelt sieht. Gefundene Perlen glänzen weiß (im Code gezeichnet). Der Film (noch Platzhalter) steht frei vor der Insel.
- Ablauf, Texte und Schlüssel der Stationen sind unverändert.

**Musik und Töne, umgesetzt am 10.10.2026 (mit Marc abgestimmt, Paket `audioplayers`):**
- Musik im Hauptmenü: Meeresrauschen mit Möwen (`music.home`, von Marc), leise und in Schleife, auf allen Menü-Seiten des Kindes: Startseite, Karte, Schatztruhe (mit Truhen-Übersicht), Aufträge, Orden, Sammlung und Rundgang. Bis 10.10.2026 lief sie nur auf Startseite und Karte; Marc wollte sie überall außer in den Missionen. Keine Musik in den Missionen (Insel, Station, Tauchgang, Begegnung auf See) und im Leuchtturm. Zurück im Menü läuft sie an derselben Stelle weiter, Dialoge halten sie nicht an. Im Hintergrund (anderes Programm, Bildschirm aus) pausiert sie.
- Kurze Töne, selbst erzeugt mit `tool/toene_erzeugen.py`: richtige Antwort (`sound.correct`, auch bei Aufwärmen, Wrack und Begegnung auf See), Perle beim Tauchgang (`sound.pearl`), Station geschafft (`sound.station_done`), Insel geschafft (`sound.island_done`). Bei falschen Antworten kein Ton (Kinder sollen sich nicht bestraft fühlen), nach nicht bestandener Prüfung keine Fanfare. Mini-Spiele noch ohne Ton.
- Lautsprecher-Knopf links oben auf der Startseite: schaltet Musik und Töne aus oder an (gilt für dieses Gerät, bleibt gespeichert). Im Leuchtturm: Schalter „Musik im Hauptmenü“ (gilt für dieses Gerät; Töne bleiben). Eine Einstellung, die Eltern für das Gerät des Kindes aus der Ferne setzen, bräuchte ein Feld in der Datenbank (vorher mit Marc klären).
- Im Browser darf Ton erst nach dem ersten Antippen starten; die App holt die Musik dann nach (`Sounds.unlock` beim Antippen; auf dem Handy zählt erst das Loslassen).
- Im Browser spielt `lib/services/web_sounds.dart` mit einfachen Audio-Elementen statt mit `audioplayers` (Paket `web`): `audioplayers` leitet den Ton im Browser über Web Audio, das iPhone schaltet Web Audio bei aktivem Lautlos-Schalter stumm und startet es nur direkt beim Antippen; auf Marcs iPhone lief die Musik deshalb nicht. Audio-Elemente spielen auch auf lautlos (wie ein Video). Beim ersten Antippen werden alle kurzen Töne einmal stumm angespielt, damit Safari sie später auch ohne Antippen erlaubt (zum Beispiel die Fanfare nach dem Laden). Die Lautstärke lässt sich auf dem iPhone im Browser nicht im Code senken, darum sind die Ton-Dateien selbst leise. Test im Browser: `CHROME_EXECUTABLE=... flutter test --platform chrome test/web`.
- Technik: `lib/services/sounds.dart` (Regeln, in Tests still und mitschreibend), `lib/services/audio_sounds.dart` (Abspielen), `lib/features/common/menu_music.dart` (Musik je Bildschirm). Neue Musik mit `tool/musik_vorbereiten.py` zur nahtlosen Schleife machen und in `ASSETS_LICENSES.md` eintragen.

**Schatztruhe kinderleicht, umgesetzt am 10.10.2026 (Wunsch von Marc):**
- „Heuer“ heißt im Kinderbereich jetzt „Taschengeld“ (Glossar angepasst). Buchungsarten im Kassenbuch kinderleicht: Taschengeld, Auftrag, Umgepackt, Gekauft, Verschenkt, Wunschschatz eingelöst, Korrektur.
- Oben erklärt Tala (die Zahlmeisterin) in einer Sprechblase die drei Truhen. Jede Truhe hat ein Bild und einen Satz mit Beispiel (Bordkasse: „zum Beispiel ein Eis“). Knöpfe sagen, was passiert: „Ich habe etwas gekauft“, „Ich habe etwas verschenkt“, „Geld in eine andere Truhe legen“.
- Abschnitte auf Papier mit Bild und Erklärung: Taschengeld, Wunschschätze („etwas, das du dir wünschst und wofür du sparst“), Wunschflaschen, Kassenbuch („alles, was mit deinem Geld passiert ist“).
- Bilder von Marc (BILDER.md Abschnitt 4f): `treasure.background` (Schatzkammer), `pot.spend` (Geldkassette), `pot.give` (runde Truhe mit Herz), `icon.ledger` (Kassenbuch), `icon.wish` (goldener Stern); die Schatztruhe zeigt `icon.treasure`. Ohne Bild Holz-Verlauf und farbige Kreise mit Symbol.

**Menü-Seiten erklärt, umgesetzt am 10.10.2026 (Wunsch von Marc):**
- Startseite: Unter dem Fahrtwind steht, was er ist („Spiel jede Woche mindestens eine Station. Jede Woche hintereinander macht deinen Fahrtwind stärker.“).
- Aufträge: Talo und Tala erklären oben, was Aufträge sind, dass die Eltern bestätigen, wohin die Belohnung geht und was „Pflicht“ heißt. Hintergrund `tasks.background` (Kapitänskajüte).
- Orden: Talo erklärt, wie man Orden bekommt. Hintergrund `badges.background` (Ehrenwand).
- Sammlung: Die Unterwasserwelt liegt hinter der ganzen Seite (statt klein oben), Tala erklärt, was man beim Tauchen findet.
- Alle diese Seiten nutzen `SceneBackground`, `PaperCard` und `PaperHeading` (`lib/features/common/scene_background.dart`); ohne Bild ein Holz-Verlauf.
- Jedes Fundstück hat ein eigenes Bild: `"fund_bild"` beim Tauchgang in der Inhaltsdatei (`collectible.<insel>.<nummer>`), ohne Angabe `collectible.wreck_item`. `tool/build_seed.dart` schreibt es in `collectibles.asset_key` und aktualisiert es beim nächsten Seed. Im Testprojekt muss `supabase/seed.sql` dafür neu ausgeführt werden. Alle neun Fundstücke der ersten drei Inseln haben Bilder von Marc.

**Rundgang „Was ist wo?“, umgesetzt am 10.10.2026 (Idee von Marc):**
- Talo und Tala zeigen nacheinander jeden Bereich der Startseite mit seinem Bild, sagen, was er ist und wo er liegt („Wo? Auf der Startseite unter der Karte, links“): Karte, Rang mit Seemeilen und Fahrtwind, Schatztruhe, Aufträge, Orden, Sammlung, Leuchtturm und Ton. Weiter und Zurück, Punkte zeigen die Station.
- Zu finden oben auf der Startseite (Knopf „Was ist wo?“ neben dem Ton-Knopf) und in der Einführung (ersetzt den alten Rundgang mit Symbolen und dem „Logbuch“, das es auf der Startseite nicht gibt).
- Technik: `lib/features/child/board_tour.dart` (`BoardTour`, `BoardTourScreen`, `tourStops`); runde Knöpfe oben auf der Startseite teilen sich `DeckRoundButton` (`sound_button.dart`).

**Rang-Namen für Mädchen und Jungen, umgesetzt am 10.10.2026 (Hinweis von Marc, mit ihm abgestimmt):**
- Das Kind wählt in der Einführung nach dem Avatar, wie seine Ränge heißen: Schiffsjunge, Matrose, Bootsmann, Steuermann, Kapitän oder Schiffsmädchen, Matrosin, Bootsfrau, Steuerfrau, Kapitänin. Es ist die Wahl des Kindes, kein Geschlecht.
- Neue Spalte `children.rank_form` (`junge`, `maedchen`, `null` = noch nicht gewählt), Migration `20261010000100_rangform.sql` (mehrfach ausführbar). Ändern nur über `update_child_look(…, p_rank_form)`, das dürfen Kinder-Gerät und Eltern.
- Kinder, die vorher angefangen haben, fragt Tala einmal auf der Startseite. Bis dahin stehen beide Formen da („Schiffsjunge/Schiffsmädchen“). Eltern können es im Leuchtturm auf der Kinderseite unter „Rang-Namen“ ändern.
- Alle Anzeigen (Startseite, neuer Rang nach Station und Begegnung, Abschluss der Einführung, Leuchtturm) nutzen `l10n.rank(rank, form)`. Die Ränge selbst und die Bilder `rank.<code>` bleiben gleich. Talo bleibt „der Kapitän“ (seine Figur).
- In der Sprechblase liegt die Figur größer hinter dem runden Rahmen (116 statt 72), oben in der Mitte: Kopf und Schultern, breite und schmale Figuren wirken gleich groß. Fehlt das Bild, steht der Platzhalter in Rahmengröße darin.
- Freistellen von Figuren: Schatten auf dem Boden fällt weg, der pinke Schimmer wird auch aus Rot herausgerechnet.

**Rückmeldungen aus Marcs Test, umgesetzt am 10.10.2026:**
- **Musik auf allen Menü-Seiten:** Was genau gilt, steht oben bei „Musik und Töne“.
- **Fehler behoben:** Nach dem Zurückgehen von der Karte zur Startseite hörte die Musik auf. Beim Zurückgehen meldet Flutter zuerst der Seite darunter, dass sie wieder vorn ist, und erst danach der Seite, die geht. Die gehende Seite hielt die Musik deshalb an. Jetzt hält nur die Seite an, die die Musik zuletzt bestellt hat (`MenuMusic`).
- **Aufträge mit Datum:**
  - Im Kinderbereich steht bei gemeldeten Aufträgen „Gemeldet am …“, bei erledigten „Erledigt am …“. Wurde an einem anderen Tag bestätigt, steht „Erledigt am …, bestätigt am …“ da.
  - Bei einer Belohnung steht dabei: „Die 5,00 € kamen in deine Bordkasse.“
  - Im Leuchtturm steht bei jeder Aufgabe „Offen seit …“, „Gemeldet am …“, „Bestätigt am …“ oder „Abgelehnt am …“, dazu „5,00 € auf „Ausgeben“ gebucht“.
  - Die Daten kommen aus `tasks.submitted_at` und `tasks.reviewed_at`. Die Datenbank bleibt unverändert.
- **Übersicht pro Truhe:**
  - Wer im Kinderbereich eine Truhe antippt (oder „Was ist drin?“), sieht oben den Stand. Darunter steht „So setzt sich das zusammen“: was dazukam und was wegging, je Art. Beispiele: Taschengeld, Belohnungen für Aufträge, aus anderen Truhen hergelegt, gekauft. Darunter stehen alle Buchungen dieser Truhe.
  - Die Rechnung steckt in `lib/domain/pot_summary.dart`. Das Kassenbuch lädt nur die neuesten 50 Buchungen; Älteres steht als „Frühere Buchungen“ da, damit die Summe immer zum Stand vom Server passt.
  - Belohnungen für Aufträge landen wie bisher in der Bordkasse, nicht in der Schatztruhe (Schritt 5a).

**Rückmeldungen aus Marcs Test, zweite Runde (10.10.2026):**
- **Fehler behoben, falsche Reihenfolge:** `supabase_flutter` sortiert mit `.order(...)` ohne Angabe **absteigend**. Darum standen die Stationen auf der Insel verkehrt herum: Station 1 lag oben, die Prüfung unten am Steg. Orden und Unterwasser-Sammlung waren auch umgedreht, ebenso Kombüsen-Fragen, Wunschschätze und die Kinderliste. Jetzt steht überall `ascending: true` (oder ausdrücklich `false`), und der `IslandController` sortiert die Stationen zusätzlich selbst. Regel: `.order()` nie ohne `ascending`.

---

## 17. Aktueller Stand und nächste Schritte (Stand 10.10.2026)

Kurzfassung für den Start einer neuen Sitzung. Die Einzelheiten stehen in Abschnitt 16.

**Stand:**
- Die MVP-Schritte 1 bis 11 sind gebaut. Schritt 9 gibt es nur ohne Kauf (9a).
- Dazu: die Wunschflasche und alle Mini-Spiele der Inseln 1 bis 3.
- Der 3D-Look mit Marcs Bildern ist eingebaut: Karte, Startseite, Inseln, Stationen, Figuren, Ränge, Orden, Fundstücke und Menü-Seiten.
- Außerdem: Musik und Töne, der Rundgang „Was ist wo?“ und Rang-Namen für Mädchen und Jungen.
- Alle Tests sind grün: 308 App-Tests, die Datenbank-Tests und der Browser-Test.
- Ziel jetzt: Marc testet die Inseln 1 bis 3 auf dem iPhone, danach wird alles für eine kleine Beta fertig gemacht.

**Letzte Testversion (10.10.2026):**
- Datei: `build/taleria_test_web.zip`, 26,5 MB. Das Skript lässt ungenutzte Web-Dateien weg, damit die Datei unter 30 MB bleibt.
- Vorher im Testprojekt ausführen: erst `20261010000100_rangform.sql`, dann `supabase/seed.sql`.
- Danach die ZIP bei Netlify unter Deploys hochladen.

**Arbeitsweise mit Marc (zusätzlich zu Abschnitt 1):**
- Vor jedem Schritt sagen, was als Nächstes kommt.
- Eine Testversion (ZIP) nur bauen, wenn Marc es sagt.
- Bilder macht Marc mit Gemini, auf pinkem Hintergrund (#FF00FF). Bei rosa Figuren nimmt er einen grünen Hintergrund.
- Claude stellt die Bilder mit `tool/bilder_freistellen.py` frei.
- Schickt Marc Bilder, während Claude noch arbeitet, kommen sie nicht an. Er schickt sie dann noch einmal neu.

**Nächste Schritte:**
1. Marc testet die Testversion. Besonders wichtig: Läuft die Musik jetzt auf dem iPhone? Seine Rückmeldungen umsetzen.
   - Erste Runde erledigt (siehe oben, „Rückmeldungen aus Marcs Test“): Musik auf allen Menü-Seiten, Aufträge mit Datum, Übersicht pro Truhe. Diese Änderungen sind noch in keiner Testversion (ZIP); eine neue baut Claude erst, wenn Marc es sagt.
2. Kleine offene Punkte:
   - Lizenz der Musik bestätigen (vermutlich Pixabay, `ASSETS_LICENSES.md`).
   - `rank.kapitaen`, `badge.wunschinsel` und `collectible.wreck_item` zeigen ein englisches „E“ für Osten. Diese Bilder neu machen, mit „O“ oder ohne Buchstaben.
   - Töne für die Mini-Spiele.
   - Musik-Einstellung der Eltern für das Kinder-Gerät aus der Ferne. Dafür braucht es ein Feld in der Datenbank, vorher Marc fragen.
3. Vor einer Beta mit fremden Familien:
   - „Powered by Netlify“ entfernen.
   - Eine eigene Schrift einbinden, statt Roboto von Google.
   - Datenschutzerklärung, Impressum und AGB rechtlich prüfen lassen.
   - Die Nutzungsbedingungen von Gemini klären.
   - Die Entwürfe prüfen: Marc und eine Fachperson. Danach den `status` in den Inhaltsdateien setzen und die Live-Datenbank nur über `supabase/inhalte_live.sql` füllen.
4. Später:
   - Schritt 9b: Kaufen mit RevenueCat, sobald Store-Konten und Preise da sind.
   - Filme: Intro und Ankunftsfilme.
   - Inhalte für die Inseln 4 bis 15.
   - Das Tauch-Spiel „Muscheln zählen“.
   - Die Urkunde als PDF.
   - Passwort zurücksetzen.
   - QR-Code zum Anmelden.
   - Captcha.
   - Nach der Beta Schritt 12: der eigene Adminbereich.
