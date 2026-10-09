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

  /// Klickt Film, Szene, Erklärung und Spiel durch, bis das Quiz kommt.
  Future<void> playUntilQuiz(WidgetTester tester) async {
    for (var i = 0; i < 40 && find.byKey(const ValueKey('quiz-question')).evaluate().isEmpty; i++) {
      await tapText(tester, 'Weiter');
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
    expect(find.text('Stationen'), findsOneWidget);
    await tapKey(tester, 'station-3');
    expect(find.text('Diese Station öffnet sich, wenn du die Station davor geschafft hast.'), findsOneWidget);
    await tapKey(tester, 'station-1');
    expect(find.text('Hier hat deine Reise begonnen.'), findsOneWidget);

    await tapKey(tester, 'station-2');
    expect(find.text('Film folgt'), findsOneWidget);
    await tapText(tester, 'Weiter');
    expect(find.textContaining('goldenen Halstuch'), findsOneWidget);
    await playUntilQuiz(tester);
    expect(find.text('Kurzer Check'), findsOneWidget);
    expect(find.text('Frage 1 von 5'), findsOneWidget);

    await answerAllCorrectly(tester, content);
    expect(find.text('Station geschafft!'), findsOneWidget);
    expect(find.text('5 von 5 richtig'), findsOneWidget);
    expect(find.text('+100 Seemeilen'), findsOneWidget);

    await tapText(tester, 'Zurück zur Insel');
    expect(progress.done, contains('island-hafen/station2'));
    await tapKey(tester, 'station-3');
    expect(find.text('Weißt du noch?'), findsOneWidget);
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

    // Zurück auf der Karte: Tauschinsel ist offen, mit Ankunftsszene beim ersten Besuch.
    expect(progress.completedIslands, contains('island-hafen'));
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
      final wrong = content.questions.values
          .expand((q) => q)
          .firstWhere((q) => q.question == question)
          .answers
          .firstWhere((a) => a != right);
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
    await tapKey(tester, 'station-2');
    await playUntilQuiz(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
