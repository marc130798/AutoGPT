import 'package:shared_preferences/shared_preferences.dart';

/// Kleine Einstellungen, die nur auf diesem Gerät gelten.
abstract interface class LocalSettings {
  /// Kind, das gerade auf dem Eltern-Gerät spielt (`null` = keins).
  Future<String?> activeChildId(String parentUserId);

  Future<void> setActiveChildId(String parentUserId, String? childId);

  /// Fragen des letzten Durchgangs einer Station, damit dieselbe
  /// Zusammenstellung nicht zweimal hintereinander kommt.
  Future<Set<String>?> lastQuizSelection(String childId, String stationId);

  Future<void> setLastQuizSelection(String childId, String stationId, Set<String> questionIds);

  /// Hat das Kind die Ankunft auf dieser Insel schon gesehen?
  Future<bool> arrivalSeen(String childId, String islandId);

  Future<void> setArrivalSeen(String childId, String islandId);

  /// Wo das Schiff zuletzt auf der Karte lag: eine Insel oder ein Stopp auf
  /// See. Darf es inzwischen weiter, segelt es beim nächsten Öffnen dorthin.
  Future<String?> lastShipIsland(String childId);

  Future<void> setLastShipIsland(String childId, String islandId);

  /// Wie viele Funde der Unterwasser-Sammlung das Kind schon gesehen hat.
  /// Nur neuere Funde leuchten auf der Startseite als Zahl auf.
  Future<int> collectionSeen(String childId);

  Future<void> setCollectionSeen(String childId, int finds);

  /// Wie viele Werft-Teile das Kind schon gesehen hat (für die Zahl auf der Kachel).
  Future<int> lookUnlocksSeen(String childId);

  Future<void> setLookUnlocksSeen(String childId, int count);

  /// Ton an (Lautsprecher-Knopf des Kindes). Standard: an.
  Future<bool> soundOn();

  Future<void> setSoundOn(bool on);

  /// Musik im Hauptmenü erlaubt (Schalter im Leuchtturm). Standard: ja.
  Future<bool> musicAllowed();

  Future<void> setMusicAllowed(bool allowed);

  /// Kurzes Vibrieren bei Erfolgen erlaubt (Schalter im Leuchtturm). Standard: ja.
  Future<bool> vibrationAllowed();

  Future<void> setVibrationAllowed(bool allowed);

  /// Stand der Truhen beim letzten Besuch der Schatztruhe (Cent je Truhe),
  /// `null` beim ersten Besuch. Ist seitdem Geld dazugekommen, fliegen Taler hinein.
  Future<Map<String, int>?> potsSeen(String childId);

  Future<void> setPotsSeen(String childId, Map<String, int> cents);

  /// Hat das Kind die Erklärung dieser Menü-Seite (zum Beispiel `tasks`)
  /// schon gesehen? Danach ist sie zugeklappt, ein „?“ zeigt sie wieder.
  Future<bool> pageIntroSeen(String childId, String page);

  Future<void> setPageIntroSeen(String childId, String page);
}

class SharedPreferencesSettings implements LocalSettings {
  static String _key(String parentUserId) => 'active_child_id.$parentUserId';

  @override
  Future<String?> activeChildId(String parentUserId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(parentUserId));
  }

  @override
  Future<Set<String>?> lastQuizSelection(String childId, String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('quiz.$childId.$stationId')?.toSet();
  }

  @override
  Future<void> setLastQuizSelection(String childId, String stationId, Set<String> questionIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('quiz.$childId.$stationId', questionIds.toList());
  }

  @override
  Future<bool> arrivalSeen(String childId, String islandId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('arrival.$childId.$islandId') ?? false;
  }

  @override
  Future<void> setArrivalSeen(String childId, String islandId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('arrival.$childId.$islandId', true);
  }

  @override
  Future<String?> lastShipIsland(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ship.$childId');
  }

  @override
  Future<void> setLastShipIsland(String childId, String islandId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ship.$childId', islandId);
  }

  @override
  Future<int> collectionSeen(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('collection.$childId') ?? 0;
  }

  @override
  Future<void> setCollectionSeen(String childId, int finds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('collection.$childId', finds);
  }

  @override
  Future<int> lookUnlocksSeen(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('shipyard.$childId') ?? 0;
  }

  @override
  Future<void> setLookUnlocksSeen(String childId, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('shipyard.$childId', count);
  }

  @override
  Future<bool> soundOn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sound.on') ?? true;
  }

  @override
  Future<void> setSoundOn(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound.on', on);
  }

  @override
  Future<bool> musicAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sound.music') ?? true;
  }

  @override
  Future<void> setMusicAllowed(bool allowed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound.music', allowed);
  }

  @override
  Future<bool> vibrationAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('vibration') ?? true;
  }

  @override
  Future<void> setVibrationAllowed(bool allowed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration', allowed);
  }

  @override
  Future<Map<String, int>?> potsSeen(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('pots.$childId');
    if (list == null) return null;
    return {
      for (final entry in list)
        if (entry.split('=') case [final pot, final cents] when int.tryParse(cents) != null) pot: int.parse(cents),
    };
  }

  @override
  Future<void> setPotsSeen(String childId, Map<String, int> cents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pots.$childId', [for (final e in cents.entries) '${e.key}=${e.value}']);
  }

  @override
  Future<bool> pageIntroSeen(String childId, String page) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('intro.$childId.$page') ?? false;
  }

  @override
  Future<void> setPageIntroSeen(String childId, String page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro.$childId.$page', true);
  }

  @override
  Future<void> setActiveChildId(String parentUserId, String? childId) async {
    final prefs = await SharedPreferences.getInstance();
    if (childId == null) {
      await prefs.remove(_key(parentUserId));
    } else {
      await prefs.setString(_key(parentUserId), childId);
    }
  }
}
