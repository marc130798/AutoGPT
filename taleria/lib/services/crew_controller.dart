import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../domain/content_models.dart';
import '../domain/family_models.dart';
import '../domain/progress_logic.dart';
import '../domain/progress_models.dart';
import '../domain/shipyard.dart';

/// Eine Aufgabe für Kind und Eltern zusammen („Gemeinsam“).
class CrewTask {
  const CrewTask({
    required this.island,
    required this.kind,
    required this.title,
    this.text,
    this.points = const [],
    this.ask,
    this.done,
  });

  final MapIsland island;
  final CrewKind kind;

  /// Crew-Abenteuer: Titel des Auftrags fürs echte Leben. Erklären: Name der Insel.
  final String title;
  final String? text;

  /// Erklären: die 3 Punkte, die das Kind erklärt.
  final List<String> points;

  /// Erklären: die Nachfrage für die Eltern.
  final String? ask;

  /// Geschafft (ein Crew-Stern), sonst `null`.
  final CrewDone? done;

  String get id => '${island.id}/${kind.name}';
}

/// Lädt die Crew-Aufgaben: Crew-Abenteuer jeder erreichten Insel und
/// „Erklär's deinen Eltern“ jeder geschafften Insel. Für Kind und Leuchtturm.
class CrewController extends ChangeNotifier {
  CrewController({required this._content, required this._progress, required this.child});

  final ContentRepository _content;
  final ProgressRepository _progress;
  final ChildProfile child;

  List<CrewTask> _tasks = const [];
  bool _loading = true;
  FailureKind? _failure;

  List<CrewTask> get tasks => _tasks;
  bool get loading => _loading;
  FailureKind? get failure => _failure;

  /// Crew-Sterne = geschaffte Crew-Aufgaben.
  int get stars => _tasks.where((t) => t.done != null).length;

  /// Offene Aufgaben zuerst (die aktuelle Insel oben), Geschafftes unten.
  List<CrewTask> get open => [
    for (final t in _tasks)
      if (t.done == null) t,
  ];
  List<CrewTask> get finished => [
    for (final t in _tasks)
      if (t.done != null) t,
  ];

  /// Das nächste Crew-Teil der Werft und wie viele Sterne noch fehlen, sonst `null`.
  (LookItem, int)? get nextReward {
    for (final item in shipyardItems) {
      final need = item.crewStars;
      if (need != null && need > stars) return (item, need - stars);
    }
    return null;
  }

  Future<void> load() async {
    _loading = _tasks.isEmpty;
    _failure = null;
    notifyListeners();
    try {
      final stats = await _progress.fetchStats(child.id);
      final map = await _content.fetchMap(child.stage);
      final progress = await _progress.fetchProgress(child.id);
      final done = await _progress.fetchCrewDone(child.id);
      final states = islandStates(map, progress, premium: stats.premium, preview: child.previewAll);
      final sorted = [...map]..sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
      CrewDone? doneFor(String islandId, CrewKind kind) {
        for (final d in done) {
          if (d.islandId == islandId && d.kind == kind) return d;
        }
        return null;
      }

      final tasks = <CrewTask>[];
      for (final island in sorted) {
        final state = states[island.id];
        if (!island.hasContent || (state != IslandState.open && state != IslandState.completed)) continue;
        final details = await _content.fetchIsland(island.id);
        if (details.realLifeTask case final task?) {
          tasks.add(
            CrewTask(
              island: island,
              kind: CrewKind.adventure,
              title: task.title,
              text: task.text,
              done: doneFor(island.id, CrewKind.adventure),
            ),
          );
        }
        if (state == IslandState.completed && details.explain.isNotEmpty) {
          tasks.add(
            CrewTask(
              island: island,
              kind: CrewKind.explain,
              title: island.title,
              points: details.explain,
              ask: details.explainAsk,
              done: doneFor(island.id, CrewKind.explain),
            ),
          );
        }
      }
      _tasks = tasks;
    } on AppFailure catch (e) {
      _failure = e.kind;
    }
    _loading = false;
    notifyListeners();
  }

  /// Kind gibt den Code der Eltern ein. Bei Erfolg lädt die Liste neu.
  Future<CrewRedeemResult> redeem(CrewTask task, String code) async {
    final result = await _progress.redeemCrewCode(
      childId: child.id,
      islandId: task.island.id,
      kind: task.kind,
      code: code,
    );
    if (result.status == CrewRedeemStatus.ok || result.status == CrewRedeemStatus.done) await load();
    return result;
  }

  /// Eltern: Code für eine Aufgabe abrufen.
  Future<String> code(CrewTask task) =>
      _progress.crewCode(childId: child.id, islandId: task.island.id, kind: task.kind);
}
