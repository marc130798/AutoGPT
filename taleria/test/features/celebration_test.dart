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
}
