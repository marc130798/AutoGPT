import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'figure_head.dart';
import 'game_frame.dart';

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

  void _tap(int trader) {
    final result = _game.tap(trader);
    if (result == TradeResult.traded) AppScope.of(context).sounds.effect(AssetKeys.soundCorrect);
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
                    width: width,
                    child: _TraderCard(
                      key: ValueKey('trader-$i'),
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
  const _TraderCard({super.key, required this.trader, required this.used, required this.onTap});

  final Trader trader;
  final bool used;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Card(
      color: used ? palette.sand.withValues(alpha: 0.4) : palette.paper,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              FigureHead(trader.figure, size: 56, dimmed: used),
              const SizedBox(height: 4),
              Text(trader.name, style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
              if (used)
                Text(l10n.tradeTraded, style: theme.textTheme.labelMedium?.copyWith(color: palette.success))
              else ...[
                Text(l10n.tradeHas(trader.has), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                Text(
                  l10n.tradeWants(trader.wants),
                  textAlign: TextAlign.center,
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
