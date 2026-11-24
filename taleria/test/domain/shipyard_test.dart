import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/avatar.dart';
import 'package:taleria/domain/shipyard.dart';

void main() {
  test('Teile werden mit Seemeilen frei, nichts wird abgezogen', () {
    expect(unlockedShipyardCount(0), 0);
    expect(unlockedShipyardCount(199), 0);
    expect(unlockedShipyardCount(200), 1);
    expect(unlockedShipyardCount(400), 2);
    expect(unlockedShipyardCount(1200), 4);
    expect(unlockedShipyardCount(100000), shipyardItems.where((i) => i.minXp > 0).length);
    expect(nextShipyardItem(1200)!.id, 'flag_wave');
    expect(nextShipyardItem(8000), isNull);
  });

  test('Grenzen steigen und jedes Teil gibt es nur einmal', () {
    final byXp = shipyardItems.where((i) => i.logbook == null && i.island == null && i.crewStars == null).toList();
    for (var i = 1; i < byXp.length; i++) {
      expect(byXp[i].minXp, greaterThanOrEqualTo(byXp[i - 1].minXp));
    }
    final ids = [for (final slot in LookSlot.values) ...lookOptions(slot).map((i) => i.id)];
    expect(ids.toSet().length, ids.length);
  });

  test('Flagge hissen ändert nur die Flagge, die Figur bleibt', () {
    const avatar = AvatarConfig(figure: PlayerFigure.lioness);
    final item = shipyardItems.firstWhere((i) => i.id == 'flag_stripes');
    final worn = wearLook(avatar, item);
    expect(worn.flag, ShipFlag.stripes);
    expect(worn.figure, PlayerFigure.lioness);
    expect(wearsLook(worn, item), isTrue);
    expect(wearsLook(avatar, item), isFalse);
  });

  test('Figur und Flagge stehen im Avatar-JSON, alte Avatare werden zum Löwen', () {
    final avatar = const AvatarConfig().copyWith(figure: PlayerFigure.lioness, flag: ShipFlag.sun);
    expect(AvatarConfig.fromJson(avatar.toJson()), avatar);
    final old = AvatarConfig.fromJson(const {'outfit': 'red', 'species': 'cat'});
    expect(old.figure, PlayerFigure.lion);
    expect(old.flag, ShipFlag.taleria);
  });

  test('Die Werft zeigt Schiffsteile und die Kleiderkiste', () {
    expect(shipyardItems.map((i) => i.slot).toSet(), {
      LookSlot.flag,
      LookSlot.sails,
      LookSlot.figurehead,
      LookSlot.clothes,
      LookSlot.garment,
    });
    final dressed = wearLook(const AvatarConfig(), shipyardItems.firstWhere((i) => i.id == 'sails_red'));
    expect(dressed.sails, SailColor.red);
    expect(AvatarConfig.fromJson(dressed.copyWith(figurehead: Figurehead.lion).toJson()).figurehead, Figurehead.lion);
    expect(logbookItem('wunschinsel')!.value, ShipFlag.bottle);
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

  test('Farben von Anfang an frei, Kleidungsstücke nach geschafften Inseln', () {
    final colors = lookOptions(LookSlot.clothes);
    expect(colors.map((i) => i.value), ClothesColor.values);
    expect(colors.every((i) => i.unlockedAt(0)), isTrue);
    final green = colors.firstWhere((i) => i.value == ClothesColor.green);
    final avatar = wearLook(const AvatarConfig(), green);
    expect(avatar.clothes, ClothesColor.green);
    expect(wearsLook(avatar, green), isTrue);
    expect(AvatarConfig.fromJson(avatar.toJson()).clothes, ClothesColor.green);
    expect(AvatarConfig.fromJson({'figure': 'lioness'}).clothes, ClothesColor.blue, reason: 'gleicher Start für alle');
    expect(AvatarConfig.fromJson({'figure': 'lioness', 'clothes': 'blue'}).clothes, ClothesColor.blue);

    final sailor = islandGarment('hafen')!;
    expect(sailor.value, Garment.sailor);
    expect(sailor.isUnlocked(100000, const {}), isFalse, reason: 'Seemeilen helfen nicht');
    expect(sailor.isUnlocked(0, const {}, const {'hafen'}), isTrue);
    expect(islandGarment('spar-insel')!.value, Garment.raincoat);
    final dressed = wearLook(const AvatarConfig(), sailor);
    expect(AvatarConfig.fromJson(dressed.toJson()).garment, Garment.sailor);
    expect(AvatarConfig.fromJson({}).garment, Garment.stripes);
    // Die Liste bleibt nach Grenzen sortiert, sonst stimmt „das nächste Teil“ nicht.
    final limits = [
      for (final i in shipyardItems.where((i) => i.logbook == null && i.island == null && i.crewStars == null)) i.minXp,
    ];
    expect(limits, [...limits]..sort());
  });

  test('Crew-Teile gibt es nur mit Crew-Sternen, nicht mit Seemeilen', () {
    final flag = shipyardItems.firstWhere((i) => i.value == ShipFlag.crew);
    expect(flag.isUnlocked(100000, const {}), isFalse);
    expect(flag.isUnlocked(0, const {}, const {}, 2), isFalse);
    expect(flag.isUnlocked(0, const {}, const {}, 3), isTrue);
    expect(crewStarSteps, [3, 6, 10]);
    expect(nextShipyardItem(100000), isNull, reason: 'Crew-Teile zählen nicht als nächstes Seemeilen-Teil');
  });
}
