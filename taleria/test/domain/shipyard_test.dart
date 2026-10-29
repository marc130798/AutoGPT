import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/avatar.dart';
import 'package:taleria/domain/shipyard.dart';

void main() {
  test('Teile werden mit Seemeilen frei, nichts wird abgezogen', () {
    expect(unlockedShipyardCount(0), 0);
    expect(unlockedShipyardCount(199), 0);
    expect(unlockedShipyardCount(200), 1);
    expect(unlockedShipyardCount(1200), 4);
    expect(unlockedShipyardCount(100000), shipyardItems.where((i) => i.minXp > 0).length);
    expect(nextShipyardItem(1200)!.id, 'flag_wave');
    expect(nextShipyardItem(8000), isNull);
  });

  test('Grenzen steigen und jedes Teil gibt es nur einmal', () {
    for (var i = 1; i < shipyardItems.length; i++) {
      expect(shipyardItems[i].minXp, greaterThanOrEqualTo(shipyardItems[i - 1].minXp));
    }
    final ids = [for (final slot in LookSlot.values) ...lookOptions(slot).map((i) => i.id)];
    expect(ids.toSet().length, ids.length);
  });

  test('Intro-Jacken und -Hüte sind frei, Werft-Teile nicht im Intro', () {
    expect(lookOptions(LookSlot.outfit).where((i) => i.minXp == 0).map((i) => i.value), starterOutfits);
    expect(starterOutfits, isNot(contains(OutfitColor.gold)));
    expect(starterHats, isNot(contains(Hat.goldCaptain)));
  });

  test('Anziehen ändert nur den einen Platz', () {
    const avatar = AvatarConfig();
    final item = shipyardItems.firstWhere((i) => i.id == 'scarf_red');
    final worn = wearLook(avatar, item);
    expect(worn.scarf, Scarf.red);
    expect(worn.copyWith(scarf: Scarf.none), avatar);
    expect(wearsLook(worn, item), isTrue);
    expect(wearsLook(avatar, item), isFalse);
  });

  test('Halstuch und Flagge stehen im Avatar-JSON, alte Avatare bleiben gültig', () {
    final avatar = const AvatarConfig().copyWith(scarf: Scarf.gold, flag: ShipFlag.sun);
    expect(AvatarConfig.fromJson(avatar.toJson()), avatar);
    final old = AvatarConfig.fromJson(const {'outfit': 'red'});
    expect(old.scarf, Scarf.none);
    expect(old.flag, ShipFlag.taleria);
  });
}
