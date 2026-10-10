import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/admin_models.dart';
import 'admin_failure.dart';

/// Anmeldung im Adminbereich: Passwort und danach immer Zwei-Faktor (TOTP-App).
abstract interface class AdminAuth {
  bool get hasSession;

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  /// Wie weit ist die Zwei-Faktor-Anmeldung?
  Future<MfaStatus> mfaStatus();

  /// Legt eine neue Zwei-Faktor-App an (noch unbestätigt).
  Future<TotpSetup> startTotpSetup();

  /// Bestätigt die neue App mit dem ersten Code. Danach gilt die Anmeldung als Zwei-Faktor.
  Future<void> confirmTotpSetup(TotpSetup setup, String code);

  /// Prüft den Code der eingerichteten App.
  Future<void> verifyTotp(String code);
}

class SupabaseAdminAuth implements AdminAuth {
  SupabaseAdminAuth(this._client);

  final sb.SupabaseClient _client;

  sb.GoTrueMFAApi get _mfa => _client.auth.mfa;

  @override
  bool get hasSession => _client.auth.currentSession != null;

  @override
  Future<void> signIn({required String email, required String password}) => guardAdmin(() async {
    await _client.auth.signInWithPassword(email: email.trim(), password: password);
  });

  @override
  Future<void> signOut() => guardAdmin(() => _client.auth.signOut());

  @override
  Future<MfaStatus> mfaStatus() => guardAdmin(() async {
    if (_mfa.getAuthenticatorAssuranceLevel().currentLevel == sb.AuthenticatorAssuranceLevels.aal2) {
      return MfaStatus.done;
    }
    final factors = await _mfa.listFactors();
    return factors.totp.isEmpty ? MfaStatus.enroll : MfaStatus.verify;
  });

  @override
  Future<TotpSetup> startTotpSetup() => guardAdmin(() async {
    // Reste eines abgebrochenen Versuchs entfernen, sonst lehnt Supabase den Namen ab.
    final factors = await _mfa.listFactors();
    for (final factor in factors.all) {
      if (factor.factorType == sb.FactorType.totp && factor.status != sb.FactorStatus.verified) {
        await _mfa.unenroll(factor.id);
      }
    }
    final response = await _mfa.enroll(
      factorType: sb.FactorType.totp,
      issuer: 'Taleria',
      friendlyName: 'Taleria Admin',
    );
    final totp = response.totp;
    if (totp == null) throw const AdminFailure(AdminFailureKind.unknown, 'Keine TOTP-Daten');
    return TotpSetup(factorId: response.id, secret: totp.secret, uri: totp.uri);
  });

  @override
  Future<void> confirmTotpSetup(TotpSetup setup, String code) => guardAdmin(() async {
    await _mfa.challengeAndVerify(factorId: setup.factorId, code: code.trim());
  });

  @override
  Future<void> verifyTotp(String code) => guardAdmin(() async {
    final factors = await _mfa.listFactors();
    if (factors.totp.isEmpty) throw const AdminFailure(AdminFailureKind.notAllowed, 'Keine Zwei-Faktor-App');
    await _mfa.challengeAndVerify(factorId: factors.totp.first.id, code: code.trim());
  });
}
