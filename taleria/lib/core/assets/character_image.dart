import 'package:flutter/material.dart';

import 'asset_keys.dart';
import 'taleria_asset.dart';

/// Talo oder Tala, auf Wunsch in einer Pose (winken, freut sich, nachdenken).
/// Fehlt das Bild der Pose, erscheint das Grundbild der Figur, fehlt auch
/// das, ihr Platzhalter.
class CharacterImage extends StatelessWidget {
  const CharacterImage(
    this.character, {
    super.key,
    this.pose,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.fallback,
    this.clothTint,
  });

  /// Schlüssel der Figur, zum Beispiel [AssetKeys.talo].
  final String character;
  final CharacterPose? pose;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  /// Eigener Ersatz, wenn auch das Grundbild fehlt (sonst der Platzhalter).
  final Widget? fallback;

  /// Farbe für Shirt und Hose (nur Löwe und Löwin): Die Maske `<bild>.cloth`
  /// wird damit eingefärbt und über das Bild gelegt. `null` = wie im Bild (blau).
  final Color? clothTint;

  @override
  Widget build(BuildContext context) {
    final base = TaleriaAsset(
      character,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fallback: fallback,
    );
    final pose = this.pose;
    final image = pose == null
        ? base
        : TaleriaAsset(
            AssetKeys.pose(character, pose),
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            fallback: base,
          );
    final tint = clothTint;
    if (tint == null) return image;
    final key = pose == null ? character : AssetKeys.pose(character, pose);
    return Stack(
      alignment: Alignment.center,
      children: [
        image,
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
            child: TaleriaAsset(
              '$key.cloth',
              width: width,
              height: height,
              fit: fit,
              alignment: alignment,
              fallback: const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
