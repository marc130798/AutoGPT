import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Was im Adminbereich schiefgehen kann.
enum AdminFailureKind {
  /// E-Mail oder Passwort falsch.
  invalidCredentials,

  /// Zwei-Faktor-Code falsch oder abgelaufen.
  invalidCode,

  /// Keine Berechtigung für diese Rolle oder ohne Zwei-Faktor.
  notAllowed,

  /// Die Datenbank lehnt ab und sagt warum (zum Beispiel: Grund fehlt).
  rejected,

  /// Konto nicht gefunden.
  notFound,
  network,
  unknown,
}

class AdminFailure implements Exception {
  const AdminFailure(this.kind, [this.message = '']);

  final AdminFailureKind kind;

  /// Meldung des Servers (bei [AdminFailureKind.rejected] auf Deutsch und zum Anzeigen gedacht).
  final String message;

  @override
  String toString() => 'AdminFailure($kind, $message)';
}

/// Führt eine Server-Anfrage aus und übersetzt Fehler in [AdminFailure].
/// Ohne dart:io, damit der Adminbereich im Browser läuft.
Future<T> guardAdmin<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AdminFailure {
    rethrow;
  } on sb.AuthRetryableFetchException catch (e) {
    throw AdminFailure(AdminFailureKind.network, e.message);
  } on sb.AuthException catch (e) {
    final kind = switch (e.code) {
      'invalid_credentials' => AdminFailureKind.invalidCredentials,
      'mfa_verification_failed' ||
      'mfa_challenge_expired' ||
      'mfa_verification_rejected' => AdminFailureKind.invalidCode,
      _ => AdminFailureKind.unknown,
    };
    throw AdminFailure(kind, '${e.code}: ${e.message}');
  } on sb.PostgrestException catch (e) {
    final kind = switch (e.code) {
      '42501' => AdminFailureKind.notAllowed,
      'P0002' => AdminFailureKind.notFound,
      'P0001' || '22023' => AdminFailureKind.rejected,
      _ => AdminFailureKind.unknown,
    };
    throw AdminFailure(kind, e.message);
  } on TimeoutException catch (e) {
    throw AdminFailure(AdminFailureKind.network, '$e');
  } on Exception catch (e) {
    // Netzwerkfehler des HTTP-Pakets heißen ClientException.
    final isNetwork = e.runtimeType.toString() == 'ClientException';
    throw AdminFailure(isNetwork ? AdminFailureKind.network : AdminFailureKind.unknown, '$e');
  }
}
