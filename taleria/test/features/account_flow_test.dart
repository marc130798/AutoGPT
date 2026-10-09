import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../test_helpers.dart';

/// Komplette Abläufe so, wie Marc sie auf dem Gerät durchklickt,
/// gegen den nachgebauten Server.
void main() {
  Future<void> enter(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(ValueKey(key)), text);
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    // Knöpfe weiter unten in langen Listen erst hinscrollen.
    if (find.text(text).evaluate().isEmpty) {
      await tester.scrollUntilVisible(find.text(text), 200, scrollable: find.byType(Scrollable).first);
    }
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('Eltern: registrieren, PIN, Kind anlegen, Code, Gerät übergeben, zurück mit PIN', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(buildTestApp(backend: backend));
    await tester.pumpAndSettle();

    // Start
    expect(find.text('Willkommen in Taleria'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('keine Finanzberatung'), 200);
    expect(find.textContaining('keine Finanzberatung'), findsOneWidget);
    await tapText(tester, 'Für Eltern: anmelden oder registrieren');

    // Registrieren ohne Einwilligung geht nicht.
    await enter(tester, 'email-field', 'eltern@test.invalid');
    await enter(tester, 'password-field', 'sehrgeheim123');
    await tapText(tester, 'Konto anlegen');
    expect(find.text('Ohne diese Einwilligung können wir kein Konto anlegen.'), findsOneWidget);
    expect(backend.accounts, isEmpty);

    // Newsletter ist nicht vorausgewählt.
    final marketing = tester.widget<CheckboxListTile>(find.byKey(const ValueKey('marketing-checkbox')));
    expect(marketing.value, isFalse);

    await tester.tap(find.byKey(const ValueKey('consent-checkbox')));
    await tapText(tester, 'Konto anlegen');

    // PIN festlegen
    expect(find.text('Eltern-PIN festlegen'), findsWidgets);
    await enter(tester, 'pin-field', '1234');
    await enter(tester, 'pin-repeat-field', '1234');
    await tapText(tester, 'PIN speichern');
    expect(find.textContaining('zu leicht zu erraten'), findsOneWidget);

    await enter(tester, 'pin-field', '2468');
    await enter(tester, 'pin-repeat-field', '2469');
    await tapText(tester, 'PIN speichern');
    expect(find.text('Die beiden PINs sind nicht gleich.'), findsOneWidget);

    await enter(tester, 'pin-repeat-field', '2468');
    await tapText(tester, 'PIN speichern');

    // Leuchtturm
    expect(find.text('Leuchtturm'), findsOneWidget);
    expect(find.text('Noch kein Kinder-Profil. Lege jetzt eins an.'), findsOneWidget);

    // Kind anlegen
    await tapText(tester, 'Kinder-Profil anlegen');
    await enter(tester, 'nickname-field', 'Mila');
    await tester.tap(find.byKey(const ValueKey('birth-year-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().year - 10}').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'Speichern');
    expect(find.text('Mila'), findsOneWidget);

    // Code erzeugen
    await tapText(tester, 'Mila');
    await tapText(tester, 'Anmeldecode erzeugen');
    expect(find.text('ABCD 2345'), findsOneWidget);
    expect(find.text('Gültig bis 14:35 Uhr und nur einmal nutzbar.'), findsOneWidget);

    // Gerät an Mila übergeben: Ein neues Kind startet mit dem Intro.
    await tapText(tester, 'Gerät an Mila übergeben');
    expect(find.text('Film folgt'), findsOneWidget);

    // Leuchtturm nur mit PIN, „Zurück an Bord“ ohne PIN
    await tester.tap(find.byKey(const ValueKey('lighthouse-button')));
    await tester.pumpAndSettle();
    expect(find.text('Bitte gib die Eltern-PIN ein.'), findsOneWidget);
    await tapText(tester, 'Zurück an Bord');
    expect(find.text('Film folgt'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lighthouse-button')));
    await tester.pumpAndSettle();
    await enter(tester, 'pin-gate-field', '1111');
    await tapText(tester, 'Öffnen');
    expect(find.text('Die PIN stimmt nicht.'), findsOneWidget);
    await enter(tester, 'pin-gate-field', '2468');
    await tapText(tester, 'Öffnen');
    expect(find.text('Kinder-Profile'), findsOneWidget);
    // Mila hat das Intro noch nicht beendet, das sehen die Eltern im Leuchtturm.
    expect(find.textContaining('Intro noch nicht abgeschlossen'), findsOneWidget);
  });

  testWidgets('Kinder-Gerät: Code eingeben, Kinderbereich, Leuchtturm-Hinweis', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);

    await tester.pumpWidget(buildTestApp(backend: backend));
    await tester.pumpAndSettle();
    await tapText(tester, 'Ich habe einen Code');

    await enter(tester, 'child-code-field', 'ABC');
    await tapText(tester, 'An Bord gehen');
    expect(find.text('Der Code hat 8 Zeichen.'), findsOneWidget);

    await enter(tester, 'child-code-field', 'WXYZ 2345');
    await tapText(tester, 'An Bord gehen');
    expect(find.textContaining('Dieser Code passt nicht'), findsOneWidget);

    await enter(tester, 'child-code-field', 'abcd 2345');
    await tapText(tester, 'An Bord gehen');
    expect(find.text('Willkommen an Bord, Mila!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lighthouse-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Er öffnet sich auf ihrem Gerät'), findsOneWidget);
  });

  testWidgets('Eltern melden das Kinder-Gerät ab: Kind sieht wieder den Start', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);

    await tester.pumpWidget(buildTestApp(backend: backend));
    await tester.pumpAndSettle();
    await tapText(tester, 'Ich habe einen Code');
    await enter(tester, 'child-code-field', 'ABCD2345');
    await tapText(tester, 'An Bord gehen');
    expect(find.text('Willkommen an Bord, Mila!'), findsOneWidget);

    backend.signOutDevice(backend.currentUser!.id);
    await tester.pumpAndSettle();
    expect(find.text('Willkommen in Taleria'), findsOneWidget);
  });

  testWidgets('Kinder-Profil und Konto löschen nur nach Rückfrage', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    backend.addChild(parent);
    backend.signInAs('eltern@test.invalid');

    await tester.pumpWidget(buildTestApp(backend: backend));
    await tester.pumpAndSettle();
    await enter(tester, 'pin-gate-field', '2468');
    await tapText(tester, 'Öffnen');

    await tapText(tester, 'Mila');
    await tapText(tester, 'Profil löschen');
    expect(find.text('Mila wirklich löschen?'), findsOneWidget);
    await tapText(tester, 'Abbrechen');
    expect(backend.children, hasLength(1));

    await tapText(tester, 'Profil löschen');
    await tapText(tester, 'Endgültig löschen');
    expect(backend.children, isEmpty);
    expect(find.text('Noch kein Kinder-Profil. Lege jetzt eins an.'), findsOneWidget);

    await tapText(tester, 'Konto löschen');
    expect(find.text('Konto wirklich löschen?'), findsOneWidget);
    await tapText(tester, 'Endgültig löschen');
    expect(find.text('Willkommen in Taleria'), findsOneWidget);
    expect(backend.parentsByUser, isEmpty);
  });

  testWidgets('Eltern-Anmeldung: falsches Passwort wird verständlich gemeldet', (tester) async {
    final backend = FakeBackend()..addParent();
    await tester.pumpWidget(buildTestApp(backend: backend));
    await tester.pumpAndSettle();
    await tapText(tester, 'Für Eltern: anmelden oder registrieren');
    await tester.tap(find.text('Anmelden').first);
    await tester.pumpAndSettle();

    await enter(tester, 'email-field', 'eltern@test.invalid');
    await enter(tester, 'password-field', 'falsch');
    await tester.tap(find.widgetWithText(FilledButton, 'Anmelden'));
    await tester.pumpAndSettle();
    expect(find.text('E-Mail oder Passwort stimmt nicht.'), findsOneWidget);
  });

  testWidgets('Registrierung mit E-Mail-Bestätigung zeigt Hinweis', (tester) async {
    final backend = FakeBackend()..requireEmailConfirmation = true;
    await tester.pumpWidget(buildTestApp(backend: backend));
    await tester.pumpAndSettle();
    await tapText(tester, 'Für Eltern: anmelden oder registrieren');
    await enter(tester, 'email-field', 'eltern@test.invalid');
    await enter(tester, 'password-field', 'sehrgeheim123');
    await tester.tap(find.byKey(const ValueKey('consent-checkbox')));
    await tapText(tester, 'Konto anlegen');
    expect(find.text('Fast geschafft!'), findsOneWidget);
  });

  testWidgets('Knöpfe sind mindestens 48 Punkte groß (Start und Leuchtturm)', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    backend.addChild(parent);
    await tester.pumpWidget(buildTestApp(backend: backend));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    backend.signInAs('eltern@test.invalid');
    await tester.pumpWidget(buildTestApp(backend: backend));
    await tester.pumpAndSettle();
    await enter(tester, 'pin-gate-field', '2468');
    await tapText(tester, 'Öffnen');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
