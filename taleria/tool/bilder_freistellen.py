#!/usr/bin/env python3
"""Stellt die Bilder aus BILDER.md frei und legt sie für die App ab.

Aufruf im Ordner taleria/ (braucht Python 3 mit Pillow und numpy):

    python3 tool/bilder_freistellen.py --art insel  bild.jpg map.island.hafen
    python3 tool/bilder_freistellen.py --art schiff bild.jpg ship.crew
    python3 tool/bilder_freistellen.py --art wolke  bild.jpg map.cloud.1
    python3 tool/bilder_freistellen.py --art meer   bild.jpg map.background

- insel, schiff: einfarbiger (pinker) Hintergrund wird durchsichtig. Nur Fläche,
  die mit dem Bildrand verbunden ist, damit pinke Dinge auf der Insel bleiben.
  Weicher Rand, pinker Farbsaum wird herausgerechnet.
- wolke: weiß auf schwarz, die Helligkeit wird zur Deckkraft.
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
MAX_WIDTH = {'insel': 768, 'schiff': 512, 'wolke': 640, 'meer': 768}


def border_connected(mask):
    """Teil von mask, der über Nachbarpixel mit dem Bildrand verbunden ist."""
    reached = np.zeros_like(mask)
    reached[0, :] = mask[0, :]
    reached[-1, :] = mask[-1, :]
    reached[:, 0] = mask[:, 0]
    reached[:, -1] = mask[:, -1]
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


def key_out_background(rgb, low=40.0, high=110.0):
    """Einfarbigen Hintergrund durchsichtig machen. Liefert RGBA (float 0..255)."""
    h, w, _ = rgb.shape
    border = np.concatenate([rgb[0, :], rgb[-1, :], rgb[:, 0], rgb[:, -1]])
    background = np.median(border, axis=0)
    distance = np.sqrt(((rgb - background) ** 2).sum(axis=2))
    region = border_connected(distance < high)
    alpha = np.ones((h, w))
    alpha[region] = np.clip((distance[region] - low) / (high - low), 0, 1)

    # Farbe ohne Hintergrund: Pixel = a * Vordergrund + (1 - a) * Hintergrund.
    a = alpha[..., None]
    safe = np.maximum(a, 1e-3)
    foreground = np.clip((rgb - (1 - a) * background) / safe, 0, 255)
    # Fast durchsichtige Pixel (Schatten, Rand) ohne Farbstich: Richtung Grau.
    gray = foreground.mean(axis=2, keepdims=True)
    toward_gray = np.clip(1 - a / 0.6, 0, 1)
    foreground = foreground * (1 - toward_gray) + gray * toward_gray
    return np.dstack([foreground, alpha * 255])


def light_to_alpha(rgb):
    """Weiße Wolke auf Schwarz: Helligkeit wird Deckkraft."""
    brightness = rgb.max(axis=2)
    alpha = np.clip((brightness - 10) / 230, 0, 1) ** 0.9
    safe = np.maximum(alpha[..., None], 1e-3)
    foreground = np.clip(rgb / safe, 0, 255)
    return np.dstack([foreground, alpha * 255])


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

    if args.art == 'meer':
        tile = np.concatenate([rgb, rgb[::-1]], axis=0)
        image = shrink(Image.fromarray(tile.astype(np.uint8), 'RGB'), MAX_WIDTH['meer'])
        target = os.path.join(OUT_DIR, args.schluessel + '.jpg')
        image.save(target, quality=82, optimize=True)
    else:
        rgba = light_to_alpha(rgb) if args.art == 'wolke' else key_out_background(rgb)
        rgba = crop_to_content(rgba)
        image = shrink(Image.fromarray(np.round(rgba).astype(np.uint8), 'RGBA'), MAX_WIDTH[args.art])
        target = os.path.join(OUT_DIR, args.schluessel + '.png')
        image.save(target, optimize=True)

    size_kb = os.path.getsize(target) / 1024
    print(f'{os.path.normpath(target)}: {image.width} × {image.height} Pixel, {size_kb:.0f} KB')


if __name__ == '__main__':
    main()
