import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/budget_models.dart';
import 'package:taleria/domain/money.dart';

import '../fake_budget.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Taschengeld und Aufgaben über zwei Geräte: Eltern und Kind.
void main() {
  Future<void> tapText(WidgetTester tester, String text) async {
    if (find.text(text).evaluate().isEmpty) {
      await tester.dragUntilVisible(find.text(text), find.byType(Scrollable).first, const Offset(0, -200));
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
    expect(find.text(formatCents(500)), findsWidgets, reason: 'Heuer in der Bordkasse');
    expect(find.textContaining('Deine Heuer: ${formatCents(500)} pro Woche'), findsOneWidget);

    await tapText(tester, 'Umbuchen');
    await enter(tester, 'amount-dialog-amount', '20');
    await tester.tap(find.byKey(const ValueKey('amount-dialog-submit')));
    await tester.pumpAndSettle();
    expect(find.text('So viel ist nicht in der Truhe.'), findsOneWidget);
    await enter(tester, 'amount-dialog-amount', '2');
    await tester.tap(find.byKey(const ValueKey('amount-dialog-submit')));
    await tester.pumpAndSettle();
    expect(budget.balance(mila.id, Pot.spend), 300);
    expect(budget.balance(mila.id, Pot.save), 200);

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
    expect(find.text('Bestätigt'), findsOneWidget);
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
