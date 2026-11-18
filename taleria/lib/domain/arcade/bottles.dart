import 'dart:math';

import 'arcade_round.dart';

/// Eine Flasche, die kurz aus dem Meer auftaucht und wieder versinkt.
class WishBottle {
  WishBottle({
    required this.x,
    required this.y,
    required this.kind,
    required this.born,
    required this.life,
    this.trick,
  });

  final double x;
  final double y;

  /// Was drin ist, zum Beispiel `regenjacke` oder `glitzerbrille`. Bild `item.<kind>`.
  final String kind;

  /// Wann sie auftaucht und wie lange sie oben bleibt (Sekunden).
  final double born;
  final double life;

  /// Werbe-Trick auf einem Wunsch (`nur_heute`, `alle_haben`, `gratis`), sonst `null`.
  final String? trick;

  /// Angetippt: `true` richtig (gebraucht), `false` falsch (Wunsch), `null` noch nicht.
  bool? tapped;
  double tappedAt = 0;

  static const rise = 0.25;
  static const showResult = 0.4;

  /// Wie weit sie aus dem Wasser ragt, 0 bis 1.
  double shown(double time) {
    if (tapped != null) return 1;
    final a = (time - born) / rise, b = (born + life - time) / rise;
    return min(1.0, max(0.0, min(a, b)));
  }

  bool isGone(double time) => tapped != null ? time - tappedAt > showResult : time > born + life;
}

/// Regeln von „Elsas Wunsch-Flaschen“ (Wunschinsel), seit 18.11.2026 statt
/// des Flaschenfängers (Marc: Lieferboot und Flaschenfänger spielten sich gleich).
///
/// Flaschen tauchen an verschiedenen Stellen im Meer kurz auf. Tippe schnell
/// die Flaschen mit Dingen, die man wirklich braucht. Wer einen Wunsch antippt
/// oder etwas Nötiges versinken lässt, verliert ein Herz. Ab Stufe 3 rufen
/// manche Wünsche Werbe-Tricks („Nur heute!“). Lernen nebenbei: Brauchen oder
/// Wollen, und Werbung durchschauen.
class BottleGame extends ArcadeRound {
  BottleGame({required super.width, Random? random}) : random = random ?? Random();

  final Random random;

  static const needs = [
    'wasserflasche',
    'regenjacke',
    'broetchen',
    'aepfel',
    'sonnenhut',
    'zahnbuerste',
    'schulranzen',
  ];
  static const wishes = ['bonbons', 'glitzerbrille', 'fernglas', 'spielzeugauto', 'sammelkarten'];
  static const tricks = ['nur_heute', 'alle_haben', 'gratis'];

  /// Bereich, in dem Flaschen auftauchen (Höhe 1): unter der Anzeige, über dem Strand
  /// des Hintergrundbilds (`game.bottles.background`, Sand ab etwa 0,74).
  static const top = 0.24;
  static const bottom = 0.68;
  static const radius = 0.075;

  final bottles = <WishBottle>[];
  int points = 0;
  int wishesCaught = 0;
  int wishesLetGo = 0;
  int needsMissed = 0;
  double _nextSpawn = 0.3;

  static bool isNeed(String kind) => needs.contains(kind);

  @override
  int get score => points;
  @override
  int get level => 1 + points ~/ 8;

  double get lifetime => max(1.9 - 0.15 * (level - 1), 0.95);
  double get spawnGap => max(1.0 - 0.08 * (level - 1), 0.45);
  int get maxOnScreen => min(2 + level ~/ 2, 4);

  /// Antippen an einer Stelle des Spielfelds (Höhe 1).
  void tap(double x, double y) {
    if (over) return;
    if (!started) {
      started = true;
      return;
    }
    WishBottle? hit;
    var best = double.infinity;
    for (final b in bottles) {
      if (b.tapped != null || b.shown(time) < 0.3) continue;
      final d = sqrt(pow(b.x - x, 2) + pow(b.y - y, 2));
      if (d < radius * 1.3 && d < best) {
        best = d;
        hit = b;
      }
    }
    if (hit == null) return;
    emit(ArcadeEvent.action);
    hit.tappedAt = time;
    if (isNeed(hit.kind)) {
      hit.tapped = true;
      points++;
      emit(ArcadeEvent.coin);
      if (points % 5 == 0) emit(ArcadeEvent.good);
    } else {
      hit.tapped = false;
      wishesCaught++;
      emit(ArcadeEvent.wrong);
      _hurtLater = true;
    }
  }

  bool _hurtLater = false;

  @override
  void update(double dt) {
    if (_hurtLater) {
      _hurtLater = false;
      hurt();
    }
    for (final b in bottles.where((b) => b.tapped == null && time > b.born + b.life)) {
      if (isNeed(b.kind)) {
        needsMissed++;
        hurt();
      } else {
        wishesLetGo++;
      }
      b.tapped = null;
    }
    bottles.removeWhere((b) => b.isGone(time));
    if (time >= _nextSpawn) {
      _nextSpawn = time + spawnGap * (0.8 + random.nextDouble() * 0.4);
      if (bottles.length < maxOnScreen) _spawn();
    }
  }

  void _spawn() {
    for (var tries = 0; tries < 12; tries++) {
      final x = radius + random.nextDouble() * (width - 2 * radius);
      final y = top + random.nextDouble() * (bottom - top);
      if (bottles.any((b) => sqrt(pow(b.x - x, 2) + pow(b.y - y, 2)) < radius * 2.4)) continue;
      final need = random.nextDouble() < 0.55;
      final list = need ? needs : wishes;
      final kind = list[random.nextInt(list.length)];
      final trick = !need && level >= 3 && random.nextDouble() < 0.5 ? tricks[random.nextInt(tricks.length)] : null;
      bottles.add(WishBottle(x: x, y: y, kind: kind, born: time, life: lifetime, trick: trick));
      return;
    }
  }
}
