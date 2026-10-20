import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/game_logic.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';
import 'game_scene.dart';
import 'station_stage.dart';
import 'story_drawings.dart';

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

  /// Für die Flugbahn: wo jede Münze liegt und wo die Schublade ist.
  final _coinKeys = {for (final v in CoinsGame.values) v: GlobalKey()};
  final _trayKey = GlobalKey();

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
        MoneyTray(
          key: _trayKey,
          label: l10n.gameCoinsPlaced(widget.game.money(game.sum), widget.game.money(game.target)),
          labelKey: const ValueKey('coins-sum'),
          empty: l10n.gameCoinsNothing,
          children: [
            for (final (i, value) in game.placed.indexed)
              CoinButton(
                key: ValueKey('coins-placed-$i'),
                cents: value,
                small: true,
                onTap: game.exact ? null : () => setState(() => game.removeAt(i)),
              ),
          ],
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
              KeyedSubtree(
                key: _coinKeys[value],
                child: CoinButton(
                  key: ValueKey('coin-$value'),
                  cents: value,
                  onTap: game.exact
                      ? null
                      : () {
                          flyCoin(context, from: _coinKeys[value]!, to: _trayKey, cents: value);
                          setState(() => game.add(value));
                          playGameSound(context, game.exact ? AssetKeys.soundCorrect : AssetKeys.soundCoin);
                        },
                ),
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

/// Eine Münze oder ein Schein als Knopf, gezeichnet wie echtes Euro-Geld
/// (Kupfer, Gold, zweifarbig; Scheine in ihren Farben). Münzen behalten ihre
/// echten Größenunterschiede, der Knopf ist immer mindestens 48 Punkte groß.
class CoinButton extends StatelessWidget {
  const CoinButton({super.key, required this.cents, required this.onTap, this.small = false});

  final int cents;
  final VoidCallback? onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final note = cents >= CoinsGame.firstNote;
    final label = cents < 100 ? l10n.coinCents(cents) : l10n.coinEuros(cents ~/ 100);
    final box = small ? 48.0 : 64.0;
    // Die 2-Euro-Münze (25,75 mm) füllt den Knopf fast ganz aus.
    final Widget money = note
        ? EuroNote(euros: cents ~/ 100, scale: small ? 0.42 : 0.72)
        : EuroCoin(cents: cents, scale: (box - 4) / 25.75);
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: PressDip(
        enabled: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Opacity(
            // Gerade nicht antippbar (zum Beispiel schon herausgegeben): etwas blasser.
            opacity: onTap == null && !small ? 0.55 : 1,
            child: SizedBox(
              width: note ? (small ? 60 : 102) : box,
              height: box,
              child: Center(child: money),
            ),
          ),
        ),
      ),
    );
  }
}

/// Eine Münze oder ein Schein fliegt von [from] in die Schublade [to].
void flyCoin(BuildContext context, {required GlobalKey from, required GlobalKey to, required int cents}) => flyThing(
  context,
  from: from,
  to: to,
  child: cents >= CoinsGame.firstNote ? EuroNote(euros: cents ~/ 100, scale: 0.6) : EuroCoin(cents: cents, scale: 2.2),
);

/// Die Geldschublade: Holzrahmen mit dunklem Filz, darauf liegt das gelegte
/// Geld. Oben steht, wie viel es ist.
class MoneyTray extends StatelessWidget {
  const MoneyTray({super.key, required this.label, required this.empty, required this.children, this.labelKey});

  final String label;
  final Key? labelKey;

  /// Hinweis, solange nichts liegt.
  final String empty;
  final List<Widget> children;

  static const _wood = [Color(0xFFC08A52), Color(0xFF8B5A2B)];
  static const _felt = Color(0xFF2E5B55);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _wood),
        border: Border.all(color: const Color(0xFF5E3A1A), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x55081C30), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Messingschild mit dem Betrag.
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: palette.paper,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.gold, width: 2),
              ),
              child: Text(
                label,
                key: labelKey,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _felt,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 4, spreadRadius: -1)],
            ),
            child: children.isEmpty
                ? Text(
                    empty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                  )
                : Wrap(spacing: 4, runSpacing: 4, alignment: WrapAlignment.center, children: children),
          ),
        ],
      ),
    );
  }
}
