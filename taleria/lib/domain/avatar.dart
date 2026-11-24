/// Avatar des Kindes als Baukasten. Gespeichert als kleines JSON in
/// `children.avatar`. Die Werte sind feste Namen, das Aussehen dazu legt die
/// Oberfläche fest (heute einfache Formen, später Grafiken).
library;

/// Die Figur des Kindes seit 16.11.2026 (mit Marc entschieden): ein junger
/// Löwe oder eine junge Löwin im 3D-Stil von Talo und Tala (BILDER.md 4r).
/// Die alten Werte (Art, Haut, Haare, Jacke, Hut, Halstuch) bleiben im JSON
/// lesbar, werden aber nicht mehr gezeigt.
enum PlayerFigure { lion, lioness }

/// Mensch oder Tier (früherer Baukasten, nicht mehr sichtbar).
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
enum Scarf { none, red, gold, purple }

/// Flagge am Mast des eigenen Schiffs, auf der Startseite und auf der Karte.
enum ShipFlag { taleria, stripes, wave, star, sun, anchor, shell, coin, bottle, book, crew, crewGold }

/// Farbe der Segel des eigenen Schiffs (die App färbt die Segel ein).
enum SailColor { white, red, blue, green, gold, purple, coral }

/// Galionsfigur vorne am Bug.
enum Figurehead { none, dolphin, lion }

/// Farbe von Shirt und Hose der Figur (die weißen Streifen bleiben weiß).
/// Blau und Rosa wählt das Kind im Intro, die anderen gibt es in der Werft.
enum ClothesColor { blue, pink, green, red, turquoise, yellow, purple }

/// Kleidungsstück der Figur (Marcs Wunsch am 17.11.2026): Ringel-Shirt von
/// Anfang an, die anderen gibt es nach geschafften Inseln. Alle sind im Bild
/// blau-weiß und lassen sich in jeder [ClothesColor] tragen.
enum Garment { stripes, sailor, vest, hoodie, raincoat, beach }

/// Seit 17.11.2026 (Marcs Wunsch) starten Löwe und Löwin gleich, ohne Farbe nach Geschlecht.

class AvatarConfig {
  const AvatarConfig({
    this.figure = PlayerFigure.lion,
    this.species = Species.human,
    this.skin = SkinTone.s3,
    this.hairStyle = HairStyle.short,
    this.hairColor = HairColor.brown,
    this.outfit = OutfitColor.navy,
    this.hat = Hat.captain,
    this.scarf = Scarf.none,
    this.flag = ShipFlag.taleria,
    this.sails = SailColor.white,
    this.figurehead = Figurehead.none,
    this.clothes = ClothesColor.blue,
    this.garment = Garment.stripes,
    this.logbooks = const {},
  });

  /// Liest gespeicherte Werte. Unbekannte oder fehlende Werte werden zum
  /// Standard, damit ein alter oder kaputter Eintrag nie zum Absturz führt.
  factory AvatarConfig.fromJson(Map<String, dynamic>? json) {
    const fallback = AvatarConfig();
    if (json == null) return fallback;
    T pick<T extends Enum>(List<T> values, String key, T orElse) => values.asNameMap()[json[key]] ?? orElse;
    return AvatarConfig(
      figure: pick(PlayerFigure.values, 'figure', fallback.figure),
      species: pick(Species.values, 'species', fallback.species),
      skin: pick(SkinTone.values, 'skin', fallback.skin),
      hairStyle: pick(HairStyle.values, 'hair', fallback.hairStyle),
      hairColor: pick(HairColor.values, 'hairColor', fallback.hairColor),
      outfit: pick(OutfitColor.values, 'outfit', fallback.outfit),
      hat: pick(Hat.values, 'hat', fallback.hat),
      scarf: pick(Scarf.values, 'scarf', fallback.scarf),
      flag: pick(ShipFlag.values, 'flag', fallback.flag),
      sails: pick(SailColor.values, 'sails', fallback.sails),
      figurehead: pick(Figurehead.values, 'figurehead', fallback.figurehead),
      clothes: pick(ClothesColor.values, 'clothes', fallback.clothes),
      garment: pick(Garment.values, 'garment', fallback.garment),
      logbooks: {
        for (final l in (json['logbooks'] as List?) ?? const [])
          if (l is String) l,
      },
    );
  }

  /// Version des Formats, falls sich der Baukasten später ändert.
  static const formatVersion = 1;

  /// Löwe oder Löwin. Wer vorher eine andere Figur hatte, bekommt den Löwen.
  final PlayerFigure figure;
  final Species species;
  final SkinTone skin;
  final HairStyle hairStyle;
  final HairColor hairColor;
  final OutfitColor outfit;
  final Hat hat;
  final Scarf scarf;
  final ShipFlag flag;
  final SailColor sails;
  final Figurehead figurehead;
  final ClothesColor clothes;
  final Garment garment;

  /// Inseln, deren Schatzcode aus dem Logbuch das Kind eingelöst hat (zum Beispiel `hafen`).
  final Set<String> logbooks;

  Map<String, dynamic> toJson() => {
    'v': formatVersion,
    'figure': figure.name,
    'species': species.name,
    'skin': skin.name,
    'hair': hairStyle.name,
    'hairColor': hairColor.name,
    'outfit': outfit.name,
    'hat': hat.name,
    'scarf': scarf.name,
    'flag': flag.name,
    'sails': sails.name,
    'figurehead': figurehead.name,
    'clothes': clothes.name,
    'garment': garment.name,
    if (logbooks.isNotEmpty) 'logbooks': [...logbooks]..sort(),
  };

  bool get isAnimal => species != Species.human;

  AvatarConfig copyWith({
    PlayerFigure? figure,
    Species? species,
    SkinTone? skin,
    HairStyle? hairStyle,
    HairColor? hairColor,
    OutfitColor? outfit,
    Hat? hat,
    Scarf? scarf,
    ShipFlag? flag,
    SailColor? sails,
    Figurehead? figurehead,
    ClothesColor? clothes,
    Garment? garment,
    Set<String>? logbooks,
  }) {
    return AvatarConfig(
      figure: figure ?? this.figure,
      species: species ?? this.species,
      skin: skin ?? this.skin,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      outfit: outfit ?? this.outfit,
      hat: hat ?? this.hat,
      scarf: scarf ?? this.scarf,
      flag: flag ?? this.flag,
      sails: sails ?? this.sails,
      clothes: clothes ?? this.clothes,
      garment: garment ?? this.garment,
      figurehead: figurehead ?? this.figurehead,
      logbooks: logbooks ?? this.logbooks,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AvatarConfig &&
      other.figure == figure &&
      other.species == species &&
      other.skin == skin &&
      other.hairStyle == hairStyle &&
      other.hairColor == hairColor &&
      other.outfit == outfit &&
      other.hat == hat &&
      other.scarf == scarf &&
      other.flag == flag &&
      other.sails == sails &&
      other.figurehead == figurehead &&
      other.logbooks.length == logbooks.length &&
      other.logbooks.containsAll(logbooks);

  @override
  int get hashCode => Object.hash(
    figure,
    species,
    skin,
    hairStyle,
    hairColor,
    outfit,
    hat,
    scarf,
    flag,
    sails,
    figurehead,
    Object.hashAllUnordered(logbooks),
  );
}
