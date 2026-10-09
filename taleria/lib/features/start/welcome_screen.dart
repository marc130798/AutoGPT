import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../l10n/app_localizations.dart';
import '../child/child_code_screen.dart';
import '../common/environment_banner.dart';
import '../parent_auth/parent_auth_screen.dart';

/// Start ohne Anmeldung: Kind mit Code oder Eltern.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                TaleriaAsset(AssetKeys.talo, width: 110, height: 110),
                SizedBox(width: 24),
                TaleriaAsset(AssetKeys.tala, width: 110, height: 110),
              ],
            ),
            const SizedBox(height: 32),
            Text(l10n.welcomeTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(l10n.welcomeSubtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChildCodeScreen())),
              child: Text(l10n.welcomeChildButton),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ParentAuthScreen())),
              child: Text(l10n.welcomeParentButton, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 32),
            Text(l10n.noFinancialAdvice, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
