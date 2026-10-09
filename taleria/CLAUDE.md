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
| `allowance` | Heuer | Taschengeld |
| `pot_spend` | Bordkasse | Ausgeben |
| `pot_save` | Schatztruhe | Sparen |
| `pot_give` | Glückstruhe | Verschenken |
| `savings_goal` | Wunschschatz | Sparziel |
| `coin` | Taler | Taler |
| `xp` | Seemeilen | Fortschritt |
| `rank` | Rang (Schiffsjunge, Matrose, Bootsmann, Steuermann, Kapitän) | Level |
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

Alle sichtbaren Texte liegen in Übersetzungsdateien (zuerst Deutsch), nie fest im Code.

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
- `parents` – verknüpft mit `auth.users`; `consent_at`, `locale`, `parent_pin_hash`, `marketing_consent_at`, `marketing_confirmed_at`, `marketing_unsubscribed_at`, `push_consent_at` (Regeln für E-Mails und Push in `MARKETING.md`, Abschnitt 5)
- `children` – `parent_id`, `nickname`, `birth_year`, `level_setting` (Einsteiger, Fortgeschritten), `stage` (1 oder 2), `avatar`, `ship_name`, `stations_per_week` (Standard 2, `null` = freie Fahrt), `release_weekdays` (Standard Montag und Donnerstag)
- `child_login_codes` – `child_id`, `code`, `expires_at`, `used_at`

**Inhalte**
- `islands` – `slug`, `stage`, `island_group`, `sort_order`, `map_x`, `map_y`, `route_type` (main, side, event), `expedition_id` (optional), `title_key`, `intro_video_url`, `is_published`
- `stations` – `island_id`, `sort_order`, `type` (video, quiz, game, practice, review_stop, exam), `is_required`, `added_in_version`, `xp_reward`, `content` (jsonb), `is_published`
- `quiz_questions` – `station_id`, `question`, `answers` (jsonb), `correct_index`, `explanation`
- `expeditions` – `title_key`, `starts_at`, `ends_at`
- `conversation_prompts` – `island_id`, `text`

**Fortschritt**
- `station_progress` – `child_id`, `station_id`, `status` (open, done), `score`, `completed_at`
- `island_completions` – `child_id`, `island_id`, `completed_at`
- `xp_events` – `child_id`, `source_type`, `source_id`, `amount` (ein Kassenbuch der Seemeilen; der Rang wird daraus berechnet)
- `badges`, `child_badges`
- `question_reviews` – `child_id`, `question_id`, `due_at`, `interval_days`, `correct_streak`, `last_answered_at`, `last_correct` (Zeitplan der Wiederholung pro Frage und Kind)
- `encounters` – `slug`, `type` (taleron, haendlerschiff, fischerboot, angeberschiff, tala_vergisst), `title_key`, `asset_key`, `question_count` (Vorlagen für Begegnungen auf See)
- `encounter_runs` – `child_id`, `encounter_id`, `started_at`, `finished_at`, `correct_count`
- `collectibles` – `slug`, `kind` (pearl, shell, wreck_item), `title_key`, `asset_key`, `rarity` (nur Optik)
- `child_collectibles` – `child_id`, `collectible_id`, `found_at`, `source_station_id`

**Budget und Aufgaben (alles virtuell)**
- `tasks` – `parent_id`, `child_id`, `title`, `reward_cents`, `is_chore` (Pflicht ohne Geld), `status` (open, submitted, approved, rejected), `photo_path` (optional), `due_at`
- `allowance_rules` – `child_id`, `amount_cents`, `interval` (weekly, monthly), `next_run_at`
- `ledger_entries` – `child_id`, `pot` (spend, save, give), `amount_cents`, `entry_type` (allowance, task, transfer, manual, goal), `reference_id`, `created_by` (Kassenbuch; Guthaben = Summe, nie direkt überschreiben)
- `savings_goals` – `child_id`, `title`, `target_cents`, `reached_at`
- `wish_bottles` – `child_id`, `title`, `price_cents` (optional), `remind_at`, `decision` (open, dropped, converted), `savings_goal_id` (bei Umwandlung)

**Abo**
- `entitlements` – `parent_id`, `entitlement` (premium), `source` (revenuecat), `valid_until`

**Admin**
- `admins` – verknüpft mit `auth.users`; `role` (owner, editor, support), `mfa_required` (immer true)
- `admin_audit_log` – `admin_id`, `action`, `target_type`, `target_id`, `reason`, `created_at` (jeder Zugriff auf ein Familienkonto und jede Löschung wird protokolliert)
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
| Talo und Tala, beweglich | Rive (`.riv`) mit State Machine (idle, talk, happy, sad, wave) | `assets/rive/` |
| Kleine Effekte (Flaschenpost, Möwe) | Lottie (`.json`) | `assets/lottie/` |
| Karte, Inseln, Hintergründe | SVG oder PNG (2x und 3x) | `assets/images/` |
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

---

## 15. Offene Punkte

- Rolle von Tala als Zahlmeisterin ist ein Vorschlag.
- Aussehen von Meister Taleron steht noch aus (alt, weise, freundlich, nicht gruselig).
- Preis: Startannahme 4,99 bis 6,99 € pro Monat oder 39 bis 59 € pro Jahr pro Familie, noch zu testen.
- Illustrationen von Talo, Tala und der Karte stehen noch aus. Bis dahin Platzhalter verwenden.
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
