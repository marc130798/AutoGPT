import 'dart:math';

import 'arcade_round.dart';

/// Ein Hindernis: unten ein Mast, oben ein hängendes Fischernetz, dazwischen
/// die Lücke, durch die Mia fliegt.
class GullObstacle {
  GullObstacle({required this.x, required this.gapCenter, required this.gapHalf, this.sway = 0, this.phase = 0});

  double x;
  final double gapCenter;
  final double gapHalf;

  /// Ab Stufe 3 schaukelt die Lücke leicht auf und ab.
  final double sway;
  final double phase;
  bool passed = false;

  double centerAt(double time) => gapCenter + sin(time * 1.6 + phase) * sway;
}

/// Ein Taler oder ein Sparglas im Flug.
class GullPickup {
  GullPickup({required this.x, required this.y, this.jar = false});

  double x;
  final double y;

  /// `true` = Sparglas: Das Geld aus der Tasche ist darin sicher.
  final bool jar;
  bool taken = false;
}

/// Regeln von „Mias Möwenflug“, ohne Aussehen (darum testbar).
///
/// Koordinaten: Höhe des Spielfelds = 1, Breite = [width]. Antippen lässt Mia
/// hochflattern, sonst sinkt sie. Taler kommen in die Tasche. Stößt Mia an
/// einen Mast, ein Netz oder ins Wasser, kostet das ein Herz und die Hälfte
/// der Taler in der Tasche fallen ins Meer. Was im Sparglas liegt, ist sicher
/// (das ist das Lernen nebenbei). Alle 10 Taler wird es schneller.
class GullFlightGame extends ArcadeRound {
  GullFlightGame({required super.width, Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Mia fliegt im linken Drittel, damit man die Hindernisse kommen sieht.
  double get birdX => min(width * 0.28, 0.32);

  static const gravity = 2.1;
  static const flapSpeed = -0.78;
  static const maxFall = 1.1;
  static const sea = 0.9;
  static const birdRadius = 0.035;
  static const pickupRadius = 0.03;
  static const obstacleWidth = 0.075;
  static const hearts = ArcadeRound.hearts;

  double y = 0.45;
  double vy = 0;
  int pocket = 0;
  int saved = 0;

  /// Alle eingesammelten Taler (für die Stufe).
  int collected = 0;
  int dropped = 0;
  final obstacles = <GullObstacle>[];
  final pickups = <GullPickup>[];
  int _spawned = 0;

  @override
  int get score => saved + pocket;
  @override
  int get level => 1 + collected ~/ 10;
  double get speed => min(0.24 * (1 + 0.1 * (level - 1)), 0.5);
  double get gapHalf => max(0.18 - 0.012 * (level - 1), 0.115);
  double get spacing => max(0.62 - 0.02 * (level - 1), 0.48);
  void flap() {
    if (over) return;
    started = true;
    vy = flapSpeed;
    emit(ArcadeEvent.action);
  }

  @override
  void idle(double dt) => y = 0.45 + sin(time * 3) * 0.015;

  @override
  void update(double dt) {
    vy = min(vy + gravity * dt, maxFall);
    y += vy * dt;
    if (y < 0.04) {
      y = 0.04;
      vy = max(vy, 0);
    }

    final move = speed * dt;
    for (final o in obstacles) {
      o.x -= move;
    }
    for (final p in pickups) {
      p.x -= move;
    }
    obstacles.removeWhere((o) => o.x < -obstacleWidth);
    pickups.removeWhere((p) => p.x < -0.1 || p.taken);
    // Das erste Hindernis kommt mit etwas Abstand, damit man sich einfliegen kann.
    if (obstacles.isEmpty) {
      _spawn(width + 0.45);
    } else if (obstacles.last.x < width + 0.1 - spacing) {
      _spawn(obstacles.last.x + spacing);
    }

    _pickups();
    _hits();
  }

  void _spawn(double x) {
    _spawned++;
    final half = gapHalf;
    final center = 0.22 + half * 0.6 + _random.nextDouble() * (sea - 0.22 - half * 1.6 - 0.1);
    final sway = level >= 3 ? min(0.03 + 0.01 * (level - 3), 0.07) : 0.0;
    obstacles.add(
      GullObstacle(x: x, gapCenter: center, gapHalf: half, sway: sway, phase: _random.nextDouble() * pi * 2),
    );
    // Jedes sechste Hindernis trägt ein Sparglas in der Lücke, sonst ein Taler.
    pickups.add(GullPickup(x: x + obstacleWidth / 2, y: center, jar: _spawned % 6 == 0));
    // Dazwischen ein kleiner Bogen aus Talern.
    final arc = 2 + _random.nextInt(2);
    final arcY = 0.25 + _random.nextDouble() * 0.5;
    for (var i = 0; i < arc; i++) {
      pickups.add(GullPickup(x: x + spacing * (0.35 + i * 0.13), y: arcY - sin((i + 0.5) / arc * pi) * 0.06));
    }
  }

  void _pickups() {
    for (final p in pickups) {
      if (p.taken) continue;
      final dx = p.x - birdX, dy = p.y - y;
      if (dx * dx + dy * dy > pow(birdRadius + pickupRadius, 2)) continue;
      p.taken = true;
      if (p.jar) {
        if (pocket > 0) {
          saved += pocket;
          events.add(ArcadeEvent.saved);
        }
        pocket = 0;
      } else {
        pocket++;
        collected++;
        events.add(ArcadeEvent.coin);
      }
    }
  }

  void _hits() {
    if (y >= sea - birdRadius) {
      if (!safe) events.add(ArcadeEvent.splash);
      _hurt();
      y = sea - birdRadius - 0.01;
      vy = flapSpeed * 1.1;
      return;
    }
    for (final o in obstacles) {
      if (birdX + birdRadius < o.x || birdX - birdRadius > o.x + obstacleWidth) {
        if (!o.passed && o.x + obstacleWidth < birdX - birdRadius) o.passed = true;
        continue;
      }
      final c = o.centerAt(time);
      if (y - birdRadius < c - o.gapHalf || y + birdRadius > c + o.gapHalf) {
        _hurt();
        return;
      }
    }
  }

  void _hurt() {
    if (!hurt()) return;
    final lost = (pocket + 1) ~/ 2;
    pocket -= lost;
    dropped += lost;
  }
}
