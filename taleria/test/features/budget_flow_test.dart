import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/budget_models.dart';
import 'package:taleria/domain/money.dart';
import 'package:taleria/features/common/texts.dart' show formatDate;

import '../fake_budget.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Taschengeld und Aufgaben über zwei Geräte: Eltern und Kind.
void main() {
  Future<void> tapText(WidgetTester tester, String text) async {
    if (find.text(text).evaluate().isEmpty) {
      // Liste der obersten Seite (darunter liegen noch die vorigen Seiten).
      await tester.dragUntilVisible(find.text(text), find.byType(Scrollable).last, const Offset(0, -200));
    }
    await Scrollable.ensureVisible(tester.element(find.text(text).last), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(ValueKey(key)), text);
    await tester.pump();
  }

  /// Baut die vorige App ganz ab, als würde ein anderes Gerät benutzt.
  Future<void> switchDevice(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  Future<void> openParentBudget(WidgetTester tester, FakeBackend backend, FakeBudget budget) async {
    await switchDevice(tester);
    backend.signInAs('eltern@test.invalid');
    await tester.pumpWidget(buildTestApp(backend: backend, budget: budget));
    await tester.pumpAndSettle();
    await enter(tester, 'pin-gate-field', '2468');
    await tapText(tester, 'Öffnen');
    await tapText(tester, 'Mila');
    await tapText(tester, 'Taschengeld und Aufgaben');
  }

  Future<void> openChildDevice(WidgetTester tester, FakeBackend backend, FakeBudget budget, String childId) async {
    backend.codes['ABCD2345'] = (childId: childId, validUntil: DateTime(2026), used: false);
    await switchDevice(tester);
    backend.currentUser = null;
    await tester.pumpWidget(buildTestApp(backend: backend, budget: budget));
    await tester.pumpAndSettle();
    await tapText(tester, 'Ich habe einen Code');
    await enter(tester, 'child-code-field', 'ABCD2345');
    await tapText(tester, 'An Bord gehen');
  }

  testWidgets('Taschengeld, Aufgabe, Truhen und Wunschschatz über zwei Geräte', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    // Die erste Zahlung „heute“ ist im Test sofort fällig.
    final budget = FakeBudget()..now = DateTime.now().add(const Duration(minutes: 1));

    // --- Eltern: Taschengeld und Aufgabe ---
    await openParentBudget(tester, backend, budget);
    expect(find.text('Kein Taschengeld festgelegt.'), findsOneWidget);
    await tapText(tester, 'Taschengeld festlegen');
    await enter(tester, 'allowance-amount', '5');
    await tester.tap(find.byKey(const ValueKey('allowance-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('${formatCents(500)} pro Woche'), findsOneWidget);

    await tapText(tester, 'Aufgabe anlegen');
    await enter(tester, 'task-title', 'Rasen mähen');
    await enter(tester, 'task-reward', '3');
    await tester.tap(find.byKey(const ValueKey('task-save')));
    await tester.pumpAndSettle();
    expect(find.text('Rasen mähen'), findsOneWidget);

    // --- Kind: Auftrag melden ---
    await openChildDevice(tester, backend, budget, mila.id);
    await tester.dragUntilVisible(find.text('1 offener Auftrag'), find.byType(Scrollable).first, const Offset(0, -200));
    expect(find.text('1 offener Auftrag'), findsOneWidget);
    await tapText(tester, 'Aufträge');
    expect(find.text('Rasen mähen'), findsOneWidget);
    expect(find.text('+${formatCents(300)}'), findsOneWidget);
    await tapText(tester, 'Erledigt!');
    expect(find.text('Super! Jetzt müssen deine Eltern bestätigen.'), findsOneWidget);
    expect(find.text('Wartet auf deine Eltern'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('child-home-open-tasks')), findsNothing, reason: 'Auftrag ist gemeldet');

    // --- Kind: Truhen, Umbuchen, Wunschschatz ---
    await tapText(tester, 'Schatztruhe');
    expect(find.text(formatCents(500)), findsWidgets, reason: 'Taschengeld in der Bordkasse');
    await tapText(tester, 'Geld in eine andere Truhe legen');
    await enter(tester, 'amount-dialog-amount', '20');
    await tester.tap(find.byKey(const ValueKey('amount-dialog-submit')));
    await tester.pumpAndSettle();
    expect(find.text('So viel ist nicht in der Truhe.'), findsOneWidget);
    await enter(tester, 'amount-dialog-amount', '2');
    await tester.tap(find.byKey(const ValueKey('amount-dialog-submit')));
    await tester.pumpAndSettle();
    expect(budget.balance(mila.id, Pot.spend), 300);
    expect(budget.balance(mila.id, Pot.save), 200);

    // Die Truhen stehen oben, das Taschengeld darunter (Liste der obersten Seite).
    await tester.dragUntilVisible(
      find.textContaining('Dein Taschengeld'),
      find.byType(Scrollable).last,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Dein Taschengeld: ${formatCents(500)} pro Woche'), findsOneWidget);
    expect(find.textContaining('Heuer'), findsNothing, reason: 'Kinder verstehen „Taschengeld“ besser');

    await tapText(tester, 'Neuer Wunschschatz');
    await enter(tester, 'amount-dialog-title', 'Ball');
    await enter(tester, 'amount-dialog-amount', '2');
    await tester.tap(find.byKey(const ValueKey('amount-dialog-submit')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Einlösen');
    expect(find.text('Ball einlösen?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Einlösen').last);
    await tester.pumpAndSettle();
    expect(find.text('Erfüllt!'), findsOneWidget);
    expect(budget.balance(mila.id, Pot.save), 0);

    // --- Eltern: bestätigen ---
    await openParentBudget(tester, backend, budget);
    expect(find.text('1 Aufgabe wartet auf Bestätigung'), findsOneWidget);
    await tapText(tester, 'Bestätigen');
    expect(budget.balance(mila.id, Pot.spend), 600, reason: '3 € Rest plus 3 € Belohnung');
    expect(find.text('Bestätigt am ${formatDate(budget.now)}'), findsOneWidget);
    expect(find.text('${formatCents(300)} auf „Ausgeben“ gebucht'), findsOneWidget);
  });

  testWidgets('Aufträge zeigen, wann sie erledigt und bestätigt wurden', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    final budget = FakeBudget()..now = DateTime(2026, 10, 9, 12);
    for (final (title, cents) in [('Rasen mähen', 500), ('Zimmer aufräumen', 0)]) {
      await budget.createTask(
        parentId: parent.id,
        childId: mila.id,
        title: title,
        rewardCents: cents,
        isChore: cents == 0,
      );
    }
    String id(String title) => budget.tasks[mila.id]!.firstWhere((t) => t.title == title).id;
    await budget.submitTask(id('Rasen mähen'));
    await budget.submitTask(id('Zimmer aufräumen'));
    budget.now = DateTime(2026, 10, 10, 9);
    await budget.reviewTask(id('Rasen mähen'), approve: true);

    await openChildDevice(tester, backend, budget, mila.id);
    await tapText(tester, 'Aufträge');
    // Erledigte Aufträge stehen unten.
    await tester.dragUntilVisible(
      find.text('Erledigt am 09.10.2026, bestätigt am 10.10.2026'),
      find.byType(Scrollable).last,
      const Offset(0, -200),
    );
    expect(find.text('Erledigt am 09.10.2026, bestätigt am 10.10.2026'), findsOneWidget);
    expect(find.text('Die ${formatCents(500)} kamen in deine Bordkasse.'), findsOneWidget);
    expect(find.text('Gemeldet am 09.10.2026'), findsOneWidget, reason: 'Zimmer wartet auf die Eltern');

    await openParentBudget(tester, backend, budget);
    expect(find.text('Gemeldet am 09.10.2026'), findsOneWidget);
    expect(find.text('Bestätigt am 10.10.2026'), findsOneWidget);
  });

  testWidgets('Truhe antippen: So setzt sich der Stand zusammen', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    final budget = FakeBudget()..now = DateTime(2026, 10, 9, 12);
    budget.allowances[mila.id] = AllowanceRule(
      amountCents: 500,
      interval: AllowanceInterval.weekly,
      nextRunAt: DateTime(2026, 10, 9, 8),
    );
    await budget.processDueAllowances(mila.id);
    await budget.createTask(
      parentId: parent.id,
      childId: mila.id,
      title: 'Rasen mähen',
      rewardCents: 300,
      isChore: false,
    );
    await budget.reviewTask(budget.tasks[mila.id]!.single.id, approve: true);
    await budget.movePots(mila.id, from: Pot.spend, to: Pot.save, amountCents: 200);
    await budget.recordSpending(mila.id, pot: Pot.spend, amountCents: 150, note: 'Eis');

    Finder inRow(String key, String text) => find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

    await openChildDevice(tester, backend, budget, mila.id);
    await tapText(tester, 'Schatztruhe');
    await tester.tap(find.byKey(const ValueKey('pot-open-spend')));
    await tester.pumpAndSettle();
    expect(find.text('Bordkasse'), findsWidgets);
    expect(inRow('pot-sum-in-allowance', '+${formatCents(500)}'), findsOneWidget);
    expect(inRow('pot-sum-in-task', '+${formatCents(300)}'), findsOneWidget);
    expect(inRow('pot-sum-out-transfer', formatCents(-200)), findsOneWidget);
    expect(inRow('pot-sum-out-purchase', formatCents(-150)), findsOneWidget);
    expect(find.byKey(const ValueKey('pot-sum-older')), findsNothing);
    expect(find.text('Jetzt in der Bordkasse'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('pot-sum-total'))).data,
      formatCents(450),
      reason: '5 € + 3 € − 2 € − 1,50 €',
    );
    await tester.dragUntilVisible(find.text('Eis'), find.byType(Scrollable).last, const Offset(0, -200));
    expect(find.text('Rasen mähen'), findsOneWidget, reason: 'Belohnung steht mit Namen in der Liste');

    // Die Schatztruhe hat nur das Umgepackte.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('pot-open-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pot-open-save')));
    await tester.pumpAndSettle();
    expect(inRow('pot-sum-in-transfer', '+${formatCents(200)}'), findsOneWidget);
    expect(find.text('Aus anderen Truhen hergelegt'), findsOneWidget);

    // Die Glückstruhe ist noch leer.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('pot-open-give')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pot-open-give')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hier ist noch nichts passiert.'), findsOneWidget);
  });

  testWidgets('Eltern lehnen ab, Kind sieht die Nachricht und meldet erneut', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    final budget = FakeBudget();
    await budget.createTask(
      parentId: parent.id,
      childId: mila.id,
      title: 'Abwaschen',
      rewardCents: 200,
      isChore: false,
    );
    await budget.submitTask(budget.tasks[mila.id]!.single.id);

    await openParentBudget(tester, backend, budget);
    await tapText(tester, 'Ablehnen');
    await enter(tester, 'reject-note', 'Die Pfanne fehlt noch');
    await tester.tap(find.byKey(const ValueKey('reject-submit')));
    await tester.pumpAndSettle();
    expect(budget.tasks[mila.id]!.single.status, TaskStatus.rejected);

    await openChildDevice(tester, backend, budget, mila.id);
    await tapText(tester, 'Aufträge');
    expect(find.text('Noch nicht ganz: Die Pfanne fehlt noch'), findsOneWidget);
    await tapText(tester, 'Nochmal melden');
    expect(budget.tasks[mila.id]!.single.status, TaskStatus.submitted);
  });

  testWidgets('Korrektur der Eltern bringt keine Truhe ins Minus', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    final budget = FakeBudget();

    await openParentBudget(tester, backend, budget);
    await tapText(tester, 'Korrektur buchen');
    await enter(tester, 'amount-dialog-amount', '-2,50');
    await tester.tap(find.byKey(const ValueKey('amount-dialog-submit')));
    await tester.pumpAndSettle();
    expect(find.text('So viel ist nicht in der Truhe.'), findsOneWidget);

    await enter(tester, 'amount-dialog-amount', '4,20');
    await tester.tap(find.byKey(const ValueKey('amount-dialog-submit')));
    await tester.pumpAndSettle();
    expect(budget.balance(mila.id, Pot.spend), 420);
  });
}
