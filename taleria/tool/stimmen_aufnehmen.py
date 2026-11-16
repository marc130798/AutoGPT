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
    # Inselbewohner (Marc hat am 16.11.2026 aus je 3 Proben gewählt, dauerhaft
    # in seinem Konto gespeichert mit tool/stimme_entwerfen.py).
    "olga": "dplDM4GRTbPZEcekle86",
    "bruno": "lM1QWXiTjt6Kx8EWVF7X",
    "greta": "sch5SA569oWkXDPtDkXT",
    "otti": "N8mipeQcK5GhXSiRPieg",
    "elsa": "8giTRiS5FxN6KhDPSpAb",
    "emma": "r3c2R2ZpQNEy4OuOxyM2",
    "gustav": "xlsHIYy4lTH1hgpTECvs",
    # Nebenrollen: feste Standard-Stimmen von ElevenLabs („premade“, belegen
    # keinen Platz im Abo), Marcs Wahl am 16.11.2026.
    "haendler": "pqHfZKP75CvOlQylNhV4",  # Bill
    "verkaeuferin": "cgSgspJ2msm6clMCkdW9",  # Jessica
    "bootsbauer": "bIHbv24MWmeRgasZH58o",  # Will
    "moritz": "N2lVS1w4EtoT3dr4eOWO",  # Callum
}
MODEL = "eleven_multilingual_v2"
# Sprache braucht keine Musik-Qualität: 32 kbit/s halten die Web-App klein.
FORMAT = "mp3_44100_32"
# Langsamer sprechen (Marc, 16.11.2026: „die sind alle zu schnell“, Probe B
# gewählt). Ändert sich etwas hier, nimmt das Werkzeug alles neu auf.
SETTINGS = {"speed": 0.87, "stability": 0.5, "similarity_boost": 0.75}
ISLANDS = ["01-hafen", "02-tauschinsel", "03-wunschinsel", "04-spar-insel"]

# Momente, deren Text sich seit der Liste geändert hat (jetzt wie in der App).
OVERRIDES = {
    "voice.tala.treasure.mp3": "Das ist deine Schatztruhe! Freies Geld darfst du ausgeben. Für Wunschschätze legst du etwas zurück.",
    "voice.tala.shipyard.mp3": "Willkommen in der Werft! Hier kann man nichts kaufen. Mit deinen Seemeilen wird nach und nach Neues frei.",
}


# Sätze aus app_de.arb, die im Intro und im Rundgang gesprochen werden (wer).
APP_LINES = {
    "introStoryTalo1": "talo",
    "introStoryTala1": "tala",
    "introStoryTalo2": "talo",
    "introStoryTala2": "tala",
    "introStoryTalo3": "talo",
    "rankFormQuestion": "tala",
    "shipBody": "tala",
    "wishBody": "tala",
    "tourMapBody": "talo",
    "tourRankBody": "talo",
    "tourChestBody": "tala",
    "tourTasksBody": "tala",
    "tourBadgesBody": "talo",
    "tourCollectionBody": "tala",
    "tourLighthouseBody": "talo",
}


def lines() -> list[tuple[str, str, str]]:
    """Alle Sätze mit Dateinamen. Die App spielt sie unter denselben Namen ab:
    Erklärung `voice.<insel>.<nr>.<i>`, Szene `voice.<insel>.<nr>.szene.<i>`,
    Stopp auf See `voice.<insel>.stopp<k>.szene.<i>` und `.abschluss`,
    Ankunft `voice.<insel>.ankunft.<i>`, Ausblick `voice.<insel>.ausblick.<i>`
    (i zählt alle Zeilen ab 1, auch die ohne Stimme)."""
    out = []

    def add(prefix, rows):
        for i, line in enumerate(rows or [], start=1):
            if line.get("wer") in VOICES:
                out.append((f"{prefix}{i}.mp3", line["wer"], line["text"]))

    for name in ISLANDS:
        data = json.loads((ROOT / "content" / "stufe1" / f"{name}.json").read_text(encoding="utf-8"))
        slug = data["slug"]
        for station in data.get("stationen", []):
            add(f"voice.{slug}.{station['nr']}.", station.get("erklaerung"))
            add(f"voice.{slug}.{station['nr']}.szene.", station.get("szene"))
        add(f"voice.{slug}.ankunft.", (data.get("ankunft") or {}).get("szene"))
        add(f"voice.{slug}.ausblick.", data.get("ausblick"))
        for k, stop in enumerate(data.get("stopps_auf_see") or [], start=1):
            add(f"voice.{slug}.stopp{k}.szene.", stop.get("szene"))
            end = stop.get("abschluss")
            if end and end.get("wer") in VOICES:
                out.append((f"voice.{slug}.stopp{k}.abschluss.mp3", end["wer"], end["text"]))
        for station in data.get("stationen", []):
            base = f"voice.{slug}.{station['nr']}."
            guess = station.get("schaetzfrage")
            if guess and guess.get("wer") in VOICES:
                out.append((f"{base}schaetzfrage.mp3", guess["wer"], guess["frage"]))
            reveal = (guess or {}).get("aufloesung")
            if isinstance(reveal, dict) and reveal.get("wer") in VOICES:
                out.append((f"{base}aufloesung.mp3", reveal["wer"], reveal["text"]))
            end = station.get("abschluss")
            if isinstance(end, dict) and end.get("wer") in VOICES:
                out.append((f"{base}abschluss.mp3", end["wer"], end["text"]))
            # „Mach mit!“ liest immer Tala (Marc, 16.11.2026).
            for k, tap in enumerate(station.get("antippen") or [], start=1):
                out.append((f"{base}mitmachen.{k}.mp3", "tala", tap["text"]))
                after = tap.get("danach") or tap.get("rueckseite")
                if after:
                    out.append((f"{base}mitmachen.{k}.danach.mp3", "tala", after))

    # Meister Taleron und andere Begegnungen auf See.
    encounters = json.loads((ROOT / "content" / "begegnungen.json").read_text(encoding="utf-8"))
    for enc in encounters["begegnungen"]:
        base = f"voice.begegnung.{enc['slug']}."
        add(f"{base}erste.", enc.get("erste_begegnung"))
        add(f"{base}szene.", enc.get("szene"))
        for part in ("richtig", "falsch", "geschafft"):
            line = enc.get(part)
            if isinstance(line, dict) and line.get("wer") in VOICES:
                out.append((f"{base}{part}.mp3", line["wer"], line["text"]))

    # Texte der App: Geschichte im Intro und der Rundgang „Was ist wo?“.
    arb = json.loads((ROOT / "lib" / "l10n" / "app_de.arb").read_text(encoding="utf-8"))
    for key, who in APP_LINES.items():
        out.append((f"voice.app.{key}.mp3", who, arb[key]))

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
    body = json.dumps({"text": spoken(text), "model_id": MODEL, "voice_settings": SETTINGS}).encode()
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
        if args.nur in f
        and (
            index.get(f, {}).get("text") != t
            or index.get(f, {}).get("einstellungen") != SETTINGS
            or not (OUT / f).exists()
        )
    ]
    chars = sum(len(t) for _, _, t in todo)
    print(f"{len(todo)} Sätze aufzunehmen, {chars} Zeichen")
    if args.liste or not todo:
        return
    today = datetime.date.today().isoformat()
    with ThreadPoolExecutor(3) as pool:
        for (file, who, text), result in zip(todo, pool.map(lambda x: record(*x), todo)):
            index[result] = {
                "wer": who,
                "text": text,
                "datum": today,
                "plan": args.plan,
                "modell": MODEL,
                "einstellungen": SETTINGS,
            }
            if spoken(text) != text:
                index[result]["aussprache"] = spoken(text)
            print("gespeichert:", result, flush=True)
    INDEX.write_text(json.dumps(dict(sorted(index.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
