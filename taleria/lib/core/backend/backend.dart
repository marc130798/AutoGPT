import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Startet die Verbindung zu Supabase, wenn Zugangsdaten eingetragen sind.
/// Ohne Zugangsdaten läuft die App ohne Server weiter (nur Testumgebung).
Future<SupabaseClient?> initBackend(AppConfig config) async {
  if (!config.hasBackend) return null;
  try {
    final supabase = await Supabase.initialize(url: config.supabaseUrl, publishableKey: config.supabasePublishableKey);
    return supabase.client;
  } catch (e, stack) {
    debugPrint('Supabase konnte nicht gestartet werden: $e\n$stack');
    return null;
  }
}

enum BackendStatus { notConfigured, ready, schemaMissing, unreachable }

/// Prüft, ob der Server erreichbar ist und die Tabellen angelegt sind.
abstract interface class BackendHealthCheck {
  Future<BackendStatus> check();
}

class SupabaseHealthCheck implements BackendHealthCheck {
  SupabaseHealthCheck(this._client, {this.timeout = const Duration(seconds: 8)});

  final SupabaseClient? _client;
  final Duration timeout;

  @override
  Future<BackendStatus> check() async {
    final client = _client;
    if (client == null) return BackendStatus.notConfigured;
    try {
      // Ohne Anmeldung liefert die Row Level Security keine Zeilen, aber die
      // Abfrage beweist, dass Server und Tabelle da sind.
      await client.from('islands').select('id').limit(1).timeout(timeout);
      return BackendStatus.ready;
    } on PostgrestException catch (e) {
      // 42P01: Tabelle fehlt in Postgres, PGRST205: Tabelle der API unbekannt.
      if (e.code == '42P01' || e.code == 'PGRST205') return BackendStatus.schemaMissing;
      return BackendStatus.unreachable;
    } catch (_) {
      return BackendStatus.unreachable;
    }
  }
}
