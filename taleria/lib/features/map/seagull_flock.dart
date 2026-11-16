import 'package:flutter/material.dart';

import '../../core/assets/taleria_asset.dart';
import 'map_painters.dart';

/// Möwen über Karte und Startseite als echte Bilder (Marcs Wunsch am
/// 16.11.2026: „keine gemalten Möwen, eher echte“). Drei Flügelstellungen
/// wechseln sich ab, so schlagen die Flügel: `critter.seagull.up` (Flügel
/// oben), `.glide` (ausgebreitet), `.down` (unten). Die Bilder schauen nach
/// rechts; nach links fliegende Möwen werden gespiegelt. Fehlt ein Bild,
/// zeichnet der Code die Möwe wie bisher als „M“.
///
/// Wann und wo Möwen fliegen, bestimmt `seagullsAt` (dreimal pro Minute ein
/// kleiner Schwarm).
class SeagullFlock extends StatelessWidget {
  const SeagullFlock({super.key, required this.clock, this.scale = 1});

  final Animation<double> clock;

  /// Größe der Möwen (1 = Startseite).
  final double scale;

  /// Breite eines Bilds im Verhältnis zur Spannweite aus `seagullsAt`.
  static const _widthPerSpan = 3.6;

  /// Seitenverhältnis der Möwen-Bilder (Breite zu Höhe).
  static const aspect = 1.4;

  static String frameFor(double flap) =>
      flap > 0.35 ? 'critter.seagull.up' : (flap < -0.35 ? 'critter.seagull.down' : 'critter.seagull.glide');

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) => AnimatedBuilder(
          animation: clock,
          builder: (context, _) {
            final gulls = seagullsAt(sceneSeconds(clock), box.biggest);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final gull in gulls)
                  Builder(
                    builder: (context) {
                      final w = gull.span * _widthPerSpan * scale;
                      final h = w / aspect;
                      return Positioned(
                        left: gull.at.dx - w / 2,
                        top: gull.at.dy - h / 2,
                        width: w,
                        height: h,
                        child: Transform.flip(
                          flipX: !gull.right,
                          child: TaleriaAsset(
                            frameFor(gull.flap),
                            fit: BoxFit.contain,
                            fallback: CustomPaint(
                              painter: _OneGull(flap: gull.flap, span: gull.span * scale),
                            ),
                          ),
                        ),
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

class _OneGull extends CustomPainter {
  _OneGull({required this.flap, required this.span});

  final double flap;
  final double span;

  @override
  void paint(Canvas canvas, Size size) => paintSeagull(canvas, size.center(Offset.zero), span, flap);

  @override
  bool shouldRepaint(_OneGull old) => old.flap != flap || old.span != span;
}
