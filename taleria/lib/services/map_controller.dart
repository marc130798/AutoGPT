import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../domain/content_models.dart';
import '../domain/family_models.dart';
import '../domain/progress_logic.dart';

/// Inselkarte eines Kindes: welche Inseln es gibt und welche offen sind.
class MapController extends ChangeNotifier {
  MapController({required this._content, required this._progress, required this.child});

  final ContentRepository _content;
  final ProgressRepository _progress;
  final ChildProfile child;

  List<MapIsland> _islands = const [];
  Map<String, IslandState> _states = const {};
  bool _loading = true;
  FailureKind? _failure;

  List<MapIsland> get islands => _islands;
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
    _loading = false;
    notifyListeners();
  }
}
