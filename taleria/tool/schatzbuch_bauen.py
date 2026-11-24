"""Baut „Talos und Talas Schatzbuch, Teil 1“ (HTML) aus den Logbüchern und der App.

Aufbau (Marcs Wahl am 24.11.2026): ein Buch für Hafen bis Taschengeld-Bucht,
Farbe sparsam plus Ausmalseiten, das Kind arbeitet allein, die Eltern helfen.
Verbindung zur App: Schatzcodes für die Werft (Urkunden), Hinweise auf die
Stationen (Seiten-Kopf), „Gemeinsam“-Seiten (Erklär's deinen Eltern und
Crew-Abenteuer mit Eltern-Code) und eine Seekarte zum Abhaken.

Was woher kommt:
- Aufgabenseiten und Urkunden: aus den Logbüchern (logbuch/logbuch_*.html),
  Kopf- und Fußzeilen werden neu gesetzt.
- Lernziele, Erklärpunkte, Nachfragen, Crew-Abenteuer: aus den Inhaltsdateien
  der App (content/stufe1), damit Buch und App dasselbe sagen.
- Ausmalbilder: Umrisse der Inselbewohner, im Werkzeug aus den App-Bildern gerechnet.
- Neue Rätsel- und Bastelseiten: unten pro Insel.

Aufruf im Ordner taleria/:  python3 tool/schatzbuch_bauen.py
Danach das PDF mit Playwright (A4, siehe tool/schatzbuch_pdf.js).
"""

import json
import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageOps

import logbuch_bauen as lb

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "schatzbuch"
IMG = "../assets/images"
BOOK = "Talos und Talas Schatzbuch"

ISLANDS = [
    # Slug, Datei der Inhalte, Logbuch, Bewohner fürs Ausmalbild
    ("hafen", "01-hafen.json", "logbuch_hafen.html", ["character.talo.wave", "character.tala.wave"]),
    ("tauschinsel", "02-tauschinsel.json", "logbuch_tauschinsel.html", ["character.bruno", "character.greta"]),
    ("wunschinsel", "03-wunschinsel.json", "logbuch_wunschinsel.html", ["character.elsa", "character.moritz"]),
    ("spar-insel", "04-spar-insel.json", "logbuch_spar-insel.html", ["character.emma", "character.gustav"]),
    ("taschengeld-bucht", "05-taschengeld-bucht.json", "logbuch_taschengeld-bucht.html", ["character.mia", "character.kurt"]),
]


# ---------------------------------------------------------------------------
# Bausteine
# ---------------------------------------------------------------------------

def head():
    return f"""<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>{BOOK} · Teil 1</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@600;700;800&family=Caveat:wght@700&family=Nunito:wght@400;600;700;800&display=swap">
<link rel="stylesheet" href="../testphase/stil.css">
<link rel="stylesheet" href="../logbuch/logbuch.css">
<link rel="stylesheet" href="schatzbuch.css">
</head>
<body>
"""


def foot(label):
    # Die Seitenzahl setzt number_pages() am Ende.
    return f'  <div class="foot"><span>{BOOK} · {label}</span><span>Seite @@</span></div>\n'


def section(cls, body, label):
    return f'\n<section class="page {cls}">\n{body}{foot(label)}</section>\n'


def lineart(src: Path, dest: Path):
    """Umrisse zum Ausmalen aus einem freigestellten Bild: Kanten schwarz, Rest weiß."""
    im = Image.open(src).convert("RGBA")
    scale = 1400 / max(im.size)
    im = im.resize((int(im.width * scale), int(im.height * scale)), Image.LANCZOS)
    bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
    bg.alpha_composite(im)
    g = ImageOps.grayscale(bg.convert("RGB")).filter(ImageFilter.GaussianBlur(2.2))
    a = np.asarray(g).astype(float)
    gx = np.abs(np.diff(a, axis=1, append=a[:, -1:]))
    gy = np.abs(np.diff(a, axis=0, append=a[-1:, :]))
    edges = np.hypot(gx, gy) > 7.5
    out = Image.fromarray(np.where(edges, 0, 255).astype("uint8")).filter(ImageFilter.MinFilter(5))
    out.convert("1").save(dest, optimize=True)


# ---------------------------------------------------------------------------
# Vorne: Titel, Elternseite, Inhalt, Seekarte
# ---------------------------------------------------------------------------

def cover():
    return f"""
<section class="page cover book-cover">
  <div class="cover-top">
    <img class="logo" src="{IMG}/brand.logo.png" alt="Taleria">
    <p class="eyebrow">Teil 1 · Vom Hafen bis zur Taschengeld-Bucht</p>
    <h1>{BOOK}</h1>
    <p class="sub">Rätseln, rechnen, malen und mit deinen Eltern lernen, wie Geld funktioniert</p>
  </div>
  <div class="crew-big">
    <img src="{IMG}/character.talo.wave.png" alt="">
    <img src="{IMG}/character.tala.wave.png" alt="">
  </div>
  <div class="box gold owner">
    <div><b>Dieses Schatzbuch gehört:</b><div class="writeline"></div></div>
    <div><b>Mein Schiff heißt:</b><div class="writeline"></div></div>
  </div>
</section>
"""


def parents_intro():
    body = """  <div class="head"><span class="tag">Für Eltern</span><h2>So benutzt ihr das Schatzbuch</h2></div>
  <div class="box">
    <h3>Buch und App gehören zusammen</h3>
    <ul>
      <li><b>Erst die App, dann das Buch:</b> Oben auf jeder Seite steht, zu welcher Station sie gehört. Am besten macht Ihr Kind die Seite, nachdem es die Station in der App gespielt hat.</li>
      <li><b>Seekarte vorn im Buch:</b> Ihr Kind malt jede geschaffte Station aus. So sieht es, wie weit es schon gesegelt ist.</li>
      <li><b>Schatzcode auf jeder Urkunde:</b> Ihr Kind gibt ihn in der App in der <b>Werft</b> ein und bekommt ein besonderes Teil für sein Schiff.</li>
      <li><b>„Gemeinsam“-Seite in jedem Kapitel:</b> Ihr Kind erklärt Ihnen, was es gelernt hat, und Sie erleben zusammen ein kleines Crew-Abenteuer. Den Code dafür finden Sie in der App im <b>Leuchtturm</b> unter <b>„Gemeinsam“</b>. Für jeden Code gibt es einen Crew-Stern.</li>
    </ul>
  </div>
  <div class="cols">
    <div class="box gold">
      <h3>Wie viel helfen?</h3>
      <ul>
        <li>Die Aufgaben sind für Kinder von 8 bis 12 zum Alleinmachen gedacht.</li>
        <li>Es gibt keine Noten. Oft sind mehrere Antworten gut, wenn Ihr Kind sie begründen kann.</li>
        <li>Lösungen und Tipps stehen hinten im Buch.</li>
      </ul>
    </div>
    <div class="box gold">
      <h3>Drucken</h3>
      <ul>
        <li>A4, gern beidseitig. Die Seiten sind tintensparend gestaltet.</li>
        <li>Sie müssen nicht alles auf einmal drucken: Jedes Kapitel ist für sich vollständig.</li>
        <li>Die Ausmalseiten sind schwarz-weiß.</li>
      </ul>
    </div>
  </div>
  <div class="box coral">
    <h3>Gut zu wissen</h3>
    <p>Alle Beträge im Buch sind Übungsbeispiele. Taleria erklärt, wie Geld funktioniert, und ist keine Finanzberatung.</p>
  </div>
"""
    return section("parents", body, "Für Eltern")


def contents(chapters):
    rows = "".join(
        f'    <div class="toc-row"><img src="{IMG}/map.island.{slug}.png" alt=""><span>Kapitel {n}: {title}</span><span class="toc-dots"></span><span>Seite @{slug}@</span></div>\n'
        for n, (slug, title) in enumerate(chapters, 1)
    )
    body = f"""  <div class="head"><span class="tag">Inhalt</span><h2>Deine Reise</h2></div>
  <div class="toc">
    <div class="toc-row"><span>Deine Seekarte zum Ausmalen</span><span class="toc-dots"></span><span>Seite @karte@</span></div>
{rows}    <div class="toc-row"><span>Lösungen für Eltern</span><span class="toc-dots"></span><span>Seite @loesungen@</span></div>
  </div>
  <div class="box talk">
    <img src="{IMG}/character.tala.happy.png" alt="">
    <div><b>Tala sagt:</b> Auf jeder Insel wartet ein Kartenstück, eine Urkunde mit Schatzcode und ein Abenteuer mit deinen Eltern. Los geht's!</div>
  </div>
"""
    return section("", body, "Inhalt")


def sea_chart(chapters):
    rows = []
    for n, (slug, title) in enumerate(chapters, 1):
        dots = "".join(
            f'<span class="dot">{k}</span>' + ('<span class="dot anchor">⚓</span>' if k in (2, 4, 6) else "")
            for k in range(1, 8)
        )
        stops = '<span class="dot sea">⛵</span><span class="dot sea">⛵</span>' if n > 1 else ""
        rows.append(
            f'    <div class="chart-row"><img src="{IMG}/map.island.{slug}.png" alt=""><div><b>{n}. {title}</b>'
            f'<div class="dots">{stops}{dots}<span class="dot exam">★</span></div></div></div>\n'
        )
        if slug == "spar-insel":
            rows.append(
                f'    <div class="chart-row taleron"><img src="{IMG}/encounter.taleron.png" alt=""><div><b>Meister Talerons Prüfung</b>'
                '<div class="dots"><span class="dot exam big">Siegel</span></div></div></div>\n'
            )
    body = f"""  <div class="head"><span class="tag">Seekarte</span><h2>Wie weit bist du gesegelt?</h2></div>
  <p class="hint-line">Mal jeden Kreis aus, wenn du die Station in der App geschafft hast. ⛵ = Stopp auf See, ⚓ = Tauchgang, ★ = Prüfung der Insel.</p>
  <div class="chart">
{''.join(rows)}  </div>
"""
    return section("", body, "Seekarte")


# ---------------------------------------------------------------------------
# Pro Insel
# ---------------------------------------------------------------------------

def opener(n, slug, island):
    learn = "".join(f"<li>{lb_escape(l)}</li>" for l in island.get("lernziel_kind", []))
    body = f"""  <div class="chapter">
    <p class="eyebrow">Kapitel {n}</p>
    <h1>{island['titel']}</h1>
    <img class="chapter-island" src="{IMG}/map.island.{slug}.png" alt="">
  </div>
  <div class="box gold">
    <h3>Das lernst du hier</h3>
    <ul>{learn}</ul>
  </div>
  <div class="box">
    <h3>So machst du dieses Kapitel</h3>
    <ol>
      <li>Spiel in der App die Stationen auf der Insel {island['titel']}.</li>
      <li>Mach danach die passende Seite hier im Buch. Oben steht, zu welcher Station sie gehört.</li>
      <li>Mal auf der Seekarte vorn jede geschaffte Station aus.</li>
      <li>Am Ende: Erklär deinen Eltern, was du gelernt hast, und hol dir deine Urkunde mit Schatzcode.</li>
    </ol>
  </div>
"""
    return section("chapter-page", body, island["titel"])


def lb_escape(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def logbook_pages(file, title):
    """Aufgabenseiten und Urkunde aus dem Logbuch (ohne Titel- und Elternseite)."""
    html = (ROOT / "logbuch" / file).read_text(encoding="utf-8")
    pages, solutions = [], ""
    for cls, inner in re.findall(r'<section class="page([^"]*)">(.*?)</section>', html, re.S):
        if "cover" in cls:
            continue
        if "parents" in cls:
            m = re.search(r'<div class="cols">(.*?)</div>\s*<div class="box coral">', inner, re.S)
            solutions = m.group(1) if m else ""
            continue
        inner = re.sub(r'\s*<div class="foot">.*?</div>\s*$', "\n", inner, flags=re.S)
        pages.append(section(cls.strip(), inner, title))
    return pages, solutions


def coloring(slug, title, figures):
    for f in figures:
        lineart(ROOT / "assets" / "images" / f"{f}.png", OUT / "bilder" / f"ausmalen.{f}.png")
    imgs = "".join(f'<img src="bilder/ausmalen.{f}.png" alt="">' for f in figures)
    body = f"""  <div class="head"><span class="tag">Ausmalen</span><h2>Bewohner der Insel {title}</h2></div>
  <div class="coloring">{imgs}</div>
  <p class="hint-line">Mal die beiden aus. Wer sind sie, und was haben sie dir beigebracht?</p>
  <div class="writeline"></div><div class="writeline"></div>
"""
    return section("coloring-page", body, title)


def together(title, island):
    g = island.get("gemeinsam", {})
    points = "".join(
        f'      <div class="explain-point"><span class="check"></span><div><b>{lb_escape(p)}</b><div class="writeline"></div></div></div>\n'
        for p in g.get("erklaeren", [])
    )
    task = island.get("auftrag") or {}
    body = f"""  <div class="head"><span class="tag">Gemeinsam</span><h2>Mit deinen Eltern</h2></div>
  <div class="box">
    <h3>Erklär's deinen Eltern</h3>
    <p>Du kennst dich jetzt auf der Insel {title} aus. Erklär deinen Eltern diese 3 Dinge. Schreib dir vorher ein Stichwort dazu auf, wenn du magst.</p>
{points}    <p class="ask"><b>Deine Eltern fragen vielleicht:</b> „{lb_escape(g.get('nachfragen', ''))}“</p>
  </div>
  <div class="box gold">
    <h3>Crew-Abenteuer: {lb_escape(task.get('titel', ''))}</h3>
    <p>{lb_escape(task.get('text', ''))}</p>
    <div class="drawbox small"></div>
  </div>
  <div class="box coral code-steps">
    <div>
      <h3>So bekommst du deine Crew-Sterne</h3>
      <ol>
        <li>Deine Eltern öffnen in der App den <b>Leuchtturm</b> und dort <b>„Gemeinsam“</b>.</li>
        <li>Sie tippen auf <b>„Code anzeigen“</b> und sagen dir den Code.</li>
        <li>Du tippst auf deiner Startseite auf <b>„Crew-Abenteuer“</b> und gibst den Code ein.</li>
      </ol>
    </div>
    <div class="stars-row"><span class="check"></span> Erklärt <span class="check"></span> Abenteuer geschafft</div>
  </div>
"""
    return section("together-page", body, title)


# Neue Rätsel- und Bastelseiten (Lösungen in SOLUTIONS).
def extra(slug, title):
    t, p, opts, table, draw = lb.task, lb.p, lb.opts, lb.table, lb.draw
    if slug == "hafen":
        left = ["2,05 €", "0,50 €", "12,90 €", "1,99 €"]
        right = ["fünfzig Cent", "zwölf Euro und neunzig Cent", "zwei Euro und fünf Cent", "ein Euro und neunundneunzig Cent"]
        pairs = "".join(f'<div class="m-l">{a}<span class="m-dot"></span></div><div></div><div class="m-r"><span class="m-dot"></span>{b}</div>'
                        for a, b in zip(left, right))
        body = t(1, "Preise lesen", p("Verbinde jeden Preis mit den passenden Worten. Zieh einen Strich von Punkt zu Punkt.")
                 + f'      <div class="connect">{pairs}</div>\n')
        body += t(2, "Geld-Wörter-Suche", p("Finde 6 Wörter rund ums Geld. Sie stehen alle waagerecht: MUENZE (so schreibt man Münze ohne Pünktchen), SCHEIN, PREIS, CENT, EURO, TAUSCH.")
                  + wortsuche(["MUENZE", "SCHEIN", "PREIS", "CENT", "EURO", "TAUSCH"]))
        return lb_page("Rätsel", "Hafen-Rätsel", title, body)
    if slug == "tauschinsel":
        body = t(1, "Tausch-Rechnen", p("Bei Otti bekommst du <b>1 Fisch für 2 Äpfel</b>. Bei Greta bekommst du <b>1 Seil für 3 Fische</b>.")
                 + lb.line("Wie viele Äpfel brauchst du für 1 Seil?") + lb.line("Wie viele Äpfel für 2 Seile?"))
        body += t(2, "Basteln: Tauschkarten", p("Schneide 6 Kärtchen aus Papier. Mal auf jedes etwas, das du hast (ein Buch, ein Spielzeug, eine Murmel). Spielt dann in der Familie Tauschmarkt: Jeder darf nur tauschen, wenn beide zufrieden sind.")
                  + draw())
        return lb_page("Rätsel und Basteln", "Tausch-Werkstatt", title, body)
    if slug == "wunschinsel":
        body = t(1, "Werbe-Detektiv", p("Welche Sätze sind Werbe-Tricks? Kreuz sie an.")
                 + opts(["„Nur heute!“", "„Alle haben es!“", "„Gratis dazu!“", "„Hält ein ganzes Jahr.“", "„Kostet 3 Euro.“", "„Nur noch 2 Stück!“"]))
        body += t(2, "Basteln: Meine Wunschflasche", p("Mal eine Flasche auf ein Blatt und schneide sie aus. Schreib einen Wunsch und das Datum darauf und kleb sie an den Kühlschrank. Willst du ihn nach einer Woche noch?")
                  + table(["Mein Wunsch", "Datum", "Nach 1 Woche: noch wichtig?"], [["", "", ""], ["", "", ""]]))
        return lb_page("Rätsel und Basteln", "Wunsch-Werkstatt", title, body)
    if slug == "spar-insel":
        cells = "".join('<span class="therm"></span>' for _ in range(12))
        body = t(1, "Spar-Thermometer", p("Ein Fahrrad-Helm kostet <b>60 €</b>. Du legst jede Woche <b>5 €</b> zurück. Mal für jede Woche ein Kästchen aus.")
                 + f'      <div class="thermometer">{cells}</div>\n' + lb.line("Nach wie vielen Wochen hast du genug?"))
        body += t(2, "Basteln: Drei Spargläser", p("Nimm drei leere Gläser oder Dosen und kleb Etiketten darauf: <b>Wunsch</b>, <b>Notfall</b> und <b>Geplantes</b>. Wofür sparst du in welchem Glas?")
                  + table(["Glas", "Wofür?"], [["Wunsch", ""], ["Notfall", ""], ["Geplantes", ""]]))
        return lb_page("Rätsel und Basteln", "Spar-Werkstatt", title, body)
    body = t(1, "Taschengeld-Wörter", p("Finde 6 Wörter. Sie stehen alle waagerecht: PLAN, SPAREN, AUSGABE, LOGBUCH, BUDGET, EINNAHME.")
             + wortsuche(["PLAN", "SPAREN", "AUSGABE", "LOGBUCH", "BUDGET", "EINNAHME"]))
    body += t(2, "Wochen-Rätsel", p("Mia hat <b>10 Taler</b>. Sie kauft ein Heft für 3 Taler und ein Eis für 2 Taler. Die Hälfte vom Rest legt sie zurück.")
              + lb.line("Wie viele Taler legt Mia zurück?") + lb.line("Wie viele kann sie noch ausgeben?"))
    return lb_page("Rätsel", "Bucht-Rätsel", title, body)


def wortsuche(words, size=10):
    """Wörtersuche: jedes Wort waagerecht in einer eigenen Zeile, versetzt; Rest feste Buchstaben."""
    rows = [0, 2, 4, 6, 8, 9]
    grid = [["" for _ in range(size)] for _ in range(size)]
    for k, (r, w) in enumerate(zip(rows, words)):
        start = (k * 3) % (size - len(w) + 1)
        for i, ch in enumerate(w):
            grid[r][start + i] = ch
    filler = "AEMORNSTLIKUBEGPAD"
    n = 0
    for r in range(size):
        for c in range(size):
            if not grid[r][c]:
                grid[r][c] = filler[n % len(filler)]
                n += 5
    cells = "".join("<tr>" + "".join(f"<td>{ch}</td>" for ch in row) + "</tr>" for row in grid)
    return f'      <table class="grid wordsearch">{cells}</table>\n'


def lb_page(tag, heading, title, body):
    return section("", f'  <div class="head"><span class="tag">{tag}</span><h2>{heading}</h2></div>\n{body}', title)


SOLUTIONS = {
    "hafen": ("Hafen-Rätsel", ["2,05 € = zwei Euro und fünf Cent; 0,50 € = fünfzig Cent; 12,90 € = zwölf Euro und neunzig Cent; 1,99 € = ein Euro und neunundneunzig Cent.", "Wörtersuche: MÜNZE steht als MUENZE im Gitter."]),
    "tauschinsel": ("Tausch-Werkstatt", ["1 Seil = 3 Fische = 6 Äpfel. 2 Seile = 12 Äpfel.", "Beim Tauschmarkt gibt es kein Richtig oder Falsch. Fragen Sie: Warum war der Tausch für beide gut?"]),
    "wunschinsel": ("Wunsch-Werkstatt", ["Werbe-Tricks: „Nur heute!“, „Alle haben es!“, „Gratis dazu!“, „Nur noch 2 Stück!“. Keine Tricks: „Hält ein ganzes Jahr.“ und „Kostet 3 Euro.“ (das sind Infos, die man prüfen kann)."]),
    "spar-insel": ("Spar-Werkstatt", ["60 € : 5 € = 12 Wochen, also alle 12 Kästchen.", "Bei den Gläsern sind viele Antworten gut. Wichtig: Notfall heißt unerwartet (etwas geht kaputt), Geplantes steht schon fest (Geburtstag, Klassenfahrt)."]),
    "taschengeld-bucht": ("Bucht-Rätsel", ["10 − 3 − 2 = 5 Taler übrig. Die Hälfte davon: 2,50 Taler zurücklegen, 2,50 Taler kann Mia noch ausgeben (Einsteiger dürfen auch 2 und 3 sagen)."]),
}


def solutions_pages(collected):
    pages = []
    for i in range(0, len(collected), 1):
        boxes = ""
        for title, sol_html, extra_sol in collected[i:i + 1]:
            h, items = extra_sol
            boxes += f'  <h3 class="sol-island">{title}</h3>\n  <div class="cols">\n{sol_html}    <div class="box gold">\n      <h3>{h}</h3>\n      <ul>\n' + "".join(
                f"        <li>{x}</li>\n" for x in items) + "      </ul>\n    </div>\n  </div>\n"
        pages.append(section("parents solutions", f'  <div class="head"><span class="tag">Für Eltern</span><h2>Lösungen und Tipps</h2></div>\n{boxes}', "Lösungen"))
    return pages


# ---------------------------------------------------------------------------

def number_pages(html, anchors):
    """Seitenzahlen in Fußzeilen und Inhaltsverzeichnis setzen."""
    parts = html.split("Seite @@")
    out = parts[0]
    for n, rest in enumerate(parts[1:], start=2):
        out += f"Seite {n}" + rest
    for key, n in anchors.items():
        out = out.replace(f"@{key}@", str(n))
    return out


def main():
    (OUT / "bilder").mkdir(parents=True, exist_ok=True)
    islands = [(slug, json.loads((ROOT / "content" / "stufe1" / f).read_text(encoding="utf-8")), log, figs)
               for slug, f, log, figs in ISLANDS]
    chapters = [(slug, isl["titel"]) for slug, isl, _, _ in islands]

    sections = [cover(), parents_intro(), contents(chapters), sea_chart(chapters)]
    anchors = {"karte": 4}
    collected = []
    for n, (slug, isl, log, figs) in enumerate(islands, 1):
        title = isl["titel"]
        anchors[slug] = len(sections) + 1
        sections.append(opener(n, slug, isl))
        pages, sol = logbook_pages(log, title)
        cert = [s for s in pages if "certificate-page" in s]
        tasks = [s for s in pages if "certificate-page" not in s]
        sections += tasks
        sections.append(extra(slug, title))
        sections.append(coloring(slug, title, figs))
        sections.append(together(title, isl))
        sections += cert
        # Die Lösungen der Logbücher nennen deren Seiten (ab 2); im Buch folgen die Seiten auf den Kapitelanfang.
        first = anchors[slug] + 1
        sol = re.sub(r"<h3>Seite (\d+)</h3>", lambda m: f"<h3>Seite {first + int(m.group(1)) - 2}</h3>", sol)
        collected.append((title, sol, SOLUTIONS[slug]))
    anchors["loesungen"] = len(sections) + 1
    sections += solutions_pages(collected)

    html = head() + "".join(sections) + "</body>\n</html>\n"
    html = number_pages(html, anchors)
    (OUT / "schatzbuch_teil1.html").write_text(html, encoding="utf-8")
    print(f"schatzbuch/schatzbuch_teil1.html: {len(sections)} Seiten")


if __name__ == "__main__":
    main()
