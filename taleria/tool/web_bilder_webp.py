"""Rechnet die Bilder der fertigen Web-Testversion ins WebP-Format um (nur im
Build-Ordner, die Originale in assets/images bleiben PNG und JPG).

Dateiname und Endung bleiben gleich, damit Asset-Manifest und Flutter nichts
merken: Flutter erkennt das Format am Inhalt der Datei, nicht an der Endung.
Durchsichtige Ränder bleiben verlustfrei. Spart etwa 8 MB, damit die ZIP-Datei
unter 30 MB bleibt (Stand 16.11.2026).

Aufruf (macht tool/build_test_web.sh selbst):
    python3 tool/web_bilder_webp.py build/web_test/assets/assets/images
"""
import glob
import io
import os
import sys

from PIL import Image

ordner = sys.argv[1]
vorher = nachher = 0
for datei in sorted(glob.glob(os.path.join(ordner, '*.png')) + glob.glob(os.path.join(ordner, '*.jpg'))):
    bild = Image.open(datei)
    bild = bild.convert('RGBA') if bild.mode in ('RGBA', 'P', 'LA') else bild.convert('RGB')
    puffer = io.BytesIO()
    bild.save(puffer, 'WEBP', quality=82, method=6)
    alt = os.path.getsize(datei)
    vorher += alt
    if len(puffer.getvalue()) < alt * 0.9:
        open(datei, 'wb').write(puffer.getvalue())
        nachher += len(puffer.getvalue())
    else:
        nachher += alt
print(f'Bilder als WebP: {vorher / 1e6:.1f} MB -> {nachher / 1e6:.1f} MB')
