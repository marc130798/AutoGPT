import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/domain/budget_models.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/domain/money.dart';
import 'package:taleria/features/station/dive_header.dart';
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
    const game = GameInfo(type: 'treasure_hunt', title: 'Schatzsuche');
    await tester.pumpWidget(host(GameStepView(game: game, onDone: () {}, placeholder: const Text('Platzhalter'))));
    expect(find.text('Platzhalter'), findsOneWidget);
  });

  testWidgets('Wunschflasche (Wunschinsel 3): Wunsch einstecken oder überspringen', (tester) async {
    final game = FakeContent().station('wunschinsel', 3).content.game!;
    final wishes = <WishDraft>[];
    var done = 0;
    Widget view() => host(
      GameStepView(
        game: game,
        onDone: () => done++,
        placeholder: const Text('Platzhalter'),
        onWish: (draft) async => wishes.add(draft),
      ),
    );

    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(find.text('Platzhalter'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('wish-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Bitte mindestens 2 Zeichen.'), findsOneWidget);
    expect(wishes, isEmpty);

    await tester.enterText(find.byKey(const ValueKey('wish-title')), 'Glitzerkompass');
    await tester.tap(find.byKey(const ValueKey('wish-submit')));
    await tester.pumpAndSettle();
    expect(wishes.single.title, 'Glitzerkompass');
    expect(wishes.single.isBig, isFalse);
    expect(find.byKey(const ValueKey('wish-thrown')), findsOneWidget);
    expect(find.textContaining('Morgen wird sie angespült'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('game-done')));
    expect(done, 1);

    // Überspringen geht auch, dann ohne Flasche.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('game-skip')));
    expect(done, 2);
    expect(wishes, hasLength(1));
  });

  testWidgets('Wunschflasche ohne Server: Platzhalter', (tester) async {
    final game = FakeContent().station('wunschinsel', 3).content.game!;
    await tester.pumpWidget(host(GameStepView(game: game, onDone: () {}, placeholder: const Text('Platzhalter'))));
    expect(find.text('Platzhalter'), findsOneWidget);
  });

  /// Hoher Bildschirm, damit lange Spiele ganz gebaut werden (Listen bauen nur, was zu sehen ist).
  Future<void> tall(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Münzschublade (Hafen 4): Beträge legen, zu viel wegnehmen, Wechselgeld', (tester) async {
    await tall(tester);
    final game = FakeContent().station('hafen', 4).content.game!;
    var done = false;
    await tester.pumpWidget(host(GameStepView(game: game, onDone: () => done = true, placeholder: const Text('-'))));
    await tester.pumpAndSettle();
    expect(find.text('Gelegt: ${formatCents(0)} von ${formatCents(350)}'), findsOneWidget);

    for (final v in [200, 100, 50]) {
      await tapKey(tester, 'coin-$v');
    }
    expect(find.text('Genau richtig!'), findsOneWidget);
    await tapKey(tester, 'game-next');

    // 1,85 €: erst zu viel, dann wegnehmen, dann mit mehr Münzen als nötig.
    await tapKey(tester, 'coin-200');
    expect(find.text('Zu viel! Tippe oben auf eine Münze, um sie wegzunehmen.'), findsOneWidget);
    await tapKey(tester, 'coins-placed-0');
    for (final v in [100, 50, 20, 10, 2, 2, 1]) {
      await tapKey(tester, 'coin-$v');
    }
    expect(find.text('Geschafft! Mit 5 Münzen und Scheinen ginge es auch.'), findsOneWidget);
    await tapKey(tester, 'game-next');

    for (final v in [50, 5]) {
      await tapKey(tester, 'coin-$v');
    }
    await tapKey(tester, 'game-next');
    for (final v in [200, 50]) {
      await tapKey(tester, 'coin-$v');
    }
    await tapKey(tester, 'game-done');
    expect(done, isTrue);
  });

  testWidgets('Tauschkette (Tauschinsel 1): Entscheidungen mit Rückmeldung', (tester) async {
    await tall(tester);
    final game = FakeContent().station('tauschinsel', 1).content.game!;
    var done = false;
    await tester.pumpWidget(host(GameStepView(game: game, onDone: () => done = true, placeholder: const Text('-'))));
    await tester.pumpAndSettle();
    expect(find.text('Situation 1 von 3'), findsOneWidget);
    expect(find.text('Mein Seil? Gern, aber nur gegen Äpfel.'), findsOneWidget);

    // Otti hat keine Äpfel: Rückmeldung und nochmal.
    await tapKey(tester, 'choice-option-1');
    expect(find.text('Otti ist Fischerin. Sie hat Fisch, aber keine Äpfel.'), findsOneWidget);
    await tapKey(tester, 'game-retry');
    await tapKey(tester, 'choice-option-0');
    expect(find.text('Richtig, Bruno hat Äpfel. Aber was will er dafür?'), findsOneWidget);
    await tapKey(tester, 'game-next');
    await tapKey(tester, 'choice-option-0');
    await tapKey(tester, 'game-next');
    expect(find.text('Situation 3 von 3'), findsOneWidget);
    await tapKey(tester, 'choice-option-0');
    expect(find.textContaining('Drei Tausche für ein Seil!'), findsOneWidget);
    await tapKey(tester, 'game-done');
    expect(done, isTrue);
  });

  testWidgets('Preis-Säule (Hafen 6): falsches Teil mit Hinweis, dann genau 10 Taler', (tester) async {
    await tall(tester);
    final game = FakeContent().station('hafen', 6).content.game!;
    var done = false;
    await tester.pumpWidget(host(GameStepView(game: game, onDone: () => done = true, placeholder: const Text('-'))));
    await tester.pumpAndSettle();
    final serviette = game.items.indexWhere((i) => i.text == 'Goldene Serviette');
    await tapKey(tester, 'pick-item-$serviette');
    await tapKey(tester, 'game-check');
    expect(find.textContaining('Eine goldene Serviette gibt es zum Fischbrötchen nicht.'), findsOneWidget);
    await tapKey(tester, 'pick-item-$serviette');
    for (final (i, item) in game.items.indexed) {
      if (item.required) await tapKey(tester, 'pick-item-$i');
    }
    expect(find.text('Zusammen: 10 von 10 Talern'), findsOneWidget);
    await tapKey(tester, 'game-check');
    expect(find.text('Passt!'), findsOneWidget);
    await tapKey(tester, 'game-done');
    expect(done, isTrue);
  });

  testWidgets('Rucksack (Wunschinsel 2): zu teuer, Wichtiges vergessen, dann passt es', (tester) async {
    await tall(tester);
    final game = FakeContent().station('wunschinsel', 2).content.game!;
    await tester.pumpWidget(host(GameStepView(game: game, onDone: () {}, placeholder: const Text('-'))));
    await tester.pumpAndSettle();
    int item(String text) => game.items.indexWhere((i) => i.text == text);

    for (final text in ['Glitzerkompass', 'Wasserflasche', 'Regenjacke']) {
      await tapKey(tester, 'pick-item-${item(text)}');
    }
    await tapKey(tester, 'game-check');
    expect(find.text('Das ist zu teuer. Lass etwas weg.'), findsOneWidget);
    await tapKey(tester, 'pick-item-${item('Glitzerkompass')}');
    await tapKey(tester, 'game-check');
    expect(find.text('Unterwegs braucht Tala etwas zu essen.'), findsOneWidget);
    await tapKey(tester, 'pick-item-${item('Brot für unterwegs')}');
    await tapKey(tester, 'pick-item-${item('Bonbons')}');
    expect(find.text('Zusammen: 10 Taler, du hast 10 Taler'), findsOneWidget);
    await tapKey(tester, 'game-check');
    expect(find.text('Passt!'), findsOneWidget);
  });

  testWidgets('Netz-Rechnung (Tauschinsel 5): Tipp, Lösung zeigen, richtig rechnen', (tester) async {
    await tall(tester);
    final game = FakeContent().station('tauschinsel', 5).content.game!;
    var done = false;
    await tester.pumpWidget(host(GameStepView(game: game, onDone: () => done = true, placeholder: const Text('-'))));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('number-input')), '50');
    await tapKey(tester, 'game-check');
    expect(find.text('Noch nicht ganz.'), findsOneWidget);
    expect(find.text('Tipp: Ein Jahr hat 12 Monate.'), findsOneWidget);
    await tapKey(tester, 'number-reveal');
    expect(find.text('Lösung: 60 Taler'), findsOneWidget);
    await tapKey(tester, 'game-next');

    await tester.enterText(find.byKey(const ValueKey('number-input')), '40');
    await tapKey(tester, 'game-check');
    expect(find.text('Richtig!'), findsOneWidget);
    await tapKey(tester, 'game-next');
    await tester.enterText(find.byKey(const ValueKey('number-input')), '12');
    await tapKey(tester, 'game-check');
    await tapKey(tester, 'game-done');
    expect(done, isTrue);
  });

  testWidgets('Tauchgang Schatztruhe: jede Antwort verrät eine Ziffer', (tester) async {
    expect(DiveGame.parse('treasure_chest'), DiveGame.treasureChest);
    expect(DiveGame.parse('shell_count'), DiveGame.pearls, reason: 'noch nicht gebaut: Perlentauchen');
    expect(chestCode('station-a', 4), chestCode('station-a', 4), reason: 'fest pro Ankerplatz');
    expect(chestCode('station-a', 4).every((d) => d >= 0 && d <= 9), isTrue);

    final code = chestCode('station-a', 3);
    await tester.pumpWidget(
      host(const DiveHeader(game: DiveGame.treasureChest, results: [true, false, null], stationId: 'station-a')),
    );
    expect(find.text('?'), findsOneWidget);
    expect(find.text('${code[0]}'), findsWidgets);
    expect(find.text('Die Truhe springt auf!'), findsNothing);

    await tester.pumpWidget(
      host(const DiveHeader(game: DiveGame.treasureChest, results: [true, false, true], stationId: 'station-a')),
    );
    expect(find.text('?'), findsNothing);
    expect(find.text('Die Truhe springt auf!'), findsOneWidget);
  });
}
