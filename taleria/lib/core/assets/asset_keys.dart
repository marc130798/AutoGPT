/// Feste Schlüssel für Grafiken, Animationen und Filme, die der Code direkt
/// verwendet. Die Zuordnung zur Datei steht in `assets/asset_manifest.json`.
abstract final class AssetKeys {
  static const talo = 'character.talo';
  static const tala = 'character.tala';
  static const taleron = 'character.taleron';
  static const avatar = 'character.avatar';

  static const crewShip = 'ship.crew';
  static const mapBackground = 'map.background';
  static const mapFog = 'map.fog';
  static const mapLock = 'map.lock';

  static const lighthouse = 'parent.lighthouse';

  static const underwaterBackground = 'underwater.background';
  static const pearl = 'collectible.pearl';

  static const introVideo = 'video.intro';
  static const logo = 'brand.logo';

  static String islandBackground(String slug) => 'island.$slug.background';
  static String arrivalVideo(String slug) => 'video.arrival.$slug';
  static String islandBadge(String slug) => 'badge.$slug';
  static String rank(String slug) => 'rank.$slug';

  /// Alle festen Schlüssel oben, damit ein Test prüfen kann, dass sie im
  /// Manifest stehen.
  static const all = [
    talo,
    tala,
    taleron,
    avatar,
    crewShip,
    mapBackground,
    mapFog,
    mapLock,
    introVideo,
    logo,
    underwaterBackground,
    pearl,
  ];
}
