import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../app_scope.dart';

/// Platzhalter für einen fehlenden Film: Standbild im Hochformat 9:16 mit
/// „Film folgt“ und einem Weiter-Knopf, damit man trotzdem weiterspielen kann.
class VideoPlaceholder extends StatelessWidget {
  const VideoPlaceholder({super.key, required this.assetKey, required this.onContinue});

  final String assetKey;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spec = AppScope.of(context).manifest.lookup(assetKey).placeholder;
    final theme = Theme.of(context);

    return Center(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          key: ValueKey('video-placeholder:$assetKey'),
          color: spec.color,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.movie_outlined, size: 72, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                spec.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.videoComingSoon,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: spec.color,
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(l10n.continueButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
