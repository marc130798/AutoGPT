import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/services/map_controller.dart';

import '../fake_content.dart';

/// Wo das Schiff auf der Karte liegt: an der Insel oder am Stopp auf See.
void main() {
  const mila = ChildProfile(
    id: 'c1',
    nickname: 'Mila',
    birthYear: 2015,
    level: LevelSetting.beginner,
    onboardingCompleted: true,
  );

  Future<MapController> load(FakeProgress progress) async {
    final controller = MapController(content: progress.content, progress: progress, child: mila);
    await controller.load();
    return controller;
  }

  test('Das Schiff fährt vom Hafen zu jedem Stopp und dann zur Tauschinsel', () async {
    final content = FakeContent();
    final progress = FakeProgress(content);
    // Mitten im Hafen: Das Schiff liegt an der Insel.
    expect((await load(progress)).shipBerthId, 'island-hafen');

    // Hafen geschafft: Es wartet am ersten Stopp (dem Händlerschiff).
    progress
      ..completeStations('hafen')
      ..completedIslands.add('island-hafen');
    var map = await load(progress);
    expect(map.shipBerthId, 'island-tauschinsel/sea1');
    expect(map.shipIslandId, 'island-hafen', reason: 'gehört noch zur Insel davor');

    progress.done.add('island-tauschinsel/sea1');
    map = await load(progress);
    expect(map.shipBerthId, 'island-tauschinsel/sea2');

    progress.done.add('island-tauschinsel/sea2');
    map = await load(progress);
    expect(map.shipBerthId, 'island-tauschinsel');
    expect(map.shipStop, isNull);

    // Reihenfolge der Liegeplätze: vor jeder Insel ihre Stopps.
    final order = map.berthOrder;
    expect(order.take(4), ['island-hafen', 'island-tauschinsel/sea1', 'island-tauschinsel/sea2', 'island-tauschinsel']);
  });
}
