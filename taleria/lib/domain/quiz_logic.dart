/// Quiz-Regeln (INSELN.md, Abschnitt Quiz-Regeln):
/// * Fragen zufällig aus dem Pool, Reihenfolge der Fragen und Antworten gemischt.
/// * Dieselbe Zusammenstellung nie zweimal hintereinander.
/// * Prüfung: mindestens eine Frage aus jeder Station, dazu Rückblick-Fragen.
library;

import 'dart:math';

import 'content_models.dart';

/// Eine Frage mit gemischten Antworten.
class ShuffledQuestion {
  ShuffledQuestion(this.question, this.order);

  /// Mischt die Antworten einer Frage.
  factory ShuffledQuestion.shuffle(QuizQuestion question, Random random) {
    final order = List<int>.generate(question.answers.length, (i) => i)..shuffle(random);
    return ShuffledQuestion(question, order);
  }

  final QuizQuestion question;

  /// order[angezeigte Stelle] = Stelle in der gespeicherten Antwortliste.
  final List<int> order;

  List<String> get answers => [for (final i in order) question.answers[i]];

  /// Angezeigte Stelle der richtigen Antwort.
  int get correctDisplayIndex => order.indexOf(question.correctIndex);

  /// Für den Server: gespeicherte Stelle der angetippten Antwort.
  int originalIndex(int displayIndex) => order[displayIndex];

  bool isCorrect(int displayIndex) => originalIndex(displayIndex) == question.correctIndex;
}

/// Zieht [count] Fragen aus dem Pool. Ist [previousIds] gesetzt (die
/// Zusammenstellung vom letzten Mal), kommt nie genau dieselbe Auswahl.
List<QuizQuestion> pickQuestions(List<QuizQuestion> pool, int count, Random random, {Set<String>? previousIds}) {
  if (pool.length <= count) return [...pool]..shuffle(random);
  for (var attempt = 0; attempt < 20; attempt++) {
    final pick = ([...pool]..shuffle(random)).take(count).toList();
    if (previousIds == null || !_sameSet(pick, previousIds)) return pick;
  }
  // Sicherheitsnetz: eine Frage gegen eine bisher nicht gezeigte tauschen.
  final pick = ([...pool]..shuffle(random)).take(count).toList();
  final unused = pool.where((q) => !previousIds!.contains(q.id)).toList();
  if (unused.isNotEmpty) pick[0] = unused[random.nextInt(unused.length)];
  return pick..shuffle(random);
}

/// Prüfungsfragen: zuerst je eine zufällige Frage pro Station, dann zufällig
/// auffüllen bis [rules.show], dazu [rules.review] Rückblick-Fragen.
/// Ergebnis ist gemischt.
List<QuizQuestion> pickExamQuestions({
  required List<QuizQuestion> ownPool,
  required List<QuizQuestion> reviewPool,
  required ExamRules rules,
  required Random random,
  Set<String>? previousIds,
}) {
  List<QuizQuestion> attempt() {
    final shuffled = [...ownPool]..shuffle(random);
    final picked = <QuizQuestion>[];
    final coveredStations = <int>{};
    for (final q in shuffled) {
      final station = q.coversStation;
      if (station != null && coveredStations.add(station) && picked.length < rules.show) picked.add(q);
    }
    for (final q in shuffled) {
      if (picked.length >= rules.show) break;
      if (!picked.contains(q)) picked.add(q);
    }
    final review = ([...reviewPool]..shuffle(random)).take(rules.review);
    return [...picked, ...review]..shuffle(random);
  }

  var pick = attempt();
  for (var i = 0; i < 20 && previousIds != null && _sameSet(pick, previousIds); i++) {
    pick = attempt();
  }
  return pick;
}

/// Tauchgang: [count] Fragen, abwechselnd aus den Pools der Stationen davor,
/// damit jede Station drankommt. Ergebnis ist gemischt.
List<QuizQuestion> pickDiveQuestions(List<List<QuizQuestion>> pools, int count, Random random) {
  final queues = [
    for (final pool in pools.where((p) => p.isNotEmpty)) [...pool]..shuffle(random),
  ];
  final picked = <QuizQuestion>[];
  while (picked.length < count && queues.any((q) => q.isNotEmpty)) {
    for (final queue in queues) {
      if (picked.length < count && queue.isNotEmpty) picked.add(queue.removeLast());
    }
  }
  return picked..shuffle(random);
}

/// „Weißt du noch?“: 2 kurze Fragen aus dem Pool der vorherigen Station.
List<QuizQuestion> pickWarmUp(List<QuizQuestion> previousStationPool, Random random) =>
    pickQuestions(previousStationPool, 2, random);

bool _sameSet(List<QuizQuestion> pick, Set<String> ids) =>
    pick.length == ids.length && pick.every((q) => ids.contains(q.id));
