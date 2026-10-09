# MARKETING.md – Inhaltskalender, Ankündigungen und E-Mail-Marketing

Damit Taleria lebendig bleibt und Eltern sehen, dass sich das Abo lohnt.
Diese Datei ist Planung für Marc. Für Claude Code relevant sind nur die technischen Punkte in Abschnitt 4 und 5.

---

## 1. Grundrhythmus

- **Jeden Monat eine Flaschenpost** (Bonus-Station an einer bestehenden Insel).
- **Zu Ferien und Feiertagen eine Expedition** (zeitlich begrenzte Event-Insel, 2 bis 4 Wochen sichtbar).
- **Jeden Monat eine E-Mail an Eltern** („Neu in Taleria“), nur an Eltern mit Newsletter-Einwilligung.
- **Inhalte rechtzeitig planen:** mindestens 4 Wochen vor Veröffentlichung fertig, damit Zeit für Test und fachliche Prüfung bleibt.

---

## 2. Inhaltskalender (Ideen)

| Monat | Anlass | Flaschenpost oder Expedition | Thema |
| --- | --- | --- | --- |
| Januar | Neues Jahr | Expedition „Neujahrs-Hafen“ | Wunschschätze fürs neue Jahr setzen |
| Februar | Fasching | Flaschenpost | Kostüm kaufen, leihen oder selbst machen? |
| März / April | Ostern | Expedition „Osterinsel“ | Geschenke und Taschengeld in den Ferien |
| Mai | Muttertag | Flaschenpost | Geschenke planen mit der Glückstruhe |
| Juni bis September | Sommerferien (je nach Bundesland unterschiedlich) | Expedition „Ferien-Lagune“ | Urlaubskasse, Geld im Ausland, Souvenirs |
| September | Schulstart | Flaschenpost | Schulsachen einkaufen und Preise vergleichen |
| Oktober | Weltspartag (Ende Oktober) | Expedition „Spar-Fest“ | Sparziele, Schatztruhen-Challenge |
| November | Black Friday | Flaschenpost | Angebote durchschauen, Werbe-Check |
| Dezember | Advent und Weihnachten | Expedition „Advents-Archipel“ mit 24 kleinen Flaschenposts | Wunschliste, Geschenke-Budget, Geben und Spenden |

Hinweis: Ferientermine sind je Bundesland verschieden. Sommer-Inhalte deshalb über mehrere Wochen sichtbar lassen.

---

## 3. Ankündigungen in der App

- **Kinderbereich:** Neues erscheint als Geschichte auf der Karte (Flaschenpost treibt an, Expedition taucht aus dem Nebel auf). Keine Push-Nachrichten an Kinder.
- **Elternbereich (Leuchtturm):** Bereich „Neu in Taleria“ mit kurzer Beschreibung und passender Kombüsen-Frage.
- **Optional für Eltern:** Push-Nachricht an das Eltern-Gerät, nur mit Einwilligung, höchstens einmal pro Woche.

---

## 4. E-Mail-Marketing an Eltern

### Arten von E-Mails

| E-Mail | Wann | Inhalt | Einwilligung nötig? |
| --- | --- | --- | --- |
| Willkommen | direkt nach Registrierung | So funktioniert Taleria, erste Schritte, Hinweis auf Kombüsen-Fragen | nein (gehört zur Registrierung) |
| Einführung, Teil 2 und 3 | nach 3 und 7 Tagen | Aufträge und Heuer einrichten, Tempo einstellen | ja, wenn werblich |
| Monats-Rückblick | einmal im Monat | Was hat mein Kind gelernt, welche Themen sitzen, Kombüsen-Frage | ja |
| Neu in Taleria | einmal im Monat | neue Flaschenpost oder Expedition | ja |
| Wir vermissen euch | nach 3 Wochen ohne Nutzung | freundliche Erinnerung, ohne Druck | ja |
| Abo-Hinweise | vor Verlängerung, bei Zahlungsproblem | Vertragsinformationen | nein (Vertragskommunikation) |

### Regeln
- E-Mails gehen nur an Eltern, nie an Kinder.
- Newsletter nur mit eigener, freiwilliger Einwilligung, getrennt von der Registrierung, mit Bestätigung per E-Mail (Double-Opt-in).
- In jeder Marketing-E-Mail ein Abmeldelink, der sofort wirkt.
- In E-Mails nur der Spitzname des Kindes, keine weiteren Kinderdaten.
- Versand über einen Anbieter mit Servern in der EU und Auftragsverarbeitungsvertrag.
- Ton: freundlich, kurz, mit Talo und Tala, keine Rabatt-Schreierei.
- Vor dem Start rechtlich prüfen lassen (Einwilligungstexte, Abmeldung, Impressum in jeder E-Mail).

### Kennzahlen (im Adminbereich ansehen)
- Öffnungs- und Klickrate pro E-Mail
- Rückkehr der Kinder in den 7 Tagen nach einer E-Mail
- Abmeldungen

---

## 5. Technik (für Claude Code)

- `parents` bekommt `marketing_consent_at` (Zeitpunkt der Newsletter-Einwilligung, `null` = keine), `marketing_confirmed_at` (Double-Opt-in bestätigt), `marketing_unsubscribed_at`.
- Einwilligung ist in der Registrierung ein eigenes, nicht vorausgewähltes Kästchen und jederzeit im Leuchtturm änderbar.
- Werbliche E-Mails nur an Eltern mit bestätigter Einwilligung und ohne Abmeldung.
- Push-Nachrichten nur an Eltern-Geräte und nur mit eigener Einwilligung (`push_consent_at`).
- Im Adminbereich: geplante Veröffentlichungen (`publish_at`) als Kalenderansicht, damit Inhaltskalender und E-Mails zusammenpassen.

---

## 6. Social Media (Ideen)

- Kurze Clips mit Talo und Tala: ein Geld-Tipp pro Woche für Eltern.
- „Tala macht den Fehler“-Reihe: typische Kinder-Geldfehler, Talo erklärt.
- Ankündigung neuer Expeditionen.
- Zielgruppe der Kanäle sind Eltern, nicht Kinder.
