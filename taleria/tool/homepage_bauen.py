#!/usr/bin/env python3
"""Baut die Webseite von Taleria (landingpage/*.html) aus einer Vorlage.

Aufruf im Ordner taleria/:
    python3 tool/homepage_bauen.py

Menü und Fußzeile stehen hier einmal und kommen auf jede Seite. Den Inhalt
jeder Seite liest das Werkzeug aus landingpage/seiten/<name>.html. Das
Aussehen steht in landingpage/site.css. Impressum und Datenschutz bekommen
nur Menü und Fußzeile, ihr Text bleibt, wie er ist.
"""
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), '..', 'landingpage')

# (Datei, Menüname, Titel im Browser, Beschreibung für Suchmaschinen)
SEITEN = [
    ('index', 'Start', 'Taleria – Geld verstehen, Abenteuer erleben',
     'Taleria ist eine Lern-App für Kinder von 8 bis 12 Jahren: Mit Talo und Tala segeln sie von Insel zu Insel '
     'und lernen spielerisch, wie Geld funktioniert. Ohne Werbung, ohne echtes Geld, Daten in der EU.'),
    ('warum-jetzt', 'Warum jetzt?', 'Warum Kinder jetzt den Umgang mit Geld lernen sollten · Taleria',
     'Geld wird unsichtbar, Kaufen geht mit einem Tipp, und in der Schule kommt das Thema kaum vor. '
     'Zahlen und Quellen, warum Finanzbildung früh beginnen sollte.'),
    ('so-funktionierts', "So funktioniert's", "So funktioniert Taleria · Taleria",
     'Stationen, Bildergeschichten, Tauchgänge, Spiele und Wiederholung: so lernt dein Kind mit Taleria.'),
    ('inseln', 'Inseln', 'Die Inseln von Taleria · Taleria',
     'Hafen, Tauschinsel, Wunschinsel, Spar-Insel und Taschengeld-Bucht: was dein Kind auf jeder Insel lernt.'),
    ('eltern', 'Für Eltern', 'Für Eltern: Leuchtturm, Sicherheit und Datenschutz · Taleria',
     'Im Leuchtturm siehst du, was dein Kind lernt. Kein echtes Geld, keine Werbung, keine Käufe durch Kinder, Daten in der EU.'),
    ('preise', 'Preise', 'Preise · Taleria',
     'Hafen und Tauschinsel sind kostenlos. Das Familien-Abo schaltet alle Inseln frei. In der Testphase ist alles kostenlos.'),
    ('fragen', 'Fragen', 'Fragen von Eltern · Taleria',
     'Antworten auf die häufigsten Fragen von Eltern zu Alter, Spielzeit, Datenschutz, Geräten und Kosten.'),
    ('testfamilien', 'Testfamilie werden', 'Testfamilie werden · Taleria',
     'Probiert Taleria vor allen anderen aus: kostenlos, mit allen Inseln, und eure Rückmeldung macht die App besser.'),
    ('danke', 'Danke', 'Danke für eure Anmeldung · Taleria', 'Eure Anmeldung als Testfamilie ist angekommen.'),
]

MENU = [s for s in SEITEN if s[0] not in ('testfamilien', 'danke')]


def nav(aktuell):
    links = []
    for datei, name, *_ in MENU:
        cur = ' aria-current="page"' if datei == aktuell else ''
        links.append(f'<a href="{datei}.html"{cur}>{name}</a>')
    cur = ' aria-current="page"' if aktuell == 'testfamilien' else ''
    links.append(f'<a class="cta" href="testfamilien.html"{cur}>Testfamilie werden</a>')
    return '\n      '.join(links)


def header(aktuell):
    n = nav(aktuell)
    return f'''<a class="sr" href="#inhalt">Zum Inhalt springen</a>
<header class="site-header">
  <div class="wrap bar">
    <a class="logo" href="index.html"><img src="bilder/brand.logo.png" alt="Taleria, zur Startseite" width="768" height="324"></a>
    <nav class="site-nav wide" aria-label="Hauptmenü">
      {n}
    </nav>
    <details class="menu">
      <summary aria-label="Menü öffnen">Menü</summary>
      <nav class="site-nav" aria-label="Hauptmenü">
      {n}
      </nav>
    </details>
  </div>
</header>'''


FOOTER = '''<footer class="site-footer">
  <div class="wrap cols">
    <div>
      <img src="bilder/brand.logo.png" alt="Taleria" width="768" height="324" style="height:44px;width:auto;margin-bottom:10px">
      <p>Die Lern-App rund ums Geld für Kinder von 8 bis 12 Jahren.</p>
    </div>
    <div>
      <h3>Taleria</h3>
      <ul>
        <li><a href="so-funktionierts.html">So funktioniert's</a></li>
        <li><a href="inseln.html">Die Inseln</a></li>
        <li><a href="warum-jetzt.html">Warum jetzt?</a></li>
      </ul>
    </div>
    <div>
      <h3>Für Eltern</h3>
      <ul>
        <li><a href="eltern.html">Leuchtturm und Sicherheit</a></li>
        <li><a href="preise.html">Preise</a></li>
        <li><a href="fragen.html">Fragen</a></li>
        <li><a href="testfamilien.html">Testfamilie werden</a></li>
      </ul>
    </div>
    <div>
      <h3>Rechtliches</h3>
      <ul>
        <li><a href="impressum.html">Impressum</a></li>
        <li><a href="datenschutz.html">Datenschutz</a></li>
      </ul>
    </div>
  </div>
  <div class="wrap legal">Taleria ist ein Lernspiel und keine Finanzberatung. Alle Beträge in der App sind virtuell. Wir empfehlen keine Banken, Produkte oder Geldanlagen.</div>
</footer>'''


def seite(datei, titel, beschreibung, inhalt):
    return f'''<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{titel}</title>
<meta name="description" content="{beschreibung}">
<meta property="og:title" content="{titel}">
<meta property="og:description" content="{beschreibung}">
<meta property="og:image" content="bilder/app.start.jpg">
<link rel="icon" href="bilder/brand.logo.png">
<link rel="stylesheet" href="site.css">
</head>
<body>
{header(datei)}
<main id="inhalt">
{inhalt.strip()}
</main>
{FOOTER}
</body>
</html>
'''


def rechtliches(datei):
    """Impressum und Datenschutz: Menü und Fußzeile austauschen, Text behalten."""
    pfad = os.path.join(ROOT, f'{datei}.html')
    html = open(pfad, encoding='utf-8').read()
    html = re.sub(r'<link rel="stylesheet" href="(site|rechtliches)\.css">\n?', '', html)
    html = html.replace('</head>', '<link rel="stylesheet" href="site.css">\n<link rel="stylesheet" href="rechtliches.css">\n</head>', 1)
    html = re.sub(r'(<a class="sr"[^\n]*\n)?<header.*?</header>', header(datei), html, count=1, flags=re.S)
    html = re.sub(r'<footer.*?</footer>', FOOTER, html, count=1, flags=re.S)
    open(pfad, 'w', encoding='utf-8').write(html)


def main():
    for datei, _, titel, beschreibung in SEITEN:
        inhalt = open(os.path.join(ROOT, 'seiten', f'{datei}.html'), encoding='utf-8').read()
        open(os.path.join(ROOT, f'{datei}.html'), 'w', encoding='utf-8').write(seite(datei, titel, beschreibung, inhalt))
        print('gebaut:', f'{datei}.html')
    for datei in ('impressum', 'datenschutz'):
        rechtliches(datei)
        print('Menü und Fußzeile:', f'{datei}.html')


if __name__ == '__main__':
    main()
