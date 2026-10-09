import 'package:flutter/material.dart';

import '../../domain/avatar.dart';

/// Farben des Avatar-Baukastens. Die Namen der Werte stehen in
/// lib/domain/avatar.dart, hier nur das Aussehen.
abstract final class AvatarPalette {
  static const skin = {
    SkinTone.s1: Color(0xFFFCE3D0),
    SkinTone.s2: Color(0xFFF1C7A5),
    SkinTone.s3: Color(0xFFD9A07A),
    SkinTone.s4: Color(0xFFB27650),
    SkinTone.s5: Color(0xFF8A5634),
    SkinTone.s6: Color(0xFF5E3A22),
  };

  static const hair = {
    HairColor.black: Color(0xFF231F20),
    HairColor.brown: Color(0xFF6B4226),
    HairColor.blond: Color(0xFFE0B860),
    HairColor.red: Color(0xFFB5482A),
    HairColor.grey: Color(0xFF9A9A9A),
  };

  static const outfit = {
    OutfitColor.navy: Color(0xFF24476B),
    OutfitColor.red: Color(0xFFC0392B),
    OutfitColor.green: Color(0xFF2E8B57),
    OutfitColor.yellow: Color(0xFFE5B425),
    OutfitColor.purple: Color(0xFF7D4E9E),
    OutfitColor.orange: Color(0xFFE8792B),
  };
}

/// Zeichnet den Avatar aus einfachen Formen. Wird später durch die
/// Rive-Animation `character.avatar` ersetzt, mit denselben Auswahl-Werten.
class AvatarView extends StatelessWidget {
  const AvatarView({super.key, required this.avatar, this.size = 160, this.semanticLabel});

  final AvatarConfig avatar;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _AvatarPainter(avatar)),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.avatar);

  final AvatarConfig avatar;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final skin = Paint()..color = AvatarPalette.skin[avatar.skin]!;
    final hair = Paint()..color = AvatarPalette.hair[avatar.hairColor]!;
    final outfit = Paint()..color = AvatarPalette.outfit[avatar.outfit]!;
    final dark = Paint()..color = const Color(0xFF1C2B3A);

    final headCenter = Offset(w * 0.5, w * 0.42);
    final headRadius = w * 0.22;

    // Haare hinten (lang, Zopf)
    if (avatar.hairStyle == HairStyle.long) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: headCenter.translate(0, w * 0.1), width: headRadius * 2.3, height: headRadius * 2.4),
          Radius.circular(w * 0.12),
        ),
        hair,
      );
    }
    if (avatar.hairStyle == HairStyle.braid) {
      canvas.drawOval(
        Rect.fromCenter(center: headCenter.translate(headRadius * 1.05, w * 0.12), width: w * 0.1, height: w * 0.26),
        hair,
      );
    }

    // Körper mit Jacke
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.22, w * 0.66, w * 0.56, w * 0.34),
        topLeft: Radius.circular(w * 0.18),
        topRight: Radius.circular(w * 0.18),
      ),
      outfit,
    );
    // Hals
    canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.5, w * 0.64), width: w * 0.12, height: w * 0.08), skin);

    // Kopf
    canvas.drawCircle(headCenter, headRadius, skin);

    // Haare vorne
    switch (avatar.hairStyle) {
      case HairStyle.short || HairStyle.long || HairStyle.braid:
        canvas.drawArc(Rect.fromCircle(center: headCenter, radius: headRadius * 1.04), 3.3, 2.82, true, hair);
      case HairStyle.curly:
        for (var i = 0; i < 7; i++) {
          final angle = 3.4 + i * 0.44;
          final c = headCenter + Offset.fromDirection(angle, headRadius * 0.92);
          canvas.drawCircle(c, headRadius * 0.32, hair);
        }
      case HairStyle.none:
        break;
    }

    // Gesicht
    final eyeY = headCenter.dy + headRadius * 0.05;
    canvas.drawCircle(Offset(headCenter.dx - headRadius * 0.38, eyeY), headRadius * 0.11, dark);
    canvas.drawCircle(Offset(headCenter.dx + headRadius * 0.38, eyeY), headRadius * 0.11, dark);
    final smile = Paint()
      ..color = dark.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: headCenter.translate(0, headRadius * 0.35),
        width: headRadius * 0.8,
        height: headRadius * 0.5,
      ),
      0.3,
      2.5,
      false,
      smile,
    );

    // Kopfbedeckung
    switch (avatar.hat) {
      case Hat.captain:
        final cap = Paint()..color = const Color(0xFF24476B);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: headCenter.translate(0, -headRadius * 0.95),
              width: headRadius * 2.1,
              height: headRadius * 0.7,
            ),
            Radius.circular(w * 0.04),
          ),
          cap,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: headCenter.translate(0, -headRadius * 0.6),
            width: headRadius * 2.3,
            height: headRadius * 0.16,
          ),
          Paint()..color = const Color(0xFF1C2B3A),
        );
        canvas.drawCircle(
          headCenter.translate(0, -headRadius * 0.95),
          headRadius * 0.14,
          Paint()..color = const Color(0xFFD4A62A),
        );
      case Hat.bandana:
        canvas.drawArc(
          Rect.fromCircle(center: headCenter, radius: headRadius * 1.08),
          3.2,
          3.0,
          true,
          Paint()..color = const Color(0xFFC0392B),
        );
      case Hat.straw:
        final straw = Paint()..color = const Color(0xFFE6C77A);
        canvas.drawOval(
          Rect.fromCenter(
            center: headCenter.translate(0, -headRadius * 0.7),
            width: headRadius * 3,
            height: headRadius * 0.5,
          ),
          straw,
        );
        canvas.drawArc(
          Rect.fromCircle(center: headCenter.translate(0, -headRadius * 0.7), radius: headRadius * 0.85),
          3.14,
          3.14,
          true,
          straw,
        );
      case Hat.none:
        break;
    }
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) => oldDelegate.avatar != avatar;
}
