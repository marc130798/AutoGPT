import 'dart:math';

/// Was in einem Schritt passiert ist (für Töne und Effekte).
enum ArcadeEvent { coin, good, saved, wrong, hit, faster, over }

/// Gemeinsamer Ablauf aller richtigen Spiele: 3 Herzen, nach einem Treffer
/// kurz geschützt, es startet erst beim ersten Antippen (kein Countdown).
///
/// Koordinaten: Höhe des Spielfelds = 1, Breite = [width] (Hochformat, also
/// kleiner als 1).
abstract class ArcadeRound {
  ArcadeRound({required this.width});

  final double width;

  static const hearts = 3;

  /// Sekunden ohne neuen Schaden nach einem Treffer.
  static const safeTime = 1.6;

  double time = 0;
  bool started = false;
  int lives = hearts;
  double safeUntil = 0;
  final events = <ArcadeEvent>[];

  bool get over => lives <= 0;
  bool get safe => time < safeUntil;
  int get score;
  int get level;

  /// Einen Zeitschritt weiter (Sekunden, höchstens 0,05 auf einmal).
  void step(double dt) {
    events.clear();
    if (over) return;
    dt = min(dt, 0.05);
    time += dt;
    if (!started) {
      idle(dt);
      return;
    }
    final before = level;
    update(dt);
    if (level > before && !over) events.add(ArcadeEvent.faster);
  }

  /// Vor dem ersten Antippen: nur leichtes Schweben, nichts kommt.
  void idle(double dt) {}

  void update(double dt);

  /// Ein Herz weg (nicht, solange noch geschützt). `true`, wenn es zählte.
  bool hurt() {
    if (safe || over) return false;
    lives--;
    safeUntil = time + safeTime;
    events.add(lives <= 0 ? ArcadeEvent.over : ArcadeEvent.hit);
    return true;
  }
}
