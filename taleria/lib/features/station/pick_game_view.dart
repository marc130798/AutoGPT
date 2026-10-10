import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/game_logic.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';

/// Auswählen: Dinge mit Preis antippen (an und aus), die Summe läuft mit.
/// „Prüfen“ sagt, ob es passt, und gibt sonst einen Hinweis.
class PickGameView extends StatefulWidget {
  const PickGameView({super.key, required this.game, required this.onDone});

  final GameInfo game;
  final VoidCallback onDone;

  @override
  State<PickGameView> createState() => _PickGameViewState();
}

class _PickGameViewState extends State<PickGameView> {
  late final PickGame _game = PickGame(widget.game);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final items = widget.game.items;

    final hint = game.hintItem == null ? null : items[game.hintItem!].hint;
    final String? feedback = switch (game.result) {
      PickResult.solved => l10n.gamePickSolved,
      PickResult.tooMuch => l10n.gamePickTooMuch,
      PickResult.tooLittle => l10n.gamePickTooLittle,
      PickResult.wrongItem || PickResult.missingItem => hint ?? l10n.gamePickTooLittle,
      null => null,
    };

    return GameFrame(
      game: widget.game,
      button: game.solved
          ? FilledButton(key: const ValueKey('game-done'), onPressed: widget.onDone, child: Text(l10n.introNext))
          : FilledButton(
              key: const ValueKey('game-check'),
              onPressed: game.selected.isEmpty ? null : () => setState(game.check),
              child: Text(l10n.gameCheck),
            ),
      children: [
        Text(
          widget.game.exactTarget
              ? l10n.gamePickExactSum(game.sum, game.target)
              : l10n.gamePickBudgetSum(game.sum, game.target),
          key: const ValueKey('pick-sum'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: !widget.game.exactTarget && game.sum > game.target ? palette.coral : null,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: game.target == 0 ? 0 : (game.sum / game.target).clamp(0.0, 1.0),
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
          color: game.sum > game.target ? palette.coral : palette.gold,
        ),
        const SizedBox(height: 16),
        for (final (i, item) in items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CheckboxListTile(
              key: ValueKey('pick-item-$i'),
              value: game.selected.contains(i),
              onChanged: game.solved ? null : (_) => setState(() => game.toggle(i)),
              title: Text(item.text, style: theme.textTheme.bodyLarge),
              secondary: Text(l10n.gameTaler(item.price ?? 0), style: theme.textTheme.titleSmall),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: game.hintItem == i ? palette.coral : palette.seaDeep),
              ),
            ),
          ),
        if (feedback != null) ...[
          const SizedBox(height: 8),
          Text(
            feedback,
            key: const ValueKey('game-feedback'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: game.solved ? palette.success : palette.coral),
          ),
        ],
        if (game.solved && widget.game.done != null) ...[
          const SizedBox(height: 16),
          SpeechBubble.line(widget.game.done!),
        ],
      ],
    );
  }
}
