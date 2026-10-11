import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../services/map_controller.dart';
import '../common/fog_reveal.dart';
import '../common/menu_music.dart';
import '../common/texts.dart';
import '../encounter/encounter_screen.dart';
import '../island/island_screen.dart';
import '../station/station_screen.dart';
import 'map_layout.dart';
import 'map_painters.dart';
import 'map_scene.dart';

/// Die Inselkarte: scrollt senkrecht, die Route führt von unten (Hafen)
/// nach oben (Schatzinsel). Inseln im Nebel und gesperrte Inseln sind
/// sichtbar, aber nicht betretbar.
///
/// Bewegung: Beim Öffnen ziehen Wolken auseinander (Nebel-Start), das Meer
/// schimmert, und ist seit dem letzten Besuch eine neue Insel offen, segelt das
/// Schiff dorthin und das Schloss springt auf. Mit „Bewegung reduzieren“ steht
/// alles still.
class IslandMapScreen extends StatefulWidget {
  const IslandMapScreen({super.key, required this.child});

  final ChildProfile child;

  @override
  State<IslandMapScreen> createState() => _IslandMapScreenState();
}

class _IslandMapScreenState extends State<IslandMapScreen> with TickerProviderStateMixin {
  MapController? _controller;

  /// Uhr für Wellen, Wolken, Flaggen (eine Minute, wiederholt sich).
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(minutes: 1));
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );
  late final AnimationController _unlock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  final ScrollController _scroll = ScrollController();

  bool _motion = false;
  bool _wasLoading = true;
  bool _introStarted = false;
  bool _scrolledToShip = false;

  /// Fahrt des Schiffs (von Liegeplatz zu Liegeplatz: Insel oder Stopp auf
  /// See) und die Insel, deren Schloss aufspringt.
  String? _travelFromId;
  String? _travelToId;
  String? _unlockingId;
  MapLayout? _layout;
  double _viewport = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final services = AppScope.of(context);
      _motion = services.sceneMotion && !MediaQuery.disableAnimationsOf(context);
      if (_motion) {
        _clock.repeat();
      } else {
        _intro.value = 1;
      }
      final controller = MapController(content: services.content!, progress: services.progress!, child: widget.child);
      _controller = controller;
      controller
        ..addListener(_onControllerChanged)
        ..load();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _clock.dispose();
    _intro.dispose();
    _travel.dispose();
    _unlock.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final loading = _controller!.loading;
    if (_wasLoading && !loading) unawaited(_afterLoad());
    _wasLoading = loading;
  }

  /// Nach jedem Laden: Nebel-Start (einmal) und, wenn das Schiff weiter darf
  /// (ein Stopp auf See oder eine Insel ist geschafft), die Fahrt dorthin.
  Future<void> _afterLoad() async {
    final controller = _controller!;
    if (controller.failure != null) {
      _intro.value = 1;
      return;
    }
    if (_motion && !_introStarted) {
      _introStarted = true;
      unawaited(_intro.forward());
    }
    final target = controller.shipBerthId;
    if (target == null) return;
    final settings = AppScope.of(context).settings;
    final last = await settings.lastShipIsland(widget.child.id);
    if (last != target) await settings.setLastShipIsland(widget.child.id, target);
    if (!mounted || !_motion || last == null || last == target) return;

    final order = controller.berthOrder;
    final from = order.indexOf(last);
    final to = order.indexOf(target);
    if (from < 0 || to <= from) return;
    bool isIsland(String id) => controller.islands.any((i) => i.id == id);
    setState(() {
      _travelFromId = last;
      _travelToId = target;
      // Das Schloss springt nur an Inseln auf, nicht an Stopps.
      _unlockingId = isIsland(target) ? target : null;
    });
    _travel.value = 0;
    _unlock.value = 0;
    // Von Stopp zu Stopp eine kurze Fahrt, von Insel zu Insel eine lange.
    final hops = to - from;
    _travel.duration = hops == 1 && isIsland(last) && isIsland(target)
        ? const Duration(milliseconds: 3400)
        : Duration(milliseconds: min(3400, 1500 + 900 * (hops - 1)));
    try {
      await _introDone();
      if (!mounted) return;
      final layout = _layout;
      final berth = layout == null ? null : berthOf(layout, controller, target);
      if (layout != null && berth != null && _scroll.hasClients) {
        unawaited(
          _scroll.animateTo(
            layout.offsetToShow(berth.anchor.dy, _viewport),
            duration: const Duration(milliseconds: 1800),
            curve: Curves.easeInOut,
          ),
        );
      }
      await _travel.forward(from: 0).orCancel;
      if (!mounted) return;
      setState(() {
        _travelFromId = null;
        _travelToId = null;
      });
      if (_unlockingId == null) return;
      await _unlock.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (mounted) setState(() => _unlockingId = null);
  }

  Future<void> _introDone() {
    if (_intro.isCompleted) return Future.value();
    final done = Completer<void>();
    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _intro.removeStatusListener(listener);
        done.complete();
      }
    }

    _intro.addStatusListener(listener);
    return done.future;
  }

  Future<void> _onTap(MapIsland island) async {
    final l10n = AppLocalizations.of(context);
    final controller = _controller!;
    // Ohne Abo bleiben Premium-Inseln zu, auch schon abgeschlossene (kein Kauf-Knopf
    // im Kinderbereich, nur ein Hinweis auf die Eltern).
    if (controller.premiumBlocked(island) && controller.stateOf(island) != IslandState.fog) {
      _hint(l10n.mapIslandPremium);
      return;
    }
    switch (controller.stateOf(island)) {
      case IslandState.fog:
        _hint(l10n.mapIslandFog);
      case IslandState.locked:
        _hint(l10n.mapIslandLocked);
      case IslandState.premium:
        _hint(l10n.mapIslandPremium);
      case IslandState.open when controller.waitingAtSea(island):
        // Erst die Stopps auf See auf dem Weg dorthin.
        _hint(l10n.mapSeaStopsFirst);
      case IslandState.open || IslandState.completed:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => IslandScreen(child: widget.child, island: island),
          ),
        );
        await controller.load();
    }
  }

  /// Stopp auf See: eine kurze Station mit Szene und Fragen zur Insel davor.
  Future<void> _openStop(StationInfo stop) async {
    final controller = _controller!;
    if (controller.stopState(stop) == StationState.locked) {
      _hint(AppLocalizations.of(context).mapSeaStopLocked);
      return;
    }
    final island = controller.islandOf(stop);
    // Nebel zieht auf, dann taucht das Schiff auf.
    await Navigator.of(context).push(
      fogRoute<void>(
        StationScreen(child: widget.child, island: island, station: stop, allStations: controller.stopsBefore(island)),
      ),
    );
    await controller.load();
  }

  Future<void> _openEncounter() async {
    final offer = _controller!.encounter;
    if (offer == null) {
      _hint(AppLocalizations.of(context).mapEncounterNone);
      return;
    }
    await Navigator.of(context).push(
      fogRoute<void>(
        EncounterScreen(
          childId: widget.child.id,
          offer: offer,
          rankForm: widget.child.rankForm,
          level: widget.child.level,
        ),
      ),
    );
    await _controller!.load();
  }

  /// Nebel voraus: eine Begegnung zum Üben, auch ohne fällige Wiederholungen.
  Future<void> _practice() async {
    final controller = _controller!;
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final offer = controller.encounter ?? await controller.practiceEncounter();
      if (!mounted) return;
      if (offer == null) {
        _hint(l10n.mapEncounterNone);
        return;
      }
      await navigator.push(
        fogRoute<void>(
          EncounterScreen(
            childId: widget.child.id,
            offer: offer,
            rankForm: widget.child.rankForm,
            level: widget.child.level,
          ),
        ),
      );
      await controller.load();
    } on AppFailure catch (e) {
      _hint(l10n.failure(e.kind));
    }
  }

  void _hint(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller!;
    // Meeresrauschen wie auf der Startseite, ohne Unterbrechung.
    return MenuMusic(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.mapTitle)),
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.loading) {
              return Stack(
                children: [
                  if (_motion)
                    Positioned.fill(
                      child: FogIntro(progress: _intro, onSkip: () {}),
                    ),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (controller.failure != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.failure(controller.failure!), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: controller.load, child: Text(l10n.retryButton)),
                    ],
                  ),
                ),
              );
            }
            final pace = controller.stats?.pace;
            return Stack(
              children: [
                Column(
                  children: [
                    if (controller.blockedAhead case final block?)
                      _BlockedBanner(block: block, onPractice: _practice)
                    else if (pace != null && !pace.hasWind)
                      _WindBanner(text: l10n.windNeededFor(pace)),
                    Expanded(child: _buildMap(controller)),
                  ],
                ),
                Positioned.fill(
                  child: FogIntro(progress: _intro, onSkip: () => _intro.value = 1),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

extension on _IslandMapScreenState {
  Widget _buildMap(MapController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = MapLayout.compute(
          width: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
          islands: controller.islands,
        );
        _layout = layout;
        _viewport = constraints.maxHeight;
        if (!_scrolledToShip) {
          _scrolledToShip = true;
          final berthId = controller.shipBerthId;
          final berth = berthId == null ? null : berthOf(layout, controller, berthId);
          if (berth != null) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) {
                _scroll.jumpTo(layout.offsetToShow(berth.anchor.dy, constraints.maxHeight));
              }
            });
          }
        }
        return AnimatedBuilder(
          animation: _intro,
          builder: (context, child) {
            // Beim Nebel-Start sinkt die Kamera ein Stück herab.
            final q = Curves.easeOut.transform(_intro.value);
            return Transform.scale(scale: 1 + 0.12 * (1 - q), child: child);
          },
          child: SingleChildScrollView(
            controller: _scroll,
            // Start unten beim Hafen.
            reverse: true,
            child: SizedBox(
              width: layout.width,
              height: layout.height,
              child: AnimatedBuilder(
                animation: Listenable.merge([_travel, _unlock]),
                builder: (context, _) => _MapScene(
                  controller: controller,
                  layout: layout,
                  clock: _clock,
                  travelFromId: _travelFromId,
                  travelToId: _travelToId,
                  travel: Curves.easeInOut.transform(_travel.value),
                  unlockingId: _unlockingId,
                  unlock: _unlock.value,
                  onTap: _onTap,
                  onStop: _openStop,
                  onEncounter: _openEncounter,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tempo als Geschichte, nie als Sperre mit Countdown (CLAUDE.md Abschnitt 8).
class _WindBanner extends StatelessWidget {
  const _WindBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Material(
      key: const ValueKey('wind-banner'),
      color: palette.paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Icon(Icons.air, color: palette.seaDeep, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: Theme.of(context).textTheme.titleSmall),
                  Text(l10n.windMeanwhile, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alle offenen Inseln geschafft, die nächste liegt im Nebel oder gehört zum
/// Abo: keine Fehlermeldung, sondern Kontrollfahrten, Tauchgänge und Spiele
/// (Abschnitt 8). Kein Kauf-Knopf im Kinderbereich.
class _BlockedBanner extends StatelessWidget {
  const _BlockedBanner({required this.block, required this.onPractice});

  final RouteBlock block;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('fog-banner'),
      color: palette.paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              block == RouteBlock.fog ? l10n.fogAheadTitle : l10n.premiumAheadTitle,
              style: theme.textTheme.titleSmall,
            ),
            Text(block == RouteBlock.fog ? l10n.fogAheadBody : l10n.premiumAheadBody, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey('fog-practice'),
              onPressed: onPractice,
              icon: const Icon(Icons.sailing),
              label: Text(l10n.fogAheadButton),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alles auf der Karte: Meer, Route, Inseln, Schiff und Begegnung.
class _MapScene extends StatelessWidget {
  const _MapScene({
    required this.controller,
    required this.layout,
    required this.clock,
    required this.travelFromId,
    required this.travelToId,
    required this.travel,
    required this.unlockingId,
    required this.unlock,
    required this.onTap,
    required this.onStop,
    required this.onEncounter,
  });

  /// Platz für Meister Taleron mit Namen (Bild 72, Name in bis zu zwei Zeilen).
  static const _encounterSize = Size(140, 124);

  final MapController controller;
  final MapLayout layout;
  final Animation<double> clock;
  final String? travelFromId;
  final String? travelToId;
  final double travel;
  final String? unlockingId;
  final double unlock;
  final ValueChanged<MapIsland> onTap;
  final ValueChanged<StationInfo> onStop;
  final VoidCallback onEncounter;

  @override
  Widget build(BuildContext context) {
    final islands = controller.islands;
    final route = layout.route;
    final shipId = controller.shipIslandId;
    final berthId = controller.shipBerthId;
    final shipIndex = layout.routeIndexOf(shipId);
    final fromBerth = travelFromId == null ? null : berthOf(layout, controller, travelFromId!);
    final toBerth = travelToId == null ? null : berthOf(layout, controller, travelToId!);
    final traveling = fromBerth != null && toBerth != null;
    final restBerth = berthId == null ? null : berthOf(layout, controller, berthId);
    final fogFrom = route.indexWhere((i) => controller.stateOf(i) == IslandState.fog);
    final centers = [for (final i in islands) layout.centerOf(i.id)];

    // Schiff: auf der Fahrt entlang der Route, sonst am Liegeplatz (Insel
    // oder Stopp auf See). Die Route ist bis zum Schiff golden.
    Offset? shipPosition;
    var facingLeft = false;
    var shipScale = 1.0;
    var goldUntil = max(0, shipIndex).toDouble();
    if (traveling) {
      final step = layout.sail(fromBerth, toBerth, travel);
      shipPosition = step.position;
      facingLeft = step.movingLeft;
      shipScale = step.scale;
      goldUntil = fromBerth.u + travel * (toBerth.u - fromBerth.u);
    } else if (restBerth != null) {
      shipPosition = restBerth.anchor;
      shipScale = restBerth.scale;
      goldUntil = restBerth.u;
      // Bug zum nächsten Liegeplatz.
      final order = controller.berthOrder;
      final i = order.indexOf(berthId!);
      final next = i >= 0 && i + 1 < order.length ? berthOf(layout, controller, order[i + 1]) : null;
      facingLeft = next != null && next.anchor.dx < restBerth.anchor.dx;
    }

    // Nach Tiefe sortiert: weiter oben liegende Inseln zuerst, damit nähere
    // Inseln und das Schiff davor liegen.
    final layers = <(double, Widget)>[];
    for (final island in islands) {
      final c = layout.centerOf(island.id);
      final state = controller.stateOf(island);
      final unlocking = island.id == unlockingId;
      final double? lock;
      if (unlocking) {
        lock = traveling ? 0 : unlock;
      } else if (state == IslandState.locked || state == IslandState.premium || controller.waitingAtSea(island)) {
        // Auch vor offenen Inseln, auf deren Weg noch Stopps auf See liegen.
        lock = 0;
      } else {
        lock = null;
      }
      layers.add((
        c.dy,
        Positioned(
          left: c.dx - layout.islandWidth / 2,
          top: c.dy - layout.islandHeight / 2,
          width: layout.islandWidth,
          height: layout.islandHeight + MapIslandMarker.labelSpace,
          child: MapIslandMarker(
            island: island,
            state: state,
            width: layout.islandWidth,
            height: layout.islandHeight,
            clock: clock,
            glow: island.id == berthId && state == IslandState.open && !traveling && !unlocking,
            lock: lock,
            onTap: () => onTap(island),
          ),
        ),
      ));
    }
    // Stopps auf See im Meer zwischen zwei Inseln.
    for (final (index, island) in route.indexed) {
      final stops = controller.stopsBefore(island);
      final spots = layout.seaStopSpots(index, stops.length);
      for (final (k, stop) in stops.indexed.take(spots.length)) {
        final spot = spots[k];
        layers.add((
          spot.dy,
          Positioned(
            // Ganze Marke (Kreis und Name) mittig im Meer zwischen den Inseln.
            left: spot.dx - SeaStopMarker.labelWidth / 2,
            top: spot.dy - SeaStopMarker.height / 2,
            width: SeaStopMarker.labelWidth,
            height: SeaStopMarker.height,
            child: Align(
              alignment: Alignment.topCenter,
              child: SeaStopMarker(
                key: ValueKey('sea-stop-${island.slug}-${k + 1}'),
                stop: stop,
                state: controller.stopState(stop),
                onTap: () => onStop(stop),
              ),
            ),
          ),
        ));
      }
    }
    if (shipPosition != null) {
      final size = layout.shipSize * shipScale;
      layers.add((
        shipPosition.dy,
        Positioned(
          left: shipPosition.dx - size / 2,
          top: shipPosition.dy - size * 0.75,
          width: size,
          height: size,
          child: IgnorePointer(
            child: MapShip(size: size, clock: clock, facingLeft: facingLeft, moving: traveling),
          ),
        ),
      ));
    }
    layers.sort((a, b) => a.$1.compareTo(b.$1));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: SeaPainter(islands: centers, islandWidth: layout.islandWidth),
            ),
          ),
        ),
        // Wasserbild aus BILDER.md, falls es da ist (sonst nur der gezeichnete Grund).
        const Positioned.fill(
          child: Opacity(
            // Der gezeichnete Grund (dunkler in der Tiefe) scheint leicht durch.
            opacity: 0.78,
            child: TaleriaAsset(
              AssetKeys.mapBackground,
              fit: BoxFit.fitWidth,
              repeat: ImageRepeat.repeatY,
              alignment: Alignment.topCenter,
              fallback: SizedBox.shrink(),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: SeaSurfacePainter(clock: clock, islands: centers, islandWidth: layout.islandWidth),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: RoutePainter(
                layout: layout,
                goldUntil: goldUntil,
                fogFrom: fogFrom < 0 ? route.length : fogFrom,
                clock: clock,
              ),
            ),
          ),
        ),
        for (final layer in layers) layer.$2,
        if (controller.encounter != null && shipId != null && !traveling)
          if (layout.encounterSpot(
                shipId,
                _encounterSize,
                // Liegt das Schiff an einem Stopp, taucht Taleron nicht darauf auf.
                avoid: [
                  if (controller.shipStop != null && shipPosition != null) layout.shipRect(shipPosition, shipScale),
                ],
              )
              case final spot)
            Positioned(
              // Im Meer vor dem Schiff, unten rechts vom Weg (nie auf einer Insel).
              left: spot.dx,
              top: spot.dy,
              width: _encounterSize.width,
              child: EncounterMapButton(encounter: controller.encounter!.encounter, onTap: onEncounter),
            ),
      ],
    );
  }
}

/// Liegeplatz zu einer ID: eine Insel der Route oder ein Stopp auf See davor.
ShipBerth? berthOf(MapLayout layout, MapController controller, String id) {
  if (layout.routeIndexOf(id) >= 0) return layout.islandBerth(id);
  for (final (index, island) in layout.route.indexed) {
    final stops = controller.stopsBefore(island);
    final k = stops.indexWhere((s) => s.id == id);
    if (k >= 0 && index > 0) return layout.stopBerth(index, stops.length, k);
  }
  return null;
}
