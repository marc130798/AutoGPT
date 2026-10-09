import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../l10n/app_localizations.dart';
import '../../services/session_controller.dart';
import '../home/preview_home_screen.dart' show IntroVideoScreen;

/// Kinderbereich. Bis zum Intro (Schritt 3) nur Begrüßung und Figuren.
/// Keine Preise, keine Kauf-Knöpfe, keine Links nach außen.
class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key, required this.state});

  final SessionChild state;

  void _openLighthouse(BuildContext context) {
    final session = AppScope.of(context).session;
    if (state.onParentDevice) {
      session.requestParentArea();
      return;
    }
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.childHomeLighthouseHint),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.ok))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TaleriaAsset(AssetKeys.talo, width: 120, height: 120),
                    SizedBox(width: 24),
                    TaleriaAsset(AssetKeys.tala, width: 120, height: 120),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.childHomeWelcome(state.child.nickname),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(l10n.homeSubtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IntroVideoScreen())),
                  child: Text(l10n.homeShowIntro),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                key: const ValueKey('lighthouse-button'),
                tooltip: l10n.lighthouseTitle,
                icon: const TaleriaAsset(AssetKeys.lighthouse, width: 48, height: 48),
                onPressed: () => _openLighthouse(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
