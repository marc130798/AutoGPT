# Erklärvideo Taleria (18.11.2026)

Etwa 80 Sekunden, 16:9 (1920 × 1080) und 9:16 (1080 × 1920), 30 Bilder pro Sekunde.
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
