import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/assets/video_placeholder.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../services/island_controller.dart';
import '../common/texts.dart';
import '../station/dialog_sequence.dart';
import '../station/station_screen.dart';

/// Eine Insel: Ankunft beim ersten Besuch, danach die Stationen der Reihe nach.
class IslandScreen extends StatefulWidget {
  const IslandScreen({super.key, required this.child, required this.island});

  final ChildProfile child;
  final MapIsland island;

  @override
  State<IslandScreen> createState() => _IslandScreenState();
}

class _IslandScreenState extends State<IslandScreen> {
  IslandController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final services = AppScope.of(context);
      _controller = IslandController(
        content: services.content!,
        progress: services.progress!,
        settings: services.settings,
        child: widget.child,
        island: widget.island,
      )..load();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openStation(StationInfo station) async {
    final l10n = AppLocalizations.of(context);
    final controller = _controller!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (station.content.isOnboarding) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.stationIntroDone)));
      return;
    }
    if (controller.stateOf(station) == StationState.locked) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.stationLocked)));
      return;
    }
    if (controller.stateOf(station) == StationState.noWind) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.windNeededFor(controller.pace))));
      return;
    }
    final result = await navigator.push<StationResult>(
      MaterialPageRoute(
        builder: (_) => StationScreen(
          child: widget.child,
          island: widget.island,
          station: station,
          allStations: controller.stations,
          details: controller.details,
        ),
      ),
    );
    // Insel geschafft: zurück zur Karte, dort ist die nächste Insel offen.
    if (result?.islandCompleted ?? false) {
      navigator.pop();
      return;
    }
    await controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final details = controller.details;
        final Widget body;
        if (controller.loading) {
          body = const Center(child: CircularProgressIndicator());
        } else if (controller.failure != null) {
          body = Center(
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
        } else if (controller.arrivalPending) {
          body = _Arrival(details: details!, onDone: controller.arrivalShown);
        } else {
          body = _StationList(controller: controller, onOpen: _openStation);
        }
        return Scaffold(
          appBar: AppBar(title: Text(details?.title ?? widget.island.title)),
          body: SafeArea(child: body),
        );
      },
    );
  }
}

/// Ankunft auf der Insel: Film (Platzhalter) und Szene.
class _Arrival extends StatefulWidget {
  const _Arrival({required this.details, required this.onDone});

  final IslandDetails details;
  final VoidCallback onDone;

  @override
  State<_Arrival> createState() => _ArrivalState();
}

class _ArrivalState extends State<_Arrival> {
  late bool _showFilm = widget.details.arrivalVideoKey != null;

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    if (_showFilm) {
      return VideoPlaceholder(
        assetKey: details.arrivalVideoKey!,
        onContinue: () => details.arrivalScene.isEmpty ? widget.onDone() : setState(() => _showFilm = false),
      );
    }
    return DialogSequence(lines: details.arrivalScene, onDone: widget.onDone);
  }
}

class _StationList extends StatelessWidget {
  const _StationList({required this.controller, required this.onOpen});

  final IslandController controller;
  final ValueChanged<StationInfo> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final details = controller.details!;
    final stations = controller.stations;
    final allDone = stations.where((s) => s.isRequired).every((s) => controller.stateOf(s) == StationState.done);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: TaleriaAsset(AssetKeys.islandBackground(details.slug), width: 220, height: 120)),
        if (details.goal != null) ...[
          const SizedBox(height: 12),
          Text(details.goal!, style: theme.textTheme.bodyLarge),
        ],
        if (allDone && stations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.islandAllDone, style: theme.textTheme.titleMedium),
        ],
        if (stations.any((s) => controller.stateOf(s) == StationState.noWind)) ...[
          const SizedBox(height: 12),
          Card(
            key: const ValueKey('island-wind-hint'),
            child: ListTile(
              leading: const Icon(Icons.air),
              title: Text(l10n.windNeededFor(controller.pace)),
              subtitle: Text(l10n.windMeanwhile),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.islandStationsHeading, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final station in stations)
          _StationTile(station: station, state: controller.stateOf(station), onTap: () => onOpen(station)),
        if (details.hasArrival)
          TextButton.icon(
            onPressed: () => _replayArrival(context, details),
            icon: const Icon(Icons.replay),
            label: Text(l10n.islandArrivalAgain),
          ),
      ],
    );
  }

  void _replayArrival(BuildContext context, IslandDetails details) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(title: Text(details.title)),
          body: SafeArea(
            child: _Arrival(details: details, onDone: () => Navigator.of(routeContext).pop()),
          ),
        ),
      ),
    );
  }
}

class _StationTile extends StatelessWidget {
  const _StationTile({required this.station, required this.state, required this.onTap});

  final StationInfo station;
  final StationState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final locked = state == StationState.locked || state == StationState.noWind;
    final label = station.isExam ? l10n.stationExam : l10n.stationNumber(station.sortOrder);

    return Card(
      key: ValueKey('station-${station.sortOrder}'),
      color: locked ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
      child: ListTile(
        minTileHeight: 72,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: switch (state) {
            StationState.done => palette.success,
            StationState.open => palette.gold,
            StationState.locked => palette.placeholderBorder,
            StationState.noWind => palette.seaDeep,
          },
          foregroundColor: Colors.white,
          child: switch (state) {
            StationState.done => const Icon(Icons.check),
            StationState.locked => const Icon(Icons.lock_outline),
            StationState.noWind => const Icon(Icons.air),
            StationState.open => station.isExam ? const Icon(Icons.flag_outlined) : Text('${station.sortOrder}'),
          },
        ),
        title: Text(station.content.title),
        subtitle: Text(
          [
            label,
            if (station.content.place != null) station.content.place!,
            if (!station.isRequired) l10n.stationBonus,
            if (state == StationState.done) l10n.stationDone,
            if (state == StationState.noWind) l10n.stationNoWind,
          ].join(' · '),
        ),
        trailing: locked ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}
