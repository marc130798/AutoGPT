import 'package:flutter/material.dart';

import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import 'figure_head.dart';
import 'game_frame.dart';

/// Markt-Einkauf: Oben Geldbeutel und Einkaufsliste, darunter die Stände.
/// Das Kind wählt einen Stand, kauft dort und vergleicht die Preise, damit
/// das Geld für alles reicht. Gekauftes kann es zurücklegen.
class MarketGameView extends StatefulWidget {
  const MarketGameView({super.key, required this.game, required this.onFinished});

  final GameInfo game;
  final ValueChanged<int> onFinished;

  @override
  State<MarketGameView> createState() => _MarketGameViewState();
}

class _MarketGameViewState extends State<MarketGameView> {
  late final MarketGame _game = MarketGame(widget.game);
  int _stand = 0;
  MarketBuy? _lastBuy;
  String? _lastItem;

  void _buy(MarketOffer offer) {
    setState(() {
      _lastBuy = _game.buy(_stand, offer);
      _lastItem = offer.item;
    });
  }

  void _putBack(String item) {
    setState(() {
      _game.putBack(item);
      _lastBuy = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final stands = widget.game.stands;
    final stand = stands[_stand];

    final String? feedback;
    final Color? feedbackColor;
    if (game.finished) {
      final more = game.spent - game.cheapestTotal;
      feedback = more <= 0
          ? l10n.marketBest(widget.game.money(game.left))
          : l10n.marketCouldSave(widget.game.money(game.left), widget.game.money(more));
      feedbackColor = palette.success;
    } else if (game.stuck) {
      feedback = l10n.marketStuck;
      feedbackColor = palette.coral;
    } else {
      feedback = switch (_lastBuy) {
        MarketBuy.notOnList => l10n.marketNotOnList,
        MarketBuy.alreadyHave => l10n.marketAlreadyHave(_lastItem ?? ''),
        MarketBuy.notEnoughMoney => l10n.marketNotEnough,
        MarketBuy.bought || null => null,
      };
      feedbackColor = palette.coral;
    }

    return GameFrame(
      game: widget.game,
      button: game.finished
          ? FilledButton(
              key: const ValueKey('game-finish'),
              onPressed: () => widget.onFinished(game.stars),
              child: Text(l10n.realGameToResult),
            )
          : const SizedBox.shrink(),
      children: [
        Card(
          color: palette.paper,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, color: palette.seaDeep),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.marketMoneyLeft(widget.game.money(game.left)),
                        key: const ValueKey('market-left'),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Text(l10n.marketList, style: theme.textTheme.labelLarge),
                for (final need in widget.game.needs) _needRow(context, need),
                if (game.cart.isNotEmpty && !game.finished)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l10n.marketPutBackHint, style: theme.textTheme.bodySmall),
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
            style: theme.textTheme.titleSmall?.copyWith(color: feedbackColor),
          ),
        ],
        const SizedBox(height: 12),
        // Stände zum Auswählen, nebeneinander.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, s) in stands.indexed)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == _stand,
                  child: InkWell(
                    key: ValueKey('market-stand-$i'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() {
                      _stand = i;
                      _lastBuy = null;
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        color: i == _stand ? palette.sand.withValues(alpha: 0.7) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: i == _stand ? palette.gold : palette.placeholderBorder),
                      ),
                      child: Column(
                        children: [
                          if (s.image != null)
                            SizedBox(height: 56, child: TaleriaAsset(s.image!, fit: BoxFit.contain))
                          else
                            FigureHead(s.figure, size: 40, highlight: i == _stand),
                          const SizedBox(height: 2),
                          Text(s.name, textAlign: TextAlign.center, maxLines: 2, style: theme.textTheme.labelMedium),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: palette.sand.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(stand.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                for (final (k, offer) in stand.offers.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        GameThumb(widget.game.images[offer.item], size: 44),
                        if (widget.game.images[offer.item] != null) const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(offer.item, style: theme.textTheme.titleSmall),
                              Text(
                                l10n.marketPerPiece(widget.game.money(offer.price)),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          key: ValueKey('market-buy-$_stand-$k'),
                          onPressed: game.finished ? null : () => _buy(offer),
                          child: Text(l10n.marketBuy),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _needRow(BuildContext context, MarketNeed need) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final bought = _game.cart[need.item];
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            bought != null ? Icons.check_circle : Icons.radio_button_unchecked,
            color: bought != null ? palette.success : palette.ink.withValues(alpha: 0.5),
            size: 22,
          ),
          const SizedBox(width: 6),
          GameThumb(widget.game.images[need.item], size: 30),
          const SizedBox(width: 6),
          Expanded(child: Text(l10n.marketNeed(need.count, need.item), style: theme.textTheme.bodyLarge)),
          if (bought != null)
            Flexible(
              child: Text(
                l10n.marketBoughtLine(
                  need.count,
                  widget.game.money(bought.price),
                  widget.game.money(bought.price * need.count),
                ),
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
    if (bought == null || _game.finished) return row;
    return Semantics(
      button: true,
      label: l10n.marketPutBack(need.item),
      child: InkWell(
        key: ValueKey('market-put-back-${need.item}'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => _putBack(need.item),
        child: row,
      ),
    );
  }
}
