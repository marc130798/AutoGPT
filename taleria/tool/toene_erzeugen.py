#!/usr/bin/env python3
"""Erzeugt die kurzen Töne der App am Computer (ohne fremde Aufnahmen).

Aufruf im Ordner taleria/ (braucht Python 3 mit numpy und ffmpeg):

    python3 tool/toene_erzeugen.py

Legt unter assets/audio/ ab:
- sound.correct.mp3       richtige Antwort: zwei helle Glockentöne nach oben
- sound.pearl.mp3         Perle gefunden: Blubb-Blubb und ein kleines Glitzern
- sound.station_done.mp3  Station geschafft: kurze Fanfare (vier Töne nach oben)
- sound.island_done.mp3   Insel geschafft: größere Fanfare mit Glitzern

Alle Töne sind weich und freundlich, nie schrill und nie laut (für Kinder). Im Browser
auf dem iPhone lässt sich die Lautstärke nicht im Code senken, darum sind schon die
Dateien leise.
"""

import os
import subprocess
import tempfile
import wave

import numpy as np

RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')


def silence(seconds):
    return np.zeros(int(RATE * seconds))


def bell(freq, seconds, decay=4.0, level=1.0):
    """Glockenspiel: Grundton mit leisen, schnell verklingenden Obertönen."""
    t = np.arange(int(RATE * seconds)) / RATE
    tone = (
        np.sin(2 * np.pi * freq * t) * np.exp(-decay * t)
        + 0.35 * np.sin(2 * np.pi * freq * 2.0 * t) * np.exp(-decay * 2.2 * t)
        + 0.12 * np.sin(2 * np.pi * freq * 3.0 * t) * np.exp(-decay * 3.5 * t)
    )
    attack = np.minimum(1, t / 0.004)  # weicher Anschlag ohne Knacken
    return level * tone * attack


def marimba(freq, seconds, level=1.0):
    """Holziger, warmer Ton (für die Fanfaren)."""
    t = np.arange(int(RATE * seconds)) / RATE
    tone = np.sin(2 * np.pi * freq * t) * np.exp(-3.2 * t) + 0.25 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-14 * t)
    return level * tone * np.minimum(1, t / 0.006)


def bubble(start_freq, end_freq, seconds=0.12, level=1.0):
    """Blubb: Ton, der schnell nach oben gleitet und verklingt."""
    t = np.arange(int(RATE * seconds)) / RATE
    freq = start_freq + (end_freq - start_freq) * (t / seconds) ** 0.6
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    return level * np.sin(phase) * np.exp(-18 * t) * np.minimum(1, t / 0.003)


def mix(length, *parts):
    """Legt Teile (Startzeit in Sekunden, Ton) übereinander."""
    out = np.zeros(int(RATE * length))
    for start, part in parts:
        i = int(RATE * start)
        n = min(len(part), len(out) - i)
        out[i : i + n] += part[:n]
    return out


def finish(samples, peak_db=-8.0):
    """Leise auslaufen lassen und auf eine angenehme Lautstärke bringen."""
    fade = int(RATE * 0.05)
    samples[-fade:] *= np.linspace(1, 0, fade)
    return samples / np.max(np.abs(samples)) * 10 ** (peak_db / 20)


def correct():
    return finish(mix(0.9, (0, bell(1046.5, 0.8, level=0.8)), (0.11, bell(1568.0, 0.78))), peak_db=-9)


def pearl():
    sparkle = [(0.32 + i * 0.06, bell(f, 0.45, decay=7, level=0.35)) for i, f in enumerate([2637.0, 3136.0, 3520.0])]
    return finish(mix(1.0, (0, bubble(320, 900)), (0.13, bubble(420, 1150, level=0.8)), *sparkle), peak_db=-10)


def station_done():
    notes = [523.25, 659.25, 783.99, 1046.5]
    run = [(i * 0.12, marimba(f, 0.9, level=0.8)) for i, f in enumerate(notes)]
    chord = [(0.48, bell(f, 1.0, decay=3, level=0.45)) for f in [1046.5, 1318.5]]
    return finish(mix(1.6, *run, *chord))


def island_done():
    notes = [523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0]
    run = [(i * 0.1, marimba(f, 0.9, level=0.75)) for i, f in enumerate(notes)]
    chord = [(0.62, marimba(f, 1.6, level=0.5)) for f in [523.25, 659.25, 783.99, 1046.5]]
    sparkle = [(0.7 + i * 0.09, bell(f, 0.6, decay=6, level=0.25)) for i, f in enumerate([2093.0, 2637.0, 3136.0, 2637.0, 3520.0])]
    return finish(mix(2.5, *run, *chord, *sparkle))


def save(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    target = os.path.join(OUT_DIR, name + '.mp3')
    with tempfile.NamedTemporaryFile(suffix='.wav') as tmp:
        with wave.open(tmp.name, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes((samples * 32767).astype(np.int16).tobytes())
        subprocess.run(
            ['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', tmp.name, '-c:a', 'libmp3lame', '-b:a', '96k', target],
            check=True,
        )
    print(f'{os.path.normpath(target)}: {len(samples) / RATE:.1f} s, {os.path.getsize(target) / 1024:.0f} KB')


def main():
    save('sound.correct', correct())
    save('sound.pearl', pearl())
    save('sound.station_done', station_done())
    save('sound.island_done', island_done())


if __name__ == '__main__':
    main()
