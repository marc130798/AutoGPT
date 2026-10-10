import 'dart:math';

import 'package:flutter/material.dart';

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

/// Die Inselkarte: scrollt senkrecht, die Route führt von unten (Hafen)
/// nach oben (Schatzinsel). Inseln im Nebel und gesperrte Inseln sind
/// sichtbar, aber nicht betretbar.
class IslandMapScreen extends StatefulWidget {
  const IslandMapScreen({super.key, required this.child});

  final ChildProfile child;

  @override
  State<IslandMapScreen> createState() => _IslandMapScreenState();
}

class _IslandMapScreenState extends State<IslandMapScreen> {
  MapController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final services = AppScope.of(context);
      _controller = MapController(content: services.content!, progress: services.progress!, child: widget.child)
        ..load();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onTap(MapIsland island) async {
    final l10n = AppLocalizations.of(context);
    final controller = _controller!;
    switch (controller.stateOf(island)) {
      case IslandState.fog:
        _hint(l10n.mapIslandFog);
      case IslandState.locked:
        _hint(l10n.mapIslandLocked);
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
          if (controller.loading) return const Center(child: CircularProgressIndicator());
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
          return Column(
            children: [
              if (controller.fogAhead)
                _FogBanner(onPractice: _practice)
              else if (pace != null && !pace.hasWind)
                _WindBanner(text: l10n.windNeededFor(pace)),
              Expanded(
                child: _MapCanvas(controller: controller, onTap: _onTap, onEncounter: _openEncounter),
              ),
            ],
          );
        },
      ),
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

/// Alle offenen Inseln geschafft, die nächste liegt im Nebel: keine
/// Fehlermeldung, sondern Kontrollfahrten, Tauchgänge und Spiele (Abschnitt 8).
class _FogBanner extends StatelessWidget {
  const _FogBanner({required this.onPractice});

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
            Text(l10n.fogAheadTitle, style: theme.textTheme.titleSmall),
            Text(l10n.fogAheadBody, style: theme.textTheme.bodySmall),
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

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({required this.controller, required this.onTap, required this.onEncounter});

  static const _markerSize = 96.0;
  static const _encounterWidth = 140.0;

  final MapController controller;
  final ValueChanged<MapIsland> onTap;
  final VoidCallback onEncounter;

  @override
  Widget build(BuildContext context) {
    final islands = controller.islands;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Genug Platz pro Insel, mindestens so hoch wie der Bildschirm.
        final height = max(constraints.maxHeight, islands.length * 150.0 + 160);
        Offset position(MapIsland i) => Offset(
          (i.mapX * width).clamp(_markerSize / 2 + 8, width - _markerSize / 2 - 8),
          (i.mapY * height).clamp(_markerSize, height - _markerSize),
        );
        final route = [...islands.where((i) => i.isMainRoute)]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final ship = islands.where((i) => i.id == controller.shipIslandId).firstOrNull;

        return SingleChildScrollView(
          // Start unten beim Hafen.
          reverse: true,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                const Positioned.fill(child: TaleriaAsset(AssetKeys.mapBackground, fit: BoxFit.cover)),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RoutePainter([for (final i in route) position(i)], context.palette.paper),
                  ),
                ),
                for (final island in islands)
                  Positioned(
                    left: position(island).dx - _markerSize / 2 - 16,
                    top: position(island).dy - _markerSize / 2,
                    width: _markerSize + 32,
                    child: _IslandMarker(
                      island: island,
                      state: controller.stateOf(island),
                      hasShip: controller.shipIslandId == island.id,
                      size: _markerSize,
                      onTap: () => onTap(island),
                    ),
                  ),
                if (controller.encounter != null && ship != null)
                  Positioned(
                    // Neben dem Schiff, auf der Seite mit mehr Platz.
                    left:
                        (position(ship).dx < width / 2
                                ? position(ship).dx + _markerSize / 2 + 8
                                : position(ship).dx - _markerSize / 2 - 8 - _encounterWidth)
                            .clamp(8.0, max(8.0, width - _encounterWidth - 8)),
                    top: position(ship).dy - _markerSize / 2,
                    width: _encounterWidth,
                    child: EncounterMapButton(encounter: controller.encounter!.encounter, onTap: onEncounter),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IslandMarker extends StatelessWidget {
  const _IslandMarker({
    required this.island,
    required this.state,
    required this.hasShip,
    required this.size,
    required this.onTap,
  });

  final MapIsland island;
  final IslandState state;
  final bool hasShip;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final theme = Theme.of(context);
    final fog = state == IslandState.fog;

    return Semantics(
      button: true,
      label: fog ? l10n.mapIslandFogTitle(island.title) : island.title,
      child: GestureDetector(
        key: ValueKey('island-${island.slug}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: state == IslandState.open
                            ? [BoxShadow(color: palette.gold.withValues(alpha: 0.8), blurRadius: 18, spreadRadius: 4)]
                            : null,
                      ),
                      child: ClipOval(
                        child: Opacity(
                          opacity: state == IslandState.locked ? 0.6 : 1,
                          child: TaleriaAsset(AssetKeys.islandBackground(island.slug), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                  if (fog)
                    const Positioned.fill(
                      child: ClipOval(child: TaleriaAsset(AssetKeys.mapFog, fit: BoxFit.cover)),
                    ),
                  if (state == IslandState.locked)
                    const Positioned(
                      right: -4,
                      bottom: -4,
                      child: TaleriaAsset(AssetKeys.mapLock, width: 36, height: 36),
                    ),
                  if (state == IslandState.completed)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: palette.success,
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                    ),
                  if (hasShip)
                    Positioned(
                      left: -20,
                      top: -12,
                      child: Semantics(
                        label: l10n.mapYouAreHere,
                        child: const TaleriaAsset(AssetKeys.crewShip, width: 56, height: 36),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: palette.paper.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fog ? l10n.mapIslandFogTitle(island.title) : island.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gestrichelte Route zwischen den Inseln der Hauptroute.
class _RoutePainter extends CustomPainter {
  _RoutePainter(this.points, this.color);

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final distance = (b - a).distance;
      const dash = 12.0, gap = 10.0;
      for (var d = 0.0; d < distance; d += dash + gap) {
        final start = Offset.lerp(a, b, d / distance)!;
        final end = Offset.lerp(a, b, min(d + dash, distance) / distance)!;
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) => oldDelegate.points != points || oldDelegate.color != color;
}
