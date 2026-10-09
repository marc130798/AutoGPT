import 'package:flutter/widgets.dart';

import 'assets/asset_manifest.dart';
import 'assets/asset_repository.dart';
import 'backend/backend.dart';
import 'config/app_config.dart';

/// Alles, was die App zum Laufen braucht, an einer Stelle.
class AppServices {
  const AppServices({
    required this.config,
    required this.assets,
    required this.manifest,
    required this.backendHealth,
    this.manifestError,
  });

  final AppConfig config;
  final AssetRepository assets;
  final TaleriaAssetManifest manifest;
  final BackendHealthCheck backendHealth;

  /// Gesetzt, wenn das Manifest nicht geladen werden konnte. Die App läuft
  /// dann mit grauen Platzhaltern weiter.
  final Object? manifestError;
}

/// Gibt [AppServices] an alle Bildschirme weiter.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope fehlt über diesem Widget');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
