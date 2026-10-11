import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/domain/money.dart';
import 'package:taleria/features/station/story_drawings.dart';
import 'package:taleria/l10n/app_localizations.dart';

/// Münzen und Scheine zeichnet die App selbst, mit den richtigen Zahlen.
void main() {
  Widget app(Widget child, {Size size = const Size(400, 300)}) => MaterialApp(
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
      body: Center(
        child: SizedBox.fromSize(size: size, child: child),
      ),
    ),
  );

  testWidgets('Alle Euro-Münzen mit ihrem Wert', (tester) async {
    await tester.pumpWidget(app(const StoryDrawing(name: 'euro_coins')));
    for (final value in ['1', '2', '5', '10', '20', '50']) {
      expect(find.text(value), findsWidgets, reason: '$value Cent');
    }
    expect(find.text('CENT'), findsNWidgets(6));
    expect(find.text('EURO'), findsNWidgets(2));
  });

  testWidgets('100 Cent sind 1 Euro, Komma, Scheine, große Münzen zuerst', (tester) async {
    await tester.pumpWidget(app(const StoryDrawing(name: 'cents_to_euro')));
    expect(find.text('50'), findsNWidgets(2));
    expect(find.text('='), findsOneWidget);

    await tester.pumpWidget(app(const StoryDrawing(name: 'comma_amount')));
    expect(
      find.text(formatCents(205), findRichText: true),
      findsOneWidget,
      reason: 'vor dem Komma Euro, dahinter Cent',
    );
    expect(find.text('2 €'), findsOneWidget);
    expect(find.text('5 ct'), findsOneWidget);

    await tester.pumpWidget(app(const StoryDrawing(name: 'euro_notes')));
    for (final value in ['5', '10', '20', '50']) {
      expect(find.text(value), findsOneWidget, reason: '$value-Euro-Schein');
    }

    await tester.pumpWidget(app(const StoryDrawing(name: 'big_coins_first')));
    expect(find.text('= ${formatCents(280)}'), findsOneWidget, reason: '2 € + 50 ct + 20 ct + 10 ct');
  });

  testWidgets('Tauschinsel: 12 billige Netze im Jahr kosten mehr als ein gutes', (tester) async {
    await tester.pumpWidget(app(const StoryDrawing(name: 'nets_year')));
    expect(find.byType(FishingNet), findsNWidgets(13));
    for (var month = 1; month <= 12; month++) {
      expect(find.text('$month'), findsOneWidget, reason: 'Monat $month');
    }
    expect(find.text('billig: hält 1 Monat'), findsOneWidget);
    expect(find.text('gut: hält 1 Jahr'), findsOneWidget);

    await tester.pumpWidget(app(const StoryDrawing(name: 'nets_cost')));
    expect(find.text('12 × 5 Taler'), findsOneWidget);
    expect(find.text('60 Taler'), findsOneWidget);
    expect(find.text('1 × 20 Taler'), findsOneWidget);
    expect(find.text('20 Taler'), findsOneWidget);
  });

  testWidgets('Zeichnungen passen in jede Größe, auch auf kleine Handys', (tester) async {
    for (final name in storyDrawings) {
      for (final size in const [Size(260, 195), Size(400, 300), Size(600, 450)]) {
        await tester.pumpWidget(app(StoryDrawing(name: name), size: size));
        expect(tester.takeException(), isNull, reason: '$name $size');
      }
    }
  });
}
