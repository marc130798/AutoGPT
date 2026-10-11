import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/assets/asset_keys.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/features/station/station_stage.dart';

import '../test_helpers.dart';

void main() {
  Future<double> veil(WidgetTester tester, {required bool faded}) async {
    await tester.pumpWidget(
      AppScope(
        services: buildTestApp().services,
        child: MaterialApp(
          theme: taleriaThemeForStage(1),
          home: StationBackdrop(
            assetKey: AssetKeys.islandBackground('hafen'),
            faded: faded,
            child: const Text('Gespräch'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('backdrop-veil'))).opacity;
  }

  testWidgets('Bei Gesprächen verblasst der Hintergrund, sonst nicht', (tester) async {
    expect(await veil(tester, faded: true), 1);
    expect(await veil(tester, faded: false), 0);
    expect(find.text('Gespräch'), findsOneWidget, reason: 'der Inhalt liegt über dem Schleier');
  });
}
