@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/assets/asset_manifest.dart';
import 'package:taleria/services/web_sounds.dart';

/// Läuft nur im Browser: `flutter test --platform chrome test/web`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = TaleriaAssetManifest.parse('''
{"version": 1, "assets": {
  "music.home": {"type": "audio", "path": "assets/audio/music.home.mp3", "placeholder": {"label": "M", "color": "#112233"}},
  "sound.correct": {"type": "audio", "path": "assets/audio/sound.correct.mp3", "placeholder": {"label": "S", "color": "#112233"}}
}}''');

  test('Musik und Töne werden als einfache Audio-Elemente abgespielt', () async {
    final sounds = WebSounds(manifest: manifest, effects: const ['sound.correct']);
    sounds.music('music.home');
    final music = sounds.elementFor('music.home')!;
    expect(music.src, endsWith('assets/audio/music.home.mp3'));
    expect(music.loop, isTrue);

    sounds.effect('sound.correct');
    final effect = sounds.elementFor('sound.correct')!;
    expect(effect.src, endsWith('assets/audio/sound.correct.mp3'));
    expect(effect.muted, isFalse);

    // Ohne Antippen verweigert der Browser den Ton: kein Absturz, die Musik
    // wartet auf das nächste Antippen.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(sounds.musicBlocked, isTrue);
    sounds.unlock();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(effect.muted, isFalse, reason: 'stummes Anspielen lässt keinen Ton stumm zurück');

    // Anderer Bildschirm: Musik pausiert nach kurzer Wartezeit.
    sounds.music(null);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(sounds.playingMusic, isNull);
    expect(music.paused, isTrue);
    sounds.dispose();
  });
}
