import 'package:flutter/services.dart';

import 'asset_manifest.dart';

/// Lädt das Asset-Manifest und prüft, welche Dateien es schon gibt.
class AssetRepository {
  AssetRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const manifestPath = 'assets/asset_manifest.json';

  /// Diese Arten kann die App heute schon anzeigen. Für Rive, Lottie, Filme
  /// und Ton kommt das passende Paket dazu, sobald die erste echte Datei da ist.
  /// Bis dahin erscheint immer der Platzhalter.
  static const supportedTypes = {AssetType.image};

  final AssetBundle _bundle;

  /// Das App-Paket, aus dem die Dateien kommen.
  AssetBundle get bundle => _bundle;
  final Map<String, bool> _availability = {};

  Future<TaleriaAssetManifest> loadManifest() async {
    final source = await _bundle.loadString(manifestPath, cache: false);
    return TaleriaAssetManifest.parse(source);
  }

  /// `true`, wenn die echte Datei im App-Paket liegt und angezeigt werden kann.
  Future<bool> isAvailable(AssetEntry entry) async {
    final path = entry.path;
    if (path == null || !supportedTypes.contains(entry.type)) return false;
    final cached = _availability[path];
    if (cached != null) return cached;
    bool available;
    try {
      await _bundle.load(path);
      available = true;
    } catch (_) {
      available = false;
    }
    return _availability[path] = available;
  }
}
