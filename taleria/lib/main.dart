import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/app_scope.dart';
import 'core/assets/asset_manifest.dart';
import 'core/assets/asset_repository.dart';
import 'core/backend/backend.dart';
import 'core/config/app_config.dart';
import 'core/config/orientation_policy.dart';
import 'data/auth_repository.dart';
import 'data/backend_errors.dart';
import 'data/budget_repository.dart';
import 'data/child_repository.dart';
import 'data/content_repository.dart';
import 'data/error_log_repository.dart';
import 'data/family_repository.dart';
import 'data/local_settings.dart';
import 'services/audio_sounds.dart';
import 'services/error_reporting.dart';
import 'services/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  await _lockOrientation();

  final client = await initBackend(config);
  if (client != null) {
    // Fehlerprotokoll für die Beta: ohne Nutzer, ohne Gerät, ohne Drittanbieter.
    final reporter = AppErrorReporter(SupabaseErrorLogRepository(client), platform: AppErrorReporter.platformName());
    installErrorReporting(reporter);
    onUnexpectedBackendError = (error, stack) => unawaited(reporter.report(error, stack));
  }

  final assets = AssetRepository();
  TaleriaAssetManifest manifest;
  Object? manifestError;
  try {
    manifest = await assets.loadManifest();
  } catch (e) {
    // Kaputtes Manifest: weiterlaufen, alle Grafiken als graue Platzhalter.
    debugPrint('Asset-Manifest konnte nicht geladen werden: $e');
    manifest = TaleriaAssetManifest(const {});
    manifestError = e;
  }

  final family = client == null ? null : SupabaseFamilyRepository(client);
  final settings = SharedPreferencesSettings();
  final session = SessionController(
    auth: client == null ? null : SupabaseAuthRepository(client),
    family: family,
    settings: settings,
  );
  // Nicht abwarten: Bis die Sitzung geprüft ist, zeigt die App einen Ladekreis.
  unawaited(session.start());
  final sounds = AudioSounds(manifest: manifest, assets: assets, settings: settings);
  unawaited(sounds.load());

  runApp(
    TaleriaApp(
      services: AppServices(
        config: config,
        assets: assets,
        manifest: manifest,
        manifestError: manifestError,
        backendHealth: SupabaseHealthCheck(client),
        session: session,
        family: family,
        children: client == null ? null : SupabaseChildRepository(client),
        content: client == null ? null : SupabaseContentRepository(client),
        progress: client == null ? null : SupabaseProgressRepository(client),
        settings: settings,
        budget: client == null ? null : SupabaseBudgetRepository(client),
        sounds: sounds,
      ),
    ),
  );
}

/// Smartphone nur Hochformat, Tablet auch Querformat.
Future<void> _lockOrientation() async {
  final view = PlatformDispatcher.instance.implicitView;
  final shortestSide = view == null ? 0.0 : view.physicalSize.shortestSide / view.devicePixelRatio;
  await SystemChrome.setPreferredOrientations(allowedOrientations(shortestSide));
}
