import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/avatar.dart';
import '../common/lively_figure.dart';
import '../common/wood_sign.dart';
import 'shipyard_screen.dart' show FlaggedShip;

/// Hafenbecken in der Werft: das eigene Schiff schwimmt in einem Becken aus
/// Wasser mit Holzrand, schaukelt, Wellen ziehen vorbei und am Rumpf schäumt
/// es. So hebt es sich vom Holz der Werft ab (Wunsch von Marc, 16.11.2026).
/// Ohne Bewegung (Tests, „Bewegung reduzieren“) steht alles still.
class ShipDock extends StatefulWidget {
  const ShipDock({super.key, required this.flag, this.height = 230});

  final ShipFlag flag;
  final double height;

  @override
  State<ShipDock> createState() => _ShipDockState();
}

class _ShipDockState extends State<ShipDock> with SingleTickerProviderStateMixin {
  late final AnimationController _waves = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = AppScope.of(context).sceneMotion && !MediaQuery.disableAnimationsOf(context);
    if (motion && !_waves.isAnimating) {
      _waves.repeat();
    } else if (!motion && _waves.isAnimating) {
      _waves.stop();
    }
  }

  @override
  void dispose() {
    _waves.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: WoodColors.edge, width: 3),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WoodColors.light, WoodColors.dark],
        ),
        boxShadow: const [BoxShadow(color: Color(0x66081C30), blurRadius: 12, offset: Offset(0, 6))],
      ),
      // Der Holzrand (Steg) um das Wasser.
      padding: const EdgeInsets.all(7),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const TaleriaAsset(
              AssetKeys.mapBackground,
              fit: BoxFit.cover,
              fallback: ColoredBox(color: Color(0xFF3FB6D3)),
            ),
            // Etwas Licht von oben, unten tieferes Blau.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33FFFFFF), Color(0x00FFFFFF), Color(0x55134A6B)],
                ),
              ),
            ),
            CustomPaint(painter: _WavePainter(clock: _waves)),
            // Das Schiff mit Schaum am Rumpf.
            Align(
              alignment: const Alignment(0.15, 0.55),
              child: SeaSway(
                amount: 1.6,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: 6,
                      child: AnimatedBuilder(
                        animation: _waves,
                        builder: (context, _) {
                          final p = 0.5 + 0.5 * sin(_waves.value * 2 * pi * 2);
                          return CustomPaint(
                            size: Size(170 + 14 * p, 34),
                            painter: _FoamPainter(strength: p),
                          );
                        },
                      ),
                    ),
                    FlaggedShip(flag: widget.flag, size: 180),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helle Wellenlinien, die langsam durch das Becken ziehen.
class _WavePainter extends CustomPainter {
  _WavePainter({required this.clock}) : super(repaint: clock);

  final Animation<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    final rnd = Random(3);
    for (var i = 0; i < 9; i++) {
      final y = size.height * (0.15 + 0.8 * rnd.nextDouble());
      final speed = 0.6 + rnd.nextDouble() * 0.8;
      final x = ((rnd.nextDouble() + t * speed) % 1.2 - 0.1) * size.width;
      final w = 18.0 + rnd.nextDouble() * 22;
      paint.color = Colors.white.withValues(alpha: 0.25 + 0.3 * rnd.nextDouble());
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + w / 2, y - 4, x + w, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => false;
}

/// Weiche Gischt um den Rumpf: verschwommene helle Ovale, keine harte Kante.
class _FoamPainter extends CustomPainter {
  _FoamPainter({required this.strength});

  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final soft = Paint()
      ..color = Colors.white.withValues(alpha: 0.4 + 0.2 * strength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(Rect.fromCenter(center: center, width: size.width, height: size.height * 0.7), soft);
    final crest = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawArc(
      Rect.fromCenter(center: center, width: size.width * 0.95, height: size.height * 0.75),
      0.15,
      pi - 0.3,
      false,
      crest,
    );
  }

  @override
  bool shouldRepaint(_FoamPainter old) => old.strength != strength;
}
