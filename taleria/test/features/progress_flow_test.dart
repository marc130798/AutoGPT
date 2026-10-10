import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/progress_models.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Seemeilen, Rang, Orden, Wind, Begegnung auf See und Tempo im Leuchtturm.
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

  /// Kind mit erledigtem Intro auf seinem eigenen Gerät, auf der Startseite.
  Future<({FakeContent content, FakeProgress progress})> startOnHome(
    WidgetTester tester, {
    void Function(FakeProgress)? prepare,
  }) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    final content = FakeContent();
    final progress = FakeProgress(content);
    prepare?.call(progress);

    await tester.pumpWidget(buildTestApp(backend: backend, content: content, progress: progress));
    await tester.pumpAndSettle();
    await tapText(tester, 'Ich habe einen Code');
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tapText(tester, 'An Bord gehen');
    return (content: content, progress: progress);
  }

  Future<void> answerAllCorrectly(WidgetTester tester, FakeContent content) async {
    while (find.byKey(const ValueKey('quiz-question')).evaluate().isNotEmpty) {
      final question = tester.widget<Text>(find.byKey(const ValueKey('quiz-question'))).data!;
      await tapText(tester, content.rightAnswerFor(question));
      await tapText(tester, find.text('Fertig').evaluate().isEmpty ? 'Nächste Frage' : 'Fertig');
    }
  }

  testWidgets('Startseite: Rang, Seemeilen, Fahrtwind und Orden-Sammlung', (tester) async {
    final started = await startOnHome(tester);
    expect(started.progress.events.map((e) => e.event), [
      TrackedEvent.appOpen,
    ], reason: 'Messung: Kinderbereich geöffnet, ohne Station');
    expect(tester.widget<Text>(find.byKey(const ValueKey('stats-rank'))).data, 'Schiffsjunge');
    expect(find.text('50 Seemeilen'), findsOneWidget);
    expect(find.text('Noch 1.450 Seemeilen bis Matrose'), findsOneWidget);
    expect(find.text('Noch kein Fahrtwind'), findsOneWidget);

    await tapKey(tester, 'home-badges');
    expect(find.text('Noch keine Orden. Schließe deine erste Insel ab!'), findsOneWidget);
    expect(find.text('Erster Landgang'), findsOneWidget);
    expect(find.text('Noch nicht gefunden'), findsNWidgets(3));
  });

  testWidgets('Ohne Wind: Hinweis auf Karte und Insel, keine neue Station, kein Countdown', (tester) async {
    await startOnHome(
      tester,
      prepare: (p) => p
        ..stationsPerWeek = 2
        ..wind = 0
        ..nextRelease = DateTime(2026, 10, 15),
    );
    await tapText(tester, 'Zur Karte');
    const windText = 'Das Schiff braucht Wind. Die nächste Station erreichst du am Donnerstag.';
    expect(find.text(windText), findsOneWidget);

    await tapKey(tester, 'island-hafen');
    expect(find.byKey(const ValueKey('island-wind-hint')), findsOneWidget);
    await scrollTo(tester, find.textContaining('Wartet auf Wind'));
    expect(find.textContaining('Wartet auf Wind'), findsOneWidget);
    await tapKey(tester, 'station-2');
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Film folgt'), findsNothing, reason: 'Station startet nicht');
  });

  testWidgets('Letzter Wind: Station 3 mit Zeitstrahl, neuer Rang, danach wartet Station 4', (tester) async {
    final (:content, :progress) = await startOnHome(
      tester,
      prepare: (p) => p
        // Erledigt: Station 2 und Ankerplatz 1.
        ..completeStations('hafen', except: 8)
        ..stationsPerWeek = 2
        ..wind = 1
        ..extraXp = 1450
        ..nextRelease = DateTime(2026, 10, 12),
    );
    await tapText(tester, 'Zur Karte');
    await tapKey(tester, 'island-hafen');
    await tapKey(tester, 'station-3');

    // „Weißt du noch?“, dann Film, Szene, Erklärung bis zum Spiel.
    await answerAllCorrectly(tester, content);
    for (var i = 0; i < 20 && find.byKey(const ValueKey('game-done')).evaluate().isEmpty; i++) {
      await tapText(tester, 'Weiter');
    }
    expect(find.text('Zeitstrahl'), findsOneWidget);
    final items = content.station('hafen', 3).content.game!.items;
    await tapText(tester, items[2].text);
    expect(find.text('Noch nicht. Was kommt davor?'), findsOneWidget);
    for (final item in items) {
      await tapText(tester, item.text);
    }
    await scrollTo(tester, find.text('Geschafft!'));
    expect(find.text('Geschafft!'), findsOneWidget);
    await tapKey(tester, 'game-done');

    await answerAllCorrectly(tester, content);
    expect(find.text('Station geschafft!'), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('result-rank-up')));
    expect(find.text('Neuer Rang: Matrose!'), findsOneWidget);
    await tapText(tester, 'Zurück zur Insel');

    expect(progress.wind, 0);
    await scrollTo(tester, find.textContaining('Wartet auf Wind'));
    expect(find.textContaining('Wartet auf Wind'), findsOneWidget);
    // Ganz nach oben scrollen: dort steht der Hinweis zum Wind.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('Das Schiff braucht Wind. Die nächste Station erreichst du am Montag.'), findsOneWidget);

    // Zurück auf der Startseite: der neue Rang.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const ValueKey('stats-rank'))).data, 'Matrose');
  });

  testWidgets('Begegnung mit Meister Taleron: Vorstellung, Rätsel, nochmal versuchen', (tester) async {
    final (:content, :progress) = await startOnHome(tester, prepare: (p) => p.makeDue('hafen', 2));
    await tapText(tester, 'Zur Karte');
    expect(find.text('Meister Taleron taucht auf!'), findsOneWidget);

    await tapKey(tester, 'encounter-marker');
    expect(find.text('Talo, schau mal! Unter dem Schiff bewegt sich etwas. Etwas sehr Großes.'), findsOneWidget);
    for (var i = 0; i < 10 && find.byKey(const ValueKey('quiz-question')).evaluate().isEmpty; i++) {
      await tapText(tester, 'Weiter');
    }
    expect(find.text('Rätsel 1 von 3'), findsOneWidget);

    String questionText() => tester.widget<Text>(find.byKey(const ValueKey('quiz-question'))).data!;
    final first = content.allQuestions.firstWhere((q) => q.question == questionText());
    await tapText(tester, first.answers[1]);
    expect(find.text('Nicht ganz. Hör gut zu, dann klappt es beim nächsten Versuch.'), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('encounter-explanation')));
    expect(find.byKey(const ValueKey('encounter-explanation')), findsOneWidget);
    await tapKey(tester, 'encounter-retry');
    await tapText(tester, first.answers[0]);
    expect(find.text('Hoho, richtig! Das hast du gut behalten.'), findsOneWidget);
    await tapKey(tester, 'encounter-next');

    for (var i = 2; i <= 3; i++) {
      expect(find.text('Rätsel $i von 3'), findsOneWidget);
      await tapText(tester, content.rightAnswerFor(questionText()));
      await tapKey(tester, 'encounter-next');
    }

    expect(find.text('Der Weg ist frei!'), findsOneWidget);
    expect(find.text('Beim ersten Versuch richtig: 2 von 3'), findsOneWidget);
    expect(find.text('+20 Seemeilen'), findsOneWidget);
    await tapText(tester, 'Zurück zur Karte');
    expect(progress.encounterRuns, 1);
    expect(find.text('Meister Taleron taucht auf!'), findsNothing, reason: 'nichts mehr fällig');
  });

  testWidgets('Leuchtturm: Level, Tempo und Pause der Serie', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    backend.addChild(parent);
    final content = FakeContent();
    final progress = FakeProgress(content)..streakWeeks = 3;
    backend.signInAs('eltern@test.invalid');
    await tester.pumpWidget(buildTestApp(backend: backend, content: content, progress: progress));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('pin-gate-field')), '2468');
    await tapText(tester, 'Öffnen');
    await tapText(tester, 'Mila');

    await scrollTo(tester, find.byKey(const ValueKey('pace-card')));
    expect(find.text('Tempo und Serie'), findsOneWidget);
    expect(find.text('Level 1 (Schiffsjunge)'), findsOneWidget);
    expect(find.text('Fortschritt: 50 Seemeilen'), findsOneWidget);
    expect(find.text('Serie: 3 Wochen'), findsOneWidget);

    await tapText(tester, '3');
    expect(progress.stationsPerWeek, 3);
    expect(find.text('Tempo gespeichert.'), findsOneWidget);
    await tapText(tester, 'Frei');
    expect(progress.stationsPerWeek, isNull);

    await tapKey(tester, 'streak-pause');
    expect(progress.streakPaused, isTrue);
    expect(find.text('Serie pausiert'), findsOneWidget);
  });

  testWidgets('Unterwasser-Sammlung: Perlen und Funde', (tester) async {
    await startOnHome(
      tester,
      prepare: (p) => p
        ..findDates['island-hafen/dive1'] = DateTime(2026, 10, 10)
        ..pearlsByDive['island-hafen/dive1'] = 3,
    );
    await tapKey(tester, 'home-collection');
    expect(find.text('3 Perlen'), findsOneWidget);
    // Jeder Fund hat ein eigenes Bild; ohne Bilddatei trägt der Platzhalter denselben Namen.
    expect(
      find.descendant(of: find.byKey(const ValueKey('find-hafen-fund-1')), matching: find.text('Alte Handelsmünze')),
      findsWidgets,
    );
    expect(find.text('Gefunden am 10.10.2026'), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('find-wunschinsel-fund-3')));
    expect(find.text('Noch nicht gefunden'), findsWidgets);
  });

  testWidgets('Nebel voraus: Hinweis statt Fehler, Kontrollfahrt zum Üben', (tester) async {
    final (:content, :progress) = await startOnHome(
      tester,
      prepare: (p) => p
        ..completedIslands.addAll(['island-hafen', 'island-tauschinsel', 'island-wunschinsel'])
        ..seen.addAll([for (var i = 1; i <= 3; i++) 'island-hafen/station2/q$i']),
    );
    await tapText(tester, 'Zur Karte');
    expect(find.text('Die nächste Insel liegt noch im Nebel.'), findsOneWidget);
    expect(find.text('Meister Taleron taucht auf!'), findsNothing, reason: 'nichts fällig');

    await tapKey(tester, 'fog-practice');
    expect(find.text('Talo, schau mal! Unter dem Schiff bewegt sich etwas. Etwas sehr Großes.'), findsOneWidget);
    expect(progress.due, isEmpty);
  });
}
