import 'package:flutter/foundation.dart';

import '../data/budget_repository.dart';
import '../data/content_repository.dart';
import '../domain/content_models.dart';
import '../domain/family_models.dart';
import '../domain/progress_logic.dart';
import '../domain/weekly_report.dart';

/// Leuchtturm: Wochenbericht eines Kindes (die letzten 7 Tage). Nur lesen,
/// aus denselben Daten wie „Fortschritt und Lernstand“.
class WeeklyReportController extends ChangeNotifier {
  WeeklyReportController({
    required this._content,
    required this._progress,
    required this._budget,
    required this.child,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ContentRepository _content;
  final ProgressRepository _progress;
  final BudgetRepository? _budget;
  final ChildProfile child;
  final DateTime Function() _clock;

  WeeklyReport? _report;
  bool _loading = true;
  FailureKind? _failure;

  WeeklyReport? get report => _report;
  bool get loading => _loading;
  FailureKind? get failure => _failure;

  Future<void> load() async {
    _loading = _report == null;
    _failure = null;
    notifyListeners();
    try {
      final stats = await _progress.fetchStats(child.id);
      final map = await _content.fetchMap(child.stage);
      final progress = await _progress.fetchProgress(child.id);
      final states = islandStates(map, progress, premium: stats.premium);

      final stations = <String, StationInfo>{};
      MapIsland? current;
      for (final island in [...map]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))) {
        final state = states[island.id];
        if (state != IslandState.open && state != IslandState.completed) continue;
        if (state == IslandState.open) current ??= island;
        for (final s in await _content.fetchStations(island.id)) {
          stations[s.id] = s;
        }
      }
      final prompts = current == null ? const <ConversationPrompt>[] : await _content.fetchPrompts([current.id]);

      _report = buildWeeklyReport(
        now: _clock(),
        stationDoneAt: progress.stationCompletedAt,
        stations: stations,
        islandCompletedAt: progress.islandCompletedAt,
        islandTitles: {for (final i in map) i.id: i.title},
        badges: await _progress.fetchBadges(child.id),
        collection: await _progress.fetchCollection(child.id),
        tasks: await _budget?.fetchTasks(child.id) ?? const [],
        learning: await _progress.fetchLearningStatus(child.id),
        prompt: prompts.isEmpty ? null : prompts.first.text,
        stats: stats,
      );
    } on AppFailure catch (e) {
      _failure = e.kind;
    }
    _loading = false;
    notifyListeners();
  }
}
