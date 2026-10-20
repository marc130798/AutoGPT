import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
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
