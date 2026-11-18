import 'dart:math';

import 'arcade_round.dart';

/// Eine Muschel am Meeresgrund: mal offen, mal zu.
class PearlShell {
  PearlShell({required this.x, required this.y, required this.phase});

  double x;
  final double y;
  final double phase;
  bool taken = false;

  /// Offen etwa die Hälfte der Zeit, im eigenen Takt.
  bool openAt(double time) => sin(time * 1.4 + phase) > -0.1;
}

/// Eine Qualle, die auf und ab schwebt.
class Jelly {
  Jelly({required this.x, required this.baseY, required this.phase, required this.amp});

  double x;
  final double baseY;
  final double phase;
  final double amp;

  double yAt(double time) => baseY + sin(time * 1.2 + phase) * amp;
}

/// Regeln vom „Perlentaucher“ (nach dem ersten Tauchgang), ohne Aussehen.
///
/// Tala taucht dem Finger hinterher. Offene Muscheln geben eine Perle,
/// geschlossene nichts. Quallen kosten ein Herz. Reiner Spaß als Belohnung
/// fürs Tauchen; es wird mit der Zeit voller.
class PearlDiveGame extends ArcadeRound {
  PearlDiveGame({required super.width, Random? random}) : _random = random ?? Random() {
    x = width * 0.3;
    _targetX = x;
  }

  final Random _random;

  static const bottom = 0.86;
  static const diverRadius = 0.04;
  static const swimSpeed = 0.75;

  late double x;
  double y = 0.45;
  late double _targetX;
  double _targetY = 0.45;
  int pearls = 0;
  int closedTouches = 0;
  final shells = <PearlShell>[];
  final jellies = <Jelly>[];
  double _sinceShell = 0.3;
  double _sinceJelly = 0;

  @override
  int get score => pearls;
  @override
  int get level => 1 + pearls ~/ 8;

  double get drift => min(0.11 * (1 + 0.12 * (level - 1)), 0.28);
  double get jellyGap => max(0.55 - 0.05 * (level - 1), 0.25);

  /// Wohin Tala schwimmen soll (Finger auf dem Bildschirm).
  void swimTo(double tx, double ty) {
    if (over) return;
    started = true;
    _targetX = tx.clamp(0.04, width - 0.04);
    _targetY = ty.clamp(0.16, bottom - 0.02);
  }

  @override
  void idle(double dt) => y = 0.45 + sin(time * 2) * 0.01;

  @override
  void update(double dt) {
    final dx = _targetX - x, dy = _targetY - y;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist > 0.001) {
      final stepLen = min(dist, swimSpeed * dt);
      x += dx / dist * stepLen;
      y += dy / dist * stepLen;
    }
    for (final s in shells) {
      s.x -= drift * dt;
    }
    for (final j in jellies) {
      j.x -= drift * 1.25 * dt;
    }
    shells.removeWhere((s) => s.x < -0.1);
    jellies.removeWhere((j) => j.x < -0.1);
    _sinceShell += drift * dt;
    if (_sinceShell > 0.2) {
      _sinceShell = 0;
      shells.add(
        PearlShell(
          x: width + 0.08,
          y: bottom - 0.01 - _random.nextDouble() * 0.04,
          phase: _random.nextDouble() * pi * 2,
        ),
      );
    }
    _sinceJelly += drift * dt;
    if (_sinceJelly > jellyGap) {
      _sinceJelly = 0;
      jellies.add(
        Jelly(
          x: width + 0.08,
          baseY: 0.25 + _random.nextDouble() * 0.45,
          phase: _random.nextDouble() * pi * 2,
          amp: 0.03 + _random.nextDouble() * (0.04 + 0.01 * level),
        ),
      );
    }
    _touch();
  }

  /// Muscheln in Talas Nähe, die gerade offen sind (für das Klappen).
  final _openNear = <PearlShell>{};

  void _touch() {
    for (final s in shells) {
      final near = (s.x - x).abs() < 0.14 && (s.y - y).abs() < 0.2;
      final open = s.openAt(time);
      if (near && !s.taken && open != _openNear.contains(s)) {
        // Nur das Zuklappen klingt, damit es nicht dauernd klickt.
        if (!open) events.add(ArcadeEvent.shell);
        open ? _openNear.add(s) : _openNear.remove(s);
      }
    }
    _openNear.removeWhere((s) => !shells.contains(s));
    for (final s in shells) {
      if (s.taken) continue;
      final dx = s.x - x, dy = s.y - y;
      if (dx * dx + dy * dy > 0.065 * 0.065) continue;
      if (s.openAt(time)) {
        s.taken = true;
        pearls++;
        events.add(ArcadeEvent.coin);
        if (pearls % 5 == 0) events.add(ArcadeEvent.good);
      }
    }
    for (final j in jellies) {
      final dx = j.x - x, dy = j.yAt(time) - y;
      if (dx * dx + dy * dy < pow(diverRadius + 0.035, 2)) {
        hurt();
        return;
      }
    }
  }
}
