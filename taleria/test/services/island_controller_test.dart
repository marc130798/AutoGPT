import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/services/island_controller.dart';

import '../fake_content.dart';
import '../fakes.dart';

/// Stationen einer Insel: immer vom Steg nach oben (nach `sort_order`).
void main() {
  test('Stationen stehen in der richtigen Reihenfolge, auch wenn der Server sie umgekehrt liefert', () async {
    final content = FakeContent();
    final hafen = content.mapIslands.firstWhere((i) => i.slug == 'hafen');
    // Supabase sortiert ohne ausdrückliche Angabe absteigend.
    content.stations[hafen.id] = content.stations[hafen.id]!.reversed.toList();
    final controller = IslandController(
      content: content,
      progress: FakeProgress(content),
      settings: FakeLocalSettings(),
      child: const ChildProfile(
        id: 'c1',
        nickname: 'Mila',
        birthYear: 2015,
        level: LevelSetting.beginner,
        onboardingCompleted: true,
      ),
      island: hafen,
    );
    await controller.load();
    final orders = [for (final s in controller.stations) s.sortOrder];
    expect(orders, [...orders]..sort());
    expect(controller.stations.first.content.isOnboarding, isTrue, reason: 'Station 1 liegt am Steg');
  });
}
