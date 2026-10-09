import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/backend/backend.dart';
import 'package:taleria/core/config/app_config.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('Ohne Server: Vorschau zeigt Talo und Tala als Platzhalter', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Willkommen an Bord!'), findsOneWidget);
    expect(find.byKey(const ValueKey('placeholder:character.talo')), findsOneWidget);
    expect(find.byKey(const ValueKey('placeholder:character.tala')), findsOneWidget);
    expect(find.text('Talo'), findsOneWidget);
    expect(find.text('Tala'), findsOneWidget);
  });

  testWidgets('Vorhandene Grafik ersetzt den Platzhalter', (tester) async {
    await tester.pumpWidget(buildTestApp(files: {'assets/images/brand.logo.png': tinyPng}));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('placeholder:brand.logo')), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    // Talo ist eine Rive-Animation, die es noch nicht gibt: weiter Platzhalter.
    expect(find.byKey(const ValueKey('placeholder:character.talo')), findsOneWidget);
  });

  testWidgets('Umgebung und Server-Status sind sichtbar', (tester) async {
    await tester.pumpWidget(buildTestApp(backendStatus: BackendStatus.ready));
    await tester.pumpAndSettle();

    expect(find.textContaining('Testumgebung'), findsOneWidget);
    expect(find.textContaining('Server verbunden, Datenbank bereit'), findsOneWidget);
  });

  testWidgets('Intro: Film folgt, Weiter führt zurück', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Intro ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('Film folgt'), findsOneWidget);
    expect(find.text('Intro-Film'), findsOneWidget);

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Willkommen an Bord!'), findsOneWidget);
  });

  testWidgets('Live: keine Grafik-Übersicht und kein Umgebungs-Schild', (tester) async {
    await tester.pumpWidget(buildTestApp(environment: AppEnvironment.live));
    await tester.pumpAndSettle();
    expect(find.text('Alle Platzhalter ansehen'), findsNothing);
    expect(find.textContaining('Testumgebung'), findsNothing);
  });

  testWidgets('Grafik-Übersicht zählt vorhandene Dateien', (tester) async {
    final total = realManifest().length;
    await tester.pumpWidget(buildTestApp(files: {'assets/images/brand.logo.png': tinyPng}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alle Platzhalter ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('Grafiken und Filme'), findsOneWidget);
    expect(find.text('1 von $total Dateien vorhanden'), findsOneWidget);
  });

  testWidgets('Knöpfe sind mindestens 48 Punkte hoch', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
