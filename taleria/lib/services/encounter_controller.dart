import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../domain/content_models.dart';
import '../domain/family_models.dart';
import '../domain/progress_models.dart';
import '../domain/quiz_logic.dart';

/// Abschnitte einer Begegnung auf See: Szene → Rätsel → Ergebnis.
enum EncounterStep { loading, intro, question, submitting, result, failed }

/// Rätsel einer Begegnung. Anders als im Stations-Check darf das Kind eine
/// falsche Antwort gleich noch einmal versuchen (CLAUDE.md Abschnitt 8).
/// Für den Wiederholungsplan zählt nur die erste Antwort je Frage.
class EncounterRun {
  EncounterRun(this.questions, this._random) : assert(questions.isNotEmpty) {
    _current = ShuffledQuestion.shuffle(questions.first, _random);
  }

  final List<QuizQuestion> questions;
  final Random _random;
  late ShuffledQuestion _current;
  int _index = 0;
  int? _chosen;
  int _attempt = 1;

  /// Erste Antwort je Frage als Stelle in der gespeicherten Antwortliste.
  final Map<int, int> _firstAnswers = {};

  int get index => _index;
  int get total => questions.length;
  bool get isLast => _index == questions.length - 1;
  ShuffledQuestion get current => _current;

  /// Wievielter Versuch an der aktuellen Frage.
  int get attempt => _attempt;

  /// Angezeigte Stelle der gewählten Antwort im aktuellen Versuch.
  int? get chosen => _chosen;
  bool get answered => _chosen != null;
  bool get answeredCorrectly => answered && _current.isCorrect(_chosen!);

  /// Beim ersten Versuch richtig beantwortet.
  int get firstTryCorrect =>
      [for (final e in _firstAnswers.entries) e.value == questions[e.key].correctIndex].where((c) => c).length;

  void answer(int displayIndex) {
    if (_chosen != null) return;
    _chosen = displayIndex;
    _firstAnswers.putIfAbsent(_index, () => _current.originalIndex(displayIndex));
  }

  /// Nach einer falschen Antwort: dieselbe Frage, Antworten neu gemischt.
  void retry() {
    if (!answered || answeredCorrectly) return;
    _chosen = null;
    _attempt++;
    _current = ShuffledQuestion.shuffle(questions[_index], _random);
  }

  /// Weiter erst, wenn die aktuelle Frage richtig beantwortet ist.
  void next() {
    if (!answeredCorrectly || isLast) return;
    _index++;
    _chosen = null;
    _attempt = 1;
    _current = ShuffledQuestion.shuffle(questions[_index], _random);
  }

  bool get finished => isLast && answeredCorrectly;

  List<({String questionId, int answerIndex})> get submission => [
    for (final (i, q) in questions.indexed) (questionId: q.id, answerIndex: _firstAnswers[i]!),
  ];
}

class EncounterController extends ChangeNotifier {
  EncounterController({
    required this._content,
    required this._progress,
    required this.childId,
    required this.offer,
    Random? random,
  }) : _random = random ?? Random();

  final ContentRepository _content;
  final ProgressRepository _progress;
  final Random _random;
  final String childId;
  final EncounterOffer offer;

  EncounterStep _step = EncounterStep.loading;
  EncounterRun? _run;
  EncounterResult? _result;
  FailureKind? _failure;

  EncounterStep get step => _step;
  EncounterRun? get run => _run;
  EncounterResult? get result => _result;
  FailureKind? get failure => _failure;
  Encounter get encounter => offer.encounter;

  Future<void> start() async {
    _go(EncounterStep.loading);
    _failure = null;
    try {
      final questions = await _content.fetchQuestionsByIds(offer.questionIds);
      if (questions.length != offer.questionIds.length || questions.isEmpty) {
        throw const AppFailure(FailureKind.unknown, 'Fragen der Begegnung fehlen');
      }
      _run = EncounterRun(questions, _random);
      _go(offer.openingScene.isEmpty ? EncounterStep.question : EncounterStep.intro);
    } on AppFailure catch (e) {
      _failure = e.kind;
      _go(EncounterStep.failed);
    }
  }

  void introDone() => _go(EncounterStep.question);

  void answer(int displayIndex) {
    _run?.answer(displayIndex);
    notifyListeners();
  }

  void retry() {
    _run?.retry();
    notifyListeners();
  }

  /// Nächstes Rätsel oder, nach dem letzten, abgeben.
  Future<void> next() async {
    final run = _run!;
    if (run.finished) {
      await submit();
      return;
    }
    run.next();
    notifyListeners();
  }

  Future<void> submit() async {
    _go(EncounterStep.submitting);
    try {
      _result = await _progress.submitEncounter(childId: childId, encounterId: encounter.id, answers: _run!.submission);
      _go(EncounterStep.result);
    } on AppFailure catch (e) {
      _failure = e.kind;
      _go(EncounterStep.failed);
    }
  }

  /// Nach einem Fehler: Abgeben wiederholen, wenn alle Rätsel gelöst sind, sonst neu starten.
  Future<void> retryAfterFailure() async {
    if (_run?.finished ?? false) {
      await submit();
    } else {
      await start();
    }
  }

  void _go(EncounterStep step) {
    _step = step;
    notifyListeners();
  }
}
