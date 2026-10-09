import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/assets/video_placeholder.dart';
import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';
import '../common/environment_banner.dart';
import '../dev/asset_gallery_screen.dart';

/// Vorschau ohne Konto, wenn kein Server eingerichtet ist (aus Schritt 1):
/// Figuren-Platzhalter, Umgebung, Server-Status und Intro-Film-Platzhalter.
class PreviewHomeScreen extends StatelessWidget {
  const PreviewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const EnvironmentBanner(),
            const SizedBox(height: 24),
            const Center(child: TaleriaAsset(AssetKeys.logo, width: 200, height: 80)),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TaleriaAsset(AssetKeys.talo, width: 120, height: 120),
                SizedBox(width: 24),
                TaleriaAsset(AssetKeys.tala, width: 120, height: 120),
              ],
            ),
            const SizedBox(height: 32),
            Text(l10n.homeWelcome, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(l10n.homeSubtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IntroVideoScreen())),
              child: Text(l10n.homeShowIntro),
            ),
            // Die Übersicht aller Grafiken ist ein Werkzeug für Marc und gibt
            // es nur in der Testumgebung.
            if (services.config.isTest) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AssetGalleryScreen())),
                child: Text(l10n.homeShowAssets),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class IntroVideoScreen extends StatelessWidget {
  const IntroVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.seaDeep,
      body: SafeArea(
        child: VideoPlaceholder(assetKey: AssetKeys.introVideo, onContinue: () => Navigator.of(context).pop()),
      ),
    );
  }
}
