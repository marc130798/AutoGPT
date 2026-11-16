"""Verkleinert die Logbuch-PDFs für die App (logbuch/*.pdf → logbuch/web/*.pdf).

Warum: Die PDFs liegen in der Web-Version neben der App, damit Eltern sie im
Leuchtturm öffnen und ausdrucken können. Die Bilder darin sind als PNG gespeichert
und machen die Dateien groß. Hier werden die Farbbilder als JPEG (Qualität 85)
neu gespeichert; die Durchsichtigkeit (Maske) bleibt, Text bleibt scharf.
Zum Ausdrucken reicht das völlig. Die Originale bleiben unverändert.

Aufruf im Ordner taleria/:  python3 tool/logbuch_verkleinern.py
Braucht: pip install pikepdf pillow
"""

import io
from pathlib import Path

import pikepdf
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "logbuch"
OUT = SRC / "web"


def shrink(path: Path) -> Path:
    pdf = pikepdf.open(path)
    # Alle Bilder der Datei (auch die in eingebetteten Formularen); die grauen
    # Masken für die Durchsichtigkeit bleiben, wie sie sind.
    for raw in pdf.objects:
        if not isinstance(raw, pikepdf.Stream) or raw.get("/Subtype") != "/Image":
            continue
        if raw.get("/Filter") != "/FlateDecode" or raw.get("/BitsPerComponent") != 8 or "/SMask" not in raw and raw.get("/ColorSpace") == "/DeviceGray":
            continue
        pil = pikepdf.PdfImage(raw).as_pil_image()
        # pikepdf hängt die Maske als Alpha an; sie bleibt im PDF ohnehin getrennt.
        if pil.mode == "RGBA":
            pil = pil.convert("RGB")
        if pil.mode != "RGB":
            continue
        buffer = io.BytesIO()
        pil.save(buffer, format="JPEG", quality=85, optimize=True)
        # Farbraum (ICC) bleibt, nur die Speicherart wird JPEG.
        raw.write(buffer.getvalue(), filter=pikepdf.Name("/DCTDecode"))
        if "/DecodeParms" in raw:
            del raw["/DecodeParms"]
    OUT.mkdir(exist_ok=True)
    target = OUT / path.name
    pdf.save(target, compress_streams=True, object_stream_mode=pikepdf.ObjectStreamMode.generate)
    return target


def main() -> None:
    for path in sorted(SRC.glob("logbuch_*.pdf")):
        target = shrink(path)
        print(f"{path.name}: {path.stat().st_size // 1024} KB → {target.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
