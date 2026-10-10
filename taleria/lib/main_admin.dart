import 'dart:async';

import 'package:flutter/widgets.dart';

import 'admin/admin_app.dart';
import 'admin/admin_scope.dart';
import 'admin/data/admin_auth.dart';
import 'admin/data/admin_repository.dart';
import 'admin/services/admin_session.dart';
import 'core/backend/backend.dart';
import 'core/config/app_config.dart';

/// Einstieg für den Adminbereich (Web). Getrennt von lib/main.dart, damit der
/// Admin-Code nie in die Kinder- und Eltern-App gelangt.
///
///     flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env/test.json
///     flutter build web -t lib/main_admin.dart --dart-define-from-file=env/live.json
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final client = await initBackend(config);
  final repository = client == null ? null : SupabaseAdminRepository(client);
  final session = client == null ? null : AdminSession(auth: SupabaseAdminAuth(client), repository: repository!);
  if (session != null) unawaited(session.start());

  runApp(
    AdminApp(
      services: AdminServices(config: config, session: session, repository: repository),
    ),
  );
}
