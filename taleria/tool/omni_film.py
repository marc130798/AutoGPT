"""Kurzer Film (3 bis 15 Sekunden) aus einem Startbild mit Gemini Omni Flash.

Der API-Schlüssel steht nicht hier: Er liegt als „Network secret“ in Marcs
Arbeitsumgebung (Header x-goog-api-key für generativelanguage.googleapis.com).

Aufruf im Ordner taleria/:
  python3 tool/omni_film.py STARTBILD.png ZIEL.mp4 "BEWEGUNG" [--sekunden 8] [--aufloesung 720p]

Kosten: Abrechnung über Marcs Vorauszahlung in Google AI Studio (Berichte
nennen etwa 0,07 bis 0,10 $ pro Sekunde, Stand November 2026).
Der Ton des Films wird später ersetzt (Marcs Stimmen und Klänge,
tool/film_vertonen.py), darum soll niemand im Film sprechen.
"""

import argparse
import base64
import io
import json
import time
import urllib.request

from PIL import Image

API = 'https://generativelanguage.googleapis.com/v1beta'
HEADERS = {'Content-Type': 'application/json', 'x-goog-api-key': 'vom-proxy'}


def _request(url, body=None, timeout=900):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, headers=HEADERS, method='POST' if body is not None else 'GET')
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def _image(path):
    image = Image.open(path).convert('RGB')
    buf = io.BytesIO()
    image.save(buf, format='JPEG', quality=90)
    return base64.b64encode(buf.getvalue()).decode()


def _find_video(node):
    """Sucht im Ergebnis den Teil mit type=video (inline `data` oder `uri`)."""
    if isinstance(node, dict):
        if node.get('type') == 'video' and ('data' in node or 'uri' in node):
            return node
        for v in node.values():
            found = _find_video(v)
            if found:
                return found
    elif isinstance(node, list):
        for v in node:
            found = _find_video(v)
            if found:
                return found
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('start')
    ap.add_argument('ziel')
    ap.add_argument('text')
    ap.add_argument('--sekunden', type=int, default=8)
    ap.add_argument('--aufloesung', default='720p')
    ap.add_argument('--format', default='9:16')
    ap.add_argument('--modell', default='gemini-omni-1.2-flash')
    a = ap.parse_args()

    body = {
        'model': a.modell,
        'input': [
            {'type': 'image', 'data': _image(a.start), 'mime_type': 'image/jpeg'},
            {'type': 'text', 'text': a.text},
        ],
        'response_format': {
            'type': 'video',
            'aspect_ratio': a.format,
            'duration': f'{a.sekunden}s',
            'resolution': a.aufloesung,
        },
    }
    started = time.time()
    try:
        raw = _request(f'{API}/interactions', body)
    except urllib.error.HTTPError as e:
        raise SystemExit(f'Fehler {e.code}: {e.read()[:1500].decode(errors="replace")}')
    result = json.loads(raw)
    video = _find_video(result)
    # Läuft es noch im Hintergrund, nachfragen, bis das Video da ist.
    while video is None and result.get('id') and result.get('status') not in ('completed', 'failed', 'cancelled'):
        time.sleep(10)
        result = json.loads(_request(f'{API}/interactions/{result["id"]}'))
        video = _find_video(result)
    if video is None:
        print(json.dumps(result, indent=1)[:3000])
        raise SystemExit('Kein Video im Ergebnis.')
    if 'data' in video:
        open(a.ziel, 'wb').write(base64.b64decode(video['data']))
    else:
        file_id = video['uri'].rstrip('/').split('/')[-1].split(':')[0]
        open(a.ziel, 'wb').write(_request(f'{API}/files/{file_id}:download?alt=media'))
    usage = result.get('usage') or result.get('usage_metadata')
    print(f'Gespeichert: {a.ziel} ({time.time() - started:.0f} s)', usage or '')


if __name__ == '__main__':
    main()
