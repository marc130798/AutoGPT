import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../admin_scope.dart';
import '../admin_texts.dart';
import '../domain/admin_models.dart';
import '../services/admin_loader.dart';
import 'admin_widgets.dart';

/// Inhalte mit Status und Statistik pro Insel und Station (owner und editor).
/// Gepflegt werden die Inhalte in den Inhaltsdateien, nicht hier (Grundversion).
class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  int _stage = 1;
  AdminLoader<ContentStats>? _loader;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loader == null) _reloadStage();
  }

  void _reloadStage() {
    final repository = AdminScope.of(context).repository!;
    final stage = _stage;
    _loader?.dispose();
    _loader = AdminLoader(() => repository.contentStats(stage))..load();
  }

  @override
  void dispose() {
    _loader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loader = _loader!;
    return ListenableBuilder(
      listenable: loader,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            title: AdminTexts.content,
            onReload: loader.load,
            trailing: SegmentedButton<int>(
              segments: [
                for (final s in [1, 2]) ButtonSegment(value: s, label: Text(AdminTexts.stage(s))),
              ],
              selected: {_stage},
              onSelectionChanged: (value) => setState(() {
                _stage = value.single;
                _reloadStage();
              }),
            ),
          ),
          Expanded(
            child: AdminLoadView(
              loading: loader.loading,
              error: loader.error,
              hasData: loader.data != null,
              onRetry: loader.load,
              builder: (context) {
                final stats = loader.data!;
                final theme = Theme.of(context);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (loader.error != null) AdminErrorText(loader.error!),
                    Text(AdminTexts.contentNote, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text(AdminTexts.onboardedChildren(stats.childrenOnboarded)),
                    const SizedBox(height: 8),
                    for (final island in stats.islands) _IslandTile(island: island),
                    const SizedBox(height: 24),
                    Text(AdminTexts.hardest, style: theme.textTheme.titleLarge),
                    _QuestionList(questions: stats.hardest),
                    const SizedBox(height: 16),
                    Text(AdminTexts.easiest, style: theme.textTheme.titleLarge),
                    _QuestionList(questions: stats.easiest),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IslandTile extends StatelessWidget {
  const _IslandTile({required this.island});

  final IslandStats island;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      child: ExpansionTile(
        key: ValueKey('island-${island.slug}'),
        title: Text('${island.sortOrder}. ${island.title}'),
        subtitle: Text(AdminTexts.islandLine(island.questions, island.reached, island.completed)),
        trailing: Wrap(
          spacing: 6,
          children: [
            _StatusChip(
              label: island.inFog ? AdminTexts.fog : AdminTexts.contentStatus(island.status),
              color: switch (island.status) {
                _ when island.inFog => palette.placeholderBorder,
                ContentStatus.published => palette.success,
                ContentStatus.review => palette.gold,
                ContentStatus.draft => palette.placeholderBorder,
              },
            ),
            _StatusChip(
              label: island.premium ? AdminTexts.premiumIsland : AdminTexts.free,
              color: island.premium ? palette.seaDeep : palette.sea,
            ),
          ],
        ),
        children: [
          for (final (i, s) in island.stations.indexed)
            ListTile(
              dense: true,
              leading: Icon(
                s.isDive
                    ? Icons.scuba_diving
                    : s.isExam
                    ? Icons.emoji_events_outlined
                    : Icons.flag_outlined,
              ),
              title: Text(AdminTexts.stationLabel(s)),
              subtitle: Text(AdminTexts.stationLine(s), style: Theme.of(context).textTheme.bodySmall),
              trailing: Text(
                AdminTexts.stationDone(s, i == 0 ? null : island.stations[i - 1].done - s.done),
                key: ValueKey('done-${s.id}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(color: context.palette.paper)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _QuestionList extends StatelessWidget {
  const _QuestionList({required this.questions});

  final List<QuestionStats> questions;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text(AdminTexts.noQuestionStats));
    }
    return Column(
      children: [
        for (final q in questions) ListTile(title: Text(q.question), subtitle: Text(AdminTexts.questionStats(q))),
      ],
    );
  }
}
