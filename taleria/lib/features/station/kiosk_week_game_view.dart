import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';
import 'game_scene.dart';
import 'quiz_view.dart' show StepDots;

/// Mias Kiosk-Woche: Jeden Tag ein Angebot am Kiosk. Wünsche kaufen oder
/// lassen, Nötiges bezahlen. Reicht das Geld für Nötiges nicht mehr, beginnt
/// die Woche von vorn.
class KioskWeekGameView extends StatefulWidget {
  const KioskWeekGameView({super.key, required this.game, required this.onFinished});

  final GameInfo game;
  final ValueChanged<int> onFinished;

  @override
  State<KioskWeekGameView> createState() => _KioskWeekGameViewState();
}

class _KioskWeekGameViewState extends State<KioskWeekGameView> {
  late final KioskWeekGame _game = KioskWeekGame(widget.game)..start();
  final _bagKey = GlobalKey();
  final _buyKey = GlobalKey();

  void _buy() {
    final game = _game;
    if (game.canPay) {
      playGameSound(context, AssetKeys.soundCoin);
      flyThing(
        context,
        from: _bagKey,
        to: _buyKey,
        child: const Icon(Icons.monetization_on, size: 30, color: Color(0xFFE0A526)),
      );
    }
    setState(game.buy);
    if (game.finished) playGameSound(context, AssetKeys.soundCorrect);
  }

  void _skip() {
    setState(_game.skip);
    if (_game.finished) playGameSound(context, AssetKeys.soundCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;

    final Widget button;
    if (game.finished) {
      button = FilledButton(
        key: const ValueKey('game-finish'),
        onPressed: () => widget.onFinished(game.stars),
        child: Text(l10n.realGameToResult),
      );
    } else if (game.broke) {
      button = FilledButton.icon(
        key: const ValueKey('kiosk-again'),
        onPressed: () => setState(game.restart),
        icon: const Icon(Icons.replay_rounded),
        label: Text(l10n.kioskAgain),
      );
    } else {
      final day = game.current;
      button = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: ValueKey(day.must ? 'kiosk-pay' : 'kiosk-buy'),
            // Für einen Wunsch, der nicht mehr in den Beutel passt, gibt es nur „Lieber nicht“.
            onPressed: day.must || game.canPay ? _buy : null,
            child: SizedBox(key: _buyKey, child: Text(day.must ? l10n.kioskPay : l10n.kioskBuy)),
          ),
          if (!day.must) ...[
            const SizedBox(height: 8),
            OutlinedButton(key: const ValueKey('kiosk-skip'), onPressed: _skip, child: Text(l10n.kioskSkip)),
          ],
        ],
      );
    }

    return GameFrame(
      game: widget.game,
      button: button,
      children: [
        _bag(context),
        const SizedBox(height: 8),
        if (game.finished) ...[
          Text(
            l10n.kioskDone(game.money),
            key: const ValueKey('kiosk-done'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: palette.success),
          ),
          if (game.bought.isNotEmpty) Text(l10n.kioskBought(game.bought.join(', ')), textAlign: TextAlign.center),
        ] else ...[
          // Die Tage als Punkte: geschafft grün, heute golden.
          StepDots(total: game.days.length, current: game.day, label: game.current.day),
          const SizedBox(height: 6),
          Text(
            game.current.day,
            key: ValueKey('kiosk-day-${game.day}'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          for (final line in game.current.scene) ...[const SizedBox(height: 8), SpeechBubble.line(line)],
          const SizedBox(height: 8),
          Text(
            game.current.must
                ? l10n.kioskMust(game.current.item, game.current.price)
                : l10n.kioskOffer(game.current.item, game.current.price),
            key: const ValueKey('kiosk-offer'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(color: game.current.must ? palette.coral : null),
          ),
          if (game.broke) ...[
            const SizedBox(height: 8),
            if (widget.game.broke case final line?) SpeechBubble.line(line),
            Text(
              l10n.kioskBroke(game.current.item),
              key: const ValueKey('kiosk-broke'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(color: palette.coral),
            ),
          ],
        ],
      ],
    );
  }

  /// Der Beutel mit dem Geld der Woche und was noch bezahlt werden muss.
  Widget _bag(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    return Card(
      key: _bagKey,
      color: palette.paper,
      shape: gameCardShape,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag_rounded, size: 34, color: palette.coral),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.kioskMoney(game.money),
                    key: const ValueKey('kiosk-money'),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (!game.finished && game.mustLeft > 0) ...[
              const SizedBox(height: 4),
              Text(l10n.kioskMustLeft(game.mustLeft), style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
