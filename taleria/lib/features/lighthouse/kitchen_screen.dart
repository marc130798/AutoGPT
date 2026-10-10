import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/content_models.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../services/child_report_controller.dart';
import '../../services/treasure_controller.dart';
import '../common/texts.dart';
import 'child_budget_screen.dart' show TaskDialog;

/// Leuchtturm: Kombüsen-Fragen (Gesprächsideen) und Aufträge fürs echte Leben
/// zu den Inseln, die das Kind erreicht hat. Die aktuelle Insel steht oben.
class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key, required this.child, required this.parentId});

  final ChildProfile child;
  final String parentId;

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
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
          listenable: controller,
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
                  for (final prompt in controller.promptsFor(report.island.id))
                    Card(
                      child: ListTile(leading: const Icon(Icons.restaurant_outlined), title: Text('„${prompt.text}“')),
                    ),
                  if (report.details?.realLifeTask case final task?)
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
