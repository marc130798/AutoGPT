import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';
import 'station_stage.dart';

/// Name eines Verkaufstricks für das Kind.
String shopTrickName(AppLocalizations l10n, String trick) => switch (trick) {
  'hurry' => l10n.shopTrickHurry,
  'everyone' => l10n.shopTrickEveryone,
  'fake_sale' => l10n.shopTrickFakeSale,
  'free_extra' => l10n.shopTrickFreeExtra,
  _ => l10n.shopTrickSparkle,
};

/// Elsas Glitzerladen: Elsa preist Dinge mit Verkaufstricks an. Das Kind
/// erkennt den Trick und entscheidet, ob Tala das Ding wirklich braucht.
class GlitterShopGameView extends StatefulWidget {
  const GlitterShopGameView({super.key, required this.game, required this.onFinished});

  final GameInfo game;
  final ValueChanged<int> onFinished;

  @override
  State<GlitterShopGameView> createState() => _GlitterShopGameViewState();
}

class _GlitterShopGameViewState extends State<GlitterShopGameView> {
  late final GlitterShopGame _game = GlitterShopGame(widget.game);

  void _guess(String trick) {
    final result = _game.guess(trick);
    if (result == ShopGuess.right) playGameSound(context, AssetKeys.soundCorrect);
    setState(() {});
  }

  void _decide(bool buy) {
    if (buy) playGameSound(context, AssetKeys.soundCoin);
    setState(() => _game.decide(buy: buy));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final offer = game.offer;
    final needed = [
      for (final o in widget.game.offers)
        if (o.needed) o.item,
    ];

    final Widget button;
    if (game.finished) {
      button = FilledButton(
        key: const ValueKey('game-finish'),
        onPressed: () => widget.onFinished(game.stars),
        child: Text(l10n.realGameToResult),
      );
    } else if (game.offerDone) {
      button = FilledButton(
        key: const ValueKey('shop-next'),
        onPressed: () => setState(game.next),
        child: Text(l10n.shopNext),
      );
    } else {
      button = const SizedBox.shrink();
    }

    return GameFrame(
      game: widget.game,
      button: button,
      children: [
        Text(
          l10n.shopMoney(game.money),
          key: const ValueKey('shop-money'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(color: palette.seaDeep),
        ),
        Text(l10n.shopList(needed.join(', ')), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(
          l10n.shopOfferCount(game.index + 1, game.total),
          key: ValueKey('shop-offer-${game.index}'),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
        Text(
          l10n.piggyOffer(offer.item, offer.price),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SpeechBubble.line(offer.pitch),
        const SizedBox(height: 12),
        Text(l10n.shopWhichTrick, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        for (final trick in game.trickOptions) ...[
          AnswerButton(
            key: ValueKey('shop-trick-$trick'),
            text: shopTrickName(l10n, trick),
            center: true,
            mark: game.spotted && trick == offer.trick
                ? AnswerMark.right
                : (game.wrongTricks.contains(trick) ? AnswerMark.wrong : AnswerMark.none),
            onPressed: game.spotted ? null : () => _guess(trick),
          ),
          const SizedBox(height: 6),
        ],
        if (!game.spotted && game.wrongTricks.isNotEmpty)
          Text(
            l10n.shopTrickWrong,
            key: const ValueKey('game-feedback'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.coral),
          ),
        if (game.spotted) ...[
          Text(
            l10n.shopTrickRight,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(color: palette.success),
          ),
          Text(offer.reveal, key: const ValueKey('shop-reveal'), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          if (!game.offerDone) ..._decision(context) else _verdict(context),
        ],
      ],
    );
  }

  List<Widget> _decision(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final offer = game.offer;
    return [
      Text(l10n.shopNeed, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
      const SizedBox(height: 6),
      OutlinedButton(
        key: const ValueKey('shop-buy'),
        onPressed: game.canAfford ? () => _decide(true) : null,
        child: Text(l10n.shopBuy(offer.price)),
      ),
      const SizedBox(height: 6),
      FilledButton(key: const ValueKey('shop-leave'), onPressed: () => _decide(false), child: Text(l10n.shopLeave)),
      if (game.wrongSkip)
        Text(
          l10n.shopNeededSkip,
          key: const ValueKey('shop-needed-skip'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.coral),
        ),
      if (!game.canAfford) ...[
        Text(
          l10n.shopNotEnough,
          key: const ValueKey('shop-not-enough'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.coral),
        ),
        for (final item in game.extras)
          TextButton(
            key: ValueKey('shop-give-back-$item'),
            onPressed: () => setState(() => game.giveBack(item)),
            child: Text(l10n.shopGiveBack(item)),
          ),
      ],
    ];
  }

  /// Rückmeldung nach dem Kaufen oder Liegenlassen.
  Widget _verdict(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final offer = game.offer;
    final good = game.decision! == offer.needed;
    final text = switch ((game.decision!, offer.needed)) {
      (true, true) => l10n.shopGoodBuy,
      (true, false) => l10n.shopExtraBought,
      _ => l10n.shopGoodLeave,
    };
    return Column(
      key: const ValueKey('shop-verdict'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(color: good ? palette.success : palette.coral),
        ),
        if (game.finished) Text(l10n.shopEnd(game.money), key: const ValueKey('shop-end'), textAlign: TextAlign.center),
      ],
    );
  }
}
