import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../data/local_settings.dart';
import '../domain/content_models.dart';
import '../domain/family_models.dart';
import '../domain/progress_logic.dart';
import '../domain/quiz_logic.dart';
import 'encounter_controller.dart' show EncounterRun;

/// Abschnitte einer Station (INSELN.md, Aufbau jeder Station):
/// Weißt du noch? → Film → Szene → Erklärung → Spiel → Quiz → Ergebnis.
/// Die Abschlussprüfung hat nur Szene, Quiz und Ergebnis.
/// Ein Ankerplatz hat Perlentauchen (quiz) und das Wrack (wreck).
enum StationStep { loading, warmUp, video, scene, lesson, game, quiz, wreck, submitting, result, failed }

/// Ein Durchgang durch Fragen mit gemischten Antworten.
class QuizRun {
  QuizRun(this.questions);

  final List<ShuffledQuestion> questions;
  final Map<int, int> _chosen = {};
  int _index = 0;

  int get index => _index;
  int get total => questions.length;
  ShuffledQuestion get current => questions[_index];
  bool get isLast => _index == questions.length - 1;

  /// Angezeigte Stelle der gewählten Antwort zur aktuellen Frage, sonst `null`.
  int? get chosen => _chosen[_index];
  bool get answered => chosen != null;
  bool get answeredCorrectly => answered && current.isCorrect(chosen!);

  int get correctCount => [for (final e in _chosen.entries) questions[e.key].isCorrect(e.value)].where((c) => c).length;

  /// Erste Antwort zählt, danach ist die Frage beantwortet.
  void answer(int displayIndex) => _chosen.putIfAbsent(_index, () => displayIndex);

  void next() {
    if (answered && !isLast) _index++;
  }

  /// Für den Server: Frage und gewählte Stelle in der gespeicherten Liste.
  List<({String questionId, int answerIndex})> get submission => [
    for (final (i, q) in questions.indexed) (questionId: q.question.id, answerIndex: q.originalIndex(_chosen[i]!)),
  ];
}

class StationController extends ChangeNotifier {
  StationController({
    required this._content,
    required this._progress,
    required this._settings,
    required this.child,
    required this.island,
    required this.station,
    required this.allStations,
    Random? random,
  }) : _random = random ?? Random();

  final ContentRepository _content;
  final ProgressRepository _progress;
  final LocalSettings _settings;
  final Random _random;
  final ChildProfile child;
  final MapIsland island;
  final StationInfo station;

  /// Alle Stationen der Insel (für „Weißt du noch?“).
  final List<StationInfo> allStations;

  StationStep _step = StationStep.loading;
  QuizRun? _warmUp;
  QuizRun? _quiz;
  EncounterRun? _wreck;
  StationResult? _result;
  FailureKind? _failure;

  StationStep get step => _step;
  QuizRun? get warmUp => _warmUp;
  QuizRun? get quiz => _quiz;

  /// Aufgabe im Wrack (nur Ankerplatz): probieren, bis es stimmt.
  EncounterRun? get wreck => _wreck;
  StationResult? get result => _result;
  FailureKind? get failure => _failure;
  StationContent get content => station.content;
  bool get isExam => station.isExam;
  bool get isDive => station.isDive;

  /// Lädt die Fragen und beginnt mit dem ersten Abschnitt.
  Future<void> start() async {
    _step = StationStep.loading;
    _failure = null;
    notifyListeners();
    try {
      await _prepareQuiz();
      await _prepareWarmUp();
      _go(_firstStep());
    } on AppFailure catch (e) {
      _failure = e.kind;
      _go(StationStep.failed);
    }
  }

  StationStep _firstStep() {
    if (isDive) return StationStep.quiz;
    if (_warmUp != null) return StationStep.warmUp;
    return _afterWarmUp();
  }

  StationStep _afterWarmUp() {
    if (content.videoKey != null && !isExam) return StationStep.video;
    return _afterVideo();
  }

  StationStep _afterVideo() => content.scene.isNotEmpty ? StationStep.scene : _afterScene();

  StationStep _afterScene() => content.lesson.isNotEmpty && !isExam ? StationStep.lesson : _afterLesson();

  StationStep _afterLesson() => content.game != null && !isExam ? StationStep.game : StationStep.quiz;

  /// Weiter zum nächsten Abschnitt (aus Film, Szene, Erklärung, Spiel).
  void next() {
    final nextStep = switch (_step) {
      StationStep.warmUp => _afterWarmUp(),
      StationStep.video => _afterVideo(),
      StationStep.scene => _afterScene(),
      StationStep.lesson => _afterLesson(),
      StationStep.game => StationStep.quiz,
      _ => _step,
    };
    _go(nextStep);
  }

  void answerWarmUp(int displayIndex) {
    _warmUp?.answer(displayIndex);
    notifyListeners();
  }

  void nextWarmUp() {
    final run = _warmUp!;
    if (run.isLast) {
      unawaited(_recordWarmUp(run));
      next();
    } else {
      run.next();
      notifyListeners();
    }
  }

  /// „Weißt du noch?“ fließt in den Wiederholungsplan, ohne Wertung.
  Future<void> _recordWarmUp(QuizRun run) async {
    if (!run.answered) return;
    try {
      await _progress.recordAnswers(childId: child.id, answers: run.submission);
    } on AppFailure {
      // Nur für den Wiederholungsplan: Ein Fehler hier stört das Kind nicht.
    }
  }

  void answerQuiz(int displayIndex) {
    _quiz?.answer(displayIndex);
    notifyListeners();
  }

  /// Nächste Frage oder, nach der letzten, abgeben.
  Future<void> nextQuiz() async {
    final run = _quiz!;
    if (!run.answered) return;
    if (!run.isLast) {
      run.next();
      notifyListeners();
      return;
    }
    final wreckTask = content.dive?.wreck;
    if (isDive && wreckTask != null) {
      _wreck = EncounterRun([wreckTask.asQuestion(station.id)], _random);
      _go(StationStep.wreck);
      return;
    }
    await submit();
  }

  void answerWreck(int displayIndex) {
    _wreck?.answer(displayIndex);
    notifyListeners();
  }

  void retryWreck() {
    _wreck?.retry();
    notifyListeners();
  }

  /// Wrack geschafft: Tauchgang abgeben.
  Future<void> finishWreck() async {
    if (!(_wreck?.finished ?? false)) return;
    await submit();
  }

  Future<void> submit() async {
    _go(StationStep.submitting);
    try {
      _result = await _progress.submitStation(childId: child.id, stationId: station.id, answers: _quiz!.submission);
      _go(StationStep.result);
    } on AppFailure catch (e) {
      _failure = e.kind;
      _go(StationStep.failed);
    }
  }

  /// Nach einem Fehler: Abgeben wiederholen, wenn das Quiz fertig ist,
  /// sonst neu starten.
  Future<void> retryAfterFailure() async {
    final run = _quiz;
    if (run != null && run.isLast && run.answered) {
      await submit();
    } else {
      await start();
    }
  }

  /// Prüfung nicht bestanden: neue Auswahl, ohne Strafe.
  Future<void> retryExam() async {
    _result = null;
    _go(StationStep.loading);
    try {
      await _prepareQuiz();
      _go(StationStep.quiz);
    } on AppFailure catch (e) {
      _failure = e.kind;
      _go(StationStep.failed);
    }
  }

  Future<void> _prepareQuiz() async {
    final previous = await _settings.lastQuizSelection(child.id, station.id);
    final List<QuizQuestion> picked;
    final exam = content.exam;
    if (isDive) {
      // Perlentauchen: Fragen der Stationen seit dem letzten Ankerplatz.
      final pools = [for (final s in stationsBeforeDive(allStations, station)) await _content.fetchQuestions(s.id)];
      picked = pickDiveQuestions(pools, content.dive?.questions ?? 4, _random);
      _quiz = QuizRun([for (final q in picked) ShuffledQuestion.shuffle(q, _random)]);
      return;
    }
    final pool = await _content.fetchQuestions(station.id);
    if (isExam && exam != null) {
      // Rückblick-Fragen aus Prüfungen früherer Inseln (ab Insel 2).
      final reviewPool = exam.review > 0
          ? await _content.fetchReviewPool(stage: child.stage, beforeSortOrder: island.sortOrder)
          : const <QuizQuestion>[];
      picked = pickExamQuestions(
        ownPool: pool,
        reviewPool: reviewPool,
        rules: exam,
        random: _random,
        previousIds: previous,
      );
    } else {
      picked = pickQuestions(pool, content.quizShow ?? 3, _random, previousIds: previous);
    }
    await _settings.setLastQuizSelection(child.id, station.id, {for (final q in picked) q.id});
    _quiz = QuizRun([for (final q in picked) ShuffledQuestion.shuffle(q, _random)]);
  }

  Future<void> _prepareWarmUp() async {
    _warmUp = null;
    if (isExam || isDive) return;
    final previous = previousQuizStation(allStations, station);
    if (previous == null) return;
    final pool = await _content.fetchQuestions(previous.id);
    if (pool.length < 2) return;
    _warmUp = QuizRun([for (final q in pickWarmUp(pool, _random)) ShuffledQuestion.shuffle(q, _random)]);
  }

  void _go(StationStep step) {
    _step = step;
    notifyListeners();
  }
}
