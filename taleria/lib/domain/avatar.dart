/// Avatar des Kindes als Baukasten. Gespeichert als kleines JSON in
/// `children.avatar`. Die Werte sind feste Namen, das Aussehen dazu legt die
/// Oberfläche fest (heute einfache Formen, später Grafiken).
library;

/// Mensch oder Tier (FIGUREN.md: „Mensch oder Tier nach Wahl“).
enum Species { human, cat, dog, bear, rabbit, mouse }

/// Haut- oder Fellfarbe, je nach [Species].
enum SkinTone { s1, s2, s3, s4, s5, s6 }

enum HairStyle { short, long, curly, braid, none }

enum HairColor { black, brown, blond, red, grey }

/// Die ersten sechs gibt es von Anfang an, [teal] und [gold] schaltet die Werft frei.
enum OutfitColor { navy, red, green, yellow, purple, orange, teal, gold }

/// Die ersten vier gibt es von Anfang an, [tricorn] und [goldCaptain] schaltet die Werft frei.
enum Hat { none, captain, bandana, straw, tricorn, goldCaptain }

/// Halstuch, nur aus der Werft (Belohnung für Seemeilen).
enum Scarf { none, red, gold }

/// Flagge am Mast des eigenen Schiffs, auf der Startseite und auf der Karte.
enum ShipFlag { taleria, stripes, wave, star, sun }

class AvatarConfig {
  const AvatarConfig({
    this.species = Species.human,
    this.skin = SkinTone.s3,
    this.hairStyle = HairStyle.short,
    this.hairColor = HairColor.brown,
    this.outfit = OutfitColor.navy,
    this.hat = Hat.captain,
    this.scarf = Scarf.none,
    this.flag = ShipFlag.taleria,
  });

  /// Liest gespeicherte Werte. Unbekannte oder fehlende Werte werden zum
  /// Standard, damit ein alter oder kaputter Eintrag nie zum Absturz führt.
  factory AvatarConfig.fromJson(Map<String, dynamic>? json) {
    const fallback = AvatarConfig();
    if (json == null) return fallback;
    T pick<T extends Enum>(List<T> values, String key, T orElse) => values.asNameMap()[json[key]] ?? orElse;
    return AvatarConfig(
      species: pick(Species.values, 'species', fallback.species),
      skin: pick(SkinTone.values, 'skin', fallback.skin),
      hairStyle: pick(HairStyle.values, 'hair', fallback.hairStyle),
      hairColor: pick(HairColor.values, 'hairColor', fallback.hairColor),
      outfit: pick(OutfitColor.values, 'outfit', fallback.outfit),
      hat: pick(Hat.values, 'hat', fallback.hat),
      scarf: pick(Scarf.values, 'scarf', fallback.scarf),
      flag: pick(ShipFlag.values, 'flag', fallback.flag),
    );
  }

  /// Version des Formats, falls sich der Baukasten später ändert.
  static const formatVersion = 1;

  final Species species;
  final SkinTone skin;
  final HairStyle hairStyle;
  final HairColor hairColor;
  final OutfitColor outfit;
  final Hat hat;
  final Scarf scarf;
  final ShipFlag flag;

  Map<String, dynamic> toJson() => {
    'v': formatVersion,
    'species': species.name,
    'skin': skin.name,
    'hair': hairStyle.name,
    'hairColor': hairColor.name,
    'outfit': outfit.name,
    'hat': hat.name,
    'scarf': scarf.name,
    'flag': flag.name,
  };

  bool get isAnimal => species != Species.human;

  AvatarConfig copyWith({
    Species? species,
    SkinTone? skin,
    HairStyle? hairStyle,
    HairColor? hairColor,
    OutfitColor? outfit,
    Hat? hat,
    Scarf? scarf,
    ShipFlag? flag,
  }) {
    return AvatarConfig(
      species: species ?? this.species,
      skin: skin ?? this.skin,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      outfit: outfit ?? this.outfit,
      hat: hat ?? this.hat,
      scarf: scarf ?? this.scarf,
      flag: flag ?? this.flag,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AvatarConfig &&
      other.species == species &&
      other.skin == skin &&
      other.hairStyle == hairStyle &&
      other.hairColor == hairColor &&
      other.outfit == outfit &&
      other.hat == hat &&
      other.scarf == scarf &&
      other.flag == flag;

  @override
  int get hashCode => Object.hash(species, skin, hairStyle, hairColor, outfit, hat, scarf, flag);
}
