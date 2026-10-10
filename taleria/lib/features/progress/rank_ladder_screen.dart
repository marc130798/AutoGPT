import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/menu_music.dart';
import '../common/scene_background.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';
import 'stats_card.dart' show rankProgressText;

/// Kinderbereich: alle Ränge als Zeitstrahl, unten der erste, oben der
/// Kapitän. Zeigt, welche Ränge geschafft sind, wo das Kind steht und wie
/// viele Seemeilen bis zum nächsten fehlen. Die Grenzen kommen aus der
/// Tabelle `ranks`.
class RankLadderScreen extends StatefulWidget {
  const RankLadderScreen({super.key, required this.stats, required this.rankForm});

  final ChildStats stats;
  final RankForm? rankForm;

  @override
  State<RankLadderScreen> createState() => _RankLadderScreenState();
}

class _RankLadderScreenState extends State<RankLadderScreen> {
  Future<List<RankStep>>? _ranks;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ranks ??= AppScope.of(context).progress!.fetchRanks();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final stats = widget.stats;
    final form = widget.rankForm;
    return MenuMusic(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.ranksTitle)),
        body: SceneBackground(
          assetKey: AssetKeys.badgesBackground,
          child: SafeArea(
            child: FutureBuilder<List<RankStep>>(
              future: _ranks,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return Center(
                    child: PaperCard(
                      margin: const EdgeInsets.all(24),
                      child: Text(l10n.failure(error is AppFailure ? error.kind : FailureKind.unknown)),
                    ),
                  );
                }
                final steps = snapshot.data;
                if (steps == null) return const Center(child: CircularProgressIndicator());
                final current = stats.rank?.index ?? -1;
                final progress = stats.nextRankNeedsCertificate ? 0.0 : (stats.progressToNextRank ?? 0.0);
                // Von oben (Kapitän) nach unten (erster Rang).
                final top = steps.reversed.toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SpeechBubble(
                      speaker: Speaker.talo,
                      pose: CharacterPose.happy,
                      text: l10n.ranksIntro(l10n.rank(Rank.kapitaen, form)),
                    ),
                    const SizedBox(height: 12),
                    PaperCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.statsXp(stats.xp),
                            key: const ValueKey('ranks-xp'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: palette.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(rankProgressText(l10n, stats, form), style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                    PaperCard(
                      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                      child: Column(
                        children: [
                          for (final (i, step) in top.indexed) ...[
                            if (i > 0)
                              // Strecke zwischen diesem Rang und dem darüber, von unten gefüllt.
                              _Segment(
                                fill: switch (step.rank.index) {
                                  final r when r < current => 1.0,
                                  final r when r == current => progress,
                                  _ => 0.0,
                                },
                              ),
                            _RankNode(
                              step: step,
                              name: l10n.rank(step.rank, form),
                              state: switch (step.rank.index) {
                                final r when r < current => _NodeState.reached,
                                final r when r == current => _NodeState.current,
                                _ => _NodeState.ahead,
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    PaperCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.ranksHowTitle, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          for (final (icon, text) in [
                            (Icons.flag_rounded, l10n.ranksHowStation),
                            (Icons.anchor, l10n.ranksHowDive),
                            (Icons.sailing_rounded, l10n.ranksHowEncounter),
                          ])
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(icon, color: palette.seaDeep),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
                                ],
                              ),
                            ),
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

enum _NodeState { reached, current, ahead }

/// Breite der linken Spalte mit Abzeichen und Linie.
const double _railWidth = 76;

class _RankNode extends StatelessWidget {
  const _RankNode({required this.step, required this.name, required this.state});

  final RankStep step;
  final String name;
  final _NodeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final current = state == _NodeState.current;
    return Row(
      key: ValueKey('rank-step-${step.rank.code}'),
      children: [
        SizedBox(
          width: _railWidth,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, color: current ? palette.gold : Colors.transparent),
              child: Opacity(
                opacity: state == _NodeState.ahead ? 0.45 : 1,
                child: ClipOval(child: TaleriaAsset(AssetKeys.rank(step.rank.code), width: 60, height: 60)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: state == _NodeState.ahead ? palette.ink.withValues(alpha: 0.6) : palette.ink,
                ),
              ),
              Text(switch (step) {
                (needsCertificate: true, minXp: _, rank: _) => l10n.ranksFromCertificate,
                (minXp: <= 1, needsCertificate: _, rank: _) => l10n.ranksFromStart,
                _ => l10n.ranksFrom(step.minXp),
              }, style: theme.textTheme.bodyMedium),
              if (state != _NodeState.ahead)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: current ? palette.gold : palette.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!current) ...[
                          Icon(Icons.check_rounded, size: 18, color: palette.success),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          current ? l10n.ranksHere : l10n.ranksReached,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: current ? Colors.white : palette.success,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Linie zwischen zwei Rängen, von unten gefüllt (0 bis 1).
class _Segment extends StatelessWidget {
  const _Segment({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: _railWidth,
        height: 36,
        child: Center(
          child: Container(
            width: 6,
            decoration: BoxDecoration(
              color: palette.placeholderBorder.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: fill.clamp(0.0, 1.0),
                widthFactor: 1,
                child: Container(
                  decoration: BoxDecoration(color: palette.gold, borderRadius: BorderRadius.circular(3)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
