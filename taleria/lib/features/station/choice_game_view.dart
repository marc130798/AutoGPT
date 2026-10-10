import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/game_logic.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';

/// Entscheidungen: Situation, Frage, Möglichkeiten als große Knöpfe. Nach der
/// Wahl erscheint die Rückmeldung. Weniger gut: „Nochmal versuchen“.
class ChoiceGameView extends StatefulWidget {
  const ChoiceGameView({super.key, required this.game, required this.onDone});

  final GameInfo game;
  final VoidCallback onDone;

  @override
  State<ChoiceGameView> createState() => _ChoiceGameViewState();
}

class _ChoiceGameViewState extends State<ChoiceGameView> {
  ChoiceGame? _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game ??= ChoiceGame(widget.game, AppScope.of(context).random);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game!;
    final round = game.current;
    final chosen = game.chosenOption;

    final Widget button;
    if (game.finished) {
      button = FilledButton(key: const ValueKey('game-done'), onPressed: widget.onDone, child: Text(l10n.introNext));
    } else if (game.answered && !game.answeredWell) {
      button = OutlinedButton(
        key: const ValueKey('game-retry'),
        onPressed: () => setState(game.retry),
        child: Text(l10n.encounterTryAgain),
      );
    } else {
      button = FilledButton(
        key: const ValueKey('game-next'),
        onPressed: game.answeredWell ? () => setState(game.next) : null,
        child: Text(l10n.gameNextSituation),
      );
    }

    return GameFrame(
      game: widget.game,
      button: button,
      children: [
        Text(
          l10n.gameChoiceProgress(game.index + 1, game.total),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        for (final line in round.scene) ...[SpeechBubble.line(line), const SizedBox(height: 8)],
        Text(round.question, key: const ValueKey('choice-question'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final option in game.optionOrder)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              key: ValueKey('choice-option-$option'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                side: BorderSide(
                  color: game.chosen == option
                      ? (game.answeredWell ? palette.success : palette.coral)
                      : palette.seaDeep,
                  width: game.chosen == option ? 3 : 2,
                ),
              ),
              onPressed: game.answered ? null : () => setState(() => game.choose(option)),
              child: Text(round.options[option].text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            ),
          ),
        if (chosen != null)
          Text(
            chosen.reply,
            key: const ValueKey('game-feedback'),
            style: theme.textTheme.bodyLarge?.copyWith(color: chosen.good ? palette.success : palette.coral),
          ),
        if (game.finished && widget.game.done != null) ...[
          const SizedBox(height: 16),
          SpeechBubble.line(widget.game.done!),
        ],
      ],
    );
  }
}
