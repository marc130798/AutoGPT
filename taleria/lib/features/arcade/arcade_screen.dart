import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../domain/arcade_games.dart';
import '../../domain/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/menu_music.dart';
import '../common/play_effect.dart';
import '../common/taleria_app_bar.dart';
import '../intro/speech_bubble.dart';
import '../progress/celebration.dart';
import '../station/real_game_flow.dart' show GameStars;
import '../station/station_stage.dart' show GlassFrame;
import 'arcade_layers.dart';

/// Name eines richtigen Spiels.
String arcadeTitle(AppLocalizations l10n, ArcadeGame game) => switch (game.kind) {
  ArcadeKind.gullFlight => l10n.arcadeGullTitle,
  ArcadeKind.crane => l10n.arcadeCraneTitle,
  ArcadeKind.delivery => l10n.arcadeDeliveryTitle,
  ArcadeKind.bottles => l10n.arcadeBottlesTitle,
  ArcadeKind.nutRun => l10n.arcadeNutsTitle,
  ArcadeKind.pearlDive => l10n.arcadePearlTitle,
};

/// Wo das Spiel auf der Insel liegt („am langen Steg“).
String arcadePlace(AppLocalizations l10n, ArcadeGame game) => switch (game.kind) {
  ArcadeKind.gullFlight => l10n.arcadeGullPlace,
  ArcadeKind.crane => l10n.arcadeCranePlace,
  ArcadeKind.delivery => l10n.arcadeDeliveryPlace,
  ArcadeKind.bottles => l10n.arcadeBottlesPlace,
  ArcadeKind.nutRun => l10n.arcadeNutsPlace,
  ArcadeKind.pearlDive => l10n.arcadePearlPlace,
};

/// Bild in der Liste der Spiele.
String arcadeCover(ArcadeKind kind) => switch (kind) {
  ArcadeKind.gullFlight => 'character.mia.fly',
  ArcadeKind.crane => 'game.crane.bag',
  ArcadeKind.delivery => 'game.delivery.boat',
  ArcadeKind.bottles => 'game.bottles.bottle',
  ArcadeKind.nutRun => 'character.emma.run',
  ArcadeKind.pearlDive => 'game.pearl.diver',
};

/// Wer das Spiel erklärt und am Ende etwas sagt.
String arcadeSpeaker(ArcadeKind kind) => switch (kind) {
  ArcadeKind.gullFlight => 'mia',
  ArcadeKind.crane => 'bootsbauer',
  ArcadeKind.delivery => 'otti',
  ArcadeKind.bottles => 'elsa',
  ArcadeKind.nutRun => 'emma',
  ArcadeKind.pearlDive => 'tala',
};

/// Die Spielregel auf dem Startbild.
String arcadeHow(AppLocalizations l10n, ArcadeKind kind) => switch (kind) {
  ArcadeKind.gullFlight => l10n.arcadeGullHow,
  ArcadeKind.crane => l10n.arcadeCraneHow,
  ArcadeKind.delivery => l10n.arcadeDeliveryHow,
  ArcadeKind.bottles => l10n.arcadeBottlesHow,
  ArcadeKind.nutRun => l10n.arcadeNutsHow,
  ArcadeKind.pearlDive => l10n.arcadePearlHow,
};

/// Der Satz der Figur am Ende (mit dem Lernen nebenbei) und eine Zeile darunter.
(String, String?) arcadeEndLines(AppLocalizations l10n, ArcadeRound round) => switch (round) {
  GullFlightGame g => (
    g.saved > 0 ? l10n.arcadeGullEndSaved(g.saved) : l10n.arcadeGullEndNone,
    g.dropped > 0 ? l10n.arcadeGullDropped(g.dropped) : null,
  ),
  CraneGame g => (g.delivered > 0 ? l10n.arcadeCraneEnd(g.delivered) : l10n.arcadeCraneEndNone, null),
  DeliveryGame g => (
    l10n.arcadeDeliveryEnd(g.points),
    g.wrongGoods > 0 ? l10n.arcadeDeliveryWrong(g.wrongGoods) : null,
  ),
  BottleGame g => (l10n.arcadeBottlesEnd(g.points), g.wishesLetGo > 0 ? l10n.arcadeBottlesWishes(g.wishesLetGo) : null),
  NutRunGame g => (
    g.stored > 0 ? l10n.arcadeNutsEnd(g.stored) : l10n.arcadeNutsEndNone,
    g.dropped > 0 ? l10n.arcadeNutsDropped(g.dropped) : null,
  ),
  PearlDiveGame g => (l10n.arcadePearlEnd(g.pearls), null),
  _ => ('', null),
};

/// Klangkulisse während des Spiels.
String arcadeMusic(ArcadeKind kind) => switch (kind) {
  ArcadeKind.pearlDive => AssetKeys.ambienceUnderwater,
  ArcadeKind.nutRun => AssetKeys.islandAmbience('spar-insel'),
  ArcadeKind.crane => AssetKeys.islandAmbience('hafen'),
  _ => AssetKeys.ambienceOpenSea,
};

/// Ein richtiges Spiel: Startbild mit Regel und Rekord, dann das Spiel, am
/// Ende Punkte, Sterne, Rekord und ein Satz der Figur. „Nochmal“ geht sofort.
class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key, required this.game, required this.childId});

  final ArcadeGame game;
  final String childId;

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

enum _Phase { intro, playing, end }

class _ArcadeScreenState extends State<ArcadeScreen> {
  _Phase _phase = _Phase.intro;
  int _best = 0;
  int _round = 0;
  ArcadeRound? _last;
  bool _newBest = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_round == 0) {
      AppScope.of(context).settings.arcadeBest(widget.childId, widget.game.id).then((best) {
        if (mounted) setState(() => _best = best);
      });
    }
  }

  void _start() => setState(() {
    _phase = _Phase.playing;
    _round++;
  });

  void _finished(ArcadeRound game) {
    final score = game.score;
    _newBest = score > _best;
    if (_newBest) {
      _best = score;
      AppScope.of(context).settings.setArcadeBest(widget.childId, widget.game.id, score);
    }
    playEffect(context, _newBest ? AssetKeys.soundArcadeRecord : AssetKeys.soundCorrect);
    setState(() {
      _last = game;
      _phase = _Phase.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MenuMusic(
      music: arcadeMusic(widget.game.kind),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: TaleriaAppBar(title: arcadeTitle(l10n, widget.game)),
        body: Stack(
          children: [
            Positioned.fill(
              child: ArcadeField(
                key: ValueKey('arcade-round-$_round'),
                kind: widget.game.kind,
                running: _phase == _Phase.playing,
                onOver: _finished,
              ),
            ),
            if (_phase == _Phase.intro) _intro(context),
            if (_phase == _Phase.end && _last != null) _end(context, _last!),
          ],
        ),
      ),
    );
  }

  Widget _intro(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _Overlay(
      key: const ValueKey('arcade-intro'),
      children: [
        SpeechBubble.line(
          DialogLine(speaker: arcadeSpeaker(widget.game.kind), text: arcadeHow(l10n, widget.game.kind)),
        ),
        const SizedBox(height: 12),
        if (_best > 0)
          Text(
            l10n.arcadeBest(_best),
            key: const ValueKey('arcade-best'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('arcade-play'),
          onPressed: _start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.arcadePlay),
        ),
      ],
    );
  }

  Widget _end(BuildContext context, ArcadeRound game) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stars = widget.game.starsFor(game.score);
    final (line, extra) = arcadeEndLines(l10n, game);
    return Stack(
      children: [
        const Positioned.fill(child: IgnorePointer(child: ConfettiBurst())),
        _Overlay(
          key: const ValueKey('arcade-end'),
          children: [
            Text(l10n.arcadeOver, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Center(child: GameStars(count: stars, pop: true)),
            const SizedBox(height: 8),
            Text(
              l10n.arcadeScore(game.score),
              key: const ValueKey('arcade-score'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              _newBest ? l10n.arcadeNewBest : l10n.arcadeBest(_best),
              key: ValueKey(_newBest ? 'arcade-new-best' : 'arcade-best'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: _newBest ? const Color(0xFFB8860B) : null),
            ),
            const SizedBox(height: 12),
            SpeechBubble.line(DialogLine(speaker: arcadeSpeaker(widget.game.kind), text: line)),
            if (extra != null) ...[const SizedBox(height: 6), Text(extra, textAlign: TextAlign.center)],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('arcade-done'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.arcadeDone),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('arcade-again'),
                    onPressed: _start,
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(l10n.arcadeAgain),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Karte über dem Spiel (Start und Ende).
class _Overlay extends StatelessWidget {
  const _Overlay({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x55102A40),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: GlassFrame(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

/// Das Spielfeld eines richtigen Spiels: Ebenen aus `arcade_layers.dart`,
/// oben Herzen, Zähler und Stufe. Antippen und Ziehen steuern.
class ArcadeField extends StatefulWidget {
  const ArcadeField({super.key, required this.kind, required this.running, required this.onOver});

  final ArcadeKind kind;

  /// `false`: Das Bild steht still im Hintergrund (vor dem Start, am Ende).
  final bool running;
  final ValueChanged<ArcadeRound> onOver;

  @override
  State<ArcadeField> createState() => ArcadeFieldState();
}

class ArcadeFieldState extends State<ArcadeField> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  ArcadeRound? _round;
  Duration _last = Duration.zero;
  double _fasterUntil = -1;
  double _shakeUntil = -1;
  bool _reported = false;

  /// Die laufende Runde (für Tests).
  @visibleForTesting
  ArcadeRound? get round => _round;

  @override
  void initState() {
    super.initState();
    if (widget.running) _ticker.start();
  }

  @override
  void didUpdateWidget(ArcadeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running && !_ticker.isActive && !(_round?.over ?? false)) _ticker.start();
  }

  /// Töne je Spiel: Taler, gute Lieferung, gespart, Fehler.
  String _sound(ArcadeEvent e) => switch ((widget.kind, e)) {
    (_, ArcadeEvent.start) => AssetKeys.soundArcadeHorn,
    // Mias Möwenflug
    (ArcadeKind.gullFlight, ArcadeEvent.action) => AssetKeys.soundArcadeFlap,
    (ArcadeKind.gullFlight, ArcadeEvent.hit || ArcadeEvent.over) => AssetKeys.soundArcadeSquawk,
    (ArcadeKind.gullFlight, ArcadeEvent.saved) => AssetKeys.soundArcadeGlass,
    // Bootsbauers Kran
    (ArcadeKind.crane, ArcadeEvent.action) => AssetKeys.soundArcadeChain,
    (ArcadeKind.crane, ArcadeEvent.junk) => AssetKeys.soundArcadeBoot,
    (ArcadeKind.crane, ArcadeEvent.good) => AssetKeys.soundRegister,
    (ArcadeKind.crane, ArcadeEvent.hit || ArcadeEvent.over) => AssetKeys.soundArcadeBonk,
    // Ottis Lieferboot
    (ArcadeKind.delivery, ArcadeEvent.action) => AssetKeys.soundArcadeOar,
    (ArcadeKind.delivery, ArcadeEvent.coin) => AssetKeys.soundArcadeThump,
    (ArcadeKind.delivery, ArcadeEvent.good) => AssetKeys.soundTrade,
    (ArcadeKind.delivery, ArcadeEvent.hit || ArcadeEvent.over) => AssetKeys.soundArcadeClonk,
    // Elsas Wunsch-Flaschen: Ein angetippter Wunsch klingt sanft, ein eigener Treffer-Ton wäre doppelt.
    (ArcadeKind.bottles, ArcadeEvent.action) => AssetKeys.soundArcadeSwoosh,
    (ArcadeKind.bottles, ArcadeEvent.coin) => AssetKeys.soundBottle,
    (ArcadeKind.bottles, ArcadeEvent.wrong) => AssetKeys.soundArcadeSparkleDown,
    (ArcadeKind.bottles, ArcadeEvent.hit || ArcadeEvent.over) => '',
    // Emmas Nussjagd
    (ArcadeKind.nutRun, ArcadeEvent.action) => AssetKeys.soundArcadeHop,
    (ArcadeKind.nutRun, ArcadeEvent.coin) => AssetKeys.soundArcadeNut,
    (ArcadeKind.nutRun, ArcadeEvent.saved) => AssetKeys.soundDig,
    (ArcadeKind.nutRun, ArcadeEvent.hit || ArcadeEvent.over) => AssetKeys.soundArcadeBonk,
    // Talas Perlentaucher
    (ArcadeKind.pearlDive, ArcadeEvent.coin) => AssetKeys.soundPearl,
    (ArcadeKind.pearlDive, ArcadeEvent.shell) => AssetKeys.soundArcadeShell,
    (ArcadeKind.pearlDive, ArcadeEvent.hit || ArcadeEvent.over) => AssetKeys.soundArcadeJelly,
    // Für alle
    (_, ArcadeEvent.splash) => AssetKeys.soundSplash,
    (_, ArcadeEvent.coin) => AssetKeys.soundCoin,
    (_, ArcadeEvent.good) => AssetKeys.soundCorrect,
    (_, ArcadeEvent.saved) => AssetKeys.soundPiggy,
    (_, ArcadeEvent.faster) => AssetKeys.soundShipBell,
    (_, ArcadeEvent.wrong || ArcadeEvent.action || ArcadeEvent.junk || ArcadeEvent.shell) => '',
  };

  void _tick(Duration now) {
    final round = _round;
    if (round == null) return;
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    round.step(dt);
    for (final e in round.events) {
      final sound = _sound(e);
      if (sound.isNotEmpty) playEffect(context, sound);
      if (e == ArcadeEvent.hit || e == ArcadeEvent.over) _shakeUntil = round.time + 0.35;
      if (e == ArcadeEvent.faster) _fasterUntil = round.time + 1.4;
    }
    if (round.over && !_reported) {
      _reported = true;
      _ticker.stop();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) widget.onOver(round);
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _pointer(Offset local, Size size, {required bool down}) {
    if (down) AppScope.of(context).sounds.unlock();
    final round = _round;
    if (!widget.running || round == null) return;
    arcadePointer(round, local, size, down: down);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final unit = size.height;
        final round = _round ??= newArcadeRound(widget.kind, size.width / unit);
        final shake = round.time < _shakeUntil ? sin(round.time * 60) * 5 : 0.0;
        return Listener(
          key: const ValueKey('arcade-field'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _pointer(e.localPosition, size, down: true),
          onPointerMove: (e) => _pointer(e.localPosition, size, down: false),
          child: ClipRect(
            child: Transform.translate(
              offset: Offset(shake, 0),
              child: Stack(
                children: [
                  ...arcadeLayers(round, size),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: MediaQuery.paddingOf(context).top + kToolbarHeight + 6,
                    child: _Hud(round: round),
                  ),
                  if (widget.running && !round.started)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: unit * 0.58,
                      child: IgnorePointer(
                        child: Center(
                          child: _Badge(text: l10n.arcadeTapToStart, key: const ValueKey('arcade-tap')),
                        ),
                      ),
                    ),
                  if (round.time < _fasterUntil)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: unit * 0.3,
                      child: IgnorePointer(
                        child: Center(child: _Badge(text: l10n.arcadeFaster)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xEEFFFBF0),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFD4A62A), width: 2),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1C2B3A)),
      ),
    ),
  );
}

/// Oben: Herzen, die Zähler des Spiels, Stufe.
class _Hud extends StatelessWidget {
  const _Hud({required this.round});

  final ArcadeRound round;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1C2B3A));
    Widget chip(Widget child, {Key? key, String? label}) => Semantics(
      label: label,
      child: Container(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xDDFFFBF0), borderRadius: BorderRadius.circular(16)),
        child: child,
      ),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        chip(
          key: const ValueKey('arcade-lives'),
          label: l10n.arcadeLives(round.lives),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < ArcadeRound.hearts; i++)
                Icon(
                  i < round.lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: const Color(0xFFE5675A),
                  size: 24,
                ),
            ],
          ),
        ),
        for (final item in arcadeHud(l10n, round))
          chip(
            key: ValueKey(item.key),
            label: item.label,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                item.icon,
                const SizedBox(width: 4),
                Flexible(child: Text(item.text, style: style)),
              ],
            ),
          ),
        chip(Text(l10n.arcadeLevel(round.level), style: style)),
      ],
    );
  }
}
