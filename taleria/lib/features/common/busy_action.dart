import 'package:flutter/material.dart';

import '../../domain/family_models.dart';
import '../../l10n/app_localizations.dart';
import 'texts.dart';

/// Führt eine Aktion aus und zeigt bei einem Fehler eine verständliche Meldung.
/// Gibt `true` zurück, wenn alles geklappt hat.
Future<bool> runWithFeedback(BuildContext context, Future<void> Function() action) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await action();
    return true;
  } on AppFailure catch (e) {
    debugPrint('Aktion fehlgeschlagen: $e');
    messenger.showSnackBar(SnackBar(content: Text(l10n.failure(e.kind))));
    return false;
  }
}

/// Fragt nach, bevor etwas Endgültiges passiert.
Future<bool> confirmDestructive(BuildContext context, {required String title, required String body}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.deleteConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
