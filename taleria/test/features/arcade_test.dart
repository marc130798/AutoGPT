import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/domain/arcade_games.dart';
import 'package:taleria/features/arcade/arcade_screen.dart';
import 'package:taleria/l10n/app_localizations.dart';

import '../fakes.dart';
import '../test_helpers.dart';

void main() {
  Widget host(Widget child, FakeLocalSettings settings) => AppScope(
    services: buildTestApp(settings: settings).services,
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
      home: child,
    ),
  );

  testWidgets('Möwenflug: Startbild, Antippen, Runde vorbei, Rekord, Nochmal', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final settings = FakeLocalSettings();
    await tester.pumpWidget(
      host(ArcadeScreen(game: arcadeGames.firstWhere((g) => g.id == 'moewenflug'), childId: 'kind'), settings),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('arcade-intro')), findsOneWidget);
    expect(find.byKey(const ValueKey('arcade-best')), findsNothing, reason: 'noch kein Rekord');

    await tester.tap(find.byKey(const ValueKey('arcade-play')));
    await tester.pump();
    expect(find.byKey(const ValueKey('arcade-tap')), findsOneWidget, reason: 'kein Countdown, es wartet aufs Antippen');

    // Einmal antippen und dann fallen lassen: drei Mal ins Wasser, Runde vorbei.
    await tester.tapAt(const Offset(200, 500));
    for (var i = 0; i < 400 && find.byKey(const ValueKey('arcade-end')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('arcade-end')), findsOneWidget);
    expect(find.byKey(const ValueKey('arcade-score')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('arcade-again')));
    await tester.pump();
    expect(find.byKey(const ValueKey('arcade-end')), findsNothing);
    expect(find.byKey(const ValueKey('arcade-tap')), findsOneWidget);
    expect(find.byKey(const ValueKey('arcade-lives')), findsOneWidget);
  });

  testWidgets('Möwenflug: ein neuer Rekord wird gemerkt', (tester) async {
    final settings = FakeLocalSettings()..arcadeScores['kind/moewenflug'] = 0;
    await tester.pumpWidget(
      host(ArcadeScreen(game: arcadeGames.firstWhere((g) => g.id == 'moewenflug'), childId: 'kind'), settings),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('arcade-play')));
    await tester.pump();
    final state = tester.state<ArcadeFieldState>(find.byType(ArcadeField));
    await tester.tapAt(const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 16));
    (state.round! as GullFlightGame)
      ..saved = 30
      ..pocket = 0;
    for (var i = 0; i < 400 && find.byKey(const ValueKey('arcade-end')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('arcade-new-best')), findsOneWidget);
    expect(settings.arcadeScores['kind/moewenflug'], 30);
  });

  for (final game in arcadeGames) {
    testWidgets('${game.id}: spielen, Runde vorbei, Satz der Figur', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final settings = FakeLocalSettings();
      await tester.pumpWidget(host(ArcadeScreen(game: game, childId: 'kind'), settings));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('arcade-play')));
      await tester.pump();
      final state = tester.state<ArcadeFieldState>(find.byType(ArcadeField));
      for (var i = 0; i < 60; i++) {
        await tester.tapAt(Offset(60.0 + (i % 3) * 130, 500));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(state.round!.started, isTrue);
      state.round!.lives = 0;
      for (var i = 0; i < 40 && find.byKey(const ValueKey('arcade-end')).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byKey(const ValueKey('arcade-end')), findsOneWidget);
      expect(find.byKey(const ValueKey('arcade-score')), findsOneWidget);
    });
  }
}
