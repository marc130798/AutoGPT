import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/budget_models.dart';
import 'package:taleria/domain/money.dart';

void main() {
  test('Eingaben werden zu Cent', () {
    expect(parseEuroInput('5'), 500);
    expect(parseEuroInput('5,5'), 550);
    expect(parseEuroInput('5,50'), 550);
    expect(parseEuroInput('5.05'), 505);
    expect(parseEuroInput(' 12,30 € '), 1230);
    expect(parseEuroInput('0,99'), 99);
  });

  test('Ungültige Eingaben', () {
    for (final input in ['', 'abc', '5,555', '-2', '1.000,00', '5,']) {
      expect(parseEuroInput(input), isNull, reason: input);
    }
  });

  test('Prüfung des Betrags', () {
    expect(validateAmount('2,50'), isNull);
    expect(validateAmount('0'), AmountProblem.zero);
    expect(validateAmount('1000,01'), AmountProblem.tooLarge);
    expect(validateAmount('101', max: 10000), AmountProblem.tooLarge);
    expect(validateAmount('zwei'), AmountProblem.invalid);
  });

  test('Anzeige in Euro', () {
    expect(formatCents(250), '2,50 €');
    expect(formatCents(5), '0,05 €');
    expect(formatCents(-250), '-2,50 €');
    expect(formatCents(123456789), '1.234.567,89 €');
    expect(centsToInput(250), '2,50');
  });

  test('Wunschschatz: Fortschritt und Einlösen', () {
    const goal = SavingsGoal(id: 'g', title: 'Ball', targetCents: 2000);
    expect(goal.progress(500), 0.25);
    expect(goal.progress(5000), 1.0);
    expect(goal.canRedeem(1999), isFalse);
    expect(goal.canRedeem(2000), isTrue);
  });

  test('Aufträge: wer was darf', () {
    FamilyTask task(TaskStatus s) => FamilyTask(id: 't', title: 'T', rewardCents: 100, isChore: false, status: s);
    expect(task(TaskStatus.open).canSubmit, isTrue);
    expect(task(TaskStatus.rejected).canSubmit, isTrue);
    expect(task(TaskStatus.submitted).canSubmit, isFalse);
    expect(task(TaskStatus.approved).canSubmit, isFalse);
    expect(task(TaskStatus.submitted).canApprove, isTrue);
    expect(task(TaskStatus.approved).canApprove, isFalse);
  });
}
