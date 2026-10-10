import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../domain/content_models.dart';
import '../domain/family_models.dart';
import '../domain/learning_status.dart';
import '../domain/progress_logic.dart';
import '../domain/progress_models.dart';

/// Ein Thema (eine Station) mit Lernstand.
class TopicReport {
  const TopicReport({required this.station, this.learning});

  final StationInfo station;
  final TopicLearning? learning;

  TopicStatus get status => learning?.status ?? TopicStatus.notStarted;
}

/// Eine Insel im Leuchtturm: Zustand, erledigte Stationen und Themen.
class IslandReport {
  const IslandReport({
    required this.island,
    required this.state,
    this.completedAt,
    this.details,
    this.requiredDone = 0,
    this.requiredTotal = 0,
    this.topics = const [],
  });

  final MapIsland island;
  final IslandState state;
  final DateTime? completedAt;
  final IslandDetails? details;
  final int requiredDone;
  final int requiredTotal;
  final List<TopicReport> topics;

  /// Das Kind war schon auf der Insel oder darf hin.
  bool get reached => state == IslandState.open || state == IslandState.completed;
}

/// Leuchtturm: Fortschritt pro Insel, Lernstand pro Thema und Kombüsen-Fragen
/// eines Kindes. Nur lesen; gerechnet wird mit denselben Regeln wie im Kinderbereich.
class ChildReportController extends ChangeNotifier {
  ChildReportController({required this._content, required this._progress, required this.child});

  final ContentRepository _content;
  final ProgressRepository _progress;
  final ChildProfile child;

  ChildStats? _stats;
  List<IslandReport> _islands = const [];
  List<ConversationPrompt> _prompts = const [];
  bool _loading = true;
  FailureKind? _failure;

  ChildStats? get stats => _stats;
  List<IslandReport> get islands => _islands;
  bool get loading => _loading;
  FailureKind? get failure => _failure;

  /// Inseln, die das Kind erreicht hat: die aktuelle zuerst, dann die fertigen.
  List<IslandReport> get reachedIslands {
    final reached = _islands.where((i) => i.reached).toList()
      ..sort((a, b) {
        if (a.state != b.state) return a.state == IslandState.open ? -1 : 1;
        return b.island.sortOrder.compareTo(a.island.sortOrder);
      });
    return reached;
  }

  List<ConversationPrompt> promptsFor(String islandId) => [
    for (final p in _prompts)
      if (p.islandId == islandId) p,
  ];

  Future<void> load() async {
    _loading = _stats == null;
    _failure = null;
    notifyListeners();
    try {
      final stats = await _progress.fetchStats(child.id);
      final map = await _content.fetchMap(child.stage);
      final progress = await _progress.fetchProgress(child.id);
      final learning = {for (final t in await _progress.fetchLearningStatus(child.id)) t.stationId: t};
      final states = islandStates(map, progress);
      final sorted = [...map]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final reports = <IslandReport>[];
      for (final island in sorted) {
        final state = states[island.id] ?? IslandState.locked;
        if (state != IslandState.open && state != IslandState.completed) {
          reports.add(IslandReport(island: island, state: state));
          continue;
        }
        final details = await _content.fetchIsland(island.id);
        final stations = await _content.fetchStations(island.id);
        final required = stations.where((s) => s.isRequired).toList();
        reports.add(
          IslandReport(
            island: island,
            state: state,
            completedAt: progress.islandCompletedAt[island.id],
            details: details,
            requiredTotal: required.length,
            requiredDone: required
                .where((s) => isStationDone(s, progress, onboardingCompleted: child.onboardingCompleted))
                .length,
            topics: [
              for (final s in stations)
                if (!s.isExam && !s.isDive && !s.content.isOnboarding)
                  TopicReport(station: s, learning: learning[s.id]),
            ],
          ),
        );
      }
      _stats = stats;
      _islands = reports;
      _prompts = await _content.fetchPrompts([
        for (final r in reports)
          if (r.reached) r.island.id,
      ]);
    } on AppFailure catch (e) {
      _failure = e.kind;
    }
    _loading = false;
    notifyListeners();
  }
}
