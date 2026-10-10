import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';

/// Ob Bewegungen gezeigt werden dürfen (Bedienungshilfen: Animationen reduzieren).
bool _animate(BuildContext context) => !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

/// Schatzkarten-Effekt nach dem Insel-Abschluss (INSELN.md): Das Kartenstück
/// erscheint, leuchtet golden, Funken steigen auf; danach kommt der Orden.
/// Etwa 3,5 Sekunden, einmalig, ohne Ton. Bei reduzierten Animationen sofort fertig.
class IslandRewardEffect extends StatefulWidget {
  const IslandRewardEffect({super.key, this.badgeAssetKey});

  /// Bild des Ordens (`badge.<slug>`), `null` ohne Orden.
  final String? badgeAssetKey;

  @override
  State<IslandRewardEffect> createState() => _IslandRewardEffectState();
}

class _IslandRewardEffectState extends State<IslandRewardEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (_animate(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = context.palette.gold;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // 0 bis 0,6: Kartenstück und Funken. 0,55 bis 1: Orden.
        final piece = Curves.easeOutBack.transform((t / 0.4).clamp(0.0, 1.0));
        final glow = sin((t / 0.6).clamp(0.0, 1.0) * pi);
        final badge = Curves.elasticOut.transform(((t - 0.55) / 0.45).clamp(0.0, 1.0));
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 170,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gold.withValues(alpha: 0.2 + 0.6 * glow),
                          blurRadius: 12 + 24 * glow,
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.3 + 0.7 * piece,
                    child: Opacity(
                      opacity: piece.clamp(0.0, 1.0),
                      child: const TaleriaAsset(AssetKeys.mapBackground, width: 160, height: 100),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(child: CustomPaint(painter: _SparklePainter(t.clamp(0.0, 0.6) / 0.6, gold))),
                  ),
                ],
              ),
            ),
            if (widget.badgeAssetKey != null)
              SizedBox(
                height: 150,
                child: Center(
                  child: Transform.scale(
                    scale: badge,
                    // Orden mit Band (Hochformat); der Platzhalter ist ein Kreis.
                    child: TaleriaAsset(widget.badgeAssetKey!, width: 104, height: 146),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Funken, die vom Kartenstück aufsteigen und verblassen. Feste Positionen,
/// damit es auf jedem Gerät gleich aussieht.
class _SparklePainter extends CustomPainter {
  _SparklePainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final paint = Paint()..color = color.withValues(alpha: 1 - progress);
    final center = size.center(Offset.zero);
    for (var i = 0; i < 14; i++) {
      final angle = i / 14 * 2 * pi;
      final distance = 30 + 70 * progress + (i % 3) * 8;
      final point = center + Offset(cos(angle) * distance, sin(angle) * distance * 0.7 - 30 * progress);
      canvas.drawCircle(point, 3.5 - 2 * progress + (i % 2), paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Ein Bild, das einmal federnd erscheint (neuer Rang, Orden). Bei
/// reduzierten Animationen sofort da.
class RewardPop extends StatelessWidget {
  const RewardPop({super.key, required this.assetKey, this.size = 96});

  final String assetKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final gold = context.palette.gold;
    final image = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.6), blurRadius: 18, spreadRadius: 2)],
      ),
      child: ClipOval(
        child: TaleriaAsset(assetKey, width: size, height: size),
      ),
    );
    if (!_animate(context)) return image;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: image,
    );
  }
}

/// Etwas taucht einmal aus dem Wasser auf (Begegnung auf See). Kein Dauer-Wackeln.
class RiseFromWater extends StatelessWidget {
  const RiseFromWater({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!_animate(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 24 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}
