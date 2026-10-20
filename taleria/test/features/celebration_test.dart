import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/features/progress/celebration.dart';

import '../test_helpers.dart';

void main() {
  Widget wrap(Widget child, {required bool reduceMotion}) {
    final app = buildTestApp();
    return AppScope(
      services: app.services,
      child: MaterialApp(
        theme: taleriaThemeForStage(1),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );
  }

  testWidgets('Kartenstück und Orden: einmalige Animation, die zur Ruhe kommt', (tester) async {
    await tester.pumpWidget(wrap(const IslandRewardEffect(badgeAssetKey: 'badge.hafen'), reduceMotion: false));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Animationen reduziert: alles sofort da', (tester) async {
    await tester.pumpWidget(wrap(const IslandRewardEffect(badgeAssetKey: 'badge.hafen'), reduceMotion: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(wrap(const RewardPop(assetKey: 'rank.matrose'), reduceMotion: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Seemeilen zählen hoch und stehen am Ende genau da', (tester) async {
    Widget count(int value) => CountUp(
      value: value,
      builder: (context, v) => Text('+$v', key: const ValueKey('n')),
    );
    await tester.pumpWidget(wrap(count(100), reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 300));
    final midway = int.parse(tester.widget<Text>(find.byKey(const ValueKey('n'))).data!.substring(1));
    expect(midway, inExclusiveRange(0, 100));
    await tester.pumpAndSettle();
    expect(find.text('+100'), findsOneWidget);

    await tester.pumpWidget(wrap(count(80), reduceMotion: true));
    expect(find.text('+80'), findsOneWidget, reason: 'ohne Bewegung sofort da');
  });

  testWidgets('Konfetti fällt einmal und hört von selbst auf, fängt kein Antippen ab', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 300,
          height: 400,
          child: Stack(
            children: [
              Positioned.fill(
                child: ElevatedButton(onPressed: () => tapped = true, child: const Text('Weiter')),
              ),
              const Positioned.fill(child: ConfettiBurst()),
            ],
          ),
        ),
        reduceMotion: false,
      ),
    );
    expect(tester.hasRunningAnimations, isTrue);
    await tester.tap(find.text('Weiter'));
    expect(tapped, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(wrap(const ConfettiBurst(), reduceMotion: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Taler fliegen nur, wenn Geld dazukommt', (tester) async {
    Widget chest(int from, int to) =>
        CoinsIntoChest(chest: const SizedBox.square(dimension: 76), size: 76, from: from, to: to);
    final flying = find.byKey(const ValueKey('coins-flying'));

    await tester.pumpWidget(wrap(chest(500, 500), reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(flying, findsNothing, reason: 'nichts Neues');

    // Während die Seite offen ist, kommt Geld dazu.
    await tester.pumpWidget(wrap(chest(500, 800), reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(flying, findsOneWidget);
    await tester.pumpAndSettle();
    expect(flying, findsNothing);

    // Ausgeben: nichts fliegt.
    await tester.pumpWidget(wrap(chest(500, 300), reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(flying, findsNothing);
  });

  testWidgets('Taler beim Öffnen: seit dem letzten Besuch dazugekommen; ohne Bewegung keine', (tester) async {
    final flying = find.byKey(const ValueKey('coins-flying'));
    await tester.pumpWidget(
      wrap(
        const CoinsIntoChest(chest: SizedBox.square(dimension: 76), size: 76, from: 200, to: 700),
        reduceMotion: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(flying, findsOneWidget);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      wrap(
        const CoinsIntoChest(chest: SizedBox.square(dimension: 76), size: 76, from: 200, to: 700),
        reduceMotion: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(flying, findsNothing);
  });
}
