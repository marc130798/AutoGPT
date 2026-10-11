import 'package:flutter/material.dart';

import '../../core/assets/character_image.dart';
import '../../core/theme/taleria_palette.dart';

/// Kopf einer Figur im runden Rahmen (oberer Teil des Figurenbilds), zum
/// Beispiel für Händler und Kunden in den Mini-Spielen.
class FigureHead extends StatelessWidget {
  const FigureHead(this.figure, {super.key, this.size = 56, this.highlight = false, this.dimmed = false});

  /// Figur ohne Präfix, zum Beispiel `otti` für `character.otti`.
  final String figure;
  final double size;
  final bool highlight;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Opacity(
      opacity: dimmed ? 0.5 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.paper,
          border: Border.all(color: highlight ? palette.gold : palette.placeholderBorder, width: highlight ? 3 : 2),
        ),
        child: ClipOval(
          child: OverflowBox(
            maxWidth: size * 1.6,
            maxHeight: size * 1.6,
            alignment: Alignment.topCenter,
            child: CharacterImage(
              'character.$figure',
              width: size * 1.6,
              height: size * 1.6,
              alignment: Alignment.topCenter,
              fallback: Icon(Icons.person, size: size * 0.6, color: palette.ink),
            ),
          ),
        ),
      ),
    );
  }
}
