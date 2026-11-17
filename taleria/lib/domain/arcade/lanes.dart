import 'dart:math';

import 'arcade_round.dart';

/// Ein Ding, das in einer der drei Bahnen von oben herunterkommt.
class LaneThing {
  LaneThing({required this.lane, required this.y, required this.kind});

  final int lane;
  double y;

  /// Was es ist, zum Beispiel `aepfel`, `rock` oder `bonbons`.
  final String kind;
  bool caught = false;
}

/// Drei Bahnen, unten der Fänger (Boot oder Kescher). Antippen links oder
/// rechts wechselt die Bahn. Was in der Bahn des Fängers unten ankommt, ist
/// gefangen. Alle Spiele dieser Art zählen Punkte für gute Fänge.
abstract class LaneGame extends ArcadeRound {
  LaneGame({required super.width, Random? random}) : random = random ?? Random();

  final Random random;

  static const lanes = 3;
  static const catchY = 0.78;
  static const catchRange = 0.05;

  int lane = 1;
  late double catcherX = laneX(1);
  final things = <LaneThing>[];
  int points = 0;
  double _sinceSpawn = 1;

  @override
  int get score => points;
  @override
  int get level => 1 + points ~/ 6;

  double get speed => min(0.26 * (1 + 0.1 * (level - 1)), 0.6);
  double get spacing => max(0.34 - 0.015 * (level - 1), 0.2);

  double laneX(int l) => width * (l + 0.5) / lanes;

  /// Eine Bahn nach links (-1) oder rechts (1).
  void move(int direction) {
    if (over) return;
    started = true;
    lane = (lane + direction).clamp(0, lanes - 1);
  }

  /// Direkt in eine Bahn (Tippen auf die Bahn).
  void moveTo(int target) {
    if (over) return;
    started = true;
    lane = target.clamp(0, lanes - 1);
  }

  String nextKind();
  void onCatch(LaneThing thing);
  void onMiss(LaneThing thing) {}

  @override
  void update(double dt) {
    catcherX += (laneX(lane) - catcherX) * min(1, dt * 16);
    for (final t in things) {
      t.y += speed * dt;
      if (!t.caught && t.lane == lane && (t.y - catchY).abs() < catchRange) {
        t.caught = true;
        onCatch(t);
      }
    }
    for (final t in things.where((t) => t.y > 1.05 && !t.caught)) {
      onMiss(t);
    }
    things.removeWhere((t) => t.y > 1.05 || t.caught);
    _sinceSpawn += speed * dt;
    if (_sinceSpawn >= spacing) {
      _sinceSpawn = 0;
      _spawn();
    }
  }

  void _spawn() {
    final first = random.nextInt(lanes);
    things.add(LaneThing(lane: first, y: -0.08, kind: nextKind()));
    // Ab Stufe 3 kommen manchmal zwei Dinge nebeneinander.
    if (level >= 3 && random.nextDouble() < 0.35) {
      final second = (first + 1 + random.nextInt(lanes - 1)) % lanes;
      things.add(LaneThing(lane: second, y: -0.08, kind: nextKind()));
    }
  }
}

/// Ein Kunde im Lieferboot und was er haben will.
class DeliveryCustomer {
  const DeliveryCustomer(this.speaker, this.wants);

  /// Figur (`bruno`, `greta` …).
  final String speaker;

  /// Ware (`fisch`, `aepfel` …), Bild `item.<ware>`.
  final String wants;
}

/// Regeln von „Ottis Lieferboot“ (Tauschinsel): Waren treiben den Fluss
/// hinunter. Fang, was der Kunde gerade will (3 Stück, dann kommt der
/// nächste). Eine falsche Ware oder ein Stein kostet ein Herz. Lernen
/// nebenbei: Wer braucht was? Beim Tauschen zählt, was der andere will.
class DeliveryGame extends LaneGame {
  DeliveryGame({required super.width, super.random});

  static const goods = ['fisch', 'aepfel', 'seil', 'eimer'];
  static const customers = [
    DeliveryCustomer('bruno', 'fisch'),
    DeliveryCustomer('greta', 'aepfel'),
    DeliveryCustomer('haendler', 'seil'),
    DeliveryCustomer('olga', 'eimer'),
  ];
  static const perCustomer = 3;

  int customer = 0;
  int got = 0;
  int wrongGoods = 0;

  DeliveryCustomer get current => customers[customer % customers.length];

  @override
  String nextKind() {
    final r = random.nextDouble();
    if (r < min(0.18 + 0.03 * (level - 1), 0.32)) return 'rock';
    if (r < 0.62) return current.wants;
    final others = goods.where((g) => g != current.wants).toList();
    return others[random.nextInt(others.length)];
  }

  @override
  void onCatch(LaneThing thing) {
    if (thing.kind == 'rock') {
      hurt();
    } else if (thing.kind == current.wants) {
      points++;
      got++;
      events.add(ArcadeEvent.coin);
      if (got == perCustomer) {
        got = 0;
        customer++;
        events.add(ArcadeEvent.good);
      }
    } else {
      wrongGoods++;
      events.add(ArcadeEvent.wrong);
      hurt();
    }
  }
}

/// Regeln von „Elsas Flaschenfänger“ (Wunschinsel): Flaschenpost treibt
/// heran, in jeder ein Ding. Fang, was man wirklich braucht; Wünsche lässt
/// man vorbeischwimmen. Ein gefangener Wunsch kostet ein Herz. Lernen
/// nebenbei: Brauchen oder Wollen.
class BottleGame extends LaneGame {
  BottleGame({required super.width, super.random});

  static const needs = ['wasserflasche', 'regenjacke', 'broetchen', 'aepfel', 'sonnenhut'];
  static const wishes = ['bonbons', 'glitzerbrille', 'fernglas'];

  int wishesCaught = 0;
  int wishesLetGo = 0;

  static bool isNeed(String kind) => needs.contains(kind);

  @override
  String nextKind() {
    final list = random.nextDouble() < 0.55 ? needs : wishes;
    return list[random.nextInt(list.length)];
  }

  @override
  void onCatch(LaneThing thing) {
    if (isNeed(thing.kind)) {
      points++;
      events.add(ArcadeEvent.coin);
      if (points % 5 == 0) events.add(ArcadeEvent.good);
    } else {
      wishesCaught++;
      events.add(ArcadeEvent.wrong);
      hurt();
    }
  }

  @override
  void onMiss(LaneThing thing) {
    if (!isNeed(thing.kind)) wishesLetGo++;
  }
}
