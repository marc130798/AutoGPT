import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/taleria_asset.dart';

/// Leben über dem Unterwasserbild (Marcs Wünsche am 17.11.2026 für
/// Taucherfunde und Tauchgänge): Lichtstrahlen schimmern, Blasen steigen
/// auf, bunte Fische schwimmen vorbei, ab und zu eine Schildkröte und ein
/// freundlicher Hai, ganz hinten ein Wal als Schatten, und unten am Boden
/// läuft manchmal eine Krabbe seitwärts ins Bild und wieder hinaus.
/// Alles im Code, kein Video. Fängt kein Antippen ab. Ohne Bewegung
/// (reduziert oder in Tests) bleibt nur das stille Bild.
class UnderwaterLife extends StatefulWidget {
  const UnderwaterLife({super.key, this.layer = UnderwaterLayer.all});

  /// Welche Tiere diese Ebene zeigt (zum Beispiel Gäste vor den Karten).
  final UnderwaterLayer layer;

  @override
  State<UnderwaterLife> createState() => _UnderwaterLifeState();
}

/// Welche Teile eine Ebene zeigt: hinten Licht, Blasen, Fische und Wal;
/// vorn Schildkröte, Hai und Krabbe. Auf den Taucherfunden liegen die Gäste
/// vor den Karten, weil man sie sonst kaum sieht (Marcs Test am 17.11.2026).
enum UnderwaterLayer { all, back, front }

/// Ein Tier, das quer durchs Bild schwimmt: Bild, Höhe (Anteil), Größe,
/// Dauer einer Durchquerung, Versatz, Richtung, Farbton (Drehung in Grad).
typedef _Swimmer = ({String key, double y, double size, double seconds, double offset, bool right, double hue});

class _UnderwaterLifeState extends State<UnderwaterLife> with SingleTickerProviderStateMixin {
  /// Eine Runde dauert 120 s; alle Bewegungen passen glatt hinein.
  static const _round = 120.0;
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 120));
  bool _motion = false;

  /// Fische in verschiedenen Farben (der Fisch ist orange-türkis, gedreht
  /// wird nur der Farbton).
  static const List<_Swimmer> _fish = [
    (key: 'critter.fish', y: 0.30, size: 46, seconds: 20, offset: 0.0, right: true, hue: 0),
    (key: 'critter.fish', y: 0.47, size: 34, seconds: 30, offset: 0.4, right: false, hue: 140),
    (key: 'critter.fish', y: 0.62, size: 56, seconds: 24, offset: 0.7, right: true, hue: 260),
    (key: 'critter.fish', y: 0.38, size: 30, seconds: 20, offset: 0.55, right: false, hue: 60),
    (key: 'critter.fish', y: 0.54, size: 26, seconds: 15, offset: 0.2, right: true, hue: 200),
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
              final back = widget.layer != UnderwaterLayer.front;
              final front = widget.layer != UnderwaterLayer.back;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (back) ...[
                    // Ganz hinten: ein Wal als blasser Schatten, einmal pro Runde.
                    _whale(s, w, h),
                    Positioned.fill(child: CustomPaint(painter: _LightAndBubbles(s))),
                  ],
                  if (front) ...[
                    // Einmal pro Runde: die Schildkröte gemächlich, später der Hai.
                    _visitor(
                      (key: 'critter.turtle', y: 0.44, size: 70, seconds: 0, offset: 0, right: true, hue: 0),
                      s,
                      from: 8,
                      duration: 34,
                      w: w,
                      h: h,
                    ),
                    _visitor(
                      (key: 'critter.shark', y: 0.26, size: 84, seconds: 0, offset: 0, right: false, hue: 0),
                      s,
                      from: 66,
                      duration: 26,
                      w: w,
                      h: h,
                    ),
                  ],
                  if (back)
                    for (final f in _fish) _swimmer(f, s, w, h),
                  if (front) ...[
                    // Unten am Boden: zweimal pro Runde schaut eine Krabbe vorbei.
                    _crab(s, w, h, from: 30, fromLeft: true),
                    _crab(s, w, h, from: 92, fromLeft: false),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _image(String key, double width, double height, double hue) {
    final image = TaleriaAsset(key, width: width, height: height, fallback: const SizedBox.shrink());
    if (hue == 0) return image;
    return ColorFiltered(colorFilter: ColorFilter.matrix(_hueMatrix(hue)), child: image);
  }

  Widget _swimmer(_Swimmer f, double s, double w, double h) {
    final p = ((s / f.seconds) + f.offset) % 1;
    final span = w + 2 * f.size * 1.4;
    final x = f.right ? -f.size * 1.4 + p * span : w + f.size * 0.4 - p * span;
    final y = f.y * h + sin(s * _k * 25 + f.offset * 9) * 6;
    return Positioned(
      left: x,
      top: y,
      child: Transform.flip(
        flipX: !f.right,
        child: Transform.rotate(
          angle: sin(s * _k * 38 + f.offset * 5) * 0.06,
          child: _image(f.key, f.size * 1.32, f.size, f.hue),
        ),
      ),
    );
  }

  /// Ein Gast, der einmal pro Runde ab [from] in [duration] Sekunden quer
  /// durchs Bild schwimmt, mit sanftem Auf und Ab.
  Widget _visitor(
    _Swimmer f,
    double s, {
    required double from,
    required double duration,
    required double w,
    required double h,
  }) {
    final p = (s - from) / duration;
    if (p < 0 || p > 1) return const SizedBox.shrink();
    final width = f.size * 1.5;
    final x = f.right ? -width + p * (w + width) : w - p * (w + width);
    final y = f.y * h + sin(p * pi * 3) * 10;
    return Positioned(
      left: x,
      top: y,
      child: Transform.flip(
        flipX: !f.right,
        child: Transform.rotate(angle: sin(s * _k * 27) * 0.04, child: _image(f.key, width, f.size, 0)),
      ),
    );
  }

  /// Eine Krabbe läuft seitwärts vom Rand ein Stück ins Bild, bleibt kurz
  /// stehen, winkt mit dem Wippen und läuft wieder zurück hinaus (16 s).
  Widget _crab(double s, double w, double h, {required double from, required bool fromLeft}) {
    final t = s - from;
    if (t < 0 || t > 16) return const SizedBox.shrink();
    const size = 54.0;
    final inside = w * 0.28;
    // 0 bis 6 s hinein, 6 bis 10 s stehen, 10 bis 16 s hinaus.
    final double walk = t < 6 ? t / 6 : (t < 10 ? 1.0 : 1 - (t - 10) / 6);
    final dist = -size + walk * (inside + size);
    final x = fromLeft ? dist : w - size - dist;
    final moving = t < 6 || t > 10;
    final step = moving ? sin(t * 14).abs() * 3 : 0.0;
    return Positioned(
      left: x,
      bottom: 10 + step,
      child: Transform.rotate(
        angle: moving ? sin(t * 14) * 0.08 : sin(t * 4) * 0.04,
        child: _image('critter.crab', size, size * 283 / 384, 0),
      ),
    );
  }

  Widget _whale(double s, double w, double h) {
    // Zieht in 24 s von links nach rechts, danach Ruhe bis zur nächsten Runde.
    final p = (s - 40) / 24;
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

/// Eine volle Schwingung pro Runde (120 s); Vielfache davon laufen nahtlos weiter.
const _k = 2 * pi / 120;

/// Farbmatrix, die den Farbton um [degrees] dreht (Helligkeit bleibt).
List<double> _hueMatrix(double degrees) {
  final a = degrees * pi / 180;
  final c = cos(a), s = sin(a);
  const r = 0.213, g = 0.715, b = 0.072;
  return [
    r + c * (1 - r) + s * -r,
    g + c * -g + s * -g,
    b + c * -b + s * (1 - b),
    0,
    0,
    r + c * -r + s * 0.143,
    g + c * (1 - g) + s * 0.140,
    b + c * -b + s * -0.283,
    0,
    0,
    r + c * -r + s * -(1 - r),
    g + c * -g + s * g,
    b + c * (1 - b) + s * b,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

/// Schimmernde Lichtstrahlen von oben und aufsteigende Blasen.
class _LightAndBubbles extends CustomPainter {
  _LightAndBubbles(this.s);

  final double s;

  static final _bubbles = [
    for (var i = 0; i < 22; i++)
      (x: (i * 0.137 + 0.05) % 1, size: 3.0 + (i * 7 % 6), speed: (5 + i * 3 % 5) / 120, phase: i * 0.29 % 1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Lichtstrahlen: schmale Keile vom oberen Rand, die sanft pulsieren und leicht wandern.
    for (var i = 0; i < 5; i++) {
      final base = w * (0.25 + i * 0.13) + sin(s * _k * 4 + i) * w * 0.03;
      final glow = 0.05 + 0.05 * (0.5 + 0.5 * sin(s * _k * 10 + i * 1.7));
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
      final x = w * b.x + sin(s * _k * 29 + b.phase * 12) * 6;
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
