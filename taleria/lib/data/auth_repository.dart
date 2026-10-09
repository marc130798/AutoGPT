import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/family_models.dart';
import 'backend_errors.dart';

/// Anmeldung über Supabase Auth.
abstract interface class AuthRepository {
  AuthUser? get currentUser;

  /// Meldet sich, wenn die Sitzung von außen endet (z. B. Gerät abgemeldet).
  Stream<void> get signedOut;

  /// Registriert Eltern. Die Einwilligung wird mitgeschickt und in der
  /// Datenbank mit Zeitpunkt gespeichert. Gibt `true` zurück, wenn die
  /// Sitzung sofort startet, `false`, wenn erst die E-Mail bestätigt werden muss.
  Future<bool> signUpParent({
    required String email,
    required String password,
    required String consentVersion,
    required bool marketingConsent,
    required String locale,
  });

  Future<void> signInParent({required String email, required String password});

  /// Anonyme Sitzung für ein Kinder-Gerät.
  Future<void> signInChildDevice();

  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  AuthUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AuthUser(id: user.id, isAnonymous: user.isAnonymous);
  }

  @override
  Stream<void> get signedOut =>
      _client.auth.onAuthStateChange.where((s) => s.event == sb.AuthChangeEvent.signedOut).map((_) {});

  @override
  Future<bool> signUpParent({
    required String email,
    required String password,
    required String consentVersion,
    required bool marketingConsent,
    required String locale,
  }) {
    return guardBackend(() async {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'taleria_role': 'parent',
          'consent_version': consentVersion,
          'marketing_consent': marketingConsent,
          'locale': locale,
        },
      );
      return response.session != null;
    });
  }

  @override
  Future<void> signInParent({required String email, required String password}) {
    return guardBackend(() => _client.auth.signInWithPassword(email: email.trim(), password: password));
  }

  @override
  Future<void> signInChildDevice() => guardBackend(() => _client.auth.signInAnonymously());

  @override
  Future<void> signOut() => guardBackend(() => _client.auth.signOut());
}
