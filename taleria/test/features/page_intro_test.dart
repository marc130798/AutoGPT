import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Erklärungen auf den Menü-Seiten: beim ersten Besuch offen, danach
/// zugeklappt mit „?“-Knopf (Marcs Wunsch am 20.10.2026).
void main() {
  const badgesIntro = 'Für jede Insel, die du schaffst, bekommst du einen Orden.';
  const tasksIntro = 'Aufträge sind Aufgaben von deinen Eltern';
  final help = find.byKey(const ValueKey('page-intro-help'));

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    if (finder.evaluate().isEmpty) {
      await tester.dragUntilVisible(finder, find.byType(Scrollable).first, const Offset(0, -200));
    }
    await Scrollable.ensureVisible(tester.element(finder.last), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
  }

  testWidgets('Orden: erst offen, beim nächsten Besuch zu, „?“ klappt auf und zu', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    final content = FakeContent();
    final settings = FakeLocalSettings();
    await tester.pumpWidget(
      buildTestApp(backend: backend, content: content, progress: FakeProgress(content), settings: settings),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Ich habe einen Code');
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tapText(tester, 'An Bord gehen');

    // Erster Besuch: Talo erklärt, kein „?“.
    await tapText(tester, 'Orden');
    expect(find.textContaining(badgesIntro), findsOneWidget);
    expect(help, findsNothing);
    expect(settings.introsSeen, contains('${mila.id}/badges'));
    await back(tester);

    // Zweiter Besuch: zugeklappt, „?“ zeigt die Erklärung und klappt sie wieder zu.
    await tapText(tester, 'Orden');
    expect(find.textContaining(badgesIntro), findsNothing);
    expect(help, findsOneWidget);
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(find.textContaining(badgesIntro), findsOneWidget);
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(find.textContaining(badgesIntro), findsNothing);
    await back(tester);

    // Andere Seiten merken sich das für sich.
    await tapText(tester, 'Aufträge');
    expect(find.textContaining(tasksIntro), findsOneWidget);
    expect(help, findsNothing);
  });
}
