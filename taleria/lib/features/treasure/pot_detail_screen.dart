import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/budget_models.dart';
import '../../domain/money.dart';
import '../../domain/pot_summary.dart';
import '../../l10n/app_localizations.dart';
import '../../services/treasure_controller.dart';
import '../common/menu_music.dart';
import '../common/scene_background.dart';
import '../common/texts.dart';
import 'ledger_tile.dart';

/// Kinderbereich: Übersicht einer Truhe (Bordkasse, Schatztruhe oder
/// Glückstruhe), geöffnet durch Antippen der Truhe. Oben der Stand, darunter,
/// wie er sich zusammensetzt (was dazukam und was wegging), dann alle
/// Buchungen dieser Truhe.
class PotDetailScreen extends StatelessWidget {
  const PotDetailScreen({super.key, required this.controller, required this.pot});

  /// Gehört zur Schatztruhe darunter; deren Daten werden hier mitbenutzt.
  final TreasureController controller;
  final Pot pot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = l10n.pot(pot, parent: false);
    return MenuMusic(
      child: Scaffold(
        appBar: AppBar(title: Text(name)),
        body: SceneBackground(
          assetKey: AssetKeys.treasureBackground,
          child: SafeArea(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final summary = PotSummary.of(pot, ledger: controller.ledger, balance: controller.balances.of(pot));
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PaperCard(
                      child: Row(
                        children: [
                          PotImage(pot: pot, size: 76),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatCents(summary.balance),
                                  key: const ValueKey('pot-detail-balance'),
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(potHint(l10n, pot), style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    PaperCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.potDetailsHeading, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          if (summary.isEmpty)
                            Text(l10n.potDetailsEmpty, style: theme.textTheme.bodyLarge)
                          else ...[
                            if (summary.incoming.isNotEmpty) ...[
                              _SubHeading(l10n.potDetailsIn),
                              for (final line in summary.incoming) _SumRow.line(l10n, line, incoming: true),
                            ],
                            if (summary.outgoing.isNotEmpty) ...[
                              _SubHeading(l10n.potDetailsOut),
                              for (final line in summary.outgoing) _SumRow.line(l10n, line, incoming: false),
                            ],
                            if (summary.older != 0)
                              _SumRow(
                                key: const ValueKey('pot-sum-older'),
                                label: l10n.potDetailsOlder,
                                cents: summary.older,
                                count: null,
                              ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.potDetailsTotal(name),
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Text(
                                  formatCents(summary.balance),
                                  key: const ValueKey('pot-sum-total'),
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (summary.entries.isNotEmpty)
                      PaperCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(l10n.potDetailsList, style: theme.textTheme.titleLarge),
                            for (final entry in summary.entries)
                              LedgerTile(entry: entry, parent: false, showPot: false),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Kurzer Satz, wofür die Truhe da ist (mit Beispiel).
String potHint(AppLocalizations l10n, Pot pot) => switch (pot) {
  Pot.spend => l10n.potSpendHint,
  Pot.save => l10n.potSaveHint,
  Pot.give => l10n.potGiveHint,
};

/// Bild einer Truhe; ohne Bild ein farbiger Kreis mit Symbol.
class PotImage extends StatelessWidget {
  const PotImage({super.key, required this.pot, required this.size});

  final Pot pot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (image, icon, color) = switch (pot) {
      Pot.spend => (AssetKeys.potSpend, Icons.sailing_outlined, palette.sea),
      Pot.save => (AssetKeys.iconTreasure, Icons.inventory_2_outlined, palette.gold),
      Pot.give => (AssetKeys.potGive, Icons.volunteer_activism_outlined, palette.tala),
    };
    return TaleriaAsset(
      image,
      width: size,
      height: size,
      fallback: Center(
        child: CircleAvatar(
          radius: size * 0.4,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: size * 0.4),
        ),
      ),
    );
  }
}

class _SubHeading extends StatelessWidget {
  const _SubHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.palette.seaDeep)),
    );
  }
}

/// Eine Zeile der Übersicht: Art, wie oft, Summe.
class _SumRow extends StatelessWidget {
  const _SumRow({super.key, required this.label, required this.cents, required this.count});

  /// Alle Buchungen einer Art in eine Richtung.
  _SumRow.line(AppLocalizations l10n, PotSummaryLine line, {required bool incoming})
    : this(
        key: ValueKey('pot-sum-${incoming ? 'in' : 'out'}-${line.type.name}'),
        label: l10n.potSumLabel(line.type, incoming: incoming),
        cents: line.cents,
        count: line.count,
      );

  final String label;
  final int cents;

  /// Wie oft (`null` bei „Frühere Buchungen“).
  final int? count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                if (count != null) Text(l10n.potDetailsCount(count!), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            '${cents > 0 ? '+' : ''}${formatCents(cents)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cents > 0 ? palette.success : palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}
