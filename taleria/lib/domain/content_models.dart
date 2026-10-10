/// Inhalte und Fortschritt auf der Inselkarte. Ohne Aussehen, ohne Supabase.
library;

import 'progress_models.dart';

/// Eine Insel auf der Karte (aus map_islands()).
class MapIsland {
  const MapIsland({
    required this.id,
    required this.slug,
    required this.title,
    required this.sortOrder,
    required this.mapX,
    required this.mapY,
    required this.hasContent,
    this.group,
    this.routeType = 'main',
  });

  final String id;
  final String slug;
  final String title;
  final int? group;
  final int sortOrder;

  /// Position auf der Karte, jeweils 0 bis 1 (y: 0 oben, 1 unten).
  final double mapX;
  final double mapY;
  final String routeType;

  /// `false` = Insel liegt im Nebel (Inhalte noch nicht veröffentlicht).
  final bool hasContent;

  bool get isMainRoute => routeType == 'main';
}

/// Eine Zeile Dialog von Talo, Tala oder einer anderen Figur.
class DialogLine {
  const DialogLine({required this.speaker, required this.text, this.name});

  factory DialogLine.fromJson(Map<String, dynamic> json) => DialogLine(
    speaker: json['speaker'] as String? ?? 'talo',
    text: json['text'] as String? ?? '',
    name: json['name'] as String?,
  );

  /// Figur, passend zum Asset-Schlüssel `character.<speaker>`.
  final String speaker;
  final String text;

  /// Angezeigter Name, wenn es nicht Talo oder Tala ist.
  final String? name;
}

class IslandDetails {
  const IslandDetails({
    required this.id,
    required this.slug,
    required this.title,
    this.goal,
    this.arrivalVideoKey,
    this.arrivalScene = const [],
    this.badge,
  });

  factory IslandDetails.fromRow(Map<String, dynamic> row) {
    final content = (row['content'] as Map<String, dynamic>?) ?? const {};
    final arrival = content['arrival'] as Map<String, dynamic>?;
    return IslandDetails(
      id: row['id'] as String,
      slug: row['slug'] as String,
      title: row['title'] as String,
      goal: content['goal'] as String?,
      arrivalVideoKey: arrival?['video_key'] as String?,
      arrivalScene: [
        for (final l in (arrival?['scene'] as List?) ?? const []) DialogLine.fromJson(l as Map<String, dynamic>),
      ],
      badge: content['badge'] as String?,
    );
  }

  final String id;
  final String slug;
  final String title;
  final String? goal;
  final String? arrivalVideoKey;
  final List<DialogLine> arrivalScene;

  /// Name des Ordens für diese Insel.
  final String? badge;

  bool get hasArrival => arrivalScene.isNotEmpty || arrivalVideoKey != null;
}

enum StationType { video, quiz, game, practice, reviewStop, exam }

class ExamRules {
  const ExamRules({required this.show, required this.review, required this.pass});

  /// Fragen aus der eigenen Prüfung.
  final int show;

  /// Rückblick-Fragen aus Prüfungen früherer Inseln.
  final int review;

  /// Bestanden ab so vielen richtigen Antworten.
  final int pass;
}

/// Ein Ding in einem Mini-Spiel (Sortieren oder Reihenfolge).
class GameItem {
  const GameItem({required this.text, this.basket, this.hint});

  final String text;

  /// Sortieren: richtiger Korb; `null` = passt in jeden Korb (dazwischen).
  final int? basket;
  final String? hint;
}

class GameInfo {
  const GameInfo({
    required this.type,
    required this.title,
    this.description,
    this.task,
    this.items = const [],
    this.baskets = const [],
    this.from,
    this.to,
    this.done,
  });

  factory GameInfo.fromJson(Map<String, dynamic> game) => GameInfo(
    type: game['type'] as String? ?? '',
    title: game['title'] as String? ?? '',
    description: game['description'] as String?,
    task: game['task'] as String?,
    items: [
      for (final i in (game['items'] as List?) ?? const [])
        GameItem(
          text: (i as Map<String, dynamic>)['text'] as String? ?? '',
          basket: i['basket'] as int?,
          hint: i['hint'] as String?,
        ),
    ],
    baskets: [for (final b in (game['baskets'] as List?) ?? const []) b as String],
    from: game['from'] as String?,
    to: game['to'] as String?,
    done: game['done'] is Map<String, dynamic> ? DialogLine.fromJson(game['done'] as Map<String, dynamic>) : null,
  );

  /// sort, order oder eine Spielart, die erst später gebaut wird (Platzhalter).
  final String type;
  final String title;
  final String? description;
  final String? task;
  final List<GameItem> items;
  final List<String> baskets;
  final String? from;
  final String? to;
  final DialogLine? done;

  /// Hat die App für diese Spielart schon eine Spielmechanik?
  bool get isPlayable => switch (type) {
    'sort' => baskets.length >= 2 && items.isNotEmpty,
    'order' => items.length >= 2,
    _ => false,
  };
}

/// Aufgabe im Wrack: eine Frage mit drei Antworten, ohne Punkte.
class WreckTask {
  const WreckTask({
    required this.question,
    required this.answers,
    required this.correctIndex,
    this.scene = const [],
    this.explanation,
  });

  final List<DialogLine> scene;
  final String question;
  final List<String> answers;
  final int correctIndex;
  final String? explanation;

  /// Als Quizfrage, damit dieselbe Mechanik wie bei Begegnungen greift.
  QuizQuestion asQuestion(String stationId) => QuizQuestion(
    id: '$stationId/wreck',
    stationId: stationId,
    question: question,
    answers: answers,
    correctIndex: correctIndex,
    explanation: explanation,
  );
}

/// Tauchgang an einem Ankerplatz (CLAUDE.md Abschnitt 8).
class DiveInfo {
  const DiveInfo({required this.game, required this.questions, this.wreck});

  /// pearls, treasure_chest, fish_swarm oder shell_count. Gebaut ist pearls,
  /// die anderen zeigen bis zu ihrem Bau das Perlentauchen.
  final String game;
  final int questions;
  final WreckTask? wreck;
}

/// Inhalt einer Station (stations.content).
class StationContent {
  const StationContent({
    required this.title,
    this.place,
    this.goal,
    this.minutes,
    this.isOnboarding = false,
    this.videoKey,
    this.scene = const [],
    this.lesson = const [],
    this.game,
    this.summary,
    this.quizShow,
    this.exam,
    this.number,
    this.dive,
  });

  factory StationContent.fromJson(Map<String, dynamic> json) {
    List<DialogLine> lines(Object? raw) => [
      for (final l in (raw as List?) ?? const []) DialogLine.fromJson(l as Map<String, dynamic>),
    ];
    final game = json['game'] as Map<String, dynamic>?;
    final exam = json['exam'] as Map<String, dynamic>?;
    final summary = json['summary'] as Map<String, dynamic>?;
    final dive = json['dive'] as Map<String, dynamic>?;
    final wreck = dive?['wreck'] as Map<String, dynamic>?;
    return StationContent(
      title: json['title'] as String? ?? '',
      place: json['place'] as String?,
      goal: json['goal'] as String?,
      minutes: json['minutes'] as String?,
      isOnboarding: json['kind'] == 'onboarding',
      videoKey: json['video_key'] as String?,
      scene: lines(json['scene']),
      lesson: lines(json['lesson']),
      game: game == null ? null : GameInfo.fromJson(game),
      summary: summary == null ? null : DialogLine.fromJson(summary),
      quizShow: (json['quiz'] as Map<String, dynamic>?)?['show'] as int?,
      exam: exam == null
          ? null
          : ExamRules(
              show: exam['show'] as int? ?? 10,
              review: exam['review'] as int? ?? 0,
              pass: exam['pass'] as int? ?? 8,
            ),
      number: json['number'] as int?,
      dive: dive == null
          ? null
          : DiveInfo(
              game: dive['game'] as String? ?? 'pearls',
              questions: dive['questions'] as int? ?? 4,
              wreck: wreck == null
                  ? null
                  : WreckTask(
                      scene: lines(wreck['scene']),
                      question: wreck['question'] as String? ?? '',
                      answers: [for (final a in (wreck['answers'] as List?) ?? const []) a as String],
                      correctIndex: wreck['correct_index'] as int? ?? 0,
                      explanation: wreck['explanation'] as String?,
                    ),
            ),
    );
  }

  final String title;
  final String? place;
  final String? goal;
  final String? minutes;
  final bool isOnboarding;
  final String? videoKey;
  final List<DialogLine> scene;
  final List<DialogLine> lesson;
  final GameInfo? game;
  final DialogLine? summary;
  final int? quizShow;
  final ExamRules? exam;

  /// Angezeigte Nummer (Station 3 oder Ankerplatz 2).
  final int? number;

  /// Nur bei Ankerplätzen.
  final DiveInfo? dive;
}

class StationInfo {
  const StationInfo({
    required this.id,
    required this.islandId,
    required this.sortOrder,
    required this.type,
    required this.isRequired,
    required this.xpReward,
    required this.content,
  });

  final String id;
  final String islandId;
  final int sortOrder;
  final StationType type;
  final bool isRequired;
  final int xpReward;
  final StationContent content;

  bool get isExam => type == StationType.exam;

  /// Ankerplatz mit Tauchgang.
  bool get isDive => type == StationType.reviewStop;

  /// Nummer für die Anzeige (bei älteren Inhalten ohne Nummer die Reihenfolge).
  int get displayNumber => content.number ?? sortOrder;

  static StationType parseType(String? value) => switch (value) {
    'video' => StationType.video,
    'quiz' => StationType.quiz,
    'practice' => StationType.practice,
    'review_stop' => StationType.reviewStop,
    'exam' => StationType.exam,
    _ => StationType.game,
  };
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.stationId,
    required this.question,
    required this.answers,
    required this.correctIndex,
    this.explanation,
    this.coversStation,
  });

  final String id;
  final String stationId;
  final String question;

  /// Antworten in der gespeicherten Reihenfolge (vor dem Mischen).
  final List<String> answers;
  final int correctIndex;
  final String? explanation;

  /// Bei Prüfungsfragen: zu welcher Station der Insel die Frage gehört.
  final int? coversStation;
}

/// Was das Kind schon geschafft hat.
class ChildProgress {
  const ChildProgress({this.doneStationIds = const {}, this.completedIslandIds = const {}});

  final Set<String> doneStationIds;
  final Set<String> completedIslandIds;
}

/// Antwort des Servers nach dem Abgeben einer Station.
class StationResult {
  const StationResult({
    required this.correct,
    required this.total,
    required this.passed,
    required this.xpAwarded,
    required this.islandCompleted,
    this.rankUp,
    this.badge,
    this.windLeft,
    this.find,
  });

  factory StationResult.fromJson(Map<String, dynamic> json) => StationResult(
    correct: json['correct'] as int,
    total: json['total'] as int,
    passed: json['passed'] as bool,
    xpAwarded: json['xp_awarded'] as int,
    islandCompleted: json['island_completed'] as bool,
    rankUp: Rank.parse(json['rank_up']),
    badge: json['badge'] is Map<String, dynamic> ? BadgeInfo.fromJson(json['badge'] as Map<String, dynamic>) : null,
    windLeft: json['wind_left'] as int?,
    find: json['find'] is Map<String, dynamic> ? CollectibleInfo.fromJson(json['find'] as Map<String, dynamic>) : null,
  );

  final int correct;
  final int total;
  final bool passed;
  final int xpAwarded;
  final bool islandCompleted;

  /// Neuer Rang durch diese Station, sonst `null`.
  final Rank? rankUp;

  /// Orden der Insel, wenn sie mit dieser Station abgeschlossen wurde.
  final BadgeInfo? badge;

  /// Wind für weitere neue Stationen (`null` bei freier Fahrt oder Bonus-Station).
  final int? windLeft;

  /// Neuer Fund aus dem Tauchgang, sonst `null`.
  final CollectibleInfo? find;
}
