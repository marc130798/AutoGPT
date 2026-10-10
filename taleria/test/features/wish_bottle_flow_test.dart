import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/budget_models.dart';

import '../fake_budget.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Wunschflasche in der Schatztruhe: Wunsch einstecken, warten, entscheiden.
void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.dragUntilVisible(finder, find.byType(Scrollable).first, const Offset(0, -200));
    }
    await Scrollable.ensureVisible(tester.element(finder.last), alignment: 0.5);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await scrollTo(tester, find.text(text));
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await scrollTo(tester, find.byKey(ValueKey(key)));
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  /// Kind auf seinem Gerät, auf der Startseite.
  Future<({FakeBudget budget, String childId})> startOnHome(
    WidgetTester tester, {
    void Function(FakeBudget budget, String childId)? prepare,
  }) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    final budget = FakeBudget();
    prepare?.call(budget, mila.id);
    await tester.pumpWidget(buildTestApp(backend: backend, budget: budget));
    await tester.pumpAndSettle();
    await tapText(tester, 'Ich habe einen Code');
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tapText(tester, 'An Bord gehen');
    return (budget: budget, childId: mila.id);
  }

  testWidgets('Vor der Wunschinsel gibt es keine Wunschflaschen in der Schatztruhe', (tester) async {
    await startOnHome(tester);
    await tapText(tester, 'Schatztruhe');
    await scrollTo(tester, find.text('Kassenbuch'));
    expect(find.text('Wunschflaschen'), findsNothing);
  });

  testWidgets('Wunsch einstecken, nach einer Nacht entscheiden: Wunschschatz oder loslassen', (tester) async {
    final (:budget, :childId) = await startOnHome(tester, prepare: (b, id) => b.wishUnlocked.add(id));
    await tapText(tester, 'Schatztruhe');
    await scrollTo(tester, find.text('Wunschflaschen'));
    expect(find.text('Gerade treibt keine Flasche auf dem Meer.'), findsOneWidget);

    // Zwei kleine Wünsche, einer mit Preis.
    for (final (title, price) in [('Comic', '4,50'), ('Sticker', '')]) {
      await tapKey(tester, 'wish-new');
      await tester.enterText(find.byKey(const ValueKey('wish-title')), title);
      await tester.enterText(find.byKey(const ValueKey('wish-price')), price);
      await tester.pump();
      expect(find.text('Du schläfst eine Nacht drüber.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('wish-submit')));
      await tester.pumpAndSettle();
    }
    expect(budget.wishBottles[childId], hasLength(2));
    expect(budget.wishBottles[childId]!.first.priceCents, 450);
    expect(find.textContaining('Treibt noch bis'), findsNWidgets(2));
    expect(find.text('Ja, Wunschschatz daraus machen'), findsNothing, reason: 'erst nach der Wartezeit');

    // Am nächsten Tag: beide angespült. Startseite zeigt den Hinweis.
    budget.now = budget.now.add(const Duration(days: 1));
    await goBack(tester);
    expect(find.text('2 Wunschflaschen sind angespült! Schau in der Schatztruhe nach.'), findsOneWidget);

    await tapText(tester, 'Schatztruhe');
    await scrollTo(tester, find.text('Willst du „Comic“ noch?'));
    await tapText(tester, 'Ja, Wunschschatz daraus machen');
    expect(budget.goals[childId]!.single.title, 'Comic');
    expect(budget.goals[childId]!.single.targetCents, 450);

    await scrollTo(tester, find.text('Willst du „Sticker“ noch?'));
    await tapText(tester, 'Loslassen');
    expect(budget.wishBottles[childId]!.map((b) => b.decision), [WishDecision.converted, WishDecision.dropped]);
    expect(find.text('Gerade treibt keine Flasche auf dem Meer.'), findsOneWidget);

    await goBack(tester);
    expect(find.byKey(const ValueKey('child-home-wish-due')), findsNothing);
  });

  testWidgets('Großer Wunsch ohne Preis: eine Woche warten, dann Preis eingeben', (tester) async {
    final (:budget, :childId) = await startOnHome(tester, prepare: (b, id) => b.wishUnlocked.add(id));
    await tapText(tester, 'Schatztruhe');
    await tapKey(tester, 'wish-new');
    await tester.enterText(find.byKey(const ValueKey('wish-title')), 'Fahrrad');
    await tester.enterText(find.byKey(const ValueKey('wish-price')), '250');
    await tester.pump();
    expect(find.text('Du schläfst eine Woche drüber.'), findsOneWidget, reason: 'ab 20 € schlägt die App groß vor');
    await tester.enterText(find.byKey(const ValueKey('wish-price')), '');
    await tester.pump();
    await tester.tap(find.text('Großer Wunsch'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('wish-submit')));
    await tester.pumpAndSettle();
    expect(budget.wishBottles[childId]!.single.isBig, isTrue);

    budget.now = budget.now.add(const Duration(days: 6));
    await goBack(tester);
    expect(find.byKey(const ValueKey('child-home-wish-due')), findsNothing, reason: 'nach 6 Tagen treibt sie noch');

    budget.now = budget.now.add(const Duration(days: 1));
    await tapText(tester, 'Schatztruhe');
    await tapText(tester, 'Ja, Wunschschatz daraus machen');
    expect(find.text('Wie viel kostet „Fahrrad“?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '120');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('amount-dialog-submit')));
    await tester.pumpAndSettle();
    expect(budget.goals[childId]!.single.targetCents, 12000);
  });
}
