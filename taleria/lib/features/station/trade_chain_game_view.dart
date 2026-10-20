import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import '../common/figure_names.dart';
import '../intro/speech_bubble.dart';
import 'figure_head.dart';
import 'game_frame.dart';
import 'game_scene.dart';

/// Tauschkette: Tala hat ein Ding und will ein anderes. Jeder Händler zeigt,
/// was er hat und was er dafür will. Das Kind tippt Händler an und tauscht,
/// bis Tala ihr Ziel hat. Wer in eine Sackgasse tauscht, fängt von vorn an.
class TradeChainGameView extends StatefulWidget {
  const TradeChainGameView({super.key, required this.game, required this.onFinished});

  final GameInfo game;
  final ValueChanged<int> onFinished;

  @override
  State<TradeChainGameView> createState() => _TradeChainGameViewState();
}

class _TradeChainGameViewState extends State<TradeChainGameView> {
  late final TradeChainGame _game = TradeChainGame(widget.game);

  /// Für die Flugbahn: Talas Hand und jeder Händler.
  final _talaKey = GlobalKey();
  late final _traderKeys = [for (final _ in widget.game.traders) GlobalKey()];

  void _tap(int trader) {
    final gave = _game.holding;
    final result = _game.tap(trader);
    if (result == TradeResult.traded) {
      AppScope.of(context).sounds.effect(AssetKeys.soundCorrect);
      // Tauschen sieht man: Talas Ding fliegt zum Händler, seins zu Tala.
      final images = widget.game.images;
      final got = widget.game.traders[trader].has;
      if (images[gave] case final image?) {
        flyThing(context, from: _talaKey, to: _traderKeys[trader], child: GameThumb(image, size: 48));
      }
      if (images[got] case final image?) {
        flyThing(context, from: _traderKeys[trader], to: _talaKey, child: GameThumb(image, size: 48));
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final refused = game.refusedBy == null ? null : widget.game.traders[game.refusedBy!];

    final Widget button;
    if (game.finished) {
      button = FilledButton(
        key: const ValueKey('game-finish'),
        onPressed: () => widget.onFinished(game.stars),
        child: Text(l10n.realGameToResult),
      );
    } else if (game.stuck) {
      button = FilledButton.icon(
        key: const ValueKey('trade-reset'),
        onPressed: () => setState(game.reset),
        icon: const Icon(Icons.replay_rounded),
        label: Text(l10n.tradeReset),
      );
    } else {
      button = const SizedBox.shrink();
    }

    return GameFrame(
      game: widget.game,
      button: button,
      children: [
        Card(
          color: palette.paper,
          shape: gameCardShape,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const FigureHead('tala', size: 52, highlight: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: Text(
                          l10n.tradeHolding(game.holding),
                          key: ValueKey('trade-holding-${game.holding}'),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.flag_rounded, size: 18, color: palette.gold),
                          const SizedBox(width: 4),
                          Flexible(child: Text(l10n.tradeGoal(widget.game.goal ?? ''))),
                        ],
                      ),
                      if (game.history.isNotEmpty)
                        Text(
                          l10n.tradeChain([...game.history, game.holding].join(' → ')),
                          key: const ValueKey('trade-chain'),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                // Was Tala gerade in der Hand hat.
                KeyedSubtree(
                  key: _talaKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: GameThumb(
                      widget.game.images[game.holding],
                      key: ValueKey('trade-holding-image-${game.holding}'),
                      size: 56,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (game.stuck) ...[
          const SizedBox(height: 8),
          SpeechBubble.line(
            widget.game.deadEnd ?? DialogLine(speaker: 'tala', text: l10n.tradeStuck(game.holding)),
            key: const ValueKey('trade-stuck'),
          ),
        ] else if (refused != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.tradeRefused(refused.name, refused.wants),
            key: const ValueKey('game-feedback'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(color: palette.coral),
          ),
        ],
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, trader) in widget.game.traders.indexed)
                  SizedBox(
                    key: _traderKeys[i],
                    width: width,
                    child: _TraderCard(
                      key: ValueKey('trader-$i'),
                      images: widget.game.images,
                      trader: trader,
                      used: game.used.contains(i),
                      onTap: game.finished || game.used.contains(i) ? null : () => _tap(i),
                    ),
                  ),
              ],
            );
          },
        ),
        if (game.history.isNotEmpty && !game.finished && !game.stuck)
          TextButton(onPressed: () => setState(game.reset), child: Text(l10n.tradeReset)),
      ],
    );
  }
}

class _TraderCard extends StatelessWidget {
  const _TraderCard({super.key, required this.trader, required this.used, required this.onTap, this.images = const {}});

  final Trader trader;

  /// Bilder der Dinge (hat und will).
  final Map<String, String> images;
  final bool used;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Card(
      color: used ? palette.sand.withValues(alpha: 0.4) : palette.paper,
      shape: gameCardShape,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              FigureHead(trader.figure, size: 56, dimmed: used),
              const SizedBox(height: 4),
              Text(
                figureLabel(l10n, trader.figure, trader.name),
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              if (used)
                Text(l10n.tradeTraded, style: theme.textTheme.labelMedium?.copyWith(color: palette.success))
              else ...[
                _ItemLine(
                  image: images[trader.has],
                  text: l10n.tradeHas(trader.has),
                  style: theme.textTheme.bodyMedium,
                ),
                _ItemLine(
                  image: images[trader.wants],
                  text: l10n.tradeWants(trader.wants),
                  style: theme.textTheme.bodyMedium?.copyWith(color: palette.seaDeep, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Eine Zeile „hat: Seil“ mit kleinem Bild davor.
class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.image, required this.text, this.style});

  final String? image;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GameThumb(image, size: 28),
          if (image != null) const SizedBox(width: 4),
          Flexible(
            child: Text(text, textAlign: TextAlign.center, style: style),
          ),
        ],
      ),
    );
  }
}
