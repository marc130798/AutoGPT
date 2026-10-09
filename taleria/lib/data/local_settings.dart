import 'package:shared_preferences/shared_preferences.dart';

/// Kleine Einstellungen, die nur auf diesem Gerät gelten.
abstract interface class LocalSettings {
  /// Kind, das gerade auf dem Eltern-Gerät spielt (`null` = keins).
  Future<String?> activeChildId(String parentUserId);

  Future<void> setActiveChildId(String parentUserId, String? childId);
}

class SharedPreferencesSettings implements LocalSettings {
  static String _key(String parentUserId) => 'active_child_id.$parentUserId';

  @override
  Future<String?> activeChildId(String parentUserId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(parentUserId));
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
