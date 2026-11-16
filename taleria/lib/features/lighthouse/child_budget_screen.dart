import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/taleria_palette.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/assets/asset_keys.dart';
import '../../domain/budget_models.dart';
import '../../domain/family_models.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../../services/treasure_controller.dart';
import '../common/busy_action.dart';
import '../common/button_spinner.dart';
import '../common/texts.dart';
import '../treasure/amount_dialog.dart';
import '../treasure/ledger_tile.dart';

/// Welche Seite: Aufträge erteilen oder Taschengeld und Schatztruhe
/// (Marcs Wunsch am 16.11.2026: zwei eigene Menüpunkte statt einer Seite).
enum BudgetSection { tasks, money }

/// Leuchtturm: Aufgaben eines Kindes ([BudgetSection.tasks]) oder sein Geld
/// ([BudgetSection.money]: Kontostand, Taschengeld, Lern-Belohnung,
/// Sparziele und Kassenbuch).
class ChildBudgetScreen extends StatefulWidget {
  const ChildBudgetScreen({super.key, required this.child, required this.parentId, this.section = BudgetSection.money});

  final ChildProfile child;
  final String parentId;
  final BudgetSection section;

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

  Future<void> _setLearning() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _LearningDialog(controller: _controller!),
    );
  }

  Future<void> _stopLearning() =>
      runWithFeedback(context, () => _controller!.setLearningRewards(stationCents: 0, islandCents: 0));

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

  /// Geld dazugeben (nur positiv): Geschenk, Geld von Oma …
  Future<void> _addMoney() {
    final l10n = AppLocalizations.of(context);
    final c = _controller!;
    return showAmountDialog(
      context,
      title: l10n.moneyAdd,
      hint: l10n.moneyAddHint,
      withNote: true,
      onSubmit: (input) => c.bookManual(amountCents: input.amountCents, note: input.note),
    );
  }

  Future<void> _manualBooking() {
    final l10n = AppLocalizations.of(context);
    final c = _controller!;
    return showAmountDialog(
      context,
      title: l10n.manualBooking,
      hint: l10n.manualHint,
      withNote: true,
      allowNegative: true,
      onSubmit: (input) => c.bookManual(amountCents: input.amountCents, note: input.note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller!;
    final tasks = widget.section == BudgetSection.tasks;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.child.nickname}: ${tasks ? l10n.budgetTasksTitle : l10n.budgetMoneyTitle}')),
      floatingActionButton: tasks
          ? FloatingActionButton.extended(
              onPressed: _createTask,
              icon: const Icon(Icons.add_task),
              label: Text(l10n.taskCreate),
            )
          : null,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.loading) return const Center(child: CircularProgressIndicator());
            if (controller.failure != null) {
              return Center(child: Text(l10n.failure(controller.failure!)));
            }
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: tasks ? _taskList(context, controller) : _moneyList(context, controller),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Aufträge: zuerst, was auf Bestätigung wartet, dann offene, erledigte
  /// und abgelehnte zugeklappt unten.
  List<Widget> _taskList(BuildContext context, TreasureController controller) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final submitted = controller.tasksWith(TaskStatus.submitted);
    final open = controller.tasksWith(TaskStatus.open);
    final done = controller.tasks
        .where((t) => t.status == TaskStatus.approved || t.status == TaskStatus.rejected)
        .toList();
    Widget card(FamilyTask task) => _ParentTaskCard(
      task: task,
      onApprove: task.canApprove
          ? () => runWithFeedback(context, () => controller.reviewTask(task, approve: true))
          : null,
      onReject: task.status == TaskStatus.submitted ? () => _reject(task) : null,
      onDelete: task.status == TaskStatus.approved || task.status == TaskStatus.submitted
          ? null
          : () => runWithFeedback(context, () => controller.deleteTask(task)),
    );
    return [
      Text(l10n.tasksParentHeading, style: theme.textTheme.titleLarge),
      if (controller.tasks.isEmpty) Text(l10n.tasksParentEmpty),
      if (submitted.isNotEmpty) ...[
        const SizedBox(height: 8),
        _SectionLabel(icon: Icons.notifications_active_outlined, text: l10n.pendingTasks(submitted.length)),
        for (final task in submitted) card(task),
      ],
      if (open.isNotEmpty) ...[
        const SizedBox(height: 8),
        _SectionLabel(icon: Icons.radio_button_unchecked, text: l10n.parentTasksOpen),
        for (final task in open) card(task),
      ],
      if (done.isNotEmpty)
        Card(
          margin: const EdgeInsets.only(top: 12),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: const ValueKey('parent-tasks-done'),
            leading: const Icon(Icons.task_alt),
            title: Text(l10n.parentTasksDone(done.length)),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            children: [for (final task in done) card(task)],
          ),
        ),
    ];
  }

  /// Geld: Kontostand groß oben, darunter Taschengeld, Lern-Belohnung,
  /// Sparziele und das Kassenbuch, jeweils als eigene Karte.
  List<Widget> _moneyList(BuildContext context, TreasureController controller) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final allowance = controller.allowance;
    final balances = controller.balances;
    final reports = controller.pendingReports;
    return [
      // Gemeldetes Geld wartet ganz oben auf die Eltern.
      if (reports.isNotEmpty)
        _MoneyCard(
          icon: Icons.card_giftcard,
          title: l10n.moneyReportsHeading,
          children: [
            for (final report in reports)
              Padding(
                key: ValueKey('money-report-${report.id}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.moneyReportLine(formatCents(report.amountCents), formatDate(report.createdAt)),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (report.note != null) Text(report.note!),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              runWithFeedback(context, () => controller.reviewMoneyReport(report, approve: false)),
                          child: Text(l10n.taskReject),
                        ),
                        FilledButton(
                          key: ValueKey('money-report-approve-${report.id}'),
                          onPressed: () =>
                              runWithFeedback(context, () => controller.reviewMoneyReport(report, approve: true)),
                          child: Text(l10n.taskApprove),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      _MoneyCard(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.balanceHeading,
        children: [
          Row(
            children: [
              for (final (pot, image) in const [(Pot.spend, AssetKeys.potSpend), (Pot.save, AssetKeys.iconTreasure)])
                Expanded(
                  child: Container(
                    key: ValueKey('parent-balance-${pot.code}'),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: palette.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        TaleriaAsset(image, width: 56, height: 56, fit: BoxFit.contain),
                        const SizedBox(height: 4),
                        Text(
                          formatCents(balances.of(pot)),
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          l10n.pot(pot, parent: true),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.moneyTotal(formatCents(balances.spend + balances.save)),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                key: const ValueKey('money-add'),
                onPressed: _addMoney,
                icon: const Icon(Icons.add),
                label: Text(l10n.moneyAdd),
              ),
              TextButton(onPressed: _manualBooking, child: Text(l10n.manualBooking)),
            ],
          ),
        ],
      ),
      _MoneyCard(
        icon: Icons.event_repeat_outlined,
        title: l10n.allowanceHeading,
        children: [
          if (allowance == null)
            Text(l10n.allowanceNone)
          else ...[
            Text(
              l10n.allowanceAmountLine(formatCents(allowance.amountCents), l10n.interval(allowance.interval)),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(l10n.allowanceNextRun(formatDate(allowance.nextRunAt))),
          ],
          Wrap(
            spacing: 8,
            children: [
              TextButton(onPressed: _setAllowance, child: Text(l10n.allowanceSet)),
              if (allowance != null) TextButton(onPressed: _stopAllowance, child: Text(l10n.allowanceStop)),
            ],
          ),
          Text(l10n.allowanceHint, style: theme.textTheme.bodySmall),
        ],
      ),
      _MoneyCard(
        icon: Icons.emoji_events_outlined,
        title: l10n.rewardHeading,
        children: [_LearningSection(rewards: controller.learningRewards, onSet: _setLearning, onStop: _stopLearning)],
      ),
      _MoneyCard(
        icon: Icons.star_outline,
        title: l10n.parentGoalsHeading,
        children: [
          if (controller.openGoals.isEmpty) Text(l10n.goalsParentEmpty),
          for (final goal in controller.openGoals)
            Padding(
              key: ValueKey('parent-goal-${goal.id}'),
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.parentGoalLine(goal.title, formatCents(goal.savedCents), formatCents(goal.targetCents)),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: goal.targetCents == 0 ? 0 : (goal.savedCents / goal.targetCents).clamp(0, 1),
                      minHeight: 10,
                      color: palette.gold,
                      backgroundColor: palette.gold.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      _MoneyCard(
        icon: Icons.menu_book_outlined,
        title: l10n.ledgerHeading,
        children: [
          if (controller.ledger.isEmpty) Text(l10n.ledgerEmpty),
          for (final entry in controller.ledger) LedgerTile(entry: entry, parent: true),
        ],
      ),
    ];
  }
}

/// Karte mit Symbol und Überschrift für einen Bereich der Geld-Seite.
class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.icon, required this.title, required this.children});

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: palette.gold.withValues(alpha: 0.25),
                  child: Icon(icon, size: 20, color: palette.seaDeep),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Kleine Überschrift über einer Gruppe von Aufgaben.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: context.palette.seaDeep),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleSmall)),
      ],
    ),
  );
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
            Text(
              _statusLine(l10n, task),
              key: ValueKey('parent-task-date-${task.id}'),
              style: theme.textTheme.bodySmall,
            ),
            if (task.status == TaskStatus.approved && !task.isChore && task.rewardCents > 0)
              Text(
                l10n.taskParentBooked(formatCents(task.rewardCents), l10n.pot(Pot.spend, parent: true)),
                style: theme.textTheme.bodySmall,
              ),
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

/// Stand der Aufgabe mit Datum, zum Beispiel „Bestätigt am 10.10.2026“.
String _statusLine(AppLocalizations l10n, FamilyTask task) {
  final (DateTime? at, String Function(String) withDate, String plain) = switch (task.status) {
    TaskStatus.open => (task.createdAt, l10n.taskParentOpenSince, l10n.taskStatusOpen),
    TaskStatus.submitted => (task.submittedAt, l10n.taskParentSubmittedOn, l10n.taskStatusSubmitted),
    TaskStatus.approved => (task.reviewedAt, l10n.taskParentApprovedOn, l10n.taskStatusApproved),
    TaskStatus.rejected => (task.reviewedAt, l10n.taskParentRejectedOn, l10n.taskStatusRejected),
  };
  return at == null ? plain : withDate(formatDate(at));
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

/// Lern-Belohnung im Leuchtturm (freiwillig, Marcs Wunsch am 16.11.2026):
/// was eingestellt ist, eine Schätzung pro Monat und ein Hinweis für Eltern.
class _LearningSection extends StatelessWidget {
  const _LearningSection({required this.rewards, required this.onSet, required this.onStop});

  final LearningRewards rewards;
  final VoidCallback onSet;
  final VoidCallback onStop;

  /// Bei 2 Stationen pro Woche: gut 8,7 Stationen und 1,2 Inseln im Monat
  /// (eine Insel hat 7 Stationen).
  static int monthlyCents(LearningRewards r) => (r.stationCents * 26 / 3 + r.islandCents * 26 / 21).round();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('learning-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!rewards.active) Text(l10n.learningNone),
        if (rewards.stationCents > 0) Text(l10n.learningPerStation(formatCents(rewards.stationCents))),
        if (rewards.islandCents > 0) Text(l10n.learningPerIsland(formatCents(rewards.islandCents))),
        if (rewards.active)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.learningMonthly(formatCents(monthlyCents(rewards))), style: theme.textTheme.bodyMedium),
          ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(key: const ValueKey('learning-set'), onPressed: onSet, child: Text(l10n.learningSet)),
            if (rewards.active)
              TextButton(key: const ValueKey('learning-off'), onPressed: onStop, child: Text(l10n.learningOff)),
          ],
        ),
        Text(l10n.rewardHint, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _LearningDialog extends StatefulWidget {
  const _LearningDialog({required this.controller});

  final TreasureController controller;

  @override
  State<_LearningDialog> createState() => _LearningDialogState();
}

class _LearningDialogState extends State<_LearningDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _station = TextEditingController(text: _initial(widget.controller.learningRewards.stationCents));
  late final _island = TextEditingController(text: _initial(widget.controller.learningRewards.islandCents));
  bool _busy = false;

  static String _initial(int cents) => cents > 0 ? centsToInput(cents) : '';

  @override
  void dispose() {
    _station.dispose();
    _island.dispose();
    super.dispose();
  }

  /// Leer = keine, sonst ein gültiger Betrag.
  String? _validate(AppLocalizations l10n, String? v) =>
      (v ?? '').trim().isEmpty ? null : l10n.amountProblem(validateAmount(v!));

  int _cents(TextEditingController c) => c.text.trim().isEmpty ? 0 : parseEuroInput(c.text)!;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    final ok = await runWithFeedback(
      context,
      () => widget.controller.setLearningRewards(stationCents: _cents(_station), islandCents: _cents(_island)),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      hintText: l10n.learningEmptyHint,
      suffixText: '€',
      border: const OutlineInputBorder(),
    );
    return AlertDialog(
      title: Text(l10n.learningSet),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const ValueKey('learning-station'),
              controller: _station,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: deco(l10n.learningStationLabel),
              validator: (v) => _validate(l10n, v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('learning-island'),
              controller: _island,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: deco(l10n.learningIslandLabel),
              validator: (v) => _validate(l10n, v),
            ),
            const SizedBox(height: 12),
            Text(l10n.rewardHint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          key: const ValueKey('learning-save'),
          onPressed: _busy ? null : _save,
          child: _busy ? const ButtonSpinner() : Text(l10n.saveButton),
        ),
      ],
    );
  }
}
