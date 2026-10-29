import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/game_logic.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';
import 'quiz_view.dart';
import 'station_stage.dart';
import 'trade_chain_game_view.dart';

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
      key: const ValueKey('choice-game'),
      game: widget.game,
      button: button,
      children: [
        StepDots(
          total: game.total,
          current: game.index,
          currentDone: game.answeredWell,
          label: l10n.gameChoiceProgress(game.index + 1, game.total),
        ),
        if (widget.game.traders.isNotEmpty) ...[const SizedBox(height: 12), _TraderBoard(game: widget.game)],
        const SizedBox(height: 12),
        for (final line in round.scene) ...[SpeechBubble.line(line), const SizedBox(height: 8)],
        Text(round.question, key: const ValueKey('choice-question'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final option in game.optionOrder)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnswerButton(
              key: ValueKey('choice-option-$option'),
              text: round.options[option].text,
              center: true,
              // Gewählte Möglichkeit: grün, wenn sie gut ist, sonst rot.
              mark: game.chosen == option ? (game.answeredWell ? AnswerMark.right : AnswerMark.wrong) : AnswerMark.none,
              onPressed: game.answered
                  ? null
                  : () {
                      setState(() => game.choose(option));
                      if (game.answeredWell) playGameSound(context, AssetKeys.soundCorrect);
                    },
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

/// Tafel „Wer hat was?“: Alle Händler der Übung bleiben die ganze Zeit sichtbar.
class _TraderBoard extends StatelessWidget {
  const _TraderBoard({required this.game});

  final GameInfo game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('trader-board'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.tradeBoardTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, trader) in game.traders.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: TraderCard(
                    key: ValueKey('board-trader-$i'),
                    trader: trader,
                    images: game.images,
                    compact: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
