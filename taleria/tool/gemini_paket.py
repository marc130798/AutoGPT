"""Erstellt mehrere Bilder aus einer Textdatei mit Gemini (siehe tool/gemini_bild.py).

Die Textdatei hat Blöcke der Form:
  Bild 141: Titel  →  story.spar-insel.1.1
  Anhängen: … (design/gemini/datei.jpg) … Bild 134 (Emma) …
  <leere Zeile>
  <Text für Gemini>

„Bild N“ in der Zeile „Anhängen“ verweist auf ein vorher erstelltes Bild
(design/gemini/<schlüssel>.png). Talo und Tala ohne Pfad: ihr Figurenbild.

Aufruf im Ordner taleria/:
  python3 tool/gemini_paket.py design/prompts_spar_insel.txt 132 133 134 …
Bereits vorhandene Bilder werden übersprungen (außer mit --neu).
"""

import argparse
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GEMINI = ROOT / "design" / "gemini"


def parse(text: str) -> dict[int, dict]:
    blocks = {}
    for m in re.finditer(r"^Bild (\d+): .*?→\s*(\S+)\nAnhängen: (.*?)\n\n(.+?)\n", text, re.M):
        blocks[int(m.group(1))] = {"key": m.group(2), "attach": m.group(3), "prompt": m.group(4).strip()}
    return blocks


def refs(attach: str, blocks: dict[int, dict]) -> list[str]:
    out = [p for p in re.findall(r"design/gemini/[\w.\-]+\.(?:jpg|png)", attach)]
    for n in re.findall(r"Bild (\d+)", attach):
        out.append(f"design/gemini/{blocks[int(n)]['key']}.png")
    for name, file in (("Talo", "character.talo.jpg"), ("Tala", "character.tala.jpg")):
        if re.search(rf"\b{name}\b", attach) and not any(file in r for r in out) and "design/gemini" not in attach.split(name)[1][:40]:
            out.append(f"design/gemini/{file}")
    return [r for r in out if (ROOT / r).exists()]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("file")
    parser.add_argument("numbers", nargs="+", type=int)
    parser.add_argument("--neu", action="store_true")
    parser.add_argument("--parallel", type=int, default=3)
    args = parser.parse_args()
    blocks = parse(Path(args.file).read_text(encoding="utf-8"))

    def run(n: int) -> str:
        b = blocks[n]
        target = GEMINI / f"{b['key']}.png"
        if target.exists() and not args.neu:
            return f"{n}: schon da"
        fmt = "4:3" if b["key"].startswith("story.") or "Querformat" in b["prompt"] else (
            "9:16" if "Hochformat" in b["prompt"] else "1:1")
        cmd = [sys.executable, str(ROOT / "tool" / "gemini_bild.py"), str(target), b["prompt"], *refs(b["attach"], blocks),
               "--format", fmt]
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT)
        return f"{n} {b['key']}: " + (result.stdout.strip() or result.stderr.strip()[-300:])

    with ThreadPoolExecutor(args.parallel) as pool:
        for line in pool.map(run, args.numbers):
            print(line, flush=True)


if __name__ == "__main__":
    main()
