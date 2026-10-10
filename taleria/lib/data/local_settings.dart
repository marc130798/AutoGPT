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

  /// Insel, an der das Schiff zuletzt auf der Karte lag. Ist inzwischen eine
  /// neue Insel offen, segelt das Schiff beim nächsten Öffnen dorthin.
  Future<String?> lastShipIsland(String childId);

  Future<void> setLastShipIsland(String childId, String islandId);

  /// Ton an (Lautsprecher-Knopf des Kindes). Standard: an.
  Future<bool> soundOn();

  Future<void> setSoundOn(bool on);

  /// Musik im Hauptmenü erlaubt (Schalter im Leuchtturm). Standard: ja.
  Future<bool> musicAllowed();

  Future<void> setMusicAllowed(bool allowed);
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
  Future<void> setActiveChildId(String parentUserId, String? childId) async {
    final prefs = await SharedPreferences.getInstance();
    if (childId == null) {
      await prefs.remove(_key(parentUserId));
    } else {
      await prefs.setString(_key(parentUserId), childId);
    }
  }
}
