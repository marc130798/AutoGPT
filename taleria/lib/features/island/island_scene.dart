import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/arcade_games.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/progress_logic.dart';
import '../../l10n/app_localizations.dart';
import '../common/game_sign.dart';
import '../../domain/avatar.dart';
import '../common/avatar_view.dart';
import '../common/lively_figure.dart';
import '../../core/assets/character_image.dart';

/// Weg, wenn das Inselbild keinen eigenen hat (oder noch fehlt): in Kurven
/// vom Steg unten bis nach oben.
const defaultIslandRoute = [
  Offset(0.5, 0.93),
  Offset(0.34, 0.82),
  Offset(0.62, 0.69),
  Offset(0.38, 0.56),
  Offset(0.64, 0.43),
  Offset(0.4, 0.3),
  Offset(0.56, 0.14),
];

/// Verteilt [count] Stellen in gleichen Abständen entlang des Wegs [route]
/// (Punkte von 0 bis 1) in einem Bild der Größe [size]. Gemessen wird in
/// Bildpunkten, damit die Abstände auch bei schmalen Bildern gleich wirken.
/// Ergebnis wieder von 0 bis 1.
List<Offset> placeAlongRoute(List<Offset> route, int count, Size size, {double from = 0.05, double to = 0.97}) {
  if (count <= 0 || route.isEmpty) return const [];
  if (route.length == 1) return List.filled(count, route.first);
  Offset px(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
  final lengths = <double>[0];
  for (var i = 1; i < route.length; i++) {
    lengths.add(lengths.last + (px(route[i]) - px(route[i - 1])).distance);
  }
  final total = lengths.last;
  return [
    for (var k = 0; k < count; k++)
      () {
        final f = count == 1 ? (from + to) / 2 : from + (to - from) * k / (count - 1);
        final s = total * f;
        var i = 1;
        while (i < lengths.length - 1 && lengths[i] < s) {
          i++;
        }
        final span = lengths[i] - lengths[i - 1];
        final t = span == 0 ? 0.0 : ((s - lengths[i - 1]) / span).clamp(0.0, 1.0);
        return Offset.lerp(route[i - 1], route[i], t)!;
      }(),
  ];
}

/// Schiebt die Stellen abwechselnd links und rechts neben den Weg (quer zur
/// Laufrichtung, um [amount] Bildpunkte), damit dicht liegende Wegmarken sich
/// nicht berühren. Ergebnis wieder von 0 bis 1.
List<Offset> staggerBeside(List<Offset> spots, Size size, double amount) {
  if (spots.length < 2) return spots;
  Offset px(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
  return [
    for (var i = 0; i < spots.length; i++)
      () {
        final before = px(spots[max(0, i - 1)]), after = px(spots[min(spots.length - 1, i + 1)]);
        final along = after - before;
        if (along.distance == 0) return spots[i];
        final across = Offset(-along.dy, along.dx) / along.distance * (i.isEven ? amount : -amount);
        final moved = px(spots[i]) + across;
        return Offset(moved.dx / size.width, moved.dy / size.height);
      }(),
  ];
}

/// Stellen am Wasser für die Ankerplätze, der Reihe nach, oder `null`, wenn
/// das Bild keine (oder zu wenige) hat. Dann liegen die Ankerplätze wie die
/// anderen Stationen auf dem Weg.
List<Offset>? diveSpots(List<Offset>? dives, List<StationInfo> stations) {
  final count = stations.where((s) => s.isDive).length;
  if (dives == null || count == 0 || dives.length < count) return null;
  return dives.sublist(0, count);
}

/// Wo jede Station auf der Insel liegt (0 bis 1): Ankerplätze am Wasser
/// ([dives], sonst auf dem Weg), alle anderen in gleichen Abständen auf dem
/// Weg, abwechselnd etwas links und rechts daneben, damit sie sich nicht
/// berühren.
List<Offset> placeStations(List<Offset> route, List<StationInfo> stations, Size size, List<Offset>? dives) {
  final onPath = dives == null
      ? stations
      : [
          for (final s in stations)
            if (!s.isDive) s,
        ];
  final pathSpots = staggerBeside(placeAlongRoute(route, onPath.length, size, from: 0.03, to: 0.98), size, 17);
  var path = 0, dive = 0;
  return [
    for (final s in stations)
      if (dives != null && s.isDive) dives[dive++] else pathSpots[path++],
  ];
}

/// Die Insel von innen: Bild über die ganze Breite (Hochformat), darauf die
/// Pflichtstationen als Wegmarken vom Steg nach oben, die Ankerplätze am
/// Wasser. Ohne Bild ein grüner
/// Grund mit gezeichnetem Sandweg.
class IslandScene extends StatelessWidget {
  const IslandScene({
    super.key,
    required this.slug,
    required this.stations,
    required this.stateOf,
    required this.onOpen,
    this.avatar,
    this.arcade = const [],
    this.onArcade,
  });

  /// Richtige Spiele an ihren Orten auf dem Bild, mit „offen“ (Marcs Wunsch
  /// am 17.11.2026: Spiele dort, wo es den Ort auf der Insel schon gibt).
  final List<(ArcadeGame, bool)> arcade;
  final void Function(ArcadeGame game, bool unlocked)? onArcade;

  /// Spielfigur des Kindes (Löwe oder Löwin). Sie steht an der Station, die
  /// gerade dran ist, und läuft zur nächsten, wenn eine geschafft ist (Marcs
  /// Wunsch am 16.11.2026). `null` = keine Figur.
  final AvatarConfig? avatar;

  /// Größe der Spielfigur auf der Insel.
  static const playerSize = Size(54, 74);

  /// Seitenverhältnis der Inselbilder (BILDER.md: Hochformat 9:16).
  static const aspect = 9 / 16;

  final String slug;

  /// Pflichtstationen in ihrer Reihenfolge (auch Ankerplätze und Prüfung).
  final List<StationInfo> stations;
  final StationState Function(StationInfo) stateOf;
  final ValueChanged<StationInfo> onOpen;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final key = AssetKeys.islandBackground(slug);
    final entry = services.manifest.lookup(key);
    final route = entry.route ?? defaultIslandRoute;
    final spotsForDives = diveSpots(entry.dives, stations);
    final motion = services.sceneMotion && !MediaQuery.disableAnimationsOf(context);
    final next = stations.where((s) => stateOf(s) == StationState.open && !s.content.isOnboarding).firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = min(constraints.maxWidth, 600.0);
        final size = Size(width, width / aspect);
        const marker = 50.0;
        final spots = placeStations(route, stations, size, spotsForDives);
        return Center(
          child: SizedBox.fromSize(
            size: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Oben blendet das Bild weich ins Meer über, statt mit einer
                // harten Kante zu enden (Marcs Test am 17.11.2026: „oben
                // abgeschnitten und Wasser eingefügt“).
                Positioned.fill(
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xFF000000)],
                      stops: [0, 0.12],
                    ).createShader(rect),
                    child: TaleriaAsset(
                      key,
                      width: size.width,
                      height: size.height,
                      fit: BoxFit.cover,
                      fallback: CustomPaint(painter: _FallbackIslandPainter(route)),
                    ),
                  ),
                ),
                ?_player(spots, size, next, motion),
                for (final (game, unlocked) in arcade)
                  if (game.spot case final spot?)
                    Positioned(
                      left: spot.dx * size.width - 28,
                      top: spot.dy * size.height - 28,
                      width: 56,
                      height: 56,
                      child: ArcadeSpot(
                        key: ValueKey('arcade-spot-${game.id}'),
                        unlocked: unlocked,
                        motion: motion,
                        onTap: () => onArcade?.call(game, unlocked),
                      ),
                    ),
                for (final (i, station) in stations.indexed)
                  Positioned(
                    left: spots[i].dx * size.width - marker / 2,
                    top: spots[i].dy * size.height - marker / 2,
                    width: marker,
                    height: marker,
                    child: StationMarker(
                      key: ValueKey(
                        station.isDive ? 'dive-${station.displayNumber}' : 'station-${station.displayNumber}',
                      ),
                      station: station,
                      state: stateOf(station),
                      highlight: station.id == next?.id,
                      motion: motion,
                      onTap: () => onOpen(station),
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

/// Spiel-Ort auf der Insel: goldenes Spiel-Zeichen, offen leicht pulsierend,
/// gesperrt grau mit Schloss.
class ArcadeSpot extends StatefulWidget {
  const ArcadeSpot({super.key, required this.unlocked, required this.motion, required this.onTap});

  final bool unlocked;
  final bool motion;
  final VoidCallback onTap;

  @override
  State<ArcadeSpot> createState() => _ArcadeSpotState();
}

class _ArcadeSpotState extends State<ArcadeSpot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.motion && widget.unlocked) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sign = const GameSign(size: 46);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Center(
          child: widget.unlocked
              ? ScaleTransition(scale: Tween(begin: 0.94, end: 1.08).animate(_pulse), child: sign)
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Opacity(
                      opacity: 0.55,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0, //
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 1, 0,
                        ]),
                        child: sign,
                      ),
                    ),
                    const Positioned(
                      right: -4,
                      bottom: -4,
                      child: Icon(Icons.lock, size: 20, color: Color(0xFF4A5D70)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

extension on IslandScene {
  /// Die Spielfigur steht links neben der Station, die dran ist (sonst an der
  /// letzten geschafften). Ändert sich die Station, läuft sie hinüber.
  Widget? _player(List<Offset> spots, Size size, StationInfo? next, bool motion) {
    final avatar = this.avatar;
    if (avatar == null || stations.isEmpty) return null;
    var index = next == null ? -1 : stations.indexOf(next);
    if (index < 0) {
      index = stations.lastIndexWhere((s) => stateOf(s) == StationState.done);
      if (index < 0) index = 0;
    }
    final spot = spots[index];
    const s = IslandScene.playerSize;
    return AnimatedPositioned(
      key: const ValueKey('island-player'),
      duration: motion ? const Duration(milliseconds: 1600) : Duration.zero,
      curve: Curves.easeInOutCubic,
      left: spot.dx * size.width - 25 - s.width * 0.85,
      top: spot.dy * size.height - s.height + 18,
      width: s.width,
      height: s.height,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Weicher Schatten unter den Füßen.
            Positioned(
              left: s.width * 0.15,
              right: s.width * 0.15,
              bottom: -3,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6)],
                ),
              ),
            ),
            Positioned.fill(
              child: Breathing(
                child: CharacterImage(
                  avatarKey(avatar),
                  width: s.width,
                  height: s.height,
                  fallback: const SizedBox(),
                  clothTint: clothTint(avatar),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eine Wegmarke auf der Insel: geschafft (goldener Haken), dran (leuchtet),
/// gesperrt (Schloss), wartet auf Wind (Wind), Ankerplatz (Anker),
/// Abschlussprüfung (Flagge).
class StationMarker extends StatefulWidget {
  const StationMarker({
    super.key,
    required this.station,
    required this.state,
    required this.highlight,
    required this.motion,
    required this.onTap,
  });

  final StationInfo station;
  final StationState state;

  /// Die Station, die als Nächstes dran ist.
  final bool highlight;
  final bool motion;
  final VoidCallback onTap;

  @override
  State<StationMarker> createState() => _StationMarkerState();
}

class _StationMarkerState extends State<StationMarker> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Lichtwellen, die von der nächsten Station nach außen laufen (wie ein
  /// Stein im Wasser), damit das Kind sofort sieht, wo es weitergeht.
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(StationMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.highlight && widget.motion) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
      if (!_ripple.isAnimating) _ripple.repeat();
    } else {
      _pulse
        ..stop()
        ..value = 0;
      _ripple
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final station = widget.station;
    final state = widget.state;
    final done = state == StationState.done;

    final (Color fill, Color border, Color ink) = switch (state) {
      StationState.done => (palette.gold, palette.paper, Colors.white),
      StationState.open => (palette.paper, palette.gold, palette.seaDeep),
      StationState.noWind => (const Color(0xFFD6E4EE), palette.paper, palette.seaDeep),
      StationState.locked => (const Color(0xFFC9D1D8), palette.paper, const Color(0xFF66717C)),
    };
    // Was die Station ist (Nummer, Anker, Flagge), auch wenn sie noch zu ist.
    final Widget kind = switch (station) {
      _ when station.isDive => Icon(Icons.anchor, size: 26, color: ink),
      _ when station.isExam => Icon(Icons.flag_rounded, size: 26, color: ink),
      _ => Text(
        '${station.displayNumber}',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink),
      ),
    };
    final Widget symbol = state == StationState.done
        ? const Icon(Icons.check_rounded, size: 30, color: Colors.white)
        : kind;
    // Kleines Zeichen am Rand: Schloss oder Wind.
    final IconData? badge = switch (state) {
      StationState.locked => Icons.lock_rounded,
      StationState.noWind => Icons.air,
      _ => null,
    };
    // Echtes Mini-Spiel: Spiel-Zeichen oben rechts.
    final game = station.content.hasMiniGame;
    final name = station.isDive
        ? l10n.stationDive
        : (station.isExam ? l10n.stationExam : l10n.stationNumber(station.displayNumber));

    return Semantics(
      button: true,
      label:
          '$name: ${station.content.title}${game ? ' · ${l10n.islandStationGame}' : ''}'
          '${done ? ' · ${l10n.stationDone}' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _ripple]),
          builder: (context, child) {
            final glow = widget.highlight ? 0.55 + 0.45 * _pulse.value : 0.0;
            final marker = Transform.scale(
              scale: widget.highlight ? 1.06 + 0.06 * _pulse.value : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(color: border, width: widget.highlight ? 4 : 3),
                  boxShadow: [
                    const BoxShadow(color: Color(0x66081C30), blurRadius: 6, offset: Offset(0, 3)),
                    if (glow > 0)
                      BoxShadow(
                        color: const Color(0xFFFFD866).withValues(alpha: glow),
                        blurRadius: 18,
                        spreadRadius: 6,
                      ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    child!,
                    if (game)
                      Positioned(
                        right: -10,
                        top: -10,
                        child: GameSign(key: ValueKey('station-game-${station.id}'), size: 26),
                      ),
                    if (badge != null)
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: state == StationState.noWind ? palette.seaDeep : const Color(0xFF6E7A86),
                            border: Border.all(color: palette.paper, width: 2),
                          ),
                          child: Icon(badge, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            );
            if (!widget.highlight) return marker;
            // Unter der Station: ein warmer Lichtfleck und zwei Wellen.
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _RipplePainter(progress: widget.motion ? _ripple.value : 0.35)),
                  ),
                ),
                marker,
              ],
            );
          },
          child: symbol,
        ),
      ),
    );
  }
}

/// Grüner Grund mit hellem Sandweg, solange das Inselbild fehlt.
class _FallbackIslandPainter extends CustomPainter {
  const _FallbackIslandPainter(this.route);

  final List<Offset> route;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA9DB8C), Color(0xFF7FC36C), Color(0xFFE9D19E)],
          stops: [0, 0.82, 1],
        ).createShader(rect),
    );
    final path = Path();
    for (final (i, p) in route.indexed) {
      final point = Offset(p.dx * size.width, p.dy * size.height);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFF3E2BE),
    );
  }

  @override
  bool shouldRepaint(_FallbackIslandPainter oldDelegate) => oldDelegate.route != route;
}

/// Lichtwellen um die nächste Station: zwei goldene Ringe laufen nach außen
/// und verblassen, darunter ein weicher Lichtschein.
class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.progress});

  /// 0 bis 1, eine Welle pro Durchlauf.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      r * 2.1,
      Paint()
        ..shader = RadialGradient(colors: [const Color(0xFFFFE08A).withValues(alpha: 0.55), const Color(0x00FFE08A)])
            .createShader(Rect.fromCircle(center: center, radius: r * 2.1)),
    );
    for (final offset in [0.0, 0.5]) {
      final t = (progress + offset) % 1;
      final radius = r * (1.05 + 1.15 * t);
      final alpha = (1 - t) * 0.85;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - t) + 1.5
          ..color = const Color(0xFFFFF1B8).withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}
