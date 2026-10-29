import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'map_painters.dart';

/// Tiere im Meer der Karte, nur zum Spaß (Marcs Wunsch am 29.10.2026: die
/// App soll lebendiger wirken). Antippen: Der Fisch springt, der Wal bläst
/// eine Fontäne, der Delfin macht einen Bogen. Es gibt nichts zu gewinnen.
enum CritterKind { fish, whale, dolphin }

class SeaCritter extends StatefulWidget {
  const SeaCritter({super.key, required this.kind, required this.clock});

  static const size = Size(84, 64);

  final CritterKind kind;

  /// Uhr der Karte (wellt das Tier leicht, steht still bei reduzierter Bewegung).
  final Animation<double> clock;

  @override
  State<SeaCritter> createState() => _SeaCritterState();
}

class _SeaCritterState extends State<SeaCritter> with SingleTickerProviderStateMixin {
  late final AnimationController _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void dispose() {
    _jump.dispose();
    super.dispose();
  }

  void _tap() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _jump.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: switch (widget.kind) {
        CritterKind.fish => l10n.critterFish,
        CritterKind.whale => l10n.critterWhale,
        CritterKind.dolphin => l10n.critterDolphin,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: SizedBox.fromSize(
          size: SeaCritter.size,
          child: CustomPaint(
            painter: _CritterPainter(kind: widget.kind, clock: widget.clock, jump: _jump),
          ),
        ),
      ),
    );
  }
}

class _CritterPainter extends CustomPainter {
  _CritterPainter({required this.kind, required this.clock, required this.jump})
    : super(repaint: Listenable.merge([clock, jump]));

  final CritterKind kind;
  final Animation<double> clock;
  final Animation<double> jump;

  static const _foam = Color(0xFFF4FBFF);

  @override
  void paint(Canvas canvas, Size size) {
    final t = sceneSeconds(clock);
    final j = jump.value;
    final active = jump.isAnimating || (j > 0 && j < 1);
    final water = size.height * 0.72;
    final center = Offset(size.width / 2, water);

    // Ringe im Wasser zeigen, dass hier etwas ist.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _foam.withValues(alpha: 0.55);
    for (final k in [0.0, 0.5]) {
      final p = cycle(t, 12, k);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 20 + p * 46, height: 6 + p * 12),
        ring..color = _foam.withValues(alpha: 0.5 * (1 - p)),
      );
    }

    switch (kind) {
      case CritterKind.fish:
        _fish(canvas, size, water, t, active ? j : null);
      case CritterKind.whale:
        _whale(canvas, size, water, t, active ? j : null);
      case CritterKind.dolphin:
        _dolphin(canvas, size, water, t, active ? j : null);
    }
  }

  /// Orangener Fisch: unter Wasser ein Schatten, beim Antippen ein Sprung im Bogen.
  void _fish(Canvas canvas, Size size, double water, double t, double? j) {
    final body = Paint()..color = const Color(0xFFF08A24);
    if (j == null) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width / 2 + osc(t, 9) * 6, water + 6), width: 22, height: 9),
        Paint()..color = const Color(0xFFF08A24).withValues(alpha: 0.45),
      );
      return;
    }
    final x = size.width * (0.15 + 0.7 * j);
    final y = water - sin(j * pi) * 46;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-cos(j * pi) * 0.9);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 24, height: 12), body);
    canvas.drawPath(
      Path()
        ..moveTo(-10, 0)
        ..lineTo(-19, -7)
        ..lineTo(-19, 7)
        ..close(),
      body,
    );
    canvas.drawCircle(const Offset(6, -2), 1.8, Paint()..color = const Color(0xFF1B2A3A));
    canvas.restore();
    _splash(canvas, Offset(size.width * 0.15, water), j, 0, 0.25);
    _splash(canvas, Offset(size.width * 0.85, water), j, 0.75, 1);
  }

  /// Wal: sein Rücken schaut heraus, beim Antippen bläst er eine Fontäne.
  void _whale(Canvas canvas, Size size, double water, double t, double? j) {
    final bob = osc(t, 7) * 1.5 - (j == null ? 0 : sin(j * pi) * 3);
    final back = Path()
      ..moveTo(size.width * 0.18, water)
      ..quadraticBezierTo(size.width * 0.45, water - 22 + bob, size.width * 0.82, water)
      ..close();
    canvas.drawPath(back, Paint()..color = const Color(0xFF3E5C7A));
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.3, water - 6 + bob)
        ..quadraticBezierTo(size.width * 0.45, water - 16 + bob, size.width * 0.6, water - 10 + bob),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.35),
    );
    if (j == null) return;
    final spout = Offset(size.width * 0.42, water - 18 + bob);
    final drop = Paint()..color = const Color(0xFFDDF2FF);
    for (var k = 0; k < 9; k++) {
      final spread = (k - 4) / 4;
      final lift = sin(j * pi) * (38 + 8 * (1 - spread.abs()));
      canvas.drawCircle(spout + Offset(spread * 16 * j, -lift), 3.2 - spread.abs(), drop);
    }
  }

  /// Delfin: eine Flosse zieht durchs Wasser, beim Antippen springt er im Bogen.
  void _dolphin(Canvas canvas, Size size, double water, double t, double? j) {
    final grey = Paint()..color = const Color(0xFF7D93A8);
    if (j == null) {
      final x = size.width / 2 + osc(t, 8) * 10;
      canvas.drawPath(
        Path()
          ..moveTo(x - 7, water)
          ..quadraticBezierTo(x - 1, water - 16, x + 6, water - 13)
          ..quadraticBezierTo(x + 3, water - 6, x + 7, water)
          ..close(),
        grey,
      );
      return;
    }
    final x = size.width * (0.1 + 0.8 * j);
    final y = water - sin(j * pi) * 40;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-cos(j * pi) * 0.8);
    canvas.drawPath(
      Path()
        ..moveTo(-18, 0)
        ..quadraticBezierTo(0, -11, 18, -1)
        ..quadraticBezierTo(0, 7, -18, 0)
        ..close(),
      grey,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-2, -7)
        ..lineTo(-7, -15)
        ..lineTo(4, -8)
        ..close(),
      grey,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-16, 0)
        ..lineTo(-24, -6)
        ..lineTo(-23, 6)
        ..close(),
      grey,
    );
    canvas.drawCircle(const Offset(11, -3), 1.6, Paint()..color = const Color(0xFF1B2A3A));
    canvas.restore();
    _splash(canvas, Offset(size.width * 0.1, water), j, 0, 0.25);
    _splash(canvas, Offset(size.width * 0.9, water), j, 0.75, 1);
  }

  /// Spritzer zwischen [from] und [to] der Sprung-Zeit.
  void _splash(Canvas canvas, Offset at, double j, double from, double to) {
    if (j < from || j > to) return;
    final p = (j - from) / (to - from);
    final drop = Paint()..color = _foam.withValues(alpha: 1 - p);
    for (var k = 0; k < 5; k++) {
      final a = pi * (0.15 + 0.7 * k / 4);
      canvas.drawCircle(at + Offset(cos(a) * 14 * p, -sin(a) * 16 * p), 2.4, drop);
    }
  }

  @override
  bool shouldRepaint(_CritterPainter old) => old.kind != kind;
}
