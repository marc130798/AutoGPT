import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/budget_models.dart';
import '../../domain/family_models.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../../services/treasure_controller.dart';
import '../common/busy_action.dart';
import '../common/texts.dart';
import 'amount_dialog.dart';

/// Kinderbereich: Bordkasse, Schatztruhe, Glückstruhe, Wunschschätze und
/// Kassenbuch. Keine Kauf-Knöpfe, alle Beträge sind virtuell.
class TreasureScreen extends StatefulWidget {
  const TreasureScreen({super.key, required this.childId});

  final String childId;

  @override
  State<TreasureScreen> createState() => _TreasureScreenState();
}

class _TreasureScreenState extends State<TreasureScreen> {
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

  Future<void> _move() {
    final l10n = AppLocalizations.of(context);
    final c = _controller!;
    return showAmountDialog(
      context,
      title: l10n.moveTitle,
      chooseFromTo: true,
      onSubmit: (input) => c.move(from: input.from!, to: input.to!, amountCents: input.amountCents),
    );
  }

  Future<void> _spend(Pot pot) {
    final l10n = AppLocalizations.of(context);
    final c = _controller!;
    return showAmountDialog(
      context,
      title: pot == Pot.give ? l10n.giveTitle : l10n.spendTitle,
      withNote: true,
      onSubmit: (input) => c.recordSpending(pot: pot, amountCents: input.amountCents, note: input.note),
    );
  }

  Future<void> _newGoal() {
    final l10n = AppLocalizations.of(context);
    final c = _controller!;
    return showAmountDialog(
      context,
      title: l10n.goalNew,
      withTitle: true,
      amountLabel: l10n.goalTargetLabel,
      onSubmit: (input) => c.createGoal(title: input.title!, targetCents: input.amountCents),
    );
  }

  Future<void> _redeem(SavingsGoal goal) async {
    final l10n = AppLocalizations.of(context);
    final c = _controller!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.goalRedeemTitle(goal.title)),
        content: Text(l10n.goalRedeemBody(formatCents(goal.targetCents))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.goalRedeem)),
        ],
      ),
    );
    if (ok == true && mounted) await runWithFeedback(context, () => c.redeemGoal(goal));
  }

  Future<void> _deleteGoal(SavingsGoal goal) async {
    final l10n = AppLocalizations.of(context);
    final c = _controller!;
    final ok = await confirmDestructive(context, title: l10n.goalDeleteTitle(goal.title));
    if (ok && mounted) await runWithFeedback(context, () => c.deleteGoal(goal));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.treasureTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.loading) return const Center(child: CircularProgressIndicator());
            if (controller.failure != null) {
              return _Failure(kind: controller.failure!, onRetry: controller.load);
            }
            return RefreshIndicator(
              onRefresh: controller.load,
              child: _TreasureContent(
                controller: controller,
                onMove: _move,
                onSpend: _spend,
                onNewGoal: _newGoal,
                onRedeem: _redeem,
                onDeleteGoal: _deleteGoal,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TreasureContent extends StatelessWidget {
  const _TreasureContent({
    required this.controller,
    required this.onMove,
    required this.onSpend,
    required this.onNewGoal,
    required this.onRedeem,
    required this.onDeleteGoal,
  });

  final TreasureController controller;
  final VoidCallback onMove;
  final ValueChanged<Pot> onSpend;
  final VoidCallback onNewGoal;
  final ValueChanged<SavingsGoal> onRedeem;
  final ValueChanged<SavingsGoal> onDeleteGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final balances = controller.balances;
    final allowance = controller.allowance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final pot in Pot.values)
          _PotCard(
            pot: pot,
            balance: balances.of(pot),
            action: switch (pot) {
              Pot.spend => (l10n.treasureSpend, () => onSpend(Pot.spend)),
              Pot.give => (l10n.treasureGive, () => onSpend(Pot.give)),
              Pot.save => null,
            },
          ),
        const SizedBox(height: 4),
        OutlinedButton.icon(onPressed: onMove, icon: const Icon(Icons.swap_vert), label: Text(l10n.treasureMove)),
        const SizedBox(height: 12),
        Text(
          allowance == null
              ? l10n.treasureNoAllowance
              : '${l10n.treasureAllowance(formatCents(allowance.amountCents), l10n.interval(allowance.interval))}\n'
                    '${l10n.treasureAllowanceNext(formatDate(allowance.nextRunAt))}',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Text(l10n.goalsHeading, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (controller.goals.isEmpty) Text(l10n.goalsEmpty),
        for (final goal in [...controller.openGoals, ...controller.reachedGoals])
          _GoalCard(
            goal: goal,
            saved: balances.save,
            onRedeem: () => onRedeem(goal),
            onDelete: () => onDeleteGoal(goal),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: onNewGoal, icon: const Icon(Icons.add), label: Text(l10n.goalNew)),
        const SizedBox(height: 24),
        Text(l10n.ledgerHeading, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (controller.ledger.isEmpty) Text(l10n.ledgerEmpty),
        for (final entry in controller.ledger) LedgerTile(entry: entry, parent: false),
        const SizedBox(height: 16),
        Text(l10n.treasureVirtual, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _PotCard extends StatelessWidget {
  const _PotCard({required this.pot, required this.balance, required this.action});

  final Pot pot;
  final int balance;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final (icon, color, hint) = switch (pot) {
      Pot.spend => (Icons.sailing_outlined, palette.sea, l10n.potSpendHint),
      Pot.save => (Icons.inventory_2_outlined, palette.gold, l10n.potSaveHint),
      Pot.give => (Icons.volunteer_activism_outlined, palette.tala, l10n.potGiveHint),
    };
    return Card(
      key: ValueKey('pot-${pot.code}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.pot(pot, parent: false), style: theme.textTheme.titleMedium),
                  Text(hint, style: theme.textTheme.bodySmall),
                  if (action != null)
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: action!.$2,
                      child: Text(action!.$1),
                    ),
                ],
              ),
            ),
            Text(
              formatCents(balance),
              key: ValueKey('balance-${pot.code}'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.saved, required this.onRedeem, required this.onDelete});

  final SavingsGoal goal;
  final int saved;
  final VoidCallback onRedeem;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(goal.title, style: theme.textTheme.titleMedium)),
                if (goal.reached)
                  Text(l10n.goalReached, style: theme.textTheme.titleMedium?.copyWith(color: palette.success))
                else
                  IconButton(tooltip: l10n.goalDelete, onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal.progress(saved),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
              color: goal.reached ? palette.success : palette.gold,
            ),
            const SizedBox(height: 4),
            Text(
              goal.reached
                  ? formatCents(goal.targetCents)
                  : l10n.goalProgress(formatCents(saved.clamp(0, goal.targetCents)), formatCents(goal.targetCents)),
            ),
            if (goal.canRedeem(saved))
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(onPressed: onRedeem, child: Text(l10n.goalRedeem)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Eine Zeile im Kassenbuch (Kinder- und Elternbereich).
class LedgerTile extends StatelessWidget {
  const LedgerTile({super.key, required this.entry, required this.parent});

  final LedgerEntry entry;
  final bool parent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final positive = entry.amountCents > 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(entry.note ?? l10n.ledgerType(entry.type)),
      subtitle: Text(
        '${l10n.ledgerType(entry.type)} · ${l10n.pot(entry.pot, parent: parent)} · ${formatDate(entry.createdAt)}',
      ),
      trailing: Text(
        '${positive ? '+' : ''}${formatCents(entry.amountCents)}',
        style: TextStyle(fontWeight: FontWeight.w700, color: positive ? palette.success : palette.ink),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.kind, required this.onRetry});

  final FailureKind kind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.failure(kind), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.retryButton)),
          ],
        ),
      ),
    );
  }
}
