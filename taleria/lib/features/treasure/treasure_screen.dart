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
import '../common/menu_music.dart';
import '../common/page_intro.dart';
import '../common/scene_background.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';
import '../progress/celebration.dart';
import 'amount_dialog.dart';
import 'ledger_tile.dart';
import 'pot_detail_screen.dart';
import 'wish_bottle_form.dart';

/// Kinderbereich: eine Schatztruhe (entschieden mit Marc am 29.10.2026) mit
/// freiem Geld und Geld, das für Wunschschätze zurückgelegt ist; dazu
/// Taschengeld, Wunschflaschen und Kassenbuch, jeweils mit kinderleichter
/// Erklärung. Oben erklärt Tala (die Zahlmeisterin). Keine Kauf-Knöpfe, alle
/// Beträge sind virtuell.
class TreasureScreen extends StatefulWidget {
  const TreasureScreen({super.key, required this.childId});

  final String childId;

  @override
  State<TreasureScreen> createState() => _TreasureScreenState();
}

class _TreasureScreenState extends State<TreasureScreen> {
  TreasureController? _controller;

  /// Stand der Truhen beim letzten Besuch (`null` beim ersten Besuch).
  Map<String, int>? _seen;
  bool _seenLoaded = false;
  PotBalances? _remembered;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = TreasureController(budget: AppScope.of(context).budget!, childId: widget.childId)..load();
      _loadSeen();
    }
  }

  Future<void> _loadSeen() async {
    Map<String, int>? seen;
    try {
      seen = await AppScope.of(context).settings.potsSeen(widget.childId);
    } catch (_) {
      // Ohne gemerkten Stand fliegen eben keine Taler.
    }
    if (!mounted) return;
    setState(() {
      _seen = seen;
      _seenLoaded = true;
    });
  }

  /// Jetzigen Stand merken: Beim nächsten Besuch fliegt nur neues Geld in die Truhe.
  void _remember(PotBalances balances) {
    final last = _remembered;
    if (last != null && Pot.values.every((p) => last.of(p) == balances.of(p))) return;
    _remembered = balances;
    final settings = AppScope.of(context).settings;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      settings.setPotsSeen(widget.childId, {for (final p in Pot.values) p.code: balances.of(p)}).ignore();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _spend() {
    final l10n = AppLocalizations.of(context);
    final c = _controller!;
    return showAmountDialog(
      context,
      title: l10n.spendTitle,
      withNote: true,
      onSubmit: (input) => c.recordSpending(amountCents: input.amountCents, note: input.note),
    );
  }

  Future<void> _saveFor(SavingsGoal goal) {
    final l10n = AppLocalizations.of(context);
    final c = _controller!;
    return showAmountDialog(
      context,
      title: l10n.goalSaveTitle(goal.title),
      hint: l10n.goalSaveHint(formatCents(c.balances.free), formatCents(goal.missingCents)),
      onSubmit: (input) => c.saveForGoal(goal, input.amountCents),
    );
  }

  Future<void> _takeBack(SavingsGoal goal) {
    final l10n = AppLocalizations.of(context);
    final c = _controller!;
    return showAmountDialog(
      context,
      title: l10n.goalTakeBackTitle(goal.title),
      hint: l10n.goalTakeBackHint(formatCents(goal.savedCents)),
      onSubmit: (input) => c.takeFromGoal(goal, input.amountCents),
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

  void _openPot(Pot pot) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PotDetailScreen(controller: _controller!, pot: pot),
    ),
  );

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
    final ok = await confirmDestructive(
      context,
      title: l10n.goalDeleteTitle(goal.title),
      body: goal.savedCents > 0 ? l10n.goalDeleteBody(formatCents(goal.savedCents)) : null,
    );
    if (ok && mounted) await runWithFeedback(context, () => c.deleteGoal(goal));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller!;
    return MenuMusic(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.treasureTitle)),
        // Schatzkammer im Bauch des Schiffs; ohne Bild warmes Holz.
        body: SceneBackground(
          assetKey: AssetKeys.treasureBackground,
          child: SafeArea(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.loading || !_seenLoaded) return const Center(child: CircularProgressIndicator());
                if (controller.failure != null) {
                  return _Failure(kind: controller.failure!, onRetry: controller.load);
                }
                _remember(controller.balances);
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: _TreasureContent(
                    controller: controller,
                    onSpend: _spend,
                    onSaveFor: _saveFor,
                    onTakeBack: _takeBack,
                    onNewGoal: _newGoal,
                    onRedeem: _redeem,
                    onDeleteGoal: _deleteGoal,
                    onNewWish: _newWish,
                    onKeepWish: _keepWish,
                    onDropWish: _dropWish,
                    onOpenPot: _openPot,
                    seen: _seen,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TreasureContent extends StatelessWidget {
  const _TreasureContent({
    required this.controller,
    required this.onSpend,
    required this.onSaveFor,
    required this.onTakeBack,
    required this.onNewGoal,
    required this.onRedeem,
    required this.onDeleteGoal,
    required this.onNewWish,
    required this.onKeepWish,
    required this.onDropWish,
    required this.onOpenPot,
    this.seen,
  });

  final TreasureController controller;

  /// Stand beim letzten Besuch: Was seitdem dazugekommen ist, fliegt hinein.
  final Map<String, int>? seen;
  final VoidCallback onSpend;
  final ValueChanged<SavingsGoal> onSaveFor;
  final ValueChanged<SavingsGoal> onTakeBack;
  final VoidCallback onNewGoal;
  final ValueChanged<SavingsGoal> onRedeem;
  final ValueChanged<SavingsGoal> onDeleteGoal;
  final VoidCallback onNewWish;
  final ValueChanged<WishBottle> onKeepWish;
  final ValueChanged<WishBottle> onDropWish;
  final ValueChanged<Pot> onOpenPot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final balances = controller.balances;
    final allowance = controller.allowance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageIntro(
          childId: controller.childId,
          page: 'treasure',
          children: [SpeechBubble(speaker: Speaker.tala, pose: CharacterPose.wave, text: l10n.treasureTalaIntro)],
        ),
        const SizedBox(height: 16),
        _ChestCard(
          balances: balances,
          seen: seen?.values.fold<int>(0, (sum, v) => sum + v),
          onOpen: () => onOpenPot(Pot.spend),
          onSpend: onSpend,
        ),
        const SizedBox(height: 4),
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
                free: balances.free,
                onSave: () => onSaveFor(goal),
                onTakeBack: () => onTakeBack(goal),
                onRedeem: () => onRedeem(goal),
                onDelete: () => onDeleteGoal(goal),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: onNewGoal, icon: const Icon(Icons.add), label: Text(l10n.goalNew)),
          ],
        ),
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

/// Die Schatztruhe: alles zusammen, darunter was frei ist und was für
/// Wunschschätze zurückgelegt ist. Antippen (oder „Was ist drin?“) zeigt,
/// wie sich das freie Geld zusammensetzt.
class _ChestCard extends StatelessWidget {
  const _ChestCard({required this.balances, required this.onOpen, required this.onSpend, this.seen});

  final PotBalances balances;

  /// Stand beim letzten Besuch (`null` = unbekannt, dann fliegt nichts).
  final int? seen;
  final VoidCallback onOpen;
  final VoidCallback onSpend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final total = balances.total;
    Widget part(Pot pot, IconData icon, Color color) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.pot(pot, parent: false), style: theme.textTheme.titleSmall),
                Text(potHint(l10n, pot), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatCents(balances.of(pot)),
            key: ValueKey('balance-${pot.code}'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
    return Padding(
      key: const ValueKey('treasure-chest'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: palette.paper.withValues(alpha: 0.95),
        elevation: 3,
        shadowColor: const Color(0x55081C30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2C27A), width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CoinsIntoChest(
                      chest: TaleriaAsset(
                        AssetKeys.iconTreasure,
                        width: 84,
                        height: 84,
                        fallback: CircleAvatar(
                          radius: 34,
                          backgroundColor: palette.gold,
                          child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 34),
                        ),
                      ),
                      size: 84,
                      from: seen ?? total,
                      to: total,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.treasureTotalLabel, style: theme.textTheme.titleMedium),
                          CountUp(
                            from: seen != null && seen! < total ? seen! : total,
                            value: total,
                            builder: (context, cents) => Text(
                              formatCents(cents),
                              key: const ValueKey('balance-total'),
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                part(Pot.spend, Icons.shopping_bag_outlined, palette.sea),
                part(Pot.save, Icons.star_rounded, palette.gold),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      key: const ValueKey('pot-open-spend'),
                      onPressed: onOpen,
                      icon: const Icon(Icons.list_alt_rounded, size: 20),
                      label: Text(l10n.potDetailsButton),
                    ),
                    TextButton.icon(
                      key: const ValueKey('treasure-spend'),
                      onPressed: onSpend,
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: Text(l10n.treasureSpend),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
  const _GoalCard({
    required this.goal,
    required this.free,
    required this.onSave,
    required this.onTakeBack,
    required this.onRedeem,
    required this.onDelete,
  });

  final SavingsGoal goal;

  /// Freies Geld: Nur dann lässt sich etwas zurücklegen.
  final int free;
  final VoidCallback onSave;
  final VoidCallback onTakeBack;
  final VoidCallback onRedeem;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Card(
      key: ValueKey('goal-${goal.id}'),
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
              value: goal.progress,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
              color: goal.reached || goal.canRedeem ? palette.success : palette.gold,
            ),
            const SizedBox(height: 4),
            Text(
              goal.reached
                  ? formatCents(goal.targetCents)
                  : l10n.goalProgress(formatCents(goal.savedCents), formatCents(goal.targetCents)),
              key: ValueKey('goal-progress-${goal.id}'),
            ),
            if (!goal.reached)
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  if (goal.savedCents > 0)
                    TextButton(
                      key: ValueKey('goal-take-back-${goal.id}'),
                      onPressed: onTakeBack,
                      child: Text(l10n.goalTakeBack),
                    ),
                  if (goal.canRedeem)
                    FilledButton(
                      key: ValueKey('goal-redeem-${goal.id}'),
                      onPressed: onRedeem,
                      child: Text(l10n.goalRedeem),
                    )
                  else
                    FilledButton.tonal(
                      key: ValueKey('goal-save-${goal.id}'),
                      onPressed: free > 0 ? onSave : null,
                      child: Text(l10n.goalSave),
                    ),
                ],
              ),
          ],
        ),
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
