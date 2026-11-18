# DIENSTE.md – Alle Konten, Dienste und Kosten von Taleria

Hier steht an einem Ort, **welche Dienste Taleria nutzt, wofür, wo man sie findet und was sie kosten**.
Wenn ein neuer Dienst, eine Domain oder ein Konto dazukommt: hier eintragen (Claude macht das bei jeder Änderung mit).

> **Wichtig: In diese Datei kommen KEINE Passwörter, API-Schlüssel, PINs oder Codes.**
> Die Datei liegt im Git und wäre sonst für jeden lesbar, der das Repository sieht.
> Passwörter gehören in einen Passwort-Manager (zum Beispiel Bitwarden, kostenlos, oder der Schlüsselbund im iPhone).
> Hier steht nur, *welches* Konto es gibt und *wo* das Passwort liegt („im Passwort-Manager unter …“).

Stand: 18.11.2026

---

## 1. Übersicht

| Dienst | Wofür | Konto / Name | Kosten | Stand |
| --- | --- | --- | --- | --- |
| GitHub (alt) | Code und Verlauf von Taleria | `marc130798`, Repository `marc130798/AutoGPT`, Branch `claude/schritt-eins-n8v6jd` | kostenlos | aktiv; Marc bekommt dort keine E-Mails mehr (Konto wiederherstellen, siehe Abschnitt 6) |
| GitHub (neu) | Ersatz für das alte Konto | `markohler31-boop` | kostenlos | angelegt; Umzug des Codes noch offen |
| Supabase Test | Datenbank, Anmeldung, Speicher der **Testumgebung** | Projekt „Taleria Test“, Region EU (Frankfurt) | kostenlos (Free-Plan) | aktiv |
| Supabase Live | Datenbank für echte Familien | Projekt „Taleria Live“, Region EU (Frankfurt) | | **noch nicht angelegt** (erst vor dem Start) |
| Netlify | Homepage und Web-Testversion der App, Formular „Testfamilie werden“ | Marcs Netlify-Konto | kostenlos (300 Credits pro Monat, etwa 15 pro Deploy) | aktiv |
| Domain | eigene Adresse, zum Beispiel `taleria.de` | | ca. 5 bis 6 € pro Jahr (siehe Abschnitt 2) | **offen** |
| E-Mail-Postfach | eigene Adresse, zum Beispiel `hallo@taleria.de` | | ca. 1 bis 3 € pro Monat (siehe Abschnitt 3) | **offen** |
| ElevenLabs | Stimmen, Sprecherin im Video, Geräusche | Starter-Abo | Starter-Abo (Preis im Konto prüfen) | 38.453 Zeichen pro Monat, am 18.11.2026 noch 2.269 frei, neue Zeichen am 16.12.2026 |
| Google Gemini | Bilder im 3D-Look | Marcs Google-Konto (Guthaben) | etwa 5 Cent pro Bild | aktiv; Claude fragt vor jedem Bild |
| Meta (Facebook, Instagram) | Werbung für Eltern, Meta-Pixel auf der Webseite (nur nach Einwilligung) | Werbekonto im Meta Business Manager | nach Werbebudget | Pixel-ID noch eintragen in `landingpage/consent.js` (`TALERIA_PIXEL_ID`) |
| RevenueCat | Abo-Kauf in den Store-Apps | | | **noch nicht angelegt** (Schritt 9b) |
| Apple App Store | iPhone-App | Apple-Entwicklerkonto | 99 $ pro Jahr | **noch nicht angelegt** (braucht einen Mac oder einen Dienst zum Bauen) |
| Google Play | Android-App | Google-Play-Entwicklerkonto | einmalig 25 $ | **noch nicht angelegt** |
| E-Mail-Versand für die App | Passwort-Codes, später Wochenbericht | zum Beispiel Brevo | kostenlos bis 300 Mails am Tag | **offen** (Supabase schickt bis dahin nur wenige Mails an das eigene Team) |

---

## 2. Domain (eigene Adresse)

**Was:** Statt `irgendwas.netlify.app` heißt die Homepage dann zum Beispiel `taleria.de`.

**Wo günstig kaufen (Empfehlung):** ein deutscher Anbieter, Server und Vertrag in Deutschland, keine Lockangebote mit teurer Verlängerung.
- **netcup** oder **INWX**: `.de`-Domain etwa 5 bis 6 € pro Jahr, auch bei der Verlängerung.
- IONOS ist oft im ersten Jahr billig (1 €), danach deutlich teurer (etwa 15 € pro Jahr).
- Vor dem Kauf immer den **Verlängerungspreis** prüfen, nicht nur den Preis im ersten Jahr.

**Vorher prüfen:**
- Ist der Name frei? (Suche beim Anbieter)
- Markenrecht: Gibt es „Taleria“ schon als Marke für Apps oder Lernspiele? Kostenlos suchen im DPMA-Register (`register.dpma.de`) und bei der EU (`euipo.europa.eu`). Im Zweifel Fachperson fragen.
- Sinnvoll: auch `taleria.app` oder `taleria-app.de` mitnehmen, wenn `taleria.de` belegt ist.

**Domain mit Netlify verbinden (etwa 10 Minuten):**
1. Bei Netlify: Projekt öffnen → „Domain management“ → „Add a domain“ → `taleria.de` eingeben.
2. Netlify zeigt an, was beim Domain-Anbieter einzutragen ist (DNS). Diese Einträge beim Anbieter (netcup oder INWX) unter „DNS“ eintragen.
3. Warten (meist unter einer Stunde, manchmal bis zu einem Tag). Netlify richtet das Schloss-Symbol (HTTPS) kostenlos selbst ein.
4. Danach hier eintragen: Domain, Anbieter, Ablaufdatum.

| Domain | Anbieter | gekauft am | verlängert sich am | Kosten pro Jahr |
| --- | --- | --- | --- | --- |
| | | | | |

---

## 3. Eigene E-Mail-Adresse

**Wofür:** Impressum, Datenschutzerklärung, Kontakt für Testfamilien, später Absender für Mails der App.

**Möglichkeiten:**
- Postfach direkt beim Domain-Anbieter (bei netcup und INWX zubuchbar).
- **mailbox.org** (Berlin, datenschutzfreundlich), etwa 1 bis 3 € pro Monat, eigene Domain möglich.
- Nach dem Einrichten: Adresse in Impressum, Datenschutz und Homepage eintragen (gelbe Stellen) und hier notieren.

| Adresse | Anbieter | wofür |
| --- | --- | --- |
| | | |

---

## 3b. Marke beim DPMA (Plan, Stand 18.11.2026)

- **Was anmelden:** zuerst die **Wortmarke „Taleria“** (schützt den Namen in jeder Schrift und Form). Das Logo als Wort-/Bildmarke ist eine zweite, eigene Anmeldung (noch einmal 290 €), am besten später.
- **Klassen (in der Grundgebühr sind 3 enthalten):**
  - **9**: herunterladbare Apps und Lernsoftware
  - **41**: Bildung, Unterricht, Lernspiele und Unterhaltung online
  - **42**: Software als Dienst im Internet (Web-Version), Entwicklung von Software
  - später möglich, je 100 €: **28** (Spiele, Spielzeug, Merchandise), **16** (gedruckte Logbücher, Bücher)
- **Kosten:** 290 € online beim DPMA (bis 3 Klassen), jede weitere Klasse 100 €. Zahlen innerhalb von 3 Monaten.
- **Vorher prüfen:** `register.dpma.de` und `tmdn.org/tmview` nach „Taleria“ und ähnlichen Namen durchsuchen. Im Zweifel Fachperson (Markenanwalt, IHK) fragen.
- **Logo-Dateien:** `marke/taleria_logo_weiss.jpg` (für die Anmeldung) und `marke/taleria_logo_transparent.png`. Das Logo ist mit Gemini erstellt; Nutzungsbedingungen vor der Anmeldung prüfen.

| Marke | Art | Klassen | angemeldet am | Aktenzeichen | Stand |
| --- | --- | --- | --- | --- | --- |
| Taleria | Wortmarke | 9, 41, 42 | | | offen |

---

## 4. Wo liegt was im Projekt

| Was | Wo |
| --- | --- |
| Gedächtnis des Projekts (Regeln, Entscheidungen) | `CLAUDE.md` |
| Inhalte der Inseln | `INSELN.md`, `content/stufe1/` |
| Bilderliste mit Gemini-Texten | `BILDER.md` |
| Lizenzen von Bildern, Tönen, Schriften | `ASSETS_LICENSES.md` |
| Homepage | `landingpage/` (Seiten in `landingpage/seiten/`, bauen mit `python3 tool/homepage_bauen.py`) |
| Erklärvideo (Quelle) | `video/` (Anleitung in `video/LIESMICH.md`); fertige Videos für die Homepage in `landingpage/videos/` |
| Zugangsdaten der App | `env/test.json`, `env/live.json` (nicht im Git) |

---

## 5. Kosten im Überblick (pro Monat, geschätzt)

| Posten | jetzt | nach dem Start |
| --- | --- | --- |
| Domain | 0 € | etwa 0,50 € |
| E-Mail | 0 € | etwa 1 bis 3 € |
| ElevenLabs | Starter-Abo | nach Bedarf |
| Supabase | 0 € | 0 € (Free) oder 25 $ (Pro, sobald viele Familien da sind) |
| Netlify | 0 € | 0 € |
| Apple | 0 € | etwa 8 € (99 $ im Jahr) |

---

## 6. Offene Punkte (To-do-Liste, Stand 18.11.2026)

Hier steht alles, was noch zu tun ist, damit nichts vergessen wird. Claude hakt ab und ergänzt bei jeder Sitzung.

**Marc erledigt:**
- [ ] **Domain und E-Mail bei IONOS bestellen** (1,50 € im Monat, monatlich kündbar, dauerhaft): `taleria-app.de`, optional `taleriaapp.de` als Weiterleitung. Postfach anlegen, zum Beispiel `hallo@taleria-app.de`. Danach Domain und Adresse an Claude geben.
- [ ] **Gewerbe anmelden** (Einzelunternehmen, online beim Gewerbeamt, etwa 20 bis 60 €). Kostenlose Gründungsberatung der IHK nutzen. Alle Rechnungen aufheben (ElevenLabs, IONOS, Gemini, Apple).
- [ ] **Impressum-Adresse klären:** eigene Anschrift oder Impressum-Adresse/virtuelles Büro (etwa 10 bis 30 € im Monat).
- [ ] **Marke beim DPMA:** vorher `register.dpma.de` und `tmdn.org/tmview` nach „Taleria“ durchsuchen, dann Wortmarke „Taleria“ in den Klassen 9, 41, 42 anmelden (290 €), Abschnitt 3b.
- [ ] **Social Media anlegen** (alles mit der neuen Mail-Adresse und Zwei-Faktor-Anmeldung): Instagram (Business-Konto), Facebook-Seite, TikTok, YouTube; überall derselbe Name, zum Beispiel `@taleria.app`. Im Profil auf das Impressum verlinken. Kontonamen an Claude geben.
- [ ] **Meta-Pixel anlegen** (Meta Business Manager → Events Manager) und die Pixel-ID an Claude geben. Dort die Vereinbarung zur gemeinsamen Verantwortung („Controller Addendum“) annehmen.
- [ ] **Testfamilien aus dem Bekanntenkreis** fragen (3 bis 5 Familien mit Kindern von 8 bis 12, 2 bis 3 Wochen).
- [ ] **Altes GitHub-Konto `marc130798`:** keine E-Mails von GitHub. Spam-Ordner prüfen, sonst GitHub-Support (`support.github.com`, Bereich „Account“). Das Hochladen funktioniert zurzeit wieder.

**Claude erledigt, sobald Marc geliefert hat:**
- [ ] Domain und Mail-Adresse in Homepage, Impressum, Datenschutz und `DIENSTE.md` eintragen; Anleitung zum Verbinden der Domain mit Netlify (DNS bei IONOS).
- [ ] Pixel-ID in `landingpage/consent.js` eintragen (`TALERIA_PIXEL_ID`), neue Homepage-ZIP bauen.
- [ ] Gelbe Stellen in Impressum und Datenschutz mit Marcs Angaben füllen (Name, Anschrift, E-Mail).
- [ ] Für die Testfamilien: frische Test-Version als ZIP, Anleitung aktualisieren; in Supabase (Test) entweder die E-Mail-Bestätigung ausschalten oder eigenen Mail-Versand einrichten (Brevo mit der IONOS-Adresse), sonst kommen bei fremden Eltern keine Mails an.
- [ ] **Social-Media-Paket** (Plan vom 18.11.2026): alle 2 Wochen ein Paket mit etwa 3 Posts pro Woche, fertige Texte mit Hashtags, Bilder und kurze Videos in 1:1, 4:5 und 9:16 aus vorhandenem Material (App-Bilder, Talo und Tala, Ausschnitte aus dem Erklärvideo, Fakten-Grafiken mit Quelle). Neue Gemini-Bilder oder Stimmen nur nach Marcs Ja. Marc prüft und plant die Posts in der kostenlosen Meta Business Suite ein. Auf Wunsch ein wiederkehrender Termin (zum Beispiel jeden zweiten Montag), an dem Claude das nächste Paket vorbereitet. Später möglich: direkt über die Meta-Schnittstelle posten (braucht Instagram-Business-Konto, verbundene Facebook-Seite und einen sicher hinterlegten Zugangsschlüssel). Grundsatz: Vor jedem Post schaut ein Mensch drauf, keine echten Kinder ohne schriftliche Erlaubnis.
- [ ] Werbetest auf Meta vorbereiten: 3 Anzeigentexte und 15-Sekunden-Schnitte aus dem Video (Budget-Vorschlag 100 bis 200 € für 1 bis 2 Wochen, Zielgruppe Eltern 30 bis 45 in Deutschland).
- [ ] **Vor dem Bezahl-Start:** mit Steuerberater über eine UG sprechen; Impressum, Datenschutz und AGB rechtlich prüfen lassen.
- [ ] **Umzug zum neuen GitHub-Konto** `markohler31-boop` (nur nötig, falls das alte Konto wieder Probleme macht): neue Sitzung mit dem Repository `markohler31-boop/taleria`, Code aus dem alten Repository übernehmen.
