import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/domain/money.dart';

void main() {
  test('Ganze Zahlen für Einsteiger: „3 €“, „80 ct“, beim Legen „1 € 20 ct“', () {
    expect(formatWholeCents(300), '3 €');
    expect(formatWholeCents(80), '80 ct');
    expect(formatWholeCents(120), '1 € 20 ct');
    expect(formatWholeCents(0), '0 €');
  });

  test('Einsteiger bekommen die Zwillingsfrage, mit gleicher Kennung und richtiger Stelle', () {
    const question = QuizQuestion(
      id: 'q1',
      stationId: 's1',
      question: 'Was ist mehr: 1,50 € oder 105 Cent?',
      answers: ['1,50 €', '105 Cent', 'Beides gleich viel'],
      correctIndex: 0,
      beginner: (
        question: 'Was ist mehr: 2 € oder 150 Cent?',
        answers: ['2 €', '150 Cent', 'Gleich viel'],
        explanation: null,
      ),
    );
    expect(question.forLevel(LevelSetting.advanced), same(question));
    final easy = question.forLevel(LevelSetting.beginner);
    expect((easy.id, easy.correctIndex, easy.question), ('q1', 0, 'Was ist mehr: 2 € oder 150 Cent?'));
    expect(easy.answers.first, '2 €');

    // Ohne Zwilling bleibt die Frage, wie sie ist.
    const plain = QuizQuestion(
      id: 'q2',
      stationId: 's1',
      question: 'Ohne Komma?',
      answers: ['Ja', 'Nein'],
      correctIndex: 0,
    );
    expect(plain.forLevel(LevelSetting.beginner), same(plain));
  });

  test('Spiele: Einsteiger spielen die Fassung mit ganzen Zahlen', () {
    final game = GameInfo.fromJson({
      'type': 'coins',
      'title': 'Münzschublade',
      'rounds': [
        {'question': 'Lege 3,50 €.', 'amount': 350},
      ],
      'beginner': {
        'type': 'coins',
        'title': 'Münzschublade',
        'rounds': [
          {'question': 'Lege 8 €.', 'amount': 800},
        ],
      },
    });
    expect(game.wholeNumbers, isFalse);
    expect(game.forLevel(LevelSetting.advanced).rounds.single.amount, 350);
    final easy = game.forLevel(LevelSetting.beginner);
    expect((easy.rounds.single.amount, easy.wholeNumbers), (800, true));
  });
}
