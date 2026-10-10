import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/services/sounds.dart';

import '../fakes.dart';

/// Schreibt mit, was abgespielt würde.
class _Recording extends Sounds {
  _Recording({super.settings, super.pauseDelay});

  final calls = <String>[];

  @override
  void startMusic(String key) => calls.add('start $key');

  @override
  void pauseMusic() => calls.add('pause');

  @override
  void resumeMusic() => calls.add('resume');

  @override
  void playEffect(String key) => calls.add('effect $key');
}

void main() {
  test('Musik läuft, pausiert auf anderen Bildschirmen und läuft an derselben Stelle weiter', () {
    final sounds = _Recording();
    sounds.music('music.home');
    expect(sounds.playingMusic, 'music.home');
    sounds.music(null);
    expect(sounds.playingMusic, isNull);
    sounds.music('music.home');
    expect(sounds.calls, ['start music.home', 'pause', 'resume']);
  });

  test('Ton aus: keine Musik und keine Töne; wieder an: Musik läuft weiter', () async {
    final settings = FakeLocalSettings();
    final sounds = _Recording(settings: settings)..music('music.home');
    await sounds.setEnabled(false);
    sounds.effect('sound.correct');
    expect(sounds.playingMusic, isNull);
    expect(sounds.playedEffects, isEmpty);
    expect(settings.sound, isFalse, reason: 'gilt auch beim nächsten Öffnen');
    await sounds.setEnabled(true);
    expect(sounds.calls, ['start music.home', 'pause', 'resume']);
  });

  test('Musik im Leuchtturm aus: keine Musik, Töne bei richtig bleiben', () async {
    final settings = FakeLocalSettings();
    final sounds = _Recording(settings: settings)..music('music.home');
    await sounds.setMusicAllowed(false);
    sounds.effect('sound.correct');
    expect(sounds.playingMusic, isNull);
    expect(sounds.playedEffects, ['sound.correct']);
    expect(settings.music, isFalse);
  });

  test('Im Hintergrund pausiert die Musik', () {
    final sounds = _Recording()..music('music.home');
    sounds.setInBackground(true);
    expect(sounds.playingMusic, isNull);
    sounds.setInBackground(false);
    expect(sounds.playingMusic, 'music.home');
  });

  test('Startseite → Karte: dieselbe Musik läuft ohne Pause weiter', () async {
    final sounds = _Recording(pauseDelay: const Duration(milliseconds: 50))..music('music.home');
    sounds
      ..music(null)
      ..music('music.home');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(sounds.calls, ['start music.home']);

    sounds.music(null);
    expect(sounds.playingMusic, 'music.home', reason: 'erst nach kurzer Wartezeit');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(sounds.playingMusic, isNull);
  });

  test('Gespeicherte Einstellungen werden beim Start gelesen', () async {
    final settings = FakeLocalSettings()
      ..sound = false
      ..music = false;
    final sounds = _Recording(settings: settings);
    await sounds.load();
    expect(sounds.enabled, isFalse);
    expect(sounds.musicAllowed, isFalse);
  });
}
