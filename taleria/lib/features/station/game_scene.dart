import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../common/wood_sign.dart';
import 'figure_head.dart';
import 'station_stage.dart';

// Gemeinsame Bausteine, damit die Mini-Spiele wie ein Ort auf der Insel
// aussehen statt wie ein Formular (Marcs Wunsch am 20.10.2026): Warteschlange
// mit Köpfen, Kreidetafel, Hüpfen bei Erfolg.

/// Warteschlange: wer schon dran war (Haken), wer gerade dran ist (größer,
/// golden), wer noch wartet (blass). Ersetzt „Kunde 1 von 6“; Vorlesen sagt [label].
class CustomerQueue extends StatelessWidget {
  const CustomerQueue({
    super.key,
    required this.figures,
    required this.current,
    required this.label,
    this.currentDone = false,
  });

  /// Figur je Platz, zum Beispiel `haendler`.
  final List<String> figures;
  final int current;
  final String label;

  /// Der aktuelle Kunde ist schon bedient.
  final bool currentDone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: GlassFrame(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            key: const ValueKey('customer-queue'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, figure) in figures.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FigureHead(figure, size: i == current ? 50 : 36, highlight: i == current, dimmed: i > current),
                      if (i < current || (i == current && currentDone))
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: palette.success,
                            child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kreidetafel mit Holzrahmen, zum Beispiel die Preistafel an der Kasse.
class ChalkBoard extends StatelessWidget {
  const ChalkBoard({super.key, required this.title, required this.entries});

  final String title;

  /// Zeilen als (Ding, Preis).
  final List<(String, String)> entries;

  static const _slate = Color(0xFF2E3B35);
  static const _wood = Color(0xFF8B5A2B);
  static const _chalk = Color(0xFFF4F1E6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: _slate,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _wood, width: 5),
        boxShadow: const [BoxShadow(color: Color(0x55081C30), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(color: _chalk.withValues(alpha: 0.8), letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 2,
            children: [
              for (final (thing, price) in entries)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$thing  '),
                      TextSpan(
                        text: price,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(color: _chalk),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Springt einmal hoch, sobald [active] wahr wird (zum Beispiel ein Kunde,
/// der sein Wechselgeld bekommen hat). Bei „Bewegung reduzieren“ ruhig.
class Hop extends StatelessWidget {
  const Hop({super.key, required this.active, required this.child, this.height = 14});

  final bool active;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!active || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, t, child) =>
          Transform.translate(offset: Offset(0, -sin(t * 2 * pi).abs() * height * (1 - t)), child: child),
      child: child,
    );
  }
}

/// Kopf eines Mini-Spiels: das Bild der Szene (zum Beispiel die Kasse), unten
/// darüber das Holzschild mit dem Titel. Ohne Bild nur das Schild.
class GameSceneHeader extends StatelessWidget {
  const GameSceneHeader({super.key, required this.title, this.image});

  final String title;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final image = this.image;
    if (image == null) return Center(child: WoodSign(text: title));
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.gold, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x44081C30), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox.expand(
                child: TaleriaAsset(image, key: const ValueKey('game-scene'), fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        WoodSign(text: title),
      ],
    );
  }
}

/// Rand für Karten in Mini-Spielen: Goldrand wie die Rahmen der Stationen
/// statt eines dunklen Strichs.
const gameCardShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  side: BorderSide(color: Color(0xFFE2C27A), width: 2),
);

/// Lässt [child] auf einem Bogen von [from] nach [to] fliegen (etwa 0,55
/// Sekunden), zum Beispiel ein gekauftes Brötchen in die Einkaufsliste oder
/// eine Münze in die Schublade. Fängt kein Antippen ab. Bei „Bewegung
/// reduzieren“ oder wenn ein Ziel nicht zu sehen ist, passiert nichts.
void flyThing(BuildContext context, {required GlobalKey from, required GlobalKey to, required Widget child}) {
  if (MediaQuery.disableAnimationsOf(context)) return;
  final overlay = Overlay.maybeOf(context);
  final fromBox = from.currentContext?.findRenderObject();
  final toBox = to.currentContext?.findRenderObject();
  final overlayBox = overlay?.context.findRenderObject();
  if (overlay == null || fromBox is! RenderBox || toBox is! RenderBox || overlayBox is! RenderBox) return;
  if (!fromBox.attached || !toBox.attached || !fromBox.hasSize || !toBox.hasSize) return;
  Offset center(RenderBox box) => overlayBox.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Flight(start: center(fromBox), end: center(toBox), onDone: entry.remove, child: child),
  );
  overlay.insert(entry);
}

class _Flight extends StatefulWidget {
  const _Flight({required this.start, required this.end, required this.onDone, required this.child});

  final Offset start;
  final Offset end;
  final VoidCallback onDone;
  final Widget child;

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  )..forward().whenComplete(() => widget.onDone());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          // Bogen nach oben, kleiner werdend, kurz vor dem Ziel ausblenden.
          final point = Offset.lerp(widget.start, widget.end, t)! + Offset(0, -sin(t * pi) * 60);
          return Stack(
            children: [
              Positioned(
                left: point.dx,
                top: point.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Opacity(
                    opacity: t < 0.85 ? 1 : (1 - t) / 0.15,
                    child: Transform.scale(scale: 1 - 0.3 * t, child: child),
                  ),
                ),
              ),
            ],
          );
        },
        child: Material(type: MaterialType.transparency, child: widget.child),
      ),
    );
  }
}
