import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/features/common/figure_names.dart';
import 'package:taleria/features/intro/speech_bubble.dart';
import 'package:taleria/features/station/figure_head.dart';
import 'package:taleria/features/station/station_stage.dart';
import 'package:taleria/l10n/app_localizations.dart';
import 'package:taleria/l10n/app_localizations_de.dart';

import '../test_helpers.dart';

/// Namen der Inselfiguren mit Tier („Bruno, der Bär“) und Gesicht auf dem
/// Antwort-Knopf (Marcs Test am 20.10.2026: niemand merkt sich die Namen).
void main() {
  final l10n = AppLocalizationsDe();

  test('Eigene Namen bekommen das Tier, Rollen wie „Händler“ nicht', () {
    expect(figureLabel(l10n, 'bruno', 'Bruno'), 'Bruno, der Bär');
    expect(figureLabel(l10n, 'greta', 'Greta'), 'Greta, die Ziege');
    expect(figureLabel(l10n, 'moritz', 'Moritz'), 'Moritz, das Murmeltier');
    expect(figureLabel(l10n, 'emma', 'Emma'), 'Emma, das Eichhörnchen');
    expect(figureLabel(l10n, 'gustav', 'Gustav'), 'Gustav, die Grille');
    expect(figureLabel(l10n, 'haendler', 'Händler'), 'Händler');
    expect(figureLabel(l10n, 'bootsbauer', 'Obststand'), 'Obststand');
    expect(figureLabel(l10n, 'talo', 'Talo'), 'Talo');
    expect(figureNamed(l10n, ' Otti '), 'otti');
    expect(figureNamed(l10n, 'Bruno hat Äpfel'), isNull);
    expect(figureNamed(l10n, 'Talo'), isNull);
  });

  Widget host(Widget child) => AppScope(
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
      home: Scaffold(body: child),
    ),
  );

  testWidgets('Antwort „Bruno“ zeigt sein Gesicht und „Bruno, der Bär“', (tester) async {
    await tester.pumpWidget(
      host(
        Column(
          children: [
            AnswerButton(key: const ValueKey('a'), text: 'Bruno', onPressed: () {}),
            AnswerButton(key: const ValueKey('b'), text: 'Ein Seil', onPressed: () {}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bruno, der Bär'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('a')), matching: find.byType(FigureHead)), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('b')), matching: find.byType(FigureHead)), findsNothing);
  });

  testWidgets('Sprechblase: „Olga, die Schildkröte“', (tester) async {
    await tester.pumpWidget(
      host(SpeechBubble.line(const DialogLine(speaker: 'olga', name: 'Olga', text: 'Willkommen!'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Olga, die Schildkröte'), findsOneWidget);
  });
}
