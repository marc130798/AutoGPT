import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/family_models.dart';
import '../../domain/learning_status.dart';
import '../../domain/progress_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../services/child_report_controller.dart';
import '../common/texts.dart';

/// Leuchtturm: Fortschritt pro Insel und Lernstand pro Thema eines Kindes.
/// Elternwörter laut Glossar (Level, Fortschritt, Abzeichen, Serie, Inhalt folgt).
class ChildProgressScreen extends StatefulWidget {
  const ChildProgressScreen({super.key, required this.child});

  final ChildProfile child;

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  ChildReportController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    _controller ??= ChildReportController(content: services.content!, progress: services.progress!, child: widget.child)
      ..load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = _controller!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle(widget.child.nickname))),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.loading) return const Center(child: CircularProgressIndicator());
            final stats = controller.stats;
            if (controller.failure != null || stats == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.failure(controller.failure ?? FailureKind.unknown), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: controller.load, child: Text(l10n.retryButton)),
                    ],
                  ),
                ),
              );
            }
            final rank = stats.rank;
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    key: const ValueKey('progress-summary'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rank == null ? l10n.rank(null) : l10n.parentLevel(rank.level, l10n.rank(rank)),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(l10n.parentProgressXp(stats.xp)),
                          Text(l10n.parentBadges(stats.badgeCount)),
                          Text(stats.streakPaused ? l10n.parentStreakPaused : l10n.parentStreak(stats.streakWeeks)),
                          Text(l10n.parentCollection(stats.finds, stats.pearls)),
                          Text(
                            stats.lastActiveAt == null
                                ? l10n.lastActiveNever
                                : l10n.lastActive(formatDate(stats.lastActiveAt!)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.islandsHeading, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(l10n.learningHint, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  for (final report in controller.islands) _IslandCard(report: report),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IslandCard extends StatelessWidget {
  const _IslandCard({required this.report});

  final IslandReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final subtitle = switch (report.state) {
      IslandState.completed => l10n.islandStatusCompleted(
        report.completedAt == null ? '' : formatDate(report.completedAt!),
      ),
      IslandState.open => l10n.islandStatusProgress(report.requiredDone, report.requiredTotal),
      IslandState.locked => l10n.islandStatusLocked,
      IslandState.premium => l10n.islandStatusPremium,
      IslandState.fog => l10n.islandStatusFog,
    };
    final icon = switch (report.state) {
      IslandState.completed => Icon(Icons.check_circle, color: palette.success),
      IslandState.open => Icon(Icons.sailing, color: palette.gold),
      IslandState.locked => const Icon(Icons.lock_outline),
      IslandState.premium => const Icon(Icons.workspace_premium_outlined),
      IslandState.fog => const Icon(Icons.cloud_outlined),
    };
    if (!report.reached) {
      return Card(
        key: ValueKey('report-${report.island.slug}'),
        child: ListTile(leading: icon, title: Text(report.island.title), subtitle: Text(subtitle)),
      );
    }
    return Card(
      key: ValueKey('report-${report.island.slug}'),
      child: ExpansionTile(
        leading: icon,
        title: Text(report.island.title),
        subtitle: Text(subtitle),
        initiallyExpanded: report.state == IslandState.open,
        children: [
          for (final topic in report.topics) _TopicTile(topic: topic),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic});

  final TopicReport topic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final (label, color) = switch (topic.status) {
      TopicStatus.secure => (l10n.topicSecure, palette.success),
      TopicStatus.learning => (l10n.topicLearning, palette.gold),
      TopicStatus.shaky => (l10n.topicShaky, palette.coral),
      TopicStatus.notStarted => (l10n.topicNotStarted, palette.placeholderBorder),
    };
    final station = topic.station;
    return ListTile(
      key: ValueKey('topic-${station.displayNumber}'),
      dense: true,
      title: Text('${l10n.stationNumber(station.displayNumber)}: ${station.content.title}'),
      subtitle: topic.learning == null ? null : Text(l10n.topicAnswered(topic.learning!.answered)),
      trailing: Chip(
        label: Text(label),
        backgroundColor: color.withValues(alpha: 0.15),
        side: BorderSide(color: color),
      ),
    );
  }
}
