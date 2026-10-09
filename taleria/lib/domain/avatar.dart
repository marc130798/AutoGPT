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

enum OutfitColor { navy, red, green, yellow, purple, orange }

enum Hat { none, captain, bandana, straw }

class AvatarConfig {
  const AvatarConfig({
    this.species = Species.human,
    this.skin = SkinTone.s3,
    this.hairStyle = HairStyle.short,
    this.hairColor = HairColor.brown,
    this.outfit = OutfitColor.navy,
    this.hat = Hat.captain,
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

  Map<String, dynamic> toJson() => {
    'v': formatVersion,
    'species': species.name,
    'skin': skin.name,
    'hair': hairStyle.name,
    'hairColor': hairColor.name,
    'outfit': outfit.name,
    'hat': hat.name,
  };

  bool get isAnimal => species != Species.human;

  AvatarConfig copyWith({
    Species? species,
    SkinTone? skin,
    HairStyle? hairStyle,
    HairColor? hairColor,
    OutfitColor? outfit,
    Hat? hat,
  }) {
    return AvatarConfig(
      species: species ?? this.species,
      skin: skin ?? this.skin,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      outfit: outfit ?? this.outfit,
      hat: hat ?? this.hat,
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
      other.hat == hat;

  @override
  int get hashCode => Object.hash(species, skin, hairStyle, hairColor, outfit, hat);
}
