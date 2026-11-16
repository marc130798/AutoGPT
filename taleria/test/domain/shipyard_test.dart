import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/avatar.dart';
import 'package:taleria/domain/shipyard.dart';

void main() {
  test('Teile werden mit Seemeilen frei, nichts wird abgezogen', () {
    expect(unlockedShipyardCount(0), 0);
    expect(unlockedShipyardCount(399), 0);
    expect(unlockedShipyardCount(400), 1);
    expect(unlockedShipyardCount(1200), 1);
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

  test('Die Werft zeigt nur noch Schiffsteile', () {
    expect(shipyardItems.map((i) => i.slot).toSet(), {LookSlot.flag});
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
}
