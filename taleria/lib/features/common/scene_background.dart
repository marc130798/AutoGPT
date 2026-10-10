import 'package:flutter/material.dart';

import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';

/// Bild über die ganze Seite (Schatzkammer, Kajüte, Unterwasserwelt …),
/// darauf der Inhalt. Ohne Bild ein warmer Holz-Verlauf.
class SceneBackground extends StatelessWidget {
  const SceneBackground({super.key, required this.assetKey, required this.child});

  final String assetKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: TaleriaAsset(
            assetKey,
            fit: BoxFit.cover,
            fallback: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE9D3AE), Color(0xFFC79A63)],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Inhalt auf Papier mit goldenem Rand, gut lesbar auf Hintergrundbildern.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: context.palette.paper.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2C27A), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33081C30), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: child,
    );
  }
}

/// Überschrift auf einem Hintergrundbild: auf einem kleinen Papierstreifen.
class PaperHeading extends StatelessWidget {
  const PaperHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: context.palette.paper.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}
