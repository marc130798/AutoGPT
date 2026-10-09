import 'dart:io';

import 'package:taleria/data/content_repository.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/domain/progress_logic.dart';

import '../tool/content/content_model.dart' as files;
import 'fakes.dart';

/// Inhalte aus den echten Inhaltsdateien (content/stufe1), so wie der Server
/// sie mit eingeschalteter Vorschau liefern würde.
class FakeContent implements ContentRepository {
  FakeContent() {
    final islands = files.loadIslands(Directory('content/stufe1'));
    for (final island in islands) {
      final id = 'island-${island.slug}';
      mapIslands.add(
        MapIsland(
          id: id,
          slug: island.slug,
          title: island.title,
          group: island.group,
          sortOrder: island.order,
          mapX: island.mapX,
          mapY: island.mapY,
          hasContent: island.stations.isNotEmpty,
        ),
      );
      details[id] = IslandDetails.fromRow({
        'id': id,
        'slug': island.slug,
        'title': island.title,
        'content': island.toDbContent(),
      });
      stations[id] = [
        for (final s in island.stations)
          StationInfo(
            id: '$id/station${s.number}',
            islandId: id,
            sortOrder: s.number,
            type: StationInfo.parseType(s.type),
            isRequired: true,
            xpReward: s.xp,
            content: StationContent.fromJson(s.toDbContent()),
          ),
      ];
      for (final s in island.stations) {
        final stationId = '$id/station${s.number}';
        questions[stationId] = [
          for (final (i, q) in s.questions.indexed)
            QuizQuestion(
              id: '$stationId/q${i + 1}',
              stationId: stationId,
              question: q.question,
              answers: q.answers,
              correctIndex: 0,
              explanation: q.explanation,
              coversStation: q.station,
            ),
        ];
      }
    }
  }

  final List<MapIsland> mapIslands = [];
  final Map<String, IslandDetails> details = {};
  final Map<String, List<StationInfo>> stations = {};
  final Map<String, List<QuizQuestion>> questions = {};

  /// Richtige Antwort zu einem Fragetext (für Tests, die richtig antworten).
  String rightAnswerFor(String questionText) =>
      questions.values.expand((q) => q).firstWhere((q) => q.question == questionText).answers.first;

  MapIsland island(String slug) => mapIslands.firstWhere((i) => i.slug == slug);

  @override
  Future<List<MapIsland>> fetchMap(int stage) async => mapIslands;

  @override
  Future<IslandDetails> fetchIsland(String islandId) async => details[islandId]!;

  @override
  Future<List<StationInfo>> fetchStations(String islandId) async => stations[islandId] ?? const [];

  @override
  Future<List<QuizQuestion>> fetchQuestions(String stationId) async => questions[stationId] ?? const [];

  @override
  Future<List<QuizQuestion>> fetchReviewPool({required int stage, required int beforeSortOrder}) async => [
    for (final island in mapIslands.where((i) => i.sortOrder < beforeSortOrder))
      for (final s in stations[island.id]!.where((s) => s.isExam)) ...questions[s.id]!,
  ];
}

/// Fortschritt wie submit_station() in der Datenbank, vereinfacht.
class FakeProgress implements ProgressRepository {
  FakeProgress(this.content, {this.backend});

  final FakeContent content;
  final FakeBackend? backend;
  final Set<String> done = {};
  final Set<String> completedIslands = {};
  final Map<String, int> xp = {};
  FailureKind? failWith;
  int submissions = 0;

  @override
  Future<ChildProgress> fetchProgress(String childId) async {
    if (failWith != null) throw AppFailure(failWith!);
    return ChildProgress(doneStationIds: {...done}, completedIslandIds: {...completedIslands});
  }

  @override
  Future<StationResult> submitStation({
    required String childId,
    required String stationId,
    required List<({String questionId, int answerIndex})> answers,
  }) async {
    if (failWith != null) throw AppFailure(failWith!);
    submissions++;
    final islandId = stationId.split('/').first;
    final stations = content.stations[islandId]!;
    final station = stations.firstWhere((s) => s.id == stationId);
    final state = stationStates(stations, ChildProgress(doneStationIds: done), onboardingCompleted: true)[stationId];
    if (state == StationState.locked) throw const AppFailure(FailureKind.notAllowed, 'gesperrt');

    final all = content.questions.values.expand((q) => q).toList();
    final correct = answers
        .where((a) => all.firstWhere((q) => q.id == a.questionId).correctIndex == a.answerIndex)
        .length;
    final passed = !station.isExam || correct >= station.content.exam!.pass;
    var xpAwarded = 0;
    var islandCompleted = false;
    if (passed) {
      done.add(stationId);
      if (!xp.containsKey(stationId)) {
        xp[stationId] = station.xpReward;
        xpAwarded = station.xpReward;
      }
      final allDone = stations.every((s) => s.content.isOnboarding || done.contains(s.id));
      if (allDone && completedIslands.add(islandId)) islandCompleted = true;
    }
    return StationResult(
      correct: correct,
      total: answers.length,
      passed: passed,
      xpAwarded: xpAwarded,
      islandCompleted: islandCompleted,
    );
  }

  /// Markiert alle Stationen einer Insel bis auf die letzten [except] als erledigt.
  void completeStations(String slug, {int except = 0}) {
    final stations = content.stations['island-$slug']!.where((s) => !s.content.isOnboarding).toList();
    for (final s in stations.take(stations.length - except)) {
      done.add(s.id);
    }
  }
}
