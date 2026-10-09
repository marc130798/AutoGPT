import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../domain/family_models.dart';
import '../domain/progress_models.dart';

/// Seemeilen, Rang, Fahrtwind, Orden und Tempo eines Kindes. Für die
/// Startseite des Kindes und die Kinderseite im Leuchtturm.
class ChildStatsController extends ChangeNotifier {
  ChildStatsController({required this._progress, required this.childId});

  final ProgressRepository _progress;
  final String childId;

  ChildStats? _stats;
  bool _loading = true;
  FailureKind? _failure;

  ChildStats? get stats => _stats;
  bool get loading => _loading;
  FailureKind? get failure => _failure;

  Future<void> load() async {
    _loading = _stats == null;
    _failure = null;
    notifyListeners();
    try {
      _stats = await _progress.fetchStats(childId);
    } on AppFailure catch (e) {
      _failure = e.kind;
    }
    _loading = false;
    notifyListeners();
  }

  /// Eltern: 2, 3 oder 4 Stationen pro Woche, `null` = freie Fahrt.
  Future<void> setPace(int? stationsPerWeek) async {
    await _progress.setPace(childId, stationsPerWeek);
    await load();
  }

  /// Eltern: Fahrtwind (Serie) pausieren oder fortsetzen.
  Future<void> setStreakPause({required bool paused}) async {
    await _progress.setStreakPause(childId, paused: paused);
    await load();
  }
}
