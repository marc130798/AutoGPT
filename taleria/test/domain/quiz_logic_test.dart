import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/domain/quiz_logic.dart';

QuizQuestion question(String id, {int? covers, int correct = 0}) => QuizQuestion(
  id: id,
  stationId: 's',
  question: 'Frage $id',
  answers: const ['A', 'B', 'C'],
  correctIndex: correct,
  coversStation: covers,
);

void main() {
  final pool = [for (var i = 0; i < 6; i++) question('q$i')];

  test('Zieht die gewünschte Anzahl ohne doppelte Fragen', () {
    final pick = pickQuestions(pool, 3, Random(1));
    expect(pick, hasLength(3));
    expect(pick.map((q) => q.id).toSet(), hasLength(3));
  });

  test('Dieselbe Zusammenstellung kommt nie zweimal hintereinander', () {
    for (var seed = 0; seed < 200; seed++) {
      final first = pickQuestions(pool, 3, Random(seed));
      final second = pickQuestions(pool, 3, Random(seed), previousIds: first.map((q) => q.id).toSet());
      expect(second.map((q) => q.id).toSet(), isNot(first.map((q) => q.id).toSet()), reason: 'seed $seed');
    }
  });

  test('Zwei Kinder bekommen fast nie dieselben Fragen in derselben Reihenfolge', () {
    final orders = {
      for (var seed = 0; seed < 100; seed++) pickQuestions(pool, 3, Random(seed)).map((q) => q.id).join(),
    };
    expect(orders.length, greaterThan(50));
  });

  test('Antworten werden gemischt, die Auswertung bleibt richtig', () {
    final q = question('x', correct: 2);
    final seen = <String>{};
    for (var seed = 0; seed < 50; seed++) {
      final shuffled = ShuffledQuestion.shuffle(q, Random(seed));
      seen.add(shuffled.answers.join());
      expect(shuffled.answers[shuffled.correctDisplayIndex], 'C');
      expect(shuffled.isCorrect(shuffled.correctDisplayIndex), isTrue);
      expect(shuffled.originalIndex(shuffled.correctDisplayIndex), 2);
    }
    expect(seen.length, greaterThan(1));
  });

  group('Prüfung', () {
    // 20 Fragen zu den Stationen 2 bis 7 wie im Hafen.
    final own = [for (var i = 0; i < 20; i++) question('p$i', covers: 2 + i % 6)];
    final review = [for (var i = 0; i < 20; i++) question('r$i')];
    const rules = ExamRules(show: 8, review: 2, pass: 8);

    test('Mindestens eine Frage aus jeder Station, dazu 2 Rückblick-Fragen', () {
      for (var seed = 0; seed < 100; seed++) {
        final pick = pickExamQuestions(ownPool: own, reviewPool: review, rules: rules, random: Random(seed));
        expect(pick, hasLength(10));
        expect(pick.where((q) => q.id.startsWith('r')), hasLength(2));
        expect(pick.map((q) => q.coversStation).whereType<int>().toSet(), {2, 3, 4, 5, 6, 7}, reason: 'seed $seed');
        expect(pick.map((q) => q.id).toSet(), hasLength(10));
      }
    });

    test('Erste Insel ohne Rückblick', () {
      final pick = pickExamQuestions(
        ownPool: own,
        reviewPool: const [],
        rules: const ExamRules(show: 10, review: 0, pass: 8),
        random: Random(3),
      );
      expect(pick, hasLength(10));
    });

    test('Wiederholung bekommt eine neue Auswahl', () {
      final first = pickExamQuestions(ownPool: own, reviewPool: review, rules: rules, random: Random(7));
      final second = pickExamQuestions(
        ownPool: own,
        reviewPool: review,
        rules: rules,
        random: Random(7),
        previousIds: first.map((q) => q.id).toSet(),
      );
      expect(second.map((q) => q.id).toSet(), isNot(first.map((q) => q.id).toSet()));
    });
  });

  test('Weißt du noch? stellt 2 Fragen', () {
    expect(pickWarmUp(pool, Random(1)), hasLength(2));
  });
}
