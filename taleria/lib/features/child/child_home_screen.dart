import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/avatar.dart';
import '../../l10n/app_localizations.dart';
import '../../services/session_controller.dart';
import '../common/avatar_view.dart';
import '../home/preview_home_screen.dart' show IntroVideoScreen;
import '../map/map_screen.dart';
import 'lighthouse_button.dart';

/// Kinderbereich nach dem Intro: Avatar, Schiff und der Weg zur Karte.
/// Keine Preise, keine Kauf-Knöpfe, keine Links nach außen.
class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key, required this.state});

  final SessionChild state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final child = state.child;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const TaleriaAsset(AssetKeys.talo, width: 88, height: 88),
                    const SizedBox(width: 12),
                    AvatarView(avatar: child.avatar ?? const AvatarConfig(), size: 140),
                    const SizedBox(width: 12),
                    const TaleriaAsset(AssetKeys.tala, width: 88, height: 88),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.childHomeWelcome(child.nickname),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                if (child.shipName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.childHomeShip(child.shipName!),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MapScreen())),
                  child: Text(l10n.childHomeMapButton),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IntroVideoScreen())),
                  child: Text(l10n.childHomeIntroAgain),
                ),
              ],
            ),
            Positioned(top: 8, right: 8, child: LighthouseButton(state: state)),
          ],
        ),
      ),
    );
  }
}
