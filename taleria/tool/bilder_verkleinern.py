"""Verkleinert große PNG-Bilder in assets/images/ verlustarm (Farbpalette mit
256 Farben, wie pngquant), damit die Web-Testversion unter 30 MB bleibt.
Figuren, Inseln und Abzeichen sehen danach praktisch gleich aus, sind aber
etwa viermal kleiner. Durchsichtige Ränder bleiben erhalten.

Braucht das Paket imagequant (pip install imagequant).

Aufruf im Ordner taleria/:
    python3 tool/bilder_verkleinern.py            # alle PNG über 100 KB
    python3 tool/bilder_verkleinern.py datei.png  # nur bestimmte Dateien
"""

import glob
import os
import sys

import imagequant
from PIL import Image

GRENZE = 100_000

dateien = sys.argv[1:] or [f for f in sorted(glob.glob('assets/images/*.png')) if os.path.getsize(f) > GRENZE]
vorher = nachher = 0
for datei in dateien:
    bild = Image.open(datei).convert('RGBA')
    klein = imagequant.quantize_pil_image(bild, dithering_level=1.0, max_colors=256, min_quality=0, max_quality=100)
    alt = os.path.getsize(datei)
    ziel = datei + '.neu'
    klein.save(ziel, format='PNG', optimize=True)
    neu = os.path.getsize(ziel)
    if neu < alt:
        os.replace(ziel, datei)
    else:
        os.remove(ziel)
        neu = alt
    vorher += alt
    nachher += neu
    print(f'{datei}: {alt // 1024} KB -> {neu // 1024} KB')
print(f'Zusammen: {vorher // 1024} KB -> {nachher // 1024} KB')
