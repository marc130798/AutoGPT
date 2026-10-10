import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/game_logic.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';

/// Mini-Spiel einer Station. Spielarten ohne eigene Mechanik zeigen den
/// Platzhalter [placeholder]. [onDone] führt weiter zum Stations-Check.
class GameStepView extends StatelessWidget {
  const GameStepView({super.key, required this.game, required this.onDone, required this.placeholder});

  final GameInfo game;
  final VoidCallback onDone;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    if (!game.isPlayable) return placeholder;
    return switch (game.type) {
      'sort' => SortGameView(game: game, onDone: onDone),
      _ => OrderGameView(game: game, onDone: onDone),
    };
  }
}

/// Gemeinsamer Rahmen: Titel, Aufgabe, Inhalt, Knopf unten.
class _GameFrame extends StatelessWidget {
  const _GameFrame({required this.game, required this.children, required this.button});

  final GameInfo game;
  final List<Widget> children;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(game.title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              if (game.task != null) ...[
                const SizedBox(height: 4),
                Text(game.task!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, child: button),
        ),
      ],
    );
  }
}

/// Sortieren: eine Karte nach der anderen in den passenden Korb.
class SortGameView extends StatefulWidget {
  const SortGameView({super.key, required this.game, required this.onDone});

  final GameInfo game;
  final VoidCallback onDone;

  @override
  State<SortGameView> createState() => _SortGameViewState();
}

class _SortGameViewState extends State<SortGameView> {
  SortGame? _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game ??= SortGame(widget.game, AppScope.of(context).random);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game!;
    final item = game.current;
    final done = game.finished;

    final Widget button;
    if (done) {
      button = FilledButton(key: const ValueKey('game-done'), onPressed: widget.onDone, child: Text(l10n.introNext));
    } else if (game.answered && !game.answeredCorrectly) {
      button = OutlinedButton(
        key: const ValueKey('game-retry'),
        onPressed: () => setState(game.retry),
        child: Text(l10n.encounterTryAgain),
      );
    } else {
      button = FilledButton(
        key: const ValueKey('game-next'),
        onPressed: game.answeredCorrectly ? () => setState(game.next) : null,
        child: Text(l10n.gameNextCard),
      );
    }

    return _GameFrame(
      game: widget.game,
      button: button,
      children: [
        Text(
          l10n.gameSortProgress(game.index + 1, game.total),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        Card(
          color: palette.paper,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              item.text,
              key: const ValueKey('game-item'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final (i, basket) in widget.game.baskets.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              key: ValueKey('basket-$i'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                side: BorderSide(
                  color: game.choice == i
                      ? (game.answeredCorrectly ? palette.success : palette.coral)
                      : palette.seaDeep,
                  width: game.choice == i ? 3 : 2,
                ),
              ),
              onPressed: game.answered ? null : () => setState(() => game.choose(i)),
              child: Text(basket, style: theme.textTheme.bodyLarge),
            ),
          ),
        if (game.answered) ...[
          Text(
            game.answeredCorrectly ? l10n.gameSortRight : l10n.gameSortWrong,
            key: const ValueKey('game-feedback'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: game.answeredCorrectly ? palette.success : palette.coral,
            ),
          ),
          if (game.answeredCorrectly && item.hint != null) ...[
            const SizedBox(height: 4),
            Text(item.hint!, style: theme.textTheme.bodyLarge),
          ],
        ],
        if (done && widget.game.done != null) ...[const SizedBox(height: 16), SpeechBubble.line(widget.game.done!)],
      ],
    );
  }
}

/// Reihenfolge: Dinge der Reihe nach antippen, von … bis ….
class OrderGameView extends StatefulWidget {
  const OrderGameView({super.key, required this.game, required this.onDone});

  final GameInfo game;
  final VoidCallback onDone;

  @override
  State<OrderGameView> createState() => _OrderGameViewState();
}

class _OrderGameViewState extends State<OrderGameView> {
  OrderGame? _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game ??= OrderGame(widget.game, AppScope.of(context).random);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game!;
    final items = widget.game.items;

    return _GameFrame(
      game: widget.game,
      button: FilledButton(
        key: const ValueKey('game-done'),
        onPressed: game.finished ? widget.onDone : null,
        child: Text(l10n.introNext),
      ),
      children: [
        if (widget.game.from != null)
          Text('${widget.game.from} ↓', style: theme.textTheme.labelLarge?.copyWith(color: palette.seaDeep)),
        const SizedBox(height: 4),
        // Die Reihe, wie sie schon gelegt ist.
        for (final (position, item) in game.placed.indexed)
          Card(
            color: palette.success.withValues(alpha: 0.12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: palette.success,
                foregroundColor: Colors.white,
                child: Text('${position + 1}'),
              ),
              title: Text(items[item].text),
              subtitle: items[item].hint == null ? null : Text(items[item].hint!),
            ),
          ),
        if (widget.game.to != null && game.finished)
          Text(widget.game.to!, style: theme.textTheme.labelLarge?.copyWith(color: palette.seaDeep)),
        const SizedBox(height: 12),
        Text(
          l10n.gameOrderPlaced(game.placed.length, items.length),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
        if (game.wrongTap != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.gameOrderWrong,
            key: const ValueKey('game-feedback'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: palette.coral),
          ),
        ],
        const SizedBox(height: 12),
        // Noch nicht gelegte Dinge, gemischt.
        for (final item in game.shuffled.where((i) => !game.placed.contains(i)))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              key: ValueKey('order-item-$item'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                side: BorderSide(color: game.wrongTap == item ? palette.coral : palette.seaDeep, width: 2),
              ),
              onPressed: () => setState(() => game.tap(item)),
              child: Text(items[item].text, style: theme.textTheme.bodyLarge),
            ),
          ),
        if (game.finished) ...[
          Text(l10n.gameDone, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          if (widget.game.done != null) ...[const SizedBox(height: 12), SpeechBubble.line(widget.game.done!)],
        ],
      ],
    );
  }
}
