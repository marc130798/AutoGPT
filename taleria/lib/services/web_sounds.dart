import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../core/assets/asset_manifest.dart';
import '../data/local_settings.dart';
import 'sounds.dart';

/// Für den Browser: [WebSounds], sonst (in `web_sounds_stub.dart`) `null`.
Sounds? createWebSounds({
  required TaleriaAssetManifest manifest,
  required List<String> effects,
  LocalSettings? settings,
}) => WebSounds(manifest: manifest, effects: effects, settings: settings);

/// Musik und Töne im Browser mit einfachen Audio-Elementen.
///
/// Warum nicht über `audioplayers`: Das Paket leitet den Ton im Browser über
/// Web Audio. Das iPhone schaltet Web Audio stumm, sobald der Lautlos-Schalter
/// an ist, und startet es nur direkt beim Antippen. Einfache Audio-Elemente
/// spielen wie ein Video auch auf lautlos, und dieser Dienst ruft sie ohne
/// Wartezeit auf, damit Safari das Antippen noch zuordnen kann.
class WebSounds extends Sounds {
  WebSounds({required this.manifest, required this.effects, super.settings})
    : super(pauseDelay: const Duration(milliseconds: 400)) {
    _lifecycle = AppLifecycleListener(onHide: () => setInBackground(true), onShow: () => setInBackground(false));
  }

  final TaleriaAssetManifest manifest;

  /// Alle kurzen Töne. Beim ersten Antippen werden sie einmal stumm
  /// angespielt; danach darf Safari sie auch ohne Antippen abspielen (zum
  /// Beispiel die Fanfare, wenn das Ergebnis vom Server kommt).
  final List<String> effects;

  /// Lautstärke (auf dem iPhone fest, dort zählt nur die Datei).
  static const musicVolume = 0.6;
  static const effectVolume = 0.8;

  final _elements = <String, web.HTMLAudioElement>{};

  /// Wie oft jeder Ton wirklich gespielt wurde (damit das stumme Anspielen
  /// einen echten Ton nicht anhält).
  final _played = <String, int>{};
  final _primed = <String>{};
  final _priming = <String>{};
  late final AppLifecycleListener _lifecycle;
  String? _musicKey;
  bool _musicBlocked = false;

  web.HTMLAudioElement? _element(String key) {
    final existing = _elements[key];
    if (existing != null) return existing;
    final entry = manifest.lookup(key);
    final path = entry.path;
    if (path == null || entry.type != AssetType.audio) return null;
    final audio = web.HTMLAudioElement()
      ..src = ui_web.assetManager.getAssetUrl(path)
      ..preload = 'auto';
    return _elements[key] = audio;
  }

  /// Abspielen; verweigert der Browser (noch nicht angetippt) oder fehlt die
  /// Datei, bleibt es still.
  void _play(web.HTMLAudioElement audio, {bool music = false}) {
    audio.play().toDart.then(
      (_) {},
      onError: (Object error) {
        if (music) _musicBlocked = true;
        debugPrint('Ton nicht abgespielt: $error');
      },
    );
  }

  @override
  void startMusic(String key) {
    final audio = _element(key);
    if (audio == null) return;
    _musicKey = key;
    audio
      ..loop = true
      ..volume = musicVolume
      ..currentTime = 0;
    _play(audio, music: true);
  }

  @override
  void pauseMusic() {
    _musicBlocked = false;
    final key = _musicKey;
    if (key != null) _elements[key]?.pause();
  }

  @override
  void resumeMusic() {
    final key = _musicKey;
    final audio = key == null ? null : _elements[key];
    if (audio != null) _play(audio, music: true);
  }

  @override
  void playEffect(String key) {
    final audio = _element(key);
    if (audio == null) return;
    _played[key] = (_played[key] ?? 0) + 1;
    audio
      ..muted = false
      ..volume = effectVolume
      ..currentTime = 0;
    _play(audio);
  }

  @override
  void unlock() {
    // Jeder Ton einmal stumm anspielen. Klappt es nicht (auf dem Handy zählt
    // erst das Loslassen als Antippen), beim nächsten Mal wieder versuchen.
    for (final key in effects) {
      if (_primed.contains(key) || _priming.contains(key)) continue;
      final audio = _element(key);
      if (audio == null) continue;
      _priming.add(key);
      final playedBefore = _played[key] ?? 0;
      audio.muted = true;
      audio.play().toDart.then(
        (_) {
          _priming.remove(key);
          _primed.add(key);
          // Nur anhalten, wenn der Ton nicht inzwischen wirklich gespielt wird.
          if ((_played[key] ?? 0) == playedBefore) {
            audio
              ..pause()
              ..currentTime = 0;
          }
          audio.muted = false;
        },
        onError: (Object _) {
          _priming.remove(key);
          audio.muted = false;
        },
      );
    }
    final key = playingMusic;
    if (_musicBlocked && key != null) {
      _musicBlocked = false;
      final audio = _element(key);
      if (audio != null) {
        _musicKey = key;
        audio.loop = true;
        _play(audio, music: true);
      }
    }
  }

  /// Audio-Element eines Tons (für Tests im Browser).
  @visibleForTesting
  web.HTMLAudioElement? elementFor(String key) => _elements[key];

  /// Der Browser hat die Musik noch nicht erlaubt (für Tests im Browser).
  @visibleForTesting
  bool get musicBlocked => _musicBlocked;

  @override
  void dispose() {
    _lifecycle.dispose();
    for (final audio in _elements.values) {
      audio.pause();
    }
    super.dispose();
  }
}
