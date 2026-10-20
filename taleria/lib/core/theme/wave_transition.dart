import 'dart:math';

import 'package:flutter/material.dart';

/// Bildschirmwechsel mit einer Welle (Animationsplan, CLAUDE.md Abschnitt 11):
/// Die neue Seite steigt mit einem welligen Rand und etwas Schaum von unten
/// herauf, beim Zurückgehen sinkt sie wieder. Bei „Bewegung reduzieren“
/// wechselt die Seite sofort.
class WavePageTransitionsBuilder extends PageTransitionsBuilder {
  const WavePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return _WaveReveal(animation: animation, child: child);
  }
}

class _WaveReveal extends AnimatedWidget {
  const _WaveReveal({required Animation<double> animation, required this.child}) : super(listenable: animation);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInOut.transform((listenable as Animation<double>).value);
    if (t >= 1) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ClipPath(clipper: _WaveClipper(t), child: child),
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _FoamPainter(t))),
        ),
      ],
    );
  }
}

/// Wellenkamm bei Fortschritt [t]: ganz unten bei 0, ganz oben bei 1.
Path _crest(Size size, double t, {bool closeBelow = false}) {
  const amplitude = 14.0;
  final level = (size.height + 2 * amplitude) * (1 - t) - amplitude;
  final wavelength = size.width / 1.5;
  final path = Path()..moveTo(0, level + amplitude * sin(t * 4 * pi));
  for (var x = 0.0; x <= size.width + 8; x += 8) {
    path.lineTo(x, level + amplitude * sin(2 * pi * x / wavelength + t * 4 * pi));
  }
  if (closeBelow) {
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }
  return path;
}

class _WaveClipper extends CustomClipper<Path> {
  _WaveClipper(this.t);

  final double t;

  @override
  Path getClip(Size size) => _crest(size, t, closeBelow: true);

  @override
  bool shouldReclip(_WaveClipper oldClipper) => oldClipper.t != t;
}

/// Weißer Schaum auf dem Wellenkamm.
class _FoamPainter extends CustomPainter {
  _FoamPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final foam = Paint()
      ..color = const Color(0xDDFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final shade = Paint()
      ..color = const Color(0x553392B9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    final crest = _crest(size, t);
    canvas
      ..drawPath(crest.shift(const Offset(0, 8)), shade)
      ..drawPath(crest, foam);
  }

  @override
  bool shouldRepaint(_FoamPainter oldDelegate) => oldDelegate.t != t;
}
