import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/budget_models.dart';
import '../../domain/family_models.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../../services/treasure_controller.dart';
import '../common/busy_action.dart';
import '../common/button_spinner.dart';
import '../common/texts.dart';
import '../treasure/amount_dialog.dart';
import '../treasure/treasure_screen.dart' show LedgerTile;

/// Leuchtturm: Taschengeld, Aufgaben und Kontostand eines Kindes.
class ChildBudgetScreen extends StatefulWidget {
  const ChildBudgetScreen({super.key, required this.child, required this.parentId});

  final ChildProfile child;
  final String parentId;

  @override
  State<ChildBudgetScreen> createState() => _ChildBudgetScreenState();
}

class _ChildBudgetScreenState extends State<ChildBudgetScreen> {
  TreasureController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= TreasureController(budget: AppScope.of(context).budget!, childId: widget.child.id)..load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _setAllowance() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AllowanceDialog(controller: _controller!),
    );
  }

  Future<void> _stopAllowance() => runWithFeedback(context, () => _controller!.setAllowance());

  Future<void> _createTask() async {
    await showDialog<void>(
      context: context,
      builder: (_) => TaskDialog(controller: _controller!, parentId: widget.parentId),
    );
  }

  Future<void> _reject(FamilyTask task) async {
    // Das Ergebnis ist null bei „Abbrechen“, sonst die (vielleicht leere) Nachricht.
    final note = await showDialog<String>(context: context, builder: (_) => const _RejectDialog());
    if (note != null && mounted) {
      await runWithFeedback(
        context,
        () => _controller!.reviewTask(task, approve: false, note: note.isEmpty ? null : note),
      );
    }
  }

  Future<void> _manualBooking() {
    final l10n = AppLocalizations.of(context);
    final c = _controller!;
    return showAmountDialog(
      context,
      title: l10n.manualBooking,
      hint: l10n.manualHint,
      choosePot: true,
      withNote: true,
      allowNegative: true,
      parentWording: true,
      onSubmit: (input) => c.bookManual(pot: input.pot!, amountCents: input.amountCents, note: input.note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = _controller!;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.child.nickname}: ${l10n.budgetTitle}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        icon: const Icon(Icons.add_task),
        label: Text(l10n.taskCreate),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.loading) return const Center(child: CircularProgressIndicator());
            if (controller.failure != null) {
              return Center(child: Text(l10n.failure(controller.failure!)));
            }
            final allowance = controller.allowance;
            final submitted = controller.tasksWith(TaskStatus.submitted);
            final others = controller.tasks.where((t) => t.status != TaskStatus.submitted).toList();
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  // Aufgaben, die auf Bestätigung warten, stehen ganz oben.
                  Text(l10n.tasksParentHeading, style: theme.textTheme.titleLarge),
                  if (submitted.isNotEmpty) Text(l10n.pendingTasks(submitted.length)),
                  for (final task in submitted)
                    _ParentTaskCard(
                      task: task,
                      onApprove: () => runWithFeedback(context, () => controller.reviewTask(task, approve: true)),
                      onReject: () => _reject(task),
                    ),
                  if (controller.tasks.isEmpty) Text(l10n.tasksParentEmpty),
                  for (final task in others)
                    _ParentTaskCard(
                      task: task,
                      onApprove: task.canApprove
                          ? () => runWithFeedback(context, () => controller.reviewTask(task, approve: true))
                          : null,
                      onDelete: task.status == TaskStatus.approved
                          ? null
                          : () => runWithFeedback(context, () => controller.deleteTask(task)),
                    ),
                  const SizedBox(height: 24),
                  Text(l10n.allowanceHeading, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    allowance == null
                        ? l10n.allowanceNone
                        : l10n.allowanceCurrent(
                            formatCents(allowance.amountCents),
                            l10n.interval(allowance.interval),
                            formatDate(allowance.nextRunAt),
                          ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(onPressed: _setAllowance, child: Text(l10n.allowanceSet)),
                      if (allowance != null) TextButton(onPressed: _stopAllowance, child: Text(l10n.allowanceStop)),
                    ],
                  ),
                  Text(l10n.allowanceHint, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 24),
                  Text(l10n.balanceHeading, style: theme.textTheme.titleLarge),
                  for (final pot in Pot.values)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.pot(pot, parent: true)),
                      trailing: Text(
                        formatCents(controller.balances.of(pot)),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  TextButton(onPressed: _manualBooking, child: Text(l10n.manualBooking)),
                  const SizedBox(height: 16),
                  Text(l10n.ledgerHeading, style: theme.textTheme.titleLarge),
                  if (controller.ledger.isEmpty) Text(l10n.ledgerEmpty),
                  for (final entry in controller.ledger) LedgerTile(entry: entry, parent: true),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ParentTaskCard extends StatelessWidget {
  const _ParentTaskCard({required this.task, this.onApprove, this.onReject, this.onDelete});

  final FamilyTask task;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('parent-task-${task.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(task.title, style: theme.textTheme.titleMedium)),
                Text(task.isChore ? l10n.taskChore : formatCents(task.rewardCents)),
              ],
            ),
            Text(l10n.taskStatus(task.status), style: theme.textTheme.bodySmall),
            if (task.parentNote != null) Text(task.parentNote!, style: theme.textTheme.bodySmall),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                if (onDelete != null) TextButton(onPressed: onDelete, child: Text(l10n.taskDelete)),
                if (onReject != null) OutlinedButton(onPressed: onReject, child: Text(l10n.taskReject)),
                if (onApprove != null) FilledButton(onPressed: onApprove, child: Text(l10n.taskApprove)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AllowanceDialog extends StatefulWidget {
  const _AllowanceDialog({required this.controller});

  final TreasureController controller;

  @override
  State<_AllowanceDialog> createState() => _AllowanceDialogState();
}

class _AllowanceDialogState extends State<_AllowanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.controller.allowance == null ? '' : centsToInput(widget.controller.allowance!.amountCents),
  );
  late AllowanceInterval _interval = widget.controller.allowance?.interval ?? AllowanceInterval.weekly;
  DateTime _firstPayout = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstPayout,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _firstPayout = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    final ok = await runWithFeedback(
      context,
      () => widget.controller.setAllowance(
        amountCents: parseEuroInput(_amount.text),
        interval: _interval,
        firstPayout: _firstPayout,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.allowanceSet),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const ValueKey('allowance-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.amountLabel,
                hintText: l10n.amountHint,
                suffixText: '€',
                border: const OutlineInputBorder(),
              ),
              validator: (v) => l10n.amountProblem(validateAmount(v ?? '')),
            ),
            const SizedBox(height: 16),
            Text(l10n.allowanceIntervalLabel),
            const SizedBox(height: 8),
            SegmentedButton<AllowanceInterval>(
              segments: [
                ButtonSegment(value: AllowanceInterval.weekly, label: Text(l10n.allowanceWeeklyOption)),
                ButtonSegment(value: AllowanceInterval.monthly, label: Text(l10n.allowanceMonthlyOption)),
              ],
              selected: {_interval},
              onSelectionChanged: (s) => setState(() => _interval = s.first),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(l10n.allowanceFirstPayout(formatDate(_firstPayout))),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          key: const ValueKey('allowance-save'),
          onPressed: _busy ? null : _save,
          child: _busy ? const ButtonSpinner() : Text(l10n.saveButton),
        ),
      ],
    );
  }
}

class TaskDialog extends StatefulWidget {
  const TaskDialog({super.key, required this.controller, required this.parentId, this.initialTitle});

  final TreasureController controller;
  final String parentId;

  /// Vorschlag für den Titel, zum Beispiel ein Auftrag fürs echte Leben.
  final String? initialTitle;

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initialTitle);
  final _reward = TextEditingController();
  bool _chore = false;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _reward.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    final ok = await runWithFeedback(
      context,
      () => widget.controller.createTask(
        parentId: widget.parentId,
        title: _title.text,
        rewardCents: _chore ? 0 : parseEuroInput(_reward.text)!,
        isChore: _chore,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.taskCreate),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const ValueKey('task-title'),
              controller: _title,
              maxLength: 60,
              decoration: InputDecoration(labelText: l10n.taskTitleLabel, border: const OutlineInputBorder()),
              validator: (v) {
                final length = (v ?? '').trim().length;
                return length < 2 || length > 60 ? l10n.taskTitleInvalid : null;
              },
            ),
            CheckboxListTile(
              key: const ValueKey('task-chore'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _chore,
              onChanged: (v) => setState(() => _chore = v ?? false),
              title: Text(l10n.taskChoreLabel),
            ),
            if (!_chore)
              TextFormField(
                key: const ValueKey('task-reward'),
                controller: _reward,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.taskRewardLabel,
                  hintText: l10n.amountHint,
                  suffixText: '€',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => l10n.amountProblem(validateAmount(v ?? '', max: 10000)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          key: const ValueKey('task-save'),
          onPressed: _busy ? null : _save,
          child: _busy ? const ButtonSpinner() : Text(l10n.saveButton),
        ),
      ],
    );
  }
}

/// Fragt eine kurze Nachricht ans Kind ab, wenn Eltern eine Aufgabe ablehnen.
/// Eigenes Widget, damit das Textfeld erst nach dem Zuklappen freigegeben wird.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.taskReject),
      content: TextField(
        key: const ValueKey('reject-note'),
        controller: _note,
        maxLength: 200,
        decoration: InputDecoration(labelText: l10n.taskRejectNoteLabel, border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          key: const ValueKey('reject-submit'),
          onPressed: () => Navigator.of(context).pop(_note.text.trim()),
          child: Text(l10n.taskReject),
        ),
      ],
    );
  }
}
