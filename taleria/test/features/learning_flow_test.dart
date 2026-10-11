import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Karte, Insel und Station so, wie ein Kind sie auf seinem Gerät spielt.
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

  /// Scrollt, bis [finder] gebaut ist (lange Listen bauen nur, was zu sehen ist).
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.dragUntilVisible(finder, find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    if (finder.evaluate().isEmpty) {
      await tester.dragUntilVisible(finder, find.byType(Scrollable).first, const Offset(0, -200));
    }
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Kind mit erledigtem Intro, auf seinem eigenen Gerät angemeldet.
  Future<({FakeContent content, FakeProgress progress})> startOnMap(
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
    await tapText(tester, 'Zur Karte');
    return (content: content, progress: progress);
  }

  /// Entscheidungs-Spiel: probiert die Möglichkeiten durch, bis eine gute dabei ist.
  Future<void> solveChoice(WidgetTester tester) async {
    while (find.byKey(const ValueKey('game-done')).evaluate().isEmpty) {
      for (var option = 0; option < 4; option++) {
        await tapKey(tester, 'choice-option-$option');
        if (find.byKey(const ValueKey('game-retry')).evaluate().isEmpty) break;
        await tapKey(tester, 'game-retry');
      }
      if (find.byKey(const ValueKey('game-done')).evaluate().isEmpty) await tapKey(tester, 'game-next');
    }
    await tapKey(tester, 'game-done');
  }

  /// Münzen legen: liest den Zielbetrag ab und legt ihn mit den größten Münzen zuerst.
  Future<void> solveCoins(WidgetTester tester) async {
    while (find.byKey(const ValueKey('game-done')).evaluate().isEmpty) {
      // „Gelegt: … von 3,50 €“, bei Einsteigern „von 8 €“ oder „von 80 ct“.
      final sum = tester.widget<Text>(find.byKey(const ValueKey('coins-sum'))).data!;
      final goal = sum.substring(sum.indexOf('von ') + 4).replaceAll('\u00A0', ' ');
      final comma = RegExp(r'^(\d+),(\d\d)').firstMatch(goal);
      final euros = RegExp(r'(\d+) €').firstMatch(goal), cents = RegExp(r'(\d+) ct').firstMatch(goal);
      final target = comma != null
          ? int.parse(comma.group(1)!) * 100 + int.parse(comma.group(2)!)
          : int.parse(euros?.group(1) ?? '0') * 100 + int.parse(cents?.group(1) ?? '0');
      var rest = target;
      for (final v in [2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1]) {
        while (rest >= v) {
          await tapKey(tester, 'coin-$v');
          rest -= v;
        }
      }
      if (find.byKey(const ValueKey('game-done')).evaluate().isEmpty) await tapKey(tester, 'game-next');
    }
    await tapKey(tester, 'game-done');
  }

  /// Klickt Szene, Bildergeschichte und Spiel durch, bis das Quiz kommt.
  Future<void> playUntilQuiz(WidgetTester tester) async {
    for (var i = 0; i < 40 && find.byKey(const ValueKey('quiz-question')).evaluate().isEmpty; i++) {
      if (find.byKey(const ValueKey('choice-game')).evaluate().isNotEmpty) {
        await solveChoice(tester);
      } else if (find.byKey(const ValueKey('coins-sum')).evaluate().isNotEmpty) {
        await solveCoins(tester);
      } else {
        await tapText(tester, 'Weiter');
      }
    }
  }

  /// Beantwortet alle Fragen richtig, bis das Ergebnis kommt.
  Future<void> answerAllCorrectly(WidgetTester tester, FakeContent content) async {
    while (find.byKey(const ValueKey('quiz-question')).evaluate().isNotEmpty) {
      final question = tester.widget<Text>(find.byKey(const ValueKey('quiz-question'))).data!;
      await tapText(tester, content.rightAnswerFor(question));
      expect(find.text('Richtig!'), findsOneWidget);
      await tapText(tester, find.text('Fertig').evaluate().isEmpty ? 'Nächste Frage' : 'Fertig');
    }
  }

  testWidgets('Karte: Hafen offen, Tauschinsel gesperrt, Spar-Insel im Nebel', (tester) async {
    await startOnMap(tester);
    expect(find.text('Hafen von Taleria'), findsOneWidget);

    await tapKey(tester, 'island-tauschinsel');
    expect(find.text('Diese Insel ist noch verschlossen. Schließ zuerst die Insel davor ab.'), findsOneWidget);

    await tapKey(tester, 'island-spar-insel');
    expect(find.text('Diese Insel taucht bald auf.'), findsOneWidget);
    expect(find.text('Spar-Insel?'), findsOneWidget);
  });

  testWidgets('Hafen: Station 2 durchspielen, danach öffnet sich Station 3', (tester) async {
    final (:content, :progress) = await startOnMap(tester);
    await tapKey(tester, 'island-hafen');

    // Keine Ankunft im Hafen (der Film lief schon im Intro), direkt die Stationen.
    expect(find.byKey(const ValueKey('island-scene')), findsOneWidget);
    await tapKey(tester, 'station-3');
    expect(find.text('Diese Station öffnet sich, wenn du die Station davor geschafft hast.'), findsOneWidget);
    await tapKey(tester, 'station-1');
    expect(find.text('Hier hat deine Reise begonnen.'), findsOneWidget);

    await tapKey(tester, 'station-2');
    expect(find.text('Film folgt'), findsNothing, reason: 'Stationen haben keinen Film mehr');
    expect(find.textContaining('goldenen Halstuch'), findsOneWidget);
    // Bis zur Bildergeschichte: Bild (noch Platzhalter mit Namen) und Erklärung.
    for (var i = 0; i < 10 && find.byKey(const ValueKey('story-dots')).evaluate().isEmpty; i++) {
      await tapText(tester, 'Weiter');
    }
    expect(find.byKey(const ValueKey('placeholder:story.hafen.2.1')), findsOneWidget);
    expect(find.textContaining('Das klappt nur selten.'), findsOneWidget);
    await tapKey(tester, 'story-next');
    expect(find.byKey(const ValueKey('placeholder:story.hafen.2.2')), findsOneWidget);
    await tapKey(tester, 'story-back');
    expect(find.byKey(const ValueKey('placeholder:story.hafen.2.1')), findsOneWidget);
    await playUntilQuiz(tester);
    expect(find.text('Kurzer Check'), findsOneWidget);
    expect(find.text('Frage 1 von 5'), findsOneWidget);

    await answerAllCorrectly(tester, content);
    expect(find.text('Station geschafft!'), findsOneWidget);
    expect(find.text('5 von 5 richtig'), findsOneWidget);
    expect(find.text('+100 Seemeilen'), findsOneWidget);

    await tapText(tester, 'Zurück zur Insel');
    expect(progress.done, contains('island-hafen/station2'));

    // Nach Station 2 wirft das Schiff Anker: Station 3 wartet auf den Tauchgang.
    await tapKey(tester, 'station-3');
    expect(find.text('Diese Station öffnet sich, wenn du die Station davor geschafft hast.'), findsOneWidget);
    await tapKey(tester, 'dive-1');
    expect(find.text('Perlentauchen'), findsOneWidget);
    expect(find.text('Jede richtige Antwort ist eine Perle.'), findsOneWidget);
    await answerAllCorrectly(tester, content);

    // Das Wrack: erst falsch, dann nochmal versuchen.
    expect(find.text('Im Wrack'), findsOneWidget);
    await tapText(tester, 'Münzen glänzen schöner als Waren.');
    expect(find.text('Nicht ganz.'), findsOneWidget);
    await tapKey(tester, 'wreck-retry');
    await tapText(tester, 'Mit Münzen konnte er später bei jedem kaufen, was er brauchte.');
    await tapKey(tester, 'wreck-done');

    expect(find.text('Wieder an Bord!'), findsOneWidget);
    expect(find.text('4 Perlen gefunden'), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('dive-find')));
    expect(find.text('Fund für deine Sammlung: Alte Handelsmünze'), findsOneWidget);
    await tapText(tester, 'Zurück zur Insel');
    expect(progress.done, contains('island-hafen/dive1'));

    await tapKey(tester, 'station-3');
    expect(find.text('Weißt du noch?'), findsOneWidget);
  });

  testWidgets('Station 4: Die Übung ist Pflicht, das Mini-Spiel kommt als Bonus am Ende', (tester) async {
    final (:content, :progress) = await startOnMap(tester, prepare: (p) => p.completeStations('hafen'));
    await tapKey(tester, 'island-hafen');
    await tapKey(tester, 'station-4');
    // Erst „Weißt du noch?“, dann Szene, Übung und Quiz.
    for (var i = 0; i < 3 && find.text('Station geschafft!').evaluate().isEmpty; i++) {
      await playUntilQuiz(tester);
      expect(find.text('Mini-Spiel!'), findsNothing, reason: 'vor dem Quiz kommt nur die Übung');
      await answerAllCorrectly(tester, content);
    }
    expect(find.text('Station geschafft!'), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('bonus-game')));
    expect(
      find.byKey(const ValueKey('bonus-game-image')),
      findsOneWidget,
      reason: 'Startbild der Kasse auf der Bonus-Karte',
    );
    expect(find.text('Bonus: Mini-Spiel'), findsOneWidget);
    expect(find.textContaining('„Fischbrötchen-Kasse“ ist jetzt freigespielt. Kein Muss'), findsOneWidget);
    await tapKey(tester, 'bonus-game-play');
    expect(find.text('Mini-Spiel!'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bonus-game')), findsOneWidget, reason: 'zurück im Ergebnis der Station');
  });

  testWidgets('Abschlussprüfung bestehen: Kartenstück, Orden, Tauschinsel offen', (tester) async {
    final (:content, :progress) = await startOnMap(tester, prepare: (p) => p.completeStations('hafen', except: 1));
    await tapKey(tester, 'island-hafen');
    await tapKey(tester, 'station-8');
    expect(find.textContaining('Abschlussprüfung'), findsWidgets);
    await playUntilQuiz(tester);
    expect(find.text('Frage 1 von 10'), findsOneWidget);
    await answerAllCorrectly(tester, content);

    expect(find.text('Prüfung bestanden!'), findsOneWidget);
    await scrollTo(tester, find.text('Neuer Orden: Erster Landgang'));
    expect(find.text('Kartenstück gefunden!'), findsOneWidget);
    expect(find.text('Neuer Orden: Erster Landgang'), findsOneWidget);
    await tapText(tester, 'Zur Karte');

    // Zurück auf der Karte: Auf dem Weg zur Tauschinsel liegen zwei Stopps auf See.
    expect(progress.completedIslands, contains('island-hafen'));
    await tapKey(tester, 'island-tauschinsel');
    expect(
      find.text('Auf dem Weg zu dieser Insel liegen noch Stopps auf See. Tipp auf den leuchtenden Stopp!'),
      findsOneWidget,
    );
    await tapKey(tester, 'sea-stop-tauschinsel-2');
    expect(
      find.text('Diesen Stopp erreichst du, wenn du die Insel und den Stopp davor geschafft hast.'),
      findsOneWidget,
    );
    // Auf der Karte stehen die Schiffe von Händler und Otti.
    expect(find.byKey(const ValueKey('sea-stop-ship-ship.haendler')), findsOneWidget);
    expect(find.byKey(const ValueKey('sea-stop-ship-ship.fischer')), findsOneWidget);
    for (final k in [1, 2]) {
      await tapKey(tester, 'sea-stop-tauschinsel-$k');
      // Nach dem Nebel liegt oben das Schiff auf dem Meer.
      expect(find.byKey(const ValueKey('stop-ship')), findsOneWidget);
      await playUntilQuiz(tester);
      expect(find.byKey(const ValueKey('stop-ship')), findsOneWidget, reason: 'auch bei den Fragen');
      expect(find.text('Weißt du noch?'), findsNothing, reason: 'der Stopp wiederholt selbst');
      await answerAllCorrectly(tester, content);
      expect(find.text('Stopp geschafft!'), findsOneWidget);
      expect(find.text('+30 Seemeilen'), findsOneWidget);
      await tapText(tester, 'Weiter segeln');
    }
    expect(progress.done, containsAll(['island-tauschinsel/sea1', 'island-tauschinsel/sea2']));

    // Jetzt ist die Tauschinsel offen, mit Ankunftsszene beim ersten Besuch.
    await tapKey(tester, 'island-tauschinsel');
    expect(find.text('Film folgt'), findsOneWidget);
    await tapText(tester, 'Weiter');
    expect(find.textContaining('Land in Sicht!'), findsOneWidget);
  });

  testWidgets('Prüfung nicht bestanden: neue Fragen, ohne Strafe', (tester) async {
    final (:content, :progress) = await startOnMap(tester, prepare: (p) => p.completeStations('hafen', except: 1));
    await tapKey(tester, 'island-hafen');
    await tapKey(tester, 'station-8');
    await playUntilQuiz(tester);
    for (var i = 0; i < 10; i++) {
      final question = tester.widget<Text>(find.byKey(const ValueKey('quiz-question'))).data!;
      final right = content.rightAnswerFor(question);
      final wrong = content.wrongAnswerFor(question);
      expect(wrong, isNot(right));
      await tapText(tester, wrong);
      expect(find.text('Nicht ganz.'), findsOneWidget);
      await tapText(tester, i == 9 ? 'Fertig' : 'Nächste Frage');
    }
    expect(find.text('Noch nicht ganz'), findsOneWidget);
    expect(find.textContaining('Du brauchst 8 richtige Antworten'), findsOneWidget);
    expect(progress.completedIslands, isEmpty);

    await tapText(tester, 'Noch einmal versuchen');
    expect(find.text('Frage 1 von 10'), findsOneWidget);
  });

  testWidgets('Knöpfe in Karte und Quiz sind groß genug', (tester) async {
    await startOnMap(tester);
    await tapKey(tester, 'island-hafen');
    // Echte Mini-Spiele (Kasse an Station 4, Markt an Station 7) tragen das Spiel-Zeichen.
    expect(find.byKey(const ValueKey('station-game-island-hafen/station4')), findsOneWidget);
    expect(find.byKey(const ValueKey('station-game-island-hafen/station7')), findsOneWidget);
    expect(find.byKey(const ValueKey('station-game-island-hafen/station2')), findsNothing);
    await tapKey(tester, 'station-2');
    await playUntilQuiz(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
