import 'avatar.dart';

/// Werft: Teile fürs eigene Schiff, die das Kind mit Seemeilen freischaltet
/// (CLAUDE.md Abschnitt 8: verdient, nie gekauft). Nichts wird ausgegeben: Wer
/// die Grenze erreicht, darf das Teil nutzen. Gespeichert wird nur, was das
/// Kind gewählt hat (im Avatar-JSON).
///
/// Seit 16.11.2026 ist die Figur des Kindes Löwe oder Löwin (frei wählbar,
/// [PlayerFigure]); Jacken, Hüte und Halstücher gibt es nicht mehr. Dafür
/// gibt es Segelfarben, Galionsfiguren und Flaggen fürs Schiff.
enum LookSlot { outfit, hat, scarf, flag, sails, figurehead }

/// Plätze, die die Werft heute zeigt.
const shipyardSlots = [LookSlot.sails, LookSlot.figurehead, LookSlot.flag];

class LookItem {
  const LookItem(this.slot, this.value, this.minXp, {this.logbook});

  final LookSlot slot;
  final Enum value;

  /// Ab so vielen Seemeilen frei. 0 = von Anfang an.
  final int minXp;

  /// Frei nur mit dem Schatzcode aus dem Logbuch dieser Insel (zum Beispiel `hafen`), nicht mit Seemeilen.
  final String? logbook;

  String get id => '${slot.name}_${value.name}';
  bool unlockedAt(int xp) => logbook == null && xp >= minXp;

  /// Frei: mit Seemeilen oder, bei Logbuch-Teilen, mit dem eingelösten Schatzcode.
  bool isUnlocked(int xp, Set<String> logbooks) => logbook != null ? logbooks.contains(logbook) : xp >= minXp;
}

/// Alle Teile der Werft in der Reihenfolge der Grenzen. Die Grenzen passen
/// zu den Rängen: Matrose ab 1.500, Bootsmann ab 4.000, Steuermann ab 8.000.
const shipyardItems = <LookItem>[
  LookItem(LookSlot.sails, SailColor.white, 0),
  LookItem(LookSlot.figurehead, Figurehead.none, 0),
  LookItem(LookSlot.flag, ShipFlag.taleria, 0),
  LookItem(LookSlot.sails, SailColor.red, 200),
  LookItem(LookSlot.flag, ShipFlag.stripes, 400),
  LookItem(LookSlot.sails, SailColor.blue, 700),
  LookItem(LookSlot.figurehead, Figurehead.dolphin, 1000),
  LookItem(LookSlot.flag, ShipFlag.wave, 1500),
  LookItem(LookSlot.sails, SailColor.green, 2000),
  LookItem(LookSlot.sails, SailColor.gold, 3000),
  LookItem(LookSlot.flag, ShipFlag.star, 4000),
  LookItem(LookSlot.sails, SailColor.purple, 5000),
  LookItem(LookSlot.figurehead, Figurehead.lion, 6000),
  LookItem(LookSlot.flag, ShipFlag.sun, 8000),
  // Aus dem Logbuch zum Ausdrucken (Schatzcode auf der Urkunde).
  LookItem(LookSlot.flag, ShipFlag.anchor, 0, logbook: 'hafen'),
  LookItem(LookSlot.flag, ShipFlag.shell, 0, logbook: 'tauschinsel'),
  LookItem(LookSlot.flag, ShipFlag.bottle, 0, logbook: 'wunschinsel'),
  LookItem(LookSlot.flag, ShipFlag.coin, 0, logbook: 'spar-insel'),
];

/// Schatzcodes aus den Logbüchern: Code → Insel. Nur Aussehen, nichts kaufbar.
const logbookCodes = {'ANKER7': 'hafen', 'MUSCHEL3': 'tauschinsel', 'FLASCHE5': 'wunschinsel', 'TALER9': 'spar-insel'};

/// Insel zum eingetippten Code, egal ob groß, klein, mit Leerzeichen oder Strich; sonst `null`.
String? logbookForCode(String input) => logbookCodes[input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '')];

/// Teil, das der Schatzcode der Insel [logbook] freischaltet.
LookItem? logbookItem(String logbook) {
  for (final i in shipyardItems) {
    if (i.logbook == logbook) return i;
  }
  return null;
}

/// Alle Möglichkeiten eines Platzes.
List<LookItem> lookOptions(LookSlot slot) => [
  for (final i in shipyardItems)
    if (i.slot == slot) i,
];

/// Teile der Werft (ohne die Starter), die bei [xp] frei sind.
int unlockedShipyardCount(int xp) => shipyardItems.where((i) => i.minXp > 0 && i.unlockedAt(xp)).length;

/// Das nächste Teil, das noch gesperrt ist, oder `null`, wenn alles frei ist.
LookItem? nextShipyardItem(int xp) {
  for (final i in shipyardItems) {
    if (i.logbook == null && !i.unlockedAt(xp)) return i;
  }
  return null;
}

/// Ein Teil anziehen oder hissen.
AvatarConfig wearLook(AvatarConfig avatar, LookItem item) => switch (item.value) {
  final OutfitColor o => avatar.copyWith(outfit: o),
  final Hat h => avatar.copyWith(hat: h),
  final Scarf s => avatar.copyWith(scarf: s),
  final ShipFlag f => avatar.copyWith(flag: f),
  final SailColor c => avatar.copyWith(sails: c),
  final Figurehead g => avatar.copyWith(figurehead: g),
  _ => avatar,
};

/// Trägt der Avatar dieses Teil gerade?
bool wearsLook(AvatarConfig avatar, LookItem item) => switch (item.value) {
  final OutfitColor o => avatar.outfit == o,
  final Hat h => avatar.hat == h,
  final Scarf s => avatar.scarf == s,
  final ShipFlag f => avatar.flag == f,
  final SailColor c => avatar.sails == c,
  final Figurehead g => avatar.figurehead == g,
  _ => false,
};
