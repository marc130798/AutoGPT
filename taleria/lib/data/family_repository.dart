import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/avatar.dart';
import '../domain/family_models.dart';
import 'backend_errors.dart';

/// Eltern-Konto, Kinder-Profile, Anmelde-Codes und Eltern-PIN.
/// Alle Rechte prüft die Datenbank (Row Level Security und Funktionen).
abstract interface class FamilyRepository {
  /// Eltern-Konto der aktuellen Sitzung, `null` bei Kinder-Geräten.
  Future<ParentAccount?> fetchParent();

  /// Eltern: alle eigenen Kinder. Kinder-Gerät: nur das eigene Profil.
  Future<List<ChildProfile>> fetchChildren();

  Future<ChildProfile> createChild({
    required String parentId,
    required String nickname,
    required int birthYear,
    required LevelSetting level,
  });

  Future<ChildProfile> updateChild(ChildProfile child);

  Future<void> deleteChild(String childId);

  Future<LoginCode> createLoginCode(String childId);

  /// Löst einen Code auf dem Kinder-Gerät ein. `null` bei falschem,
  /// abgelaufenem oder schon benutztem Code.
  Future<ChildProfile?> redeemLoginCode(String code);

  Future<int> countChildDevices(String childId);

  Future<void> signOutChildDevices(String childId);

  Future<void> setParentPin(String pin);

  Future<PinCheckResult> verifyParentPin(String pin);

  Future<void> deleteMyAccount();

  /// Abo des Eltern-Kontos.
  Future<Subscription> fetchSubscription();

  /// Nur in der Testumgebung: Abo testweise ein- oder ausschalten.
  Future<void> setTestPremium({required bool active});
}

class SupabaseFamilyRepository implements FamilyRepository {
  SupabaseFamilyRepository(this._client);

  final sb.SupabaseClient _client;

  // Nie "*" abfragen: die PIN-Prüfsumme ist für die App gesperrt.
  static const _parentColumns = 'id, user_id, has_parent_pin';
  static const _childColumns =
      'id, nickname, birth_year, level_setting, stage, avatar, ship_name, onboarding_completed_at';

  @override
  Future<ParentAccount?> fetchParent() => guardBackend(() async {
    final row = await _client.from('parents').select(_parentColumns).maybeSingle();
    if (row == null) return null;
    return ParentAccount(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      hasPin: row['has_parent_pin'] as bool,
    );
  });

  @override
  Future<List<ChildProfile>> fetchChildren() => guardBackend(() async {
    final rows = await _client.from('children').select(_childColumns).order('created_at');
    return rows.map(_childFromRow).toList();
  });

  @override
  Future<ChildProfile> createChild({
    required String parentId,
    required String nickname,
    required int birthYear,
    required LevelSetting level,
  }) => guardBackend(() async {
    final row = await _client
        .from('children')
        .insert({
          'parent_id': parentId,
          'nickname': nickname.trim(),
          'birth_year': birthYear,
          'level_setting': level.code,
          // Gebaut wird nur Stufe 1.
          'stage': 1,
        })
        .select(_childColumns)
        .single();
    return _childFromRow(row);
  });

  @override
  Future<ChildProfile> updateChild(ChildProfile child) => guardBackend(() async {
    final row = await _client
        .from('children')
        .update({'nickname': child.nickname.trim(), 'birth_year': child.birthYear, 'level_setting': child.level.code})
        .eq('id', child.id)
        .select(_childColumns)
        .single();
    return _childFromRow(row);
  });

  @override
  Future<void> deleteChild(String childId) =>
      guardBackend(() => _client.rpc<void>('delete_child', params: {'p_child_id': childId}));

  @override
  Future<LoginCode> createLoginCode(String childId) => guardBackend(() async {
    final rows = await _client.rpc<List<dynamic>>('create_child_login_code', params: {'p_child_id': childId});
    final row = rows.single as Map<String, dynamic>;
    return LoginCode(
      code: row['login_code'] as String,
      validUntil: DateTime.parse(row['valid_until'] as String).toLocal(),
    );
  });

  @override
  Future<ChildProfile?> redeemLoginCode(String code) => guardBackend(() async {
    final rows = await _client.rpc<List<dynamic>>('redeem_child_login_code', params: {'p_code': code});
    if (rows.isEmpty) return null;
    final children = await fetchChildren();
    return children.isEmpty ? null : children.first;
  });

  @override
  Future<int> countChildDevices(String childId) => guardBackend(() async {
    final response = await _client.from('child_devices').select('id').eq('child_id', childId).count();
    return response.count;
  });

  @override
  Future<void> signOutChildDevices(String childId) =>
      guardBackend(() => _client.rpc<void>('sign_out_child_devices', params: {'p_child_id': childId}));

  @override
  Future<void> setParentPin(String pin) =>
      guardBackend(() => _client.rpc<void>('set_parent_pin', params: {'p_pin': pin}));

  @override
  Future<PinCheckResult> verifyParentPin(String pin) => guardBackend(() async {
    final rows = await _client.rpc<List<dynamic>>('verify_parent_pin', params: {'p_pin': pin});
    final row = rows.single as Map<String, dynamic>;
    final status = switch (row['status']) {
      'ok' => PinCheckStatus.ok,
      'locked' => PinCheckStatus.locked,
      'not_set' => PinCheckStatus.notSet,
      _ => PinCheckStatus.wrong,
    };
    final lockedUntil = row['locked_until'] as String?;
    return PinCheckResult(status, lockedUntil: lockedUntil == null ? null : DateTime.parse(lockedUntil).toLocal());
  });

  @override
  Future<void> deleteMyAccount() => guardBackend(() => _client.rpc<void>('delete_my_account'));

  @override
  Future<Subscription> fetchSubscription() => guardBackend(() async {
    final result = await _client.rpc<Map<String, dynamic>>('my_subscription');
    return Subscription.fromJson(result);
  });

  @override
  Future<void> setTestPremium({required bool active}) =>
      guardBackend(() => _client.rpc<void>('set_test_premium', params: {'p_active': active}));

  static ChildProfile _childFromRow(Map<String, dynamic> row) {
    final avatar = row['avatar'] as Map<String, dynamic>?;
    return ChildProfile(
      id: row['id'] as String,
      nickname: row['nickname'] as String,
      birthYear: row['birth_year'] as int,
      level: LevelSetting.fromCode(row['level_setting'] as String?),
      stage: row['stage'] as int,
      // Leeres Objekt = noch kein Avatar gestaltet.
      avatar: avatar == null || avatar.isEmpty ? null : AvatarConfig.fromJson(avatar),
      shipName: row['ship_name'] as String?,
      onboardingCompleted: row['onboarding_completed_at'] != null,
    );
  }
}
