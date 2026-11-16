import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/avatar.dart';
import '../common/ship_flag.dart';
import '../common/wood_sign.dart';

/// Bühne oben in der Werft: Blick ins Hafenbecken (Bild `shipyard.dock`), darin
/// das eigene Schiff von der Seite (`ship.side`) mit der gewählten Flagge am
/// höchsten Mast. Das Schiff liegt im Wasser: Es schaukelt, vorne am Rumpf
/// laufen Wellen und Gischt, der untere Rand des Rumpfs liegt unter Wasser
/// (Wunsch von Marc, 16.11.2026: seitlich in 3D statt schräg von oben).
/// Ohne Bewegung (Tests, „Bewegung reduzieren“) steht alles still.
class ShipDock extends StatefulWidget {
  const ShipDock({super.key, required this.avatar, this.height = 300});

  /// Flagge, Segel und Galionsfigur kommen aus dem Avatar des Kindes.
  final AvatarConfig avatar;
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
        boxShadow: const [BoxShadow(color: Color(0x66081C30), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final shipWidth = min(w * 0.64, 240.0);
            final shipHeight = shipWidth * 432 / 512;
            // Wasserlinie: Dort liegt der Rumpf im Becken.
            final waterline = h * 0.8;
            return Stack(
              fit: StackFit.expand,
              children: [
                const TaleriaAsset(
                  AssetKeys.shipyardDock,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  fallback: ColoredBox(color: Color(0xFF3FB6D3)),
                ),
                AnimatedBuilder(
                  animation: _waves,
                  builder: (context, _) {
                    final t = _waves.value * 2 * pi;
                    final bob = sin(t * 2) * 2.5;
                    final tilt = sin(t * 2 + 0.8) * 0.018;
                    return Stack(
                      children: [
                        Positioned(
                          left: (w - shipWidth) / 2,
                          top: waterline - shipHeight * 0.93 + bob,
                          width: shipWidth,
                          height: shipHeight,
                          child: Transform.rotate(
                            angle: tilt,
                            alignment: Alignment.bottomCenter,
                            child: ShipSideView(avatar: widget.avatar, width: shipWidth),
                          ),
                        ),
                        // Wasser vor dem unteren Rumpf: Das Schiff liegt im Becken, nicht darauf.
                        Positioned(
                          left: 0,
                          right: 0,
                          top: waterline - 8 + bob * 0.3,
                          bottom: 0,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x002AA6BE), Color(0xCC2AA6BE), Color(0xE61D8AA3)],
                                stops: [0, 0.35, 1],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _WaterPainter(
                              progress: _waves.value,
                              waterline: waterline,
                              hull: Rect.fromLTWH(
                                (w - shipWidth) / 2 + shipWidth * 0.12,
                                waterline - 6,
                                shipWidth * 0.8,
                                12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Wellenlinien auf dem Wasser und Gischt entlang des Rumpfs.
class _WaterPainter extends CustomPainter {
  _WaterPainter({required this.progress, required this.waterline, required this.hull});

  final double progress;
  final double waterline;
  final Rect hull;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    final rnd = Random(5);
    for (var i = 0; i < 10; i++) {
      final y = waterline - 14 + rnd.nextDouble() * (size.height - waterline + 10);
      final speed = 0.5 + rnd.nextDouble();
      final x = ((rnd.nextDouble() + progress * speed) % 1.2 - 0.1) * size.width;
      final w = 16.0 + rnd.nextDouble() * 22;
      line.color = Colors.white.withValues(alpha: 0.3 + 0.35 * rnd.nextDouble());
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + w / 2, y - 3, x + w, y),
        line,
      );
    }
    // Weiche Gischt am Rumpf, am Bug (rechts) etwas mehr.
    final pulse = 0.5 + 0.5 * sin(progress * 2 * pi * 3);
    final foam = Paint()
      ..color = Colors.white.withValues(alpha: 0.5 + 0.2 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(hull.inflate(2), foam);
    canvas.drawOval(
      Rect.fromCenter(center: hull.centerRight.translate(-4, 0), width: 34 + 8 * pulse, height: 14),
      foam,
    );
  }

  @override
  bool shouldRepaint(_WaterPainter old) => old.progress != progress || old.waterline != waterline;
}

/// Das eigene Schiff von der Seite: Bild `ship.side`, die Segel in der
/// gewählten Farbe (Maske `ship.side.sails`), die Galionsfigur am Bug und die
/// Flagge oben am höchsten Mast. In der Werft-Bühne und als Vorschau.
class ShipSideView extends StatelessWidget {
  const ShipSideView({super.key, required this.avatar, required this.width});

  final AvatarConfig avatar;
  final double width;

  /// Seitenverhältnis des Bilds `ship.side` (512 × 432).
  static const aspect = 432 / 512;

  /// Spitze des höchsten Masts und Bug im Bild (Anteil von Breite und Höhe).
  static const _mastTip = Offset(0.322, 0.012);
  static const _bow = Offset(0.815, 0.74);

  static const sailColors = {
    SailColor.red: Color(0xFFD0453A),
    SailColor.blue: Color(0xFF3D73C2),
    SailColor.green: Color(0xFF3F9E62),
    SailColor.gold: Color(0xFFE8B83E),
    SailColor.purple: Color(0xFF8E5BB5),
  };

  @override
  Widget build(BuildContext context) {
    final height = width * aspect;
    final flagSize = width * 0.17;
    final headSize = width * 0.2;
    final tint = sailColors[avatar.sails];
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: TaleriaAsset(AssetKeys.shipSide, fit: BoxFit.contain)),
          if (tint != null)
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
                child: const TaleriaAsset(AssetKeys.shipSideSails, fit: BoxFit.contain, fallback: SizedBox.shrink()),
              ),
            ),
          if (avatar.figurehead != Figurehead.none)
            Positioned(
              left: width * _bow.dx - headSize * 0.35,
              top: height * _bow.dy - headSize * 0.6,
              width: headSize,
              height: headSize,
              child: TaleriaAsset(
                'figurehead.${avatar.figurehead.name}',
                fit: BoxFit.contain,
                fallback: const SizedBox.shrink(),
              ),
            ),
          // Die eigene Flagge oben am höchsten Mast.
          Positioned(
            left: width * _mastTip.dx - flagSize * 0.12,
            top: height * _mastTip.dy - flagSize * 0.92,
            child: ShipFlagView(flag: avatar.flag, size: flagSize),
          ),
        ],
      ),
    );
  }
}
