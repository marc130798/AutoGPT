# BILDER.md – Bildliste für die Karte (mit Gemini)

Entschieden mit Marc am 10.10.2026: Taleria bekommt einen **3D-Animationsfilm-Look**. Die Bilder erstellt Marc mit Gemini, die Bewegung (Nebel, Schiff, Wellen, Leuchten) macht der Code.
Diese Datei sagt, welche Bilder es braucht und was man Gemini dafür schreibt.

Zuerst kommt die Karte. Die Figuren (Talo, Tala, Meister Taleron) folgen in einem eigenen Schritt.

---

## 1. So gehst du vor

1. Fang mit dem **Hafen** an (Bild 1). Probier so lange, bis er dir richtig gefällt. Er ist die Vorlage für alle anderen Bilder.
2. Bei jedem weiteren Bild lädst du den fertigen Hafen in Gemini mit hoch. Der Text dazu sagt Gemini, dass es Stil, Blickwinkel und Licht übernehmen soll. So passen alle Bilder zusammen.
3. Kopier immer den **ganzen Text** aus dem Kasten. Die Beschreibung der Insel darfst du ändern, die Sätze zu Stil, Blickwinkel und Hintergrund nicht.
4. Gefällt dir ein Bild nicht ganz, schreib Gemini einfach, was anders sein soll („mehr Palmen“, „den Steg länger“), und lass es überarbeiten.
5. Schick mir die fertigen Bilder hier im Chat. Ich stelle sie frei (der pinke Hintergrund verschwindet), mache sie passend klein für die App und baue sie ein.

**Wichtig für alle Bilder**
- Keine Schrift, keine Logos, keine Kanonen oder andere Waffen.
- Nichts, das wie eine bekannte Filmfigur aussieht.
- Der Hintergrund muss einfarbig sein (pink oder schwarz, steht beim Bild). Kein Schatten auf dem Hintergrund und **kein Wasser um die Insel**. Das Wasser zeichnet die App selbst, auch die Gischt am Strand.
- Das Licht kommt immer von links oben, auch wenn die Insel im Spiel eine andere Tageszeit hat. Auf der Karte scheint für alle Inseln dieselbe Sonne.

---

## 2. Die Bilder für den Start (Priorität 1)

### Bild 1: Hafen von Taleria → `map.island.hafen`

```
Eine kleine runde Insel als Spielfeld auf einer Schatzsucher-Karte, ohne Wasser drumherum. Rundherum ein heller Sandstrand, innen grüne Wiese mit ein paar Palmen. Auf der Insel: ein Holzsteg, der rechts über den Strand hinausragt, ein kleines Steinhaus (das Hafenkontor), ein altes Lagerhaus, eine kleine Werft mit einem Boot im Bau, ein Fischbrötchen-Stand, ein kleiner bunter Marktplatz und ein kleiner rot-weißer Leuchtturm. Die Insel füllt etwa zwei Drittel der Bildbreite. Quadratisches Bild.

Stil: hochwertiger 3D-Animationsfilm-Look, wie ein gerendertes Standbild aus einem Kinofilm für Kinder. Weiche, runde Formen, leuchtende, warme Farben, sonniges Licht von links oben, weiche Schatten nach rechts unten, viele liebevolle kleine Details. Keine Schrift, keine Logos, keine Waffen, keine Menschen, keine Tiere.

Kamera schräg von oben (etwa 45 Grad), wie die Karte in einem Handyspiel. Die Insel steht vollständig in der Bildmitte, mit Abstand zu allen Rändern.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Wasser, ohne Boden.
```

### Bild 2: Tauschinsel → `map.island.tauschinsel`

Den Hafen als Bild anhängen.

```
Gleicher Stil, gleicher Blickwinkel, gleiche Größe und gleiches Licht wie im angehängten Bild, aber eine andere Insel:

Eine kleine runde Insel ohne Wasser drumherum, auf der es kein Geld gibt und alle tauschen. Rundherum Sandstrand, innen grüne Wiese und ein kleiner Hügel. Auf der Insel: ein großer Tauschmarkt mit bunten Stoffbahnen und Wimpeln, Körbe mit Obst, Fischen und Werkzeug, eine kleine Quelle am Hügel, ein Eisstand am Strand, eine Werkstatt mit Fischernetzen, ein hölzerner Aussichtsturm und eine kleine Anlegestelle. Quadratisches Bild.

Keine Schrift, keine Logos, keine Waffen, keine Menschen, keine Tiere.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Wasser, ohne Boden.
```

### Bild 3: Wunschinsel → `map.island.wunschinsel`

Den Hafen als Bild anhängen.

```
Gleicher Stil, gleicher Blickwinkel, gleiche Größe und gleiches Licht wie im angehängten Bild, aber eine andere Insel:

Eine kleine runde Insel ohne Wasser drumherum, auf der Wünsche wohnen. Rundherum Sandstrand mit ein paar angespülten Glasflaschen, innen grüne Wiese und ein Hügel mit einer gemütlichen Höhle. Auf der Insel: ein kleiner Laden mit glitzernden Schaufenstern, ein Packhaus, ein runder Platz, ein großer Felsen und in der Mitte ein Wunschbrunnen mit goldenen Lichterketten. Quadratisches Bild.

Keine Schrift, keine Logos, keine Waffen, keine Menschen, keine Tiere.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Wasser, ohne Boden.
```

### Bild 4: Das Schiff der Crew → `ship.crew`

Den Hafen als Bild anhängen.

```
Gleicher Stil, gleicher Blickwinkel und gleiches Licht wie im angehängten Bild, aber statt einer Insel ein Schiff:

Ein altes, liebevoll gepflegtes Segelschiff aus Holz mit zwei Masten, cremeweißen Segeln mit einem goldenen Kompass-Zeichen und blauen Wimpeln. An Deck Fässer, Kisten und Seile, keine Kanonen, keine Figuren. Das Schiff fährt nach rechts. Kein Wasser, keine Bugwelle. Das Schiff füllt etwa drei Viertel der Bildbreite. Quadratisches Bild.

Keine Schrift, keine Logos, keine Waffen, keine Menschen, keine Tiere.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Wasser, ohne Boden.
```

### Bild 5: Das Meer → `map.background`

```
Die Meeresoberfläche direkt von oben gesehen: nur Wasser, kein Horizont, keine Inseln, keine Schiffe, kein Himmel. Klares tropisches Meer in Türkis bis Tiefblau, sanfte kleine Wellen, ein paar Lichtreflexe der Sonne. Überall gleichmäßig, ohne hellere oder dunklere Ecken, damit man mehrere Bilder nahtlos untereinander setzen kann. Hochformat.

Stil: hochwertiger 3D-Animationsfilm-Look, wie ein gerendertes Standbild aus einem Kinofilm für Kinder, leuchtende Farben, Sonnenlicht von links oben. Keine Schrift, keine Logos.
```

### Bild 6: Wolke → `map.cloud.1`

Nur eine längliche Wolke (entschieden mit Marc: keine runden Wolken). Die App spiegelt sie und zeigt sie verschieden groß.

```
Eine einzelne flauschige weiße Wolke, lang und flach, im 3D-Animationsfilm-Look, leicht von oben gesehen, weiche Ränder, Sonnenlicht von links oben, unten ganz leicht bläulich schattiert. Hintergrund: komplett reines Schwarz (#000000), sonst nichts im Bild. Keine Schrift.
```

---

## 3. Später: die weiteren Inseln (Priorität 2)

Wie Bild 2: Hafen anhängen, denselben Text nehmen und nur die Beschreibung der Insel austauschen.
Gebraucht werden sie erst, wenn die Insel veröffentlicht wird. Bis dahin liegt sie im Nebel.

| Nr. | Datei | Was auf die Insel gehört |
| --- | --- | --- |
| 4 | `map.island.spar-insel` | Herbst, bunte Blätter, ein Dorf aus Baumhäusern, eine kleine Lichtung, ein Turm aus Nüssen, eine Holzbank, eine Hütte, eine Schatzkammer im Fels, ein Vorratsspeicher |
| 5 | `map.island.taschengeld-bucht` | ruhige Bucht mit Holzstegen, ein Kiosk mit bunten Gläsern, ein Haus mit drei Truhen davor, ein kleines Kontor, eine Grotte |
| 6 | `map.island.marktinsel` | Markt mit drei Obstständen, eine Halle mit Regalen, ein Platz, ein kleines Postkontor, eine Picknickwiese |
| 7 | `map.island.werbe-riff` | ein Riff mit bunten, leuchtenden Schildern ohne Schrift, eine kleine Bühne, ein Turm mit Lautsprechern, ein Lager mit Kisten |
| 8 | `map.island.verdienst-insel` | eine Werft mit Holzgerüst, eine Straße mit kleinen Werkstätten, ein Flohmarkt, ein Limonadenstand |
| 9 | `map.island.bank-insel` | Steinmauern, ein Bankgebäude mit hellen Säulen, Messing und Holz, ein Tresor im Fels, ein kleiner Platz |
| 10 | `map.island.zins-insel` | Winterinsel mit glitzerndem Schnee, Iglus, ein kleiner Eispalast, ein Schneeball-Hang |
| 11 | `map.island.leih-lagune` | Insel mit einer türkisen Lagune in der Mitte, Laternen, Stege, ein Leihhaus |
| 12 | `map.island.sicherheits-festung` | eine kleine Burg mit dicken Mauern, ein Tor, ein Wachturm, Fackeln |
| 13 | `map.island.risiko-klippen` | hohe Klippen, ein Pfad, eine Schutzhütte, eine Wetterstation, eine kleine Höhle |
| 14 | `map.island.zukunftsinsel` | junge Bäume, eine Baumschule, eine Sternwarte auf einem Hügel, ein Wegweiser |
| 15 | `map.island.schatzinsel` | ein großer Felsen mit einer alten Truhe, goldener Strand, Palmen, eine kleine Bucht |

---

## 4. Startseite des Kindes (nächster Schritt)

Statt weißem Hintergrund ein Bild, oben Talo und Tala, der Leuchtturm als echtes Bild, das Schiff bei „Dein Schiff“ und große Bild-Kacheln statt schlichter Knöpfe.
Das Schiff gibt es schon (Bild 4), es wird wiederverwendet.

### Bild 7: Hintergrund der Startseite → `home.background`

```
Blick vom Deck eines alten Holz-Segelschiffs auf das Meer von Taleria an einem sonnigen Vormittag. Unten im Bild ein Stück helles Holzdeck mit Reling, dahinter ruhiges türkisblaues Meer mit zwei, drei kleinen Inseln am Horizont, oben viel heller Himmel mit ein paar länglichen weißen Wolken. Die Mitte des Bildes ist ruhig und ohne viele Einzelheiten, damit Text und Knöpfe darauf gut lesbar sind. Hochformat 9:16.

Stil: hochwertiger 3D-Animationsfilm-Look, wie ein gerendertes Standbild aus einem Kinofilm für Kinder. Weiche, runde Formen, leuchtende, warme Farben, sonniges Licht von links oben. Keine Schrift, keine Logos, keine Waffen oder Kanonen, keine Menschen, keine Tiere.
```

### Bild 8: Leuchtturm → `parent.lighthouse`

Den Hafen als Bild anhängen.

```
Gleicher Stil und gleiches Licht wie im angehängten Bild, aber statt einer Insel ein einzelner Leuchtturm:

Ein rot-weiß gestreifter Leuchtturm auf einem kleinen runden Felsen mit etwas Gras, oben eine warm leuchtende Laterne und ein dunkelblaues Dach. Leicht von oben gesehen, steht vollständig in der Bildmitte mit Abstand zu allen Rändern. Kein Wasser. Quadratisches Bild.

Keine Schrift, keine Logos, keine Menschen, keine Tiere.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Wasser, ohne Boden.
```

### Bild 9 bis 13: Bilder für die Kacheln

Jeweils den Hafen anhängen und nur den Gegenstand austauschen:

| Nr. | Datei | Gegenstand (statt „GEGENSTAND“ einsetzen) |
| --- | --- | --- |
| 9 | `icon.map` | eine halb aufgerollte alte Schatzkarte mit Inseln und einer gestrichelten Route, daneben ein Messing-Kompass |
| 10 | `icon.treasure` | eine offene hölzerne Schatztruhe mit Goldbeschlägen, gefüllt mit goldenen Talern |
| 11 | `icon.tasks` | eine Schriftrolle mit rotem Wachssiegel und einer Feder |
| 12 | `icon.badges` | ein goldener Orden mit einem Anker darauf an einem blauen Band |
| 13 | `icon.collection` | eine offene Muschel mit einer glänzenden Perle darin |

```
Gleicher Stil und gleiches Licht wie im angehängten Bild, aber statt einer Insel ein einzelner Gegenstand: GEGENSTAND. Leicht von oben gesehen, groß in der Bildmitte mit Abstand zu allen Rändern. Quadratisches Bild.

Keine Schrift, keine Logos, keine Waffen, keine Menschen, keine Tiere.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Boden.
```

### Talo und Tala: zuerst der Entwurf, dann die Posen

Talo und Tala kommen später auf fast jedem Bildschirm vor. Deshalb zuerst je ein **Entwurf** von vorn. Erst wenn er dir gefällt, entstehen daraus die Posen (für die Startseite: winken), immer mit dem Entwurf als angehängtem Bild, damit die Figur gleich bleibt.
Bitte prüfen: Die Figuren dürfen keiner bekannten Filmfigur ähneln, und Tala trägt keine Krone und kein Kleid (`FIGUREN.md`).

**Bild 14: Talo, Entwurf → `character.talo`** (Hafen anhängen)

```
Gleicher Stil und gleiches Licht wie im angehängten Bild, aber statt einer Insel ein Figurenentwurf für eine Kinder-App:

Talo, ein junger, freundlicher Fuchs, Kapitän eines kleinen Segelschiffs. Goldrotes Fell, weiße Schwanzspitze, große runde bernsteinfarbene Augen, kurze runde Schnauze, rundliche, kindgerechte Proportionen mit großem Kopf. Dunkelblaue Kapitänsjacke mit goldenen Knöpfen, eine kleine dunkelblaue Kapitänsmütze und ein Messing-Kompass an einer Kette um den Hals. Er steht aufrecht, ganzer Körper von vorn, freundliches Lächeln. Quadratisches Bild, die Figur vollständig in der Mitte.

Keine Schrift, keine Logos, keine Waffen.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Boden.
```

**Bild 15: Tala, Entwurf → `character.tala`** (Hafen anhängen)

```
Gleicher Stil und gleiches Licht wie im angehängten Bild, aber statt einer Insel ein Figurenentwurf für eine Kinder-App:

Tala, ein mutiges, fröhliches Schweinemädchen, die Zahlmeisterin der Crew. Rosa, rundliche, kindgerechte Proportionen, große freundliche Augen. Ein goldenes Halstuch, eine türkisfarbene Weste mit Taschen, ein Gürtel mit einer Ledertasche, an der ein goldener Schlüssel hängt. In der Hand ein kleines Rechnungsbuch mit einer Feder. Keine Krone, kein Kleid. Sie steht aufrecht, ganzer Körper von vorn, offenes Lachen. Quadratisches Bild, die Figur vollständig in der Mitte.

Keine Schrift, keine Logos, keine Waffen.

Hintergrund: komplett einfarbig reines Grün (#00FF00), ohne Verlauf, ohne Schatten, ohne Boden.
```

Tala bekommt einen grünen statt pinken Hintergrund, weil sie selbst rosa ist. Sonst würde beim Freistellen ein Teil von ihr verschwinden.

---

## 5. Was der Code dazu macht

- **Meer:** Das Wasserbild wird untereinander gesetzt (jedes zweite gespiegelt, damit man keine Kante sieht). Darüber glitzert es und kleine Wellen bewegen sich.
- **Um jede Insel:** flaches türkises Wasser und Gischt, die sich bewegt.
- **Nebel-Start:** Beim Öffnen der Karte liegen Wolken über allem und ziehen dann auseinander.
- **Inseln im Nebel:** Wolken ziehen langsam darüber.
- **Gesperrte Inseln:** etwas blasser, mit Schloss. Wird eine Insel frei, springt das Schloss auf und die Insel leuchtet.
- **Schiff:** segelt zur nächsten Insel, sobald sie offen ist.
- **Geschaffte Inseln:** Eine Flagge weht.

Solange ein Bild fehlt, zeichnet die App einen einfachen Ersatz (CLAUDE.md Abschnitt 11).

---

## 6. Rechte

- Vor dem Start die Nutzungsbedingungen von Gemini prüfen: Darf man die Bilder in einer kostenpflichtigen App, in Werbung und für Merchandise nutzen?
- Jedes Bild, das in die App kommt, steht in `ASSETS_LICENSES.md` (Urheber: Marc mit Google Gemini, Datum).
- Reine KI-Bilder sind rechtlich oft nur schwach geschützt. Für Logo und Hauptfiguren, die du schützen willst, mit einer Fachperson sprechen (CLAUDE.md Abschnitt 9).

---

## 7. Technische Angaben (für Claude Code)

- Werkzeug: `python3 tool/bilder_freistellen.py --art insel|schiff|wolke|meer <Bild> <Schlüssel>` (braucht Pillow und numpy). Es legt die fertige Datei unter `assets/images/` ab.
- Inseln (768 px breit) und Schiff (512 px): PNG mit durchsichtigem Hintergrund. Durchsichtig wird nur die einfarbige Fläche, die mit dem Bildrand verbunden ist (pinke Dinge auf der Insel bleiben), mit weichem Rand und ohne pinken Farbsaum, zugeschnitten auf den Inhalt.
- Meer (`map.background`): JPG, 768 px breit, aus Bild und Spiegelbild zu einer Kachel zusammengesetzt, die sich nahtlos wiederholt.
- Wolke (640 px): PNG, die Helligkeit wird zur Deckkraft (weiß auf schwarz).
- Die Originale von Gemini liegen in `design/gemini/` (gleicher Name wie der Schlüssel). So lassen sie sich jederzeit neu freistellen.
- Alle Bilder vor dem Einbau in `ASSETS_LICENSES.md` eintragen.

**Stand 10.10.2026:** Bild 1 bis 6 sind da und eingebaut (eine längliche Wolke).
