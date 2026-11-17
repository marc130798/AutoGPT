"""Baut die Logbücher zum Ausdrucken (HTML) für die Inseln 2 bis 4.

Titelseite, Urkunde mit Schatzcode und Elternseite sind für jede Insel gleich
aufgebaut; die Aufgaben-Seiten stehen unten pro Insel. Das Logbuch des Hafens
(logbuch/logbuch_hafen.html) ist von Hand geschrieben und das Vorbild.

Aufruf im Ordner taleria/:  python3 tool/logbuch_bauen.py
Danach die PDFs mit Playwright erzeugen (siehe CLAUDE.md, „Logbuch“).
Die Codes müssen zu `logbookCodes` in lib/domain/shipyard.dart passen.
"""

from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "logbuch"
IMG = "../assets/images"


def head(title):
    return f"""<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>Taleria – Mein Logbuch: {title}</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@600;700;800&family=Caveat:wght@700&family=Nunito:wght@400;600;700;800&display=swap">
<link rel="stylesheet" href="../testphase/stil.css">
<link rel="stylesheet" href="logbuch.css">
</head>
<body>
"""


def foot(title, page):
    return f'  <div class="foot"><span>Taleria · Mein Logbuch · {title}</span><span>Seite {page}</span></div>\n'


def cover(nr, title, sub):
    return f"""
<section class="page cover">
  <div class="cover-top">
    <img class="logo" src="{IMG}/brand.logo.png" alt="Taleria">
    <p class="eyebrow">Mein Logbuch · Insel {nr}</p>
    <h1>{title}</h1>
    <p class="sub">{sub}</p>
  </div>
  <div class="crew-big">
    <img src="{IMG}/character.talo.wave.png" alt="">
    <img src="{IMG}/character.tala.wave.png" alt="">
  </div>
  <div class="box gold owner">
    <div><b>Dieses Logbuch gehört:</b><div class="writeline"></div></div>
    <div><b>Mein Schiff heißt:</b><div class="writeline"></div></div>
  </div>
  <div class="box howto">
    <h3>So funktioniert dein Logbuch</h3>
    <ol>
      <li>Spiel in der App eine Station auf der {title}.</li>
      <li>Dann machst du die passende Seite hier im Logbuch. Oben steht, zu welcher Station sie gehört.</li>
      <li>Auf der letzten Seite wartet deine <b>Urkunde</b> mit einem <b>Schatzcode</b> für die Werft.</li>
    </ol>
  </div>
{foot(title, 1)}</section>
"""


def task(n, heading, body):
    return f"""  <div class="task">
    <div class="tnum">{n}</div>
    <div>
      <h3>{heading}</h3>
{body}
    </div>
  </div>
"""


def talk(figure, question):
    return f"""  <div class="box talk">
    <img src="{IMG}/{figure}.png" alt="">
    <div><b>Frag deine Eltern:</b> {question}<div class="writeline"></div><div class="writeline"></div></div>
  </div>
"""


def page(tag, heading, title, nr, body):
    return f"""
<section class="page">
  <div class="head"><span class="tag">{tag}</span><h2>{heading}</h2></div>
{body}{foot(title, nr)}</section>
"""


def certificate(title, badge_title, badge_img, learned, code, reward, nr):
    return f"""
<section class="page certificate-page">
  <div class="certificate">
    <img class="logo" src="{IMG}/brand.logo.png" alt="Taleria">
    <p class="eyebrow dark">Urkunde</p>
    <h1>{badge_title}</h1>
    <img class="badge" src="{IMG}/{badge_img}" alt="">
    <p class="cert-text">Hiermit bestätigen Kapitän Talo und Zahlmeisterin Tala:</p>
    <div class="cert-name"><div class="writeline"></div><span>Name</span></div>
    <p class="cert-text">hat die <b>{title}</b> geschafft und weiß jetzt, {learned}.</p>
    <div class="signs">
      <div><span class="script">Talo</span><div class="sline"></div><span>Kapitän Talo</span></div>
      <div><div class="writeline date"></div><span>Datum</span></div>
      <div><span class="script">Tala</span><div class="sline"></div><span>Zahlmeisterin Tala</span></div>
    </div>
  </div>
  <div class="code-box">
    <img src="{IMG}/icon.treasure.png" alt="">
    <div>
      <p class="eyebrow dark">Dein Schatzcode</p>
      <p class="treasure-code">{code}</p>
      <p>Öffne in der App die <b>Werft</b> und tippe auf <b>„Schatzcode eingeben“</b>. Dafür bekommst du {reward}!</p>
    </div>
  </div>
{foot(title, nr)}</section>
"""


def parents(title, solutions, nr):
    boxes = "".join(
        f'    <div class="box gold">\n      <h3>{h}</h3>\n      <ul>\n'
        + "".join(f"        <li>{li}</li>\n" for li in items)
        + "      </ul>\n    </div>\n"
        for h, items in solutions
    )
    return f"""
<section class="page parents">
  <div class="head"><span class="tag">Für Eltern</span><h2>Lösungen und Tipps</h2></div>
  <div class="box">
    <h3>So nutzen Sie das Logbuch</h3>
    <ul>
      <li>Jede Seite gehört zu Stationen der {title}. Am besten macht Ihr Kind die Seite, nachdem es die Station in der App gespielt hat.</li>
      <li>Es gibt keine Noten. Bei vielen Aufgaben gibt es mehrere gute Antworten; wichtig ist, dass Ihr Kind seine Antwort begründen kann.</li>
      <li>Die Fragen „Frag deine Eltern“ sind Gesprächsanlässe. Ihre eigenen Geschichten bleiben Kindern am besten im Kopf.</li>
    </ul>
  </div>
  <div class="cols">
{boxes}  </div>
  <div class="box coral">
    <h3>Der Schatzcode</h3>
    <p>Der Code auf der Urkunde schaltet in der App ein Teil für das eigene Schiff frei (Werft). Es ist nur Aussehen, nichts kann gekauft werden. Am schönsten ist es, wenn Ihr Kind den Code eingibt, nachdem es das Logbuch fertig gemacht hat.</p>
  </div>
  <div class="foot"><span>Alle Beträge im Logbuch sind Übungsbeispiele. Keine Finanzberatung.</span><span>Seite {nr}</span></div>
</section>
"""


def opts(items, cls="checks"):
    return f'      <div class="{cls}">\n' + "".join(f'        <span class="opt">{i}</span>\n' for i in items) + "      </div>\n"


def circles(items, cls="order"):
    return f'      <div class="{cls}">\n' + "".join(
        f'        <div class="ord"><span class="circle"></span>{i}</div>\n' for i in items
    ) + "      </div>\n"


def table(headers, rows, cls="grid"):
    out = f'      <table class="{cls}">\n        <tr>' + "".join(f"<th>{h}</th>" for h in headers) + "</tr>\n"
    for r in rows:
        out += "        <tr>" + "".join(f'<td class="fill">{c}</td>' if c == "" else f"<td>{c}</td>" for c in r) + "</tr>\n"
    return out + "      </table>\n"


def p(text, cls=None):
    return f'      <p{f" class=\"{cls}\"" if cls else ""}>{text}</p>\n'


def line(label=""):
    return f'      <p>{label}<span class="inline-line"></span></p>\n'


def draw(small=False):
    return f'      <div class="drawbox{" small" if small else ""}"></div>\n'


# ---------------------------------------------------------------------------
# Tauschinsel
# ---------------------------------------------------------------------------

def tauschinsel():
    t = "Tauschinsel"
    traders = "".join(
        f"""        <div class="trader"><img src="{IMG}/character.{w}.png" alt=""><b>{n}</b><span>hat: {h}</span><span class="wants">will: {wi}</span></div>
"""
        for w, n, h, wi in [
            ("bruno", "Bruno, der Bär", "Äpfel", "Fisch"),
            ("greta", "Greta, die Ziege", "Seil", "Äpfel"),
            ("otti", "Otti, der Otter", "Fisch", "Eimer"),
            ("olga", "Olga, die Schildkröte", "Muschel", "Eimer"),
        ]
    )
    s = head(t) + cover(2, t, "Tauschen, Werte und faire Geschäfte")
    s += page("Station 1 und 2", "Tauschen ohne Geld", t, 2,
        task(1, "Wer hat was?", p("Auf der Tauschinsel gibt es kein Geld. Hier siehst du, wer was hat und was er dafür haben will.")
             + '      <div class="traders">\n' + traders + "      </div>\n"
             + p("Tala hat einen <b>Eimer</b> und braucht ein <b>Seil</b>. Schreib auf, mit wem sie nacheinander tauscht.")
             + '      <div class="steps-line"><span>Eimer</span>→<i></i>→<i></i>→<span>Seil</span></div>\n'
             + p("Warum hilft ihr der Tausch mit Olga nicht weiter?")
             + '      <div class="writeline"></div>\n')
        + task(2, "Vor jedem Tausch überlegen", p("Kreuze an, was du dich vor einem Tausch fragen solltest.")
             + opts(["Was brauche ich wirklich?", "Was gebe ich dafür her?", "Wer ruft am lautesten?", "Darf man zurücktauschen?"], "checks two"))
        + talk("character.talo.think", "Was hast du als Kind getauscht, und war es ein guter Tausch?"))
    s += page("Station 3 und 4", "Was ist es wert?", t, 3,
        task(1, "Wert ist nicht für jeden gleich", p("Wann ist das Ding mehr wert? Kreise die Situation ein.")
             + table(["Ding", "Situation A", "Situation B"], [
                 ["ein Regenschirm", "bei Regen", "bei Sonnenschein"],
                 ["eine Flasche Wasser", "am Strand in der Hitze", "zu Hause am Wasserhahn"],
                 ["eine warme Mütze", "im Sommer", "im Winter"],
             ]))
        + task(2, "Wenn alle Eis wollen", p("Am Eisstand gibt es nur 20 Kugeln. Wird der Preis eher <b>höher</b> oder <b>niedriger</b>? Schreib H oder N in den Kreis.")
             + circles(["Es ist heiß, und 30 Kinder wollen Eis.", "Es regnet, und kaum jemand will Eis.", "Ein zweiter Eisstand macht daneben auf.", "Morgen ist ein Fest, alle kommen zum Strand."]))
        + task(3, "Was ist dir viel wert?", p("Male etwas, das dir viel wert ist, für andere aber kaum etwas.") + draw(small=True)))
    s += page("Station 5 und 6", "Billig oder günstig?", t, 4,
        task(1, "Ottis Netze", p("Ein billiges Netz kostet <b>5 Taler</b> und hält einen Monat. Ein gutes Netz kostet <b>20 Taler</b> und hält ein ganzes Jahr.")
             + line("Wie viel kosten billige Netze für ein ganzes Jahr (12 Monate)? ")
             + line("Welches ist auf das Jahr gesehen günstiger? ")
             + p("Platz zum Rechnen:", "hint") + draw(small=True))
        + task(2, "Preis pro Stück", p("Bei Händler A gibt es <b>4 Fische für 10 Taler</b>. Bei Händler B gibt es <b>3 Fische für 9 Taler</b>.")
             + table(["", "So viel kostet 1 Fisch"], [["Händler A", ""], ["Händler B", ""]])
             + line("Wo ist ein Fisch günstiger? "))
        + task(3, "Jede Wahl hat einen Preis", p("Du hast <b>10 Taler</b>. Ein Kinobesuch kostet 8 Taler, ein Buch 7 Taler und ein Eis 3 Taler. Wofür entscheidest du dich, und worauf verzichtest du dafür?")
             + '      <div class="writeline"></div><div class="writeline"></div>\n'))
    s += page("Station 7 und Auftrag", "Fair tauschen", t, 5,
        task(1, "Was gehört zu einem fairen Tausch?", p("Kreuze an.")
             + opts(["Beide wissen genau, was sie bekommen.", "Beide sind einverstanden.", "Einer überredet den anderen schnell.", "Man klärt vorher, ob man zurücktauschen darf.", "Man verschweigt, dass etwas kaputt ist.", "Keiner fühlt sich gedrängt."], "checks two"))
        + task(2, "Auftrag: Fairer Tausch", p("Tausche mit jemandem aus deiner Familie etwas, zum Beispiel ein Buch, ein Spielzeug oder eine Sammelkarte.")
             + table(["", "Ich", "Mein Tauschpartner"], [["Das gebe ich her", "", ""], ["Darum ist es mir etwas wert", "", ""], ["Dürfen wir zurücktauschen?", "", ""]], "grid detective"))
        + talk("character.tala.think", "Wann musstest du zuletzt auf etwas verzichten, um dir etwas anderes leisten zu können?"))
    s += certificate(t, "Meistertauscher", "badge.tauschinsel.png",
        "wie Tauschen klappt, warum Dinge für jeden anders viel wert sind und warum billig nicht immer günstig ist",
        "MUSCHEL3", "die <b>Muschel-Flagge</b> für dein Schiff", 6)
    s += parents(t, [
        ("Seite 2", ["Tauschkette: Eimer an Otti (gibt Fisch), Fisch an Bruno (gibt Äpfel), Äpfel an Greta (gibt Seil).",
                     "Olga gibt eine Muschel, die aber niemand haben will: eine Sackgasse.",
                     "Richtig: brauchen, hergeben, zurücktauschen. Nicht: wer am lautesten ruft."]),
        ("Seite 3", ["Mehr wert: Schirm bei Regen, Wasser in der Hitze, Mütze im Winter.",
                     "Preis eher höher: heiß und viele Kinder, Fest am Strand. Eher niedriger: Regen, zweiter Eisstand."]),
        ("Seite 4", ["12 × 5 Taler = 60 Taler. Das gute Netz (20 Taler) ist günstiger.",
                     "Händler A: 2,50 Taler pro Fisch, Händler B: 3 Taler. A ist günstiger.",
                     "Verzicht: Mit 10 Talern geht Kino (8) oder Buch und Eis (10), nicht alles. Jede Wahl ist in Ordnung, wenn Ihr Kind den Verzicht benennt."]),
        ("Seite 5", ["Fair: wissen, einverstanden, zurücktauschen klären, nicht gedrängt. Nicht fair: überreden, Mängel verschweigen."]),
    ], 7)
    return s + "\n</body>\n</html>\n"


# ---------------------------------------------------------------------------
# Wunschinsel
# ---------------------------------------------------------------------------

def wunschinsel():
    t = "Wunschinsel"
    s = head(t) + cover(3, t, "Brauchen, wollen und klug wünschen")
    s += page("Station 1 und 2", "Brauchen oder wollen?", t, 2,
        task(1, "Bedürfnis oder Wunsch?", p("Schreib <b>B</b> (das brauche ich) oder <b>W</b> (das wünsche ich mir) in den Kreis.")
             + circles(["Trinkwasser", "ein Videospiel", "eine Winterjacke", "Sammelsticker", "eine Zahnbürste", "eine Kinokarte", "Brot", "Glitzer-Turnschuhe", "ein Bett"], "order three"))
        + task(2, "Was zuerst?", p("Du hast <b>15 €</b>. Nummeriere von 1 (am wichtigsten) bis 4. Dann kreise ein, was du dir von 15 € kaufst.")
             + table(["Was?", "Preis", "Wie wichtig?"], [
                 ["ein Heft für die Schule", "2 €", ""],
                 ["Geschenk für Omas Geburtstag", "8 €", ""],
                 ["ein Comic", "6 €", ""],
                 ["ein Eis", "2 €", ""],
             ])
             + line("So viel bleibt übrig: ") )
        + talk("character.tala.think", "Was hast du dir mal sehr gewünscht und dann kaum benutzt?"))
    s += page("Station 3 und 4", "Warten und Nein sagen", t, 3,
        task(1, "Meine Wunschflasche", p("Schreib einen Wunsch auf. Nach einer Woche schaust du nach: Willst du ihn noch?")
             + """      <div class="bottle">
        <div class="bottle-neck"></div>
        <div class="bottle-body">
          <b>Mein Wunsch:</b><div class="writeline"></div>
          <b>Heute ist der:</b><div class="writeline"></div>
          <b>Nach einer Woche:</b> <span class="opt">Ich will ihn noch.</span> <span class="opt">Ich brauche ihn nicht mehr.</span>
        </div>
      </div>
""")
        + task(2, "„Alle haben das!“", p("Deine Freunde sagen: „Alle haben die neuen Schuhe, du musst sie auch kaufen!“ Was kannst du sagen? Kreuze an, was dir hilft.")
             + opts(["„Ich überlege es mir erst in Ruhe.“", "„Okay, ich kaufe sie sofort.“", "„Ich brauche sie gerade nicht.“", "„Ich spare gerade für etwas anderes.“", "„Ihr seid doof.“", "„Mir gefallen meine Schuhe.“"], "checks two")))
    s += page("Station 5 und 6", "Was macht glücklich?", t, 4,
        task(1, "Glück ohne Geld", p("Male drei Dinge, die dich glücklich machen und kein Geld kosten.")
             + '      <div class="three-boxes"><div class="drawbox small"></div><div class="drawbox small"></div><div class="drawbox small"></div></div>\n')
        + task(2, "Erlebnis oder Ding?", p("Schreib <b>E</b> (Erlebnis) oder <b>D</b> (Ding) in den Kreis.")
             + circles(["ein Ausflug an den See", "ein neues Spielzeugauto", "ein Picknick mit Freunden", "ein T-Shirt", "eine Nacht im Zelt", "ein Kuscheltier"], "order three"))
        + talk("character.talo.think", "Was war dein schönstes Erlebnis, das fast kein Geld gekostet hat?"))
    s += page("Station 7 und Auftrag", "Meine Wunschliste", t, 5,
        task(1, "Meine Wunschliste", p("Schreib deine Wünsche auf. Brauchst du sie (B) oder wünschst du sie dir (W)? Wie wichtig sind sie (1 = sehr, 3 = nicht so)?")
             + table(["Wunsch", "Ungefährer Preis", "B oder W", "Wie wichtig?"], [["", "", "", ""]] * 4, "grid detective"))
        + task(2, "Auftrag: Wunschflasche", p("Steck einen Wunsch in der App in die <b>Wunschflasche</b>. Schau nach einer Woche mit deinen Eltern nach, ob du ihn noch willst.")
             + p("Das habe ich nach einer Woche entschieden:")
             + '      <div class="writeline"></div><div class="writeline"></div>\n'))
    s += certificate(t, "Klarer Kompass", "badge.wunschinsel.png",
        "was man wirklich braucht, wie die Warte-Regel hilft und wie man Nein sagt",
        "FLASCHE5", "die <b>Flaschenpost-Flagge</b> für dein Schiff", 6)
    s += parents(t, [
        ("Seite 2", ["Brauchen: Trinkwasser, Winterjacke, Zahnbürste, Brot, Bett. Wünschen: Videospiel, Sticker, Kinokarte, Glitzer-Turnschuhe.",
                     "Sinnvolle Reihenfolge zum Beispiel: Heft, Geschenk, dann Eis oder Comic. Heft, Geschenk und Eis kosten 12 €, 3 € bleiben übrig. Comic statt Eis ginge nicht (16 €)."]),
        ("Seite 3", ["Hilfreich: in Ruhe überlegen, gerade nicht nötig, für etwas anderes sparen, eigene Schuhe gefallen.",
                     "Nicht hilfreich: sofort nachgeben oder andere beleidigen."]),
        ("Seite 4", ["Erlebnisse: See, Picknick, Zelt. Dinge: Spielzeugauto, T-Shirt, Kuscheltier.",
                     "Studien zeigen, dass Erlebnisse oft länger glücklich machen. Beides ist erlaubt."]),
        ("Seite 5", ["Die Wunschliste hat keine richtige Lösung. Gut ist, wenn Ihr Kind Wünsche und Bedürfnisse unterscheidet und Prioritäten setzt."]),
    ], 7)
    return s + "\n</body>\n</html>\n"


# ---------------------------------------------------------------------------
# Spar-Insel
# ---------------------------------------------------------------------------

def spar_insel():
    t = "Spar-Insel"
    s = head(t) + cover(4, t, "Sparen, Geduld und der eigene Sparplan")
    s += page("Station 1 und 2", "Warum sparen?", t, 2,
        task(1, "Wofür ist Sparen gut?", p("Kreuze alles an, was stimmt.")
             + opts(["Ich kann mir später etwas Größeres leisten.", "Ich habe Geld, wenn etwas kaputtgeht.", "Gespartes Geld wird von allein doppelt so viel.", "Ich muss mir nicht sofort alles kaufen.", "Sparen heißt, nie wieder etwas auszugeben.", "Ich kann ein Ziel planen."], "checks two"))
        + task(2, "Mein Wunschschatz", p("Ein gutes Sparziel ist genau: Was, wie viel, bis wann?")
             + """      <div class="goal-card">
        <div class="drawbox small"></div>
        <div class="goal-lines">
          <b>Was wünsche ich mir?</b><div class="writeline"></div>
          <b>Was kostet es?</b><div class="writeline"></div>
          <b>Bis wann will ich es haben?</b><div class="writeline"></div>
        </div>
      </div>
""")
        + talk("character.tala.think", "Wofür hast du als Kind gespart?"))
    s += page("Station 3 und 4", "Kleine Beträge werden groß", t, 3,
        task(1, "50 Cent am Tag", p("Tala legt jeden Tag <b>50 Cent</b> zurück. Wie viel hat sie nach …")
             + table(["Zeit", "Rechnung", "Gespart"], [
                 ["1 Woche (7 Tage)", "7 × 50 ct", ""],
                 ["4 Wochen", "4 × ...", ""],
                 ["1 Jahr (52 Wochen)", "52 × ...", ""],
             ]))
        + task(2, "Geduld lohnt sich", p("Gustav, die Grille, darf sofort <b>ein</b> Eis essen. Emma, das Eichhörnchen, wartet eine Woche und bekommt dafür <b>zwei</b> Eis. Was würdest du machen, und warum?")
             + '      <div class="writeline"></div><div class="writeline"></div>\n')
        + task(3, "Wie viel Geduld brauchst du?", p("Wie lange musst du sparen? Tala legt jede Woche <b>3 Taler</b> zurück.")
             + table(["Ziel", "So viele Wochen"], [["ein Ball für 12 Taler", ""], ["ein Buch für 9 Taler", ""], ["ein Rucksack für 30 Taler", ""]])))
    s += page("Station 5 und 6", "Mein Sparplan", t, 4,
        task(1, "Emmas Sparplan", p("Emma möchte <b>30 Taler</b> sparen und legt jede Woche <b>5 Taler</b> zurück. Male für jede Woche ein Kästchen aus, bis sie 30 Taler hat.")
             + '      <div class="plan">' + "".join(f'<div class="week"><span>Woche {i}</span><div class="cell"></div></div>' for i in range(1, 9)) + "</div>\n"
             + line("Nach wie vielen Wochen hat sie ihr Ziel erreicht? "))
        + task(2, "Wo spare ich?", p("Verbinde jeden Sparort mit dem, was zu ihm passt.")
             + """      <div class="match">
        <div class="mright">
          <div class="what"><i></i><b>Sparschwein</b></div>
          <div class="what"><i></i><b>Spardose mit Schloss</b></div>
          <div class="what"><i></i><b>Konto bei der Bank</b></div>
        </div>
        <div class="mright">
          <div class="what"><i></i>Man sieht und hört, wie es mehr wird.</div>
          <div class="what"><i></i>Das Geld ist sicher, und Erwachsene helfen beim Einrichten.</div>
          <div class="what"><i></i>Man kommt nicht so leicht schnell ans Geld.</div>
        </div>
      </div>
"""))
    s += page("Station 7 und Auftrag", "Schatztruhen-Challenge", t, 5,
        task(1, "Vier Wochen sparen", p("Leg vier Wochen lang jede Woche etwas für deinen Wunschschatz zurück, egal wie wenig. Trag es hier ein.")
             + table(["Woche", "Diese Woche zurückgelegt", "Zusammen"], [["1", "", ""], ["2", "", ""], ["3", "", ""], ["4", "", ""]], "grid detective"))
        + task(2, "Auftrag: Erster Wunschschatz", p("Legt in der App zusammen einen <b>Wunschschatz</b> an und besprecht, wie viel jede Woche dafür zurückgelegt wird.")
             + line("Unser Plan: jede Woche ") )
        + talk("character.talo.think", "Wofür sparen wir als Familie gerade?"))
    s += certificate(t, "Vorratsmeister", "icon.treasure.png",
        "warum Sparen hilft, wie kleine Beträge groß werden und wie ein Sparplan funktioniert",
        "TALER9", "die <b>Taler-Flagge</b> für dein Schiff", 6)
    s += parents(t, [
        ("Seite 2", ["Richtig: Größeres leisten, Notfälle, nicht sofort kaufen, Ziel planen.",
                     "Nicht richtig: Geld verdoppelt sich nicht von allein, und Sparen heißt nicht, nie etwas auszugeben."]),
        ("Seite 3", ["1 Woche: 3,50 €. 4 Wochen: 4 × 3,50 € = 14 €. 1 Jahr: 52 × 3,50 € = 182 €.",
                     "Ball: 4 Wochen. Buch: 3 Wochen. Rucksack: 10 Wochen.",
                     "Bei Gustav und Emma gibt es kein Richtig oder Falsch; spannend ist die Begründung."]),
        ("Seite 4", ["6 Wochen (6 × 5 Taler = 30 Taler).",
                     "Sparschwein: man sieht und hört es. Spardose mit Schloss: nicht so leicht ans Geld. Konto: sicher, Erwachsene helfen."]),
        ("Seite 5", ["Bei der Challenge zählt das Dranbleiben, nicht der Betrag."]),
    ], 7)
    return s + "\n</body>\n</html>\n"


def _wortsuche(words, size=9):
    """Kleine Wörtersuche: Wörter waagerecht und senkrecht, Rest mit festen Buchstaben."""
    grid = [["" for _ in range(size)] for _ in range(size)]
    places = [(0, 0, 0), (2, 1, 0), (4, 0, 0), (6, 2, 0), (0, 8, 1), (8, 3, 0)]
    for (r, c, down), w in zip(places, words):
        for k, ch in enumerate(w):
            rr, cc = (r + k, c) if down else (r, c + k)
            grid[rr][cc] = ch
    filler = "AEMORNSTLIKUBEGPA"
    n = 0
    for r in range(size):
        for c in range(size):
            if not grid[r][c]:
                grid[r][c] = filler[n % len(filler)]
                n += 3
    rows = "".join("<tr>" + "".join(f"<td>{ch}</td>" for ch in row) + "</tr>" for row in grid)
    return f'      <table class="grid" style="width:auto;margin:6px auto;text-align:center;font-weight:700;letter-spacing:2px">{rows}</table>\n'


def taschengeld_bucht():
    t = "Taschengeld-Bucht"
    s = head(t) + cover(5, t, "Taschengeld einteilen, aufschreiben und planen")
    s += page("Station 1", "Wie viel Taschengeld ist üblich?", t, 2,
        task(1, "Was stimmt beim Taschengeld?", p("Kreuze alles an, was stimmt.")
             + opts(["Jede Familie entscheidet selbst, wie viel es gibt.", "Wer mehr bekommt, muss oft auch mehr selbst bezahlen.", "Alle Kinder bekommen gleich viel.", "Vergleichen macht oft unzufrieden.", "Mit einer festen Summe kann man gut üben.", "Taschengeld muss man sofort ausgeben."], "checks two"))
        + task(2, "Wer bezahlt was?", p("Frag deine Eltern und kreuze an, wer was bei euch bezahlt.")
             + table(["", "Ich", "Meine Eltern"], [["Süßigkeiten", "", ""], ["Hefte und Stifte", "", ""], ["Kino mit Freunden", "", ""], ["Busfahrten", "", ""], ["Geschenke für Freunde", "", ""]]))
        + task(3, "Wöchentlich oder monatlich?", p("Bekommst du dein Taschengeld jede Woche oder einmal im Monat? Was ist daran gut, was ist schwer?")
             + '      <div class="writeline"></div><div class="writeline"></div>\n')
        + talk("character.tala.think", "Wie viel Taschengeld hattest du als Kind?"))
    s += page("Station 2", "Geld bekommt eine Aufgabe", t, 3,
        task(1, "Talas 10 Taler", p("Tala legt <b>3 Taler</b> für ihren Wunschschatz zurück. Wie viel ist frei zum Ausgeben?")
             + line("Frei zum Ausgeben: "))
        + task(2, "Frei oder zurücklegen?", p("Schreib ein <b>F</b> (frei zum Ausgeben) oder ein <b>W</b> (für einen Wunschschatz zurücklegen) in den Kreis.")
             + circles(["Ein Eis heute", "Rollschuhe für 40 Taler", "Sticker fürs Album", "Ein Zelt für die Ferien", "Saft für den Ausflug morgen", "Ein großes Lego-Schiff"]))
        + task(3, "Meine Aufteilung", p("So teile ich mein eigenes Taschengeld auf:")
             + table(["", "Betrag"], [["Mein Taschengeld", ""], ["Für meinen Wunschschatz", ""], ["Frei zum Ausgeben", ""]])
             + line("Mein Wunschschatz ist: ")))
    s += page("Station 3", "Einnahmen und Ausgaben", t, 4,
        task(1, "Einnahme oder Ausgabe?", p("Schreib ein <b>E</b> für Einnahme oder ein <b>A</b> für Ausgabe in den Kreis.")
             + circles(["Taschengeld von Mama", "Ein Eis am Kiosk", "Geld von Oma zum Geburtstag", "Eine Busfahrkarte", "Ein Heft für die Schule", "Geld fürs Rasenmähen"]))
        + task(2, "Kurts Logbuch rechnen", p("Kurt beginnt mit <b>5 Talern</b>. Rechne den Stand nach jedem Zettel aus.")
             + table(["Zettel", "+ / −", "Stand"], [["Am Anfang", "", "5"], ["Taschengeld", "+ 8", ""], ["Bonbons", "− 2", ""], ["Comic", "− 4", ""], ["Geld von Oma", "+ 5", ""], ["Eis", "− 3", ""]]))
        + task(3, "Wofür geht mein Geld?", p("Male für jede Sache so viele Kästchen aus, wie du in einer Woche ausgibst.")
             + table(["", "1", "2", "3", "4", "5", "6"], [["Süßes", "", "", "", "", "", ""], ["Spielzeug", "", "", "", "", "", ""], ["Schule", "", "", "", "", "", ""], ["Anderes", "", "", "", "", "", ""]])))
    s += page("Station 4", "Mein Wochenplan", t, 5,
        task(1, "Mit 8 Talern durch die Woche", p("Die Busfahrt (<b>2 Taler</b>) muss sein. Was passt noch in 8 Taler? Kreuze an und rechne.")
             + opts(["Kinokarte: 6 Taler", "Sticker: 2 Taler", "Snack: 3 Taler", "Glitzerstift: 1 Taler"], "checks two")
             + line("Das kostet zusammen: "))
        + task(2, "Mein eigener Wochenplan", p("Plane deine nächste Woche. Was muss sein, was wünschst du dir?")
             + table(["Tag", "Was?", "Muss sein?", "Taler"], [["Montag", "", "", ""], ["Dienstag", "", "", ""], ["Mittwoch", "", "", ""], ["Donnerstag", "", "", ""], ["Freitag", "", "", ""], ["Wochenende", "", "", ""]])
             + line("Mein Taschengeld: ") + line("Alles zusammen kostet: ") + line("Passt es? ")))
    s += page("Station 5", "Wenn das Geld alle ist", t, 6,
        task(1, "Der Beutel ist leer", p("Es ist Mittwoch, und Talas Taschengeld ist schon weg. Was ist klug? Kreuze an.")
             + opts(["Bis zum nächsten Taschengeld warten", "Sofort Geld leihen und doppelt zurückgeben", "Etwas machen, das nichts kostet", "Nächste Woche gleich am Montag planen"], "checks two"))
        + task(2, "Leihen kostet mehr", p("Mia leiht Tala <b>5 Taler</b>. Nächste Woche will sie <b>10 Taler</b> zurück.")
             + line("So viel muss Tala mehr zurückgeben: "))
        + task(3, "Spaß ohne Geld", p("Schreib fünf Dinge auf, die Spaß machen und nichts kosten.")
             + "".join('      <div class="writeline"></div>\n' for _ in range(5))))
    s += page("Station 6", "Geld geschenkt bekommen", t, 7,
        task(1, "Omas Geschenk", p("Oma schenkt dir <b>20 Taler</b>. Wie teilst du sie auf?")
             + table(["Wofür?", "Taler"], [["Jetzt ausgeben", ""], ["Für meinen Wunschschatz", ""], ["Zusammen", "20"]]))
        + task(2, "Rechnen wie Tala", p("Tala hatte <b>18 Taler</b> zurückgelegt und legt <b>12</b> dazu. Die Rollschuhe kosten <b>40 Taler</b>.")
             + line("Jetzt hat sie: ") + line("Es fehlen noch: "))
        + task(3, "Meine Danke-Karte", p("Male eine Danke-Karte für jemanden, der dir etwas geschenkt hat.") + draw(small=True)))
    s += page("Station 7", "Taschengeld verhandeln", t, 8,
        task(1, "Gut verhandeln", p("Was hilft, wenn du um mehr Taschengeld bittest? Kreuze an.")
             + opts(["In einem ruhigen Moment fragen", "Mein Logbuch zeigen", "Quengeln, bis alle Ja sagen", "Anbieten, mehr selbst zu bezahlen", "Sagen, dass alle anderen mehr bekommen", "Freundlich bleiben, wenn die Antwort Nein ist"], "checks two"))
        + task(2, "Meine guten Gründe", p("Warum könntest du mehr Taschengeld brauchen? Und was würdest du dafür selbst bezahlen?")
             + line("Mein Grund: ") + line("Das bezahle ich dann selbst: "))
        + task(3, "Übt das Gespräch", p("Spielt es zu Hause einmal durch. Diese Satzanfänge helfen:")
             + opts(["„Ich habe aufgeschrieben, dass …“", "„Ich würde gern selbst … bezahlen.“", "„Können wir nächste Woche noch einmal darüber reden?“"], "checks"))
        + talk("character.talo.think", "Was könnte ich ab jetzt selbst bezahlen?"))
    s += page("Rätsel", "Kurts Rätselseite", t, 9,
        task(1, "Wörtersuche", p("Finde die 6 Wörter: <b>TALER</b>, <b>BUDGET</b>, <b>KIOSK</b>, <b>SPAREN</b>, <b>LOGBUCH</b>, <b>PLAN</b>.")
             + _wortsuche(["TALER", "BUDGET", "KIOSK", "SPAREN", "LOGBUCH", "PLAN"]))
        + task(2, "Kurts Kopfrechnen", p("Rechne im Kopf.")
             + table(["Aufgabe", "Ergebnis"], [["10 Taler − 3 − 4", ""], ["5 Wochen × 3 Taler", ""], ["Spiel für 15 Taler, 5 Taler pro Woche: wie viele Wochen?", ""]])))
    s += page("Auftrag", "Logbuch-Woche", t, 10,
        task(1, "Auftrag: Logbuch-Woche", p("Schreib eine Woche lang alles auf, was du bekommst und ausgibst. Schau es danach mit deinen Eltern an.")
             + table(["Tag", "Bekommen", "Ausgegeben", "Wofür?"], [["Montag", "", "", ""], ["Dienstag", "", "", ""], ["Mittwoch", "", "", ""], ["Donnerstag", "", "", ""], ["Freitag", "", "", ""], ["Samstag", "", "", ""], ["Sonntag", "", "", ""]], "grid detective")
             + line("Am meisten habe ich ausgegeben für: ")))
    s += certificate(t, "Kassenwart der Bucht", "badge.taschengeld-bucht.png",
        "wie man Taschengeld einteilt, aufschreibt und eine Woche plant",
        "KURT5", "die <b>Logbuch-Flagge</b> für dein Schiff", 11)
    s += parents(t, [
        ("Seiten 2 und 3", ["Richtig: Familie entscheidet, wer mehr bekommt zahlt oft mehr selbst, Vergleichen macht unzufrieden, feste Summe zum Üben.",
                     "Tala: 7 Taler frei. F: Eis, Sticker, Saft. W: Rollschuhe, Zelt, Lego-Schiff."]),
        ("Seiten 4 und 5", ["E: Taschengeld, Geld von Oma, Rasenmähen. A: Eis, Busfahrkarte, Heft.",
                     "Kurts Logbuch: 13, 11, 7, 12, 9 Taler.",
                     "Wochenplan: Busfahrt und Kino (8 Taler) oder Busfahrt, Sticker, Snack und Glitzerstift (8 Taler)."]),
        ("Seiten 6 bis 8", ["Klug: warten, etwas Kostenloses machen, nächste Woche gleich planen. Tala muss 5 Taler mehr zurückgeben.",
                     "Tala hat jetzt 30 Taler, es fehlen noch 10.",
                     "Hilfreich: ruhiger Moment, Logbuch zeigen, mehr selbst bezahlen, freundlich bleiben."]),
        ("Seite 9", ["Kopfrechnen: 3 Taler, 15 Taler, 3 Wochen."]),
    ], 12)
    return s + "\n</body>\n</html>\n"


if __name__ == "__main__":
    for name, build in [("tauschinsel", tauschinsel), ("wunschinsel", wunschinsel), ("spar-insel", spar_insel), ("taschengeld-bucht", taschengeld_bucht)]:
        path = OUT / f"logbuch_{name}.html"
        path.write_text(build(), encoding="utf-8")
        print("geschrieben:", path.name)
