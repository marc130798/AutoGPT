import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/features/station/picture_story.dart';

import '../test_helpers.dart';

Widget _zoom({required bool motion, bool reduce = false}) => AppScope(
  services: buildTestApp(sceneMotion: motion).services,
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: const Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 400,
        height: 300,
        child: StoryZoom(
          opening: true,
          child: ColoredBox(key: ValueKey('bild'), color: Colors.green),
        ),
      ),
    ),
  ),
);

double _scale(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.ancestor(of: find.byKey(const ValueKey('bild')), matching: find.byType(Transform)).first,
  );
  return transform.transform.getMaxScaleOnAxis();
}

void main() {
  testWidgets('Bild der Geschichte zoomt langsam heran und blendet am Anfang aus dem Dunkeln auf', (tester) async {
    await tester.pumpWidget(_zoom(motion: true));
    expect(_scale(tester), closeTo(1, 0.01));
    expect(find.byType(ColoredBox), findsNWidgets(2), reason: 'dunkler Schleier am Anfang');

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ColoredBox), findsOneWidget, reason: 'nach einer Sekunde ist das Bild hell');
    await tester.pump(const Duration(seconds: 8));
    expect(_scale(tester), closeTo(StoryZoom.endScale, 0.01));
  });

  testWidgets('Ohne Bewegung (Tests, „Bewegung reduzieren“) steht das Bild still', (tester) async {
    await tester.pumpWidget(_zoom(motion: true, reduce: true));
    expect(find.ancestor(of: find.byKey(const ValueKey('bild')), matching: find.byType(Transform)), findsNothing);
    await tester.pumpWidget(_zoom(motion: false));
    expect(find.ancestor(of: find.byKey(const ValueKey('bild')), matching: find.byType(Transform)), findsNothing);
  });
}
