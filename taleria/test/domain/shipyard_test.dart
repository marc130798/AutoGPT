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
    final byXp = shipyardItems.where((i) => i.logbook == null).toList();
    for (var i = 1; i < byXp.length; i++) {
      expect(byXp[i].minXp, greaterThanOrEqualTo(byXp[i - 1].minXp));
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

  test('Schatzcode aus dem Logbuch: schaltet die Anker-Flagge frei, Seemeilen helfen nicht', () {
    expect(logbookForCode('ANKER7'), 'hafen');
    expect(logbookForCode(' anker-7 '), 'hafen', reason: 'groß, klein, Leerzeichen und Strich egal');
    expect(logbookForCode('ANKER8'), isNull);
    final anchor = logbookItem('hafen')!;
    expect(anchor.value, ShipFlag.anchor);
    expect(anchor.isUnlocked(100000, const {}), isFalse);
    expect(anchor.isUnlocked(0, const {'hafen'}), isTrue);
    expect(nextShipyardItem(100000), isNull, reason: 'Logbuch-Teile zählen nicht als nächstes Seemeilen-Ziel');
    expect(unlockedShipyardCount(100000), shipyardItems.where((i) => i.logbook == null && i.minXp > 0).length);
  });

  test('Eingelöste Codes stehen im Avatar-JSON', () {
    final avatar = const AvatarConfig().copyWith(logbooks: {'hafen'}, flag: ShipFlag.anchor);
    final back = AvatarConfig.fromJson(avatar.toJson());
    expect(back, avatar);
    expect(back.logbooks, {'hafen'});
    expect(const AvatarConfig().toJson().containsKey('logbooks'), isFalse);
  });

  test('Jeder Logbuch-Code schaltet genau ein eigenes Teil frei', () {
    final items = {for (final island in logbookCodes.values) logbookItem(island)};
    expect(items, isNot(contains(null)));
    expect(items.length, logbookCodes.length, reason: 'jede Insel ihr eigenes Teil');
    expect(logbookForCode('muschel 3'), 'tauschinsel');
    expect(logbookForCode('Flasche5'), 'wunschinsel');
    expect(logbookForCode('TALER-9'), 'spar-insel');
  });
}
