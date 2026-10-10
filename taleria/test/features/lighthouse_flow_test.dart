import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/learning_status.dart';

import '../fake_budget.dart';
import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Leuchtturm: Fortschritt, Lernstand, Kombüsen-Fragen und offene Aufgaben.
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

  TopicLearning topic(FakeContent content, int number, {int secure = 0, int learning = 0, int shaky = 0}) {
    final station = content.station('hafen', number);
    return TopicLearning(
      stationId: station.id,
      islandId: station.islandId,
      answered: secure + learning + shaky,
      secure: secure,
      learning: learning,
      shaky: shaky,
    );
  }

  /// Eltern im Leuchtturm, Mila hat Station 2, Ankerplatz 1 und Station 3 geschafft.
  Future<({FakeContent content, FakeProgress progress, FakeBudget budget, String childId})> openLighthouse(
    WidgetTester tester, {
    Future<void> Function(FakeBudget, String childId)? prepareBudget,
  }) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    final content = FakeContent();
    final progress = FakeProgress(content)
      ..completeStations('hafen', except: 7)
      ..lastActiveAt = DateTime(2026, 10, 10)
      ..streakWeeks = 2;
    progress.learning
      ..[content.station('hafen', 2).id] = topic(content, 2, secure: 1, shaky: 2)
      ..[content.station('hafen', 3).id] = topic(content, 3, secure: 3);
    final budget = FakeBudget();
    await prepareBudget?.call(budget, mila.id);
    backend.signInAs('eltern@test.invalid');
    await tester.pumpWidget(buildTestApp(backend: backend, content: content, progress: progress, budget: budget));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('pin-gate-field')), '2468');
    await tapText(tester, 'Öffnen');
    return (content: content, progress: progress, budget: budget, childId: mila.id);
  }

  testWidgets('Fortschritt pro Insel und Lernstand pro Thema', (tester) async {
    await openLighthouse(tester);
    expect(find.textContaining('Level 1 (Schiffsjunge)'), findsOneWidget, reason: 'Übersicht in der Kinderliste');
    await tapText(tester, 'Mila');
    await tapKey(tester, 'child-progress');

    expect(find.text('Mila: Fortschritt'), findsOneWidget);
    expect(find.text('Fortschritt: 50 Seemeilen'), findsOneWidget);
    expect(find.text('Serie: 2 Wochen'), findsOneWidget);
    expect(find.text('Zuletzt aktiv am 10.10.2026'), findsOneWidget);

    expect(find.text('4 von 11 Stationen geschafft'), findsOneWidget, reason: 'Intro, 2, Ankerplatz 1, 3');
    await scrollTo(tester, find.byKey(const ValueKey('topic-2')));
    expect(
      find.descendant(of: find.byKey(const ValueKey('topic-2')), matching: find.text('Wackelt noch')),
      findsOneWidget,
    );
    expect(find.descendant(of: find.byKey(const ValueKey('topic-3')), matching: find.text('Sicher')), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('topic-4')));
    expect(
      find.descendant(of: find.byKey(const ValueKey('topic-4')), matching: find.text('Noch nicht dran')),
      findsOneWidget,
    );

    await scrollTo(tester, find.byKey(const ValueKey('report-tauschinsel')));
    expect(find.text('Noch gesperrt'), findsWidgets);
    await scrollTo(tester, find.byKey(const ValueKey('report-spar-insel')));
    expect(find.text('Inhalt folgt'), findsWidgets);
  });

  testWidgets('Kombüsen-Fragen und Auftrag fürs echte Leben als Aufgabe', (tester) async {
    final (:content, :progress, :budget, :childId) = await openLighthouse(tester);
    await tapText(tester, 'Mila');
    await tapKey(tester, 'child-kitchen');

    expect(find.text('Gesprächsideen für den Familientisch, passend zu dem, was Mila gerade lernt.'), findsOneWidget);
    expect(find.text('Gerade dran'), findsOneWidget);
    final hafenPrompt = content.prompts.firstWhere((p) => p.islandId == 'island-hafen').text;
    expect(find.text('„$hafenPrompt“'), findsOneWidget);

    await scrollTo(tester, find.byKey(const ValueKey('real-life-hafen')));
    expect(find.text('Preis-Detektiv'), findsOneWidget);
    await tapKey(tester, 'real-life-create-hafen');
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: find.byKey(const ValueKey('task-title')), matching: find.byType(EditableText)),
          )
          .controller
          .text,
      'Preis-Detektiv',
    );
    await tester.enterText(find.byKey(const ValueKey('task-reward')), '1');
    await tester.tap(find.byKey(const ValueKey('task-save')));
    await tester.pumpAndSettle();

    expect(find.text('Aufgabe angelegt. Sie steht jetzt bei Mila unter den Aufträgen.'), findsOneWidget);
    expect(budget.tasks[childId]!.single.title, 'Preis-Detektiv');
    expect(budget.tasks[childId]!.single.rewardCents, 100);
  });

  testWidgets('Offene Aufgaben aller Kinder oben im Leuchtturm', (tester) async {
    await openLighthouse(
      tester,
      prepareBudget: (budget, childId) async {
        await budget.createTask(parentId: 'p', childId: childId, title: 'Abwaschen', rewardCents: 0, isChore: true);
        await budget.submitTask(budget.tasks[childId]!.single.id);
      },
    );
    expect(find.text('Wartet auf deine Bestätigung'), findsOneWidget);
    await tapText(tester, 'Wartet auf deine Bestätigung');
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('pending-overview')), matching: find.text('Mila')));
    await tester.pumpAndSettle();
    expect(find.text('Mila: Taschengeld und Aufgaben'), findsOneWidget);
    expect(find.text('Abwaschen'), findsOneWidget);
  });
}
