import 'dart:math';

import 'arcade_round.dart';

enum NutThingType { nut, mushroom, log, hollow }

/// Ein Ding am Waldweg: Nuss, Hindernis (Pilz, Baumstamm) oder Versteck.
class NutThing {
  NutThing({required this.x, required this.y, required this.type});

  double x;

  /// Mitte (Nüsse) oder Boden (alles andere).
  final double y;
  final NutThingType type;
  bool taken = false;

  double get w => switch (type) {
    NutThingType.nut => 0.04,
    NutThingType.mushroom => 0.06,
    NutThingType.log => 0.11,
    NutThingType.hollow => 0.12,
  };

  double get h => switch (type) {
    NutThingType.nut => 0.04,
    NutThingType.mushroom => 0.065,
    NutThingType.log => 0.06,
    NutThingType.hollow => 0.14,
  };

  bool get obstacle => type == NutThingType.mushroom || type == NutThingType.log;
}

/// Regeln von „Emmas Nussjagd“ (Spar-Insel), ohne Aussehen.
///
/// Emma läuft durch den Herbstwald. Antippen = springen (in der Luft noch
/// einmal). Nüsse kommen in die Backen, am Versteck im Baumstumpf werden sie
/// für den Winter sicher eingelagert. Stößt Emma an einen Pilz oder Baumstamm,
/// kostet das ein Herz und die Hälfte der Nüsse in den Backen fällt herunter.
/// Lernen nebenbei: Vorrat anlegen, Sparen für später.
class NutRunGame extends ArcadeRound {
  NutRunGame({required super.width, Random? random}) : _random = random ?? Random();

  final Random _random;

  static const ground = 0.86;
  static const gravity = 3.4;
  static const jumpSpeed = -1.35;
  static const doubleJumpSpeed = -1.1;
  static const emmaW = 0.065;
  static const emmaH = 0.085;

  double get emmaX => min(width * 0.26, 0.3);

  /// Füße von Emma (oben ist kleiner).
  double y = ground;
  double vy = 0;
  int _jumps = 0;
  int carried = 0;
  int stored = 0;
  int collected = 0;
  int dropped = 0;
  final things = <NutThing>[];
  double _sinceSpawn = 0.4;
  int _spawned = 0;

  bool get onGround => y >= ground && vy >= 0;

  @override
  int get score => stored + carried;
  @override
  int get level => 1 + collected ~/ 12;

  double get speed => min(0.3 * (1 + 0.08 * (level - 1)), 0.62);
  double get spacing => max(0.62 - 0.03 * (level - 1), 0.42);

  void jump() {
    if (over) return;
    started = true;
    if (onGround) {
      vy = jumpSpeed;
      _jumps = 1;
    } else if (_jumps < 2) {
      vy = doubleJumpSpeed;
      _jumps = 2;
    }
  }

  @override
  void update(double dt) {
    vy += gravity * dt;
    y += vy * dt;
    if (y >= ground) {
      y = ground;
      vy = 0;
      _jumps = 0;
    }
    for (final t in things) {
      t.x -= speed * dt;
    }
    things.removeWhere((t) => t.x < -0.15);
    _sinceSpawn += speed * dt;
    if (_sinceSpawn >= spacing) {
      _sinceSpawn = _random.nextDouble() * 0.12;
      _spawn(width + 0.1);
    }
    _touch();
  }

  void _spawn(double x) {
    _spawned++;
    if (_spawned % 7 == 0) {
      things.add(NutThing(x: x, y: ground, type: NutThingType.hollow));
      return;
    }
    final type = level >= 2 && _random.nextBool() ? NutThingType.log : NutThingType.mushroom;
    things.add(NutThing(x: x, y: ground, type: type));
    // Nüsse im Bogen über dem Hindernis und am Boden davor.
    for (var i = 0; i < 3; i++) {
      things.add(
        NutThing(x: x - 0.08 + i * 0.08, y: ground - 0.14 - sin((i + 0.5) / 3 * pi) * 0.08, type: NutThingType.nut),
      );
    }
    if (_random.nextBool()) {
      things.add(NutThing(x: x + 0.22, y: ground - 0.03, type: NutThingType.nut));
    }
  }

  void _touch() {
    final left = emmaX - emmaW / 2, right = emmaX + emmaW / 2;
    final top = y - emmaH, bottom = y;
    for (final t in things) {
      if (t.taken) continue;
      final tl = t.x - t.w / 2, tr = t.x + t.w / 2;
      if (tr < left || tl > right) continue;
      switch (t.type) {
        case NutThingType.nut:
          if (t.y + t.h / 2 > top && t.y - t.h / 2 < bottom) {
            t.taken = true;
            carried++;
            collected++;
            events.add(ArcadeEvent.coin);
          }
        case NutThingType.hollow:
          t.taken = true;
          if (carried > 0) {
            stored += carried;
            carried = 0;
            events.add(ArcadeEvent.saved);
          }
        case NutThingType.mushroom:
        case NutThingType.log:
          // Etwas Spielraum, damit knappe Sprünge zählen.
          if (bottom > t.y - t.h + 0.012) {
            t.taken = true;
            if (hurt()) {
              final lost = (carried + 1) ~/ 2;
              carried -= lost;
              dropped += lost;
            }
          }
      }
    }
  }
}
