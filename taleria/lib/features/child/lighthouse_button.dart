import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../l10n/app_localizations.dart';
import '../../services/session_controller.dart';

/// Leuchtturm-Knopf im Kinderbereich. Auf dem Eltern-Gerät führt er zur
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
    return IconButton(
      key: const ValueKey('lighthouse-button'),
      tooltip: AppLocalizations.of(context).lighthouseTitle,
      icon: const TaleriaAsset(AssetKeys.lighthouse, width: 48, height: 48),
      onPressed: () => _open(context),
    );
  }
}
