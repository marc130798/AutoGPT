"""Klangkulissen und kurze Töne mit ElevenLabs (Sound Effects) erzeugen.

Aufruf (im Ordner taleria/):
    python3 tool/klaenge_erzeugen.py            # nur fehlende oder geänderte
    python3 tool/klaenge_erzeugen.py amb.hafen   # nur diesen Klang neu

Der API-Schlüssel kommt nie in diese Datei: In der Cloud-Umgebung setzt der
Proxy den Header `xi-api-key` selbst ein (Network secret für api.elevenlabs.io,
mit der Berechtigung „Sound Effects“). Kosten: etwa 10 Zeichen pro Sekunde.

Kulissen (`amb.*`) sind Endlosschleifen (30 Sekunden, `loop`), kurze Töne
(`sound.*`) einmalig. Danach werden alle Dateien leise und klein gerechnet
(ffmpeg: Kulissen 64 kbit/s, Töne 96 kbit/s mono, gleiche Lautstärke) und in
`assets/audio/klaenge.json` steht, mit welchem Text und wann sie entstanden
(für ASSETS_LICENSES.md; im bezahlten Starter-Plan, kommerziell nutzbar).
"""
import concurrent.futures
import datetime
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.request

OUT = 'assets/audio'
LOG = os.path.join(OUT, 'klaenge.json')
NO = ' No music, no voices, no speech.'

# Schlüssel → (Sekunden, Schleife, früher Ziel-Lautstärke (ungenutzt), Text)
KLAENGE = {
    # Klangkulissen für die Orte (statt Stille in den Missionen)
    'amb.hafen': (30, True, -20, "Calm cozy harbor ambience for a children's game: gentle waves lapping against a wooden pier, soft creaking of moored wooden boats, distant seagulls, a faint ship bell far away. Peaceful." + NO),
    'amb.tauschinsel': (30, True, -21, "Friendly island village market ambience for a children's game: soft indistinct murmur of a small crowd in the distance, wooden carts, a goat bleating once far away, birds, light sea breeze. Cheerful and calm." + NO),
    'amb.wunschinsel': (30, True, -21, "Dreamy magical island ambience for a children's game: soft warm wind, gentle chimes and sparkling twinkles now and then, distant waves, tropical birds. Calm and wondrous." + NO),
    'amb.spar-insel': (30, True, -20, "Peaceful autumn forest ambience for a children's game: soft wind through trees, rustling colorful falling leaves, gentle songbirds, an occasional distant woodpecker. Calm and cozy." + NO),
    'amb.underwater': (30, True, -20, "Calm underwater ambience for a children's game: deep soft muffled water, gentle bubbles rising now and then, slow whale-like hum far away. Peaceful, not scary." + NO),
    'amb.open_sea': (30, True, -21, "Open sea ambience on a wooden sailing ship for a children's game: waves against the hull, sails flapping softly in the wind, ropes creaking. Calm adventure." + NO),
    'amb.fog': (30, True, -22, "Mysterious but friendly foggy sea ambience for a children's game: soft deep wind, slow waves, a distant low foghorn once, gentle shimmering magical tone in the background. Calm, not scary." + NO),
    'amb.shipyard': (30, True, -21, "Small harbor shipyard workshop ambience for a children's game: occasional soft hammering on wood, a saw now and then, creaking planks, water lapping, seagulls far away. Calm and cozy." + NO),
    # Kurze Töne für besondere Momente
    'sound.chest_open': (2, False, -14, "Wooden treasure chest lid opening with a soft creak and a bright magical sparkle, for a children's game." + NO),
    'sound.badge_hang': (2, False, -15, "Small gold medal clinking softly onto a nail on a wooden wall, light metallic ting, for a children's game." + NO),
    'sound.map_unroll': (2, False, -15, "Old paper map unrolling quickly with a soft rustle, then a gentle magical shimmer, for a children's game." + NO),
    'sound.splash': (1.5, False, -16, "Small playful water splash, a fish jumping out of the sea, for a children's game." + NO),
    'sound.dolphin': (2.5, False, -18, "A small group of playful dolphins clicking and whistling happily above the water, with a light splash, for a children's game." + NO),
    'sound.whale': (2.5, False, -16, "Friendly whale blowing water from its blowhole, a soft whoosh and spray, for a children's game." + NO),
    'sound.dive': (2.5, False, -16, "Diving into water: a soft splash followed by bubbling as the sound goes underwater, for a children's game." + NO),
    'sound.page': (1, False, -18, "Single soft paper page turn of a storybook, for a children's game." + NO),
    'sound.unlock': (1.5, False, -15, "Small old padlock clicking open, followed by a short bright twinkle, for a children's game." + NO),
    'sound.rank_up': (3, False, -14, "Short cheerful brass fanfare with a ship bell ding, celebrating a promotion, for a children's game. Short and happy." + NO),
    'sound.ship_bell': (2, False, -16, "Two soft rings of a small brass ship bell, for a children's game." + NO),
    'sound.fog_rise': (3, False, -17, "Soft magical whoosh of fog rolling in over the sea, gentle shimmer, mysterious but friendly, for a children's game." + NO),
    'sound.bottle': (2, False, -16, "A small glass bottle with a cork plopping gently into the sea and bobbing, for a children's game." + NO),
    'sound.tool': (1.5, False, -16, "Two quick soft hammer taps on wood and a small sparkle, something new built, for a children's game." + NO),
}


def erzeugen(key, roh):
    dauer, schleife, _, text = KLAENGE[key]
    body = {'text': text, 'duration_seconds': dauer, 'prompt_influence': 0.4, 'model_id': 'eleven_text_to_sound_v2'}
    if schleife:
        body['loop'] = True
    req = urllib.request.Request(
        'https://api.elevenlabs.io/v1/sound-generation',
        data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', 'xi-api-key': 'vom-proxy'},
    )
    for versuch in range(4):
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                open(roh, 'wb').write(r.read())
                return
        except urllib.error.HTTPError as e:
            if e.code == 429 and versuch < 3:
                import time
                time.sleep(5 * (versuch + 1))
                continue
            raise SystemExit(f'{key}: {e.code} {e.read()[:300]!r}')


def _mittel(datei):
    out = subprocess.run(['ffmpeg', '-hide_banner', '-i', datei, '-af', 'volumedetect', '-f', 'null', '-'],
                         capture_output=True, text=True).stderr
    return float(re.search(r'mean_volume: ([-\d.]+)', out).group(1))


def verkleinern(key, roh, ziel):
    """Leise und klein: Kulissen im Mittel -38 dB wie `music.home` (seit 16.11.2026 leiser, damit man die Stimmen hört), kurze Töne
    -24 dB wie `sound.correct`, Spitzen begrenzt (auf dem iPhone lässt sich die
    Lautstärke im Browser nicht im Code senken, es zählt die Datei)."""
    schleife = KLAENGE[key][1]
    gain = (-38.0 if schleife else -24.0) - _mittel(roh)
    args = ['ffmpeg', '-y', '-loglevel', 'error', '-i', roh,
            '-af', f'volume={gain:.1f}dB,alimiter=limit={0.5 if schleife else 0.6}:level=disabled']
    args += ['-b:a', '64k'] if schleife else ['-ac', '1', '-b:a', '96k']
    subprocess.run(args + ['-ar', '44100', ziel], check=True)


def main():
    log = json.load(open(LOG)) if os.path.exists(LOG) else {}
    nur = sys.argv[1:]
    offen = [k for k in KLAENGE if k in nur] if nur else [
        k for k in KLAENGE if log.get(k, {}).get('text') != KLAENGE[k][3] or not os.path.exists(f'{OUT}/{k}.mp3')
    ]
    if not offen:
        print('Alles aktuell.')
        return
    tmp = tempfile.mkdtemp()

    def eins(key):
        roh = os.path.join(tmp, key + '.mp3')
        erzeugen(key, roh)
        verkleinern(key, roh, f'{OUT}/{key}.mp3')
        return key

    with concurrent.futures.ThreadPoolExecutor(3) as pool:
        for key in pool.map(eins, offen):
            dauer, schleife, _, text = KLAENGE[key]
            log[key] = {'text': text, 'sekunden': dauer, 'schleife': schleife,
                        'datum': datetime.date.today().isoformat(), 'plan': 'ElevenLabs Starter',
                        'modell': 'eleven_text_to_sound_v2'}
            print('fertig', key)
    json.dump(dict(sorted(log.items())), open(LOG, 'w'), ensure_ascii=False, indent=2)


if __name__ == '__main__':
    main()
