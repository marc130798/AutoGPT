import 'package:flutter/material.dart';

import '../theme/taleria_palette.dart';
import 'asset_manifest.dart';

/// Gut erkennbarer Platzhalter für eine fehlende Grafik:
/// farbige Form mit Namen, z. B. ein oranger Kreis „Talo“.
class AssetPlaceholder extends StatelessWidget {
  const AssetPlaceholder({super.key, required this.entry, this.width, this.height});

  final AssetEntry entry;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final spec = entry.placeholder;
    final border = Border.all(color: context.palette.placeholderBorder, width: 2);
    final decoration = switch (spec.shape) {
      PlaceholderShape.circle => BoxDecoration(color: spec.color, shape: BoxShape.circle, border: border),
      PlaceholderShape.rounded => BoxDecoration(
        color: spec.color,
        borderRadius: BorderRadius.circular(16),
        border: border,
      ),
      PlaceholderShape.rectangle => BoxDecoration(color: spec.color, border: border),
    };
    // Helle oder dunkle Schrift, je nachdem was auf der Farbe besser lesbar ist.
    final textColor = ThemeData.estimateBrightnessForColor(spec.color) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Semantics(
      label: spec.label,
      image: true,
      child: Container(
        key: ValueKey('placeholder:${entry.key}'),
        width: width,
        height: height,
        decoration: decoration,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            spec.label,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
