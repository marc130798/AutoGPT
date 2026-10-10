import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/budget_models.dart';
import '../../domain/family_models.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../../services/treasure_controller.dart';
import '../common/busy_action.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';
import 'amount_dialog.dart';
import 'wish_bottle_form.dart';

/// Kinderbereich: Bordkasse, Schatztruhe, Glückstruhe, Wunschschätze und
/// Kassenbuch, jeweils mit Bild und kinderleichter Erklärung; oben erklärt
/// Tala (die Zahlmeisterin). Keine Kauf-Knöpfe, alle Beträge sind virtuell.
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

  Future<void> _newWish() => showWishBottleDialog(context, onSubmit: _controller!.createWishBottle);

  /// Wunschschatz aus einer angespülten Flasche. Ohne Preis (oder unter 1 €) fragt die App danach.
  Future<void> _keepWish(WishBottle bottle) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final c = _controller!;
    final price = bottle.priceCents;
    final bool ok;
    if (price != null && price >= 100) {
      ok = await runWithFeedback(context, () => c.keepWish(bottle));
    } else {
      ok = await showAmountDialog(
        context,
        title: l10n.wishBottleKeepPrice(bottle.title),
        amountLabel: l10n.goalTargetLabel,
        onSubmit: (input) => c.keepWish(bottle, targetCents: input.amountCents),
      );
    }
    if (ok) messenger.showSnackBar(SnackBar(content: Text(l10n.wishBottleKept(bottle.title))));
  }

  Future<void> _dropWish(WishBottle bottle) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await runWithFeedback(context, () => _controller!.dropWish(bottle));
    if (ok) messenger.showSnackBar(SnackBar(content: Text(l10n.wishBottleDropped)));
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
      body: Stack(
        children: [
          // Schatzkammer im Bauch des Schiffs; ohne Bild warmes Holz.
          Positioned.fill(
            child: TaleriaAsset(
              AssetKeys.treasureBackground,
              fit: BoxFit.cover,
              fallback: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE9D3AE), Color(0xFFC79A63)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
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
                    onNewWish: _newWish,
                    onKeepWish: _keepWish,
                    onDropWish: _dropWish,
                  ),
                );
              },
            ),
          ),
        ],
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
    required this.onNewWish,
    required this.onKeepWish,
    required this.onDropWish,
  });

  final TreasureController controller;
  final VoidCallback onMove;
  final ValueChanged<Pot> onSpend;
  final VoidCallback onNewGoal;
  final ValueChanged<SavingsGoal> onRedeem;
  final ValueChanged<SavingsGoal> onDeleteGoal;
  final VoidCallback onNewWish;
  final ValueChanged<WishBottle> onKeepWish;
  final ValueChanged<WishBottle> onDropWish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final balances = controller.balances;
    final allowance = controller.allowance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SpeechBubble(speaker: Speaker.tala, pose: CharacterPose.wave, text: l10n.treasureTalaIntro),
        const SizedBox(height: 16),
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
        FilledButton.tonalIcon(onPressed: onMove, icon: const Icon(Icons.swap_vert), label: Text(l10n.treasureMove)),
        const SizedBox(height: 16),
        _Section(
          imageKey: null,
          fallbackIcon: Icons.event_repeat,
          title: l10n.allowanceHeading,
          children: [
            Text(
              allowance == null
                  ? l10n.treasureNoAllowance
                  : '${l10n.treasureAllowance(formatCents(allowance.amountCents), l10n.interval(allowance.interval))}\n'
                        '${l10n.treasureAllowanceNext(formatDate(allowance.nextRunAt))}',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
        _Section(
          imageKey: AssetKeys.iconWish,
          fallbackIcon: Icons.star_rounded,
          title: l10n.goalsHeading,
          intro: l10n.goalsIntro,
          children: [
            if (controller.goals.isEmpty) Text(l10n.goalsEmpty, style: theme.textTheme.bodyLarge),
            for (final goal in [...controller.openGoals, ...controller.reachedGoals])
              _GoalCard(
                goal: goal,
                saved: balances.save,
                onRedeem: () => onRedeem(goal),
                onDelete: () => onDeleteGoal(goal),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: onNewGoal, icon: const Icon(Icons.add), label: Text(l10n.goalNew)),
          ],
        ),
        if (controller.wishBottlesUnlocked)
          _Section(
            imageKey: null,
            fallbackIcon: Icons.water_drop_outlined,
            title: l10n.wishBottlesHeading,
            intro: l10n.wishBottlesIntro,
            children: [
              if (controller.dueWishBottles.isEmpty && controller.driftingWishBottles.isEmpty)
                Text(l10n.wishBottlesEmpty),
              for (final bottle in controller.dueWishBottles)
                _WishDueCard(bottle: bottle, onKeep: () => onKeepWish(bottle), onDrop: () => onDropWish(bottle)),
              for (final bottle in controller.driftingWishBottles)
                ListTile(
                  key: ValueKey('wish-drifting-${bottle.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.water_drop_outlined),
                  title: Text(bottle.title),
                  subtitle: Text(l10n.wishBottleDrifting(formatDate(bottle.remindAt))),
                  trailing: TextButton(onPressed: () => onDropWish(bottle), child: Text(l10n.wishBottleDrop)),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('wish-new'),
                onPressed: onNewWish,
                icon: const Icon(Icons.water_drop_outlined),
                label: Text(l10n.wishBottleNew),
              ),
            ],
          ),
        _Section(
          imageKey: AssetKeys.iconLedger,
          fallbackIcon: Icons.menu_book_rounded,
          title: l10n.ledgerHeading,
          intro: l10n.ledgerIntro,
          children: [
            if (controller.ledger.isEmpty) Text(l10n.ledgerEmpty, style: theme.textTheme.bodyLarge),
            for (final entry in controller.ledger) LedgerTile(entry: entry, parent: false),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.palette.paper.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(l10n.treasureVirtual, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

/// Ein Abschnitt auf Papier: Bild, Überschrift, kurze Erklärung, Inhalt.
class _Section extends StatelessWidget {
  const _Section({
    required this.imageKey,
    required this.fallbackIcon,
    required this.title,
    required this.children,
    this.intro,
  });

  /// Bild neben der Überschrift; ohne Bild das Symbol [fallbackIcon].
  final String? imageKey;
  final IconData fallbackIcon;
  final String title;
  final String? intro;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final icon = CircleAvatar(
      radius: 26,
      backgroundColor: palette.sand,
      child: Icon(fallbackIcon, color: palette.seaDeep, size: 28),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.paper.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2C27A), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33081C30), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: imageKey == null ? icon : TaleriaAsset(imageKey!, width: 56, height: 56, fallback: icon),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
            ],
          ),
          if (intro != null) ...[const SizedBox(height: 8), Text(intro!, style: theme.textTheme.bodyMedium)],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
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
    final (image, icon, color, hint) = switch (pot) {
      Pot.spend => (AssetKeys.potSpend, Icons.sailing_outlined, palette.sea, l10n.potSpendHint),
      Pot.save => (AssetKeys.iconTreasure, Icons.inventory_2_outlined, palette.gold, l10n.potSaveHint),
      Pot.give => (AssetKeys.potGive, Icons.volunteer_activism_outlined, palette.tala, l10n.potGiveHint),
    };
    return Container(
      key: ValueKey('pot-${pot.code}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.paper.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2C27A), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33081C30), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bild der Truhe; ohne Bild ein farbiger Kreis mit Symbol.
          TaleriaAsset(
            image,
            width: 76,
            height: 76,
            fallback: Center(
              child: CircleAvatar(
                radius: 30,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.pot(pot, parent: false),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      formatCents(balance),
                      key: ValueKey('balance-${pot.code}'),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(hint, style: theme.textTheme.bodyMedium),
                if (action != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: action!.$2,
                    icon: const Icon(Icons.edit_note, size: 20),
                    label: Text(action!.$1),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Angespülte Wunschflasche: Das Kind entscheidet, ob es den Wunsch noch will.
class _WishDueCard extends StatelessWidget {
  const _WishDueCard({required this.bottle, required this.onKeep, required this.onDrop});

  final WishBottle bottle;
  final VoidCallback onKeep;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('wish-due-${bottle.id}'),
      color: context.palette.sand,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.wishBottleDueQuestion(bottle.title), style: theme.textTheme.titleMedium),
            if (bottle.priceCents != null) Text(formatCents(bottle.priceCents!)),
            const SizedBox(height: 12),
            FilledButton(onPressed: onKeep, child: Text(l10n.wishBottleKeep)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onDrop, child: Text(l10n.wishBottleDrop)),
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
