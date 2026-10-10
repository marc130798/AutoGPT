import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/admin_models.dart';
import 'admin_failure.dart';

/// Daten des Adminbereichs. Jede Funktion prüft Rolle und Zwei-Faktor in der
/// Datenbank (supabase/migrations/…_admin.sql), nicht hier.
abstract interface class AdminRepository {
  /// `null`, wenn die Anmeldung kein Admin ist.
  Future<AdminIdentity?> whoami();

  Future<AdminOverview> overview();

  Future<ContentStats> contentStats(int stage);

  Future<EnvironmentSettings> environmentSettings();

  /// Sucht ein Eltern-Konto per E-Mail (landet mit Grund im Audit-Log).
  Future<FamilyInfo?> findFamily({required String email, required String reason});

  /// Abo von Hand vergeben oder entfernen. Gibt zurück, ob die Familie danach ein Abo hat.
  Future<bool> setPremium({
    required String parentId,
    required bool active,
    required String reason,
    DateTime? validUntil,
  });

  /// Löscht das Eltern-Konto mit allen Kindern und Daten.
  Future<void> deleteFamily({required String parentId, required String reason});

  Future<List<AuditEntry>> auditLog({int limit = 100});
}

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<AdminIdentity?> whoami() => guardAdmin(() async {
    final result = await _client.rpc<dynamic>('admin_whoami');
    return AdminIdentity.fromJson(result as Map<String, dynamic>?);
  });

  @override
  Future<AdminOverview> overview() => guardAdmin(() async {
    final result = await _client.rpc<dynamic>('admin_overview');
    return AdminOverview.fromJson(result as Map<String, dynamic>);
  });

  @override
  Future<ContentStats> contentStats(int stage) => guardAdmin(() async {
    final result = await _client.rpc<dynamic>('admin_content_stats', params: {'p_stage': stage});
    return ContentStats.fromJson(result as Map<String, dynamic>);
  });

  @override
  Future<EnvironmentSettings> environmentSettings() => guardAdmin(() async {
    final rows = await _client.from('app_settings').select('key, value');
    return EnvironmentSettings.fromRows(rows);
  });

  @override
  Future<FamilyInfo?> findFamily({required String email, required String reason}) => guardAdmin(() async {
    final result = await _client.rpc<dynamic>('admin_find_family', params: {'p_email': email, 'p_reason': reason});
    return result == null ? null : FamilyInfo.fromJson(result as Map<String, dynamic>);
  });

  @override
  Future<bool> setPremium({
    required String parentId,
    required bool active,
    required String reason,
    DateTime? validUntil,
  }) => guardAdmin(() async {
    final result = await _client.rpc<dynamic>(
      'admin_set_premium',
      params: {
        'p_parent_id': parentId,
        'p_active': active,
        'p_valid_until': validUntil?.toUtc().toIso8601String(),
        'p_reason': reason,
      },
    );
    return (result as Map<String, dynamic>)['premium'] as bool? ?? false;
  });

  @override
  Future<void> deleteFamily({required String parentId, required String reason}) => guardAdmin(() async {
    await _client.rpc<dynamic>('admin_delete_family', params: {'p_parent_id': parentId, 'p_reason': reason});
  });

  @override
  Future<List<AuditEntry>> auditLog({int limit = 100}) => guardAdmin(() async {
    final rows = await _client.rpc<dynamic>('admin_audit_recent', params: {'p_limit': limit});
    return [for (final r in rows as List) AuditEntry.fromJson(r as Map<String, dynamic>)];
  });
}
