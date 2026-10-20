import 'dart:math';

import 'package:flutter/material.dart';

/// Abtauchen zu Beginn eines Tauchgangs (Animationsplan, CLAUDE.md
/// Abschnitt 11): Das Wasser steigt mit welligem Rand über den Bildschirm,
/// Blasen steigen auf, das Licht wird blauer; dann wird das Wasser klar und
/// die Unterwasserwelt ist da. Einmalig, etwa 1,6 Sekunden, fängt kein
/// Antippen ab. Bei reduzierten Animationen sofort fertig.
class DiveDescent extends StatefulWidget {
  const DiveDescent({super.key, required this.child});

  static const duration = Duration(milliseconds: 1600);

  final Widget child;

  @override
  State<DiveDescent> createState() => _DiveDescentState();
}

class _DiveDescentState extends State<DiveDescent> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: DiveDescent.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        if (t >= 1) return child!;
        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            IgnorePointer(
              child: CustomPaint(key: const ValueKey('dive-descent'), painter: _DivePainter(t)),
            ),
          ],
        );
      },
    );
  }
}

class _DivePainter extends CustomPainter {
  _DivePainter(this.t);

  final double t;

  static const _deep = Color(0xFF0E3557);
  static const _sea = Color(0xFF1D5F8C);

  @override
  void paint(Canvas canvas, Size size) {
    // 0 bis 0,35: Das Wasser steigt bis über den oberen Rand.
    // 0,35 bis 1: Das Blau wird klarer, bis die Szene darunter da ist.
    final rise = Curves.easeIn.transform((t / 0.35).clamp(0.0, 1.0));
    final clear = Curves.easeOut.transform(((t - 0.35) / 0.65).clamp(0.0, 1.0));
    final alpha = 0.92 * (1 - clear);
    if (alpha <= 0) return;

    const amplitude = 12.0;
    final level = (size.height + 2 * amplitude) * (1 - rise) - amplitude;
    final water = Path()..moveTo(0, level);
    for (var x = 0.0; x <= size.width + 8; x += 8) {
      water.lineTo(x, level + amplitude * sin(2 * pi * x / (size.width / 1.3) + t * 10));
    }
    water
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      water,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _sea.withValues(alpha: alpha),
            _deep.withValues(alpha: alpha),
          ],
        ).createShader(Offset.zero & size),
    );

    // Blasen: feste Lage, steigen mit unterschiedlichem Tempo auf.
    final random = Random(11);
    final bubble = Paint()
      ..color = Colors.white.withValues(alpha: 0.75 * (1 - clear * 0.8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 22; i++) {
      final x = random.nextDouble() * size.width;
      final speed = 0.8 + random.nextDouble() * 0.8;
      final r = 3 + random.nextDouble() * 7;
      final y = size.height + 20 - t * speed * size.height * 1.2;
      if (y < level || y < -r) continue;
      canvas.drawCircle(Offset(x + sin(t * 12 + i) * 6, y), r, bubble);
    }
  }

  @override
  bool shouldRepaint(_DivePainter oldDelegate) => oldDelegate.t != t;
}
