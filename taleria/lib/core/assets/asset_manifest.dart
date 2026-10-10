import 'dart:convert';
import 'dart:ui' show Color, Offset;

/// Art einer Datei aus dem Asset-Manifest.
enum AssetType { image, rive, lottie, video, audio }

/// Form des Platzhalters, solange die echte Datei fehlt.
enum PlaceholderShape { circle, rounded, rectangle }

class AssetPlaceholderSpec {
  const AssetPlaceholderSpec({required this.label, required this.color, required this.shape});

  /// Name, der auf dem Platzhalter steht (z. B. „Talo“).
  final String label;
  final Color color;
  final PlaceholderShape shape;
}

/// Ein Eintrag im Manifest: fester Schlüssel → Datei + Platzhalter.
class AssetEntry {
  const AssetEntry({required this.key, required this.type, required this.path, required this.placeholder, this.route});

  /// Fester Schlüssel, z. B. `character.talo` oder `video.intro`.
  final String key;
  final AssetType type;

  /// Pfad im App-Paket (`assets/...`). `null`, wenn es die Datei noch nicht gibt
  /// (z. B. Filme, die später in Supabase Storage liegen).
  final String? path;
  final AssetPlaceholderSpec placeholder;

  /// Weg durch das Bild, falls es einen hat (zum Beispiel vom Steg zum Marktplatz
  /// einer Insel): Punkte von 0 bis 1, x von links, y von oben. Darauf setzt die
  /// App die Stationen. Gehört zum Bild, weil er genau dessen Weg nachzeichnet.
  final List<Offset>? route;

  /// Erster Teil des Schlüssels, z. B. `character` bei `character.talo`.
  String get category => key.split('.').first;
}

class AssetManifestException implements Exception {
  AssetManifestException(this.message);

  final String message;

  @override
  String toString() => 'AssetManifestException: $message';
}

/// Die zentrale Liste aller Grafiken, Animationen und Filme.
///
/// Austausch einer Grafik = Datei ablegen und Pfad hier eintragen.
/// Kein Umbau im Code.
class TaleriaAssetManifest {
  TaleriaAssetManifest(Map<String, AssetEntry> entries) : _entries = Map.unmodifiable(entries);

  static final _keyPattern = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z0-9_-]+)+$');
  static final _colorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  final Map<String, AssetEntry> _entries;

  /// Liest das Manifest aus JSON. Wirft [AssetManifestException] mit einer
  /// verständlichen Meldung, wenn ein Eintrag kaputt ist.
  factory TaleriaAssetManifest.parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw AssetManifestException('Kein gültiges JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic> || decoded['assets'] is! Map<String, dynamic>) {
      throw AssetManifestException('Es fehlt der Bereich "assets"');
    }
    final assets = decoded['assets'] as Map<String, dynamic>;
    final entries = <String, AssetEntry>{};
    for (final MapEntry(:key, :value) in assets.entries) {
      entries[key] = _parseEntry(key, value);
    }
    return TaleriaAssetManifest(entries);
  }

  static AssetEntry _parseEntry(String key, Object? raw) {
    if (!_keyPattern.hasMatch(key)) {
      throw AssetManifestException('Ungültiger Schlüssel "$key" (Beispiel: character.talo)');
    }
    if (raw is! Map<String, dynamic>) {
      throw AssetManifestException('"$key" ist kein Objekt');
    }
    final type = AssetType.values.asNameMap()[raw['type']];
    if (type == null) {
      throw AssetManifestException('"$key" hat einen unbekannten Typ: ${raw['type']}');
    }
    final path = raw['path'];
    if (path != null && (path is! String || !path.startsWith('assets/'))) {
      throw AssetManifestException('"$key": Pfad muss mit "assets/" beginnen oder null sein');
    }
    final placeholder = raw['placeholder'];
    if (placeholder is! Map<String, dynamic>) {
      throw AssetManifestException('"$key" braucht einen Platzhalter');
    }
    final label = placeholder['label'];
    if (label is! String || label.trim().isEmpty) {
      throw AssetManifestException('"$key": Platzhalter braucht einen Namen (label)');
    }
    final color = placeholder['color'];
    if (color is! String || !_colorPattern.hasMatch(color)) {
      throw AssetManifestException('"$key": Farbe muss wie #E8792B aussehen');
    }
    final shape = PlaceholderShape.values.asNameMap()[placeholder['shape'] ?? 'rounded'];
    if (shape == null) {
      throw AssetManifestException('"$key": unbekannte Form ${placeholder['shape']}');
    }
    final route = raw['route'];
    List<Offset>? points;
    if (route != null) {
      if (route is! List || route.length < 2) {
        throw AssetManifestException('"$key": route braucht mindestens zwei Punkte');
      }
      points = [];
      for (final point in route) {
        if (point is! List || point.length != 2 || point.any((v) => v is! num || v < 0 || v > 1)) {
          throw AssetManifestException('"$key": jeder Punkt der route ist [x, y] mit Werten von 0 bis 1');
        }
        points.add(Offset((point[0] as num).toDouble(), (point[1] as num).toDouble()));
      }
    }
    return AssetEntry(
      key: key,
      type: type,
      route: points,
      path: path as String?,
      placeholder: AssetPlaceholderSpec(
        label: label,
        color: Color(0xFF000000 | int.parse(color.substring(1), radix: 16)),
        shape: shape,
      ),
    );
  }

  Iterable<AssetEntry> get entries => _entries.values;

  int get length => _entries.length;

  bool contains(String key) => _entries.containsKey(key);

  /// Liefert den Eintrag zum Schlüssel. Unbekannte Schlüssel ergeben einen
  /// grauen Platzhalter mit dem Schlüssel als Namen, nie einen Absturz.
  AssetEntry lookup(String key) {
    return _entries[key] ??
        AssetEntry(
          key: key,
          type: AssetType.image,
          path: null,
          placeholder: AssetPlaceholderSpec(
            label: key,
            color: const Color(0xFF9E9E9E),
            shape: PlaceholderShape.rounded,
          ),
        );
  }
}
