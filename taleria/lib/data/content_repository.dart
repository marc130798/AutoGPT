import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/content_models.dart';
import '../domain/progress_models.dart';
import 'backend_errors.dart';

/// Inseln, Stationen und Fragen aus der Datenbank. Was ein Kind sehen darf,
/// entscheidet die Datenbank (Row Level Security, Nebel, Vorschau).
abstract interface class ContentRepository {
  Future<List<MapIsland>> fetchMap(int stage);

  Future<IslandDetails> fetchIsland(String islandId);

  Future<List<StationInfo>> fetchStations(String islandId);

  Future<List<QuizQuestion>> fetchQuestions(String stationId);

  /// Prüfungsfragen früherer Inseln derselben Stufe (Rückblick).
  Future<List<QuizQuestion>> fetchReviewPool({required int stage, required int beforeSortOrder});

  /// Bestimmte Fragen (für Begegnungen auf See), in der Reihenfolge von [ids].
  Future<List<QuizQuestion>> fetchQuestionsByIds(List<String> ids);
}

/// Fortschritt eines Kindes: Stationen abgeben, Seemeilen, Rang, Orden,
/// Wind, Wiederholungen und Begegnungen. Berechnet wird auf dem Server.
abstract interface class ProgressRepository {
  Future<ChildProgress> fetchProgress(String childId);

  Future<ChildStats> fetchStats(String childId);

  /// Alle sichtbaren Orden, verdiente mit Datum.
  Future<List<BadgeInfo>> fetchBadges(String childId);

  /// „Weißt du noch?“: Antworten nur für den Wiederholungsplan.
  Future<void> recordAnswers({required String childId, required List<({String questionId, int answerIndex})> answers});

  /// Begegnung, wenn Wiederholungen fällig sind, sonst `null`.
  Future<EncounterOffer?> nextEncounter(String childId);

  /// [answers]: die erste Antwort je Frage.
  Future<EncounterResult> submitEncounter({
    required String childId,
    required String encounterId,
    required List<({String questionId, int answerIndex})> answers,
  });

  /// Eltern: 2, 3 oder 4 Stationen pro Woche, `null` = freie Fahrt.
  Future<void> setPace(String childId, int? stationsPerWeek);

  /// Eltern: Fahrtwind pausieren oder fortsetzen.
  Future<void> setStreakPause(String childId, {required bool paused});

  /// [answers]: Frage und gewählte Antwort als Stelle in der gespeicherten
  /// Antwortliste (vor dem Mischen). Der Server zählt selbst nach.
  Future<StationResult> submitStation({
    required String childId,
    required String stationId,
    required List<({String questionId, int answerIndex})> answers,
  });
}

class SupabaseContentRepository implements ContentRepository {
  SupabaseContentRepository(this._client);

  final sb.SupabaseClient _client;

  static const _questionColumns = 'id, station_id, question, answers, correct_index, explanation, covers_station';

  @override
  Future<List<MapIsland>> fetchMap(int stage) => guardBackend(() async {
    final rows = await _client.rpc<List<dynamic>>('map_islands', params: {'p_stage': stage});
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        MapIsland(
          id: r['id'] as String,
          slug: r['slug'] as String,
          title: r['title'] as String,
          group: r['island_group'] as int?,
          sortOrder: r['sort_order'] as int,
          mapX: (r['map_x'] as num?)?.toDouble() ?? 0.5,
          mapY: (r['map_y'] as num?)?.toDouble() ?? 0.5,
          routeType: r['route_type'] as String? ?? 'main',
          hasContent: r['has_content'] as bool? ?? false,
        ),
    ];
  });

  @override
  Future<IslandDetails> fetchIsland(String islandId) => guardBackend(() async {
    final row = await _client.from('islands').select('id, slug, title, content').eq('id', islandId).single();
    return IslandDetails.fromRow(row);
  });

  @override
  Future<List<StationInfo>> fetchStations(String islandId) => guardBackend(() async {
    final rows = await _client
        .from('stations')
        .select('id, island_id, sort_order, type, is_required, xp_reward, content')
        .eq('island_id', islandId)
        .order('sort_order');
    return [
      for (final r in rows)
        StationInfo(
          id: r['id'] as String,
          islandId: r['island_id'] as String,
          sortOrder: r['sort_order'] as int,
          type: StationInfo.parseType(r['type'] as String?),
          isRequired: r['is_required'] as bool,
          xpReward: r['xp_reward'] as int,
          content: StationContent.fromJson((r['content'] as Map<String, dynamic>?) ?? const {}),
        ),
    ];
  });

  @override
  Future<List<QuizQuestion>> fetchQuestions(String stationId) => guardBackend(() async {
    final rows = await _client.from('quiz_questions').select(_questionColumns).eq('station_id', stationId);
    return rows.map(_question).toList();
  });

  @override
  Future<List<QuizQuestion>> fetchReviewPool({required int stage, required int beforeSortOrder}) =>
      guardBackend(() async {
        final rows = await _client
            .from('quiz_questions')
            .select('$_questionColumns, stations!inner(type, islands!inner(stage, sort_order))')
            .eq('stations.type', 'exam')
            .eq('stations.islands.stage', stage)
            .lt('stations.islands.sort_order', beforeSortOrder);
        return rows.map(_question).toList();
      });

  @override
  Future<List<QuizQuestion>> fetchQuestionsByIds(List<String> ids) => guardBackend(() async {
    if (ids.isEmpty) return const <QuizQuestion>[];
    final rows = await _client.from('quiz_questions').select(_questionColumns).inFilter('id', ids);
    final byId = {for (final r in rows) r['id'] as String: _question(r)};
    return [for (final id in ids) ?byId[id]];
  });

  static QuizQuestion _question(Map<String, dynamic> r) => QuizQuestion(
    id: r['id'] as String,
    stationId: r['station_id'] as String,
    question: r['question'] as String,
    answers: [for (final a in r['answers'] as List) a as String],
    correctIndex: r['correct_index'] as int,
    explanation: r['explanation'] as String?,
    coversStation: r['covers_station'] as int?,
  );
}

class SupabaseProgressRepository implements ProgressRepository {
  SupabaseProgressRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<ChildProgress> fetchProgress(String childId) => guardBackend(() async {
    final done = await _client
        .from('station_progress')
        .select('station_id')
        .eq('child_id', childId)
        .eq('status', 'done');
    final islands = await _client.from('island_completions').select('island_id').eq('child_id', childId);
    return ChildProgress(
      doneStationIds: {for (final r in done) r['station_id'] as String},
      completedIslandIds: {for (final r in islands) r['island_id'] as String},
    );
  });

  @override
  Future<StationResult> submitStation({
    required String childId,
    required String stationId,
    required List<({String questionId, int answerIndex})> answers,
  }) => guardBackend(() async {
    final result = await _client.rpc<Map<String, dynamic>>(
      'submit_station',
      params: {'p_child_id': childId, 'p_station_id': stationId, 'p_answers': _answers(answers)},
    );
    return StationResult.fromJson(result);
  });

  static List<Map<String, Object>> _answers(List<({String questionId, int answerIndex})> answers) => [
    for (final a in answers) {'question_id': a.questionId, 'answer_index': a.answerIndex},
  ];

  @override
  Future<ChildStats> fetchStats(String childId) => guardBackend(() async {
    final result = await _client.rpc<Map<String, dynamic>>('child_stats', params: {'p_child_id': childId});
    return ChildStats.fromJson(result);
  });

  @override
  Future<List<BadgeInfo>> fetchBadges(String childId) => guardBackend(() async {
    final badges = await _client.from('badges').select('id, slug, title, asset_key, sort_order').order('sort_order');
    final earned = await _client.from('child_badges').select('badge_id, earned_at').eq('child_id', childId);
    final earnedAt = {for (final r in earned) r['badge_id'] as String: DateTime.parse(r['earned_at'] as String)};
    return [
      for (final r in badges)
        if (earnedAt[r['id']] case final date?) BadgeInfo.fromJson(r).earnedOn(date) else BadgeInfo.fromJson(r),
    ];
  });

  @override
  Future<void> recordAnswers({
    required String childId,
    required List<({String questionId, int answerIndex})> answers,
  }) => guardBackend(
    () => _client.rpc<void>('record_answers', params: {'p_child_id': childId, 'p_answers': _answers(answers)}),
  );

  @override
  Future<EncounterOffer?> nextEncounter(String childId) => guardBackend(() async {
    final result = await _client.rpc<Map<String, dynamic>?>('next_encounter', params: {'p_child_id': childId});
    return result == null ? null : EncounterOffer.fromJson(result);
  });

  @override
  Future<EncounterResult> submitEncounter({
    required String childId,
    required String encounterId,
    required List<({String questionId, int answerIndex})> answers,
  }) => guardBackend(() async {
    final result = await _client.rpc<Map<String, dynamic>>(
      'submit_encounter',
      params: {'p_child_id': childId, 'p_encounter_id': encounterId, 'p_answers': _answers(answers)},
    );
    return EncounterResult.fromJson(result);
  });

  @override
  Future<void> setPace(String childId, int? stationsPerWeek) => guardBackend(
    () => _client.rpc<void>('set_pace', params: {'p_child_id': childId, 'p_stations_per_week': stationsPerWeek}),
  );

  @override
  Future<void> setStreakPause(String childId, {required bool paused}) =>
      guardBackend(() => _client.rpc<void>('set_streak_pause', params: {'p_child_id': childId, 'p_paused': paused}));
}
