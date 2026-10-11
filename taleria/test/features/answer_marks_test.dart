import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/domain/quiz_logic.dart';
import 'package:taleria/features/station/quiz_view.dart';
import 'package:taleria/features/station/station_stage.dart';
import 'package:taleria/l10n/app_localizations.dart';
import 'package:taleria/services/station_controller.dart';

import '../test_helpers.dart';

void main() {
  const question = QuizQuestion(
    id: 'q1',
    stationId: 's1',
    question: 'Warum ist Geld praktischer als Tauschen?',
    answers: ['Fast jeder nimmt es an', 'Es ist aus Gold', 'Es glänzt'],
    correctIndex: 0,
    explanation: 'Mit Geld musst du niemanden suchen, der genau deine Sache will.',
  );

  Future<QuizRun> pump(WidgetTester tester, {required bool open, int? choose}) async {
    final run = QuizRun([ShuffledQuestion.shuffle(question, Random(2))]);
    if (choose != null) run.answer(choose);
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
          home: Scaffold(
            body: StagePanel(
              open: open,
              child: QuizView(run: run, title: 'Stations-Check', onAnswer: (_) {}, onNext: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return run;
  }

  AnswerMark mark(WidgetTester tester, int i) => tester.widget<AnswerButton>(find.byKey(ValueKey('answer-$i'))).mark;

  testWidgets('Falsch gewählt: die gewählte Antwort rot, die richtige grün, die dritte bleibt neutral', (tester) async {
    final probe = QuizRun([ShuffledQuestion.shuffle(question, Random(2))]);
    final right = probe.current.correctDisplayIndex;
    final wrong = (right + 1) % 3;
    final other = (right + 2) % 3;
    await pump(tester, open: true, choose: wrong);
    expect(mark(tester, wrong), AnswerMark.wrong);
    expect(mark(tester, right), AnswerMark.right);
    expect(mark(tester, other), AnswerMark.none);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('Vor dem Antippen alles neutral', (tester) async {
    await pump(tester, open: true);
    for (var i = 0; i < 3; i++) {
      expect(mark(tester, i), AnswerMark.none);
    }
  });

  testWidgets('Ohne Blatt: Frage und Rückmeldung im Rahmen; auf dem Blatt ohne Rahmen', (tester) async {
    await pump(tester, open: true, choose: 0);
    expect(find.byType(GlassFrame), findsNWidgets(2), reason: 'Frage und Rückmeldung');
    await pump(tester, open: false, choose: 0);
    expect(find.byType(GlassFrame), findsNothing);
  });
}
