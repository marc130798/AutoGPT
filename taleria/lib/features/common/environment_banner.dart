import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/backend/backend.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';

/// Zeigt in der Testumgebung, gegen welchen Server die App läuft und ob er
/// antwortet. In der Live-App unsichtbar.
class EnvironmentBanner extends StatefulWidget {
  const EnvironmentBanner({super.key});

  @override
  State<EnvironmentBanner> createState() => _EnvironmentBannerState();
}

class _EnvironmentBannerState extends State<EnvironmentBanner> {
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
    if (isLive) return const SizedBox.shrink();

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
