import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Eigenes Fehlerprotokoll der App (report_app_error), ohne Nutzer und ohne Gerät.
abstract interface class ErrorLogRepository {
  /// Nur mit Anmeldung möglich (Eltern oder Kinder-Gerät).
  bool get canReport;

  Future<void> reportError({required String platform, required String error, String? stack});
}

class SupabaseErrorLogRepository implements ErrorLogRepository {
  SupabaseErrorLogRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  bool get canReport => _client.auth.currentSession != null;

  @override
  Future<void> reportError({required String platform, required String error, String? stack}) async {
    await _client.rpc<void>('report_app_error', params: {'p_platform': platform, 'p_error': error, 'p_stack': stack});
  }
}
