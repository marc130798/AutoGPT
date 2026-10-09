import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';

enum Speaker { talo, tala }

/// Talo oder Tala mit Sprechblase. Die Figur ist heute ein Platzhalter und
/// später die Rive-Animation (Zustand „sprechen“).
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.speaker, required this.text});

  final Speaker speaker;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final theme = Theme.of(context);
    final (assetKey, name, color) = switch (speaker) {
      Speaker.talo => (AssetKeys.talo, l10n.speakerTalo, palette.talo),
      Speaker.tala => (AssetKeys.tala, l10n.speakerTala, palette.tala),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TaleriaAsset(assetKey, width: 72, height: 72),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.labelLarge?.copyWith(color: palette.ink)),
                const SizedBox(height: 4),
                Text(text, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
