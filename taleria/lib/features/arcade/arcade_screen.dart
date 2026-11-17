import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/character_image.dart';
import '../../core/assets/taleria_asset.dart';
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

/// Name eines richtigen Spiels.
String arcadeTitle(AppLocalizations l10n, ArcadeGame game) => switch (game.kind) {
  ArcadeKind.gullFlight => l10n.arcadeGullTitle,
};

/// Wo das Spiel auf der Insel liegt („am langen Steg“).
String arcadePlace(AppLocalizations l10n, ArcadeGame game) => switch (game.kind) {
  ArcadeKind.gullFlight => l10n.arcadeGullPlace,
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
  GullFlightGame? _last;
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

  void _finished(GullFlightGame game) {
    final score = game.score;
    _newBest = score > _best;
    if (_newBest) {
      _best = score;
      AppScope.of(context).settings.setArcadeBest(widget.childId, widget.game.id, score);
    }
    playEffect(context, _newBest ? AssetKeys.soundStationDone : AssetKeys.soundCorrect);
    setState(() {
      _last = game;
      _phase = _Phase.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MenuMusic(
      music: AssetKeys.ambienceOpenSea,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: TaleriaAppBar(title: arcadeTitle(l10n, widget.game)),
        body: Stack(
          children: [
            Positioned.fill(
              child: GullFlightView(
                key: ValueKey('arcade-round-$_round'),
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
        SpeechBubble.line(DialogLine(speaker: 'mia', text: l10n.arcadeGullHow)),
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

  Widget _end(BuildContext context, GullFlightGame game) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stars = widget.game.starsFor(game.score);
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
            SpeechBubble.line(
              DialogLine(
                speaker: 'mia',
                text: game.saved > 0 ? l10n.arcadeGullEndSaved(game.saved) : l10n.arcadeGullEndNone,
              ),
            ),
            if (game.dropped > 0) ...[
              const SizedBox(height: 6),
              Text(l10n.arcadeGullDropped(game.dropped), textAlign: TextAlign.center),
            ],
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

/// Das Spielfeld von „Mias Möwenflug“: Himmel über der Bucht, Masten und
/// Netze, Taler und Sparglas, oben Herzen und Zähler. Antippen = flattern.
class GullFlightView extends StatefulWidget {
  const GullFlightView({super.key, required this.running, required this.onOver});

  /// `false`: Das Bild steht still im Hintergrund (vor dem Start, am Ende).
  final bool running;
  final ValueChanged<GullFlightGame> onOver;

  @override
  State<GullFlightView> createState() => GullFlightViewState();
}

class GullFlightViewState extends State<GullFlightView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  GullFlightGame? _game;
  Duration _last = Duration.zero;
  double _fasterUntil = -1;
  double _shakeUntil = -1;
  bool _reported = false;

  /// Das laufende Spiel (für Tests).
  @visibleForTesting
  GullFlightGame? get game => _game;

  @override
  void didUpdateWidget(GullFlightView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running && !_ticker.isActive && !(_game?.over ?? false)) _ticker.start();
  }

  @override
  void initState() {
    super.initState();
    if (widget.running) _ticker.start();
  }

  void _tick(Duration now) {
    final game = _game;
    if (game == null) return;
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    game.step(dt);
    for (final e in game.events) {
      switch (e) {
        case GullEvent.coin:
          playEffect(context, AssetKeys.soundCoin);
        case GullEvent.saved:
          playEffect(context, AssetKeys.soundPiggy);
        case GullEvent.hit:
        case GullEvent.over:
          playEffect(context, AssetKeys.soundSplash);
          _shakeUntil = game.time + 0.35;
        case GullEvent.faster:
          playEffect(context, AssetKeys.soundShipBell);
          _fasterUntil = game.time + 1.4;
      }
    }
    if (game.over && !_reported) {
      _reported = true;
      _ticker.stop();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) widget.onOver(game);
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _flap() {
    AppScope.of(context).sounds.unlock();
    if (!widget.running) return;
    _game?.flap();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final unit = size.height;
        final game = _game ??= GullFlightGame(width: size.width / unit);
        final shake = game.time < _shakeUntil ? sin(game.time * 60) * 5 : 0.0;
        final birdSize = unit * 0.1;
        final art = AppScope.of(context).manifest.lookup('game.gull.crate').path != null;
        final blink = game.safe && (game.time * 8).floor().isEven;
        return Listener(
          key: const ValueKey('arcade-field'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _flap(),
          child: Transform.translate(
            offset: Offset(shake, 0),
            child: Stack(
              children: [
                if (art)
                  const Positioned.fill(
                    child: TaleriaAsset(
                      'game.gull.background',
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                      fallback: SizedBox.shrink(),
                    ),
                  ),
                Positioned.fill(
                  child: CustomPaint(painter: _GullPainter(game, art: art)),
                ),
                if (art) ...[
                  for (final o in game.obstacles) ..._obstacleArt(o, game, unit),
                  for (final p in game.pickups)
                    if (!p.taken) _pickupArt(p, game, unit),
                ],
                Positioned(
                  left: game.birdX * unit - birdSize * 0.6,
                  top: game.y * unit - birdSize / 2,
                  width: birdSize * 1.2,
                  height: birdSize,
                  child: Opacity(
                    opacity: blink ? 0.35 : 1,
                    child: Transform.rotate(
                      angle: (game.vy * 0.45).clamp(-0.45, 0.6),
                      // Das Bild schaut nach links, Mia fliegt nach rechts.
                      child: Transform.flip(
                        flipX: true,
                        child: const TaleriaAsset(
                          'character.mia.fly',
                          fit: BoxFit.contain,
                          fallback: CharacterImage('character.mia', fallback: _GullFallback()),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: MediaQuery.paddingOf(context).top + kToolbarHeight + 6,
                  child: _Hud(game: game),
                ),
                if (widget.running && !game.started)
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
                if (game.time < _fasterUntil)
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
        );
      },
    );
  }
}

/// Hindernis mit Bildern: unten ein Turm aus Kisten bis ins Wasser, oben ein
/// Fischernetz an einem Seil. Die Trefferfläche bleibt die aus den Regeln.
List<Widget> _obstacleArt(GullObstacle o, GullFlightGame game, double unit) {
  final w = GullFlightGame.obstacleWidth * unit;
  final left = o.x * unit;
  final center = o.centerAt(game.time) * unit;
  final top = center - o.gapHalf * unit;
  final bottom = center + o.gapHalf * unit;
  final seaTop = GullFlightGame.sea * unit;
  final crate = w * 1.12;
  final crates = ((seaTop - bottom) / crate).ceil() + 1;
  final netW = w * 1.5;
  final netH = netW * 1.5;
  return [
    Positioned(
      left: left + w / 2 - crate / 2,
      top: bottom,
      width: crate,
      height: max(0, seaTop - bottom + crate * 0.3),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: crate * crates,
          child: Column(
            children: [
              for (var i = 0; i < crates; i++)
                SizedBox.square(
                  dimension: crate,
                  child: const TaleriaAsset('game.gull.crate', fit: BoxFit.fill, fallback: SizedBox.shrink()),
                ),
            ],
          ),
        ),
      ),
    ),
    // Seil von oben bis zum Netz.
    Positioned(
      left: left + w / 2 - 2,
      top: 0,
      width: 4,
      height: max(0, top - netH * 0.85),
      child: const ColoredBox(color: Color(0xFFC9A66B)),
    ),
    Positioned(
      left: left + w / 2 - netW / 2,
      top: top - netH,
      width: netW,
      height: netH,
      child: const TaleriaAsset('game.gull.net', fit: BoxFit.fill, fallback: SizedBox.shrink()),
    ),
  ];
}

/// Taler oder Sparglas als Bild, leicht schwebend.
Widget _pickupArt(GullPickup p, GullFlightGame game, double unit) {
  final size = p.jar ? 0.1 * unit : GullFlightGame.pickupRadius * 2.4 * unit;
  final bob = sin(game.time * 4 + p.x * 9) * 0.006 * unit;
  final pulse = p.jar ? 1 + sin(game.time * 6) * 0.05 : 1.0;
  return Positioned(
    left: p.x * unit - size / 2,
    top: p.y * unit - size / 2 + bob,
    width: size,
    height: size,
    child: Transform.scale(
      scale: pulse,
      child: TaleriaAsset(
        p.jar ? 'game.gull.jar' : 'game.gull.coin',
        fit: BoxFit.contain,
        fallback: const SizedBox.shrink(),
      ),
    ),
  );
}

class _GullFallback extends StatelessWidget {
  const _GullFallback();

  @override
  Widget build(BuildContext context) => const Icon(Icons.flight_rounded, size: 40, color: Colors.white);
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

/// Oben: Herzen, Taler in der Tasche, Taler im Sparglas, Stufe.
class _Hud extends StatelessWidget {
  const _Hud({required this.game});

  final GullFlightGame game;

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
          label: l10n.arcadeLives(game.lives),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < GullFlightGame.hearts; i++)
                Icon(
                  i < game.lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: const Color(0xFFE5675A),
                  size: 24,
                ),
            ],
          ),
        ),
        chip(
          key: const ValueKey('arcade-pocket'),
          label: l10n.arcadePocket(game.pocket),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_rounded, color: Color(0xFFE0A526), size: 22),
              const SizedBox(width: 4),
              Text('${game.pocket}', style: style),
            ],
          ),
        ),
        chip(
          key: const ValueKey('arcade-saved'),
          label: l10n.arcadeSaved(game.saved),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.savings_rounded, color: Color(0xFF3E8FB0), size: 22),
              const SizedBox(width: 4),
              Text('${game.saved}', style: style),
            ],
          ),
        ),
        chip(Text(l10n.arcadeLevel(game.level), style: style)),
      ],
    );
  }
}

/// Malt Himmel, Bucht, Meer, Masten, Netze, Taler und Sparglas.
class _GullPainter extends CustomPainter {
  _GullPainter(this.game, {this.art = false});

  final GullFlightGame game;

  /// Mit Bildern (Gemini): Der Maler zeichnet nur das Wasser vorn, der Rest
  /// sind Bilder darüber.
  final bool art;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.height;
    final t = game.time;
    final travel = game.started ? t * 0.04 : 0.0;
    if (art) {
      _sea(canvas, size, u, t);
      return;
    }

    // Himmel mit Sonne.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7CC8EC), Color(0xFFDFF3FC)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(Offset(size.width * 0.82, u * 0.16), u * 0.06, Paint()..color = const Color(0xFFFFE9A8));

    // Wolken, die langsam vorbeiziehen.
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 4; i++) {
      final x = ((i * 0.37 - travel * (0.6 + i * 0.1)) % 1.4 - 0.2) * size.width * 1.2;
      final y = u * (0.12 + i * 0.09);
      for (final (dx, dy, r) in [(0.0, 0.0, 0.04), (0.04, -0.015, 0.05), (0.09, 0.0, 0.035)]) {
        canvas.drawCircle(Offset(x + dx * u, y + dy * u), r * u, cloud);
      }
    }

    // Ferne Ufer der Bucht.
    final hills = Path()..moveTo(0, u * 0.86);
    for (var x = 0.0; x <= size.width + 20; x += 20) {
      final p = x / u + travel * 1.5;
      hills.lineTo(x, u * (0.82 - 0.03 * sin(p * 4) - 0.02 * sin(p * 9 + 1)));
    }
    hills
      ..lineTo(size.width, u * 0.9)
      ..lineTo(0, u * 0.9)
      ..close();
    canvas.drawPath(hills, Paint()..color = const Color(0xFF8FC59A));

    _sea(canvas, size, u, t);

    for (final o in game.obstacles) {
      _obstacle(canvas, o, u, size);
    }
    for (final p in game.pickups) {
      if (p.taken) continue;
      final c = Offset(p.x * u, p.y * u + sin(t * 4 + p.x * 9) * 0.006 * u);
      p.jar ? _jar(canvas, c, u) : _coin(canvas, c, u);
    }
  }

  void _sea(Canvas canvas, Size size, double u, double t) {
    final seaTop = GullFlightGame.sea * u;
    canvas.drawRect(
      Rect.fromLTRB(0, seaTop, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF39B3C9), Color(0xFF1E7FA0)],
        ).createShader(Rect.fromLTRB(0, seaTop, size.width, size.height)),
    );
    final foam = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final wave = Path()..moveTo(0, seaTop);
    for (var x = 0.0; x <= size.width + 10; x += 10) {
      wave.lineTo(x, seaTop + sin(x / 18 + t * 3) * 2.5);
    }
    canvas.drawPath(wave, foam);
  }

  void _obstacle(Canvas canvas, GullObstacle o, double u, Size size) {
    final left = o.x * u;
    final w = GullFlightGame.obstacleWidth * u;
    final center = o.centerAt(game.time) * u;
    final top = center - o.gapHalf * u;
    final bottom = center + o.gapHalf * u;
    final seaTop = GullFlightGame.sea * u;

    // Unten ein Mast mit Rahen und kleinem Wimpel.
    final wood = Paint()..color = const Color(0xFF8A5A2B);
    final dark = Paint()..color = const Color(0xFF5E3B1A);
    final mast = Rect.fromLTRB(left + w * 0.3, bottom, left + w * 0.7, seaTop + 4);
    canvas.drawRRect(RRect.fromRectAndRadius(mast, const Radius.circular(4)), wood);
    canvas.drawRect(Rect.fromLTWH(left + w * 0.3, bottom, w * 0.1, mast.height), dark);
    for (var y = bottom + 0.06 * u; y < seaTop - 0.04 * u; y += 0.14 * u) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left - w * 0.1, y, w * 1.2, 0.012 * u), const Radius.circular(3)),
        dark,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(left + w * 0.5, bottom - 0.002 * u)
        ..lineTo(left + w * 0.5, bottom - 0.05 * u)
        ..lineTo(left + w * 1.05, bottom - 0.03 * u)
        ..close(),
      Paint()..color = const Color(0xFFE5675A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + w * 0.2, bottom - 0.01 * u, w * 0.6, 0.018 * u),
        const Radius.circular(3),
      ),
      dark,
    );

    // Oben ein hängendes Fischernetz an zwei Seilen, unten Schwimmer.
    final rope = Paint()
      ..color = const Color(0xFFC9A66B)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(left + w * 0.15, 0), Offset(left + w * 0.15, top), rope);
    canvas.drawLine(Offset(left + w * 0.85, 0), Offset(left + w * 0.85, top), rope);
    final netTop = max(0.0, top - 0.22 * u);
    final net = Rect.fromLTRB(left, netTop, left + w, top);
    canvas.drawRRect(RRect.fromRectAndRadius(net, const Radius.circular(6)), Paint()..color = const Color(0x664A6B5A));
    final mesh = Paint()
      ..color = const Color(0xFF2F4A3C)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(net, const Radius.circular(6)));
    for (var d = -net.height; d < net.width + net.height; d += 9) {
      canvas.drawLine(Offset(net.left + d, net.top), Offset(net.left + d + net.height, net.bottom), mesh);
      canvas.drawLine(Offset(net.left + d, net.bottom), Offset(net.left + d + net.height, net.top), mesh);
    }
    canvas.restore();
    canvas.drawRRect(RRect.fromRectAndRadius(net, const Radius.circular(6)), mesh..strokeWidth = 2);
    final float = Paint()..color = const Color(0xFFF08A24);
    for (final fx in [0.2, 0.5, 0.8]) {
      canvas.drawCircle(Offset(left + w * fx, top), 0.012 * u, float);
    }
  }

  void _coin(Canvas canvas, Offset c, double u) {
    final r = GullFlightGame.pickupRadius * u;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFB8860B));
    canvas.drawCircle(c, r * 0.82, Paint()..color = const Color(0xFFF3C94B));
    canvas.drawCircle(
      c,
      r * 0.6,
      Paint()
        ..color = const Color(0xFFB8860B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(c + Offset(-r * 0.35, -r * 0.35), r * 0.18, Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  void _jar(Canvas canvas, Offset c, double u) {
    final h = 0.075 * u, w = 0.06 * u;
    final pulse = 1 + sin(game.time * 6) * 0.05;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(pulse);
    canvas.drawCircle(Offset.zero, h * 0.75, Paint()..color = const Color(0x55FFF3B0));
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, h * 0.08), width: w, height: h * 0.8),
      Radius.circular(w * 0.3),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xAAD8F1FA));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF3E8FB0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(-w * 0.18 + i * w * 0.18, h * 0.3 - i % 2 * h * 0.08),
        w * 0.13,
        Paint()..color = const Color(0xFFF3C94B),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -h * 0.36), width: w * 0.8, height: h * 0.14),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFE5675A),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GullPainter old) => true;
}
