import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';

/// Öffnet [page] so, dass erst Nebel über die Karte zieht. Danach lichtet
/// [FogReveal] auf der neuen Seite den Nebel (Stopps auf See, Begegnungen).
Route<T> fogRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 450),
  reverseTransitionDuration: const Duration(milliseconds: 250),
  pageBuilder: (_, _, _) => page,
  // Die neue Seite beginnt im dichten Nebel; einblenden heißt: Nebel zieht auf.
  transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
);

/// Die Szene liegt zuerst im dichten Nebel und ist herangezoomt. Dann treiben
/// die Nebelschwaden auseinander, und das Bild zoomt zurück. Einmalig, etwa
/// 1,8 Sekunden. Bei reduzierten Animationen sofort fertig.
class FogReveal extends StatefulWidget {
  const FogReveal({super.key, required this.child});

  /// Gesamtdauer: Nebel hält kurz, dann lichtet er sich.
  static const duration = Duration(milliseconds: 1800);

  /// Ab diesem Anteil der Dauer lichtet sich der Nebel.
  static const clearFrom = 0.3;

  final Widget child;

  @override
  State<FogReveal> createState() => _FogRevealState();
}

class _FogRevealState extends State<FogReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: FogReveal.duration);

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
        final clearing = ((t - FogReveal.clearFrom) / (1 - FogReveal.clearFrom)).clamp(0.0, 1.0);
        final zoom = 1 + 0.2 * (1 - Curves.easeOutCubic.transform(t));
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(scale: zoom, child: child),
            IgnorePointer(child: _Fog(clearing: Curves.easeInOut.transform(clearing))),
          ],
        );
      },
    );
  }
}

/// Nebelschwaden über der Szene. [clearing] von 0 (dicht) bis 1 (weg): Die
/// Schwaden treiben zu den Rändern und werden durchsichtig.
class _Fog extends StatelessWidget {
  const _Fog({required this.clearing});

  final double clearing;

  /// Lage der Schwaden (Mitte, Anteil der Breite und Höhe) und Größe.
  static const _puffs = [
    (0.15, 0.12, 1.1),
    (0.75, 0.08, 1.2),
    (0.45, 0.35, 1.3),
    (0.05, 0.5, 1.0),
    (0.9, 0.45, 1.1),
    (0.3, 0.72, 1.2),
    (0.78, 0.8, 1.3),
    (0.5, 0.95, 1.1),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth, h = constraints.maxHeight;
        final base = max(w, h) * 0.55;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Dichter Grund, der sich zuerst auflöst.
            Positioned.fill(
              child: ColoredBox(color: const Color(0xFFE9EFF3).withValues(alpha: (1 - clearing * 1.6).clamp(0.0, 1.0))),
            ),
            for (final (x, y, scale) in _puffs)
              () {
                final size = base * scale;
                // Weg von der Mitte, zum nächsten Rand hin.
                final dx = (x - 0.5) * w * 1.6 * clearing;
                final dy = (y - 0.5) * h * 0.6 * clearing;
                return Positioned(
                  left: x * w - size / 2 + dx,
                  top: y * h - size / 2 + dy,
                  width: size,
                  height: size * 0.6,
                  child: Opacity(
                    opacity: (1 - clearing).clamp(0.0, 1.0),
                    child: TaleriaAsset(
                      AssetKeys.mapClouds.first,
                      fit: BoxFit.fill,
                      fallback: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(colors: [Color(0xF2FFFFFF), Color(0x00FFFFFF)]),
                        ),
                      ),
                    ),
                  ),
                );
              }(),
          ],
        );
      },
    );
  }
}

/// [child] taucht aus dem Wasser auf: steigt hoch, wird größer und deutlich,
/// mit einem kleinen Nachwippen. Beginnt nach [delay], damit es erst kommt,
/// wenn sich der Nebel lichtet.
class EmergeFromSea extends StatelessWidget {
  const EmergeFromSea({super.key, required this.child, this.delay = const Duration(milliseconds: 700)});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    const rise = Duration(milliseconds: 1100);
    final total = delay + rise;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutBack),
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Transform.scale(scale: 0.7 + 0.3 * value, alignment: Alignment.bottomCenter, child: child),
        ),
      ),
      child: child,
    );
  }
}
