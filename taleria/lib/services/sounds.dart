import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local_settings.dart';

/// Musik im Hauptmenü, kurze Töne (richtige Antwort, Station geschafft),
/// Stimmen von Talo, Tala und Meister Taleron und kurzes Vibrieren bei Erfolgen.
///
/// Diese Klasse kennt nur die Regeln:
/// - Ton aus (Lautsprecher-Knopf des Kindes): alles still.
/// - Musik nicht erlaubt (Schalter im Leuchtturm): keine Musik, Töne ja.
/// - Stimmen nicht erlaubt (Schalter im Leuchtturm): keine Stimmen, sonst alles.
///   Es spricht immer nur eine Stimme; eine neue beendet die alte.
/// - Vibrieren nicht erlaubt (Schalter im Leuchtturm): kein Vibrieren, unabhängig vom Ton.
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
  bool _vibrationAllowed = true;
  bool _voicesAllowed = true;
  bool _inBackground = false;
  String? _wanted;
  String? _playing;
  String? _loaded;
  Timer? _pauseTimer;

  /// Ton an (Lautsprecher-Knopf auf der Startseite).
  bool get enabled => _enabled;

  /// Musik im Hauptmenü erlaubt (Schalter im Leuchtturm).
  bool get musicAllowed => _musicAllowed;

  /// Kurzes Vibrieren bei Erfolgen erlaubt (Schalter im Leuchtturm).
  bool get vibrationAllowed => _vibrationAllowed;

  /// Stimmen erlaubt (Schalter im Leuchtturm).
  bool get voicesAllowed => _voicesAllowed;

  /// Alle Sprachaufnahmen, die gespielt wurden (für Tests).
  final List<String> playedVoices = [];

  /// Wie oft vibriert wurde (für Tests).
  int vibrations = 0;

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
    _vibrationAllowed = await settings.vibrationAllowed();
    _voicesAllowed = await settings.voicesAllowed();
    _apply();
    notifyListeners();
  }

  Future<void> setEnabled(bool on) async {
    _enabled = on;
    if (!on) stopVoice();
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

  Future<void> setVoicesAllowed(bool on) async {
    _voicesAllowed = on;
    if (!on) stopVoice();
    notifyListeners();
    await settings?.setVoicesAllowed(on);
  }

  /// Ordner der Sprachaufnahmen (aufgenommen mit `tool/stimmen_aufnehmen.py`).
  static const voiceFolder = 'assets/audio/voice';

  /// Eine Sprachaufnahme abspielen, zum Beispiel `voice.talo.tap.1.mp3`.
  /// Still, wenn der Ton aus ist oder Stimmen nicht erlaubt sind; eine
  /// laufende Stimme hört dabei auf. Fehlt die Datei, bleibt es still.
  void voice(String file) {
    _queue.clear();
    _start(file);
  }

  /// Mehrere Aufnahmen nacheinander (zum Beispiel der Ausblick am Ende einer
  /// Insel). Fehlende Aufnahmen werden übersprungen.
  void voices(List<String> files) {
    _queue
      ..clear()
      ..addAll(files.where(hasVoice));
    if (_queue.isNotEmpty) _start(_queue.removeAt(0));
  }

  final List<String> _queue = [];

  void _start(String file) {
    if (!_enabled || !_voicesAllowed || !hasVoice(file)) return;
    playedVoices.add(file);
    _setDucked(true);
    playVoice('$voiceFolder/$file');
  }

  /// Welche Aufnahmen es gibt (aus `assets/audio/voice/stimmen.json`, beim
  /// Start geladen). `null` = unbekannt, dann wird alles versucht (Tests).
  Set<String>? knownVoices;

  /// Gibt es diese Aufnahme? Nicht jede Zeile hat eine Stimme (zum Beispiel
  /// Figuren ohne eigene Stimme).
  bool hasVoice(String file) => knownVoices?.contains(file) ?? true;

  /// Die laufende Stimme beenden (zum Beispiel beim Verlassen einer Seite).
  void stopVoice() {
    _queue.clear();
    stopVoiceAudio();
    _setDucked(false);
  }

  /// Musik leiser, solange eine Stimme spricht oder ein Film läuft
  /// (Marcs Test am 16.11.2026: „man hört die Stimmen beim Rauschen nicht“).
  bool get musicDucked => _voiceDucked || _filmDucked;
  bool _voiceDucked = false;
  bool _filmDucked = false;

  void _setDucked(bool on) {
    final before = musicDucked;
    _voiceDucked = on;
    if (musicDucked != before) duckMusic(musicDucked);
  }

  /// Ein Film läuft (mit eigenem Ton): Musik leiser, danach wieder normal.
  void setFilmPlaying(bool on) {
    final before = musicDucked;
    _filmDucked = on;
    if (musicDucked != before) duckMusic(musicDucked);
  }

  /// Die Stimme ist zu Ende (meldet die Unterklasse).
  @protected
  void voiceFinished() {
    if (_queue.isNotEmpty) {
      _start(_queue.removeAt(0));
    } else {
      _setDucked(false);
    }
  }

  /// Musik leiser stellen (`true`) oder wieder normal. Auf dem iPhone im
  /// Browser lässt sich die Lautstärke nicht ändern; dort sind die Dateien
  /// selbst leise.
  @protected
  void duckMusic(bool on) {}

  Future<void> setVibrationAllowed(bool on) async {
    _vibrationAllowed = on;
    notifyListeners();
    await settings?.setVibrationAllowed(on);
  }

  /// Kurzes Vibrieren bei einem Erfolg (Station geschafft). Im Browser auf
  /// dem iPhone ohne Wirkung, erst in der Store-App.
  void success() {
    if (!_vibrationAllowed) return;
    vibrations++;
    vibrate();
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

  @protected
  void vibrate() {}

  /// Pfad wie `assets/audio/voice/voice.talo.tap.1.mp3`.
  @protected
  void playVoice(String path) {}

  @protected
  void stopVoiceAudio() {}

  @override
  void dispose() {
    _pauseTimer?.cancel();
    super.dispose();
  }
}
