import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';
import 'game_scene.dart';

/// Emmas Wintervorrat: An jedem Herbsttag entscheidet das Kind, ob Emma
/// gleich isst oder für den Winter vergräbt. Gustav isst immer alles sofort.
/// Im Winter zeigt sich, ob der Vorrat reicht; dann klopft Gustav hungrig an.
class WinterStoreGameView extends StatefulWidget {
  const WinterStoreGameView({super.key, required this.game, required this.onFinished});

  final GameInfo game;
  final ValueChanged<int> onFinished;

  @override
  State<WinterStoreGameView> createState() => _WinterStoreGameViewState();
}

class _WinterStoreGameViewState extends State<WinterStoreGameView> {
  late final WinterStoreGame _game = WinterStoreGame(widget.game);
  final _storeKey = GlobalKey();
  final _waitKey = GlobalKey();

  void _store() {
    playGameSound(context, AssetKeys.soundDig);
    flyThing(context, from: _waitKey, to: _storeKey, child: const _Nut(size: 36));
    setState(_game.store);
    _afterChoice();
  }

  void _eat() {
    setState(_game.eat);
    _afterChoice();
  }

  void _afterChoice() {
    if (_game.winter && _game.enough) playGameSound(context, AssetKeys.soundCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final spec = game.spec;

    final Widget button;
    if (game.finished) {
      button = FilledButton(
        key: const ValueKey('game-finish'),
        onPressed: () => widget.onFinished(game.stars),
        child: Text(l10n.realGameToResult),
      );
    } else if (game.winter && !game.enough) {
      button = FilledButton.icon(
        key: const ValueKey('winter-again'),
        onPressed: () => setState(game.restart),
        icon: const Icon(Icons.replay_rounded),
        label: Text(l10n.winterAgain),
      );
    } else if (game.winter) {
      // Teilen oder behalten: Die Knöpfe stehen bei Gustav.
      button = const SizedBox.shrink();
    } else {
      button = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const ValueKey('winter-wait'),
            onPressed: _store,
            icon: SizedBox(key: _waitKey, child: const Icon(Icons.download_rounded)),
            label: Text(l10n.winterWait(spec.later)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('winter-eat'),
            onPressed: _eat,
            icon: const Icon(Icons.restaurant_rounded),
            label: Text(l10n.winterEat(spec.now)),
          ),
        ],
      );
    }

    return GameFrame(
      game: widget.game,
      button: button,
      children: [
        _storeCard(context),
        const SizedBox(height: 8),
        if (!game.winter) ...[
          Text(
            l10n.winterDay(game.day + 1, game.days),
            key: ValueKey('winter-day-${game.day}'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          for (final line in spec.days[game.day]) ...[const SizedBox(height: 8), SpeechBubble.line(line)],
          const SizedBox(height: 8),
          Text(
            l10n.winterGustav(game.day * spec.now),
            key: const ValueKey('winter-gustav'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ] else ...[
          Text(
            l10n.winterCame,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (!game.enough) ...[
            Text(
              l10n.winterNotEnough(game.stored, game.need),
              key: const ValueKey('winter-not-enough'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(color: palette.coral),
            ),
            if (spec.hungry case final line?) ...[const SizedBox(height: 8), SpeechBubble.line(line)],
          ] else ...[
            Text(
              l10n.winterEnough,
              key: const ValueKey('winter-enough'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(color: palette.success),
            ),
            if (spec.knock case final line?) ...[const SizedBox(height: 8), SpeechBubble.line(line)],
            if (game.surplus > 0 && game.shared == null) ...[
              const SizedBox(height: 8),
              Text(l10n.winterSurplus(game.surplus), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('winter-share'),
                onPressed: () => setState(() => game.decideShare(true)),
                icon: const Icon(Icons.volunteer_activism_rounded),
                label: Text(l10n.winterShare(game.surplus)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('winter-keep'),
                onPressed: () => setState(() => game.decideShare(false)),
                child: Text(l10n.winterKeep),
              ),
            ],
            if (game.shared == true && spec.share != null) ...[
              const SizedBox(height: 8),
              SpeechBubble.line(spec.share!, key: const ValueKey('winter-shared')),
            ],
            if (game.shared == false && spec.keep != null) ...[
              const SizedBox(height: 8),
              SpeechBubble.line(spec.keep!, key: const ValueKey('winter-kept')),
            ],
          ],
        ],
      ],
    );
  }

  /// Emmas Vorrat: Nüsse im Versteck, Balken bis zum Winterbedarf.
  Widget _storeCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final full = game.stored >= game.need;
    return Card(
      key: _storeKey,
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
                const _Nut(size: 28),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.winterStoreLabel, style: theme.textTheme.titleSmall)),
                Text(
                  l10n.winterStoreCount(game.stored, game.need),
                  key: const ValueKey('winter-stored'),
                  style: theme.textTheme.titleSmall?.copyWith(color: full ? palette.success : palette.seaDeep),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: game.need == 0 ? 0 : (game.stored / game.need).clamp(0, 1).toDouble(),
                minHeight: 12,
                color: full ? palette.success : palette.gold,
                backgroundColor: palette.sand,
              ),
            ),
            const SizedBox(height: 6),
            Text(l10n.winterEaten(game.eaten), textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Eine Nuss, im Code gezeichnet (bis es ein Bild gibt).
class _Nut extends StatelessWidget {
  const _Nut({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Icon(Icons.spa_rounded, size: size, color: const Color(0xFF9A6A3A));
}
