import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/texts.dart';

/// Wie weit es noch bis zum nächsten Rang ist, als Satz für Kinder.
String rankProgressText(AppLocalizations l10n, ChildStats stats, RankForm? rankForm) {
  final next = stats.nextRank;
  if (stats.rank == null) return l10n.statsNoRank;
  if (next == null) return l10n.statsTopRank;
  if (stats.nextRankNeedsCertificate) return l10n.statsNextRankCertificate(l10n.rank(next, rankForm));
  return l10n.statsNextRank(stats.xpToNextRank ?? 0, l10n.rank(next, rankForm));
}

/// Rang, Seemeilen, Weg zum nächsten Rang und Fahrtwind (Kinderbereich).
/// Antippen öffnet alle Ränge als Zeitstrahl ([onOpenRanks]).
class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.stats, required this.rankForm, this.onOpenRanks});

  final ChildStats stats;

  /// Schiffsjunge … oder Schiffsmädchen … (Wahl des Kindes).
  final RankForm? rankForm;

  /// Öffnet den Zeitstrahl der Ränge (`null` = Karte nicht antippbar).
  final VoidCallback? onOpenRanks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final rank = stats.rank;
    final progress = stats.progressToNextRank;
    final nextText = rankProgressText(l10n, stats, rankForm);

    // Papier mit goldenem Rand wie die Kacheln der Startseite.
    return Material(
      key: const ValueKey('stats-card'),
      color: palette.paper.withValues(alpha: 0.95),
      elevation: 3,
      shadowColor: const Color(0x55081C30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.gold.withValues(alpha: 0.7), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenRanks,
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
                        Text(
                          l10n.rank(rank, rankForm),
                          key: const ValueKey('stats-rank'),
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          l10n.statsXp(stats.xp),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: palette.gold,
                            fontWeight: FontWeight.w800,
                          ),
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
              if (onOpenRanks != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('stats-open-ranks'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: onOpenRanks,
                    icon: const Icon(Icons.timeline_rounded, size: 20),
                    label: Text(l10n.ranksOpen),
                  ),
                ),
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
              // Was Fahrtwind ist, in einem Satz für Kinder.
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 2),
                child: Text(
                  l10n.streakHint,
                  key: const ValueKey('stats-streak-hint'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
