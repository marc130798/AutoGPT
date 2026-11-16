"""Macht aus den Original-Schriften in design/schriften/ die Dateien in assets/fonts/.

Warum: Ohne eigene Schrift lädt Flutter im Browser Roboto (und Ersatzschriften für
fehlende Zeichen) von Google. Damit fremde Familien beim Testen nichts an Google
schicken, liegen die Schriften in der App:
  Nunito  für Fließtext, Knöpfe und kleine Überschriften (rund und gut lesbar),
  Baloo 2 für große Überschriften und Holzschilder (passt zum Logo).
Am 16.11.2026 mit Marc entschieden, vorher war es Roboto. Fehlende Zeichen wie
→ und ↓ kommen aus einer kleinen Ersatzschrift aus Baloo 2 („TaleriaZeichen“).

Quellen (SIL Open Font License 1.1, Lizenztexte daneben):
  https://github.com/google/fonts/tree/main/ofl/nunito  (Nunito[wght].ttf)
  https://github.com/google/fonts/tree/main/ofl/baloo2  (Baloo2[wght].ttf)

Aufruf im Ordner taleria/:  python3 tool/schriften_vorbereiten.py
Braucht: pip install fonttools
"""

from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "schriften"
OUT = ROOT / "assets" / "fonts"

# Lateinisch mit Umlauten und Sonderbuchstaben, Satzzeichen („“ – … €), Pfeile.
UNICODES = (
    list(range(0x20, 0x7F))
    + list(range(0xA0, 0x180))
    + list(range(0x2000, 0x2070))
    + [0x20AC, 0x2122, 0x2190, 0x2191, 0x2192, 0x2193, 0x2212, 0x2713]
)

NUNITO_WEIGHTS = [400, 600, 700, 800]
BALOO_WEIGHTS = [600, 700, 800]


def _subset(font: TTFont, unicodes: list[int]) -> None:
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    sub = subset.Subsetter(options)
    sub.populate(unicodes=unicodes)
    sub.subset(font)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for family, source, weights in (
        ("Nunito", "Nunito[wght].ttf", NUNITO_WEIGHTS),
        ("Baloo2", "Baloo2[wght].ttf", BALOO_WEIGHTS),
    ):
        for weight in weights:
            font = instancer.instantiateVariableFont(TTFont(SRC / source), {"wght": weight}, updateFontNames=False)
            _subset(font, UNICODES)
            path = OUT / f"{family}-{weight}.ttf"
            font.save(path)
            print(path.relative_to(ROOT), path.stat().st_size // 1024, "KB")

    font = instancer.instantiateVariableFont(TTFont(SRC / "Baloo2[wght].ttf"), {"wght": 700}, updateFontNames=False)
    _subset(font, [0x2190, 0x2191, 0x2192, 0x2193, 0x2713])
    path = OUT / "TaleriaZeichen.ttf"
    font.save(path)
    print(path.relative_to(ROOT), path.stat().st_size // 1024, "KB")


if __name__ == "__main__":
    main()
