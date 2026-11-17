import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';
import 'game_scene.dart';

/// Sparschwein füttern: Das Kind wählt einen Sparplan (Taler pro Woche) und
/// sieht die Rechnung. Dann füttert es Woche für Woche das Schwein; der Rest
/// kommt in die Hosentasche. Manche Wochen locken mit etwas zum Kaufen oder
/// bringen ein Geschenk. Am Ende zählt, ob es für den Wunschschatz reicht.
class PiggyBankGameView extends StatefulWidget {
  const PiggyBankGameView({super.key, required this.game, required this.onFinished});

  final GameInfo game;
  final ValueChanged<int> onFinished;

  @override
  State<PiggyBankGameView> createState() => _PiggyBankGameViewState();
}

class _PiggyBankGameViewState extends State<PiggyBankGameView> {
  late final PiggyBankGame _game = PiggyBankGame(widget.game);

  /// Gewählter Plan, bevor das Kind startet.
  int? _choice;
  final _pigKey = GlobalKey();
  final _feedKey = GlobalKey();

  void _feed() {
    playGameSound(context, AssetKeys.soundCoin);
    flyThing(
      context,
      from: _feedKey,
      to: _pigKey,
      child: const Icon(Icons.monetization_on, size: 32, color: Color(0xFFE0A526)),
    );
    setState(_game.feed);
  }

  void _next() {
    setState(_game.nextWeek);
    if (_game.finished) playGameSound(context, AssetKeys.soundCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final game = _game;
    final spec = game.spec;

    if (!game.started) return _plan(context);

    final Widget button;
    if (game.finished) {
      button = FilledButton(
        key: const ValueKey('game-finish'),
        onPressed: () => widget.onFinished(game.stars),
        child: Text(l10n.realGameToResult),
      );
    } else if (game.over) {
      button = FilledButton.icon(
        key: const ValueKey('piggy-again'),
        onPressed: () => setState(() {
          game.restart();
          _choice = null;
        }),
        icon: const Icon(Icons.replay_rounded),
        label: Text(l10n.piggyAgain),
      );
    } else if (!game.fed) {
      button = FilledButton.icon(
        key: const ValueKey('piggy-feed'),
        onPressed: _feed,
        icon: SizedBox(key: _feedKey, child: const Icon(Icons.savings_rounded)),
        label: Text(l10n.piggyFeed(game.plan!)),
      );
    } else {
      button = FilledButton(
        key: const ValueKey('piggy-next'),
        onPressed: game.weekDone ? _next : null,
        child: Text(l10n.piggyNextWeek),
      );
    }

    final theme = Theme.of(context);
    final palette = context.palette;
    return GameFrame(
      game: widget.game,
      button: button,
      children: [
        _pigCard(context),
        const SizedBox(height: 8),
        if (!game.over) ...[
          Text(
            l10n.piggyWeek(game.week + 1, game.weeks),
            key: ValueKey('piggy-week-${game.week}'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          for (final line in game.current.scene) ...[const SizedBox(height: 8), SpeechBubble.line(line)],
          if (game.fed && game.current.event != null) ..._event(context, game.current.event!),
        ] else if (game.reached) ...[
          Text(
            l10n.piggyReached(spec.goal),
            key: const ValueKey('piggy-reached'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: palette.success),
          ),
          if (game.bought.isNotEmpty) Text(l10n.piggyBought(game.bought.join(', ')), textAlign: TextAlign.center),
        ] else ...[
          Text(
            l10n.piggyMissed(game.pig, spec.goalPrice),
            key: const ValueKey('piggy-missed'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: palette.coral),
          ),
          Text(l10n.piggyPlanCheck(game.weeks, game.plan!, game.planTotal(game.plan!)), textAlign: TextAlign.center),
        ],
      ],
    );
  }

  /// Versuchung oder Geschenk dieser Woche.
  List<Widget> _event(BuildContext context, PiggyEvent event) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final game = _game;
    final open = game.eventOpen;
    return [
      const SizedBox(height: 8),
      SpeechBubble.line(event.line),
      const SizedBox(height: 4),
      Text(
        event.gift ? l10n.piggyGift(event.price) : l10n.piggyOffer(event.item, event.price),
        key: const ValueKey('piggy-event'),
        textAlign: TextAlign.center,
        style: theme.textTheme.titleSmall,
      ),
      if (open) ...[
        const SizedBox(height: 8),
        if (event.gift) ...[
          FilledButton(
            key: const ValueKey('piggy-gift-pig'),
            onPressed: () => setState(() => game.takeGift(intoPig: true)),
            child: Text(l10n.piggyGiftPig),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('piggy-gift-pocket'),
            onPressed: () => setState(() => game.takeGift(intoPig: false)),
            child: Text(l10n.piggyGiftPocket),
          ),
        ] else ...[
          OutlinedButton(
            key: const ValueKey('piggy-buy-pocket'),
            onPressed: game.canBuyFromPocket ? () => setState(() => game.buy(fromPig: false)) : null,
            child: Text(l10n.piggyBuyPocket),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('piggy-buy-pig'),
            onPressed: game.canBuyFromPig ? () => setState(() => game.buy(fromPig: true)) : null,
            child: Text(l10n.piggyBuyPig),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const ValueKey('piggy-skip'),
            onPressed: () => setState(game.skip),
            child: Text(l10n.piggySkip),
          ),
        ],
      ],
    ];
  }

  /// Sparschwein und Hosentasche mit Balken bis zum Wunschschatz.
  Widget _pigCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final price = game.spec.goalPrice;
    return Card(
      key: _pigKey,
      color: palette.paper,
      shape: gameCardShape,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.piggyGoal(game.spec.goal, price), style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.savings_rounded, size: 36, color: palette.coral),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.piggyPig(game.pig, price), key: const ValueKey('piggy-pig')),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: price == 0 ? 0 : (game.pig / price).clamp(0, 1).toDouble(),
                          minHeight: 10,
                          color: game.reached ? palette.success : palette.gold,
                          backgroundColor: palette.sand,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.piggyPocket(game.pocket),
              key: const ValueKey('piggy-pocket'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Plan wählen: Taler pro Woche, darunter die Rechnung zum gewählten Plan.
  Widget _plan(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final spec = game.spec;
    final choice = _choice;
    return GameFrame(
      game: widget.game,
      button: FilledButton(
        key: const ValueKey('piggy-start'),
        onPressed: choice == null ? null : () => setState(() => game.choosePlan(choice)),
        child: Text(l10n.piggyStart),
      ),
      children: [
        Text(
          l10n.piggyGoal(spec.goal, spec.goalPrice),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        Text(l10n.piggyIncome(spec.income), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(l10n.piggyPlanQuestion, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final amount in spec.plans) ...[
          ChoiceChip(
            key: ValueKey('piggy-plan-$amount'),
            label: SizedBox(
              width: double.infinity,
              child: Text(l10n.piggyPlanOption(amount), textAlign: TextAlign.center),
            ),
            selected: choice == amount,
            onSelected: (_) => setState(() => _choice = amount),
          ),
          const SizedBox(height: 6),
        ],
        if (choice != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.piggyPlanCheck(game.weeks, choice, game.planTotal(choice)),
            key: const ValueKey('piggy-plan-check'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: game.planTotal(choice) >= spec.goalPrice ? palette.success : palette.coral,
            ),
          ),
        ],
      ],
    );
  }
}
