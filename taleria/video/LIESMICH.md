# Erklärvideo Taleria (18.11.2026)

Etwa 62 Sekunden, 16:9 (1920 × 1080) und 9:16 (1080 × 1920), 30 Bilder pro Sekunde.
Sprecher: „Otto“ von ElevenLabs (Stimme `FTNCalFNG5bRnkkaP5Ug`, Marcs Wahl aus drei Proben),
leises Meeresrauschen (`music.home`) darunter. Farben, Schriften und Bilder wie auf der Homepage.

- `video.html`: alle 10 Szenen als Animation im Browser (`render(t)` zeichnet den Zeitpunkt t).
- `vo.json`: Sprechertext je Szene und die Länge der Aufnahmen; danach richtet sich der Zeitplan.
- `render_video.js`: nimmt jedes Bild mit Playwright auf (`node render_video.js <ordner> 1920 1080 full <bilder>`).

Zum Neubauen braucht der Ordner zusätzlich `img/` (Bilder aus `landingpage/bilder` und `assets/images`),
`fonts/` (aus `landingpage/schriften`), `music.home.mp3` und die Sprachaufnahmen `vo_01.mp3` bis `vo_10.mp3`.
Danach mit ffmpeg Bilder und Ton zusammenfügen. Die fertigen MP4-Dateien liegen nicht im Git (zu groß).

Fakten mit Quelle (wie auf der Homepage): Bankenverband Jugendstudie 2024, Deutsche Bundesbank
Zahlungsverhalten 2023, Creditreform SchuldnerAtlas 2025.

Zweite Fassung (18.11.2026, Marcs Wunsch „zu langsam“): Sprachaufnahmen mit ffmpeg `atempo=1.2`
beschleunigt (keine neue Aufnahme), kürzere Pausen, Animationen 1,3-mal schneller, Überschriften Wort
für Wort, Luftblasen im Meer. Szene 7 zeigt ein großes Handy, das ein Finger durchscrollt
(Geschichte, Quiz, Möwenflug, Kran, Schatztruhe); dafür braucht `img/` zusätzlich die
App-Bilder `app.geschichte`, `app.kran` aus `landingpage/bilder`.

Dritte Fassung (18.11.2026): heller Look wie die Homepage (Farbflecken, weiße Karten, Wellen unten).
Problem-Szenen mit Grafiken: 10 Kinder, 8 mit Fragezeichen (80 %); Säulen Barzahlungen 2021 58 % und
2023 51 %, Münze wird Handy; Linie der überschuldeten Erwachsenen 2019 bis 2025 mit echten Werten aus
dem SchuldnerAtlas 2025, Tabellenband, Tab. 54 (6,922 / 6,853 / 6,158 / 5,884 / 5,651 / 5,557 / 5,668 Mio.),
leuchtende Spitze, „Heute“-Marke, dazu unter 30 Jahren 763.000 (+19.000, +2,6 %). Achtung: Bei den
unter 30-Jährigen ist die Zahl seit 2013 stark gesunken (1,79 Mio.) und erst 2025 leicht gestiegen;
„immer mehr“ darf man darum nicht sagen.

Vierte Fassung (18.11.2026): Sprecherin „Matilda“ (ElevenLabs `XrExE9yKIg1WjnnlVkGX`, eleven_multilingual_v2,
Tempo 1,1), im Sprechtext „Taléria“ geschrieben, damit die Betonung stimmt (Marcs Wahl). Aufnahme mit
`/with-timestamps`; die Wortzeiten stehen in `vo.json` (`words`) und steuern die Untertitel, die Wort für Wort
erscheinen. Geräusche aus `assets/audio` (Liste `window.SFX` im Video, beim Aufnehmen als `sfx.json` gespeichert),
dazu ein mit ffmpeg erzeugtes Handy-Vibrieren (`sound.buzz.mp3`, 170 Hz gepulst).
