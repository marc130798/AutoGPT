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

  /// Startseite seit 17.11.2026: das Schiff im Schnitt (oben Deck, darunter Räume zum Antippen).
  static const homeShip = 'home.ship';

  /// Hintergrund der Werft (BILDER.md Bild 176). Bis er da ist: [homeBackground].
  static const shipyardBackground = 'shipyard.background';

  /// Hafenbecken der Werft und das eigene Schiff von der Seite (Bühne oben in der Werft).
  static const shipyardDock = 'shipyard.dock';
  static const shipSide = 'ship.side';
  static const shipSideSails = 'ship.side.sails';
  static const iconMap = 'icon.map';
  static const iconTreasure = 'icon.treasure';
  static const iconTasks = 'icon.tasks';
  static const iconBadges = 'icon.badges';
  static const iconCollection = 'icon.collection';
  static const iconGames = 'icon.games';

  /// Schatztruhe (Kinderbereich): Hintergrund und Bilder (BILDER.md, Abschnitt 4f).
  /// Die Schatztruhe selbst zeigt [iconTreasure].
  static const treasureBackground = 'treasure.background';
  static const potSpend = 'pot.spend';
  static const potGive = 'pot.give';
  static const iconLedger = 'icon.ledger';
  static const iconWish = 'icon.wish';

  /// Hintergründe von Aufträgen und Orden (BILDER.md, Abschnitt 4g).
  static const tasksBackground = 'tasks.background';
  static const badgesBackground = 'badges.background';

  static const underwaterBackground = 'underwater.background';
  static const pearl = 'collectible.pearl';

  /// Musik und Töne (`tool/musik_vorbereiten.py`, `tool/toene_erzeugen.py`).
  static const musicHome = 'music.home';
  static const soundCorrect = 'sound.correct';
  static const soundPearl = 'sound.pearl';
  static const soundStationDone = 'sound.station_done';
  static const soundIslandDone = 'sound.island_done';

  /// Münze gelegt (Münzen legen, Kasse, Markt).
  static const soundCoin = 'sound.coin';

  /// Kurze Töne mit ElevenLabs (`tool/klaenge_erzeugen.py`, 16.11.2026).
  static const soundChestOpen = 'sound.chest_open';
  static const soundBadgeHang = 'sound.badge_hang';
  static const soundMapUnroll = 'sound.map_unroll';
  static const soundSplash = 'sound.splash';
  static const soundWhale = 'sound.whale';
  static const soundDive = 'sound.dive';
  static const soundPage = 'sound.page';
  static const soundUnlock = 'sound.unlock';
  static const soundRankUp = 'sound.rank_up';
  static const soundShipBell = 'sound.ship_bell';
  static const soundFogRise = 'sound.fog_rise';
  static const soundBottle = 'sound.bottle';
  static const soundTool = 'sound.tool';

  /// Klangkulissen statt Stille in den Missionen (leise, in Schleife, wie die
  /// Musik im Hauptmenü und mit demselben Schalter im Leuchtturm).
  static const ambienceUnderwater = 'amb.underwater';
  static const ambienceOpenSea = 'amb.open_sea';
  static const ambienceFog = 'amb.fog';
  static const ambienceShipyard = 'amb.shipyard';

  /// Klang einer Insel (`amb.hafen` …); fehlt die Datei, bleibt es still.
  static String islandAmbience(String slug) => 'amb.$slug';

  /// Alle kurzen Töne: Im Browser werden sie beim ersten Antippen einmal stumm
  /// angespielt, damit das iPhone sie später auch ohne Antippen spielt.
  static const effects = [
    soundCorrect,
    soundPearl,
    soundStationDone,
    soundIslandDone,
    soundCoin,
    soundChestOpen,
    soundBadgeHang,
    soundMapUnroll,
    soundSplash,
    soundWhale,
    soundDive,
    soundPage,
    soundUnlock,
    soundRankUp,
    soundShipBell,
    soundFogRise,
    soundBottle,
    soundTool,
  ];

  static const ambiences = [
    ambienceUnderwater,
    ambienceOpenSea,
    ambienceFog,
    ambienceShipyard,
    'amb.hafen',
    'amb.tauschinsel',
    'amb.wunschinsel',
    'amb.spar-insel',
  ];

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
    homeShip,
    iconMap,
    iconTreasure,
    iconTasks,
    iconBadges,
    iconCollection,
    treasureBackground,
    potSpend,
    potGive,
    iconLedger,
    iconWish,
    tasksBackground,
    badgesBackground,
    introVideo,
    logo,
    musicHome,
    ...effects,
    ...ambiences,
    underwaterBackground,
    pearl,
  ];
}
