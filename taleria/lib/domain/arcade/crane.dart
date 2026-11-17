import 'dart:math';

import 'arcade_round.dart';

/// Ein Ding im Hafenbecken: ein Geldsack (1, 2 oder 5 Taler) oder ein alter
/// Stiefel (Wert 0).
class CraneItem {
  CraneItem({required this.x, required this.value, required this.phase});

  double x;
  final int value;
  final double phase;

  bool get boot => value == 0;
}

/// Regeln von „Bootsbauers Kran“ (Hafen), ohne Aussehen.
///
/// Der Haken fährt oben am Kran hin und her. Antippen lässt ihn ins Wasser
/// fallen; was darunter schwimmt, hängt dran. Eine Bestellung verlangt genau
/// so viele Taler (zum Beispiel 8). Wer genau trifft, liefert und bekommt die
/// Taler als Punkte. Zu viel oder ein Stiefel kostet ein Herz (das Lernen
/// nebenbei: Beträge im Kopf zusammenzählen). Alle 2 Lieferungen schneller.
class CraneGame extends ArcadeRound {
  CraneGame({required super.width, Random? random}) : _random = random ?? Random() {
    target = _newTarget();
  }

  final Random _random;

  static const top = 0.36;
  static const water = 0.79;
  static const hookSpeed = 1.6;
  static const grabRange = 0.06;

  double trolley = 0.2;
  double _dir = 1;
  double hookY = top;

  /// 0 = oben, 1 = fällt, 2 = wird hochgezogen.
  int state = 0;
  CraneItem? held;
  final items = <CraneItem>[];

  late int target;
  int sum = 0;
  int delivered = 0;
  int points = 0;

  @override
  int get score => points;
  @override
  int get level => 1 + delivered ~/ 2;

  double get trolleySpeed => min(0.17 * (1 + 0.15 * (level - 1)), 0.42);
  double get itemSpeed => min(0.09 * (1 + 0.12 * (level - 1)), 0.22);
  double get bootChance => min(0.08 + 0.05 * (level - 1), 0.3);

  int _newTarget() => 3 + _random.nextInt(min(4 + level * 2, 13));

  void drop() {
    if (over) return;
    started = true;
    if (state == 0) state = 1;
  }

  @override
  void idle(double dt) => _moveItems(dt * 0.5);

  @override
  void update(double dt) {
    if (state == 0) {
      trolley += _dir * trolleySpeed * dt;
      if (trolley > width - 0.06) _dir = -1;
      if (trolley < 0.06) _dir = 1;
      trolley = trolley.clamp(0.06, width - 0.06);
    } else if (state == 1) {
      hookY += hookSpeed * dt;
      if (hookY >= water) {
        hookY = water;
        final near = items.where((i) => (i.x - trolley).abs() < grabRange).toList()
          ..sort((a, b) => (a.x - trolley).abs().compareTo((b.x - trolley).abs()));
        if (near.isNotEmpty) {
          held = near.first;
          items.remove(held);
        }
        state = 2;
      }
    } else {
      hookY -= hookSpeed * dt;
      if (hookY <= top) {
        hookY = top;
        state = 0;
        _resolve();
      }
    }
    _moveItems(dt);
  }

  void _moveItems(double dt) {
    for (final i in items) {
      i.x -= itemSpeed * dt;
    }
    items.removeWhere((i) => i.x < -0.08);
    if (items.isEmpty || items.last.x < width - 0.17) _spawn();
  }

  void _spawn() {
    final x = items.isEmpty ? width * 0.5 : max(items.last.x + 0.17, width + 0.06);
    final int value;
    if (started && _random.nextDouble() < bootChance) {
      value = 0;
    } else {
      // Kleine Säcke öfter, damit man jede Bestellung genau treffen kann.
      const values = [1, 1, 1, 2, 2, 5];
      value = values[_random.nextInt(values.length)];
    }
    items.add(CraneItem(x: x, value: value, phase: _random.nextDouble() * pi * 2));
  }

  void _resolve() {
    final item = held;
    held = null;
    if (item == null) return;
    if (item.boot) {
      events.add(ArcadeEvent.wrong);
      hurt();
      return;
    }
    sum += item.value;
    events.add(ArcadeEvent.coin);
    if (sum == target) {
      points += target;
      delivered++;
      sum = 0;
      events.add(ArcadeEvent.good);
      target = _newTarget();
    } else if (sum > target) {
      // Zu viel in der Kiste: Die Bestellung beginnt von vorn.
      sum = 0;
      events.add(ArcadeEvent.wrong);
      hurt();
    }
  }
}
