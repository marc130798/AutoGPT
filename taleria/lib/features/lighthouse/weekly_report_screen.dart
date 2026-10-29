import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/family_models.dart';
import '../../domain/money.dart';
import '../../domain/weekly_report.dart';
import '../../l10n/app_localizations.dart';
import '../../services/weekly_report_controller.dart';
import '../common/texts.dart';

/// Leuchtturm: Was das Kind in den letzten 7 Tagen geschafft hat, was noch
/// wackelt und eine Gesprächsidee. Elternwörter laut Glossar.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key, required this.child});

  final ChildProfile child;

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  WeeklyReportController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    _controller ??= WeeklyReportController(
      content: services.content!,
      progress: services.progress!,
      budget: services.budget,
      child: widget.child,
    )..load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.weeklyTitle(widget.child.nickname))),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.loading) return const Center(child: CircularProgressIndicator());
            final report = controller.report;
            if (controller.failure != null || report == null) {
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
            return RefreshIndicator(
              onRefresh: controller.load,
              child: _ReportList(report: report, nickname: widget.child.nickname),
            );
          },
        ),
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.report, required this.nickname});

  final WeeklyReport report;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.weeklyRange(formatDate(report.from), formatDate(report.to)), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        if (report.quiet)
          _Block(
            key: const ValueKey('weekly-quiet'),
            icon: Icons.sailing_outlined,
            title: l10n.weeklyQuietTitle,
            lines: [l10n.weeklyQuietBody(nickname)],
          )
        else
          _Block(
            key: const ValueKey('weekly-done'),
            icon: Icons.emoji_events_outlined,
            title: l10n.weeklyDoneTitle,
            lines: [
              if (report.stations.isNotEmpty) l10n.weeklyStations(report.stations.length),
              for (final s in report.stations) '· $s',
              if (report.dives > 0) l10n.weeklyDives(report.dives),
              for (final i in report.islands) l10n.weeklyIsland(i),
              for (final b in report.badges) l10n.weeklyBadge(b),
              if (report.finds > 0) l10n.weeklyFinds(report.finds),
              if (report.tasksApproved > 0) l10n.weeklyTasks(report.tasksApproved, formatCents(report.rewardCents)),
            ],
          ),
        if (report.shakyTopics.isNotEmpty)
          _Block(
            key: const ValueKey('weekly-shaky'),
            icon: Icons.replay_outlined,
            title: l10n.weeklyShakyTitle,
            lines: [l10n.weeklyShakyBody, for (final t in report.shakyTopics) '· $t'],
          ),
        if (report.prompt != null)
          _Block(
            key: const ValueKey('weekly-prompt'),
            icon: Icons.restaurant_outlined,
            title: l10n.weeklyPromptTitle,
            lines: ['„${report.prompt}“'],
          ),
        _Block(
          icon: Icons.air,
          title: l10n.weeklyStreakTitle,
          lines: [
            l10n.parentStreak(report.streakWeeks),
            report.lastActiveAt == null ? l10n.lastActiveNever : l10n.lastActive(formatDate(report.lastActiveAt!)),
          ],
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({super.key, required this.icon, required this.title, required this.lines});

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  for (final l in lines) Text(l),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
