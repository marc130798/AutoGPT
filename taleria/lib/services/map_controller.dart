import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../domain/content_models.dart';
import '../domain/family_models.dart';
import '../domain/progress_logic.dart';
import '../domain/progress_models.dart';

/// Inselkarte eines Kindes: welche Inseln es gibt und welche offen sind.
class MapController extends ChangeNotifier {
  MapController({required this._content, required this._progress, required this.child});

  final ContentRepository _content;
  final ProgressRepository _progress;
  final ChildProfile child;

  List<MapIsland> _islands = const [];
  Map<String, IslandState> _states = const {};

  /// Stopps auf See je Insel (auf der Route davor) und ihr Zustand.
  Map<String, List<StationInfo>> _stops = const {};
  Map<String, StationState> _stopStates = const {};
  ChildStats? _stats;
  EncounterOffer? _offer;
  bool _loading = true;
  FailureKind? _failure;

  List<MapIsland> get islands => _islands;

  /// Wind und fällige Wiederholungen; `null`, wenn sie nicht geladen werden konnten.
  ChildStats? get stats => _stats;

  /// Begegnung auf See, die gerade wartet (Wiederholungen sind fällig), sonst `null`.
  EncounterOffer? get encounter => _offer;

  /// Keine offene Insel mehr: die nächste liegt im Nebel oder gehört zum Abo.
  RouteBlock? get blockedAhead => _loading || _failure != null ? null : routeBlock(_islands, _states);

  /// Begegnung zum Üben, wenn Nebel voraus liegt (auch ohne fällige Wiederholungen).
  Future<EncounterOffer?> practiceEncounter() => _progress.nextEncounter(child.id, practice: true);
  bool get loading => _loading;
  FailureKind? get failure => _failure;

  IslandState stateOf(MapIsland island) => _states[island.id] ?? IslandState.locked;

  /// Die Insel, zu der das Schiff gehört. Liegen vor der nächsten Insel noch
  /// Stopps auf See, ist es die Insel davor (das Schiff selbst liegt dann am
  /// Stopp, siehe [shipBerthId]).
  String? get shipIslandId {
    final current = currentIslandId(_islands, _states);
    final island = _islands.where((i) => i.id == current).firstOrNull;
    if (island == null || !waitingAtSea(island)) return current;
    final route = [..._islands.where((i) => i.isMainRoute)]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = route.indexWhere((i) => i.id == island.id);
    return index > 0 ? route[index - 1].id : current;
  }

  /// Der Stopp auf See, an dem das Schiff gerade liegt: der erste noch nicht
  /// geschaffte vor der nächsten offenen Insel. `null`, wenn es an einer Insel liegt.
  StationInfo? get shipStop {
    final current = currentIslandId(_islands, _states);
    final island = _islands.where((i) => i.id == current).firstOrNull;
    if (island == null || !waitingAtSea(island)) return null;
    return stopsBefore(island).where((s) => stopState(s) != StationState.done).firstOrNull;
  }

  /// Wo das Schiff liegt: der Stopp auf See ([shipStop]) oder die Insel.
  String? get shipBerthId => shipStop?.id ?? shipIslandId;

  /// Reihenfolge der Liegeplätze auf der Fahrt: vor jeder Insel ihre Stopps,
  /// dann die Insel (Hafen zuerst).
  List<String> get berthOrder => [
    for (final island in [
      ..._islands.where((i) => i.isMainRoute),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))) ...[
      for (final stop in stopsBefore(island)) stop.id,
      island.id,
    ],
  ];

  /// Stopps auf See auf der Route vor [island], in Fahrtrichtung.
  List<StationInfo> stopsBefore(MapIsland island) => _stops[island.id] ?? const [];

  StationState stopState(StationInfo stop) => _stopStates[stop.id] ?? StationState.locked;

  /// Die Insel ist offen, aber auf dem Weg dorthin liegen noch Stopps auf See.
  bool waitingAtSea(MapIsland island) =>
      stateOf(island) == IslandState.open && stopsBefore(island).any((s) => stopState(s) != StationState.done);

  /// Die Insel, zu der ein Stopp auf See gehört.
  MapIsland islandOf(StationInfo stop) => _islands.firstWhere((i) => i.id == stop.islandId);

  Future<void> load() async {
    _loading = true;
    _failure = null;
    notifyListeners();
    try {
      _stats = await _progress.fetchStats(child.id);
      _offer = _stats!.reviewsDue > 0 ? await _progress.nextEncounter(child.id) : null;
    } on AppFailure {
      // Ohne Statistik geht die Karte trotzdem; nur Wind, Abo und Begegnung fehlen.
      _stats = null;
      _offer = null;
    }
    try {
      // Überall nach Stufe filtern, auch wenn heute nur Stufe 1 gebaut wird.
      final islands = await _content.fetchMap(child.stage);
      final progress = await _progress.fetchProgress(child.id);
      _islands = islands;
      // Ohne Statistik ist das Abo unbekannt: dann entscheidet der Server.
      _states = islandStates(islands, progress, premium: _stats?.premium ?? true);
      final stops = await _content.fetchSeaStops([
        for (final i in islands)
          if (i.hasContent) i.id,
      ]);
      _stops = {
        for (final island in islands)
          island.id: [...stops.where((s) => s.islandId == island.id)]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      };
      _stopStates = {for (final island in islands) ...seaStopStates(_stops[island.id]!, progress, stateOf(island))};
    } on AppFailure catch (e) {
      _failure = e.kind;
    }
    _loading = false;
    notifyListeners();
  }

  /// Insel gehört zum Abo, das gerade nicht aktiv ist (auch schon abgeschlossene).
  bool premiumBlocked(MapIsland island) => island.isPremium && !(_stats?.premium ?? true);
}
