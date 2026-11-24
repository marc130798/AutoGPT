import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/content_models.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_logic.dart';
import '../../domain/progress_models.dart';
import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';
import '../../services/child_report_controller.dart';
import '../../services/crew_controller.dart';
import '../../services/treasure_controller.dart';
import '../common/texts.dart';
import 'child_budget_screen.dart' show TaskDialog;

/// Leuchtturm „Gemeinsam“: zu jeder Insel, die das Kind erreicht hat, das
/// Crew-Abenteuer (Auftrag fürs echte Leben), nach geschaffter Insel
/// „Erklär's deinen Eltern“ und die Fragen für zu Hause. Für die Crew-Aufgaben
/// rufen die Eltern einen Code ab und sagen ihn dem Kind. Die aktuelle Insel steht oben.
class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key, required this.child, required this.parentId});

  final ChildProfile child;
  final String parentId;

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  ChildReportController? _controller;
  CrewController? _crew;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    _controller ??= ChildReportController(content: services.content!, progress: services.progress!, child: widget.child)
      ..load();
    _crew ??= CrewController(content: services.content!, progress: services.progress!, child: widget.child)..load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _crew?.dispose();
    super.dispose();
  }

  /// Code abrufen und groß zeigen.
  Future<void> _showCode(CrewTask task) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await _crew!.code(task);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          key: const ValueKey('together-code-dialog'),
          title: Text(l10n.togetherCodeTitle(widget.child.nickname)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                key: const ValueKey('together-code'),
                style: Theme.of(context).textTheme.displayMedium
                    ?.copyWith(letterSpacing: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                task.kind == CrewKind.explain
                    ? l10n.togetherCodeHintExplain(widget.child.nickname)
                    : l10n.togetherCodeHintAdventure(widget.child.nickname),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.ok))],
        ),
      );
    } on AppFailure catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.failure(e.kind))));
    }
    await _crew!.load();
  }

  Widget _crewCard(BuildContext context, CrewTask task, {RealLifeTask? realLife}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final explain = task.kind == CrewKind.explain;
    return Card(
      key: ValueKey('together-${task.kind.name}-${task.island.slug}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(explain ? l10n.togetherExplainHeading : l10n.realLifeTaskHeading, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            if (explain) ...[
              Text(l10n.togetherExplainIntro(widget.child.nickname), style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              for (final p in task.points) Text('• $p'),
              if (task.ask case final ask?) ...[
                const SizedBox(height: 8),
                Text(l10n.togetherAsk, style: theme.textTheme.labelLarge),
                Text('„$ask“'),
              ],
            ] else ...[
              Text(task.title, style: theme.textTheme.titleMedium),
              if (task.text case final text?) ...[const SizedBox(height: 4), Text(text)],
            ],
            const SizedBox(height: 12),
            if (task.done case final done?)
              Row(
                children: [
                  Icon(Icons.check_circle, color: palette.success),
                  const SizedBox(width: 6),
                  Expanded(child: Text(l10n.togetherDone(formatDate(done.doneAt)))),
                ],
              )
            else
              FilledButton.icon(
                key: ValueKey('together-show-code-${task.kind.name}-${task.island.slug}'),
                onPressed: () => _showCode(task),
                icon: const Icon(Icons.pin_outlined),
                label: Text(l10n.togetherShowCode),
              ),
            if (!explain && realLife != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: ValueKey('real-life-create-${task.island.slug}'),
                onPressed: () => _createTask(realLife),
                icon: const Icon(Icons.add_task),
                label: Text(l10n.realLifeTaskCreate),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createTask(RealLifeTask task) async {
    final budget = AppScope.of(context).budget;
    if (budget == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final treasure = TreasureController(budget: budget, childId: widget.child.id);
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => TaskDialog(controller: treasure, parentId: widget.parentId, initialTitle: task.title),
    );
    treasure.dispose();
    if (created ?? false) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.realLifeTaskCreated(widget.child.nickname))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = _controller!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.kitchenTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([controller, _crew!]),
          builder: (context, _) {
            if (controller.loading) return const Center(child: CircularProgressIndicator());
            if (controller.failure != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.failure(controller.failure!), textAlign: TextAlign.center),
                ),
              );
            }
            final islands = controller.reachedIslands;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  islands.isEmpty ? l10n.kitchenNone(widget.child.nickname) : l10n.kitchenIntro(widget.child.nickname),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                for (final report in islands) ...[
                  Row(
                    children: [
                      Expanded(child: Text(report.island.title, style: theme.textTheme.titleLarge)),
                      if (report.state == IslandState.open) Chip(label: Text(l10n.kitchenCurrent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final task in _crew!.tasks.where((t) => t.island.id == report.island.id))
                    _crewCard(context, task, realLife: report.details?.realLifeTask),
                  for (final prompt in controller.promptsFor(report.island.id))
                    Card(
                      child: ListTile(leading: const Icon(Icons.restaurant_outlined), title: Text('„${prompt.text}“')),
                    ),
                  if (report.details?.realLifeTask case final task?
                      when !_crew!.tasks.any((t) => t.island.id == report.island.id && t.kind == CrewKind.adventure))
                    Card(
                      key: ValueKey('real-life-${report.island.slug}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(l10n.realLifeTaskHeading, style: theme.textTheme.labelLarge),
                            const SizedBox(height: 4),
                            Text(task.title, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(task.text),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              key: ValueKey('real-life-create-${report.island.slug}'),
                              onPressed: () => _createTask(task),
                              icon: const Icon(Icons.add_task),
                              label: Text(l10n.realLifeTaskCreate),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Hinweis oben auf der Kinderseite im Leuchtturm, sobald etwas Gemeinsames
/// wartet (Marc: Ein 8-Jähriger denkt nicht selbst daran, die Eltern sollen
/// den Anstoß bekommen). Ohne offene Aufgabe oder ohne Verbindung unsichtbar.
class TogetherHint extends StatefulWidget {
  const TogetherHint({super.key, required this.child, required this.parentId});

  final ChildProfile child;
  final String parentId;

  @override
  State<TogetherHint> createState() => _TogetherHintState();
}

class _TogetherHintState extends State<TogetherHint> {
  CrewController? _crew;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    if (services.content == null || services.progress == null) return;
    _crew ??= CrewController(content: services.content!, progress: services.progress!, child: widget.child)..load();
  }

  @override
  void dispose() {
    _crew?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crew = _crew;
    if (crew == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return ListenableBuilder(
      listenable: crew,
      builder: (context, _) {
        final open = crew.open;
        if (crew.loading || crew.failure != null || open.isEmpty) return const SizedBox.shrink();
        // Erklären zuerst: Das ist nach einer geschafften Insel der schönste Moment.
        final first = open.firstWhere((t) => t.kind == CrewKind.explain, orElse: () => open.first);
        return Card(
          key: const ValueKey('together-hint'),
          color: palette.coral.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: palette.coral, width: 2),
          ),
          child: ListTile(
            minTileHeight: 72,
            leading: Icon(Icons.groups_rounded, color: palette.coral, size: 36),
            title: Text(l10n.togetherWaiting(open.length), style: theme.textTheme.titleMedium),
            subtitle: Text(
              first.kind == CrewKind.explain
                  ? l10n.togetherWaitingExplain(widget.child.nickname, first.island.title)
                  : l10n.togetherWaitingAdventure(widget.child.nickname, first.title),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => KitchenScreen(child: widget.child, parentId: widget.parentId),
                ),
              );
              await crew.load();
            },
          ),
        );
      },
    );
  }
}
