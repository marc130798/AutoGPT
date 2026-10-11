import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/game_logic.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'coins_game_view.dart';
import 'game_frame.dart';

/// Kasse: Ein Kunde nach dem anderen bestellt und bezahlt. Das Kind legt das
/// Wechselgeld mit Münzen und Scheinen und gibt es heraus.
class TillGameView extends StatefulWidget {
  const TillGameView({super.key, required this.game, required this.onFinished});

  final GameInfo game;

  /// Alle Kunden bedient; übergibt die Sterne.
  final ValueChanged<int> onFinished;

  @override
  State<TillGameView> createState() => _TillGameViewState();
}

class _TillGameViewState extends State<TillGameView> {
  late final TillGame _game = TillGame(widget.game);

  void _give() {
    final check = _game.give();
    if (check == TillCheck.right) AppScope.of(context).sounds.effect(AssetKeys.soundCorrect);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final customer = game.current;

    final Widget button;
    if (game.finished) {
      button = FilledButton(
        key: const ValueKey('game-finish'),
        onPressed: () => widget.onFinished(game.stars),
        child: Text(l10n.realGameToResult),
      );
    } else if (game.served) {
      button = FilledButton(
        key: const ValueKey('till-next'),
        onPressed: () => setState(game.next),
        child: Text(l10n.tillNextCustomer),
      );
    } else {
      button = FilledButton.icon(
        key: const ValueKey('till-give'),
        onPressed: game.placed.isEmpty ? null : _give,
        icon: const Icon(Icons.payments_outlined),
        label: Text(l10n.tillGive),
      );
    }

    final (String? feedback, Color? color) = switch (game.check) {
      TillCheck.right => (l10n.tillRight, palette.success),
      TillCheck.tooMuch => (l10n.tillTooMuch(widget.game.money(game.difference)), palette.coral),
      TillCheck.tooLittle => (l10n.tillTooLittle(widget.game.money(game.difference)), palette.coral),
      null => (null, null),
    };

    return GameFrame(
      game: widget.game,
      button: button,
      children: [
        Text(
          l10n.tillCustomer(game.index + 1, game.total),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SpeechBubble.line(
          DialogLine(
            speaker: customer.figure,
            name: customer.name,
            text:
                '${customer.text} ${l10n.tillPays(widget.game.money(customer.price), widget.game.money(customer.paid))}',
          ),
          key: ValueKey('till-customer-${game.index}'),
        ),
        if (widget.game.items.isNotEmpty) ...[
          const SizedBox(height: 6),
          // Preistafel klein in einer Zeile, damit die Münzen ohne Scrollen zu sehen sind.
          Text(
            '${l10n.tillPriceBoard}: ${[for (final item in widget.game.items) '${item.text} ${widget.game.money(item.price ?? 0)}'].join(' · ')}',
            key: const ValueKey('till-board'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        Card(
          color: palette.paper,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  l10n.tillTray(widget.game.money(game.sum)),
                  key: const ValueKey('till-sum'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (game.placed.isEmpty)
                  Text(l10n.tillTrayEmpty, textAlign: TextAlign.center, style: theme.textTheme.bodySmall)
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final (i, value) in game.placed.indexed)
                        CoinButton(
                          key: ValueKey('till-placed-$i'),
                          cents: value,
                          small: true,
                          onTap: game.served ? null : () => setState(() => game.removeAt(i)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (feedback != null) ...[
          const SizedBox(height: 8),
          Text(
            feedback,
            key: const ValueKey('game-feedback'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final value in CoinsGame.values)
              CoinButton(
                key: ValueKey('coin-$value'),
                cents: value,
                onTap: game.served ? null : () => setState(() => game.add(value)),
              ),
          ],
        ),
        if (game.placed.isNotEmpty && !game.served)
          TextButton(onPressed: () => setState(game.clear), child: Text(l10n.gameCoinsClear)),
      ],
    );
  }
}
