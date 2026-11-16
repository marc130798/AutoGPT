"""Erstellt ein Bild mit Gemini (Bild-Modell) aus einem Text und Vorlagen-Bildern.

Der API-Schlüssel steht nicht hier: Er liegt als „Network secret“ in Marcs
Arbeitsumgebung, der Proxy hängt ihn an jede Anfrage an
generativelanguage.googleapis.com an (Header x-goog-api-key). Nie in Dateien schreiben.

Aufruf im Ordner taleria/:
  python3 tool/gemini_bild.py ZIEL.png "TEXT" [VORLAGE.jpg ...] [--modell NAME] [--format 1:1]
Beispiel:
  python3 tool/gemini_bild.py design/gemini/avatar.lion.png "$(cat prompt.txt)" design/gemini/character.talo.jpg

Kosten: Abgerechnet über Marcs Vorauszahlung in Google AI Studio (pro Bild wenige Cent).
"""

import argparse
import base64
import json
import mimetypes
import sys
import urllib.request
from pathlib import Path

URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("target")
    parser.add_argument("prompt")
    parser.add_argument("refs", nargs="*")
    parser.add_argument("--modell", default="gemini-3.1-flash-image")
    parser.add_argument("--format", default="1:1")
    args = parser.parse_args()

    parts = []
    for ref in args.refs:
        mime = mimetypes.guess_type(ref)[0] or "image/png"
        parts.append({"inline_data": {"mime_type": mime, "data": base64.b64encode(Path(ref).read_bytes()).decode()}})
    parts.append({"text": args.prompt})
    body = {
        "contents": [{"parts": parts}],
        "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": args.format}},
    }
    request = urllib.request.Request(
        URL.format(model=args.modell),
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            data = json.load(response)
    except urllib.error.HTTPError as error:
        sys.exit(f"Fehler {error.code}: {error.read().decode()[:500]}")
    for candidate in data.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            inline = part.get("inlineData") or part.get("inline_data")
            if inline:
                Path(args.target).parent.mkdir(parents=True, exist_ok=True)
                Path(args.target).write_bytes(base64.b64decode(inline["data"]))
                print(f"Gespeichert: {args.target}")
                return
    sys.exit("Kein Bild bekommen: " + json.dumps(data)[:800])


if __name__ == "__main__":
    main()
