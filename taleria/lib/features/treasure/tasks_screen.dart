import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/budget_models.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../../services/treasure_controller.dart';
import '../common/busy_action.dart';
import '../common/scene_background.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';

/// Kinderbereich: Aufträge der Eltern. „Erledigt!“ meldet den Auftrag,
/// gutgeschrieben wird erst, wenn die Eltern bestätigen. Oben erklären Talo
/// und Tala, wofür Aufträge da sind; dahinter die Kapitänskajüte.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.childId});

  final String childId;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TreasureController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= TreasureController(budget: AppScope.of(context).budget!, childId: widget.childId)..load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _submit(FamilyTask task) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await runWithFeedback(context, () => _controller!.submitTask(task));
    if (ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.taskSubmitted)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = _controller!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tasksTitle)),
      body: SceneBackground(
        assetKey: AssetKeys.tasksBackground,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (controller.loading) return const Center(child: CircularProgressIndicator());
              if (controller.failure != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.failure(controller.failure!)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: controller.load, child: Text(l10n.retryButton)),
                    ],
                  ),
                );
              }
              final open = [...controller.tasksWith(TaskStatus.rejected), ...controller.tasksWith(TaskStatus.open)];
              final waiting = controller.tasksWith(TaskStatus.submitted);
              final done = controller.tasksWith(TaskStatus.approved);
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SpeechBubble(speaker: Speaker.talo, pose: CharacterPose.wave, text: l10n.tasksIntroTalo),
                    const SizedBox(height: 12),
                    SpeechBubble(speaker: Speaker.tala, text: l10n.tasksIntroTala),
                    const SizedBox(height: 16),
                    if (controller.tasks.isEmpty)
                      PaperCard(child: Text(l10n.tasksEmpty, style: theme.textTheme.bodyLarge)),
                    if (open.isNotEmpty) PaperHeading(l10n.tasksOpenHeading),
                    for (final task in open) _ChildTaskCard(task: task, onSubmit: () => _submit(task)),
                    if (waiting.isNotEmpty) PaperHeading(l10n.tasksWaitingHeading),
                    for (final task in waiting) _ChildTaskCard(task: task),
                    if (done.isNotEmpty) PaperHeading(l10n.tasksDoneHeading),
                    for (final task in done) _ChildTaskCard(task: task),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChildTaskCard extends StatelessWidget {
  const _ChildTaskCard({required this.task, this.onSubmit});

  final FamilyTask task;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final rejected = task.status == TaskStatus.rejected;
    return PaperCard(
      key: ValueKey('task-${task.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(task.title, style: theme.textTheme.titleMedium)),
              Text(
                task.isChore ? l10n.taskChore : l10n.taskReward(formatCents(task.rewardCents)),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: task.isChore ? palette.ink : palette.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (rejected) ...[
            const SizedBox(height: 8),
            Text(
              task.parentNote == null ? l10n.taskRejectedNoNote : l10n.taskRejected(task.parentNote!),
              style: TextStyle(color: palette.coral),
            ),
          ],
          if (onSubmit != null && task.canSubmit) ...[
            const SizedBox(height: 8),
            FilledButton(onPressed: onSubmit, child: Text(rejected ? l10n.taskResubmit : l10n.taskDoneButton)),
          ],
        ],
      ),
    );
  }
}
