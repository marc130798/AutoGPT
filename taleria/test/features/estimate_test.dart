import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/features/station/estimate_view.dart';
import 'package:taleria/features/station/picture_story.dart';
import 'package:taleria/features/station/station_stage.dart';
import 'package:taleria/l10n/app_localizations.dart';

import '../test_helpers.dart';

/// Schätzfrage vor der Erklärung (INSELN.md, Aufbau jeder Station):
/// schätzen ohne Richtig oder Falsch, Auflösung am Ende der Bildergeschichte.
void main() {
  const reveal = DialogLine(speaker: 'tala', text: 'Geld gibt es seit etwa 2.600 Jahren.');
  const slider = EstimateQuestion(
    speaker: 'talo',
    question: 'Wie alt ist Geld?',
    kind: 'slider',
    reveal: reveal,
    min: 0,
    max: 5000,
    step: 100,
    start: 1000,
    unit: 'Jahre',
    unitOne: 'Jahr',
    answer: 2600,
  );
  const wheel = EstimateQuestion(
    speaker: 'talo',
    question: 'Wie viele Leute wollten tauschen?',
    kind: 'wheel',
    reveal: DialogLine(speaker: 'tala', text: 'Keiner.'),
    min: 0,
    max: 10,
    answer: 0,
  );
  const choice = EstimateQuestion(
    speaker: 'tala',
    question: 'Was ist am wertvollsten?',
    kind: 'choice',
    reveal: DialogLine(speaker: 'tala', text: 'Das kommt darauf an.'),
    options: ['Muschel', 'Fisch', 'Salz'],
    answer: 2,
  );

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      AppScope(
        services: buildTestApp().services,
        child: MaterialApp(
          theme: taleriaThemeForStage(1),
          locale: const Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: StagePanel(open: true, child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('Anzeige: Tausender-Punkt, Einheit, „1 Jahr“, Startwert auf dem Raster', () {
    expect(slider.display(2600), '2.600 Jahre');
    expect(slider.display(1), '1 Jahr');
    expect(slider.initial, 1000);
    expect(wheel.initial, 5, reason: 'ohne Startwert die Mitte');
    expect(choice.display(1), 'Fisch');
    expect(choice.initial, -1, reason: 'bei der Auswahl ist erst nichts gewählt');
    expect(slider.isExact(2600), isTrue);
    expect(slider.isExact(2500), isFalse);
  });

  testWidgets('Auswahl: „Das ist mein Tipp“ erst nach einer Wahl, ohne Richtig oder Falsch', (tester) async {
    int? sent;
    await pump(tester, EstimateView(estimate: choice, onSubmit: (v) => sent = v));
    expect(find.text('Was glaubst du?'), findsOneWidget);
    expect(find.text('Was ist am wertvollsten?'), findsOneWidget);
    final submit = find.byKey(const ValueKey('estimate-submit'));
    expect(tester.widget<ButtonStyleButton>(submit).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('estimate-option-1')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    await tester.tap(submit);
    expect(sent, 1);
  });

  testWidgets('Schieberegler: zeigt die Zahl mit Einheit und schickt einen Wert auf dem Raster', (tester) async {
    int? sent;
    await pump(tester, EstimateView(estimate: slider, onSubmit: (v) => sent = v));
    expect(find.byKey(const ValueKey('estimate-value')), findsOneWidget);
    expect(find.text('1.000 Jahre'), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('estimate-slider')), const Offset(120, 0));
    await tester.pumpAndSettle();
    final shown = tester.widget<Text>(find.byKey(const ValueKey('estimate-value'))).data!;
    expect(shown, isNot('1.000 Jahre'));

    await tester.tap(find.byKey(const ValueKey('estimate-submit')));
    expect(sent, isNotNull);
    expect(sent! % 100, 0);
    expect(sent, greaterThan(1000));
    expect(slider.display(sent!), shown);
  });

  testWidgets('Zahlenrad: Drehen ändert die Zahl', (tester) async {
    int? sent;
    await pump(tester, EstimateView(estimate: wheel, onSubmit: (v) => sent = v));
    expect(find.byKey(const ValueKey('estimate-wheel')), findsOneWidget);
    await tester.drag(find.byKey(const ValueKey('estimate-wheel')), const Offset(0, -96));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('estimate-submit')));
    expect(sent, 7, reason: 'von 5 zwei Zahlen weiter');
  });

  Future<bool> playStory(WidgetTester tester, int guess) async {
    var done = false;
    await pump(
      tester,
      PictureStory(
        lines: const [
          DialogLine(speaker: 'talo', text: 'Früher hat man getauscht.'),
          DialogLine(speaker: 'tala', text: 'Dann kamen Münzen.'),
        ],
        estimate: slider,
        guess: guess,
        onDone: () => done = true,
      ),
    );
    // Zwei Bilder und die Auflösung: drei Punkte.
    expect(
      find.descendant(of: find.byKey(const ValueKey('story-dots')), matching: find.byType(Container)),
      findsNWidgets(3),
    );
    expect(find.byKey(const ValueKey('estimate-reveal')), findsNothing);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('story-next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('estimate-reveal')), findsOneWidget);
    expect(find.text(reveal.text), findsOneWidget);
    expect(done, isFalse);
    return done;
  }

  testWidgets('Auflösung am Ende der Geschichte: Tipp, Lösung und „Genau getroffen!“', (tester) async {
    await playStory(tester, 2600);
    expect(find.text('Dein Tipp: 2.600 Jahre'), findsOneWidget);
    expect(find.byKey(const ValueKey('estimate-exact')), findsOneWidget);
  });

  testWidgets('Auflösung: Daneben geschätzt ist kein Fehler, nur ohne „Genau getroffen!“', (tester) async {
    var done = false;
    await pump(
      tester,
      PictureStory(
        lines: const [DialogLine(speaker: 'talo', text: 'Früher hat man getauscht.')],
        estimate: slider,
        guess: 1000,
        onDone: () => done = true,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('story-next')));
    await tester.pumpAndSettle();
    expect(find.text('Dein Tipp: 1.000 Jahre'), findsOneWidget);
    expect(find.byKey(const ValueKey('estimate-exact')), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-next')));
    expect(done, isTrue);
  });
}
