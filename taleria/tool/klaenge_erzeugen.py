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

# Schlüssel → (Sekunden, Schleife, mittlere Lautstärke in dB, Text)
KLAENGE = {
    # Klangkulissen für die Orte. Seit 17.11.2026 (Marcs Test) ruhiger: weniger Rauschen,
    # mehr typische Geräusche, und leiser (dritter Wert = mittlere Lautstärke in dB).
    'amb.hafen': (30, True, -50, "Very soft and quiet harbor ambience for a children's game: gentle small waves lapping against a wooden pier, a wooden boat creaking now and then, seagulls calling in the distance from time to time. Very little wind noise, no rumbling, clear and calm." + NO),
    'amb.tauschinsel': (30, True, -50, "Very soft friendly island village market ambience for a children's game: quiet indistinct murmur of a few people far away, a wooden cart rolling by once, a goat bleating once far away, songbirds, small waves. Very little wind noise, no rumbling, clear and calm." + NO),
    'amb.wunschinsel': (30, True, -50, "Very soft dreamy magical island ambience for a children's game: gentle chimes and little sparkling twinkles now and then, tropical birds, small waves on a beach. Very little wind noise, no rumbling, clear and calm." + NO),
    'amb.spar-insel': (30, True, -50, "Very soft autumn forest ambience for a children's game: rustling colorful falling leaves, gentle songbirds, a squirrel scurrying now and then, an occasional distant woodpecker. Very little wind noise, no rumbling, clear and calm." + NO),
    'amb.underwater': (30, True, -50, "Very soft calm underwater ambience for a children's game: gentle bubbles rising now and then, soft muffled water, a few soft water drips and gentle sand swirling, nothing else (no animal calls, no whales, no dolphins). Very little wind noise, no rumbling, clear and calm." + NO),
    'amb.open_sea': (30, True, -50, "Very soft open sea ambience on a wooden sailing ship for a children's game: small waves against the hull, sails flapping softly now and then, ropes creaking, a seagull far away. Very little wind noise, no rumbling, clear and calm." + NO),
    'amb.fog': (30, True, -50, "Very soft mysterious but friendly foggy sea ambience for a children's game: slow quiet waves, a distant low foghorn once, a gentle shimmering magical tone. Very little wind noise, no rumbling, clear and calm." + NO),
    'amb.shipyard': (30, True, -46, "Busy but cozy small harbor shipyard ambience for a children's game: clear hammering on wood, a hand saw sawing, a plane shaving wood, planks creaking, a chisel tapping, water lapping, seagulls far away. Clearly a workshop. Very little wind noise, no rumbling, clear and calm." + NO),
    # Kurze Töne für besondere Momente
    'sound.chest_open': (2.5, False, -29, "An old heavy wooden pirate treasure chest slowly creaking open, rusty iron hinges squeaking, a soft wooden thud as the lid falls back, for a children's game." + NO),
    'sound.badge_hang': (2, False, -29, "Small gold medal clinking softly onto a nail on a wooden wall, light metallic ting, for a children's game." + NO),
    'sound.map_unroll': (2, False, -29, "Old paper map unrolling quickly with a soft rustle, then a gentle magical shimmer, for a children's game." + NO),
    'sound.splash': (1.5, False, -29, "Small playful water splash, a fish jumping out of the sea, for a children's game." + NO),
    'sound.dolphin': (2.5, False, -29, "A small group of playful dolphins clicking and whistling happily above the water, with a light splash, for a children's game." + NO),
    'sound.whale': (2.5, False, -29, "Friendly whale blowing water from its blowhole, a soft whoosh and spray, for a children's game." + NO),
    'sound.dive': (2.5, False, -29, "Diving into water: a soft splash followed by bubbling as the sound goes underwater, for a children's game." + NO),
    'sound.page': (1, False, -29, "Single soft paper page turn of a storybook, for a children's game." + NO),
    'sound.unlock': (1.5, False, -29, "Small old padlock clicking open, followed by a short bright twinkle, for a children's game." + NO),
    'sound.rank_up': (3, False, -29, "Short cheerful brass fanfare with a ship bell ding, celebrating a promotion, for a children's game. Short and happy." + NO),
    'sound.ship_bell': (2, False, -29, "Two soft rings of a small brass ship bell, for a children's game." + NO),
    'sound.fog_rise': (3, False, -29, "Soft magical whoosh of fog rolling in over the sea, gentle shimmer, mysterious but friendly, for a children's game." + NO),
    'sound.bottle': (2, False, -29, "A small glass bottle with a cork plopping gently into the sea and bobbing, for a children's game." + NO),
    'sound.tool': (1.5, False, -29, "Two quick soft hammer taps on wood and a small sparkle, something new built, for a children's game." + NO),
    # Beim Betreten der Kabinen (Marcs Wunsch am 17.11.2026)
    'sound.medals': (1.5, False, -30, "A few small gold medals clinking gently against each other on ribbons, light and bright, for a children's game." + NO),
    'sound.paper': (1.5, False, -30, "Soft rustling of a few old paper notes being picked up from a wooden desk, for a children's game." + NO),
    'sound.bubbles': (1.5, False, -30, "A short burst of soft underwater bubbles rising, playful blub blub, for a children's game." + NO),
    'sound.dice': (1.5, False, -30, "A pair of wooden dice rattling in a cup and rolling onto a wooden table, for a children's game." + NO),
    # Eigene Töne der Mini-Spiele (Marcs Wunsch am 17.11.2026)
    'sound.register': (1.5, False, -29, "An old-fashioned shop cash register: a cheerful small bell ding and the cash drawer sliding open, for a children's game." + NO),
    'sound.market_bell': (1.2, False, -29, "A small cheerful brass hand bell at a market stall ringing twice, for a children's game." + NO),
    'sound.ice_scoop': (1.2, False, -29, "An ice cream scoop scraping a scoop of ice cream and plopping it onto a waffle cone, for a children's game." + NO),
    'sound.trade': (1.2, False, -29, "A quick friendly whoosh as two things are swapped between hands, ending with a soft pop, for a children's game." + NO),
    'sound.zipper': (1.2, False, -29, "A backpack zipper being zipped closed quickly, for a children's game." + NO),
    'sound.piggy': (1.5, False, -29, "A coin dropping into a ceramic piggy bank with a clink and a short rattle inside, for a children's game." + NO),
    'sound.dig': (1.5, False, -29, "A small animal quickly digging in dry autumn leaves and soft earth, burying a nut, for a children's game." + NO),
    'sound.shop_bell': (1.5, False, -29, "A little shop door bell jingling brightly as the door opens, with a magical sparkle, for a children's game." + NO),
    # Töne der richtigen Spiele (Marcs Wunsch am 18.11.2026). Häufige Töne (Flügelschlag,
    # Sprung, Bahnwechsel, Kescher) besonders leise.
    'sound.arcade.flap': (0.5, False, -37, "One single soft whoosh of a seagull flapping its wings once, very short, for a children's game." + NO),
    'sound.arcade.squawk': (0.8, False, -31, "One short funny surprised seagull squawk, like a little 'aak!', for a children's game." + NO),
    'sound.arcade.glass': (0.8, False, -30, "A few gold coins dropping into a glass jar with a bright clink, for a children's game." + NO),
    'sound.arcade.chain': (1.0, False, -32, "A short metal chain rattling quickly as a crane hook is lowered, for a children's game." + NO),
    'sound.arcade.boot': (1.0, False, -30, "A funny squeaky wet rubber boot being pulled out of water, squelch and squeak, for a children's game." + NO),
    'sound.arcade.oar': (0.5, False, -36, "One soft paddle stroke of a wooden oar in calm water, very short, for a children's game." + NO),
    'sound.arcade.thump': (0.5, False, -31, "A soft dull thump of a small basket of goods landing in a wooden boat, for a children's game." + NO),
    'sound.arcade.clonk': (0.7, False, -31, "A short hollow wooden clonk of a small rowing boat bumping gently into a rock, for a children's game." + NO),
    'sound.arcade.swoosh': (0.5, False, -37, "One quick soft swish of a fishing net swung through the air, very short, for a children's game." + NO),
    'sound.arcade.sparkle_down': (0.9, False, -32, "A gentle magical sparkle sound going downwards, soft and friendly, like a tiny 'oh-oh', for a children's game." + NO),
    'sound.arcade.hop': (0.5, False, -36, "A tiny soft cartoon hop sound, a light springy boing, very short, for a children's game." + NO),
    'sound.arcade.nut': (0.5, False, -32, "One small crisp crack of a hazelnut being picked up, very short, for a children's game." + NO),
    'sound.arcade.bonk': (0.6, False, -31, "A soft cartoon bonk of bumping into a mushroom, cushioned and funny, not painful, for a children's game." + NO),
    'sound.arcade.shell': (0.5, False, -35, "A small seashell clam snapping gently shut underwater, soft muffled click, for a children's game." + NO),
    'sound.arcade.jelly': (0.8, False, -31, "A friendly wobbly bzzt of a cartoon jellyfish, soft electric jiggle, not scary, for a children's game." + NO),
    'sound.arcade.horn': (1.2, False, -31, "A short cheerful ship horn toot, like 'let's go', for a children's game." + NO),
    'sound.arcade.record': (2.2, False, -28, "A short bright happy fanfare with a little drum roll and sparkle, celebrating a new high score, for a children's game." + NO),
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
    """Leise und klein auf die Lautstärke aus `KLAENGE` (Kulissen seit 17.11.2026 abends um -50 dB, die Werft -46,
    leiser als `music.home`; kurze Töne um -29 dB, Marcs Test: „in den Aufgaben zu laut“), Spitzen begrenzt (auf dem iPhone lässt sich die
    Lautstärke im Browser nicht im Code senken, es zählt die Datei)."""
    schleife = KLAENGE[key][1]
    gain = KLAENGE[key][2] - _mittel(roh)
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
