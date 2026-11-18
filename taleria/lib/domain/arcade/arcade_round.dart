import 'dart:math';

/// Was in einem Schritt passiert ist (für Töne und Effekte).
enum ArcadeEvent {
  coin,
  good,
  saved,
  wrong,
  hit,
  faster,
  over,

  /// Die Runde beginnt (erstes Antippen).
  start,

  /// Eine Aktion des Kindes: flattern, Haken fallen lassen, Bahn wechseln, springen.
  action,

  /// Etwas fällt ins Wasser (Haken, Möwe).
  splash,

  /// Unnützes gefangen (alter Stiefel).
  junk,

  /// Eine Muschel in der Nähe klappt auf oder zu.
  shell,
}

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
  final _queued = <ArcadeEvent>[];
  bool _announced = false;

  /// Ereignis außerhalb eines Schritts (beim Antippen); erscheint im nächsten Schritt.
  void emit(ArcadeEvent e) => _queued.add(e);

  bool get over => lives <= 0;
  bool get safe => time < safeUntil;
  int get score;
  int get level;

  /// Einen Zeitschritt weiter (Sekunden, höchstens 0,05 auf einmal).
  void step(double dt) {
    events
      ..clear()
      ..addAll(_queued);
    _queued.clear();
    if (over) return;
    if (started && !_announced) {
      _announced = true;
      events.insert(0, ArcadeEvent.start);
    }
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
  /// Mit `always` zählt es auch in der Schutzzeit (eigene falsche Entscheidung
  /// statt Zusammenstoß, zum Beispiel falsche Ware im Lieferboot).
  bool hurt({bool always = false}) {
    if ((safe && !always) || over) return false;
    lives--;
    safeUntil = time + safeTime;
    events.add(lives <= 0 ? ArcadeEvent.over : ArcadeEvent.hit);
    return true;
  }
}
