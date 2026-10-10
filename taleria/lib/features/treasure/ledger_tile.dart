import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../../domain/budget_models.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/texts.dart';

/// Eine Zeile im Kassenbuch (Kinder- und Elternbereich).
class LedgerTile extends StatelessWidget {
  const LedgerTile({super.key, required this.entry, required this.parent, this.showPot = true});

  final LedgerEntry entry;
  final bool parent;

  /// In der Übersicht einer Truhe steht der Name der Truhe schon oben.
  final bool showPot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final positive = entry.amountCents > 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(entry.note ?? l10n.ledgerType(entry.type)),
      subtitle: Text(
        [
          // Ohne Notiz steht die Art schon als Titel da.
          if (entry.note != null) l10n.ledgerType(entry.type),
          if (showPot) l10n.pot(entry.pot, parent: parent),
          formatDate(entry.createdAt),
        ].join(' · '),
      ),
      trailing: Text(
        '${positive ? '+' : ''}${formatCents(entry.amountCents)}',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700, color: positive ? palette.success : palette.ink),
      ),
    );
  }
}
