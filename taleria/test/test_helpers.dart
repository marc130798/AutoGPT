import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:taleria/app.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/assets/asset_manifest.dart';
import 'package:taleria/core/assets/asset_repository.dart';
import 'package:taleria/core/backend/backend.dart';
import 'package:taleria/core/config/app_config.dart';
import 'package:taleria/services/session_controller.dart';

import 'fakes.dart';

/// Ein App-Paket im Speicher: enthält nur die Dateien, die der Test angibt.
class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this.files);

  final Map<String, Uint8List> files;

  @override
  Future<ByteData> load(String key) async {
    // Flutter sucht Bilder über dieses Verzeichnis (für 2x- und 3x-Varianten).
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final path in files.keys)
          path: [
            {'asset': path},
          ],
      })!;
    }
    final bytes = files[key];
    if (bytes == null) throw StateError('Datei fehlt: $key');
    return ByteData.sublistView(bytes);
  }
}

class FakeHealthCheck implements BackendHealthCheck {
  FakeHealthCheck(this.status);

  final BackendStatus status;

  @override
  Future<BackendStatus> check() async => status;
}

TaleriaAssetManifest realManifest() =>
    TaleriaAssetManifest.parse(File('assets/asset_manifest.json').readAsStringSync());

/// Kleinstes gültiges PNG (1 × 1 Pixel).
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

/// Baut die App für Widget-Tests.
///
/// Ohne [backend] läuft sie wie ohne Server (Vorschau). Mit [backend] gegen
/// den nachgebauten Server aus fakes.dart.
TaleriaApp buildTestApp({
  AppEnvironment environment = AppEnvironment.test,
  BackendStatus backendStatus = BackendStatus.notConfigured,
  Map<String, Uint8List> files = const {},
  FakeBackend? backend,
  FakeLocalSettings? settings,
}) {
  final family = backend == null ? null : FakeFamilyRepository(backend);
  final session = SessionController(
    auth: backend == null ? null : FakeAuthRepository(backend),
    family: family,
    settings: settings ?? FakeLocalSettings(),
  )..start();
  return TaleriaApp(
    services: AppServices(
      config: AppConfig(
        environment: environment,
        supabaseUrl: environment == AppEnvironment.live ? 'https://live.supabase.co' : '',
        supabasePublishableKey: environment == AppEnvironment.live ? 'sb_publishable_x' : '',
      ),
      assets: AssetRepository(bundle: FakeAssetBundle(files)),
      manifest: realManifest(),
      backendHealth: FakeHealthCheck(backendStatus),
      session: session,
      family: family,
      children: backend == null ? null : FakeChildRepository(backend),
    ),
  );
}
