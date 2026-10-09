import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/assets/video_placeholder.dart';
import '../../core/backend/backend.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';
import '../dev/asset_gallery_screen.dart';

/// Erster Bildschirm. In Schritt 1 nur ein Startpunkt zum Ausprobieren:
/// Figuren-Platzhalter, Umgebung, Server-Status und Intro-Film-Platzhalter.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            const _EnvironmentBanner(),
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
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _IntroVideoScreen())),
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

/// Zeigt, gegen welche Umgebung die App läuft und ob der Server antwortet.
class _EnvironmentBanner extends StatefulWidget {
  const _EnvironmentBanner();

  @override
  State<_EnvironmentBanner> createState() => _EnvironmentBannerState();
}

class _EnvironmentBannerState extends State<_EnvironmentBanner> {
  Future<BackendStatus>? _status;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _status ??= AppScope.of(context).backendHealth.check();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = AppScope.of(context).config;
    final palette = context.palette;
    final isLive = config.environment == AppEnvironment.live;

    return FutureBuilder<BackendStatus>(
      future: _status,
      builder: (context, snapshot) {
        final statusText = switch (snapshot.data) {
          null => l10n.backendChecking,
          BackendStatus.notConfigured => l10n.backendNotConfigured,
          BackendStatus.ready => l10n.backendReady,
          BackendStatus.schemaMissing => l10n.backendSchemaMissing,
          BackendStatus.unreachable => l10n.backendUnreachable,
        };
        final ok = snapshot.data == BackendStatus.ready;
        return Container(
          key: const ValueKey('environment-banner'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isLive ? palette.coral : palette.sand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(ok ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, color: palette.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${isLive ? l10n.environmentLive : l10n.environmentTest} · $statusText',
                  style: TextStyle(color: palette.ink, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IntroVideoScreen extends StatelessWidget {
  const _IntroVideoScreen();

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
