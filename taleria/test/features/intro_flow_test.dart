import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/avatar.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/features/common/avatar_view.dart';

import '../fakes.dart';
import '../test_helpers.dart';

/// Das Intro so, wie ein Kind es auf seinem eigenen Gerät durchspielt.
void main() {
  Future<void> tapText(WidgetTester tester, String text) async {
    // Lange Listen bauen ihre unteren Einträge erst beim Scrollen.
    if (find.text(text).evaluate().isEmpty) {
      await tester.dragUntilVisible(find.text(text), find.byType(Scrollable).first, const Offset(0, -200));
    }
    // In die Mitte scrollen, damit der Tipp nicht auf einem Knopf am Rand landet.
    await Scrollable.ensureVisible(tester.element(find.text(text).last), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// Startet die App auf einem Kinder-Gerät, dessen Kind das Intro noch vor sich hat.
  Future<FakeBackend> startNewChild(WidgetTester tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent, onboardingCompleted: false);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    await tester.pumpWidget(buildTestApp(backend: backend));
    await tester.pumpAndSettle();
    await tapText(tester, 'Ich habe einen Code');
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tapText(tester, 'An Bord gehen');
    return backend;
  }

  Future<void> playUntilWish(WidgetTester tester) async {
    // Film (Platzhalter)
    expect(find.text('Film folgt'), findsOneWidget);
    await tapText(tester, 'Weiter');

    // Talo und Tala erzählen
    expect(find.textContaining('Ich bin Talo'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tapText(tester, 'Weiter');
    }
    expect(find.textContaining('Willst du in unsere Crew?'), findsOneWidget);
    await tapText(tester, 'Ja, ich bin dabei!');

    // Avatar
    expect(find.text('Wie siehst du aus?'), findsOneWidget);
    await tapText(tester, 'Locken');
    await tapText(tester, 'Strohhut');
    await tapText(tester, 'So sehe ich aus!');

    // Schiffstaufe: zu kurzer Name, dann Vorschlag
    expect(find.text('Taufe dein Schiff'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('ship-name-field')), 'X');
    await tapText(tester, 'Schiff taufen');
    expect(find.text('Der Name braucht mindestens 2 Zeichen.'), findsOneWidget);
    await tapText(tester, 'Goldmöwe');
    await tapText(tester, 'Schiff taufen');

    // Rundgang
    expect(find.text('Die Karte'), findsOneWidget);
    await tapText(tester, 'Weiter');
    expect(find.text('Die Schatztruhe'), findsOneWidget);
    await tapText(tester, 'Weiter');
    expect(find.text('Das Logbuch'), findsOneWidget);
    await tapText(tester, 'Verstanden!');

    expect(find.text('Dein erster Wunschschatz'), findsOneWidget);
  }

  testWidgets('Intro komplett: Avatar, Schiff, Wunschschatz, Seemeilen, Karte', (tester) async {
    final backend = await startNewChild(tester);
    await playUntilWish(tester);

    // Wunschschatz: erst ungültig, dann richtig
    await tapText(tester, 'In die Schatztruhe legen');
    expect(find.text('Schreib mindestens 2 Zeichen.'), findsOneWidget);
    expect(find.text('Bitte eine ganze Zahl von 1 bis 10000.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('wish-title-field')), 'Fahrradhelm');
    await tester.enterText(find.byKey(const ValueKey('wish-amount-field')), '40');
    await tapText(tester, 'In die Schatztruhe legen');

    // Abschluss
    expect(find.text('Willkommen in der Crew, Mila!'), findsOneWidget);
    expect(find.text('Dein Rang: Schiffsjunge'), findsOneWidget);
    expect(find.text('+50 Seemeilen'), findsOneWidget);
    expect(find.text('Dein Wunschschatz liegt in der Schatztruhe.'), findsOneWidget);

    // Karte rollt sich auf
    await tapText(tester, 'Karte öffnen');
    expect(find.text('Die Karte ist offen!'), findsOneWidget);
    expect(find.byKey(const ValueKey('placeholder:map.background')), findsOneWidget);
    await tapText(tester, "Los geht's");

    // Kinderbereich mit Schiffsname
    expect(find.text('Willkommen an Bord, Mila!'), findsOneWidget);
    expect(find.text('Dein Schiff: Goldmöwe'), findsOneWidget);

    // Gespeichert wurde alles auf dem Server, Geld in Cent.
    final mila = backend.children.single;
    expect(mila.onboardingCompleted, isTrue);
    expect(mila.shipName, 'Goldmöwe');
    expect(mila.avatar?.hat, Hat.straw);
    expect(mila.avatar?.hairStyle, HairStyle.curly);
    expect(backend.savingsGoals.single.title, 'Fahrradhelm');
    expect(backend.savingsGoals.single.targetCents, 4000);
    expect(backend.xpByChild[mila.id], 50);
  });

  testWidgets('Wunschschatz überspringen geht auch', (tester) async {
    final backend = await startNewChild(tester);
    await playUntilWish(tester);
    await tapText(tester, 'Weiß ich noch nicht');
    expect(find.text('Willkommen in der Crew, Mila!'), findsOneWidget);
    expect(find.text('Dein Wunschschatz liegt in der Schatztruhe.'), findsNothing);
    expect(backend.savingsGoals, isEmpty);
    expect(backend.children.single.onboardingCompleted, isTrue);
  });

  testWidgets('Ohne Verbindung bleibt das Intro beim Avatar stehen', (tester) async {
    final backend = await startNewChild(tester);
    await tapText(tester, 'Weiter');
    for (var i = 0; i < 4; i++) {
      await tapText(tester, 'Weiter');
    }
    await tapText(tester, 'Ja, ich bin dabei!');
    backend.failWith = FailureKind.network;
    await tapText(tester, 'So sehe ich aus!');
    expect(find.textContaining('Keine Verbindung zum Server'), findsOneWidget);
    expect(find.text('Wie siehst du aus?'), findsOneWidget);
  });

  testWidgets('Knöpfe im Avatar-Baukasten sind groß genug', (tester) async {
    await startNewChild(tester);
    await tapText(tester, 'Weiter');
    for (var i = 0; i < 4; i++) {
      await tapText(tester, 'Weiter');
    }
    await tapText(tester, 'Ja, ich bin dabei!');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets('Tier-Avatar: Fellfarbe statt Frisur', (tester) async {
    final backend = await startNewChild(tester);
    await tapText(tester, 'Weiter');
    for (var i = 0; i < 4; i++) {
      await tapText(tester, 'Weiter');
    }
    await tapText(tester, 'Ja, ich bin dabei!');
    expect(find.text('Frisur'), findsOneWidget);
    await tapText(tester, 'Katze');
    expect(find.text('Fellfarbe'), findsOneWidget);
    expect(find.text('Frisur'), findsNothing);
    expect(find.text('Haarfarbe'), findsNothing);
    await tapText(tester, 'So sehe ich aus!');
    expect(backend.children.single.avatar?.species, Species.cat);
  });

  testWidgets('Jeder Avatar lässt sich zeichnen', (tester) async {
    for (final species in Species.values) {
      for (final hat in Hat.values) {
        for (final hair in HairStyle.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: AvatarView(
                avatar: AvatarConfig(species: species, hat: hat, hairStyle: hair),
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: '$species $hat $hair');
        }
      }
    }
  });
}
