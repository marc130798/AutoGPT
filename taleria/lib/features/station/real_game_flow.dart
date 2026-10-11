import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'ice_stand_game_view.dart';
import 'market_game_view.dart';
import 'till_game_view.dart';
import 'trade_chain_game_view.dart';

/// Ablauf eines echten Mini-Spiels: Startbild „Mini-Spiel!“, das Spiel, am
/// Ende Sterne und der Satz aus den Inhalten. In der Station führt [onDone]
/// weiter zum Stations-Check; auf der Seite „Spiele“ ([replay]) kann man
/// nochmal spielen.
class RealGameFlow extends StatefulWidget {
  const RealGameFlow({super.key, required this.game, required this.onDone, this.replay = false});

  final GameInfo game;
  final VoidCallback onDone;
  final bool replay;

  @override
  State<RealGameFlow> createState() => _RealGameFlowState();
}

enum _Phase { intro, play, end }

class _RealGameFlowState extends State<RealGameFlow> {
  _Phase _phase = _Phase.intro;
  int _stars = 0;

  /// Neuer Schlüssel bei „Nochmal spielen“: Das Spiel beginnt von vorn.
  int _round = 0;

  void _finished(int stars) {
    AppScope.of(context).sounds.effect(AssetKeys.soundCorrect);
    setState(() {
      _stars = stars;
      _phase = _Phase.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.intro => RealGameIntro(
        game: widget.game,
        replay: widget.replay,
        onPlay: () => setState(() => _phase = _Phase.play),
      ),
      _Phase.play => KeyedSubtree(key: ValueKey('real-game-$_round'), child: _game()),
      _Phase.end => _RealGameEnd(
        game: widget.game,
        stars: _stars,
        replay: widget.replay,
        onAgain: () => setState(() {
          _round++;
          _phase = _Phase.play;
        }),
        onDone: widget.onDone,
      ),
    };
  }

  Widget _game() => switch (widget.game.type) {
    'till' => TillGameView(game: widget.game, onFinished: _finished),
    'market' => MarketGameView(game: widget.game, onFinished: _finished),
    'ice_stand' => IceStandGameView(game: widget.game, onFinished: _finished),
    _ => TradeChainGameView(game: widget.game, onFinished: _finished),
  };
}

/// Startbild: Spiel-Zeichen, „Mini-Spiel!“, Titel, worum es geht, Spielen-Knopf.
class RealGameIntro extends StatelessWidget {
  const RealGameIntro({super.key, required this.game, required this.onPlay, this.replay = false});

  final GameInfo game;
  final VoidCallback onPlay;
  final bool replay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Center(child: GameSign(size: 96)),
              const SizedBox(height: 16),
              Text(
                l10n.realGameBadge,
                key: const ValueKey('real-game-badge'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(color: palette.coral, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(game.title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              if (game.task != null) ...[
                const SizedBox(height: 16),
                Text(game.task!, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              ],
              if (replay) ...[
                const SizedBox(height: 16),
                Text(l10n.realGameReplayNote, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('real-game-play'),
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.realGamePlay),
            ),
          ),
        ),
      ],
    );
  }
}

/// Das Spiel-Zeichen: ein Steuerkreuz auf goldenem Grund. Steht auf dem
/// Startbild, an Stationen auf der Insel und auf der Seite „Spiele“.
class GameSign extends StatelessWidget {
  const GameSign({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.gold,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size / 14),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Icon(Icons.sports_esports_rounded, size: size * 0.6, color: palette.ink),
    );
  }
}

/// Drei Sterne, [count] davon leuchten.
class GameStars extends StatelessWidget {
  const GameStars({super.key, required this.count, this.size = 48});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Semantics(
      label: l10n.realGameStars(count),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              i < count ? Icons.star_rounded : Icons.star_outline_rounded,
              key: i < count ? ValueKey('game-star-$i') : null,
              size: i == 1 ? size * 1.25 : size,
              color: i < count ? palette.gold : palette.ink.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }
}

class _RealGameEnd extends StatelessWidget {
  const _RealGameEnd({
    required this.game,
    required this.stars,
    required this.replay,
    required this.onAgain,
    required this.onDone,
  });

  final GameInfo game;
  final int stars;
  final bool replay;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.realGameWellDone,
                key: const ValueKey('real-game-done'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              GameStars(count: stars),
              if (game.done != null) ...[const SizedBox(height: 20), SpeechBubble.line(game.done!)],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (replay) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const ValueKey('real-game-again'),
                    onPressed: onAgain,
                    child: Text(l10n.realGameAgain),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(key: const ValueKey('game-done'), onPressed: onDone, child: Text(l10n.introNext)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
