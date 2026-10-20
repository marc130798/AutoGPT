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

## 4b. Die Inseln von innen

Tippt das Kind auf der Karte auf eine Insel, füllt sie den ganzen Bildschirm. Auf ihrem Weg liegen die Stationen als Wegmarken (die zeichnet die App). Jede Insel braucht dafür ein Bild im Hochformat. Immer das Kartenbild der Insel anhängen, damit es dieselbe Insel wird.

| Insel | Datei | Stand |
| --- | --- | --- |
| Hafen | `island.hafen.background` | da (10.10.2026) |
| Tauschinsel | `island.tauschinsel.background` | da (10.10.2026) |
| Wunschinsel | `island.wunschinsel.background` | da (10.10.2026) |

**Tauschinsel** (Kartenbild der Tauschinsel anhängen):

```
Die gleiche Insel wie im angehängten Bild, aber ganz nah und im Hochformat 9:16, sie füllt das ganze Bild. Blick schräg von oben. Unten am Rand eine kleine Anlegestelle aus Holz am Wasser. Von dort schlängelt sich ein heller Sandweg in großen Kurven nach oben durch die ganze Insel: vorbei an einem Eisstand am Strand, einer Werkstatt mit Fischernetzen, einem großen Tauschmarkt mit bunten Stoffbahnen und Wimpeln und Körben voller Obst, Fische und Werkzeug, einer kleinen Quelle an einem Hügel, bis zu einem hölzernen Aussichtsturm ganz oben. Palmen, Wiesen und an den Seiten etwas türkises Wasser. Der Weg ist gut sichtbar und frei, ohne Gebäude darauf.

Stil: hochwertiger 3D-Animationsfilm-Look, wie ein gerendertes Standbild aus einem Kinofilm für Kinder. Weiche Formen, leuchtende, warme Farben, sonniges Licht von links oben. Keine Schrift, keine Logos, keine Waffen, keine Menschen, keine Tiere.
```

**Wunschinsel** (Kartenbild der Wunschinsel anhängen):

```
Die gleiche Insel wie im angehängten Bild, aber ganz nah und im Hochformat 9:16, sie füllt das ganze Bild. Blick schräg von oben, warmes Licht am späten Nachmittag. Unten am Rand ein Strand mit angespülten Glasflaschen und ein kleiner Steg am Wasser. Von dort schlängelt sich ein heller Weg aus Sand und Steinplatten in großen Kurven nach oben durch die ganze Insel: vorbei an einem kleinen Laden mit glitzernden Schaufenstern, einem Packhaus mit Kisten, einem runden Platz, einer gemütlichen Höhle in einem Hügel und einem großen Felsen, bis zu einem Wunschbrunnen mit goldenen Lichterketten ganz oben. Palmen, Wiesen und an den Seiten etwas türkises Wasser. Der Weg ist gut sichtbar und frei, ohne Gebäude darauf.

Stil: hochwertiger 3D-Animationsfilm-Look, wie ein gerendertes Standbild aus einem Kinofilm für Kinder. Weiche Formen, leuchtende, warme Farben, sonniges Licht von links oben. Keine Schrift, keine Logos, keine Waffen, keine Menschen, keine Tiere.
```

Den Verlauf des Wegs zeichnet Claude Code im Bild nach und trägt ihn im Manifest ein (`route`). Darauf verteilt die App die Wegmarken.

---

## 4c. Posen, Ränge, Orden (alle da)

### Talo und Tala winkend → `character.talo.wave`, `character.tala.wave`

Jeweils das fertige Bild der Figur anhängen (`design/gemini/character.talo.jpg`, `character.tala.jpg`).

```
Gleiche Figur wie im angehängten Bild, gleicher Stil, gleiche Kleidung und gleiche Größe. Er winkt fröhlich mit einer Hand und lacht. Ganzer Körper von vorn, quadratisches Bild, die Figur vollständig in der Mitte. Keine Schrift, keine Logos, keine Waffen. Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Boden.
```

```
Gleiche Figur wie im angehängten Bild, gleicher Stil, gleiche Kleidung und gleiche Größe. Sie winkt fröhlich mit einer Hand und lacht, das Buch hält sie in der anderen Hand. Ganzer Körper von vorn, quadratisches Bild, die Figur vollständig in der Mitte. Keine Schrift, keine Logos, keine Waffen. Hintergrund: komplett einfarbig reines Grün (#00FF00), ohne Verlauf, ohne Schatten, ohne Boden.
```

Danach auf dieselbe Art „freut sich“ (`.happy`) und „denkt nach“ (`.think`) für die Stationen.

| Pose | Talo | Tala |
| --- | --- | --- |
| winkt (`.wave`) | da | da |
| freut sich (`.happy`) | da | da |
| denkt nach (`.think`) | da | da |

### Fünf Rang-Abzeichen → `rank.schiffsjunge` … `rank.kapitaen`

Den Orden von der Startseite (Bild 12) anhängen, damit alle Abzeichen dazu passen. Von Rang zu Rang wertvoller:

| Datei | Rang | Abzeichen (statt „ABZEICHEN“ einsetzen) | Stand |
| --- | --- | --- | --- |
| `rank.schiffsjunge` | Schiffsjunge | ein rundes Abzeichen aus hellem Holz mit einem Seilknoten in der Mitte und einem Rand aus Tau | da |
| `rank.matrose` | Matrose | ein rundes Abzeichen aus Bronze mit einem kleinen Anker in der Mitte | da |
| `rank.bootsmann` | Bootsmann | ein rundes Abzeichen aus Silber mit zwei gekreuzten Rudern in der Mitte | da |
| `rank.steuermann` | Steuermann | ein rundes Abzeichen aus Gold mit einem Steuerrad in der Mitte | da |
| `rank.kapitaen` | Kapitän | ein prächtiges rundes Abzeichen aus Gold mit einer Kompassrose, kleinen blauen Edelsteinen am Rand und Lorbeerzweigen | da (mit Buchstaben N, W, E, S; bei Bedarf ohne Buchstaben neu machen) |

```
Gleicher Stil und gleiches Licht wie im angehängten Bild, aber statt des Ordens ein einzelnes Abzeichen: ABZEICHEN. Ohne Band. Leicht von oben gesehen, groß in der Bildmitte mit Abstand zu allen Rändern. Quadratisches Bild. Keine Schrift, keine Zahlen, keine Logos, keine Waffen. Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Boden.
```

### Orden der Inseln → `badge.hafen`, `badge.tauschinsel`, `badge.wunschinsel`

Bekommt das Kind, wenn es eine Insel schafft. Wieder den Orden von der Startseite anhängen.

| Datei | Orden | Motiv (statt „MOTIV“ einsetzen) | Stand |
| --- | --- | --- | --- |
| `badge.hafen` | Erster Landgang | ein kleiner rot-weißer Leuchtturm | da |
| `badge.tauschinsel` | Meistertauscher | zwei Hände, die einen Apfel gegen einen Fisch tauschen | da |
| `badge.wunschinsel` | Klarer Kompass | ein Kompass, dessen Nadel auf einen kleinen goldenen Stern zeigt | da (mit Buchstaben W, E, S) |

```
Gleicher Stil, gleiches Licht und gleicher Bildaufbau wie im angehängten Bild: ein goldener Orden an einem kurzen blauen Stoffband. Das Band ist oben zu einer kleinen Schlaufe gelegt, genau wie im angehängten Bild, und hört dort auf. Auf dem Orden statt des Ankers: MOTIV.
Orden und Band zusammen sind nur etwa zwei Drittel so hoch wie das Bild. Das ganze Band ist zu sehen, nichts ragt über den Bildrand hinaus, rundherum ist viel freier Platz.
Leicht von oben gesehen. Quadratisches Bild. Keine Schrift, keine Zahlen, keine Logos, keine Waffen. Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Boden.
```

Ist das Band trotzdem abgeschnitten, im selben Gemini-Chat nachschieben: „Bitte weiter herauszoomen. Das ganze blaue Band muss zu sehen sein, mit freiem Platz bis zum Rand.“

---

## 4d. Die Figuren auf den ersten drei Inseln (alle da)

Diese Figuren sprechen in den Stationen mit dem Kind. Bis jetzt sieht man dort nur einen farbigen Kreis mit Namen. Insel für Insel:

- **Schritt A, Hafen:** Händler, Verkäuferin, Bootsbauer
- **Schritt B, Tauschinsel:** Bruno, Greta, Otti, Olga
- **Schritt C, Wunschinsel:** Elsa, Moritz
- **Schritt D:** Meister Taleron

Für jede Figur das fertige Bild von Talo anhängen (`design/gemini/character.talo.jpg`), damit alle im gleichen Stil sind. Dann diesen Text, „FIGUR“ durch die Beschreibung aus der Tabelle ersetzen:

```
Gleicher Stil wie im angehängten Bild (hochwertiger 3D-Animationsfilm-Look, weiche Formen, warme Farben, Licht von links oben), aber eine ganz andere Figur: FIGUR. Freundlicher Blick, lächelt. Ganzer Körper von vorn, quadratisches Bild, die Figur vollständig in der Mitte mit Abstand zu allen Rändern. Keine Schrift, keine Logos, keine Waffen. Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Boden.
```

Die Tiere der Hafen-Figuren hat Claude Code vorgeschlagen und Marc so gemacht (jetzt auch in FIGUREN.md), die anderen standen schon in FIGUREN.md.

Tipp: Bei Figuren mit viel Weiß oder Grau (zum Beispiel einer weißen Schürze) oder mit Lila und Rosa besser grünen Hintergrund (#00FF00) nehmen, außer die Figur trägt selbst Grün. Pink färbt Weiß rosa und verfälscht Lila, Grün lässt sich sauberer herausrechnen. Dann im Text „reines Pink-Magenta (#FF00FF)“ durch „reines Grün (#00FF00)“ ersetzen.

| Datei | Figur | Beschreibung (statt „FIGUR“ einsetzen) | Stand |
| --- | --- | --- | --- |
| `character.haendler` | Händler im Hafen | ein gemütliches Walross mit großem Schnurrbart, grüner Kaufmannsweste über weißem Hemd und kleiner runder Brille, es hält ein dickes Buch unter dem Arm | da |
| `character.verkaeuferin` | Verkäuferin am Fischbrötchen-Stand | eine fröhliche Seehündin mit weißer Schürze und rot-weiß kariertem Kopftuch, sie hält ein Tablett mit Fischbrötchen | da |
| `character.bootsbauer` | Bootsbauer | ein kräftiger Biber mit Zimmermannsweste und Bleistift hinter dem Ohr, er trägt ein Holzbrett unter dem Arm | da |
| `character.bruno` | Bruno, Obstbauer | ein großer, gemütlicher Braunbär mit Strohhut und grüner Latzhose, er hält einen Korb voller roter Äpfel | da |
| `character.greta` | Greta, Seilmacherin | eine weiße Ziege mit kleinen Hörnern, rotem Kopftuch und Lederschürze, über der Schulter trägt sie aufgerollte Seile | da |
| `character.otti` | Otti, Fischer | ein Fischotter mit gelber Regenjacke und Fischermütze, er hält einen geflochtenen Korb mit glänzenden Fischen | da |
| `character.olga` | Olga, Inselälteste | eine alte, freundliche Landschildkröte mit Brille und Wollschal, sie stützt sich auf einen Stock aus Treibholz und hält eine aufgerollte alte Karte | da |
| `character.elsa` | Elsa, Glitzerladen | eine Elster mit glänzend schwarz-weißem Gefieder mit blauem Schimmer und lila Weste, behängt mit vielen glitzernden goldenen Ketten und Ringen (**grüner Hintergrund**, sonst leidet das Lila) | da |
| `character.moritz` | Moritz, zufrieden mit wenig | ein Murmeltier in einem einfachen hellbraunen Hemd mit bunten Flicken in Blau, Gelb und Grün, es lächelt zufrieden und hält eine Tasse Tee | da |
| `character.taleron` | Meister Taleron | ein großes, uraltes, freundliches Seeungeheuer mit türkisgrünen Schuppen, langem Bart aus Seetang mit kleinen Muscheln und runder Brille, es sitzt gemütlich und hat den langen Schwanz um sich gelegt, sanft und gar nicht gruselig | da |

---

## 4e. Der Tauchgang (beide da)

An den Ankerplätzen taucht das Kind und findet Dinge für seine Sammlung. Die Perle ist schon da (dasselbe Bild wie die Muschel mit Perle auf der Startseite).

### Bild 11: Unterwasserwelt → `underwater.background`

Als Vorlage das Bild vom Hafen von innen anhängen (`design/gemini/island.hafen.background.jpg`).

```
Hochwertiger 3D-Animationsfilm-Look wie im angehängten Bild: eine fröhliche, helle Unterwasserwelt in einer flachen Lagune. Sonnenstrahlen fallen von oben durch türkisblaues Wasser, unten heller Sandboden mit bunten Korallen, Seegras, ein paar Muscheln und kleinen bunten Fischen, hinten ein altes, freundlich aussehendes Schiffswrack aus Holz halb im Sand. Ruhig und einladend, nicht dunkel, nicht gruselig. Hochformat 9:16. Keine Schrift, keine Logos, keine Waffen, keine Figuren.
```

Stand: da.

### Bild 12: Fundstück → `collectible.wreck_item`

Als Vorlage den Orden mit dem Anker anhängen (`design/gemini/icon.badges.jpg`).

```
Gleicher Stil und gleiches Licht wie im angehängten Bild, aber statt des Ordens: ein kleiner Haufen Fundstücke vom Meeresgrund, eine alte Goldmünze, ein kleiner Messing-Kompass und eine hübsche Muschel, mit etwas grünem Seetang. Leicht von oben gesehen, groß in der Bildmitte mit Abstand zu allen Rändern. Quadratisches Bild. Keine Schrift, keine Zahlen, keine Logos, keine Waffen. Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Boden.
```

Stand: da (zweite Fassung mit Anker auf der Münze, von Marc gewählt). Tipp, falls ein Bild zu fotorealistisch wird: „Im verspielten 3D-Animationsfilm-Look mit runden, weichen Formen, nicht fotorealistisch.“ an den Text anhängen.

---

## 4f. Die Schatztruhe (Deine Truhen, alle da)

Die Seite „Deine Truhen“ hat jetzt Platz für Bilder. Die Schatztruhe selbst ist die Truhe von der Startseite (Bild 10), die muss nicht neu gemacht werden.

### Bild 13: Hintergrund der Schatzkammer → `treasure.background`

Als Vorlage das Startseiten-Bild anhängen (`design/gemini/home.background.jpg`).

```
Hochwertiger 3D-Animationsfilm-Look wie im angehängten Bild: eine gemütliche Schatzkammer im Bauch eines Holzschiffs. Warme Holzwände und Balken, Laternen mit warmem Licht, Seile, ein paar Fässer und Kisten am Rand, eine alte Seekarte an der Wand. Die Mitte des Bildes ist ruhig und eher leer (heller Holzboden), damit man dort Text gut lesen kann. Hochformat 9:16. Keine Schrift, keine Logos, keine Waffen, keine Figuren.
```

Stand: da.

### Bild 14 bis 17: Truhen und Zeichen

Als Vorlage jeweils die Schatztruhe von der Startseite anhängen (`design/gemini/icon.treasure.jpg`), dann „DING“ ersetzen:

```
Gleicher Stil und gleiches Licht wie im angehängten Bild, aber statt der Schatztruhe: DING. Leicht von oben gesehen, groß in der Bildmitte mit Abstand zu allen Rändern. Quadratisches Bild. Keine Schrift, keine Zahlen, keine Logos, keine Waffen. Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Boden.
```

| Nr. | Datei | Wofür | DING | Stand |
| --- | --- | --- | --- | --- |
| 14 | `pot.spend` | Bordkasse | eine kleine hölzerne Geldkassette mit Messingbeschlägen und Tragegriff, der Deckel ist offen, darin ein paar Goldmünzen | da |
| 15 | `pot.give` | Glückstruhe | eine kleine runde Holztruhe mit einem goldenen Herz auf dem Deckel, der Deckel ist offen, darin ein kleines Geschenk mit roter Schleife und ein paar Goldmünzen | da |
| 16 | `icon.ledger` | Kassenbuch | ein dickes, altes Buch mit braunem Ledereinband, aufgeschlagen, auf den Seiten nur Linien ohne Schrift, daneben eine Schreibfeder und ein kleines Tintenfass | da |
| 17 | `icon.wish` | Wunschschätze | ein großer, funkelnder goldener Wunschstern, um den ein paar Goldmünzen liegen | da |

---

## 4g. Aufträge, Orden und Fundstücke (alle da)

### Bild 18 und 19: Hintergründe

Als Vorlage jeweils die Schatzkammer anhängen (`design/gemini/treasure.background.jpg`).

**18 → `tasks.background` (Aufträge):**
```
Hochwertiger 3D-Animationsfilm-Look wie im angehängten Bild: die gemütliche Kapitänskajüte auf dem Schiff. Ein Schreibtisch mit Schreibfeder, an der Wand eine Pinnwand aus Kork mit ein paar leeren Zetteln ohne Schrift, eine Laterne, ein rundes Fenster mit Blick aufs Meer. Die Mitte des Bildes ist ruhig und eher leer, damit man dort Text gut lesen kann. Hochformat 9:16. Keine Schrift, keine Logos, keine Waffen, keine Figuren.
```

Stand: da.

**19 → `badges.background` (Orden):**
```
Hochwertiger 3D-Animationsfilm-Look wie im angehängten Bild: eine feierliche Ehrenwand in der Kapitänskajüte. Dunkelblaue Holzwand mit goldenen Verzierungen, ein paar leere goldene Haken, warmes Licht von Laternen, unten ein Holzregal. Die Mitte des Bildes ist ruhig und eher leer, damit man dort Text gut lesen kann. Hochformat 9:16. Keine Schrift, keine Logos, keine Waffen, keine Figuren.
```

Stand: da.

### Bild 20 bis 28: Fundstücke aus den Wracks

Jedes Fundstück hat ein eigenes Bild. Als Vorlage das Fundstück anhängen (`design/gemini/collectible.wreck_item.jpg`), dann „DING“ ersetzen:

```
Gleicher Stil und gleiches Licht wie im angehängten Bild, aber statt der Fundstücke: DING, frisch vom Meeresgrund, mit etwas grünem Seetang und ein paar Wassertropfen. Leicht von oben gesehen, groß in der Bildmitte mit Abstand zu allen Rändern. Quadratisches Bild. Keine Schrift, keine Zahlen, keine Logos, keine Waffen. Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Boden.
```

| Nr. | Datei | Fundstück | DING | Stand |
| --- | --- | --- | --- | --- |
| 20 | `collectible.hafen.1` | Alte Handelsmünze | eine große alte Goldmünze mit einem kleinen Segelschiff darauf, etwas angelaufen | da |
| 21 | `collectible.hafen.2` | Kleine Münztruhe | eine kleine verschlossene Holztruhe mit Eisenbeschlägen, mit Muscheln und Seepocken bewachsen, aus dem Spalt schauen ein paar Goldmünzen | da |
| 22 | `collectible.hafen.3` | Rostiges Preisschild | ein altes, rostiges Preisschild aus Metall an einer Schnur | da |
| 23 | `collectible.tauschinsel.1` | Alter Kompass | ein alter Messing-Kompass mit aufgeklapptem Deckel und einer roten Nadel | da |
| 24 | `collectible.tauschinsel.2` | Logbuch des Händlers | ein altes, zugeklapptes Logbuch mit Ledereinband und einem roten Lesebändchen | da |
| 25 | `collectible.tauschinsel.3` | Taucherbrille | eine alte Taucherbrille aus Messing und Leder mit rundem, leicht bläulichem Glas | da |
| 26 | `collectible.wunschinsel.1` | Kapitänskiste | eine kleine verzierte Kapitänskiste mit einem goldenen Anker auf dem geschlossenen Deckel | da |
| 27 | `collectible.wunschinsel.2` | Flaschenbrief | eine grüne Glasflasche mit Korken, in der ein zusammengerollter Brief liegt | da |
| 28 | `collectible.wunschinsel.3` | Altes Fotoalbum | ein altes Fotoalbum mit Stoffeinband, aufgeschlagen, darin kleine gemalte Bilder von Schiffen und Inseln | da |

Welches Bild zu welchem Fund gehört, steht in den Inhaltsdateien (`"fund_bild"` beim Tauchgang).

## 4p. Logo für den Startbildschirm

Am 20.10.2026 mit Marc besprochen: Der Startbildschirm zeigt das Schiffsdeck (`home.background`), Talo und Tala winken. Oben steht das Logo. Bis es da ist, zeichnet die App ein Holzschild „Taleria“. Hier ist die Schrift ausnahmsweise erwünscht. Gemini schreibt Wörter nicht immer richtig, darum genau prüfen, ob „Taleria“ dasteht, und sonst neu erzeugen lassen. Freistellen mit `--art insel` (768 px, durchsichtig).

| Nr. | Datei | Bild | Anhängen | Stand |
| --- | --- | --- | --- | --- |
| 163 | `brand.logo` | Logo „Taleria“ | Talo (design/gemini/character.talo.jpg), nur für den Stil | da |

Text für Bild 163:

> Hochwertiger 3D-Animationsfilm-Look wie im angehängten Bild: gleiche warme Farben, gleiches Licht von links oben, weiche runde Formen. Ein Logo für ein Kinder-Lernspiel auf einer Abenteuer-Insel: das Wort „Taleria“ (genau so geschrieben: T, a, l, e, r, i, a), in großen, dicken, runden und freundlichen Buchstaben aus glänzendem Gold mit dunkelbraunem Rand. Die Buchstaben stehen leicht geschwungen auf einem breiten Holzschild mit zwei Nägeln, wie an einem Hafen. Links neben dem Wort ein kleiner goldener Kompass, über dem „i“ ein kleiner funkelnder Stern statt des Punkts. Querformat, etwa doppelt so breit wie hoch, das Schild vollständig in der Bildmitte mit Abstand zu allen Rändern. Keine weiteren Wörter, keine Zahlen, keine Figuren, keine Waffen. Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Boden.

## 4o. Spar-Insel (Insel 4)

Vorbereitet am 11.10.2026 abends auf Marcs Wunsch, bevor die Texte der Spar-Insel geschrieben sind: Die Bildergeschichten geben die Geschichte vor, die Sätze schreibt Claude danach passend dazu. Reihenfolge: erst Karte (132), dann die Insel von innen (133, braucht 132 als Vorlage), dann Emma und Gustav (134, 135, sie sind Vorlagen für die Geschichten), danach Orden, Siegel, Funde und die Geschichten. Emma ist rotbraun, Gustav hellgrün: beide auf Pink. Gustav darf nicht wie eine bekannte Filmgrille aussehen (kein Zylinder, kein Regenschirm). Wo Zahlen nötig sind (Station 3: 50 Cent am Tag sind 3,50 € in der Woche; Station 5: Sparplan 30 Taler mit 5 pro Woche), zeichnet die App das Bild selbst. Ganze Texte in `design/prompts_spar_insel.txt`.

| Nr. | Datei | Bild | Anhängen | Stand |
| --- | --- | --- | --- | --- |
| 132 | `map.island.spar-insel` | Die Spar-Insel auf der Karte | das Kartenbild des Hafens (design/gemini/map.island.hafen.jpg) | fehlt |
| 133 | `island.spar-insel.background` | Die Spar-Insel von innen | das neue Kartenbild der Spar-Insel (Bild 132) | fehlt |
| 134 | `character.emma` | Emma, die Vorratsmeisterin | Talo (design/gemini/character.talo.jpg) | fehlt |
| 135 | `character.gustav` | Gustav, die Grille | Talo (design/gemini/character.talo.jpg) | fehlt |
| 136 | `badge.spar-insel` | Orden „Vorratsmeister“ | der Orden mit dem Anker (design/gemini/icon.badges.jpg) | fehlt |
| 137 | `badge.taleron_seal_a` | Taleron-Siegel A (nach der Spar-Insel) | der Orden mit dem Anker (design/gemini/icon.badges.jpg) und Meister Taleron (design/gemini/character.taleron.jpg) | fehlt |
| 138 | `collectible.spar-insel.1` | Fund: Tagebuch eines Matrosen | das Fundstück (design/gemini/collectible.wreck_item.jpg) | fehlt |
| 139 | `collectible.spar-insel.2` | Fund: Alte Spardose | das Fundstück (design/gemini/collectible.wreck_item.jpg) | fehlt |
| 140 | `collectible.spar-insel.3` | Fund: Schlüssel der Schatzkammer | das Fundstück (design/gemini/collectible.wreck_item.jpg) | fehlt |

**Bildergeschichten** (Querformat 4:3, ganze Szene; Text wie in Abschnitt 4h, mit Talas Kleidung):

| Nr. | Datei | Station | Bild | Vorlagen | SZENE | Stand |
| --- | --- | --- | --- | --- | --- | --- |
| 141 | `story.spar-insel.1.1` | 1 Warum sparen? | Herbst im Baumhaus-Dorf | Emma, Gustav | Herbst im Baumhaus-Dorf der Spar-Insel, bunte Blätter fallen. Emma, das Eichhörnchen, trägt einen vollen Korb Nüsse eine Strickleiter zu ihrem Baumhaus hinauf. Unten sitzt Gustav, die Grille, auf einem großen Pilz, spielt fröhlich Geige und lacht. | fehlt |
| 142 | `story.spar-insel.1.2` | 1 Warum sparen? | Der Winter kommt | Emma, Gustav | Winter im Baumhaus-Dorf, alles ist verschneit. Durch das warm leuchtende Fenster sieht man Emma gemütlich vor einem Regal voller Nüsse und Gläser sitzen. Draußen vor der Tür steht Gustav und fröstelt, mit leeren Taschen und einem Schal, der ihm zu dünn ist. | fehlt |
| 143 | `story.spar-insel.1.3` | 1 Warum sparen? | Wofür man spart | Talo | Talo steht vor einem Holzregal mit drei Einmachgläsern voller goldener Münzen ohne Zeichen. Auf jedem Glas klebt ein gemaltes Bild statt Schrift: auf dem ersten ein rotes Fahrrad, auf dem zweiten ein Pflaster, auf dem dritten eine kleine Sanduhr. Talo zeigt freundlich auf die Gläser. | fehlt |
| 144 | `story.spar-insel.1.4` | 1 Warum sparen? | Ein Vorrat für schlechte Zeiten | Emma, Tala | In Emmas gemütlichem Baumhaus: Emma öffnet eine kleine Holzkiste mit einem Vorrat Nüsse und einem Säckchen Münzen und zeigt sie Tala. Tala schaut neugierig hinein. | fehlt |
| 145 | `story.spar-insel.2.1` | 2 Mein erster Wunschschatz | Talas großer Wunsch | Tala | Auf einer sonnigen Herbstlichtung mit Pilzen sitzt Tala im bunten Laub. Über ihr schwebt eine Gedankenblase mit einem Paar roter Rollschuhe. Sie lächelt verträumt. | fehlt |
| 146 | `story.spar-insel.2.2` | 2 Mein erster Wunschschatz | Ein gutes Sparziel | Emma, Tala | Auf der Lichtung hält Emma eine kleine Holztafel hoch. Darauf sind nur drei gemalte Bilder nebeneinander, ohne Schrift: ein Paar Rollschuhe, ein Häufchen Münzen und eine Sanduhr. Tala schaut aufmerksam zu. | fehlt |
| 147 | `story.spar-insel.2.3` | 2 Mein erster Wunschschatz | Der Wunschschatz bekommt ein Bild | Tala | Tala hängt ein selbst gemaltes Bild von roten Rollschuhen an einen Ast. Darunter steht ihre kleine Schatztruhe aus Holz auf einem Baumstumpf. Sie ist stolz. | fehlt |
| 148 | `story.spar-insel.3.1` | 3 Kleine Beträge werden groß | Nur eine Nuss am Tag | Emma, Gustav | Am Fuß eines kleinen Nussstapels legt Emma eine einzelne Nuss obendrauf. Gustav steht daneben, hält seine Geige und lacht spöttisch über die kleine Nuss. | fehlt |
| 149 | `story.spar-insel.3.2` | 3 Kleine Beträge werden groß | Der Nussturm ist riesig | Gustav, Tala | Viele Wochen später: Der Nussturm ist riesig hoch geworden, höher als die Bäume. Gustav staunt mit offenem Mund und lässt fast seine Geige fallen, Tala klatscht begeistert in die Hände. | fehlt |
| – | – | 3 Kleine Beträge werden groß | 50 Cent am Tag, 3,50 € in der Woche | – | entfällt: zeichnet die App selbst | – |
| 150 | `story.spar-insel.4.1` | 4 Geduld lohnt sich | Eine Nuss jetzt oder drei morgen? | Emma, Tala | Auf einer Holzbank unter einem roten Herbstbaum: Emma hält in der einen Pfote eine einzelne Nuss, neben ihr steht ein Körbchen mit drei Nüssen und eine kleine Sanduhr. Tala sitzt daneben und überlegt mit schräg gelegtem Kopf. | fehlt |
| 151 | `story.spar-insel.4.2` | 4 Geduld lohnt sich | Gustav kann nicht warten | Gustav, Tala | Abendstimmung an der Holzbank: Gustav hat seine eine Nuss schon gegessen und reibt sich zufrieden den Bauch. Tala sitzt geduldig auf der Bank und schaut in den Sonnenuntergang. | fehlt |
| 152 | `story.spar-insel.4.3` | 4 Geduld lohnt sich | Warten hat sich gelohnt | Gustav, Tala | Am nächsten Morgen an der Holzbank: Tala hält stolz drei Nüsse in den Händen und strahlt. Gustav schaut mit leeren Händen etwas neidisch zu. | fehlt |
| 153 | `story.spar-insel.5.1` | 5 Einen Sparplan aufstellen | In der Planungs-Hütte | Emma, Tala | In einer gemütlichen kleinen Hütte mit rundem Fenster: Emma sitzt an einem Holztisch mit einer großen Papierrolle und einer Feder, Tala beugt sich neugierig darüber. Auf dem Papier sind nur kleine gemalte Nüsse und Pfeile, keine Zahlen. | fehlt |
| – | – | 5 Einen Sparplan aufstellen | Sparplan: 30 Taler, 5 pro Woche, 6 Wochen | – | entfällt: zeichnet die App selbst | – |
| 154 | `story.spar-insel.5.3` | 5 Einen Sparplan aufstellen | Die erste Woche geschafft | Tala | In der Planungs-Hütte: An der Wand hängt ein Papierstreifen mit sechs leeren Kästchen in einer Reihe. Tala malt mit einem dicken Stift einen Haken in das erste Kästchen und lacht. | fehlt |
| 155 | `story.spar-insel.6.1` | 6 Sparschwein, Spardose, Konto | Wo liegt Geld gut? | Emma | In einer Schatzkammer im Felsen mit warmem Laternenlicht: Auf einem Holzregal stehen ein rosa Sparschwein ohne Zeichen, eine bunte Spardose aus Blech und ein kleiner, schwerer Tresor mit dickem Schloss. Emma zeigt darauf. | fehlt |
| 156 | `story.spar-insel.6.2` | 6 Sparschwein, Spardose, Konto | Man hört, wie es wächst | Tala | Tala hält ihr rosa Sparschwein ohne Zeichen hoch und schüttelt es. Man sieht kleine Klimper-Striche in der Luft, Tala strahlt. | fehlt |
| 157 | `story.spar-insel.6.3` | 6 Sparschwein, Spardose, Konto | Überall verteilt | Gustav | Gustav hat seine Münzen überall versteckt: unter einem Stein, in einem Schuh, in einer Blüte und in seinem Geigenkasten. Eine Münze rollt gerade davon. Gustav kratzt sich ratlos am Kopf. | fehlt |
| 158 | `story.spar-insel.6.4` | 6 Sparschwein, Spardose, Konto | Später auf der Bank-Insel | Talo, Tala | Talo und Tala stehen am Ufer der Spar-Insel. Talo zeigt mit einem Fernrohr über das Meer auf eine ferne Insel mit einem hellen Gebäude mit Säulen. Tala schaut neugierig. | fehlt |
| 159 | `story.spar-insel.7.1` | 7 Schatztruhen-Challenge | Am Vorratsspeicher | Emma, Tala | Vor dem großen Vorratsspeicher in einem dicken hohlen Baumstamm mit runder Holztür: Tala legt eine goldene Münze ohne Zeichen in ihre kleine Schatztruhe, Emma klatscht anerkennend. | fehlt |
| 160 | `story.spar-insel.7.2` | 7 Schatztruhen-Challenge | Jede Woche ein bisschen | Tala | Vier kleine Stoffsäckchen stehen in einer Reihe auf einem Holztisch, jedes etwas voller als das davor. Tala legt gerade eine Münze in das vierte Säckchen und lächelt. | fehlt |
| 161 | `story.spar-insel.7.3` | 7 Schatztruhen-Challenge | Das Kartenstück im Speicher | Talo, Tala | Die runde Tür des Vorratsspeichers steht offen. Drinnen, zwischen Bergen von Nüssen, leuchtet golden ein altes Stück einer Schatzkarte, nur mit gemalten Wellen und einer Insel. Talo und Tala staunen mit großen Augen. | fehlt |
| 162 | `story.spar-insel.7.4` | 7 Schatztruhen-Challenge | Gustav fängt an | Emma, Gustav | Vor dem Vorratsspeicher gibt Emma Gustav lächelnd eine kleine Spardose. Gustav hält sie vorsichtig wie einen Schatz und freut sich. Bunte Blätter wirbeln um die beiden. | fehlt |

## 4n. Nachbesserungen

Aus den offenen Punkten (CLAUDE.md, Abschnitt 17): drei Bilder mit englischem „E“ für Osten und das Startbild der Kasse, auf dem Talo ohne Jacke ist. Immer das jetzige Bild anhängen, damit nur die eine Stelle anders wird. Ganze Texte in `design/prompts_spar_insel.txt`.

| Nr. | Datei | Was anders wird | Anhängen | Stand |
| --- | --- | --- | --- | --- |
| 128 | `rank.kapitaen` | Rang Kapitän ohne Buchstaben | das jetzige Kapitäns-Abzeichen (design/gemini/rank.kapitaen.jpg) | fehlt |
| 129 | `badge.wunschinsel` | Orden Wunschinsel ohne Buchstaben | der jetzige Orden der Wunschinsel (design/gemini/badge.wunschinsel.jpg) | fehlt |
| 130 | `collectible.wreck_item` | Fundstück ohne Buchstaben | das jetzige Fundstück (design/gemini/collectible.wreck_item.jpg) | fehlt |
| 131 | `game.till` | Startbild Kasse, Talo mit Jacke | Talo (design/gemini/character.talo.jpg) | fehlt |

## 4m. Bilder für „Talas Ausflüge“ (Wunschinsel 2)

Bonus-Spiel der Wunschinsel, Station 2 (Rucksack packen für drei Ausflüge, besprochen mit Marc am 11.10.2026). Startbild und die drei Ausflüge sind ganze Szenen im Querformat 4:3 (die App zeigt die Ausflüge etwas breiter, oben und unten fällt ein Rand weg). Die Dinge sind freigestellt auf Pink wie bei den anderen Mini-Spielen; Brötchen und Bonbons gibt es schon (Bild 108 und 111). Die Ausflugsbilder verraten nicht, was Tala braucht (keine Regenjacke an, kein Hut auf): Das soll das Kind aus Bild und Text selbst erkennen. Ganze Texte in `design/prompts_minispiele.txt`.

| Nr. | Datei | Bild | Vorlagen | Art | Stand |
| --- | --- | --- | --- | --- | --- |
| 117 | `game.backpack` | Startbild: Tala packt ihren Rucksack | character.tala | Szene 4:3 | fehlt |
| 118 | `game.backpack.waterfall` | Ausflug 1: Wanderung zum Wasserfall | character.tala | Szene 4:3 | fehlt |
| 119 | `game.backpack.beach` | Ausflug 2: Ein Tag am Strand | character.tala | Szene 4:3 | fehlt |
| 120 | `game.backpack.night` | Ausflug 3: Nachts zum Leuchtturm | character.tala | Szene 4:3 | fehlt |
| 121 | `item.wasserflasche` | Ding: Wasserflasche | – | freigestellt, quadratisch | fehlt |
| 122 | `item.regenjacke` | Ding: Regenjacke | – | freigestellt, quadratisch | fehlt |
| 123 | `item.sonnenhut` | Ding: Sonnenhut | – | freigestellt, quadratisch | fehlt |
| 124 | `item.taschenlampe` | Ding: Taschenlampe | – | freigestellt, quadratisch | fehlt |
| 125 | `item.glitzerbrille` | Ding: Glitzer-Sonnenbrille | – | freigestellt, quadratisch | fehlt |
| 126 | `item.fernglas` | Ding: Fernglas | – | freigestellt, quadratisch | fehlt |
| 127 | `item.kissen` | Ding: Kissen | – | freigestellt, quadratisch | fehlt |

## 4l. Bilder für die echten Mini-Spiele

Mit Marc besprochen am 11.10.2026: Die Mini-Spiele brauchen eigene Bilder. Startbilder (Querformat 4:3, ganze Szene) für Kasse und Markt; der Eisstand bekommt einen Wolkentag dazu (Sonne und Regen sind die Bilder 66 und 68), die Tauschkette nimmt als Startbild Bild 59. Stände und Dinge sind freigestellt auf Pink (wie die Fundstücke). Ganze Texte in `design/prompts_minispiele.txt`.

| Nr. | Datei | Spiel | Bild | Vorlagen | Art | Stand |
| --- | --- | --- | --- | --- | --- | --- |
| 102 | `game.till` | Fischbrötchen-Kasse (Hafen 4) | Startbild: die Kasse | character.talo | Szene 4:3 | da (Talo ohne Jacke; bei Gelegenheit neu, mit „Talo trägt seine blaue Kapitänsjacke wie auf dem Vorlagenbild“) |
| 103 | `game.market` | Markt-Einkauf (Hafen 7) | Startbild: der Markt | character.tala | Szene 4:3 | da (Gemini hat Schilder mit Schrift gemalt; die abgeschnittene Schrift an der Theke hat Claude entfernt) |
| 104 | `game.ice_stand.clouds` | Eisstand (Tauschinsel 4) | Der Eisstand an einem bewölkten Tag | character.tala, Bild 66 (story.tauschinsel.4.1, der Eisstand bei Sonne) | Szene 4:3 | da |
| 105 | `game.stand.hafenladen` | Markt-Einkauf | Stand: Hafenladen | – | freigestellt, quadratisch | da |
| 106 | `game.stand.fischbroetchen` | Markt-Einkauf | Stand: Fischbrötchen-Stand | – | freigestellt, quadratisch | da |
| 107 | `game.stand.obststand` | Markt-Einkauf | Stand: Obststand | – | freigestellt, quadratisch | da |
| 108 | `item.broetchen` | Markt-Einkauf | Ding: Brötchen | – | freigestellt, quadratisch | da |
| 109 | `item.aepfel` | Markt-Einkauf und Tauschkette | Ding: Äpfel | – | freigestellt, quadratisch | da |
| 110 | `item.saft` | Markt-Einkauf | Ding: Flasche Saft | – | freigestellt, quadratisch | da |
| 111 | `item.bonbons` | Markt-Einkauf | Ding: Bonbons | – | freigestellt, quadratisch | da |
| 112 | `item.fischbroetchen` | Markt-Einkauf | Ding: Fischbrötchen | – | freigestellt, quadratisch | da |
| 113 | `item.eimer` | Tauschkette | Ding: Eimer | – | freigestellt, quadratisch | da |
| 114 | `item.fisch` | Tauschkette | Ding: Fisch | – | freigestellt, quadratisch | da |
| 115 | `item.seil` | Tauschkette | Ding: Seil | – | freigestellt, quadratisch | da |
| 116 | `item.muschel` | Tauschkette | Ding: Muschel | – | freigestellt, quadratisch | da |

## 4k. Bildergeschichten der Wunschinsel

Wie bei Hafen und Tauschinsel: Querformat 4:3, ganze Szene mit Hintergrund, nicht freigestellt. Die ganzen Texte für Gemini stehen in `design/prompts_wunschinsel.txt`. Seit den Erfahrungen auf der Tauschinsel steht in jedem Text mit Tala ihre Kleidung, und Nebenfiguren sollen keinen bekannten Filmfiguren ähneln. Keine Zahlen und keine Währungszeichen im Bild; wo Beträge vorkommen, zeigen die Bilder nur Münzhäufchen.

| Nr. | Datei | Station | Bild | Vorlagen | SZENE | Stand |
| --- | --- | --- | --- | --- | --- | --- |
| 78 | `story.wunschinsel.1.1` | 1 Bedürfnis oder Wunsch | Was man zum Leben braucht | character.talo | Vor einer gemütlichen kleinen Hütte auf der Wunschinsel steht Talo, der Fuchs-Kapitän, neben einem Holztisch. Darauf liegen ein Laib Brot, eine Karaffe mit Wasser und eine warme, gefaltete Jacke. Aus dem Fenster der Hütte fällt warmes Licht. Talo zeigt freundlich auf die Dinge. | da |
| 79 | `story.wunschinsel.1.2` | 1 Bedürfnis oder Wunsch | Wünsche machen Spaß | character.tala, character.elsa | Im Glitzerladen der Wunschinsel: Überall glänzen Regale voller funkelnder Spielsachen. Tala drückt staunend die Nase an eine Glasvitrine, in der ein glitzernder goldener Kompass liegt. Hinter der Theke steht Elsa, die Elster, und lächelt. | da |
| 80 | `story.wunschinsel.1.3` | 1 Bedürfnis oder Wunsch | Das Handy liegt dazwischen | character.talo, character.tala | Talo hält ein einfaches Handy ohne Logo mit leerem hellblauem Bildschirm in der Pfote und überlegt. Über ihm schweben zwei Gedankenblasen: in der linken telefoniert Tala fröhlich mit ihm, in der rechten sind bunte Spielsteine zu sehen. | da |
| 81 | `story.wunschinsel.1.4` | 1 Bedürfnis oder Wunsch | Bedürfnisse zuerst | character.tala | Tala trägt fröhlich einen Einkaufskorb. Unten im Korb liegen Brot, eine Wasserflasche und Äpfel, ganz obenauf ein kleiner glitzernder Stern-Anhänger. Im Hintergrund die glitzernden Schaufenster der Wunschinsel. | da |
| 82 | `story.wunschinsel.2.1` | 2 Prioritäten setzen | Nicht genug für alles | character.tala | Im Packhaus, einem gemütlichen Holzschuppen: Tala steht ratlos vor einem langen Tisch voller Wandersachen (Wasserflasche, Proviantdose, Regenjacke, Taschenlampe, glitzernde Sonnenbrille, Spielzeug-Fernglas, Kuschelkissen). Daneben liegen ein kleiner leerer Rucksack und ein fast leerer Münzbeutel. | da |
| 83 | `story.wunschinsel.2.2` | 2 Prioritäten setzen | Das Wichtigste zuerst | character.talo, character.tala | Im Packhaus: Talo hilft Tala, zuerst eine Wasserflasche und eine Proviantdose in den kleinen Rucksack zu stecken. Die glitzernde Sonnenbrille liegt noch auf dem Tisch. | da |
| 84 | `story.wunschinsel.2.3` | 2 Prioritäten setzen | Wer wählt, verzichtet | character.tala | Tala hat den vollen Rucksack auf dem Rücken und geht zur Tür des Packhauses hinaus. Sie dreht sich um und winkt ein bisschen wehmütig der glitzernden Sonnenbrille zu, die auf dem Tisch liegen bleibt. | da |
| 85 | `story.wunschinsel.3.1` | 3 Die Warte-Regel | Eine Nacht drüber schlafen | character.tala | Abend am Strand der Wunschinsel: Tala liegt in einer Hängematte zwischen zwei Palmen und schläft friedlich. Über ihr steht der Mond, im Sand neben der Hängematte liegt ein kleines Bild des glitzernden Kompasses. Ruhige, blaue Abendstimmung mit goldenem Rest-Licht. | da |
| 86 | `story.wunschinsel.3.2` | 3 Die Warte-Regel | Viele Wünsche verschwinden | character.talo | Am Wunschflaschen-Strand stecken bunte Glasflaschen mit Korken im Sand. Aus einigen steigen kleine Spielsachen wie Seifenblasen auf und verpuffen in der Luft. Eine einzige Flasche leuchtet weiter golden. Talo steht daneben und lächelt wissend. | da |
| 87 | `story.wunschinsel.3.3` | 3 Die Warte-Regel | Die Wunschflasche | character.tala | Am Wunschflaschen-Strand im Abendlicht: Tala steckt einen zusammengerollten Zettel, auf dem nur ein kleiner gemalter Kompass zu sehen ist, in eine Glasflasche mit Korken. Ringsum liegen weitere Flaschen im Sand. | da |
| 88 | `story.wunschinsel.4.1` | 4 Alle haben das | Alle tragen rote Mützen | character.tala | Auf dem Möwenplatz der Wunschinsel: Viele Möwen tragen alle die gleiche rote Mütze und schauen auf Tala, die als Einzige keine Mütze hat. Tala schaut unsicher an sich herunter. | da |
| 89 | `story.wunschinsel.4.2` | 4 Alle haben das | Nur um dazuzugehören | character.tala | Auf dem Möwenplatz: Tala hat zögernd eine rote Mütze aufgesetzt, die ihr viel zu groß ist und über die Augen rutscht. Sie sieht nicht glücklich aus. Die Möwen ringsum nicken zufrieden. | da |
| 90 | `story.wunschinsel.4.3` | 4 Alle haben das | Würde ich das auch allein wollen? | character.tala | Tala sitzt allein auf einer Bank am Rand des Möwenplatzes, hält die rote Mütze in den Händen und denkt nach. Über ihr eine Gedankenblase: Tala steht allein auf einer leeren kleinen Insel mit der roten Mütze und langweilt sich. | da |
| 91 | `story.wunschinsel.4.4` | 4 Alle haben das | Freundlich Nein sagen | character.tala, character.talo | Auf dem Möwenplatz gibt Tala lächelnd die rote Mütze an eine Möwe zurück und hebt freundlich eine Hand wie zu einem „Nein, danke“. Talo steht neben ihr und schaut stolz. | da (abgeschnittene Schrift auf einem Schild von Claude entfernt) |
| 92 | `story.wunschinsel.5.1` | 5 Macht Geld glücklich? | Geld nimmt Sorgen | character.talo | Talo zeigt auf ein gemütliches Inselhaus mit warmem Licht in den Fenstern. Davor sitzt eine Kaninchenfamilie an einem gedeckten Tisch mit Brot, Obst und Suppe und isst zufrieden. | da |
| 93 | `story.wunschinsel.5.2` | 5 Macht Geld glücklich? | Die Freude hält nicht lange | character.tala | In Talas kleiner Schiffskajüte: Tala sitzt gelangweilt auf ihrer Koje. Der glitzernde Kompass liegt achtlos in der Ecke, schon ein bisschen verstaubt. Tala schaut aus dem runden Fenster aufs Meer. | da |
| 94 | `story.wunschinsel.5.3` | 5 Macht Geld glücklich? | Was man nicht kaufen kann | character.moritz, character.tala | Vor Moritz' gemütlicher Höhle in der Abendsonne: Moritz, das Murmeltier, und Tala sitzen auf einer Decke, lachen zusammen und teilen eine Schale Beeren. Moritz zeigt stolz seine bunte Murmelsammlung in einem kleinen Holzkästchen. | da |
| 95 | `story.wunschinsel.6.1` | 6 Erlebnisse statt Dinge | Spielzeug in der Ecke | – | Eine Ecke in einer gemütlichen Schiffskajüte: ein kleiner Haufen Spielzeug (Kreisel, Ball, Holzschiff, Teddy) liegt verstaubt in der Ecke, ein paar Spinnweben daran. Warmes Licht fällt durch ein rundes Fenster. Keine Figuren. | da |
| 96 | `story.wunschinsel.6.2` | 6 Erlebnisse statt Dinge | Unsere erste Fahrt | character.tala, character.talo | Tala und Talo stehen vorne am Bug ihres Holzsegelschiffs, der Wind weht, sie lachen und breiten die Arme aus. Neben dem Schiff springen zwei Delfine aus dem glitzernden Meer. | da (zweite Fassung; in der ersten hatte Tala einen Fuchsschwanz) |
| 97 | `story.wunschinsel.6.3` | 6 Erlebnisse statt Dinge | Erlebnisse teilen | character.tala, character.moritz | Am Strand der Wunschinsel: Tala und Moritz, das Murmeltier, bauen gemeinsam eine große Sandburg mit Muscheln und lachen. Neben ihnen liegen nur ein Eimer und eine Schaufel. | da |
| 98 | `story.wunschinsel.7.1` | 7 Meine Wunschliste | Wünsche aufschreiben | character.tala, character.talo | Am großen steinernen Wunschbrunnen: Tala sitzt auf dem Brunnenrand und malt auf ein Blatt Papier. Auf dem Blatt sind nur kleine gemalte Bilder: ein Kompass, ein Fernglas, ein Ball, und neben jedem Bild ein kleines Häufchen Münzen, unterschiedlich groß. Talo schaut ihr über die Schulter. | da |
| 99 | `story.wunschinsel.7.2` | 7 Meine Wunschliste | Das Wichtigste nach oben | character.tala | Am Wunschbrunnen: Tala legt drei Bildkärtchen untereinander auf den Brunnenrand. Auf dem obersten ist ein Kompass gemalt und es leuchtet golden, darunter ein Fernglas und ein Ball. | da |
| 100 | `story.wunschinsel.7.3` | 7 Meine Wunschliste | Ein Wunschschatz | character.talo, character.tala | Tala legt eine goldene Münze ohne Zeichen in eine kleine Schatztruhe aus Holz. Auf dem Deckel der Truhe ist ein Kompass gemalt. Talo hält die Truhe und lächelt. | da |
| 101 | `story.wunschinsel.7.4` | 7 Meine Wunschliste | Das Kartenstück steigt auf | character.elsa, character.tala | Am Wunschbrunnen im goldenen Abendlicht: Aus dem Brunnen steigt ein leuchtendes, altes Stück einer Schatzkarte auf, nur mit gemalten Wellen und einer Insel. Elsa, die Elster, flattert begeistert darüber, Tala staunt mit großen Augen. | da |

## 4j. Bildergeschichten der Tauschinsel

Wie beim Hafen (Abschnitt 4h): Querformat 4:3, ganze Szene mit Hintergrund, nicht freigestellt. Gleicher Text für Gemini, „SZENE“ durch den Text aus der Tabelle ersetzen. Die Figuren aus der Spalte „Vorlagen“ anhängen, höchstens zwei, sonst lehnt Gemini öfter ab („Interessen von Drittanbietern“). Station 5 rechnet mit Zahlen; diese zwei Bilder zeichnet die App.

| Nr. | Datei | Station | Bild | Vorlagen | SZENE | Stand |
| --- | --- | --- | --- | --- | --- | --- |
| 56 | `story.tauschinsel.1.1` | 1 Hier gibt es kein Geld | Äpfel nur gegen Fisch | character.bruno, character.tala | Auf dem Tauschmarkt der Tauschinsel: Bruno, der große Braunbär mit Strohhut, steht hinter einem Stand voller roter Äpfel. Er hält einen Apfel hoch, über ihm schwebt eine Gedankenblase mit einem Fisch. Tala (Schwein) steht davor und schaut ihn erwartungsvoll an. | da |
| 57 | `story.tauschinsel.1.2` | 1 Hier gibt es kein Geld | Fisch gegen Eimer | character.otti | Am Steg der Tauschinsel: Otti, der Otter mit gelber Regenjacke, hält stolz einen glänzenden Fisch hoch. Über ihm schwebt eine Gedankenblase mit einem einfachen Holzeimer. | da |
| 58 | `story.tauschinsel.1.3` | 1 Hier gibt es kein Geld | Ein Eimer an Bord | character.tala, character.talo | Am Steg der Tauschinsel liegt das Schiff der Crew. Tala hebt fröhlich einen Holzeimer über die Reling, Talo (Fuchs, Kapitän) hilft ihr dabei und lacht. | da |
| 59 | `story.tauschinsel.1.4` | 1 Hier gibt es kein Geld | Die Tauschkette | – | Vier Dinge nebeneinander auf einem Holzsteg, verbunden mit geschwungenen goldenen Pfeilen von links nach rechts: ein Holzeimer, ein glänzender Fisch, drei rote Äpfel, ein aufgerolltes Seil. Warmes Licht, Meer im Hintergrund. | da |
| 60 | `story.tauschinsel.2.1` | 2 Das große Tauschspiel | Was brauche ich wirklich? | character.tala, character.talo | Auf dem bunten Tauschmarkt: Tala hält eine Muschelkette, einen Korb und ein Stück Käse im Arm und überlegt. Talo zeigt auf eine schöne alte Laterne an einem Marktstand. | da (zweite Fassung mit Kleidung) |
| 61 | `story.tauschinsel.2.2` | 2 Das große Tauschspiel | Kein guter Tausch | character.tala | Ein Dachs als Händler bietet Tala drei kleine, schrumpelige Äpfel für ihre schöne, glänzende Muschelkette an. Tala verschränkt die Arme und schüttelt freundlich, aber bestimmt den Kopf. | da |
| 62 | `story.tauschinsel.2.3` | 2 Das große Tauschspiel | Beide zufrieden | character.tala | Am Marktstand: Tala gibt einer Ente einen geflochtenen Korb und bekommt dafür eine leuchtende Laterne. Beide lächeln zufrieden. | da |
| 63 | `story.tauschinsel.3.1` | 3 Wert ist nicht für jeden gleich | Wasser oben am Berg | character.tala | Oben auf dem Berg der Tauschinsel in der Mittagshitze: Tala sitzt erschöpft auf einem Stein und hält eine glitzernde Wasserflasche wie einen Schatz. Weit unten sieht man klein den Strand und eine Quelle. | da |
| 64 | `story.tauschinsel.3.2` | 3 Wert ist nicht für jeden gleich | Tala liebt Fischbrötchen | character.tala, character.talo | Tala strahlt und hält ein Fischbrötchen in den Händen, über ihr kleine Herzchen. Talo daneben verzieht lustig das Gesicht und schiebt es mit einer Pfote freundlich weg. | da (zweite Fassung mit Kleidung, Geldscheine in der Kiste von Claude entfernt) |
| 65 | `story.tauschinsel.3.3` | 3 Wert ist nicht für jeden gleich | Ein guter Tausch für beide | character.tala, character.talo | Tala und Talo tauschen lachend: Tala gibt Talo eine Flasche Wasser, Talo gibt Tala ein Fischbrötchen. Beide sind glücklich. | da |
| 66 | `story.tauschinsel.4.1` | 4 Wenn alle Eis wollen | Ein heißer Tag | character.tala | Ein Eisstand am Strand der Tauschinsel an einem heißen Sonnentag. Davor steht eine lange Schlange fröhlicher Tiere. Tala steht hinter der Theke und füllt Eiskugeln in Waffeln. Keine Schilder. | da |
| 67 | `story.tauschinsel.4.2` | 4 Wenn alle Eis wollen | Das Eis wird knapp | character.tala | Am Eisstand ist nur noch eine einzige Eiskugel übrig. Mehrere Tiere strecken gleichzeitig die Pfoten danach aus, eines hält einen prall gefüllten Münzbeutel hoch. Tala hinter der Theke staunt. Keine Schilder. | da |
| 68 | `story.tauschinsel.4.3` | 4 Wenn alle Eis wollen | Ein Regentag | character.tala | Regentag am Eisstand: Niemand ist da, nur eine Möwe sitzt unter dem Sonnenschirm. Die Eistruhe ist voll. Tala stützt den Kopf in die Hände und schaut in den Regen. Keine Schilder. | da |
| 69 | `story.tauschinsel.4.4` | 4 Wenn alle Eis wollen | Angebot und Nachfrage | character.talo | Talo steht neben einer großen, alten Holzwaage am Strand. Auf der einen Schale liegt ein Berg Eiskugeln, auf der anderen steht eine Gruppe winziger Tiere mit leeren Waffeln in den Pfoten. Die Waage ist im Gleichgewicht. | da |
| – | – | 5 Preis und Qualität | 12 Netze im Jahr | – | entfällt: zeichnet die App selbst (`drawing:nets_year`) | – |
| – | – | 5 Preis und Qualität | 60 Taler gegen 20 Taler | – | entfällt: zeichnet die App selbst (`drawing:nets_cost`) | – |
| 70 | `story.tauschinsel.5.3` | 5 Preis und Qualität | Billig ist nicht immer günstig | character.otti | Otti in seinem kleinen Fischerboot hält stolz ein dickes, starkes Fischernetz voller Fische hoch. Daneben treibt im Wasser ein dünnes, zerrissenes Netz. | da |
| 71 | `story.tauschinsel.6.1` | 6 Was ist mir etwas wert? | Nur einmal ausgeben | character.tala | Tala steht zwischen Eisstand und Aussichtsturm und hält eine einzelne Münze in der Pfote. Über ihr zwei Gedankenblasen: in der einen ein Eis, in der anderen ein Messing-Fernrohr. | da |
| 72 | `story.tauschinsel.6.2` | 6 Was ist mir etwas wert? | Sparen für das Fernrohr | character.tala | Tala oben auf einem hölzernen Aussichtsturm schaut glücklich durch ein Messing-Fernrohr über das weite Meer. Neben ihr steht ein kleines Sparschwein. | da (Dollarzeichen auf dem Sparschwein von Claude entfernt) |
| 73 | `story.tauschinsel.6.3` | 6 Was ist mir etwas wert? | Wissen, worauf man verzichtet | character.talo, character.tala | Eine Weggabelung auf der Tauschinsel mit zwei Holzwegweisern ohne Schrift: Ein Weg führt zum Eisstand am Strand, der andere hinauf zum Aussichtsturm. Talo und Tala stehen an der Gabelung und überlegen. | da |
| 74 | `story.tauschinsel.7.1` | 7 Fair tauschen unter Freunden | Ein unfairer Tausch | – | Auf einem Schulhof: Ein größerer Hase hält einem kleinen Igel eine ganz gewöhnliche Sammelkarte hin und zeigt gierig auf die glänzende, seltene Karte des Igels. Der Igel schaut unsicher. Keine Schrift und keine Bilder auf den Karten, nur Farben. | da |
| 75 | `story.tauschinsel.7.2` | 7 Fair tauschen unter Freunden | Das ist unfair! | character.tala | Tala stellt sich mit verschränkten Armen freundlich, aber bestimmt neben den kleinen Igel, der seine glänzende Sammelkarte fest an sich drückt. Der große Hase schaut ertappt. | da |
| 76 | `story.tauschinsel.7.3` | 7 Fair tauschen unter Freunden | So geht fair | character.talo | Ein Hase und ein Igel tauschen lächelnd zwei gleich glänzende Sammelkarten und nicken sich zu. Talo steht daneben und hebt den Daumen. Keine Schrift auf den Karten. | da |
| 77 | `story.tauschinsel.7.4` | 7 Fair tauschen unter Freunden | Olga gibt das Kartenstück | character.olga, character.tala | Am Strandlager mit Lagerfeuer im Abendlicht: Olga, die alte Schildkröte mit Brille und Wollschal, überreicht Tala feierlich ein altes, zerrissenes Stück einer Schatzkarte. Auf der Karte nur gemalte Wellen und eine Insel, keine Schrift. | da |

Stand 11.10.2026 abends: alle 22 sind da. Nr. 60 und 64 hat Marc noch einmal gemacht, weil Tala in der ersten Fassung ihre Kleidung nicht trug (Tipp dazu unten). Nr. 66 und 67 (Eisstand): Fuchs und Hase in der Schlange ähneln Figuren aus einem bekannten Kinofilm; vor dem Live-Start noch einmal ansehen.

## 4i. Begegnungen und Stopps auf See (vor der Tauschinsel)

Besprochen mit Marc am 11.10.2026: Auf der Karte sieht man bisher nur runde Köpfe für die Stopps, und Meister Taleron sitzt wie eine Statue im Meer. Besser: Taleron taucht halb aus dem Wasser auf (so ist er auch beschrieben: Er zeigt sich nur halb), und die Stopps zeigen ihr Schiff mit der Figur an Bord. Alle Bilder freigestellt auf Pink, die App setzt sie aufs Meer.

| Nr. | Datei | Bild | Vorlagen | Stand |
| --- | --- | --- | --- | --- |
| 52 | `encounter.taleron` | Meister Taleron taucht auf | character.taleron | da |
| 53 | `ship.haendler` | Das Händlerschiff (Stopp vor der Tauschinsel) | ship.crew, character.haendler | da (ohne Walross, Gemini lehnte es mit Figur ab; die App zeigt den Kopf als Rundbild daneben) |
| 54 | `ship.fischer` | Das Fischerboot (Stopp vor der Tauschinsel) | ship.crew, character.otti | da |
| 55 | `ship.greta` | Gretas Händlerboot (Stopp vor der Wunschinsel) | ship.crew, character.greta | da |

### Bild 52: Meister Taleron taucht auf → `encounter.taleron`

```
Gleiche Figur wie im angehängten Bild, gleicher Stil, gleiche Farben: Meister Taleron, das freundliche Seeungeheuer. Er taucht gerade aus dem Meer auf: Man sieht nur Kopf, Bart aus Seetang und Oberkörper bis zur Brust, dazu zwei Bögen seines langen Schwanzes, die hinter ihm aus dem Wasser ragen. Direkt um ihn herum ein kleiner Ring aus weißer Gischt und ein paar Wassertropfen. Er lächelt freundlich und hebt grüßend eine Pfote. Sanft und gar nicht gruselig. Quadratisches Bild, die Figur vollständig in der Mitte.

Keine Schrift, keine Buchstaben, keine Zahlen, keine Logos, keine Waffen.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten. Kein Meer bis zum Bildrand, nur der kleine Gischtring direkt um ihn.
```

### Bild 53: Das Händlerschiff → `ship.haendler`

```
Gleicher Stil, gleicher Blickwinkel und gleiches Licht wie im ersten angehängten Bild (das Schiff der Crew), aber ein anderes Schiff: ein breites, bauchiges Handelsschiff aus dunklem Holz mit einem Mast und einem großen ockergelben Segel. An Deck viele Fässer, Kisten und Säcke mit Waren. Vorn an der Reling steht der Händler aus dem zweiten Bild (das Walross mit grüner Weste) und winkt. Er ist gut zu erkennen, etwa ein Drittel so hoch wie das Schiff. Das Schiff fährt nach links. Kein Wasser, keine Bugwelle. Das Schiff füllt etwa drei Viertel der Bildbreite. Quadratisches Bild.

Keine Schrift, keine Buchstaben, keine Zahlen, keine Logos, keine Waffen, keine Kanonen.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Wasser, ohne Boden.
```

Gemini lehnte das am 11.10.2026 ab („Interessen von Drittanbietern“). Zweiter Versuch in einem neuen Chat, nur mit dem Händler als Vorlage:

```
Gleiche Figur und gleicher Stil wie im angehängten Bild: Der Händler, ein gemütliches Walross mit grüner Weste und runder Brille, steht vorn an der Reling seines eigenen Handelsschiffs und winkt fröhlich. Das Schiff ist breit und bauchig, aus dunklem Holz, mit einem Mast und einem großen ockergelben Segel. An Deck stehen Fässer, Kisten und Säcke mit Waren. Blick leicht schräg von oben, das Schiff fährt nach links. Das Walross ist gut zu erkennen, etwa ein Drittel so hoch wie das Schiff. Kein Wasser, keine Bugwelle. Das Schiff füllt etwa drei Viertel der Bildbreite. Quadratisches Bild.

Keine Schrift, keine Buchstaben, keine Zahlen, keine Logos, keine Waffen, keine Kanonen.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Wasser, ohne Boden.
```

Klappt auch das nicht: das Schiff ohne Figur (nur das Crew-Schiff als Vorlage, Satz mit dem Walross weglassen). Die App setzt dann den Kopf des Händlers als kleines Rundbild an das Schiff.

### Bild 54: Das Fischerboot → `ship.fischer`

```
Gleicher Stil, gleicher Blickwinkel und gleiches Licht wie im ersten angehängten Bild (das Schiff der Crew), aber ein anderes Boot: ein kleines, rundliches Fischerboot aus hellblau gestrichenem Holz mit einem kleinen Mast und einem geflickten weißen Segel. An Bord Fischernetze, eine Kiste mit glänzenden Fischen und eine kleine Waage. Im Boot steht Otti aus dem zweiten Bild (der Otter mit gelber Regenjacke) und winkt. Er ist gut zu erkennen, etwa halb so hoch wie das Boot. Das Boot fährt nach rechts. Kein Wasser, keine Bugwelle. Das Boot füllt etwa drei Viertel der Bildbreite. Quadratisches Bild.

Keine Schrift, keine Buchstaben, keine Zahlen, keine Logos, keine Waffen.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Wasser, ohne Boden.
```

### Bild 55: Gretas Händlerboot → `ship.greta`

```
Gleicher Stil, gleicher Blickwinkel und gleiches Licht wie im ersten angehängten Bild (das Schiff der Crew), aber ein anderes Boot: ein schmales Segelboot aus rötlichem Holz mit einem dreieckigen roten Segel. An Bord liegen viele aufgerollte Seile in verschiedenen Farben. Im Boot steht Greta aus dem zweiten Bild (die weiße Ziege mit rotem Kopftuch) und winkt. Sie ist gut zu erkennen, etwa halb so hoch wie das Boot. Das Boot fährt nach links. Kein Wasser, keine Bugwelle. Das Boot füllt etwa drei Viertel der Bildbreite. Quadratisches Bild.

Keine Schrift, keine Buchstaben, keine Zahlen, keine Logos, keine Waffen.

Hintergrund: komplett einfarbig reines Pink-Magenta (#FF00FF), ohne Verlauf, ohne Schatten, ohne Wasser, ohne Boden.
```

## 4h. Bildergeschichten in den Stationen (Hafen zuerst)

Entschieden mit Marc am 10.10.2026: Statt eines Films erklärt jede Station ihr Thema als **Bildergeschichte**. Das Kind blättert durch 3 bis 5 Bilder, zu jedem sagen Talo, Tala oder eine Inselfigur ein bis zwei Sätze (die Texte stehen schon in den Inhaltsdateien unter `"erklaerung"`). Filme gibt es nur noch für das Intro und die Ankunft auf den Inseln.

- Querformat 4:3, ganze Szene mit Hintergrund. Die Bilder werden **nicht** freigestellt, ein pinker Hintergrund ist also nicht nötig.
- Bis ein Bild da ist, zeigt die App einen blauen Platzhalter mit dem Namen des Bildes, zum Beispiel „Bild: Tauschen klappt selten“.
- Münzen, Scheine und Beträge mit Zahlen zeichnet die App selbst (`"bild": "drawing:…"` in der Inhaltsdatei). Gemini malt dort falsche Zahlen. Darum entfallen die Bilder 37 bis 39.
- Bitte immer die Figuren als Vorlage anhängen, die im Bild vorkommen (Spalte „Vorlagen“, die Dateien liegen in `design/gemini/`), dazu `island.hafen.background.jpg` für den Hafen-Look.
- Am besten 3 bis 5 Bilder pro Nachricht schicken, mit Nummer, zum Beispiel „Bild 29, Bild 30, Bild 31“.
- Gibt Gemini Tala einen Fuchsschwanz (passiert, wenn Talo dicht neben ihr steht): den Satz „Tala ist ein Schwein und hat einen kleinen geringelten Schweineschwanz, keinen Fuchsschwanz. Nur Talo hat einen buschigen Fuchsschwanz.“ einfügen.
- Lässt Gemini bei Tala die Kleidung weg: den Satz „Tala trägt ihre Kleidung wie auf dem Vorlagenbild: rote Schleife, gelbes Halstuch, blau-weiß gestreiftes Shirt, grüne Weste, blauer Rock.“ einfügen.
- Meldet Gemini „Interessen von Drittanbietern“: einen neuen Chat öffnen, weniger Vorlagen anhängen (eine Figur reicht oft) und die Szene etwas anders beschreiben.
- Malt Gemini trotzdem ein Logo, eine Bankkarten-Schrift oder fremdes Geld (zum Beispiel Dollar), bessert Claude die Stelle aus. In `design/gemini/` liegt dann schon die ausgebesserte Fassung.

So geht der Text für Gemini. „SZENE“ durch den Text aus der Tabelle ersetzen:

```
Hochwertiger 3D-Animationsfilm-Look wie in den angehängten Bildern: gleiche Figuren, gleiche Farben, gleiches warmes Licht. SZENE Querformat 4:3. Freundlich und kindgerecht, eine klare Bildaussage, nicht zu viele Kleinigkeiten. Keine Schrift, keine Buchstaben, keine Zahlen, keine Logos, keine Waffen. Ganze Szene mit Hintergrund.
```

| Nr. | Datei | Station | Bild | Vorlagen | SZENE | Stand |
| --- | --- | --- | --- | --- | --- | --- |
| 29 | `story.hafen.2.1` | 2 Was ist Geld? | Tauschen klappt selten | character.haendler, character.verkaeuferin | Auf dem Hafenmarkt: Der Händler (Walross) hält einen Sack Mehl und schaut ratlos zur Fischverkäuferin (Seehündin). Sie hält einen Fisch und schüttelt den Kopf, weil sie gerade kein Mehl braucht. Über beiden je eine kleine Gedankenblase: beim Walross ein Fisch, bei der Seehündin ein Paar Stiefel. | da |
| 30 | `story.hafen.2.2` | 2 Was ist Geld? | Geld nimmt jeder | character.talo, character.haendler | Talo (Fuchs, Kapitän) reicht dem Händler (Walross) ein paar glänzende Goldmünzen. Der Händler lächelt zufrieden und gibt ihm dafür einen Sack Mehl. Im Hintergrund der Hafenmarkt. | da |
| 31 | `story.hafen.2.3` | 2 Was ist Geld? | Geld kann man aufheben | character.tala | Auf einem Holztisch nebeneinander: links ein altes, grünlich verdorbenes Fischbrötchen, über dem zwei Fliegen kreisen (lustig, nicht eklig), rechts eine glänzende, saubere Goldmünze. Tala (Schwein) zeigt fröhlich auf die Münze. | da |
| 32 | `story.hafen.2.4` | 2 Was ist Geld? | Alles hat einen Preis | character.talo | Ein Marktstand am Hafen mit Brot, Fisch, Äpfeln und einem Seil. Vor jeder Ware liegt ein Häufchen Goldmünzen, verschieden groß: wenige vor den Äpfeln, viele vor dem Seil. Talo zeigt erklärend darauf. | da |
| 33 | `story.hafen.3.1` | 3 Geld früher und heute | Muscheln und Salz | – | Eine Szene aus alter Zeit an einem Strand: Tiere in einfacher, altertümlicher Kleidung tauschen. Einer bezahlt mit hübschen weißen Muscheln, ein anderer mit einem kleinen Säckchen Salz. Warmes Abendlicht. | da |
| 34 | `story.hafen.3.2` | 3 Geld früher und heute | Münzen aus Metall | character.bootsbauer | Eine alte Werkstatt: ein Biber (wie der Bootsbauer) prägt mit einem Hammer runde Metallmünzen. Daneben liegt ein Stapel glänzender Münzen in einer Waagschale. | da |
| 35 | `story.hafen.3.3` | 3 Geld früher und heute | Scheine aus Papier | character.talo, character.tala | Tala schleppt lachend einen riesigen, schweren Sack voller Münzen und kommt ins Schwitzen. Daneben hält Talo ganz leicht ein kleines Bündel Geldscheine aus Papier in der Pfote. Ein lustiger Vergleich: schwer gegen leicht. | da (die Scheine sahen aus wie Dollar, von Claude blau gefärbt wie ein 20-Euro-Schein) |
| 36 | `story.hafen.3.4` | 3 Geld früher und heute | Karte und Handy | character.talo, character.tala, character.verkaeuferin | Am Fischbrötchen-Stand im Hafen: Talo hält eine Bankkarte an ein kleines Bezahlgerät, Tala hält ein Handy daneben. Die Verkäuferin (Seehündin) reicht zwei Fischbrötchen. Auf dem Gerät leuchtet nur ein grünes Häkchen. | da (Logo und Schrift auf der Karte von Claude entfernt) |
| 37 | – | 4 Münzen und Scheine | Die Euro-Münzen | – | entfällt: zeichnet die App selbst (genaue Zahlen) | – |
| 38 | – | 4 Münzen und Scheine | Die Euro-Scheine | – | entfällt: zeichnet die App selbst (genaue Zahlen) | – |
| 39 | – | 4 Münzen und Scheine | Große Münzen zuerst | – | entfällt: zeichnet die App selbst (genaue Zahlen) | – |
| 40 | `story.hafen.4.4` | 4 Münzen und Scheine | Geld auf dem Konto | character.talo, character.tala | Talo zeigt Tala auf einem Tablet ein einfaches Bild von einem Sparschwein mit einem leuchtenden Häkchen. Um das Tablet schweben ein paar durchsichtig leuchtende Münzen, als Zeichen, dass das Geld digital da ist. | da |
| 41 | `story.hafen.5.1` | 5 Woher kommt Geld? | Lohn für Arbeit | character.bootsbauer, character.talo | Am Steg im Hafen liegt ein frisch repariertes kleines Segelboot. Der Biber mit Lederschürze steht stolz daneben, den Hammer noch in der Hand. Der Fuchs-Kapitän bedankt sich und reicht ihm einen kleinen, zugebundenen Lederbeutel. Beide lächeln. Abendsonne. | da (zweiter Versuch: Talo statt Walross, der erste wurde von Gemini abgelehnt) |
| 42 | `story.hafen.5.2` | 5 Woher kommt Geld? | Viele Berufe | character.bootsbauer | Drei kleine Szenen nebeneinander wie drei Bilder an einer Wand: ein Biber baut an einem Schiff, ein Bär als Bäcker holt Brot aus dem Ofen, eine Katze als Ärztin mit Stethoskop hilft einem kleinen Hasen. | da |
| 43 | `story.hafen.5.3` | 5 Woher kommt Geld? | Kein Falschgeld | character.talo | Ein tollpatschiger Waschbär kurbelt heimlich an einer kleinen, bunten Spielzeug-Druckmaschine. Heraus kommen leere grüne Papierzettel ganz ohne Aufdruck. Talo steht davor, schüttelt freundlich den Kopf und hebt die Pfote wie ein Stoppschild. Lustig, nicht bedrohlich. | da |
| 44 | `story.hafen.6.1` | 6 Warum kostet etwas etwas? | Die Zutaten | character.verkaeuferin | Der Fischbrötchen-Stand im Hafen, leicht von oben: Auf der Theke liegen die Zutaten eines Fischbrötchens nebeneinander: ein Brötchen, ein Stück Fisch, Zwiebelringe, Salat. Die Verkäuferin (Seehündin) zeigt darauf. | da |
| 45 | `story.hafen.6.2` | 6 Warum kostet etwas etwas? | Miete und Lohn | character.verkaeuferin | Am Fischbrötchen-Stand: Ein kleines Säckchen Münzen geht an die Verkäuferin (Seehündin) als Lohn, ein zweites an eine Möwe mit Hafenmeister-Mütze, der der Platz gehört, als Miete. | da |
| 46 | `story.hafen.6.3` | 6 Warum kostet etwas etwas? | Der Gewinn | character.verkaeuferin | Am Abend legt die Verkäuferin (Seehündin) die übrig gebliebenen Münzen in eine Spardose. Daneben steht ein glänzender neuer Grill mit einer roten Schleife, ohne Preisschild, den sie sich davon kaufen will. | da |
| 47 | `story.hafen.6.4` | 6 Warum kostet etwas etwas? | Zu teuer | – | Zwei Fischbrötchen-Stände nebeneinander im Hafen: Vor dem einen steht eine lange, fröhliche Schlange von Tieren. Vor dem anderen, auf dessen Theke ein riesiger Münzberg als Preis liegt, steht niemand, nur eine Möwe schaut verwundert. Keine Schilder an den Ständen. | da |
| 48 | `story.hafen.7.1` | 7 Wie viel ist viel? | Preise kennen | character.talo, character.tala | Tala steht vor einem Marktstand und hält ein leeres Preisschild ohne Aufdruck in der Hand. Über ihrem Kopf eine Gedankenblase mit einer Waage. Talo schaut ihr über die Schulter. | da |
| 49 | `story.hafen.7.2` | 7 Wie viel ist viel? | Brötchen, Kino, Fahrrad | – | Drei Dinge nebeneinander auf einer langen Holzbank, vor jedem ein Münzhaufen: ein Brötchen mit nur einer Münze davor, eine Kinokarte ohne Aufdruck mit einem kleinen Münzstapel, ein Fahrrad mit einem großen Münzberg. | da |
| 50 | `story.hafen.7.3` | 7 Wie viel ist viel? | Auf Preisschilder schauen | character.tala | Tala mit einer großen Lupe im Laden am Hafen. Sie schaut ganz genau auf die Preisschilder an den Regalen. Auf den Schildern sind statt Zahlen nur kleine gemalte Münzen: auf einem eine Münze, auf einem anderen drei. | da |
| 51 | `story.hafen.7.4` | 7 Wie viel ist viel? | Preise vergleichen | character.talo, character.tala | Talo und Tala stehen auf der Hafenstraße zwischen zwei Läden. In beiden Schaufenstern liegt derselbe rote Ball. Vor dem einen Laden liegen wenige Münzen, vor dem anderen viele. Tala zeigt auf den günstigeren Laden. Keine Ladenschilder. | da |

Manche Sätze teilen sich ein Bild: Bei Station 5 zeigt Talas Merksatz noch das Bild „Kein Falschgeld“.

**Tauschinsel und Wunschinsel** haben ihre Bildplätze schon (`story.tauschinsel.…`, `story.wunschinsel.…`, im Asset-Manifest mit Namen). Die Texte für Gemini schreibt Claude, sobald die Hafen-Bilder fertig sind.

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
- Inseln von innen (`island.<slug>.background`): JPG, Hochformat 9:16, unverändert verkleinert (`--art hintergrund`). Dazu im Manifest `route`: Punkte des Wegs von unten (Steg) nach oben, jeweils [x, y] von 0 bis 1.
- Alle Bilder vor dem Einbau in `ASSETS_LICENSES.md` eintragen.

**Stand 10.10.2026:** Bild 1 bis 6 sind da und eingebaut (eine längliche Wolke). Für die Startseite sind Bild 7 bis 13 eingebaut, dazu die Entwürfe von Talo und Tala (Bild 14 und 15).
