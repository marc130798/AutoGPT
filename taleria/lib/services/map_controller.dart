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
  ChildStats? _stats;
  EncounterOffer? _offer;
  bool _loading = true;
  FailureKind? _failure;

  List<MapIsland> get islands => _islands;

  /// Wind und fällige Wiederholungen; `null`, wenn sie nicht geladen werden konnten.
  ChildStats? get stats => _stats;

  /// Begegnung auf See, die gerade wartet (Wiederholungen sind fällig), sonst `null`.
  EncounterOffer? get encounter => _offer;
  bool get loading => _loading;
  FailureKind? get failure => _failure;

  IslandState stateOf(MapIsland island) => _states[island.id] ?? IslandState.locked;

  /// Wo das Schiff gerade liegt.
  String? get shipIslandId => currentIslandId(_islands, _states);

  Future<void> load() async {
    _loading = true;
    _failure = null;
    notifyListeners();
    try {
      // Überall nach Stufe filtern, auch wenn heute nur Stufe 1 gebaut wird.
      final islands = await _content.fetchMap(child.stage);
      final progress = await _progress.fetchProgress(child.id);
      _islands = islands;
      _states = islandStates(islands, progress);
    } on AppFailure catch (e) {
      _failure = e.kind;
    }
    try {
      _stats = await _progress.fetchStats(child.id);
      _offer = _stats!.reviewsDue > 0 ? await _progress.nextEncounter(child.id) : null;
    } on AppFailure {
      // Ohne Statistik geht die Karte trotzdem; nur Wind und Begegnung fehlen.
      _stats = null;
      _offer = null;
    }
    _loading = false;
    notifyListeners();
  }
}
