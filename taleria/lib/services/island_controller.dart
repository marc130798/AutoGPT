import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../data/local_settings.dart';
import '../domain/content_models.dart';
import '../domain/family_models.dart';
import '../domain/progress_logic.dart';

/// Eine offene Insel: Stationen in der richtigen Reihenfolge und ihr Zustand.
class IslandController extends ChangeNotifier {
  IslandController({
    required this._content,
    required this._progress,
    required this._settings,
    required this.child,
    required this.island,
  });

  final ContentRepository _content;
  final ProgressRepository _progress;
  final LocalSettings _settings;
  final ChildProfile child;
  final MapIsland island;

  IslandDetails? _details;
  List<StationInfo> _stations = const [];
  Map<String, StationState> _states = const {};
  bool _loading = true;
  bool _arrivalPending = false;
  FailureKind? _failure;

  IslandDetails? get details => _details;
  List<StationInfo> get stations => _stations;
  bool get loading => _loading;
  FailureKind? get failure => _failure;

  /// Die Ankunft (Film und Szene) wurde auf diesem Gerät noch nicht gezeigt.
  bool get arrivalPending => _arrivalPending;

  StationState stateOf(StationInfo station) => _states[station.id] ?? StationState.locked;

  Future<void> load() async {
    _loading = _details == null;
    _failure = null;
    notifyListeners();
    try {
      final details = await _content.fetchIsland(island.id);
      final stations = await _content.fetchStations(island.id);
      final progress = await _progress.fetchProgress(child.id);
      _details = details;
      _stations = stations;
      _states = stationStates(stations, progress, onboardingCompleted: child.onboardingCompleted);
      _arrivalPending = details.hasArrival && !await _settings.arrivalSeen(child.id, island.id);
    } on AppFailure catch (e) {
      _failure = e.kind;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> arrivalShown() async {
    _arrivalPending = false;
    notifyListeners();
    await _settings.setArrivalSeen(child.id, island.id);
  }
}
