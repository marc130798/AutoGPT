import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/texts.dart';

/// Rang, Seemeilen, Weg zum nächsten Rang und Fahrtwind (Kinderbereich).
class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.stats});

  final ChildStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final rank = stats.rank;
    final next = stats.nextRank;
    final progress = stats.progressToNextRank;

    final String nextText;
    if (rank == null) {
      nextText = l10n.statsNoRank;
    } else if (next == null) {
      nextText = l10n.statsTopRank;
    } else if (stats.nextRankNeedsCertificate) {
      nextText = l10n.statsNextRankCertificate;
    } else {
      nextText = l10n.statsNextRank(stats.xpToNextRank ?? 0, l10n.rank(next));
    }

    return Card(
      key: const ValueKey('stats-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Opacity(
                  opacity: rank == null ? 0.4 : 1,
                  child: ClipOval(
                    child: TaleriaAsset(AssetKeys.rank((rank ?? Rank.schiffsjunge).code), width: 64, height: 64),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.rank(rank), key: const ValueKey('stats-rank'), style: theme.textTheme.titleLarge),
                      Text(
                        l10n.statsXp(stats.xp),
                        style: theme.textTheme.titleMedium?.copyWith(color: palette.gold, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: progress, minHeight: 10, color: palette.gold),
              ),
            ],
            const SizedBox(height: 8),
            Text(nextText, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.air, color: palette.seaDeep),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stats.streakPaused ? l10n.streakPaused : l10n.streakWeeks(stats.streakWeeks),
                    key: const ValueKey('stats-streak'),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
