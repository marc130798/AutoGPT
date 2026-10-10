import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/game_logic.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';

/// Münzen legen: oben die Ablage mit den gelegten Münzen (antippen = wegnehmen),
/// unten alle Euro-Münzen und -Scheine. Mit einer Hand bedienbar, im Hochformat.
class CoinsGameView extends StatefulWidget {
  const CoinsGameView({super.key, required this.game, required this.onDone});

  final GameInfo game;
  final VoidCallback onDone;

  @override
  State<CoinsGameView> createState() => _CoinsGameViewState();
}

class _CoinsGameViewState extends State<CoinsGameView> {
  late final CoinsGame _game = CoinsGame(widget.game);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;

    final Widget button;
    if (game.finished) {
      button = FilledButton(key: const ValueKey('game-done'), onPressed: widget.onDone, child: Text(l10n.introNext));
    } else {
      button = FilledButton(
        key: const ValueKey('game-next'),
        onPressed: game.exact ? () => setState(game.next) : null,
        child: Text(l10n.gameNextTask),
      );
    }

    final String? feedback;
    final Color? feedbackColor;
    if (game.exact) {
      feedback = game.couldUseFewer ? l10n.gameCoinsFewer(CoinsGame.fewestPieces(game.target)) : l10n.gameCoinsExact;
      feedbackColor = palette.success;
    } else if (game.tooMuch) {
      feedback = l10n.gameCoinsTooMuch;
      feedbackColor = palette.coral;
    } else {
      feedback = null;
      feedbackColor = null;
    }

    return GameFrame(
      game: widget.game,
      button: button,
      children: [
        Text(
          l10n.gameTaskProgress(game.index + 1, game.total),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Text(
          game.current.question,
          key: const ValueKey('coins-task'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          color: palette.paper,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  l10n.gameCoinsPlaced(formatCents(game.sum), formatCents(game.target)),
                  key: const ValueKey('coins-sum'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (game.placed.isEmpty)
                  Text(l10n.gameCoinsNothing, textAlign: TextAlign.center, style: theme.textTheme.bodySmall)
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final (i, value) in game.placed.indexed)
                        _Coin(
                          key: ValueKey('coins-placed-$i'),
                          cents: value,
                          small: true,
                          onTap: game.exact ? null : () => setState(() => game.removeAt(i)),
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
            style: theme.textTheme.titleMedium?.copyWith(color: feedbackColor),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final value in CoinsGame.values)
              _Coin(
                key: ValueKey('coin-$value'),
                cents: value,
                onTap: game.exact ? null : () => setState(() => game.add(value)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (game.placed.isNotEmpty && !game.exact)
          TextButton(onPressed: () => setState(game.clear), child: Text(l10n.gameCoinsClear)),
        if (game.finished && widget.game.done != null) ...[
          const SizedBox(height: 16),
          SpeechBubble.line(widget.game.done!),
        ],
      ],
    );
  }
}

/// Eine Münze (rund) oder ein Schein (eckig) als Knopf, mindestens 48 Punkte groß.
class _Coin extends StatelessWidget {
  const _Coin({super.key, required this.cents, required this.onTap, this.small = false});

  final int cents;
  final VoidCallback? onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final note = cents >= CoinsGame.firstNote;
    final label = cents < 100 ? l10n.coinCents(cents) : l10n.coinEuros(cents ~/ 100);
    final size = small ? 48.0 : 64.0;
    final color = note ? palette.sea : (cents >= 100 ? palette.gold : palette.sand);
    return Semantics(
      button: onTap != null,
      label: label,
      child: Material(
        color: color,
        shape: note
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: palette.seaDeep),
              )
            : CircleBorder(side: BorderSide(color: palette.seaDeep)),
        child: InkWell(
          customBorder: note ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)) : const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: note ? size * 1.6 : size,
            height: size,
            child: Center(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, color: palette.ink, fontSize: small ? 12 : 15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
