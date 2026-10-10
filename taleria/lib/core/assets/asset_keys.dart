/// Posen von Talo und Tala (BILDER.md, Abschnitt 4c): winken (Begrüßung),
/// freut sich (geschafft), nachdenken (Tipp, Frage).
enum CharacterPose { wave, happy, think }

/// Feste Schlüssel für Grafiken, Animationen und Filme, die der Code direkt
/// verwendet. Die Zuordnung zur Datei steht in `assets/asset_manifest.json`.
abstract final class AssetKeys {
  static const talo = 'character.talo';
  static const tala = 'character.tala';
  static const taleron = 'character.taleron';
  static const avatar = 'character.avatar';

  /// Eine Pose von Talo oder Tala, zum Beispiel `character.talo.wave`.
  static String pose(String character, CharacterPose pose) => '$character.${pose.name}';

  static const crewShip = 'ship.crew';
  static const mapBackground = 'map.background';
  static const mapFog = 'map.fog';
  static const mapLock = 'map.lock';

  /// Wolken für den Nebel-Start und die Inseln im Nebel (BILDER.md, Bild 6).
  /// Nur die längliche Wolke (entschieden mit Marc); sie wird gespiegelt und
  /// verschieden groß gezeigt.
  static const mapClouds = ['map.cloud.1'];

  static const lighthouse = 'parent.lighthouse';

  /// Startseite des Kindes: Hintergrund und Bilder der Kacheln (BILDER.md, Abschnitt 4).
  static const homeBackground = 'home.background';
  static const iconMap = 'icon.map';
  static const iconTreasure = 'icon.treasure';
  static const iconTasks = 'icon.tasks';
  static const iconBadges = 'icon.badges';
  static const iconCollection = 'icon.collection';

  static const underwaterBackground = 'underwater.background';
  static const pearl = 'collectible.pearl';

  static const introVideo = 'video.intro';
  static const logo = 'brand.logo';

  static String islandBackground(String slug) => 'island.$slug.background';

  /// Die Insel, wie sie auf der Karte liegt (freigestellt, BILDER.md).
  static String mapIsland(String slug) => 'map.island.$slug';
  static String arrivalVideo(String slug) => 'video.arrival.$slug';
  static String islandBadge(String slug) => 'badge.$slug';
  static String rank(String slug) => 'rank.$slug';

  /// Alle festen Schlüssel oben, damit ein Test prüfen kann, dass sie im
  /// Manifest stehen.
  static final all = [
    for (final character in [talo, tala])
      for (final p in CharacterPose.values) pose(character, p),
    talo,
    tala,
    taleron,
    avatar,
    crewShip,
    mapBackground,
    mapFog,
    mapLock,
    ...mapClouds,
    lighthouse,
    homeBackground,
    iconMap,
    iconTreasure,
    iconTasks,
    iconBadges,
    iconCollection,
    introVideo,
    logo,
    underwaterBackground,
    pearl,
  ];
}
