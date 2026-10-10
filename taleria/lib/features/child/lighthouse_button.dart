import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';
import '../../services/session_controller.dart';

/// Leuchtturm-Knopf im Kinderbereich: Bild des Leuchtturms mit Namen darunter.
/// Auf dem Eltern-Gerät führt er zur
/// PIN-Abfrage, auf dem Kinder-Gerät erklärt er nur, wo der Leuchtturm ist.
class LighthouseButton extends StatelessWidget {
  const LighthouseButton({super.key, required this.state});

  final SessionChild state;

  void _open(BuildContext context) {
    if (state.onParentDevice) {
      AppScope.of(context).session.requestParentArea();
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
    final palette = context.palette;
    return Tooltip(
      message: l10n.lighthouseTitle,
      child: InkWell(
        key: const ValueKey('lighthouse-button'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TaleriaAsset(AssetKeys.lighthouse, width: 44, height: 64),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.paper.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.lighthouseTitle,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: palette.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
