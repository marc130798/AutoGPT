import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/services/station_controller.dart';

import '../fake_content.dart';
import '../fakes.dart';

void main() {
  late FakeContent content;
  late FakeProgress progress;
  late FakeLocalSettings settings;
  const child = ChildProfile(
    id: 'kind',
    nickname: 'Mila',
    birthYear: 2015,
    level: LevelSetting.beginner,
    onboardingCompleted: true,
  );

  setUp(() {
    content = FakeContent();
    progress = FakeProgress(content);
    settings = FakeLocalSettings();
  });

  StationController controllerFor(String slug, int number, {int seed = 1}) {
    final island = content.island(slug);
    final stations = content.stations[island.id]!;
    return StationController(
      content: content,
      progress: progress,
      settings: settings,
      child: child,
      island: island,
      station: stations.firstWhere((s) => s.sortOrder == number),
      allStations: stations,
      random: Random(seed),
    );
  }

  /// Beantwortet alle Fragen des Quiz (richtig oder immer die erste Antwort).
  Future<void> answerAll(StationController c, {bool correctly = true}) async {
    final run = c.quiz!;
    for (var i = 0; i < run.total; i++) {
      c.answerQuiz(correctly ? run.current.correctDisplayIndex : (run.current.correctDisplayIndex + 1) % 3);
      await c.nextQuiz();
    }
  }

  test('Hafen Station 2: Film, Szene, Erklärung, Spiel, Quiz mit 5 Fragen, Ergebnis', () async {
    final c = controllerFor('hafen', 2);
    await c.start();
    // Kein „Weißt du noch?“: davor liegt nur das Intro.
    expect(c.step, StationStep.video);
    c.next();
    expect(c.step, StationStep.scene);
    c.next();
    expect(c.step, StationStep.lesson);
    c.next();
    expect(c.step, StationStep.game);
    c.next();
    expect(c.step, StationStep.quiz);
    expect(c.quiz!.total, 5);

    await answerAll(c);
    expect(c.step, StationStep.result);
    expect(c.result!.correct, 5);
    expect(c.result!.xpAwarded, 100);
  });

  test('Ab Station 3: zuerst „Weißt du noch?“ mit 2 Fragen der Station davor', () async {
    progress.done.add('island-hafen/station2');
    final c = controllerFor('hafen', 3);
    await c.start();
    expect(c.step, StationStep.warmUp);
    expect(c.warmUp!.total, 2);
    final previousIds = content.questions['island-hafen/station2']!.map((q) => q.id).toSet();
    expect(c.warmUp!.questions.every((q) => previousIds.contains(q.question.id)), isTrue);

    c.answerWarmUp(0);
    c.nextWarmUp();
    c.answerWarmUp(0);
    c.nextWarmUp();
    expect(c.step, StationStep.video);
    expect(progress.submissions, 0, reason: 'Aufwärmfragen werden nicht abgegeben');
    await pumpEventQueue();
    expect(progress.recordedAnswers, hasLength(1), reason: 'aber sie fließen in den Wiederholungsplan');
    expect(progress.recordedAnswers.single.map((a) => a.questionId), c.warmUp!.questions.map((q) => q.question.id));
  });

  test('Ohne Wind: Server lehnt eine neue Station ab, die App zeigt es freundlich', () async {
    progress
      ..stationsPerWeek = 2
      ..wind = 0;
    final c = controllerFor('hafen', 2);
    await c.start();
    while (c.step != StationStep.quiz) {
      c.next();
    }
    await answerAll(c);
    expect(c.step, StationStep.failed);
    expect(c.failure, FailureKind.noWind);
  });

  test('Neue Station verbraucht Wind; Rang und Orden kommen im Ergebnis', () async {
    progress
      ..stationsPerWeek = 2
      ..wind = 1
      ..extraXp = 1450;
    final c = controllerFor('hafen', 2);
    await c.start();
    while (c.step != StationStep.quiz) {
      c.next();
    }
    await answerAll(c);
    expect(c.result!.windLeft, 0);
    expect(c.result!.rankUp?.code, 'matrose');
    expect(progress.wind, 0);
  });

  test('Falsche Antworten: Station trotzdem geschafft', () async {
    progress.completeStations('hafen', except: 6);
    final c = controllerFor('hafen', 3);
    await c.start();
    while (c.step != StationStep.quiz) {
      if (c.step == StationStep.warmUp) {
        c.answerWarmUp(0);
        c.nextWarmUp();
      } else {
        c.next();
      }
    }
    await answerAll(c, correctly: false);
    expect(c.result!.passed, isTrue);
    expect(c.result!.correct, 0);
  });

  test('Prüfung Hafen: 10 Fragen, jede Station abgedeckt, Insel abgeschlossen', () async {
    progress.completeStations('hafen', except: 1);
    final c = controllerFor('hafen', 8);
    await c.start();
    expect(c.step, StationStep.scene);
    c.next();
    expect(c.step, StationStep.quiz);
    expect(c.quiz!.total, 10);
    expect(c.quiz!.questions.map((q) => q.question.coversStation).toSet(), {2, 3, 4, 5, 6, 7});

    await answerAll(c);
    expect(c.result!.passed, isTrue);
    expect(c.result!.xpAwarded, 150);
    expect(c.result!.islandCompleted, isTrue);
  });

  test('Prüfung nicht bestanden: neue Auswahl ohne Strafe', () async {
    progress.completeStations('hafen', except: 1);
    final c = controllerFor('hafen', 8);
    await c.start();
    c.next();
    final firstIds = c.quiz!.questions.map((q) => q.question.id).toSet();
    await answerAll(c, correctly: false);
    expect(c.result!.passed, isFalse);
    expect(c.result!.xpAwarded, 0);

    await c.retryExam();
    expect(c.step, StationStep.quiz);
    expect(c.quiz!.questions.map((q) => q.question.id).toSet(), isNot(firstIds));
  });

  test('Prüfung Tauschinsel: 8 eigene Fragen und 2 Rückblick-Fragen aus dem Hafen', () async {
    progress.completeStations('tauschinsel', except: 1);
    final c = controllerFor('tauschinsel', 8);
    await c.start();
    c.next();
    final run = c.quiz!;
    expect(run.total, 10);
    final hafenExam = content.questions['island-hafen/station8']!.map((q) => q.id).toSet();
    expect(run.questions.where((q) => hafenExam.contains(q.question.id)), hasLength(2));
  });

  test('Ohne Verbindung beim Abgeben: Fehler, dann erneut abgeben ohne Neustart', () async {
    final c = controllerFor('hafen', 2);
    await c.start();
    while (c.step != StationStep.quiz) {
      c.next();
    }
    progress.failWith = FailureKind.network;
    await answerAll(c);
    expect(c.step, StationStep.failed);
    expect(c.failure, FailureKind.network);

    progress.failWith = null;
    await c.retryAfterFailure();
    expect(c.step, StationStep.result);
    expect(progress.submissions, 1);
  });
}
