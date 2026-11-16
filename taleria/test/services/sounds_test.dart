import 'dart:io';

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

  @override
  void vibrate() => calls.add('vibrate');

  @override
  void playVoice(String path) => calls.add('voice $path');

  @override
  void stopVoiceAudio() => calls.add('stop voice');

  @override
  void duckMusic(bool on) => calls.add(on ? 'leiser' : 'normal');

  void finish() => voiceFinished();
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
    expect(sounds.calls, ['start music.home', 'stop voice', 'pause', 'resume']);
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

  test('Vibrieren bei Erfolgen: an, im Leuchtturm abschaltbar, unabhängig vom Ton', () async {
    final settings = FakeLocalSettings();
    final sounds = _Recording(settings: settings);
    await sounds.load();
    sounds.success();
    expect(sounds.calls, ['vibrate']);

    await sounds.setEnabled(false);
    sounds.success();
    expect(sounds.vibrations, 2, reason: 'Ton aus heißt nicht Vibrieren aus');

    await sounds.setVibrationAllowed(false);
    expect(settings.vibration, isFalse);
    sounds.success();
    expect(sounds.vibrations, 2);

    final reloaded = _Recording(settings: settings);
    await reloaded.load();
    expect(reloaded.vibrationAllowed, isFalse);
  });

  test('Stimmen: spielen aus dem Ordner, still bei Ton aus oder im Leuchtturm abgeschaltet', () async {
    final settings = FakeLocalSettings();
    final sounds = _Recording(settings: settings);
    await sounds.load();
    sounds.voice('voice.talo.tap.1.mp3');
    expect(sounds.calls, ['leiser', 'voice assets/audio/voice/voice.talo.tap.1.mp3']);

    await sounds.setEnabled(false);
    expect(sounds.calls, contains('stop voice'), reason: 'Ton aus beendet die Stimme');
    expect(sounds.musicDucked, isFalse);
    sounds.voice('voice.talo.tap.2.mp3');
    await sounds.setEnabled(true);

    await sounds.setVoicesAllowed(false);
    expect(settings.voices, isFalse);
    sounds.voice('voice.talo.tap.3.mp3');
    expect(sounds.playedVoices, ['voice.talo.tap.1.mp3']);

    final reloaded = _Recording(settings: settings);
    await reloaded.load();
    expect(reloaded.voicesAllowed, isFalse);
  });

  test('Jede Stimme, die die App abspielt, gibt es als Aufnahme', () {
    // Siehe tool/stimmen_aufnehmen.py; fehlt eine Datei, bleibt es nur still.
    final files = Directory(Sounds.voiceFolder).listSync().map((f) => f.uri.pathSegments.last).toSet();
    for (final name in [
      for (var i = 1; i <= 4; i++) ...['voice.talo.tap.$i.mp3', 'voice.tala.tap.$i.mp3'],
      for (var i = 1; i <= 3; i++) ...['voice.talo.station.$i.mp3', 'voice.tala.station.$i.mp3'],
      for (var i = 1; i <= 2; i++) ...[
        'voice.talo.island.$i.mp3',
        'voice.tala.island.$i.mp3',
        'voice.talo.oops.$i.mp3',
        'voice.tala.oops.$i.mp3',
        'voice.tala.dive.$i.mp3',
        'voice.talo.seastop.$i.mp3',
      ],
      for (var i = 0; i < 6; i++) 'voice.${i.isEven ? 'tala' : 'talo'}.tip.$i.mp3',
      'voice.talo.welcome.mp3',
      'voice.tala.welcome.mp3',
      'voice.talo.wind.mp3',
      'voice.talo.nowind.mp3',
      'voice.talo.reviews.mp3',
      'voice.tala.treasure.mp3',
      'voice.tala.shipyard.mp3',
      'voice.tala.goal.mp3',
      for (final t in ['first', 'hello', 'right', 'wrong', 'bye']) 'voice.taleron.$t.mp3',
      'voice.talo.arrive.hafen.mp3',
      'voice.tala.arrive.tauschinsel.mp3',
      'voice.talo.arrive.wunschinsel.mp3',
      'voice.tala.arrive.spar-insel.mp3',
    ]) {
      expect(files, contains(name));
    }
  });

  test('Musik wird leiser, solange eine Stimme spricht oder ein Film läuft', () {
    final sounds = _Recording();
    sounds.voice('voice.talo.tap.1.mp3');
    expect(sounds.musicDucked, isTrue);
    sounds.voice('voice.talo.tap.2.mp3');
    sounds.finish();
    expect(sounds.musicDucked, isFalse);
    expect(sounds.calls.where((c) => c == 'leiser' || c == 'normal'), ['leiser', 'normal']);

    sounds.setFilmPlaying(true);
    sounds.voice('voice.talo.tap.3.mp3');
    sounds.stopVoice();
    expect(sounds.musicDucked, isTrue, reason: 'der Film läuft noch');
    sounds.setFilmPlaying(false);
    expect(sounds.musicDucked, isFalse);
  });
}
