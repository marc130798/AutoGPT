#!/usr/bin/env python3
"""Stellt die Bilder aus BILDER.md frei und legt sie für die App ab.

Aufruf im Ordner taleria/ (braucht Python 3 mit Pillow und numpy):

    python3 tool/bilder_freistellen.py --art insel  bild.jpg map.island.hafen
    python3 tool/bilder_freistellen.py --art schiff bild.jpg ship.crew
    python3 tool/bilder_freistellen.py --art wolke  bild.jpg map.cloud.1
    python3 tool/bilder_freistellen.py --art meer   bild.jpg map.background
    python3 tool/bilder_freistellen.py --art figur  bild.jpg character.talo
    python3 tool/bilder_freistellen.py --art gegenstand  bild.jpg icon.treasure
    python3 tool/bilder_freistellen.py --art hintergrund bild.jpg home.background

- insel, schiff, figur, gegenstand: einfarbiger (pinker oder grüner) Hintergrund wird durchsichtig. Nur Fläche,
  die mit dem Bildrand verbunden ist, damit pinke Dinge auf der Insel bleiben.
  Weicher Rand, pinker Farbsaum wird herausgerechnet.
  figur und gegenstand: auch eingeschlossene Lücken und Schatten am Boden werden
  durchsichtig. figur: der Farbschimmer wird auf der ganzen Figur herausgerechnet.
- wolke: weiß auf schwarz, die Helligkeit wird zur Deckkraft.
- hintergrund: ganzes Bild (zum Beispiel für die Startseite), nur verkleinert, als JPG.
- meer: wird mit seinem Spiegelbild zu einer Kachel, die man nahtlos
  untereinander setzen kann (JPG, damit die Datei klein bleibt).

Danach den Eintrag in ASSETS_LICENSES.md nicht vergessen.
"""

import argparse
import os
import sys

import numpy as np
from PIL import Image

OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'images')

# Breite in Pixeln für die App (etwa dreifache Anzeigegröße auf dem Handy).
MAX_WIDTH = {'insel': 768, 'schiff': 512, 'figur': 512, 'gegenstand': 384, 'wolke': 640, 'meer': 768, 'hintergrund': 900}


def border_connected(mask, seeds=None):
    """Teil von mask, der über Nachbarpixel mit dem Bildrand (oder mit seeds)
    verbunden ist."""
    reached = np.zeros_like(mask) if seeds is None else (seeds & mask)
    reached[0, :] |= mask[0, :]
    reached[-1, :] |= mask[-1, :]
    reached[:, 0] |= mask[:, 0]
    reached[:, -1] |= mask[:, -1]
    while True:
        grown = reached.copy()
        grown[1:, :] |= reached[:-1, :]
        grown[:-1, :] |= reached[1:, :]
        grown[:, 1:] |= reached[:, :-1]
        grown[:, :-1] |= reached[:, 1:]
        grown &= mask
        if np.array_equal(grown, reached):
            return reached
        reached = grown


def key_out_background(rgb, low=40.0, high=110.0, figure=False, loose=False):
    """Einfarbigen Hintergrund durchsichtig machen. Liefert RGBA (float 0..255).

    figure: für Figuren mit Fell. Dort wirft der Hintergrund Farbe auf die
    ganze Figur, das wird überall herausgerechnet.
    loose: für Figuren und lose Gegenstände. Dunklere Lücken (zwischen Arm
    und Kopf, zwischen Seetang und Münze) und Schatten am Boden werden
    durchsichtig, der Rand wird ein wenig nach innen gezogen."""
    loose = loose or figure
    h, w, _ = rgb.shape
    border = np.concatenate([rgb[0, :], rgb[-1, :], rgb[:, 0], rgb[:, -1]])
    background = np.median(border, axis=0)
    distance = np.sqrt(((rgb - background) ** 2).sum(axis=2))
    # Vom Rand aus, dazu eingeschlossene Lücken in reiner Hintergrundfarbe
    # (zum Beispiel zwischen den Balken eines Turms). Pinke Dinge auf der Insel
    # sind nie so nah an der Hintergrundfarbe und bleiben.
    # Wie weit ein Pixel von einem bloß dunkleren (oder helleren) Hintergrund
    # entfernt ist. Klein bei Schatten und Lücken, groß bei echten Farben.
    k = (rgb @ background) / (background @ background)
    residual = np.sqrt(((rgb - k[..., None] * background) ** 2).sum(axis=2))
    seeds = distance < 35
    if loose:
        # Auch dunklere Lücken, zum Beispiel zwischen Arm und Kopf.
        seeds |= (residual < 20) & (distance < high)
    region = border_connected(distance < high, seeds=seeds)
    alpha = np.ones((h, w))
    alpha[region] = np.clip((distance[region] - low) / (high - low), 0, 1)
    if loose:
        # Helle, zarte Farben (Creme, Rosa) liegen bei blasserem Pink nah am
        # Hintergrund. Was aber keine bloß hellere oder dunklere Hintergrundfarbe
        # ist, bleibt deckend.
        alpha[region] = np.maximum(alpha[region], np.clip((residual[region] - 15) / 45, 0, 1))
        # Schatten auf dem Boden (nur dunkleres Pink oder Grün): ganz weg, damit
        # die Figur nicht auf einem grauen Fleck steht.
        alpha[region & (residual < 24)] = 0

    # Farbe ohne Hintergrund: Pixel = a * Vordergrund + (1 - a) * Hintergrund.
    a = alpha[..., None]
    safe = np.maximum(a, 1e-3)
    foreground = np.clip((rgb - (1 - a) * background) / safe, 0, 255)
    # Fast durchsichtige Pixel (Schatten, Rand) ohne Farbstich: Richtung Grau.
    gray = foreground.mean(axis=2, keepdims=True)
    toward_gray = np.clip(1 - a / 0.6, 0, 1)
    foreground = foreground * (1 - toward_gray) + gray * toward_gray

    # Farbschimmer, den der Hintergrund auf Sand, Holz oder Fell am Rand wirft:
    # in einem Streifen am Rand den Anteil der Hintergrundfarbe herausnehmen.
    near_edge = np.ones((h, w)) if figure else grow(alpha < 0.5, 24)
    r, g, b = foreground[..., 0], foreground[..., 1], foreground[..., 2]
    if background[1] > max(background[0], background[2]):
        # grüner Hintergrund (zum Beispiel bei der rosa Tala)
        green = np.clip(g - np.maximum(r, b), 0, None) * near_edge
        if loose:
            # Direkt am Rand wirft der grüne Grund helles Licht aufs Fell, das
            # sonst gelblich bleibt: dort Grün höchstens wie der Mittelwert.
            rim = grow(alpha < 0.5, round(max(h, w) / 128))
            green = np.maximum(green, np.clip(g - (r + b) / 2, 0, None) * rim)
        foreground[..., 1] = g - green
    else:
        # pinker Hintergrund
        magenta = np.clip(np.minimum(r, b) - g, 0, None) * near_edge
        foreground[..., 2] = b - magenta
        # Bei Figuren auch Rot ganz herausnehmen, sonst bleiben Weiß und Fell rosa.
        foreground[..., 0] = r - magenta * (1.0 if figure else 0.35)
    # Feiner Saum aus Hintergrundfarbe am Rand (bei Fell und Haaren): Rand ein
    # wenig nach innen ziehen (bei 1024 Pixeln drei Pixel). Die Farben bleiben.
    choke = round(max(h, w) / 400) if loose else 0
    for _ in range(choke):
        shrunk = alpha.copy()
        shrunk[1:, :] = np.minimum(shrunk[1:, :], alpha[:-1, :])
        shrunk[:-1, :] = np.minimum(shrunk[:-1, :], alpha[1:, :])
        shrunk[:, 1:] = np.minimum(shrunk[:, 1:], alpha[:, :-1])
        shrunk[:, :-1] = np.minimum(shrunk[:, :-1], alpha[:, 1:])
        alpha = shrunk
    return np.dstack([foreground, alpha * 255])


def grow(mask, steps):
    """Maske um steps Pixel in alle Richtungen erweitern."""
    grown = mask.copy()
    for _ in range(steps):
        step = grown.copy()
        step[1:, :] |= grown[:-1, :]
        step[:-1, :] |= grown[1:, :]
        step[:, 1:] |= grown[:, :-1]
        step[:, :-1] |= grown[:, 1:]
        grown = step
    return grown


def light_to_alpha(rgb):
    """Weiße Wolke auf Schwarz: Helligkeit wird Deckkraft.

    Farbstiche (zum Beispiel ein goldener Lichtschein am Rand) werden fast
    ganz zu Weiß, damit die Wolken über dem Meer neutral wirken."""
    brightness = rgb.max(axis=2)
    alpha = np.clip((brightness - 28) / 210, 0, 1) ** 0.9
    safe = np.maximum(alpha[..., None], 1e-3)
    foreground = np.clip(rgb / safe, 0, 255)
    gray = foreground.mean(axis=2, keepdims=True)
    foreground = foreground * 0.25 + gray * 0.75
    return np.dstack([foreground, alpha * 255])


def flatten_light(rgb):
    """Gleicht großflächige Helligkeit aus (zum Beispiel Sonnenglanz in einer
    Ecke), die Wellen bleiben. So wiederholt sich das Meer ohne helle Flecken."""
    image = Image.fromarray(rgb.astype(np.uint8), 'RGB')
    small = image.resize((8, 14), Image.BILINEAR).resize(image.size, Image.BICUBIC)
    low = np.asarray(small, dtype=np.float64)
    mean = rgb.reshape(-1, 3).mean(axis=0)
    return np.clip(rgb * (mean / np.maximum(low, 1)), 0, 255)


def crop_to_content(rgba, margin=6):
    alpha = rgba[..., 3]
    rows = np.where(alpha.max(axis=1) > 6)[0]
    cols = np.where(alpha.max(axis=0) > 6)[0]
    if len(rows) == 0 or len(cols) == 0:
        sys.exit('Abbruch: Im Bild ist nach dem Freistellen nichts übrig.')
    top = max(0, rows[0] - margin)
    bottom = min(rgba.shape[0], rows[-1] + 1 + margin)
    left = max(0, cols[0] - margin)
    right = min(rgba.shape[1], cols[-1] + 1 + margin)
    return rgba[top:bottom, left:right]


def shrink(image, max_width):
    if image.width <= max_width:
        return image
    height = round(image.height * max_width / image.width)
    return image.resize((max_width, height), Image.LANCZOS)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--art', required=True, choices=sorted(MAX_WIDTH))
    parser.add_argument('quelle', help='Bild von Gemini (JPG oder PNG)')
    parser.add_argument('schluessel', help='Asset-Schlüssel, z. B. map.island.hafen')
    args = parser.parse_args()

    rgb = np.asarray(Image.open(args.quelle).convert('RGB'), dtype=np.float64)
    os.makedirs(OUT_DIR, exist_ok=True)

    if args.art == 'hintergrund':
        image = shrink(Image.fromarray(rgb.astype(np.uint8), 'RGB'), MAX_WIDTH['hintergrund'])
        target = os.path.join(OUT_DIR, args.schluessel + '.jpg')
        image.save(target, quality=84, optimize=True)
    elif args.art == 'meer':
        flat = flatten_light(rgb)
        tile = np.concatenate([flat, flat[::-1]], axis=0)
        image = shrink(Image.fromarray(tile.astype(np.uint8), 'RGB'), MAX_WIDTH['meer'])
        target = os.path.join(OUT_DIR, args.schluessel + '.jpg')
        image.save(target, quality=82, optimize=True)
    else:
        if args.art == 'wolke':
            rgba = light_to_alpha(rgb)
        else:
            rgba = key_out_background(rgb, figure=args.art == 'figur', loose=args.art == 'gegenstand')
        rgba = crop_to_content(rgba)
        image = shrink(Image.fromarray(np.round(rgba).astype(np.uint8), 'RGBA'), MAX_WIDTH[args.art])
        target = os.path.join(OUT_DIR, args.schluessel + '.png')
        image.save(target, optimize=True)

    size_kb = os.path.getsize(target) / 1024
    print(f'{os.path.normpath(target)}: {image.width} × {image.height} Pixel, {size_kb:.0f} KB')


if __name__ == '__main__':
    main()
