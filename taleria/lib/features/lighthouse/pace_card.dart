import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../services/child_stats_controller.dart';
import '../common/busy_action.dart';
import '../common/texts.dart';

/// Leuchtturm: Fortschritt in Kürze, Tempo (Stationen pro Woche) und Pause
/// der Serie. Elternwörter laut Glossar: Level, Fortschritt, Abzeichen, Serie, Tempo.
class PaceCard extends StatefulWidget {
  const PaceCard({super.key, required this.childId});

  final String childId;

  @override
  State<PaceCard> createState() => _PaceCardState();
}

class _PaceCardState extends State<PaceCard> {
  ChildStatsController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final progress = AppScope.of(context).progress;
    if (_controller == null && progress != null) {
      _controller = ChildStatsController(progress: progress, childId: widget.childId)..load();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _setPace(int value) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final ok = await runWithFeedback(context, () => _controller!.setPace(value == 0 ? null : value));
    if (ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.paceSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final stats = controller.stats;
        if (stats == null) {
          return controller.failure == null
              ? const SizedBox.shrink()
              : Card(child: ListTile(title: Text(l10n.failure(controller.failure!))));
        }
        final rank = stats.rank;
        final selected = stats.pace.free ? 0 : (stats.pace.stationsPerWeek ?? 2);
        return Card(
          key: const ValueKey('pace-card'),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.paceHeading, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  rank == null ? l10n.rank(null) : l10n.parentLevel(rank.level, l10n.rank(rank)),
                  style: theme.textTheme.bodyLarge,
                ),
                Text(l10n.parentProgressXp(stats.xp)),
                Text(l10n.parentBadges(stats.badgeCount)),
                Text(stats.streakPaused ? l10n.parentStreakPaused : l10n.parentStreak(stats.streakWeeks)),
                const SizedBox(height: 16),
                Text(l10n.paceLabel, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  key: const ValueKey('pace-selector'),
                  segments: [
                    for (final n in const [2, 3, 4]) ButtonSegment(value: n, label: Text('$n')),
                    ButtonSegment(value: 0, label: Text(l10n.paceFree)),
                  ],
                  selected: {selected},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) => _setPace(values.single),
                ),
                const SizedBox(height: 8),
                Text(l10n.paceHint, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const ValueKey('streak-pause'),
                  contentPadding: EdgeInsets.zero,
                  value: stats.streakPaused,
                  title: Text(l10n.streakPauseLabel),
                  subtitle: Text(l10n.streakPauseHint),
                  onChanged: (paused) => runWithFeedback(context, () => controller.setStreakPause(paused: paused)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
