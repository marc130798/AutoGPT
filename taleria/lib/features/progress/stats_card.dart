import '../common/texts.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';

/// Wie weit es noch bis zum nächsten Rang ist, als Satz für Kinder.
String rankProgressText(AppLocalizations l10n, ChildStats stats, RankForm? rankForm) {
  final next = stats.nextRank;
  if (stats.rank == null) return l10n.statsNoRank;
  if (next == null) return l10n.statsTopRank;
  if (stats.nextRankNeedsCertificate) return l10n.statsNextRankCertificate(l10n.rank(next, rankForm));
  return l10n.statsNextRank(stats.xpToNextRank ?? 0, l10n.rank(next, rankForm));
}
