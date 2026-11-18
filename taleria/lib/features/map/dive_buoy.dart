import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/assets/taleria_asset.dart';
import '../../l10n/app_localizations.dart';
import '../common/game_sign.dart';
import 'map_painters.dart' show sceneSeconds;

/// Tauch-Boje auf der Seekarte: Hier startet Talas Perlentaucher (Marcs
/// Wunsch am 18.11.2026). Sie schaukelt leicht; gesperrt ist sie blass mit
/// Schloss, bis der erste Tauchgang im Hafen geschafft ist.
class DiveBuoy extends StatelessWidget {
  const DiveBuoy({super.key, required this.unlocked, required this.clock, required this.onTap});

  static const size = Size(104, 112);

  final bool unlocked;
  final Animation<double> clock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 74,
          height: 66,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Rot-weiße Boje mit Taucherin obendrauf.
              Positioned(left: 17, right: 17, bottom: 0, height: 34, child: CustomPaint(painter: _BuoyPainter())),
              const Positioned(
                left: 2,
                right: 2,
                top: -8,
                height: 50,
                child: TaleriaAsset('game.pearl.diver', fit: BoxFit.contain, fallback: SizedBox.shrink()),
              ),
              Positioned(
                right: -4,
                bottom: 0,
                child: unlocked ? const GameSign(size: 24) : const Icon(Icons.lock, size: 20, color: Color(0xFF4A5D70)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xEEFFFBF0), borderRadius: BorderRadius.circular(10)),
          child: Text(
            l10n.arcadePearlTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1C2B3A), height: 1.15),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      label: l10n.arcadePearlTitle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedBuilder(
          animation: clock,
          builder: (context, child) {
            final t = sceneSeconds(clock);
            return Transform.translate(
              offset: Offset(0, sin(t * 1.6) * 2.5),
              child: Transform.rotate(angle: sin(t * 1.2) * 0.04, child: child),
            );
          },
          child: Opacity(opacity: unlocked ? 1 : 0.6, child: body),
        ),
      ),
    );
  }
}

class _BuoyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    final body = RRect.fromRectAndRadius(r, Radius.circular(size.width / 2));
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(r, Paint()..color = const Color(0xFFE5675A));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.28),
      Paint()..color = Colors.white,
    );
    canvas.restore();
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF8A2E25),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width / 2, size.height + 1), width: size.width * 1.9, height: 7),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_BuoyPainter old) => false;
}
