import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/budget_models.dart';
import 'package:taleria/services/treasure_controller.dart';

import '../fake_budget.dart';

void main() {
  late FakeBudget budget;
  late TreasureController treasure;

  setUp(() async {
    budget = FakeBudget();
    treasure = TreasureController(budget: budget, childId: 'kind');
  });

  test('Heuer wird beim Öffnen nachgezahlt, aber nie doppelt', () async {
    await budget.setAllowance('kind', amountCents: 500, firstPayout: budget.now.subtract(const Duration(days: 15)));
    await treasure.load();
    expect(treasure.balances.spend, 1500, reason: 'vor 15, 8 und 1 Tag fällig');
    await treasure.load();
    expect(treasure.balances.spend, 1500);
    expect(treasure.allowance!.nextRunAt.isAfter(budget.now), isTrue);
  });

  test('Auftrag: erst nach Bestätigung gutgeschrieben, Pflicht ohne Geld', () async {
    await treasure.createTask(parentId: 'p', title: 'Rasen mähen', rewardCents: 300, isChore: false);
    await treasure.createTask(parentId: 'p', title: 'Zimmer', rewardCents: 0, isChore: true);
    final mow = treasure.tasks.firstWhere((t) => t.title == 'Rasen mähen');

    await treasure.submitTask(mow);
    expect(treasure.tasksWith(TaskStatus.submitted), hasLength(1));
    expect(treasure.balances.spend, 0);

    await treasure.reviewTask(treasure.tasksWith(TaskStatus.submitted).single, approve: true);
    expect(treasure.balances.spend, 300);

    final chore = treasure.tasks.firstWhere((t) => t.isChore);
    await treasure.reviewTask(chore, approve: true);
    expect(treasure.balances.spend, 300);
  });

  test('Abgelehnt: mit Nachricht, kann erneut gemeldet werden', () async {
    await treasure.createTask(parentId: 'p', title: 'Abwaschen', rewardCents: 200, isChore: false);
    await treasure.submitTask(treasure.tasks.single);
    await treasure.reviewTask(treasure.tasks.single, approve: false, note: 'Die Pfanne fehlt');
    final task = treasure.tasks.single;
    expect(task.status, TaskStatus.rejected);
    expect(task.parentNote, 'Die Pfanne fehlt');
    expect(task.canSubmit, isTrue);
  });

  test('Ausgeben: nie ins Minus, Fehler schon in der App', () async {
    await budget.bookManual('kind', amountCents: 1000);
    await treasure.load();
    expect(() => treasure.recordSpending(amountCents: 1500), throwsA(isA<NotEnoughMoney>()));
    await treasure.recordSpending(amountCents: 150, note: 'Eis');
    expect(treasure.balances.free, 850);
    expect(treasure.ledger.first.note, 'Eis');
  });

  test('Zurücklegen für einen Wunschschatz, zurücknehmen und einlösen', () async {
    await budget.bookManual('kind', amountCents: 2500);
    await treasure.load();
    await treasure.createGoal(title: 'Fußball', targetCents: 2000);
    await treasure.createGoal(title: 'Buch', targetCents: 800);
    var ball = treasure.openGoals.first;
    expect(() => treasure.redeemGoal(ball), throwsStateError);

    await treasure.saveForGoal(ball, 1500);
    ball = treasure.openGoals.first;
    expect(ball.savedCents, 1500);
    expect(treasure.balances.free, 1000);
    expect(treasure.balances.save, 1500);

    // Mehr, als noch fehlt, und mehr, als frei ist, geht nicht.
    expect(() => treasure.saveForGoal(ball, 600), throwsA(isA<GoalNeedsLess>()));
    final book = treasure.openGoals.last;
    expect(() => treasure.saveForGoal(book, 1100), throwsA(isA<NotEnoughMoney>()));

    await treasure.takeFromGoal(ball, 500);
    ball = treasure.openGoals.first;
    expect(ball.savedCents, 1000);
    expect(treasure.balances.free, 1500);
    expect(() => treasure.takeFromGoal(ball, 1200), throwsA(isA<NotEnoughMoney>()));

    await treasure.saveForGoal(ball, 1000);
    await treasure.redeemGoal(treasure.openGoals.first);
    expect(treasure.reachedGoals.single.title, 'Fußball');
    expect(treasure.balances.save, 0);
    expect(treasure.balances.free, 500);
  });

  test('Gelöschter Wunschschatz: zurückgelegtes Geld ist wieder frei', () async {
    await budget.bookManual('kind', amountCents: 1000);
    await treasure.load();
    await treasure.createGoal(title: 'Buch', targetCents: 800);
    await treasure.saveForGoal(treasure.openGoals.single, 600);
    expect(treasure.balances.free, 400);
    await treasure.deleteGoal(treasure.openGoals.single);
    expect(treasure.goals, isEmpty);
    expect(treasure.balances.free, 1000);
    expect(treasure.balances.save, 0);
  });
}
