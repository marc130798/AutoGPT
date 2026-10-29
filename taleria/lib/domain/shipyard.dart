import 'avatar.dart';

/// Werft: Teile für den Avatar und Flaggen fürs Schiff, die das Kind mit
/// Seemeilen freischaltet (CLAUDE.md Abschnitt 8: verdient, nie gekauft).
/// Nichts wird ausgegeben: Wer die Grenze erreicht, darf das Teil tragen.
/// Gespeichert wird nur, was das Kind trägt (im Avatar-JSON).
enum LookSlot { outfit, hat, scarf, flag }

class LookItem {
  const LookItem(this.slot, this.value, this.minXp);

  final LookSlot slot;
  final Enum value;

  /// Ab so vielen Seemeilen frei. 0 = von Anfang an.
  final int minXp;

  String get id => '${slot.name}_${value.name}';
  bool unlockedAt(int xp) => xp >= minXp;
}

/// Alle Teile der Werft in der Reihenfolge der Grenzen. Die Grenzen passen
/// zu den Rängen: Matrose ab 1.500, Bootsmann ab 4.000, Steuermann ab 8.000.
const shipyardItems = <LookItem>[
  LookItem(LookSlot.flag, ShipFlag.taleria, 0),
  LookItem(LookSlot.scarf, Scarf.none, 0),
  LookItem(LookSlot.scarf, Scarf.red, 200),
  LookItem(LookSlot.flag, ShipFlag.stripes, 400),
  LookItem(LookSlot.outfit, OutfitColor.teal, 700),
  LookItem(LookSlot.hat, Hat.tricorn, 1000),
  LookItem(LookSlot.flag, ShipFlag.wave, 1500),
  LookItem(LookSlot.scarf, Scarf.gold, 2000),
  LookItem(LookSlot.outfit, OutfitColor.gold, 3000),
  LookItem(LookSlot.flag, ShipFlag.star, 4000),
  LookItem(LookSlot.hat, Hat.goldCaptain, 6000),
  LookItem(LookSlot.flag, ShipFlag.sun, 8000),
];

/// Jacken und Kopfbedeckungen, die es schon im Intro gibt.
const starterOutfits = [
  OutfitColor.navy,
  OutfitColor.red,
  OutfitColor.green,
  OutfitColor.yellow,
  OutfitColor.purple,
  OutfitColor.orange,
];
const starterHats = [Hat.none, Hat.captain, Hat.bandana, Hat.straw];

/// Alle Möglichkeiten eines Platzes: zuerst die aus dem Intro (frei), dann die der Werft.
List<LookItem> lookOptions(LookSlot slot) => [
  if (slot == LookSlot.outfit)
    for (final o in starterOutfits) LookItem(slot, o, 0),
  if (slot == LookSlot.hat)
    for (final h in starterHats) LookItem(slot, h, 0),
  for (final i in shipyardItems)
    if (i.slot == slot) i,
];

/// Teile der Werft (ohne die Starter), die bei [xp] frei sind.
int unlockedShipyardCount(int xp) => shipyardItems.where((i) => i.minXp > 0 && i.unlockedAt(xp)).length;

/// Das nächste Teil, das noch gesperrt ist, oder `null`, wenn alles frei ist.
LookItem? nextShipyardItem(int xp) {
  for (final i in shipyardItems) {
    if (!i.unlockedAt(xp)) return i;
  }
  return null;
}

/// Ein Teil anziehen oder hissen.
AvatarConfig wearLook(AvatarConfig avatar, LookItem item) => switch (item.value) {
  final OutfitColor o => avatar.copyWith(outfit: o),
  final Hat h => avatar.copyWith(hat: h),
  final Scarf s => avatar.copyWith(scarf: s),
  final ShipFlag f => avatar.copyWith(flag: f),
  _ => avatar,
};

/// Trägt der Avatar dieses Teil gerade?
bool wearsLook(AvatarConfig avatar, LookItem item) => switch (item.value) {
  final OutfitColor o => avatar.outfit == o,
  final Hat h => avatar.hat == h,
  final Scarf s => avatar.scarf == s,
  final ShipFlag f => avatar.flag == f,
  _ => false,
};
