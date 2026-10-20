import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/character_image.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/game_logic.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import 'coins_game_view.dart';
import 'figure_head.dart';
import 'game_scene.dart';
import 'story_drawings.dart';
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

  /// Für die Flugbahn: wo jede Münze liegt und wo die Schublade ist.
  final _coinKeys = {for (final v in CoinsGame.values) v: GlobalKey()};
  final _trayKey = GlobalKey();

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
        // Wer schon bedient ist, wer dran ist, wer noch wartet.
        CustomerQueue(
          figures: [for (final c in widget.game.customers) c.figure],
          current: game.index,
          currentDone: game.served,
          label: l10n.tillCustomer(game.index + 1, game.total),
        ),
        const SizedBox(height: 10),
        _CustomerAtCounter(
          key: ValueKey('till-customer-${game.index}'),
          customer: customer,
          happy: game.served,
          text:
              '${customer.text} ${l10n.tillPays(widget.game.money(customer.price), widget.game.money(customer.paid))}',
        ),
        if (widget.game.items.isNotEmpty) ...[
          const SizedBox(height: 10),
          ChalkBoard(
            key: const ValueKey('till-board'),
            title: l10n.tillPriceBoard,
            entries: [for (final item in widget.game.items) (item.text, widget.game.money(item.price ?? 0))],
          ),
        ],
        const SizedBox(height: 12),
        MoneyTray(
          key: _trayKey,
          label: l10n.tillTray(widget.game.money(game.sum)),
          labelKey: const ValueKey('till-sum'),
          empty: l10n.tillTrayEmpty,
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
              KeyedSubtree(
                key: _coinKeys[value],
                child: CoinButton(
                  key: ValueKey('coin-$value'),
                  cents: value,
                  onTap: game.served
                      ? null
                      : () {
                          flyCoin(context, from: _coinKeys[value]!, to: _trayKey, cents: value);
                          setState(() => game.add(value));
                          playGameSound(context, AssetKeys.soundCoin);
                        },
                ),
              ),
          ],
        ),
        if (game.placed.isNotEmpty && !game.served)
          TextButton(onPressed: () => setState(game.clear), child: Text(l10n.gameCoinsClear)),
      ],
    );
  }
}

/// Der Kunde steht als ganze Figur an der Theke und sagt, was er möchte und
/// womit er bezahlt; das Geld liegt gezeichnet daneben. Bedient: Er freut sich
/// und hüpft.
class _CustomerAtCounter extends StatelessWidget {
  const _CustomerAtCounter({super.key, required this.customer, required this.happy, required this.text});

  final TillCustomer customer;
  final bool happy;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final figure = customer.figure;
    final placeholder = AppScope.of(context).manifest.lookup('character.$figure').placeholder;
    final (name, color) = switch (figure) {
      'talo' => (l10n.speakerTalo, palette.talo),
      'tala' => (l10n.speakerTala, palette.tala),
      _ => (customer.name ?? placeholder.label, placeholder.color),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Hop(
          active: happy,
          child: SizedBox(
            width: 92,
            height: 132,
            child: CharacterImage(
              'character.$figure',
              pose: happy ? CharacterPose.happy : null,
              alignment: Alignment.bottomCenter,
              fallback: Center(child: FigureHead(figure, size: 72)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color, width: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 6),
                // Womit der Kunde bezahlt, als echtes Geld.
                Wrap(
                  key: const ValueKey('till-paid'),
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final piece in _pieces(customer.paid))
                      piece >= CoinsGame.firstNote
                          ? EuroNote(euros: piece ~/ 100, scale: 0.55)
                          : EuroCoin(cents: piece, scale: 1.8),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Ein Betrag in möglichst wenigen Münzen und Scheinen.
  static List<int> _pieces(int cents) {
    final pieces = <int>[];
    var rest = cents;
    for (final v in CoinsGame.values.reversed) {
      while (rest >= v) {
        pieces.add(v);
        rest -= v;
      }
    }
    return pieces;
  }
}
