import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/taleria_asset.dart';

/// Leben über dem Unterwasserbild (Marcs Wunsch am 17.11.2026 für die
/// Taucherfunde): Lichtstrahlen schimmern, Blasen steigen auf, ein paar
/// Fische schwimmen langsam vorbei, ganz hinten zieht ab und zu ein Wal.
/// Alles im Code, kein Video. Fängt kein Antippen ab. Ohne Bewegung
/// (reduziert oder in Tests) bleibt nur das stille Bild.
class UnderwaterLife extends StatefulWidget {
  const UnderwaterLife({super.key});

  @override
  State<UnderwaterLife> createState() => _UnderwaterLifeState();
}

/// Ein Fisch: Höhe (Anteil), Größe, Dauer einer Durchquerung, Versatz, Richtung.
typedef _Swimmer = ({double y, double size, double seconds, double offset, bool right});

class _UnderwaterLifeState extends State<UnderwaterLife> with SingleTickerProviderStateMixin {
  /// Eine Runde dauert 60 s; alle Bewegungen passen glatt hinein.
  static const _round = 60.0;
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 60));
  bool _motion = false;

  static const List<_Swimmer> _fish = [
    (y: 0.30, size: 46, seconds: 20, offset: 0.0, right: true),
    (y: 0.47, size: 34, seconds: 30, offset: 0.4, right: false),
    (y: 0.62, size: 56, seconds: 15, offset: 0.7, right: true),
    (y: 0.38, size: 30, seconds: 20, offset: 0.55, right: false),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = AppScope.of(context).sceneMotion && !MediaQuery.disableAnimationsOf(context);
    if (_motion && !_clock.isAnimating) {
      _clock.repeat();
    } else if (!_motion) {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_motion) return const SizedBox.shrink();
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          return AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              final s = _clock.value * _round;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Ganz hinten: ein Wal als blasser Schatten, einmal pro Runde.
                  _whale(s, w, h),
                  Positioned.fill(child: CustomPaint(painter: _LightAndBubbles(s))),
                  for (final f in _fish) _swimmer(f, s, w, h),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _swimmer(_Swimmer f, double s, double w, double h) {
    final p = ((s / f.seconds) + f.offset) % 1;
    final span = w + 2 * f.size * 1.4;
    final x = f.right ? -f.size * 1.4 + p * span : w + f.size * 0.4 - p * span;
    final y = f.y * h + sin(s * 1.3 + f.offset * 9) * 6;
    return Positioned(
      left: x,
      top: y,
      child: Transform.flip(
        flipX: !f.right,
        child: Transform.rotate(
          angle: sin(s * 2 + f.offset * 5) * 0.06,
          child: TaleriaAsset('critter.fish', width: f.size * 1.32, height: f.size),
        ),
      ),
    );
  }

  Widget _whale(double s, double w, double h) {
    // Zieht in 24 s von links nach rechts, danach Ruhe bis zur nächsten Runde.
    final p = (s - 20) / 24;
    if (p < 0 || p > 1) return const SizedBox.shrink();
    final size = w * 0.45;
    return Positioned(
      left: -size + p * (w + size),
      top: h * 0.2 + sin(p * pi) * -12,
      child: Opacity(
        opacity: 0.22 * sin(p * pi).clamp(0, 1),
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Color(0xFF1C5F86), BlendMode.srcATop),
          child: TaleriaAsset('critter.whale', width: size, height: size * 300 / 384),
        ),
      ),
    );
  }
}

/// Schimmernde Lichtstrahlen von oben und aufsteigende Blasen.
class _LightAndBubbles extends CustomPainter {
  _LightAndBubbles(this.s);

  final double s;

  static final _bubbles = [
    for (var i = 0; i < 22; i++)
      (x: (i * 0.137 + 0.05) % 1, size: 3.0 + (i * 7 % 6), speed: 0.04 + (i * 3 % 4) * 0.012, phase: i * 0.29 % 1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Lichtstrahlen: schmale Keile vom oberen Rand, die sanft pulsieren und leicht wandern.
    for (var i = 0; i < 5; i++) {
      final base = w * (0.25 + i * 0.13) + sin(s * 0.21 + i) * w * 0.03;
      final glow = 0.05 + 0.05 * (0.5 + 0.5 * sin(s * 0.5 + i * 1.7));
      final spread = w * (0.04 + i % 2 * 0.02);
      final path = Path()
        ..moveTo(base - spread * 0.3, 0)
        ..lineTo(base + spread * 0.3, 0)
        ..lineTo(base + spread * 2 + (i - 2) * w * 0.08, h * 0.6)
        ..lineTo(base - spread * 2 + (i - 2) * w * 0.08, h * 0.6)
        ..close();
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: glow),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.6));
      canvas.drawPath(path, paint);
    }

    // Blasen: steigen von unten auf, wackeln seitlich, werden oben blasser.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final shine = Paint();
    for (final b in _bubbles) {
      final p = (s * b.speed + b.phase) % 1;
      final y = h * (1.05 - p * 1.1);
      final x = w * b.x + sin(s * 1.5 + b.phase * 12) * 6;
      final a = 0.55 * (1 - p * 0.7);
      ring.color = Colors.white.withValues(alpha: a);
      shine.color = Colors.white.withValues(alpha: a * 0.8);
      canvas.drawCircle(Offset(x, y), b.size, ring);
      canvas.drawCircle(Offset(x - b.size * 0.35, y - b.size * 0.35), b.size * 0.25, shine);
    }
  }

  @override
  bool shouldRepaint(_LightAndBubbles old) => old.s != s;
}
