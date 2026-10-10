import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/features/station/game_views.dart';
import 'package:taleria/l10n/app_localizations.dart';

import '../fake_content.dart';
import '../test_helpers.dart';

void main() {
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

  testWidgets('Zwei Körbe (Wunschinsel 1): falsch, nochmal, dazwischen mit Hinweis, geschafft', (tester) async {
    final game = FakeContent().station('wunschinsel', 1).content.game!;
    var done = false;
    await tester.pumpWidget(
      host(GameStepView(game: game, onDone: () => done = true, placeholder: const Text('Platzhalter'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Zwei Körbe'), findsOneWidget);

    var sawBetween = false;
    for (var i = 0; i < game.items.length; i++) {
      final text = tester.widget<Text>(find.byKey(const ValueKey('game-item'))).data!;
      final item = game.items.firstWhere((it) => it.text == text);
      if (item.basket == null) {
        sawBetween = true;
        await tester.tap(find.byKey(const ValueKey('basket-1')));
        await tester.pumpAndSettle();
        expect(find.text(item.hint!), findsOneWidget);
      } else {
        await tester.tap(find.byKey(ValueKey('basket-${1 - item.basket!}')));
        await tester.pumpAndSettle();
        expect(find.text('Passt nicht ganz. Versuch einen anderen Korb.'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('game-retry')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('basket-${item.basket}')));
        await tester.pumpAndSettle();
        expect(find.text('Passt!'), findsOneWidget);
      }
      if (i < game.items.length - 1) {
        await tester.tap(find.byKey(const ValueKey('game-next')));
        await tester.pumpAndSettle();
      }
    }
    expect(sawBetween, isTrue, reason: 'das Handy liegt dazwischen');
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('game-done')),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.tap(find.byKey(const ValueKey('game-done')));
    expect(done, isTrue);
  });

  testWidgets('Spiel ohne eigene Mechanik zeigt den Platzhalter', (tester) async {
    final game = FakeContent().station('hafen', 4).content.game!;
    expect(game.type, 'coins');
    await tester.pumpWidget(host(GameStepView(game: game, onDone: () {}, placeholder: const Text('Platzhalter'))));
    expect(find.text('Platzhalter'), findsOneWidget);
  });
}
