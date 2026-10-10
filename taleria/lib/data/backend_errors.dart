import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/family_models.dart';

/// Wird bei unerwarteten Daten vom Server aufgerufen (Fehlerprotokoll, Schritt 11).
/// Setzt lib/main.dart; ohne Server bleibt es leer.
void Function(Object error, StackTrace stack)? onUnexpectedBackendError;

/// Führt eine Server-Anfrage aus und übersetzt Fehler in [AppFailure].
/// So muss die Oberfläche nichts über Supabase wissen.
Future<T> guardBackend<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppFailure {
    rethrow;
  } on TypeError catch (e, stack) {
    // Unerwartete Daten vom Server (zum Beispiel ein leeres Feld): lieber eine
    // Fehlermeldung mit „Nochmal versuchen“ als ein Ladekreis, der nie aufhört.
    onUnexpectedBackendError?.call(e, stack);
    throw AppFailure(FailureKind.unknown, '$e');
  } on sb.AuthException catch (e) {
    throw AppFailure(authFailureKind(e), '${e.code}: ${e.message}');
  } on sb.PostgrestException catch (e) {
    throw AppFailure(postgrestFailureKind(e), '${e.code}: ${e.message}');
  } on SocketException catch (e) {
    throw AppFailure(FailureKind.network, e.message);
  } on TimeoutException catch (e) {
    throw AppFailure(FailureKind.network, e.message);
  } on Exception catch (e) {
    // Netzwerkfehler des HTTP-Pakets heißen ClientException.
    final isNetwork = e.runtimeType.toString() == 'ClientException';
    throw AppFailure(isNetwork ? FailureKind.network : FailureKind.unknown, '$e');
  }
}

FailureKind postgrestFailureKind(sb.PostgrestException e) {
  // 42501: keine Berechtigung (z. B. fremdes Kinder-Profil).
  if (e.code == '42501') return FailureKind.notAllowed;
  // Meldung der Buchungsfunktionen, wenn eine Truhe ins Minus gehen würde.
  if (e.message.contains('Nicht genug Guthaben')) return FailureKind.notEnoughMoney;
  // Tempo: submit_station(), wenn für eine neue Station kein Wind da ist.
  if (e.message.contains('braucht Wind')) return FailureKind.noWind;
  // Abo-Grenze, zum Beispiel ein weiteres Kinder-Profil ohne Abo.
  if (e.message.contains('mit dem Abo')) return FailureKind.premiumRequired;
  return FailureKind.unknown;
}

FailureKind authFailureKind(sb.AuthException e) {
  if (e is sb.AuthRetryableFetchException) return FailureKind.network;
  return switch (e.code) {
    'invalid_credentials' => FailureKind.invalidCredentials,
    'email_not_confirmed' => FailureKind.emailNotConfirmed,
    'user_already_exists' || 'email_exists' => FailureKind.emailTaken,
    'weak_password' => FailureKind.weakPassword,
    'over_request_rate_limit' || 'over_email_send_rate_limit' => FailureKind.rateLimited,
    _ => FailureKind.unknown,
  };
}
