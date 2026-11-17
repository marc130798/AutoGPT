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
      case ShipFlag.anchor:
        canvas.drawRect(rect, Paint()..color = _white);
        final anchor = Paint()
          ..color = _navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = rect.height * 0.09
          ..strokeCap = StrokeCap.round;
        final c = rect.center;
        final h = rect.height;
        canvas.drawCircle(c + Offset(0, -h * 0.28), h * 0.07, anchor);
        canvas.drawLine(c + Offset(0, -h * 0.2), c + Offset(0, h * 0.3), anchor);
        canvas.drawLine(c + Offset(-h * 0.17, -h * 0.08), c + Offset(h * 0.17, -h * 0.08), anchor);
        canvas.drawArc(Rect.fromCircle(center: c + Offset(0, h * 0.05), radius: h * 0.25), 0.35, 2.44, false, anchor);
      case ShipFlag.shell:
        canvas.drawRect(rect, Paint()..color = _teal);
        final c = rect.center + Offset(0, rect.height * 0.08);
        final h = rect.height;
        final shell = Path()
          ..moveTo(c.dx, c.dy + h * 0.28)
          ..lineTo(c.dx - h * 0.34, c.dy - h * 0.06)
          ..quadraticBezierTo(c.dx, c.dy - h * 0.62, c.dx + h * 0.34, c.dy - h * 0.06)
          ..close();
        canvas.drawPath(shell, Paint()..color = const Color(0xFFF6D7C3));
        final rib = Paint()
          ..color = const Color(0xFFC98F72)
          ..strokeWidth = h * 0.04;
        for (final dx in [-0.2, -0.07, 0.07, 0.2]) {
          canvas.drawLine(Offset(c.dx, c.dy + h * 0.26), Offset(c.dx + h * dx, c.dy - h * 0.22), rib);
        }
      case ShipFlag.coin:
        canvas.drawRect(rect, Paint()..color = _navy);
        canvas.drawCircle(rect.center, rect.height * 0.32, Paint()..color = _gold);
        canvas.drawCircle(
          rect.center,
          rect.height * 0.24,
          Paint()
            ..color = const Color(0xFFB8862B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = rect.height * 0.05,
        );
        final tPaint = Paint()
          ..color = const Color(0xFFB8862B)
          ..strokeWidth = rect.height * 0.07
          ..strokeCap = StrokeCap.round;
        final t = rect.center;
        canvas.drawLine(
          t + Offset(-rect.height * 0.1, -rect.height * 0.1),
          t + Offset(rect.height * 0.1, -rect.height * 0.1),
          tPaint,
        );
        canvas.drawLine(t + Offset(0, -rect.height * 0.1), t + Offset(0, rect.height * 0.12), tPaint);
      case ShipFlag.bottle:
        // Flaschenpost (Logbuch der Wunschinsel): grüne Flasche mit Brief auf Lila.
        canvas.drawRect(rect, Paint()..color = const Color(0xFF7D4E9E));
        final h = rect.height;
        final c = rect.center;
        final glass = Paint()..color = const Color(0xFF9FD8C4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c + Offset(h * 0.04, 0), width: h * 0.62, height: h * 0.34),
            Radius.circular(h * 0.14),
          ),
          glass,
        );
        canvas.drawRect(Rect.fromCenter(center: c + Offset(-h * 0.36, 0), width: h * 0.16, height: h * 0.14), glass);
        canvas.drawRect(
          Rect.fromCenter(center: c + Offset(-h * 0.46, 0), width: h * 0.07, height: h * 0.16),
          Paint()..color = const Color(0xFFB07A45),
        );
        canvas.drawRect(
          Rect.fromCenter(center: c + Offset(h * 0.05, 0), width: h * 0.32, height: h * 0.14),
          Paint()..color = _white,
        );
      case ShipFlag.book:
        // Logbuch (Taschengeld-Bucht): aufgeschlagenes weißes Buch auf Grün.
        canvas.drawRect(rect, Paint()..color = const Color(0xFF2E8B57));
        final h = rect.height;
        final c = rect.center + Offset(0, h * 0.04);
        final page = Paint()..color = _white;
        for (final side in [-1.0, 1.0]) {
          final p = Path()
            ..moveTo(c.dx, c.dy - h * 0.2)
            ..quadraticBezierTo(c.dx + side * h * 0.18, c.dy - h * 0.3, c.dx + side * h * 0.38, c.dy - h * 0.24)
            ..lineTo(c.dx + side * h * 0.38, c.dy + h * 0.2)
            ..quadraticBezierTo(c.dx + side * h * 0.18, c.dy + h * 0.14, c.dx, c.dy + h * 0.24)
            ..close();
          canvas.drawPath(p, page);
        }
        final lineP = Paint()
          ..color = const Color(0xFF2E8B57)
          ..strokeWidth = h * 0.035;
        canvas.drawLine(c + Offset(0, -h * 0.2), c + Offset(0, h * 0.24), lineP);
        for (final dy in [-0.08, 0.02, 0.12]) {
          canvas.drawLine(c + Offset(-h * 0.3, h * dy), c + Offset(-h * 0.08, h * dy), lineP);
          canvas.drawLine(c + Offset(h * 0.08, h * dy), c + Offset(h * 0.3, h * dy), lineP);
        }
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
