import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/texts.dart';

/// Wahl, wie die Ränge des Kindes heißen: zwei große Karten
/// „Schiffsjunge“ und „Schiffsmädchen“, darunter die weiteren Ränge.
/// Antippen wählt sofort (in der Einführung und einmal auf der Startseite).
class RankFormChoice extends StatelessWidget {
  const RankFormChoice({super.key, required this.onChoose, this.selected, this.busy = false});

  final ValueChanged<RankForm> onChoose;
  final RankForm? selected;

  /// Während gespeichert wird, lässt sich nichts antippen.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, form) in RankForm.values.indexed) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _FormCard(
                form: form,
                title: l10n.rank(Rank.schiffsjunge, form),
                ladder: form == RankForm.junge ? l10n.rankFormLadderJunge : l10n.rankFormLadderMaedchen,
                selected: selected == form,
                onTap: busy ? null : () => onChoose(form),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.form,
    required this.title,
    required this.ladder,
    required this.selected,
    required this.onTap,
  });

  final RankForm form;
  final String title;
  final String ladder;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Material(
      color: palette.paper.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey('rank-form-${form.name}'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? palette.gold : const Color(0xFFE2C27A), width: selected ? 4 : 2),
          ),
          child: Column(
            children: [
              TaleriaAsset(AssetKeys.rank(Rank.schiffsjunge.code), width: 72, height: 72),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: palette.ink),
              ),
              const SizedBox(height: 4),
              Text(ladder, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
