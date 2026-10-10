import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/game_logic.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';

/// Rechnen: Aufgabe lesen, Zahl eintippen, prüfen. Nach einem falschen Versuch
/// gibt es den Tipp und den Knopf „Lösung zeigen“. Kein Zeitdruck.
class NumberGameView extends StatefulWidget {
  const NumberGameView({super.key, required this.game, required this.onDone});

  final GameInfo game;
  final VoidCallback onDone;

  @override
  State<NumberGameView> createState() => _NumberGameViewState();
}

class _NumberGameViewState extends State<NumberGameView> {
  late final NumberGame _game = NumberGame(widget.game);
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _check() {
    final value = int.tryParse(_input.text.trim());
    if (value == null) return;
    setState(() => _game.submit(value));
  }

  void _next() {
    setState(() {
      _game.next();
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final round = game.current;
    final solution = '${round.amount} ${round.unit ?? ''}'.trim();

    final Widget button;
    if (game.finished) {
      button = FilledButton(key: const ValueKey('game-done'), onPressed: widget.onDone, child: Text(l10n.introNext));
    } else if (game.canContinue) {
      button = FilledButton(key: const ValueKey('game-next'), onPressed: _next, child: Text(l10n.gameNextTask));
    } else {
      button = FilledButton(key: const ValueKey('game-check'), onPressed: _check, child: Text(l10n.gameCheck));
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
        Text(round.question, key: const ValueKey('number-question'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('number-input'),
          controller: _input,
          enabled: !game.canContinue,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          decoration: InputDecoration(labelText: l10n.gameNumberLabel, suffixText: round.unit),
          onSubmitted: (_) => _check(),
        ),
        const SizedBox(height: 12),
        if (game.correct) ...[
          Text(
            l10n.gameNumberRight,
            key: const ValueKey('game-feedback'),
            style: theme.textTheme.titleMedium?.copyWith(color: palette.success),
          ),
          if (round.explanation != null) Text(round.explanation!, style: theme.textTheme.bodyLarge),
        ] else if (game.revealed) ...[
          Text(l10n.gameNumberSolution(solution), style: theme.textTheme.titleMedium),
          if (round.explanation != null) Text(round.explanation!, style: theme.textTheme.bodyLarge),
        ] else if (game.wrongTries > 0) ...[
          Text(
            l10n.gameNumberWrong,
            key: const ValueKey('game-feedback'),
            style: theme.textTheme.titleMedium?.copyWith(color: palette.coral),
          ),
          if (round.hint != null) Text(l10n.gameNumberTip(round.hint!), style: theme.textTheme.bodyLarge),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('number-reveal'),
              onPressed: () => setState(game.reveal),
              child: Text(l10n.gameNumberShowSolution),
            ),
          ),
        ],
        if (game.finished && widget.game.done != null) ...[
          const SizedBox(height: 16),
          SpeechBubble.line(widget.game.done!),
        ],
      ],
    );
  }
}
