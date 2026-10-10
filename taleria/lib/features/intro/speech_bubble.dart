import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/character_image.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../l10n/app_localizations.dart';

enum Speaker { talo, tala }

/// Eine Figur mit Sprechblase. Die Figur ist ihr Bild (oder der Platzhalter),
/// Talo und Tala auf Wunsch in einer Pose.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.speaker, required this.text, this.pose}) : line = null;

  /// Dialogzeile aus den Inhalten (Talo, Tala oder eine andere Figur).
  SpeechBubble.line(DialogLine this.line, {super.key}) : speaker = null, text = line.text, pose = null;

  final Speaker? speaker;
  final DialogLine? line;
  final String text;

  /// Pose von Talo oder Tala (winken, freut sich, nachdenken). Ohne Pose
  /// das Grundbild.
  final CharacterPose? pose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final theme = Theme.of(context);
    final key = line?.speaker ?? speaker!.name;
    final (assetKey, name, color) = switch (key) {
      'talo' => (AssetKeys.talo, l10n.speakerTalo, palette.talo),
      'tala' => (AssetKeys.tala, l10n.speakerTala, palette.tala),
      _ => _other(context, key),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Bild im runden Rahmen, nur Kopf und Schultern (die Bilder zeigen die ganze Figur).
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 3),
          ),
          child: ClipOval(
            child: CharacterImage(
              assetKey,
              pose: key == 'talo' || key == 'tala' ? pose : null,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
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
                Text(line?.name ?? name, style: theme.textTheme.labelLarge?.copyWith(color: palette.ink)),
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

(String, String, Color) _other(BuildContext context, String speaker) {
  final entry = AppScope.of(context).manifest.lookup('character.$speaker');
  return (entry.key, entry.placeholder.label, entry.placeholder.color);
}
