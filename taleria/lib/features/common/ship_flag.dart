import 'package:flutter/material.dart';

import '../../domain/avatar.dart';

/// Die Flagge am Mast des eigenen Schiffs (Werft). Im Code gezeichnet, damit
/// sie auf jedes Schiffsbild passt.
class ShipFlagView extends StatelessWidget {
  const ShipFlagView({super.key, required this.flag, this.size = 28});

  final ShipFlag flag;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('ship-flag-${flag.name}'),
      width: size,
      height: size,
      child: CustomPaint(painter: _ShipFlagPainter(flag)),
    );
  }
}

class _ShipFlagPainter extends CustomPainter {
  _ShipFlagPainter(this.flag);

  final ShipFlag flag;

  static const _navy = Color(0xFF24476B);
  static const _gold = Color(0xFFE6BB45);
  static const _white = Color(0xFFFFFBF2);
  static const _red = Color(0xFFC0392B);
  static const _teal = Color(0xFF1F9AA0);
  static const _orange = Color(0xFFE8792B);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final pole = Paint()
      ..color = const Color(0xFF5A3A1A)
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * 0.12, s * 0.98), Offset(s * 0.12, s * 0.04), pole);
    final rect = Rect.fromLTWH(s * 0.16, s * 0.06, s * 0.8, s * 0.52);
    final cloth = Path()
      ..moveTo(rect.left, rect.top)
      ..quadraticBezierTo(rect.center.dx, rect.top - s * 0.06, rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..quadraticBezierTo(rect.center.dx, rect.bottom - s * 0.06, rect.left, rect.bottom)
      ..close();
    canvas.save();
    canvas.clipPath(cloth);
    switch (flag) {
      case ShipFlag.taleria:
        canvas.drawRect(rect, Paint()..color = _navy);
        canvas.drawPath(_star(rect.center, rect.height * 0.32), Paint()..color = _gold);
      case ShipFlag.stripes:
        for (var i = 0; i < 4; i++) {
          canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.top + rect.height * i / 4, rect.width, rect.height / 4),
            Paint()..color = i.isEven ? _red : _white,
          );
        }
      case ShipFlag.wave:
        canvas.drawRect(rect, Paint()..color = _teal);
        final wave = Paint()
          ..color = _white
          ..style = PaintingStyle.stroke
          ..strokeWidth = rect.height * 0.1;
        for (final y in [0.4, 0.7]) {
          final p = Path()..moveTo(rect.left, rect.top + rect.height * y);
          for (var k = 0; k < 4; k++) {
            final x0 = rect.left + rect.width * k / 4;
            p.quadraticBezierTo(
              x0 + rect.width / 8,
              rect.top + rect.height * (y - 0.15),
              x0 + rect.width / 4,
              rect.top + rect.height * y,
            );
          }
          canvas.drawPath(p, wave);
        }
      case ShipFlag.star:
        canvas.drawRect(rect, Paint()..color = _gold);
        canvas.drawPath(_star(rect.center, rect.height * 0.36), Paint()..color = _navy);
      case ShipFlag.sun:
        canvas.drawRect(rect, Paint()..color = _orange);
        canvas.drawCircle(rect.center, rect.height * 0.24, Paint()..color = _gold);
        final ray = Paint()
          ..color = _gold
          ..strokeWidth = rect.height * 0.06;
        for (var k = 0; k < 8; k++) {
          final d = Offset.fromDirection(k * 0.785, rect.height * 0.36);
          canvas.drawLine(rect.center + d * 0.9, rect.center + d * 1.25, ray);
        }
    }
    canvas.restore();
    canvas.drawPath(
      cloth,
      Paint()
        ..color = const Color(0x55000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02,
    );
  }

  Path _star(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final angle = -1.5708 + i * 0.6283;
      final pt = c + Offset.fromDirection(angle, radius);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  @override
  bool shouldRepaint(_ShipFlagPainter oldDelegate) => oldDelegate.flag != flag;
}
