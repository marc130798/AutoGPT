"""Erstellt Masken für die Kleiderfarben von Löwe und Löwin.

Die blauen Teile von Shirt und Hose werden erkannt (Farbton Blau, genug
Sättigung) und als helle Graustufen-Maske gespeichert:
`avatar.<figur>[.<pose>].cloth.png`. Die App färbt die Maske mit der gewählten
Farbe ein (BlendMode.modulate) und legt sie über das Bild. Die weißen Streifen
bleiben weiß, weil sie nicht blau sind.

Aufruf im Ordner taleria/:
  python3 tool/kleider_masken.py            # alle Bilder avatar.lion*, avatar.lioness*
  python3 tool/kleider_masken.py --probe rosa  # Vorschau in Rosa in den Notizordner
"""

import argparse
import colorsys
import glob
import os

import numpy as np
from PIL import Image, ImageFilter

QUELLEN = sorted(
    f for f in glob.glob('assets/images/avatar.lion*.png') if not f.endswith('.cloth.png')
)


def maske(pfad: str) -> Image.Image:
    bild = Image.open(pfad).convert('RGBA')
    a = np.asarray(bild).astype(np.float32) / 255.0
    r, g, b, alpha = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    # Blau: b ist der größte Anteil, deutlich vor Rot, genug Farbe.
    # Blau-Anteil relativ zur Helligkeit, damit auch dunkles, glänzendes Blau
    # (Regenjacke) erkannt wird.
    vorsprung = (b - np.maximum(r, g)) / np.maximum(b, 1e-3)
    blau = (b >= g) & (vorsprung > 0.12) & ((sat > 0.14) | (mx < 0.45)) & (alpha > 0.5)
    staerke = np.clip(np.maximum((sat - 0.14) / 0.14, (vorsprung - 0.12) / 0.12), 0, 1) * blau
    # Glanzlichter auf blauem Stoff: hell und nur leicht bläulich. Weiße Streifen
    # sind fast neutral und bleiben weiß.
    glanz = (b >= g) & (vorsprung > 0.07) & (mx > 0.5) & (alpha > 0.5)
    staerke = np.maximum(staerke, np.clip((vorsprung - 0.07) / 0.06, 0, 1) * glanz)
    # Weiche Kante, damit der Übergang zu den weißen Streifen nicht ausfranst.
    m = Image.fromarray((staerke * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    staerke = np.asarray(m).astype(np.float32) / 255.0 * alpha
    # Helligkeit: dunkles Blau wird zu hellem Grau, damit Rosa und Grün nicht zu dunkel werden.
    hell = 0.299 * r + 0.587 * g + 0.114 * b
    grau = np.clip(0.42 + hell * 1.6, 0, 1)
    out = np.dstack([grau, grau, grau, staerke])
    return Image.fromarray((out * 255).astype(np.uint8), 'RGBA')


FARBEN = {
    'rosa': (0xF2, 0x8A, 0xB3), 'gruen': (0x4C, 0xB0, 0x6E), 'rot': (0xD8, 0x4A, 0x40),
    'lila': (0x9A, 0x6B, 0xC9), 'gelb': (0xF0, 0xBE, 0x3A), 'tuerkis': (0x2F, 0xB5, 0xB8),
}


def vorschau(pfad: str, m: Image.Image, farbe: str, ziel: str) -> None:
    bild = Image.open(pfad).convert('RGBA')
    t = np.asarray(m).astype(np.float32) / 255.0
    rgb = t[..., :3] * (np.array(FARBEN[farbe]) / 255.0)
    over = Image.fromarray((np.dstack([rgb, t[..., 3]]) * 255).astype(np.uint8), 'RGBA')
    bild.alpha_composite(over)
    bild.save(ziel)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--probe')
    parser.add_argument('--ordner', default='.')
    args = parser.parse_args()
    for pfad in QUELLEN:
        m = maske(pfad)
        if args.probe:
            name = os.path.basename(pfad).replace('.png', f'.{args.probe}.png')
            vorschau(pfad, m, args.probe, os.path.join(args.ordner, name))
        else:
            ziel = pfad.replace('.png', '.cloth.png')
            m.save(ziel, optimize=True)
            print(ziel, os.path.getsize(ziel) // 1024, 'KB')


if __name__ == '__main__':
    main()
