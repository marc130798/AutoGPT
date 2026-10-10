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
  });

  /// Schlüssel der Figur, zum Beispiel [AssetKeys.talo].
  final String character;
  final CharacterPose? pose;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final base = TaleriaAsset(character, width: width, height: height, fit: fit, alignment: alignment);
    final pose = this.pose;
    if (pose == null) return base;
    return TaleriaAsset(
      AssetKeys.pose(character, pose),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fallback: base,
    );
  }
}
