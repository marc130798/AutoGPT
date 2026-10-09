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

  test('Umbuchen und Ausgeben: nie ins Minus, Fehler schon in der App', () async {
    await budget.bookManual('kind', pot: Pot.spend, amountCents: 1000);
    await treasure.load();
    await treasure.move(from: Pot.spend, to: Pot.save, amountCents: 600);
    expect(treasure.balances.spend, 400);
    expect(treasure.balances.save, 600);

    expect(() => treasure.move(from: Pot.spend, to: Pot.give, amountCents: 500), throwsA(isA<NotEnoughMoney>()));
    expect(() => treasure.recordSpending(pot: Pot.save, amountCents: 100), throwsArgumentError);
    await treasure.recordSpending(pot: Pot.spend, amountCents: 150, note: 'Eis');
    expect(treasure.balances.spend, 250);
    expect(treasure.ledger.first.note, 'Eis');
  });

  test('Wunschschatz einlösen, wenn die Schatztruhe reicht', () async {
    await budget.bookManual('kind', pot: Pot.save, amountCents: 1500);
    await treasure.load();
    await treasure.createGoal(title: 'Fußball', targetCents: 2000);
    final goal = treasure.openGoals.single;
    expect(() => treasure.redeemGoal(goal), throwsStateError);

    await budget.bookManual('kind', pot: Pot.save, amountCents: 500);
    await treasure.load();
    await treasure.redeemGoal(treasure.openGoals.single);
    expect(treasure.reachedGoals, hasLength(1));
    expect(treasure.balances.save, 0);
  });
}
