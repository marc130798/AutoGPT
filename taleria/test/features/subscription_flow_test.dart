import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Abo-Rechte: Gratis-Inseln, verschlossene Premium-Inseln, Abo-Seite und
/// Grenze von einem Kinder-Profil (CLAUDE.md Abschnitt 8).
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

  testWidgets('Kinderbereich ohne Abo: Wunschinsel verschlossen, Hinweis auf die Eltern, kein Preis', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    final content = FakeContent();
    final progress = FakeProgress(content)
      ..premium = false
      ..completedIslands.addAll(['island-hafen', 'island-tauschinsel']);

    await tester.pumpWidget(buildTestApp(backend: backend, content: content, progress: progress));
    await tester.pumpAndSettle();
    await tapText(tester, 'Ich habe einen Code');
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tapText(tester, 'An Bord gehen');
    await tapText(tester, 'Zur Karte');

    expect(find.text('Die nächste Insel ist noch verschlossen.'), findsOneWidget);
    expect(find.byKey(const ValueKey('fog-practice')), findsOneWidget, reason: 'Kontrollfahrt statt Warten');
    await tapKey(tester, 'island-wunschinsel');
    expect(
      find.text('Diese Insel ist noch verschlossen. Deine Eltern können sie im Leuchtturm freischalten.'),
      findsOneWidget,
    );
    expect(find.textContaining('€'), findsNothing, reason: 'keine Preise im Kinderbereich');
    expect(find.textContaining('abschließen'), findsNothing, reason: 'kein Kauf-Knopf im Kinderbereich');

    // Gratis-Inseln bleiben offen (vorher den Hinweis unten verschwinden lassen).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tapKey(tester, 'island-hafen');
    expect(find.byKey(const ValueKey('island-scene')), findsOneWidget);
  });

  Future<FakeBackend> openLighthouse(WidgetTester tester, {bool premium = false}) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    backend.addChild(parent);
    if (premium) backend.premiumParents.add(parent.id);
    final content = FakeContent();
    final progress = FakeProgress(content)..premium = premium;
    backend.signInAs('eltern@test.invalid');
    await tester.pumpWidget(buildTestApp(backend: backend, content: content, progress: progress));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('pin-gate-field')), '2468');
    await tapText(tester, 'Öffnen');
    return backend;
  }

  testWidgets('Abo-Seite: Basis, Kaufen folgt, Test-Abo ein- und ausschalten', (tester) async {
    final backend = await openLighthouse(tester);
    await tapKey(tester, 'open-subscription');
    expect(find.text('Basis (kostenlos)'), findsOneWidget);
    expect(find.text('Hafen und Tauschinsel'), findsOneWidget);
    final buy = tester.widget<FilledButton>(find.byKey(const ValueKey('subscription-buy')));
    expect(buy.onPressed, isNull, reason: 'Kaufen kommt mit RevenueCat');

    await tapKey(tester, 'test-premium');
    expect(backend.premiumParents, isNotEmpty);
    expect(find.text('Abo ist aktiv'), findsOneWidget);
    expect(find.text('Test-Abo (nur in der Testumgebung)'), findsOneWidget);

    await tapKey(tester, 'test-premium');
    expect(backend.premiumParents, isEmpty);
  });

  testWidgets('Gratis: ein Kinder-Profil, für das zweite geht es zum Abo', (tester) async {
    await openLighthouse(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Weitere Kinder-Profile'), findsOneWidget);
    await tapText(tester, 'Zum Abo');
    expect(find.text('Basis (kostenlos)'), findsOneWidget);
  });

  testWidgets('Mit Abo: weiteres Kinder-Profil anlegen geht', (tester) async {
    await openLighthouse(tester, premium: true);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Weitere Kinder-Profile'), findsNothing);
    expect(find.byKey(const ValueKey('nickname-field')), findsOneWidget);
  });

  testWidgets('Leuchtturm-Fortschritt: Wunschinsel „Mit dem Abo“', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    backend.addChild(parent);
    final content = FakeContent();
    final progress = FakeProgress(content)
      ..premium = false
      ..completedIslands.addAll(['island-hafen', 'island-tauschinsel']);
    backend.signInAs('eltern@test.invalid');
    await tester.pumpWidget(buildTestApp(backend: backend, content: content, progress: progress));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('pin-gate-field')), '2468');
    await tapText(tester, 'Öffnen');
    await tapText(tester, 'Mila');
    await tapKey(tester, 'child-progress');
    await scrollTo(tester, find.byKey(const ValueKey('report-wunschinsel')));
    expect(
      find.descendant(of: find.byKey(const ValueKey('report-wunschinsel')), matching: find.text('Mit dem Abo')),
      findsOneWidget,
    );
  });
}
