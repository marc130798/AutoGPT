import 'dart:math';

import 'package:flutter/widgets.dart';

import 'map_layout.dart';

// Alles, was die Karte im Code zeichnet: Meer, Wasser um die Inseln, Route,
// Flagge, Schloss, Wolken und Schiff. Inseln, Schiff und Wolken werden durch
// die Bilder aus BILDER.md ersetzt, sobald sie da sind; bis dahin zeichnen die
// Ersatz-Maler hier eine einfache Fassung im selben Aufbau.
//
// Bewegung: Alle Maler bekommen dieselbe Uhr (eine Minute, die sich wiederholt).
// Jede Bewegung macht eine ganze Zahl von Schwüngen pro Minute, damit es beim
// Wiederholen keinen Sprung gibt.

const _minute = 60.0;

/// Sekunden der Szenen-Uhr (0 bis 60).
double sceneSeconds(Animation<double>? clock) => (clock?.value ?? 0) * _minute;

/// Schwingung zwischen -1 und 1 mit [perMinute] Schwüngen pro Minute.
double osc(double t, int perMinute, [double phase = 0]) => sin(2 * pi * perMinute * t / _minute + phase);

/// Wert von 0 bis 1, der [perMinute]-mal pro Minute von vorn beginnt.
double cycle(double t, int perMinute, [double phase = 0]) => (perMinute * t / _minute + phase) % 1.0;

/// Gleicher Zufall auf allen Geräten (String.hashCode ist nicht überall gleich).
int stableSeed(String text) {
  var h = 2166136261;
  for (final unit in text.codeUnits) {
    h = ((h ^ unit) * 16777619) & 0x7fffffff;
  }
  return h;
}

/// Farben der Szene, die nicht im Theme stehen (Wasser, Sand, Wiese, Holz).
abstract final class SceneColors {
  static const seaTop = Color(0xFF143A60);
  static const seaMiddle = Color(0xFF1D5F8C);
  static const seaBottom = Color(0xFF3392B9);
  static const lagoon = Color(0xFF78D6D6);
  static const foam = Color(0xFFFFFFFF);
  static const sandLight = Color(0xFFFAEBC9);
  static const sand = Color(0xFFE9D19E);
  static const sandSide = Color(0xFFD5B67E);
  static const grassLight = Color(0xFF9CD46C);
  static const grass = Color(0xFF5FA54A);
  static const leaf = Color(0xFF3E8E4A);
  static const leafLight = Color(0xFF5AAE55);
  static const wood = Color(0xFF8B5A2B);
  static const woodDark = Color(0xFF5E3A1A);
  static const plank = Color(0xFFA9773F);
  static const rock = Color(0xFF8D99A6);
  static const rockLight = Color(0xFFB9C2CB);
  static const wall = Color(0xFFFFF4E0);
  static const gold = Color(0xFFD4A62A);
  static const goldLight = Color(0xFFF3C94B);
  static const coral = Color(0xFFE5675A);
  static const navy = Color(0xFF24476B);
  static const sail = Color(0xFFFFF8EA);
  static const water = Color(0xFF6CC6D9);
}

Path _star4(Offset c, double s) => Path()
  ..moveTo(c.dx, c.dy - s)
  ..quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy)
  ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s)
  ..quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy)
  ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s)
  ..close();

Paint _fill(Color color) => Paint()..color = color;

// ---------------------------------------------------------------------------
// Meer
// ---------------------------------------------------------------------------

/// Grund des Meeres unter der ganzen Karte: Verlauf und Tiefen. Steht still.
class SeaPainter extends CustomPainter {
  SeaPainter({required this.islands, required this.islandWidth});

  /// Inselmitten (für die Verteilung von Wellen und Glitzern).
  final List<Offset> islands;
  final double islandWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SceneColors.seaTop, SceneColors.seaMiddle, SceneColors.seaBottom],
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );
    for (final blob in _SeaDecor.of(size, islands, islandWidth).blobs) {
      final color = blob.dark ? const Color(0x33082440) : const Color(0x2478CDE6);
      canvas.drawCircle(
        blob.center,
        blob.radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: blob.center, radius: blob.radius)),
      );
    }
  }

  @override
  bool shouldRepaint(SeaPainter oldDelegate) =>
      oldDelegate.islandWidth != islandWidth || !_sameOffsets(oldDelegate.islands, islands);
}

/// Oberfläche des Meeres: kleine Wellen, die schimmern, und Glitzern.
/// Liegt über dem Wasserbild, falls es eins gibt.
class SeaSurfacePainter extends CustomPainter {
  SeaSurfacePainter({required this.clock, required this.islands, required this.islandWidth}) : super(repaint: clock);

  final Animation<double> clock;

  /// Inselmitten: dort keine Wellen, damit die Inseln ruhig im Wasser liegen.
  final List<Offset> islands;
  final double islandWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final t = sceneSeconds(clock);
    final decor = _SeaDecor.of(size, islands, islandWidth);
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;
    for (final w in decor.waves) {
      final alpha = 0.12 + 0.28 * (0.5 + 0.5 * osc(t, 9, w.phase));
      final x = w.center.dx + osc(t, 5, w.phase) * 5;
      final y = w.center.dy;
      wave.color = SceneColors.foam.withValues(alpha: alpha);
      canvas.drawPath(
        Path()
          ..moveTo(x - w.size, y)
          ..quadraticBezierTo(x - w.size / 2, y - w.size * 0.45, x, y)
          ..quadraticBezierTo(x + w.size / 2, y - w.size * 0.45, x + w.size, y),
        wave,
      );
    }
    for (final s in decor.sparkles) {
      final v = osc(t, s.speed, s.phase);
      if (v < 0.82) continue;
      canvas.drawPath(_star4(s.center, 3.2), _fill(SceneColors.foam.withValues(alpha: (v - 0.82) * 4.5)));
    }
  }

  @override
  bool shouldRepaint(SeaSurfacePainter oldDelegate) =>
      oldDelegate.islandWidth != islandWidth || !_sameOffsets(oldDelegate.islands, islands);
}

bool _sameOffsets(List<Offset> a, List<Offset> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _SeaDecor {
  _SeaDecor(this.size, this.islands, this.islandWidth, this.waves, this.blobs, this.sparkles);

  /// Gleiche Verteilung für Grund und Oberfläche; die letzte bleibt gemerkt.
  static _SeaDecor of(Size size, List<Offset> islands, double islandWidth) {
    final last = _last;
    if (last != null && last.size == size && last.islandWidth == islandWidth && _sameOffsets(last.islands, islands)) {
      return last;
    }
    return _last = _SeaDecor.generate(size, islands, islandWidth);
  }

  static _SeaDecor? _last;

  factory _SeaDecor.generate(Size size, List<Offset> islands, double islandWidth) {
    final rnd = Random(7);
    bool free(Offset p, double distance) =>
        islands.every((c) => Offset(c.dx - p.dx, (c.dy - p.dy) * 1.6).distance > distance);
    final waves = <_Wave>[];
    for (var y = 30.0; y < size.height; y += 34) {
      for (var k = 0; k < 3; k++) {
        final p = Offset(rnd.nextDouble() * size.width, y + rnd.nextDouble() * 18);
        if (free(p, islandWidth * 0.66)) {
          waves.add(_Wave(p, 7 + rnd.nextDouble() * 7, rnd.nextDouble() * 2 * pi));
        }
      }
    }
    final blobs = [
      for (var k = 0; k < (size.height / 90).ceil(); k++)
        _Blob(
          Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
          80 + rnd.nextDouble() * 150,
          rnd.nextDouble() < 0.55,
        ),
    ];
    final sparkles = <_Sparkle>[];
    for (var k = 0; k < (size.height / 32).ceil(); k++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      if (free(p, islandWidth * 0.6)) sparkles.add(_Sparkle(p, 6 + rnd.nextInt(9), rnd.nextDouble() * 2 * pi));
    }
    return _SeaDecor(size, islands, islandWidth, waves, blobs, sparkles);
  }

  final Size size;
  final List<Offset> islands;
  final double islandWidth;
  final List<_Wave> waves;
  final List<_Blob> blobs;
  final List<_Sparkle> sparkles;
}

class _Wave {
  _Wave(this.center, this.size, this.phase);
  final Offset center;
  final double size;
  final double phase;
}

class _Blob {
  _Blob(this.center, this.radius, this.dark);
  final Offset center;
  final double radius;
  final bool dark;
}

class _Sparkle {
  _Sparkle(this.center, this.speed, this.phase);
  final Offset center;
  final int speed;
  final double phase;
}

// ---------------------------------------------------------------------------
// Wasser um eine Insel
// ---------------------------------------------------------------------------

/// Flaches türkises Wasser, Gischt am Strand und Brandung, die nach außen
/// läuft. Liegt unter dem Inselbild, im Feld der Insel.
class IslandWaterPainter extends CustomPainter {
  IslandWaterPainter({required this.clock, required this.phase, this.glow = false}) : super(repaint: clock);

  final Animation<double> clock;
  final double phase;

  /// Leuchten um die Insel, an der das Schiff gerade liegt.
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final t = sceneSeconds(clock);
    final center = Offset(size.width / 2, size.height * 0.6);
    final rx = size.width * 0.5;
    final squash = 0.56;

    if (glow) {
      final pulse = 0.75 + 0.25 * osc(t, 20, phase);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1, squash);
      final r = rx * 1.7;
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              SceneColors.goldLight.withValues(alpha: 0.55 * pulse),
              SceneColors.goldLight.withValues(alpha: 0),
            ],
            stops: const [0.45, 1],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
      );
      canvas.restore();
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, squash);
    final lagoon = rx * 1.32;
    canvas.drawCircle(
      Offset.zero,
      lagoon,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SceneColors.lagoon.withValues(alpha: 0.65),
            SceneColors.lagoon.withValues(alpha: 0.4),
            SceneColors.lagoon.withValues(alpha: 0),
          ],
          stops: const [0.6, 0.82, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: lagoon)),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    stroke.color = SceneColors.foam.withValues(alpha: 0.55);
    canvas.drawCircle(Offset.zero, rx * (1.0 + 0.015 * osc(t, 24, phase)), stroke);
    final surf = cycle(t, 12, phase);
    stroke
      ..strokeWidth = 2
      ..color = SceneColors.foam.withValues(alpha: 0.45 * (1 - surf));
    canvas.drawCircle(Offset.zero, rx * (1.03 + 0.22 * surf), stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(IslandWaterPainter oldDelegate) => oldDelegate.glow != glow || oldDelegate.phase != phase;
}

// ---------------------------------------------------------------------------
// Route
// ---------------------------------------------------------------------------

/// Gepunktete Route: gold bis zum Schiff, weiß voraus (die Punkte wandern),
/// blass in den Nebel hinein.
class RoutePainter extends CustomPainter {
  RoutePainter({required this.layout, required this.goldUntil, required this.fogFrom, required this.clock})
    : super(repaint: clock);

  final MapLayout layout;

  /// Bis wohin die Route gefahren ist, als Routen-Stelle (1.5 = halb zwischen
  /// der zweiten und dritten Insel).
  final double goldUntil;

  /// Erste Routen-Insel im Nebel (oder die Zahl der Inseln, wenn keine).
  final int fogFrom;
  final Animation<double> clock;

  static const _spacing = 15.0;

  @override
  void paint(Canvas canvas, Size size) {
    final t = sceneSeconds(clock);
    final count = layout.route.length;
    for (var i = 0; i < count - 1; i++) {
      // Punkte in gleichem Abstand entlang der Kurve.
      const samples = 48;
      final points = [for (var k = 0; k <= samples; k++) layout.pointOn(i, k / samples)];
      final lengths = <double>[0];
      for (var k = 1; k <= samples; k++) {
        lengths.add(lengths.last + (points[k] - points[k - 1]).distance);
      }
      final total = lengths.last;
      final ahead = i == goldUntil.floor() && i + 1 < fogFrom;
      final start = ahead ? (t * 14) % _spacing : _spacing / 2;
      var k = 1;
      for (var s = start; s < total; s += _spacing) {
        while (k < samples && lengths[k] < s) {
          k++;
        }
        final span = lengths[k] - lengths[k - 1];
        final f = span == 0 ? 0.0 : (s - lengths[k - 1]) / span;
        final p = Offset.lerp(points[k - 1], points[k], f)!;
        final position = i + (k - 1 + f) / samples;
        final Paint paint;
        final double radius;
        if (position <= goldUntil + 1e-6) {
          paint = _fill(SceneColors.goldLight);
          radius = 3.4;
        } else if (i + 1 >= fogFrom) {
          paint = _fill(SceneColors.foam.withValues(alpha: 0.22));
          radius = 2.4;
        } else {
          paint = _fill(SceneColors.foam.withValues(alpha: ahead ? 0.8 : 0.45));
          radius = 2.8;
        }
        canvas.drawCircle(p, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(RoutePainter oldDelegate) =>
      oldDelegate.layout != layout || oldDelegate.goldUntil != goldUntil || oldDelegate.fogFrom != fogFrom;
}

// ---------------------------------------------------------------------------
// Flagge und Schloss
// ---------------------------------------------------------------------------

/// Goldene Flagge auf einer geschafften Insel, sie weht im Wind.
class FlagPainter extends CustomPainter {
  FlagPainter({required this.clock, required this.phase}) : super(repaint: clock);

  final Animation<double> clock;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final t = sceneSeconds(clock);
    final h = size.height;
    final x = size.width * 0.2;
    canvas.drawLine(
      Offset(x, h),
      Offset(x, 0),
      Paint()
        ..color = SceneColors.woodDark
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    final fw = size.width * 0.75, fh = h * 0.38;
    double wave(double u) => osc(t, 40, phase - u * 4) * fh * 0.18 * u;
    final path = Path()..moveTo(x, 0);
    for (var j = 1; j <= 10; j++) {
      final u = j / 10;
      path.lineTo(x + u * fw, wave(u));
    }
    for (var j = 10; j >= 0; j--) {
      final u = j / 10;
      path.lineTo(x + u * fw, fh + wave(u));
    }
    path.close();
    canvas.drawPath(path, _fill(SceneColors.gold));
    canvas.drawPath(_star4(Offset(x + fw * 0.45, fh * 0.5 + wave(0.45)), fh * 0.28), _fill(SceneColors.sail));
  }

  @override
  bool shouldRepaint(FlagPainter oldDelegate) => oldDelegate.phase != phase;
}

/// Vorhängeschloss einer gesperrten Insel. [unlock] von 0 (zu) bis 1: der
/// Bügel springt auf, dann wird das Schloss größer und verschwindet.
class LockPainter extends CustomPainter {
  LockPainter({this.unlock = 0});

  final double unlock;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    var lift = 0.0, scale = 1.0, alpha = 1.0;
    if (unlock > 0) {
      lift = Curves.easeOutCubic.transform((unlock / 0.45).clamp(0.0, 1.0)) * s * 0.3;
      if (unlock > 0.45) {
        final q = ((unlock - 0.45) / 0.55).clamp(0.0, 1.0);
        scale = 1 + q * 0.6;
        alpha = 1 - q;
      }
    }
    if (alpha <= 0) return;
    canvas.save();
    canvas.translate(s / 2, s * 0.55);
    canvas.scale(scale);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, s * 0.42), width: s * 0.9, height: s * 0.18),
      _fill(const Color(0xFF081E32).withValues(alpha: 0.25 * alpha)),
    );
    final shackle = Path()
      ..moveTo(-s * 0.24, -s * 0.05 - lift)
      ..lineTo(-s * 0.24, -s * 0.26 - lift)
      ..arcToPoint(Offset(s * 0.24, -s * 0.26 - lift), radius: Radius.circular(s * 0.24))
      ..lineTo(s * 0.24, -s * 0.05 - lift * 0.2);
    canvas.drawPath(
      shackle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.13
        ..color = const Color(0xFF6E7A86).withValues(alpha: alpha),
    );
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(-s * 0.4, -s * 0.08, s * 0.8, s * 0.6),
      Radius.circular(s * 0.12),
    );
    canvas.drawRRect(body, _fill(const Color(0xFFE2B23C).withValues(alpha: alpha)));
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF9C7A22).withValues(alpha: alpha),
    );
    final hole = _fill(const Color(0xFF5A4410).withValues(alpha: alpha));
    canvas.drawCircle(Offset(0, s * 0.16), s * 0.08, hole);
    canvas.drawRect(Rect.fromLTWH(-s * 0.03, s * 0.18, s * 0.06, s * 0.16), hole);
    canvas.restore();
  }

  @override
  bool shouldRepaint(LockPainter oldDelegate) => oldDelegate.unlock != unlock;
}

// ---------------------------------------------------------------------------
// Wolken
// ---------------------------------------------------------------------------

/// Weiche Wolke als Ersatz, bis die Wolkenbilder da sind.
class CloudPainter extends CustomPainter {
  const CloudPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    final w = size.width, h = size.height;
    for (var k = 0; k < 7; k++) {
      final c = Offset(w * (0.18 + 0.64 * rnd.nextDouble()), h * (0.42 + 0.22 * rnd.nextDouble()));
      final r = h * (0.26 + 0.16 * rnd.nextDouble());
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFFFFFFFF), Color(0xF7F4F8FB), Color(0xBFE2EAF1), Color(0x00DCE6EE)],
            stops: [0, 0.5, 0.8, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(CloudPainter oldDelegate) => oldDelegate.seed != seed;
}

// ---------------------------------------------------------------------------
// Schiff
// ---------------------------------------------------------------------------

/// Das Schiff der Crew als Ersatz, bis das Bild da ist. Fährt nach rechts.
class ShipPainter extends CustomPainter {
  const ShipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width * 0.36;
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.68);
    final hull = Path()
      ..moveTo(-s * 1.05, -s * 0.02)
      ..lineTo(s * 1.12, -s * 0.06)
      ..quadraticBezierTo(s * 0.95, s * 0.46, s * 0.5, s * 0.48)
      ..lineTo(-s * 0.62, s * 0.48)
      ..quadraticBezierTo(-s * 0.98, s * 0.38, -s * 1.05, -s * 0.02)
      ..close();
    canvas.drawPath(
      hull,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA56C36), Color(0xFF6B4220)],
        ).createShader(Rect.fromLTRB(-s, -s * 0.1, s, s * 0.5)),
    );
    canvas.drawPath(
      hull,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = SceneColors.woodDark,
    );
    canvas.drawLine(
      Offset(-s * 0.95, s * 0.12),
      Offset(s, s * 0.1),
      Paint()
        ..color = SceneColors.gold
        ..strokeWidth = s * 0.08,
    );
    for (final x in [-0.45, 0.0, 0.45]) {
      canvas.drawCircle(Offset(x * s, s * 0.3), s * 0.07, _fill(SceneColors.sail));
    }
    canvas.drawLine(
      Offset.zero,
      Offset(0, -s * 1.7),
      Paint()
        ..color = SceneColors.woodDark
        ..strokeWidth = s * 0.09,
    );
    const b = 0.26;
    final sail = Path()
      ..moveTo(-s * 0.55, -s * 1.5)
      ..lineTo(s * 0.55, -s * 1.5)
      ..quadraticBezierTo(s * (0.55 + b), -s * 0.9, s * 0.66, -s * 0.28)
      ..lineTo(-s * 0.66, -s * 0.28)
      ..quadraticBezierTo(-s * (0.55 - b * 0.6), -s * 0.9, -s * 0.55, -s * 1.5)
      ..close();
    canvas.drawPath(
      sail,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFFFFDF6), Color(0xFFE6DCC8)])
            .createShader(Rect.fromLTRB(-s * 0.66, -s * 1.5, s * 0.8, -s * 0.28)),
    );
    canvas.drawCircle(Offset(s * 0.09, -s * 0.9), s * 0.2, _fill(SceneColors.gold));
    canvas.drawPath(
      Path()
        ..moveTo(0, -s * 1.7)
        ..quadraticBezierTo(s * 0.25, -s * 1.75, s * 0.48, -s * 1.62)
        ..lineTo(0, -s * 1.52)
        ..close(),
      _fill(SceneColors.coral),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ShipPainter oldDelegate) => false;
}

/// Bugwelle und Kielwasser hinter dem fahrenden Schiff.
class WakePainter extends CustomPainter {
  WakePainter({required this.clock}) : super(repaint: clock);

  final Animation<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = sceneSeconds(clock);
    final s = size.width * 0.36;
    final base = Offset(size.width / 2, size.height * 0.68);
    for (var k = 1; k <= 3; k++) {
      final o = cycle(t, 66, k / 3) * s * 0.4;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx - s * (0.95 + k * 0.32) - o, base.dy + s * 0.42 - k * 3)
          ..quadraticBezierTo(
            base.dx - s * (1.05 + k * 0.32) - o,
            base.dy + s * 0.46,
            base.dx - s * (1.1 + k * 0.32) - o,
            base.dy + s * 0.52 + k * 3,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.4 - k * 0.4
          ..color = SceneColors.foam.withValues(alpha: 0.75 - k * 0.2),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: base + Offset(0, s * 0.5), width: s * 2.3, height: s * 0.32),
      _fill(SceneColors.foam.withValues(alpha: 0.35)),
    );
  }

  @override
  bool shouldRepaint(WakePainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Ersatz-Insel
// ---------------------------------------------------------------------------

/// Einfache Insel im Aufbau der Inselbilder (runder Sandsockel, Wiese,
/// ein paar Häuser oder Palmen je nach Insel), bis das Bild da ist.
class FallbackIslandPainter extends CustomPainter {
  const FallbackIslandPainter(this.slug);

  final String slug;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rnd = Random(stableSeed(slug));
    final c = Offset(w / 2, h * 0.6);
    final rx = w * 0.47, ry = rx * 0.56, thick = h * 0.08;

    final side = _fill(SceneColors.sandSide);
    canvas.drawOval(Rect.fromCenter(center: c + Offset(0, thick), width: rx * 2, height: ry * 2), side);
    canvas.drawRect(Rect.fromLTRB(c.dx - rx, c.dy, c.dx + rx, c.dy + thick), side);
    final top = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SceneColors.sandLight, SceneColors.sand],
        ).createShader(top),
    );

    const n = 14;
    final points = <Offset>[];
    for (var k = 0; k < n; k++) {
      final a = k / n * 2 * pi + (rnd.nextDouble() - 0.5) * 0.25;
      final r = 0.74 + rnd.nextDouble() * 0.12;
      points.add(Offset(c.dx + cos(a) * rx * r, c.dy - ry * 0.08 + sin(a) * ry * r));
    }
    final grass = Path();
    Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final m0 = mid(points.last, points.first);
    grass.moveTo(m0.dx, m0.dy);
    for (var k = 0; k < n; k++) {
      final p = points[k], m = mid(p, points[(k + 1) % n]);
      grass.quadraticBezierTo(p.dx, p.dy, m.dx, m.dy);
    }
    grass.close();
    canvas.drawPath(
      grass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SceneColors.grassLight, SceneColors.grass],
        ).createShader(top),
    );

    _decorate(canvas, slug, Offset(c.dx, c.dy - ry * 0.1), rx * 0.62);
  }

  @override
  bool shouldRepaint(FallbackIslandPainter oldDelegate) => oldDelegate.slug != slug;
}

void _decorate(Canvas canvas, String slug, Offset c, double r) {
  Offset at(double x, double y) => c + Offset(x * r, y * r);
  switch (slug) {
    case 'hafen':
      _pier(canvas, at(0.9, 0.35), r * 0.9, r * 0.14);
      _house(canvas, at(-0.4, 0.15), r * 0.27, SceneColors.coral);
      _house(canvas, at(-0.05, -0.12), r * 0.25, SceneColors.navy);
      _lighthouse(canvas, at(0.42, 0.05), r * 0.22);
    case 'tauschinsel' || 'marktinsel':
      _tent(canvas, at(-0.32, 0.12), r * 0.36, SceneColors.coral, const Color(0xFFF08C80));
      _tent(canvas, at(0.1, -0.08), r * 0.32, SceneColors.gold, SceneColors.goldLight);
      _palm(canvas, at(0.48, 0.25), r * 0.5, 0.18);
    case 'wunschinsel':
      _tree(canvas, at(-0.05, 0.18), r * 0.55, fruit: true);
      _palm(canvas, at(0.5, 0.2), r * 0.45, 0.2);
    case 'spar-insel':
      _tree(canvas, at(-0.25, 0.15), r * 0.45);
      _chest(canvas, at(0.28, 0.2), r * 0.3);
    case 'bank-insel':
      _bank(canvas, at(0, 0.15), r * 0.5);
    case 'sicherheits-festung':
      _tower(canvas, at(0, 0.2), r * 0.38);
    case 'risiko-klippen':
      _rock(canvas, at(-0.25, 0.2), r * 0.32);
      _rock(canvas, at(0.22, 0.1), r * 0.26);
    case 'leih-lagune':
      canvas.drawOval(Rect.fromCenter(center: at(0, 0.0), width: r * 0.6, height: r * 0.3), _fill(SceneColors.water));
      _palm(canvas, at(-0.45, 0.22), r * 0.42, -0.2);
      _palm(canvas, at(0.42, 0.15), r * 0.4, 0.2);
    case 'schatzinsel':
      _palm(canvas, at(-0.3, 0.18), r * 0.5, -0.15);
      final x = Paint()
        ..color = SceneColors.coral
        ..strokeWidth = r * 0.08
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(at(0.12, -0.08), at(0.36, 0.14), x);
      canvas.drawLine(at(0.36, -0.08), at(0.12, 0.14), x);
    default:
      _palm(canvas, at(-0.25, 0.2), r * 0.5, -0.12);
      _palm(canvas, at(0.25, 0.08), r * 0.44, 0.15);
      _rock(canvas, at(0.05, 0.32), r * 0.12);
  }
}

void _shadow(Canvas canvas, Offset c, double rx, double ry) =>
    canvas.drawOval(Rect.fromCenter(center: c, width: rx * 2, height: ry * 2), _fill(const Color(0x2E1E3C1E)));

void _palm(Canvas canvas, Offset base, double h, double lean) {
  _shadow(canvas, base + Offset(h * 0.1, h * 0.04), h * 0.32, h * 0.09);
  final top = base + Offset(h * lean, -h);
  canvas.drawPath(
    Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + h * lean * 1.6, base.dy - h * 0.5, top.dx, top.dy),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.12
      ..strokeCap = StrokeCap.round
      ..color = SceneColors.wood,
  );
  for (var k = 0; k < 6; k++) {
    final a = -pi / 2 + (k - 2.5) * 0.62;
    canvas.save();
    canvas.translate(top.dx + cos(a) * h * 0.3, top.dy + sin(a) * h * 0.22 + h * 0.08);
    canvas.rotate(a);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: h * 0.72, height: h * 0.22),
      _fill(k.isOdd ? SceneColors.leaf : SceneColors.leafLight),
    );
    canvas.restore();
  }
}

void _tree(Canvas canvas, Offset base, double s, {bool fruit = false}) {
  _shadow(canvas, base + Offset(0, s * 0.05), s * 0.5, s * 0.14);
  canvas.drawRect(Rect.fromLTWH(base.dx - s * 0.07, base.dy - s * 0.45, s * 0.14, s * 0.45), _fill(SceneColors.wood));
  final crown = _fill(SceneColors.leaf);
  canvas.drawCircle(base + Offset(-s * 0.22, -s * 0.62), s * 0.3, crown);
  canvas.drawCircle(base + Offset(s * 0.22, -s * 0.62), s * 0.3, crown);
  canvas.drawCircle(base + Offset(0, -s * 0.85), s * 0.34, crown);
  canvas.drawCircle(base + Offset(-s * 0.1, -s * 0.95), s * 0.16, _fill(const Color(0x24FFFFFF)));
  if (fruit) {
    for (final f in const [Offset(-0.3, -0.6), Offset(0.15, -0.95), Offset(0.3, -0.55), Offset(-0.05, -0.7)]) {
      canvas.drawCircle(base + f * s, s * 0.07, _fill(SceneColors.goldLight));
    }
  }
}

void _house(Canvas canvas, Offset base, double w, Color roof) {
  _shadow(canvas, base + Offset(w * 0.1, w * 0.02), w * 0.6, w * 0.1);
  canvas.drawRect(Rect.fromLTWH(base.dx - w / 2, base.dy - w * 0.6, w, w * 0.6), _fill(SceneColors.wall));
  canvas.drawPath(
    Path()
      ..moveTo(base.dx - w * 0.64, base.dy - w * 0.58)
      ..lineTo(base.dx, base.dy - w * 1.08)
      ..lineTo(base.dx + w * 0.64, base.dy - w * 0.58)
      ..close(),
    _fill(roof),
  );
  canvas.drawRect(Rect.fromLTWH(base.dx - w * 0.1, base.dy - w * 0.32, w * 0.2, w * 0.32), _fill(SceneColors.woodDark));
}

void _tent(Canvas canvas, Offset base, double w, Color left, Color right) {
  _shadow(canvas, base + Offset(0, w * 0.03), w * 0.6, w * 0.12);
  canvas.drawPath(
    Path()
      ..moveTo(base.dx - w / 2, base.dy)
      ..lineTo(base.dx, base.dy - w * 0.85)
      ..lineTo(base.dx, base.dy)
      ..close(),
    _fill(left),
  );
  canvas.drawPath(
    Path()
      ..moveTo(base.dx, base.dy)
      ..lineTo(base.dx, base.dy - w * 0.85)
      ..lineTo(base.dx + w / 2, base.dy)
      ..close(),
    _fill(right),
  );
}

void _rock(Canvas canvas, Offset base, double s) {
  canvas.drawPath(
    Path()
      ..moveTo(base.dx - s, base.dy)
      ..lineTo(base.dx - s * 0.55, base.dy - s * 0.85)
      ..lineTo(base.dx + s * 0.2, base.dy - s * 1.05)
      ..lineTo(base.dx + s, base.dy - s * 0.3)
      ..lineTo(base.dx + s * 0.8, base.dy)
      ..close(),
    _fill(SceneColors.rock),
  );
  canvas.drawPath(
    Path()
      ..moveTo(base.dx - s * 0.55, base.dy - s * 0.85)
      ..lineTo(base.dx + s * 0.2, base.dy - s * 1.05)
      ..lineTo(base.dx - s * 0.05, base.dy - s * 0.45)
      ..close(),
    _fill(SceneColors.rockLight),
  );
}

void _chest(Canvas canvas, Offset base, double w) {
  canvas.drawRect(Rect.fromLTWH(base.dx - w / 2, base.dy - w * 0.5, w, w * 0.5), _fill(SceneColors.wood));
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(base.dx - w / 2, base.dy - w * 0.72, w, w * 0.26), Radius.circular(w * 0.12)),
    _fill(const Color(0xFF9E6A35)),
  );
  canvas.drawRect(Rect.fromLTWH(base.dx - w / 2, base.dy - w * 0.5, w, w * 0.08), _fill(SceneColors.gold));
}

void _bank(Canvas canvas, Offset base, double w) {
  _shadow(canvas, base, w * 0.6, w * 0.1);
  final wall = _fill(SceneColors.wall);
  canvas.drawRect(Rect.fromLTWH(base.dx - w * 0.55, base.dy - w * 0.1, w * 1.1, w * 0.1), wall);
  for (var k = -1; k <= 1; k++) {
    canvas.drawRect(Rect.fromLTWH(base.dx + k * w * 0.32 - w * 0.07, base.dy - w * 0.55, w * 0.14, w * 0.45), wall);
  }
  canvas.drawPath(
    Path()
      ..moveTo(base.dx - w * 0.6, base.dy - w * 0.55)
      ..lineTo(base.dx, base.dy - w * 0.92)
      ..lineTo(base.dx + w * 0.6, base.dy - w * 0.55)
      ..close(),
    _fill(SceneColors.goldLight),
  );
}

void _tower(Canvas canvas, Offset base, double w) {
  _shadow(canvas, base, w * 0.55, w * 0.1);
  canvas.drawRect(
    Rect.fromLTWH(base.dx - w * 0.4, base.dy - w * 1.1, w * 0.8, w * 1.1),
    _fill(const Color(0xFFA7B0BA)),
  );
  for (var k = 0; k < 3; k++) {
    canvas.drawRect(
      Rect.fromLTWH(base.dx - w * 0.4 + k * w * 0.3, base.dy - w * 1.26, w * 0.2, w * 0.18),
      _fill(const Color(0xFFC3CAD2)),
    );
  }
  canvas.drawPath(
    Path()
      ..moveTo(base.dx, base.dy - w * 1.7)
      ..lineTo(base.dx + w * 0.4, base.dy - w * 1.6)
      ..lineTo(base.dx, base.dy - w * 1.5)
      ..close(),
    _fill(SceneColors.coral),
  );
}

void _lighthouse(Canvas canvas, Offset base, double w) {
  _shadow(canvas, base, w * 0.55, w * 0.14);
  final h = w * 2.1;
  canvas.drawPath(
    Path()
      ..moveTo(base.dx - w * 0.32, base.dy)
      ..lineTo(base.dx - w * 0.2, base.dy - h)
      ..lineTo(base.dx + w * 0.2, base.dy - h)
      ..lineTo(base.dx + w * 0.32, base.dy)
      ..close(),
    _fill(SceneColors.wall),
  );
  for (final f in const [0.2, 0.55]) {
    final y1 = base.dy - h * f, y2 = base.dy - h * (f + 0.17);
    final a = w * (0.32 - 0.12 * f), b = w * (0.32 - 0.12 * (f + 0.17));
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - a, y1)
        ..lineTo(base.dx - b, y2)
        ..lineTo(base.dx + b, y2)
        ..lineTo(base.dx + a, y1)
        ..close(),
      _fill(SceneColors.coral),
    );
  }
  canvas.drawRect(
    Rect.fromLTWH(base.dx - w * 0.2, base.dy - h - w * 0.32, w * 0.4, w * 0.32),
    _fill(SceneColors.goldLight),
  );
  canvas.drawPath(
    Path()
      ..moveTo(base.dx - w * 0.28, base.dy - h - w * 0.3)
      ..lineTo(base.dx, base.dy - h - w * 0.62)
      ..lineTo(base.dx + w * 0.28, base.dy - h - w * 0.3)
      ..close(),
    _fill(SceneColors.navy),
  );
}

void _pier(Canvas canvas, Offset start, double length, double width) {
  final post = _fill(const Color(0xFF7A4F25));
  for (var k = 0; k <= 3; k++) {
    canvas.drawRect(Rect.fromLTWH(start.dx + length * k / 3 - 1.5, start.dy + width - 1, 3, width * 0.7), post);
  }
  canvas.drawRect(Rect.fromLTWH(start.dx, start.dy, length, width), _fill(SceneColors.plank));
  final line = Paint()
    ..color = const Color(0x733C230F)
    ..strokeWidth = 1;
  for (var k = 1; k < 7; k++) {
    final x = start.dx + length * k / 7;
    canvas.drawLine(Offset(x, start.dy), Offset(x, start.dy + width), line);
  }
}
