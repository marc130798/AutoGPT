"""Stimmen für Inselbewohner mit ElevenLabs „Voice Design“ entwerfen und die
gewählte dauerhaft in Marcs Konto speichern (Marc, 16.11.2026: Stimmen müssen
gleich bleiben und wiederverwendbar sein, falls sich ein Satz ändert).

Der API-Schlüssel steht nicht hier (Network secret, Header xi-api-key). Er
braucht die Berechtigungen „Voice Generation“ und „Voices: Write“.

1. Proben erzeugen (je Figur 3 Vorschläge, landen in design/stimmen/):
     python3 tool/stimme_entwerfen.py proben [figur ...]
2. Gewählte Probe dauerhaft speichern (gibt die feste voice_id aus, die dann in
   tool/stimmen_aufnehmen.py unter VOICES eingetragen wird):
     python3 tool/stimme_entwerfen.py speichern olga 2

Das Starter-Abo hat 10 eigene Stimmen (3 belegt: Talo, Tala, Taleron). Nur
die 7 Figuren mit den meisten Sätzen bekommen eine eigene; Moritz und die
Nebenrollen bekommen feste Stimmen aus der ElevenLabs-Bibliothek.
"""

import base64
import json
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'design' / 'stimmen'
API = 'https://api.elevenlabs.io/v1'
DE = ' Native German speaker with a clear standard German accent, for a German children\'s cartoon. Friendly, never scary.'

# Figur → (Beschreibung für ElevenLabs, Probesatz auf Deutsch)
FIGUREN = {
    # Neue Stimme für Talo (Marc am 17.11.2026: die alte gefällt ihm nicht). Zwei Richtungen, je 3 Proben.
    'talo': (
        'A young adult male voice actor with a bright, light and youthful voice, voicing a brave fox captain in an '
        'animated family film. Warm, clear, lively and confident, curious and kind, with a smile in the voice.' + DE,
        'Ahoi! Ich bin Talo, der Kapitän. Willkommen an Bord! Komm mit, wir segeln zur nächsten Insel von Taléria. '
        'Ich habe meinen Kompass dabei und meistens auch einen Plan.',
    ),
    'talo3': (
        'A very young-sounding male voice with a light, high, boyish tone, like a cheerful cartoon hero. Energetic, '
        'playful and bright, quick and curious, friendly, a little cheeky, clear articulation.' + DE,
        'Ahoi! Ich bin Talo, der Kapitän. Willkommen an Bord! Komm mit, wir segeln zur nächsten Insel von Taléria. '
        'Ich habe meinen Kompass dabei und meistens auch einen Plan.',
    ),
    'talo4': (
        'A youthful, light male voice actor known for animated young heroes. Higher pitch, soft and warm, enthusiastic, '
        'adventurous and kind, sounds young but clearly male, smiling while speaking.' + DE,
        'Ahoi! Ich bin Talo, der Kapitän. Willkommen an Bord! Komm mit, wir segeln zur nächsten Insel von Taléria. '
        'Ich habe meinen Kompass dabei und meistens auch einen Plan.',
    ),
    'talo2': (
        'A cheerful young adult male narrator voice, voicing a friendly fox ship captain in an animated family film. '
        'Warm, relaxed, adventurous, calm and reassuring, clear articulation, medium pitch.' + DE,
        'Ahoi! Ich bin Talo, der Kapitän. Willkommen an Bord! Komm mit, wir segeln zur nächsten Insel von Taléria. '
        'Ich habe meinen Kompass dabei und meistens auch einen Plan.',
    ),
    'emma': (
        'A lively, warm young adult female squirrel, the careful storekeeper of an autumn island. Bright, quick-witted, '
        'cheerful and caring voice, a little bit bubbly.' + DE,
        'Hallo, ich bin Emma! Siehst du meine Nüsse? Jeden Tag lege ich ein paar zur Seite. '
        'Wenn der Winter kommt, habe ich genug. Sparen ist gar nicht so schwer, wenn man klein anfängt.',
    ),
    'gustav': (
        'A carefree, playful male cricket musician, a fiddler who loves today more than tomorrow. Light, '
        'cheeky, sing-song voice, charming and relaxed, a bit dreamy.' + DE,
        'Ach, Emma, warum denn sparen? Die Sonne scheint, und meine Geige klingt so schön! '
        'Morgen ist morgen. Komm, tanz doch mit mir, nur ein kleines Lied!',
    ),
    'bruno': (
        'A big, friendly, good-natured male bear, a fruit farmer. Deep, warm, slow and cozy voice, '
        'a gentle giant who laughs easily.' + DE,
        'Na, ihr zwei? Ich bin Bruno. Meine Äpfel sind die saftigsten auf der ganzen Insel. '
        'Aber ich bräuchte dringend ein neues Seil. Hat vielleicht jemand eins zum Tauschen?',
    ),
    'greta': (
        'A practical, clever middle-aged female goat, a rope maker. Clear, brisk, slightly bleating '
        'undertone, confident and good at bargaining, but kind.' + DE,
        'Ich bin Greta, ich mache die besten Seile. Ein Seil gegen drei Fische? Hm, das muss ich mir überlegen. '
        'Ein Tausch ist nur gut, wenn beide zufrieden sind.',
    ),
    'otti': (
        'A cheerful, energetic young male otter, a fisherman. Fast-talking but clear, playful and enthusiastic, '
        'always in a good mood.' + DE,
        'Ahoi! Ich bin Otti, der Fischer! Heute war ein toller Tag, mein Netz ist voll bis oben hin. '
        'Wer möchte frischen Fisch? Ich tausche gern!',
    ),
    'olga': (
        'A warm, wise, very old female tortoise, the elder of an island. Slow, calm, kind grandmother voice, '
        'slightly raspy, gentle and patient.' + DE,
        'Willkommen auf der Tauschinsel, ihr beiden. Ich bin Olga. Hier gibt es kein Geld, hier wird getauscht. '
        'Aber passt gut auf: Ein fairer Tausch muss für beide gut sein.',
    ),
    'elsa': (
        'A glamorous, excited female magpie who runs a glitter shop and loves shiny things. Bright, a bit '
        'theatrical and persuasive saleswoman voice, enthusiastic, slightly high.' + DE,
        'Oh, herein, herein! Ich bin Elsa. Schaut nur, wie das glitzert! Diese Sonnenbrille brauchst du unbedingt. '
        'Na gut, vielleicht brauchst du sie nicht, aber sie ist doch soo schön!',
    ),
}


def _post(path, body):
    req = urllib.request.Request(
        f'{API}{path}',
        data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', 'xi-api-key': 'vom-proxy'},
    )
    try:
        with urllib.request.urlopen(req, timeout=240) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        raise SystemExit(f'{path}: {e.code} {e.read()[:400]!r}')


def proben(namen):
    OUT.mkdir(parents=True, exist_ok=True)
    index_file = OUT / 'proben.json'
    index = json.loads(index_file.read_text()) if index_file.exists() else {}
    for name in namen or FIGUREN:
        beschreibung, text = FIGUREN[name]
        result = _post('/text-to-voice/design', {
            'voice_description': beschreibung,
            'model_id': 'eleven_multilingual_ttv_v2',
            'text': text,
        })
        index[name] = []
        for i, p in enumerate(result.get('previews', []), start=1):
            (OUT / f'{name}_{i}.mp3').write_bytes(base64.b64decode(p['audio_base_64']))
            index[name].append(p['generated_voice_id'])
        print(name, len(index[name]), 'Proben')
    index_file.write_text(json.dumps(index, indent=2))


def speichern(name, nummer):
    index = json.loads((OUT / 'proben.json').read_text())
    beschreibung, _ = FIGUREN[name]
    result = _post('/text-to-voice', {
        'voice_name': f'Taleria {name.capitalize()}',
        'voice_description': beschreibung[:1000],
        'generated_voice_id': index[name][int(nummer) - 1],
    })
    print(name, 'gespeichert, voice_id:', result['voice_id'])


if __name__ == '__main__':
    if len(sys.argv) >= 2 and sys.argv[1] == 'proben':
        proben(sys.argv[2:])
    elif len(sys.argv) == 4 and sys.argv[1] == 'speichern':
        speichern(sys.argv[2], sys.argv[3])
    else:
        print(__doc__)
