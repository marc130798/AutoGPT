import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import '../core/assets/asset_manifest.dart';
import '../core/assets/asset_repository.dart';
import 'sounds.dart';

/// Spielt Musik und Töne wirklich ab (Paket `audioplayers`). Fehlt eine
/// Datei oder verweigert der Browser den Ton, bleibt es still, ohne Fehler.
class AudioSounds extends Sounds {
  AudioSounds({required this.manifest, required this.assets, super.settings})
    : super(pauseDelay: const Duration(milliseconds: 400)) {
    _lifecycle = AppLifecycleListener(onHide: () => setInBackground(true), onShow: () => setInBackground(false));
  }

  final TaleriaAssetManifest manifest;
  final AssetRepository assets;

  /// Lautstärke der Musik: leise im Hintergrund.
  static const musicVolume = 0.6;
  static const effectVolume = 0.8;

  final _music = AudioPlayer(playerId: 'taleria-music');
  final _effects = <String, AudioPlayer>{};
  final _available = <String, Future<bool>>{};
  late final AppLifecycleListener _lifecycle;

  /// Der Browser hat das Abspielen verweigert (noch nicht angetippt).
  bool _blocked = false;

  /// Pfad für `AssetSource` (ohne `assets/`), oder `null`, wenn die Datei fehlt.
  Future<String?> _source(String key) async {
    final entry = manifest.lookup(key);
    final path = entry.path;
    if (path == null || entry.type != AssetType.audio) return null;
    if (!await (_available[key] ??= assets.isAvailable(entry))) return null;
    return path.startsWith('assets/') ? path.substring('assets/'.length) : path;
  }

  Future<void> _try(Future<void> Function() action, {bool music = false}) async {
    try {
      await action();
    } catch (error) {
      // Meist: Browser erlaubt Ton erst nach dem ersten Antippen.
      if (music) _blocked = true;
      debugPrint('Ton nicht abgespielt: $error');
    }
  }

  @override
  void startMusic(String key) => _try(() async {
    final source = await _source(key);
    if (source == null || playingMusic != key) return;
    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setVolume(musicVolume);
    await _music.play(AssetSource(source));
  }, music: true);

  @override
  void pauseMusic() => _try(_music.pause);

  @override
  void resumeMusic() => _try(_music.resume, music: true);

  @override
  void playEffect(String key) => _try(() async {
    final source = await _source(key);
    if (source == null) return;
    final player = _effects[key] ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    await player.stop();
    await player.play(AssetSource(source), volume: effectVolume);
  });

  @override
  void unlock() {
    if (!_blocked || playingMusic == null) return;
    _blocked = false;
    final key = playingMusic!;
    _try(() async {
      if (_music.source == null) {
        final source = await _source(key);
        if (source == null) return;
        await _music.setReleaseMode(ReleaseMode.loop);
        await _music.setVolume(musicVolume);
        await _music.play(AssetSource(source));
      } else {
        await _music.resume();
      }
    }, music: true);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _music.dispose();
    for (final player in _effects.values) {
      player.dispose();
    }
    super.dispose();
  }
}
