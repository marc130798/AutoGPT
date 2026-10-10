#!/usr/bin/env python3
"""Macht aus einer Musik- oder Geräuschdatei eine nahtlose Schleife für die App.

Aufruf im Ordner taleria/ (braucht ffmpeg):

    python3 tool/musik_vorbereiten.py musik.mp3 music.home --von 5 --bis 71

- Schneidet das leise Ein- und Ausblenden ab (--von, --bis in Sekunden).
- Blendet das Ende weich in den Anfang über (--ueberblendung, Standard 4 s),
  so dass die Schleife ohne Pause und ohne Sprung weiterläuft.
- Speichert als MP3 mit 112 kbit/s unter assets/audio/<schluessel>.mp3, damit
  die App klein bleibt.

Danach den Eintrag in ASSETS_LICENSES.md nicht vergessen.
"""

import argparse
import os
import subprocess
import sys

OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('quelle', help='Musik- oder Geräuschdatei (MP3, WAV, ...)')
    parser.add_argument('schluessel', help='Asset-Schlüssel, z. B. music.home')
    parser.add_argument('--von', type=float, default=0, help='Anfang in Sekunden (nach dem Einblenden)')
    parser.add_argument('--bis', type=float, required=True, help='Ende in Sekunden (vor dem Ausblenden)')
    parser.add_argument('--ueberblendung', type=float, default=4, help='Länge der Überblendung in Sekunden')
    parser.add_argument('--kbps', type=int, default=112)
    args = parser.parse_args()

    start, end, fade = args.von, args.bis, args.ueberblendung
    if end - start < 3 * fade:
        sys.exit('Abbruch: Das Stück ist für diese Überblendung zu kurz.')

    # Schleife = Mitte + (Ende überblendet in den Anfang). Am Ende der Schleife
    # klingt es genau wie am Anfang der Mitte, darum gibt es keinen Sprung.
    graph = (
        '[0:a]asplit=3[a1][a2][a3];'
        f'[a1]atrim={start + fade}:{end - fade},asetpts=N/SR/TB[mitte];'
        f'[a2]atrim={end - fade}:{end},asetpts=N/SR/TB,afade=t=out:st=0:d={fade}:curve=qsin[ende];'
        f'[a3]atrim={start}:{start + fade},asetpts=N/SR/TB,afade=t=in:st=0:d={fade}:curve=qsin[anfang];'
        '[ende][anfang]amix=inputs=2:duration=longest:normalize=0[ueber];'
        '[mitte][ueber]concat=n=2:v=0:a=1[aus]'
    )
    os.makedirs(OUT_DIR, exist_ok=True)
    target = os.path.join(OUT_DIR, args.schluessel + '.mp3')
    subprocess.run(
        [
            'ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', args.quelle,
            '-filter_complex', graph, '-map', '[aus]',
            '-ar', '44100', '-ac', '2', '-c:a', 'libmp3lame', '-b:a', f'{args.kbps}k', target,
        ],
        check=True,
    )
    size_kb = os.path.getsize(target) / 1024
    print(f'{os.path.normpath(target)}: Schleife {end - start - fade:.0f} s, {size_kb:.0f} KB')


if __name__ == '__main__':
    main()
