import 'dart:io';
import 'dart:math';

import 'package:taleria/data/content_repository.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/domain/learning_status.dart';
import 'package:taleria/domain/progress_logic.dart';
import 'package:taleria/domain/progress_models.dart';

import '../tool/content/content_model.dart' as files;
import 'fakes.dart';

/// Inhalte aus den echten Inhaltsdateien (content/stufe1), so wie der Server
/// sie mit eingeschalteter Vorschau liefern würde.
class FakeContent implements ContentRepository {
  FakeContent() {
    final islands = files.loadIslands(Directory('content/stufe1'));
    for (final e in files.parseEncounters('begegnungen.json', File('content/begegnungen.json').readAsStringSync())) {
      encounters.add(
        Encounter.fromJson({
          'id': 'encounter-${e.slug}',
          'slug': e.slug,
          'type': e.type,
          'title': e.title,
          'asset_key': e.assetKey,
          'question_count': e.questionCount,
          'xp_reward': e.xp,
          'content': e.toDbContent(),
        }),
      );
    }
    for (final island in islands) {
      final id = 'island-${island.slug}';
      if (island.badge != null) {
        badges[id] = BadgeInfo(
          id: 'badge-${island.slug}',
          slug: island.slug,
          title: island.badge!,
          assetKey: 'badge.${island.slug}',
          sortOrder: island.order,
        );
      }
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
          access: island.access == 'gratis' ? 'free' : 'premium',
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
            sortOrder: s.number * 10,
            type: StationInfo.parseType(s.type),
            isRequired: true,
            xpReward: s.xp,
            content: StationContent.fromJson(s.toDbContent()),
          ),
        for (final (k, st) in island.seaStops.indexed)
          StationInfo(
            id: '$id/sea${k + 1}',
            islandId: id,
            sortOrder: k + 1,
            type: StationType.seaStop,
            isRequired: true,
            xpReward: st.xp,
            content: StationContent.fromJson(st.toDbContent(k + 1)),
          ),
        for (final (k, d) in island.dives.indexed)
          StationInfo(
            id: '$id/dive${k + 1}',
            islandId: id,
            sortOrder: d.after * 10 + 5,
            type: StationType.reviewStop,
            isRequired: true,
            xpReward: files.diveXp,
            content: StationContent.fromJson(d.toDbContent(k + 1)),
          ),
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final (i, text) in island.prompts.indexed) {
        prompts.add(ConversationPrompt(id: '$id/prompt${i + 1}', islandId: id, text: text));
      }
      for (final (k, d) in island.dives.indexed) {
        collectibles['$id/dive${k + 1}'] = CollectibleInfo(
          id: 'find-${island.slug}-${k + 1}',
          slug: '${island.slug}-fund-${k + 1}',
          kind: 'wreck_item',
          title: d.find,
          assetKey: d.findImage,
        );
      }
      for (final (k, st) in island.seaStops.indexed) {
        final stopId = '$id/sea${k + 1}';
        questions[stopId] = [
          for (final (i, q) in st.questions.indexed)
            QuizQuestion(
              id: '$stopId/q${i + 1}',
              stationId: stopId,
              question: q.question,
              answers: q.answers,
              correctIndex: 0,
              explanation: q.explanation,
            ),
        ];
      }
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

  /// Orden je Insel-ID.
  final Map<String, BadgeInfo> badges = {};

  /// Fund je Ankerplatz-ID.
  final Map<String, CollectibleInfo> collectibles = {};
  final List<ConversationPrompt> prompts = [];
  final List<Encounter> encounters = [];

  List<QuizQuestion> get allQuestions => questions.values.expand((q) => q).toList();

  /// Richtige Antwort zu einem Fragetext (für Tests, die richtig antworten).
  String rightAnswerFor(String questionText) =>
      questions.values.expand((q) => q).firstWhere((q) => q.question == questionText).answers.first;

  /// Eine falsche Antwort zu einem Fragetext.
  String wrongAnswerFor(String questionText) =>
      questions.values.expand((q) => q).firstWhere((q) => q.question == questionText).answers.last;

  MapIsland island(String slug) => mapIslands.firstWhere((i) => i.slug == slug);

  /// Station einer Insel nach angezeigter Nummer (ohne Ankerplätze und Stopps auf See).
  StationInfo station(String slug, int number) =>
      stations['island-$slug']!.firstWhere((s) => !s.isDive && !s.isSeaStop && s.displayNumber == number);

  /// Stopp auf See vor einer Insel (1 oder 2).
  StationInfo seaStop(String slug, int number) =>
      stations['island-$slug']!.firstWhere((s) => s.id.endsWith('/sea$number'));

  /// Ankerplatz einer Insel (1 bis 3).
  StationInfo dive(String slug, int number) =>
      stations['island-$slug']!.firstWhere((s) => s.id.endsWith('/dive$number'));

  @override
  Future<List<MapIsland>> fetchMap(int stage) async => mapIslands;

  @override
  Future<List<StationInfo>> fetchSeaStops(List<String> islandIds) async => [
    for (final id in islandIds) ...?stations[id]?.where((s) => s.isSeaStop),
  ];

  @override
  Future<IslandDetails> fetchIsland(String islandId) async => details[islandId]!;

  @override
  Future<List<StationInfo>> fetchStations(String islandId) async => stations[islandId] ?? const [];

  @override
  Future<List<QuizQuestion>> fetchQuestions(String stationId) async => questions[stationId] ?? const [];

  @override
  Future<List<ConversationPrompt>> fetchPrompts(List<String> islandIds) async => [
    for (final p in prompts)
      if (islandIds.contains(p.islandId)) p,
  ];

  @override
  Future<List<QuizQuestion>> fetchQuestionsByIds(List<String> ids) async {
    final all = {for (final q in allQuestions) q.id: q};
    return [for (final id in ids) ?all[id]];
  }

  @override
  Future<List<QuizQuestion>> fetchReviewPool({required int stage, required int beforeSortOrder}) async => [
    for (final island in mapIslands.where((i) => i.sortOrder < beforeSortOrder))
      for (final s in stations[island.id]!.where((s) => s.isExam)) ...questions[s.id]!,
  ];
}

/// Fortschritt wie submit_station(), child_stats() und submit_encounter() in
/// der Datenbank, vereinfacht. Standard ist freie Fahrt, damit Tests viele
/// Stationen am Stück spielen können.
class FakeProgress implements ProgressRepository {
  FakeProgress(this.content, {this.backend});

  final FakeContent content;
  final FakeBackend? backend;
  final Set<String> done = {};
  final Set<String> completedIslands = {};
  final Map<String, DateTime> badgeDates = {};
  final Map<String, DateTime> findDates = {};
  final Map<String, int> pearlsByDive = {};
  final Map<String, int> xp = {};

  /// Seemeilen aus dem Intro und anderen Quellen.
  int extraXp = 50;
  FailureKind? failWith;
  int submissions = 0;

  /// Tempo: `null` = freie Fahrt.
  int? stationsPerWeek;
  int wind = 2;
  DateTime? nextRelease;

  /// Fragen, die das Kind schon kennt, und welche davon fällig sind.
  final Set<String> seen = {};
  final Set<String> due = {};
  final List<List<({String questionId, int answerIndex})>> recordedAnswers = [];
  int encounterRuns = 0;
  bool reviewXpToday = false;
  int streakWeeks = 0;
  bool streakPaused = false;
  DateTime? lastActiveAt;

  /// Abo des Eltern-Kontos (Standard: an, damit Tests alle Inseln spielen können).
  bool premium = true;

  /// Lernstand pro Station (wie learning_status() in der Datenbank).
  final Map<String, TopicLearning> learning = {};

  int get totalXp => extraXp + xp.values.fold(0, (a, b) => a + b);

  static const _rankXp = {Rank.schiffsjunge: 1, Rank.matrose: 1500, Rank.bootsmann: 4000, Rank.steuermann: 8000};

  Rank? get rank {
    if (completedIslands.contains('island-schatzinsel')) return Rank.kapitaen;
    Rank? best;
    for (final e in _rankXp.entries) {
      if (totalXp >= e.value) best = e.key;
    }
    return best;
  }

  void _check() {
    if (failWith != null) throw AppFailure(failWith!);
  }

  @override
  Future<ChildProgress> fetchProgress(String childId) async {
    _check();
    return ChildProgress(
      doneStationIds: {...done},
      completedIslandIds: {...completedIslands},
      islandCompletedAt: {for (final id in completedIslands) id: badgeDates[id] ?? DateTime(2026, 10, 9)},
    );
  }

  @override
  Future<StationResult> submitStation({
    required String childId,
    required String stationId,
    required List<({String questionId, int answerIndex})> answers,
  }) async {
    _check();
    submissions++;
    final islandId = stationId.split('/').first;
    final stations = content.stations[islandId]!;
    final station = stations.firstWhere((s) => s.id == stationId);
    final state = stationStates(stations, ChildProgress(doneStationIds: done), onboardingCompleted: true)[stationId];
    if (state == StationState.locked) throw const AppFailure(FailureKind.notAllowed, 'gesperrt');
    final first = !done.contains(stationId);
    // Ankerplätze und Stopps auf See brauchen keinen Wind (wie submit_station()).
    final noWind = station.isDive || station.isSeaStop;
    if (first && station.isRequired && !noWind && stationsPerWeek != null && wind <= 0) {
      throw const AppFailure(FailureKind.noWind, 'Das Schiff braucht Wind');
    }

    final all = content.allQuestions;
    final correct = answers
        .where((a) => all.firstWhere((q) => q.id == a.questionId).correctIndex == a.answerIndex)
        .length;
    seen.addAll(answers.map((a) => a.questionId));
    final rankBefore = rank;
    final passed = !station.isExam || correct >= station.content.exam!.pass;
    var xpAwarded = 0;
    var islandCompleted = false;
    CollectibleInfo? find;
    if (station.isDive) {
      pearlsByDive[stationId] = max(pearlsByDive[stationId] ?? 0, correct);
      final collectible = content.collectibles[stationId];
      if (collectible != null && !findDates.containsKey(stationId)) {
        findDates[stationId] = DateTime(2026, 10, 10);
        find = collectible;
      }
    }
    if (passed) {
      if (first && !noWind && stationsPerWeek != null) wind--;
      done.add(stationId);
      if (!xp.containsKey(stationId)) {
        xp[stationId] = station.xpReward;
        xpAwarded = station.xpReward;
      }
      final allDone = stations.every((s) => s.content.isOnboarding || done.contains(s.id));
      if (allDone && completedIslands.add(islandId)) {
        islandCompleted = true;
        badgeDates[islandId] = DateTime(2026, 10, 9);
      }
    }
    if (streakWeeks == 0) streakWeeks = 1;
    final rankAfter = rank;
    return StationResult(
      correct: correct,
      total: answers.length,
      passed: passed,
      xpAwarded: xpAwarded,
      islandCompleted: islandCompleted,
      rankUp: rankAfter != rankBefore ? rankAfter : null,
      badge: islandCompleted ? content.badges[islandId] : null,
      windLeft: stationsPerWeek == null || noWind ? null : wind,
      find: find,
    );
  }

  @override
  Future<List<RankStep>> fetchRanks() async {
    _check();
    return [
      for (final rank in Rank.values) (rank: rank, minXp: _rankXp[rank] ?? 0, needsCertificate: rank == Rank.kapitaen),
    ];
  }

  @override
  Future<ChildStats> fetchStats(String childId) async {
    _check();
    final current = rank;
    final next = current == null
        ? Rank.schiffsjunge
        : (current.index + 1 < Rank.values.length ? Rank.values[current.index + 1] : null);
    return ChildStats(
      xp: totalXp,
      rank: current,
      rankMinXp: current == null ? null : (_rankXp[current] ?? 0),
      nextRank: next,
      nextRankXp: next == null ? null : _rankXp[next],
      nextRankNeedsCertificate: next == Rank.kapitaen,
      streakWeeks: streakWeeks,
      streakPaused: streakPaused,
      badgeCount: badgeDates.length,
      reviewsDue: due.length,
      pearls: pearlsByDive.values.fold(0, (a, b) => a + b),
      lastActiveAt: lastActiveAt,
      premium: premium,
      finds: findDates.length,
      pace: stationsPerWeek == null
          ? PaceStatus.freeSailing
          : PaceStatus(
              free: false,
              stationsPerWeek: stationsPerWeek,
              wind: wind,
              nextRelease: wind == 0 ? nextRelease : null,
            ),
    );
  }

  @override
  Future<List<BadgeInfo>> fetchBadges(String childId) async {
    _check();
    return [
      for (final e in content.badges.entries)
        if (badgeDates[e.key] case final date?) e.value.earnedOn(date) else e.value,
    ];
  }

  @override
  Future<void> recordAnswers({
    required String childId,
    required List<({String questionId, int answerIndex})> answers,
  }) async {
    _check();
    recordedAnswers.add(answers);
    seen.addAll(answers.map((a) => a.questionId));
  }

  @override
  Future<List<TopicLearning>> fetchLearningStatus(String childId) async {
    _check();
    return learning.values.toList();
  }

  @override
  Future<List<CollectibleInfo>> fetchCollection(String childId) async {
    _check();
    return [
      for (final e in content.collectibles.entries)
        if (findDates[e.key] case final date?) e.value.foundOn(date) else e.value,
    ];
  }

  @override
  Future<EncounterOffer?> nextEncounter(String childId, {bool practice = false}) async {
    _check();
    if ((due.isEmpty && !practice) || content.encounters.isEmpty) return null;
    final encounter = content.encounters.first;
    final ids = [...due, ...seen.where((id) => !due.contains(id))].take(encounter.questionCount).toList();
    if (ids.length < encounter.questionCount) return null;
    return EncounterOffer(
      encounter: encounter,
      questionIds: ids,
      firstMeeting: encounterRuns == 0,
      dueCount: due.length,
    );
  }

  @override
  Future<EncounterResult> submitEncounter({
    required String childId,
    required String encounterId,
    required List<({String questionId, int answerIndex})> answers,
  }) async {
    _check();
    final encounter = content.encounters.firstWhere((e) => e.id == encounterId);
    final all = content.allQuestions;
    final correct = answers
        .where((a) => all.firstWhere((q) => q.id == a.questionId).correctIndex == a.answerIndex)
        .length;
    final rankBefore = rank;
    var xpAwarded = 0;
    if (!reviewXpToday) {
      reviewXpToday = true;
      xpAwarded = encounter.xpReward;
      extraXp += xpAwarded;
    }
    encounterRuns++;
    due.removeAll(answers.map((a) => a.questionId));
    if (streakWeeks == 0) streakWeeks = 1;
    final rankAfter = rank;
    return EncounterResult(
      correct: correct,
      total: answers.length,
      xpAwarded: xpAwarded,
      rankUp: rankAfter != rankBefore ? rankAfter : null,
      streakWeeks: streakWeeks,
    );
  }

  @override
  Future<void> setPace(String childId, int? stationsPerWeek) async {
    _check();
    if (stationsPerWeek != null && ![2, 3, 4].contains(stationsPerWeek)) throw const AppFailure(FailureKind.unknown);
    if (this.stationsPerWeek == null && stationsPerWeek != null) wind = stationsPerWeek;
    this.stationsPerWeek = stationsPerWeek;
  }

  @override
  Future<void> setStreakPause(String childId, {required bool paused}) async {
    _check();
    streakPaused = paused;
  }

  /// Gemeldete Ereignisse der Messung (ohne Prüfung auf „einmal am Tag“).
  final List<({String childId, TrackedEvent event, String? stationId})> events = [];

  @override
  Future<void> trackEvent(String childId, TrackedEvent event, {String? stationId}) async {
    _check();
    events.add((childId: childId, event: event, stationId: stationId));
  }

  /// Markiert alle Stationen einer Insel bis auf die letzten [except] als erledigt.
  void completeStations(String slug, {int except = 0}) {
    final stations = content.stations['island-$slug']!.where((s) => !s.content.isOnboarding).toList();
    for (final s in stations.take(stations.length - except)) {
      done.add(s.id);
    }
  }

  /// Macht Fragen einer Station bekannt und fällig (Wiederholung steht an).
  void makeDue(String slug, int station, {int count = 3}) {
    final ids = content.questions['island-$slug/station$station']!.take(count).map((q) => q.id);
    seen.addAll(ids);
    due.addAll(ids);
  }
}
