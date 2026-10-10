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
import '../common/texts.dart';
import '../encounter/encounter_screen.dart';
import '../island/island_screen.dart';
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

  /// Fahrt des Schiffs (Routen-Stellen) und die Insel, deren Schloss aufspringt.
  int? _travelFrom;
  int? _travelTo;
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

  /// Nach jedem Laden: Nebel-Start (einmal) und, wenn eine neue Insel offen
  /// ist, die Fahrt des Schiffs dorthin.
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
    final target = controller.shipIslandId;
    if (target == null) return;
    final settings = AppScope.of(context).settings;
    final last = await settings.lastShipIsland(widget.child.id);
    if (last != target) await settings.setLastShipIsland(widget.child.id, target);
    if (!mounted || !_motion || last == null || last == target) return;

    final route = [...controller.islands.where((i) => i.isMainRoute)]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final from = route.indexWhere((i) => i.id == last);
    final to = route.indexWhere((i) => i.id == target);
    if (from < 0 || to <= from) return;
    setState(() {
      _travelFrom = from;
      _travelTo = to;
      _unlockingId = target;
    });
    _travel.value = 0;
    _unlock.value = 0;
    try {
      await _introDone();
      if (!mounted) return;
      final layout = _layout;
      if (layout != null && _scroll.hasClients) {
        unawaited(
          _scroll.animateTo(
            layout.offsetToShow(layout.centerOf(target).dy, _viewport),
            duration: const Duration(milliseconds: 1800),
            curve: Curves.easeInOut,
          ),
        );
      }
      await _travel.forward(from: 0).orCancel;
      if (!mounted) return;
      setState(() {
        _travelFrom = null;
        _travelTo = null;
      });
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
      case IslandState.open || IslandState.completed:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => IslandScreen(child: widget.child, island: island),
          ),
        );
        await controller.load();
    }
  }

  Future<void> _openEncounter() async {
    final offer = _controller!.encounter;
    if (offer == null) {
      _hint(AppLocalizations.of(context).mapEncounterNone);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EncounterScreen(childId: widget.child.id, offer: offer),
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
        MaterialPageRoute<void>(
          builder: (_) => EncounterScreen(childId: widget.child.id, offer: offer),
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
    return Scaffold(
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
          final shipId = controller.shipIslandId;
          if (shipId != null) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) {
                _scroll.jumpTo(layout.offsetToShow(layout.centerOf(shipId).dy, constraints.maxHeight));
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
                  travelFrom: _travelFrom,
                  travelTo: _travelTo,
                  travel: Curves.easeInOut.transform(_travel.value),
                  unlockingId: _unlockingId,
                  unlock: _unlock.value,
                  onTap: _onTap,
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
    required this.travelFrom,
    required this.travelTo,
    required this.travel,
    required this.unlockingId,
    required this.unlock,
    required this.onTap,
    required this.onEncounter,
  });

  static const _encounterWidth = 140.0;

  final MapController controller;
  final MapLayout layout;
  final Animation<double> clock;
  final int? travelFrom;
  final int? travelTo;
  final double travel;
  final String? unlockingId;
  final double unlock;
  final ValueChanged<MapIsland> onTap;
  final VoidCallback onEncounter;

  @override
  Widget build(BuildContext context) {
    final islands = controller.islands;
    final route = layout.route;
    final shipId = controller.shipIslandId;
    final shipIndex = layout.routeIndexOf(shipId);
    final traveling = travelFrom != null && travelTo != null;
    final fogFrom = route.indexWhere((i) => controller.stateOf(i) == IslandState.fog);
    final centers = [for (final i in islands) layout.centerOf(i.id)];

    // Schiff: auf der Fahrt entlang der Route, sonst am Ankerplatz.
    Offset? shipPosition;
    var facingLeft = false;
    if (traveling) {
      final step = layout.travel(travelFrom!, travelTo!, travel);
      shipPosition = step.position;
      facingLeft = step.movingLeft;
    } else if (shipId != null) {
      shipPosition = layout.shipAnchor(shipId);
      final next = shipIndex >= 0 && shipIndex + 1 < route.length ? route[shipIndex + 1] : null;
      facingLeft = next != null && layout.centerOf(next.id).dx < shipPosition.dx;
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
      } else if (state == IslandState.locked || state == IslandState.premium) {
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
            glow: island.id == shipId && state == IslandState.open && !traveling && !unlocking,
            lock: lock,
            onTap: () => onTap(island),
          ),
        ),
      ));
    }
    if (shipPosition != null) {
      final size = layout.shipSize;
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
                goldUntil: traveling ? travelFrom! + travel * (travelTo! - travelFrom!) : max(0, shipIndex).toDouble(),
                fogFrom: fogFrom < 0 ? route.length : fogFrom,
                clock: clock,
              ),
            ),
          ),
        ),
        for (final layer in layers) layer.$2,
        if (controller.encounter != null && shipPosition != null && !traveling)
          Positioned(
            // Neben dem Schiff, auf der Seite mit mehr Platz.
            left:
                (shipPosition.dx < layout.width / 2
                        ? shipPosition.dx + layout.shipSize / 2
                        : shipPosition.dx - layout.shipSize / 2 - _encounterWidth)
                    .clamp(8.0, max(8.0, layout.width - _encounterWidth - 8)),
            top: shipPosition.dy - layout.shipSize * 0.9,
            width: _encounterWidth,
            child: EncounterMapButton(encounter: controller.encounter!.encounter, onTap: onEncounter),
          ),
      ],
    );
  }
}
