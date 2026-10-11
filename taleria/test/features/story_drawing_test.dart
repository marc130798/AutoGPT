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

  testWidgets('100 Cent sind 1 Euro, Scheine, große Münzen zuerst', (tester) async {
    await tester.pumpWidget(app(const StoryDrawing(name: 'cents_to_euro')));
    expect(find.text('50'), findsNWidgets(2));
    expect(find.text('='), findsOneWidget);

    await tester.pumpWidget(app(const StoryDrawing(name: 'euro_notes')));
    for (final value in ['5', '10', '20', '50']) {
      expect(find.text(value), findsOneWidget, reason: '$value-Euro-Schein');
    }

    await tester.pumpWidget(app(const StoryDrawing(name: 'big_coins_first')));
    expect(find.text('= ${formatCents(280)}'), findsOneWidget, reason: '2 € + 50 ct + 20 ct + 10 ct');
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
