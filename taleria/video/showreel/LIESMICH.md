# Showreel Taleria (18.11.2026)

15 Sekunden Motion-Graphics, 16:9 (1920 × 1080) und 9:16 (1080 × 1920), 30 Bilder pro Sekunde, Schnitte auf den Beat (120 BPM).
Nur vorhandenes Material: App-Screenshots aus `landingpage/bilder`, Bilder aus `assets/images`, Klänge aus `assets/audio`.
Der Beat (Kick, Clap, Hi-Hat, Bass, Akkord) ist im Code erzeugt (numpy), kein fremder Dienst.

Szenen: Logo-Einschlag · Kinetische Schrift „Geld verstehen. Abenteuer erleben.“ · Inselkarte · Lernen (Handy in 3D, „Richtig!“, Konfetti) ·
Mini-Spiele (schräge Galerie) · Tauchgang (Welle, Perlen) · Schatztruhe (Münzen, Zähler) · Leuchtturm für Eltern · Abschluss mit Talo, Tala, Orden und „Jetzt kostenfrei testen“.

Neu bauen: Ordner mit `img/` (Bilder wie oben) und `fonts/` (aus `landingpage/schriften`) anlegen,
`node render.js 1920 1080 fl` und `node render.js 1080 1920 fp`, Beat erzeugen, mit ffmpeg zusammenfügen.
