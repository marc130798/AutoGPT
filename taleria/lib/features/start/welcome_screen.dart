import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/character_image.dart';
import '../../core/assets/taleria_asset.dart';
import '../../l10n/app_localizations.dart';
import '../child/child_code_screen.dart';
import '../common/environment_banner.dart';
import '../common/scene_background.dart';
import '../common/wood_sign.dart';
import '../parent_auth/parent_auth_screen.dart';

/// Start ohne Anmeldung: Kind mit Code oder Eltern. Blick vom Schiffsdeck
/// aufs Meer, oben das Logo (bis es da ist, ein Holzschild), Talo und Tala
/// winken, unten die Knöpfe auf Papier.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SceneBackground(
        assetKey: AssetKeys.homeBackground,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const EnvironmentBanner(),
                        const SizedBox(height: 16),
                        TaleriaAsset(
                          AssetKeys.logo,
                          width: 260,
                          height: 120,
                          fallback: Center(child: WoodSign(text: l10n.appTitle, large: true)),
                        ),
                        const SizedBox(height: 20),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CharacterImage(AssetKeys.talo, pose: CharacterPose.wave, width: 130, height: 160),
                            SizedBox(width: 20),
                            CharacterImage(AssetKeys.tala, pose: CharacterPose.wave, width: 130, height: 160),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: PaperCard(
                        key: const ValueKey('welcome-card'),
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.welcomeTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(l10n.welcomeSubtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(context)
                                      .push(MaterialPageRoute<void>(builder: (_) => const ChildCodeScreen())),
                              child: Text(l10n.welcomeChildButton),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(context)
                                      .push(MaterialPageRoute<void>(builder: (_) => const ParentAuthScreen())),
                              child: Text(l10n.welcomeParentButton, textAlign: TextAlign.center),
                            ),
                            const SizedBox(height: 14),
                            Text(l10n.noFinancialAdvice, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
