"""Nimmt die Sätze von Talo, Tala und Meister Taleron mit Marcs ElevenLabs-Stimmen auf.

Quellen:
- Erklärungen der Stationen direkt aus content/stufe1/*.json (Feld „erklaerung“),
  Datei voice.<insel>.<station>.<n>.mp3. So passt der gesprochene Satz immer genau
  zum Text in der App.
- Die „Momente“ (Jubel, Trost, Begrüßung, Taleron …) aus design/sprachaufnahmen.md.

Der API-Schlüssel steht nicht hier, sondern als „Network secret“ in Marcs
Arbeitsumgebung (Header xi-api-key für api.elevenlabs.io).

WICHTIG (Lizenz): Nur Aufnahmen aus einem bezahlten ElevenLabs-Abo dürfen in der
verkauften App genutzt werden, auch nach einer Kündigung. Jede Aufnahme steht mit
Datum und Plan in assets/audio/voice/stimmen.json.

Aufruf im Ordner taleria/:
  python3 tool/stimmen_aufnehmen.py              # alles, was fehlt oder sich geändert hat
  python3 tool/stimmen_aufnehmen.py --nur hafen  # nur Dateien, deren Name das enthält
  python3 tool/stimmen_aufnehmen.py --liste      # nur zählen, nichts aufnehmen
"""

import argparse
import datetime
import json
import re
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "audio" / "voice"
INDEX = OUT / "stimmen.json"
VOICES = {
    "talo": "50ziM9y8Nnahpd5X0J82",
    "tala": "GtGbvM5PvWwzWI8rtTKT",
    "taleron": "DrEioZtDeKuQuCiimPiq",
}
MODEL = "eleven_multilingual_v2"
# Sprache braucht keine Musik-Qualität: 32 kbit/s halten die Web-App klein.
FORMAT = "mp3_44100_32"
ISLANDS = ["01-hafen", "02-tauschinsel", "03-wunschinsel", "04-spar-insel"]

# Momente, deren Text sich seit der Liste geändert hat (jetzt wie in der App).
OVERRIDES = {
    "voice.tala.treasure.mp3": "Das ist deine Schatztruhe! Freies Geld darfst du ausgeben. Für Wunschschätze legst du etwas zurück.",
    "voice.tala.shipyard.mp3": "Willkommen in der Werft! Hier kann man nichts kaufen. Mit deinen Seemeilen wird nach und nach Neues frei.",
}


def lines() -> list[tuple[str, str, str]]:
    out = []
    for name in ISLANDS:
        data = json.loads((ROOT / "content" / "stufe1" / f"{name}.json").read_text(encoding="utf-8"))
        for station in data.get("stationen", []):
            for i, line in enumerate(station.get("erklaerung") or [], start=1):
                if line.get("wer") in VOICES:
                    out.append((f"voice.{data['slug']}.{station['nr']}.{i}.mp3", line["wer"], line["text"]))
    md = (ROOT / "design" / "sprachaufnahmen.md").read_text(encoding="utf-8")
    for file, who, text in re.findall(r"^\| \d+ \| `(voice\.[^`]+)` \| (\w+) \| (.+?) \|$", md, re.M):
        out.append((file, who.lower(), OVERRIDES.get(file, text)))
    return out


# Aussprache: So schreibt das Werkzeug Wörter für ElevenLabs, damit die Betonung
# stimmt. Die Texte in der App bleiben unverändert. „Taleria“ wird auf dem e
# betont (Marc, 16.11.2026: Variante A, vorher klang es wie „Tale-RI-a“).
AUSSPRACHE = {"Taleria": "Taléria"}


def spoken(text: str) -> str:
    for word, sound in AUSSPRACHE.items():
        text = re.sub(rf"\b{word}\b", sound, text)
    return text


def record(file: str, who: str, text: str) -> str:
    body = json.dumps({"text": spoken(text), "model_id": MODEL}).encode()
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICES[who]}?output_format={FORMAT}"
    request = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                (OUT / file).write_bytes(response.read())
            return file
        except urllib.error.HTTPError as error:
            if error.code == 429 and attempt < 3:
                import time

                time.sleep(3 * (attempt + 1))
                continue
            raise RuntimeError(f"{file}: Fehler {error.code} {error.read()[:200]!r}") from error
    return file


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--nur", default="")
    parser.add_argument("--liste", action="store_true")
    parser.add_argument("--plan", default="starter")
    args = parser.parse_args()
    index = json.loads(INDEX.read_text(encoding="utf-8")) if INDEX.exists() else {}
    todo = [
        (f, w, t)
        for f, w, t in lines()
        if args.nur in f and (index.get(f, {}).get("text") != t or not (OUT / f).exists())
    ]
    chars = sum(len(t) for _, _, t in todo)
    print(f"{len(todo)} Sätze aufzunehmen, {chars} Zeichen")
    if args.liste or not todo:
        return
    today = datetime.date.today().isoformat()
    with ThreadPoolExecutor(3) as pool:
        for (file, who, text), result in zip(todo, pool.map(lambda x: record(*x), todo)):
            index[result] = {"wer": who, "text": text, "datum": today, "plan": args.plan, "modell": MODEL}
            print("gespeichert:", result, flush=True)
    INDEX.write_text(json.dumps(dict(sorted(index.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
