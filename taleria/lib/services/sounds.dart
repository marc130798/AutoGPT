import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local_settings.dart';

/// Musik im Hauptmenü und kurze Töne (richtige Antwort, Station geschafft).
///
/// Diese Klasse kennt nur die Regeln:
/// - Ton aus (Lautsprecher-Knopf des Kindes): alles still.
/// - Musik nicht erlaubt (Schalter im Leuchtturm): keine Musik, Töne ja.
/// - Jeder Bildschirm sagt mit [music], welche Musik er möchte (`null` = keine).
/// - Ist die App im Hintergrund, pausiert die Musik.
///
/// Abgespielt wird in [AudioSounds]. Diese Klasse selbst ist still und
/// schreibt nur mit (für Tests und Geräte ohne Ton).
class Sounds extends ChangeNotifier {
  Sounds({this.settings, this.pauseDelay = Duration.zero});

  /// Wo Ton an und Musik erlaubt gespeichert werden (`null` = nur im Speicher).
  final LocalSettings? settings;

  /// Wartezeit, bevor die Musik beim Bildschirmwechsel pausiert. Geht es auf
  /// einen Bildschirm mit derselben Musik weiter (Startseite → Karte), läuft
  /// sie ohne Unterbrechung weiter.
  final Duration pauseDelay;

  bool _enabled = true;
  bool _musicAllowed = true;
  bool _inBackground = false;
  String? _wanted;
  String? _playing;
  String? _loaded;
  Timer? _pauseTimer;

  /// Ton an (Lautsprecher-Knopf auf der Startseite).
  bool get enabled => _enabled;

  /// Musik im Hauptmenü erlaubt (Schalter im Leuchtturm).
  bool get musicAllowed => _musicAllowed;

  /// Musik, die gerade läuft (`null` = keine oder pausiert).
  String? get playingMusic => _playing;

  /// Alle kurzen Töne, die gespielt wurden (für Tests).
  final List<String> playedEffects = [];

  /// Einstellungen dieses Geräts lesen.
  Future<void> load() async {
    final settings = this.settings;
    if (settings == null) return;
    _enabled = await settings.soundOn();
    _musicAllowed = await settings.musicAllowed();
    _apply();
    notifyListeners();
  }

  Future<void> setEnabled(bool on) async {
    _enabled = on;
    _apply();
    notifyListeners();
    await settings?.setSoundOn(on);
  }

  Future<void> setMusicAllowed(bool on) async {
    _musicAllowed = on;
    _apply();
    notifyListeners();
    await settings?.setMusicAllowed(on);
  }

  /// Kurzer Ton, zum Beispiel `sound.correct`. Still, wenn der Ton aus ist.
  void effect(String key) {
    if (!_enabled) return;
    playedEffects.add(key);
    playEffect(key);
  }

  /// Musik, die der Bildschirm im Vordergrund möchte (`null` = keine).
  void music(String? key) {
    _wanted = key;
    _pauseTimer?.cancel();
    if (key == null && pauseDelay > Duration.zero) {
      _pauseTimer = Timer(pauseDelay, _apply);
    } else {
      _apply();
    }
  }

  /// App im Hintergrund (anderes Programm, Bildschirm aus): Musik pausiert.
  void setInBackground(bool value) {
    _inBackground = value;
    _apply();
  }

  /// Nach einem Antippen. Browser erlauben Ton erst, wenn jemand auf die
  /// Seite getippt hat; dann wird die Musik hier nachgeholt.
  void unlock() {}

  void _apply() {
    final target = _enabled && _musicAllowed && !_inBackground ? _wanted : null;
    if (target == _playing) return;
    _playing = target;
    if (target == null) {
      pauseMusic();
    } else if (target == _loaded) {
      resumeMusic();
    } else {
      _loaded = target;
      startMusic(target);
    }
  }

  /// Musik von vorn starten (in Schleife).
  @protected
  void startMusic(String key) {}

  @protected
  void pauseMusic() {}

  /// Pausierte Musik an derselben Stelle weiterspielen.
  @protected
  void resumeMusic() {}

  @protected
  void playEffect(String key) {}

  @override
  void dispose() {
    _pauseTimer?.cancel();
    super.dispose();
  }
}
