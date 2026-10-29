import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/features/map/sea_critters.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Lebendigere App: Talo und Tala reagieren, Satz des Tages, Tiere im Meer.
void main() {
  Future<void> startOnHome(WidgetTester tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    final content = FakeContent();
    await tester.pumpWidget(buildTestApp(backend: backend, content: content, progress: FakeProgress(content)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ich habe einen Code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tester.tap(find.text('An Bord gehen'));
    await tester.pumpAndSettle();
  }

  testWidgets('Talo und Tala antippen: Sie sagen etwas, jedes Mal den nächsten Satz', (tester) async {
    await startOnHome(tester);
    final talo = find.byKey(const ValueKey('lively-character.talo'));
    await tester.tap(talo);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Ahoi! Schön, dass du da bist.'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lively-says-character.talo')), findsNothing, reason: 'die Blase geht wieder');

    await tester.tap(talo);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Ein guter Kapitän plant die Fahrt. Und sein Geld!'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('lively-character.tala')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hallo! Ich passe auf die Taler auf.'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Satz des Tages steht auf der Startseite', (tester) async {
    await startOnHome(tester);
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
  });

  testWidgets('Tiere im Meer lassen sich antippen', (tester) async {
    await startOnHome(tester);
    await tester.ensureVisible(find.text('Zur Karte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zur Karte'));
    await tester.pumpAndSettle();
    final critters = find.byType(SeaCritter);
    expect(critters, findsWidgets);
    await tester.ensureVisible(critters.first);
    await tester.pumpAndSettle();
    await tester.tap(critters.first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
