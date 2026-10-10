import 'package:flutter/foundation.dart';

import '../data/admin_auth.dart';
import '../data/admin_failure.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

/// Wo steht die Anmeldung im Adminbereich?
enum AdminStage {
  loading,
  signedOut,

  /// Passwort stimmt, Zwei-Faktor-App muss noch eingerichtet werden.
  enrollMfa,

  /// Passwort stimmt, Code aus der Zwei-Faktor-App fehlt.
  verifyMfa,

  /// Das Konto ist kein Admin (wurde wieder abgemeldet).
  notAdmin,
  ready,
}

/// Ablauf der Anmeldung: Passwort → Admin? → Zwei-Faktor einrichten oder Code → fertig.
/// Erst mit Zwei-Faktor gelten die Admin-Rechte in der Datenbank.
class AdminSession extends ChangeNotifier {
  AdminSession({required this.auth, required this.repository});

  final AdminAuth auth;
  final AdminRepository repository;

  AdminStage _stage = AdminStage.loading;
  AdminStage get stage => _stage;

  AdminIdentity? _identity;
  AdminIdentity? get identity => _identity;

  TotpSetup? _setup;

  /// Daten zum Einrichten der Zwei-Faktor-App (nur in [AdminStage.enrollMfa]).
  TotpSetup? get setup => _setup;

  AdminFailure? _error;
  AdminFailure? get error => _error;

  bool _busy = false;
  bool get busy => _busy;

  Future<void> start() => _run(() async {
    if (!auth.hasSession) {
      _stage = AdminStage.signedOut;
      return;
    }
    await _continueAfterPassword();
  }, onError: () => _stage = AdminStage.signedOut);

  Future<void> signIn({required String email, required String password}) => _run(() async {
    await auth.signIn(email: email, password: password);
    await _continueAfterPassword();
  });

  Future<void> confirmSetup(String code) => _run(() async {
    final setup = _setup;
    if (setup == null) return;
    await auth.confirmTotpSetup(setup, code);
    _setup = null;
    await _finish();
  });

  Future<void> verify(String code) => _run(() async {
    await auth.verifyTotp(code);
    await _finish();
  });

  Future<void> signOut() => _run(() async {
    try {
      await auth.signOut();
    } finally {
      _identity = null;
      _setup = null;
      _stage = AdminStage.signedOut;
    }
  });

  /// Von „Kein Admin-Zugang“ zurück zur Anmeldung.
  void backToLogin() {
    _stage = AdminStage.signedOut;
    _error = null;
    notifyListeners();
  }

  Future<void> _continueAfterPassword() async {
    final identity = await repository.whoami();
    if (identity == null) {
      // Eltern-Konten und andere haben hier nichts zu suchen.
      await auth.signOut();
      _identity = null;
      _stage = AdminStage.notAdmin;
      return;
    }
    _identity = identity;
    if (identity.mfa) {
      _stage = AdminStage.ready;
      return;
    }
    switch (await auth.mfaStatus()) {
      case MfaStatus.done:
        await _finish();
      case MfaStatus.verify:
        _stage = AdminStage.verifyMfa;
      case MfaStatus.enroll:
        _setup = await auth.startTotpSetup();
        _stage = AdminStage.enrollMfa;
    }
  }

  Future<void> _finish() async {
    final identity = await repository.whoami();
    if (identity == null || !identity.mfa) {
      throw const AdminFailure(AdminFailureKind.notAllowed, 'Zwei-Faktor-Anmeldung nicht erkannt');
    }
    _identity = identity;
    _stage = AdminStage.ready;
  }

  Future<void> _run(Future<void> Function() action, {VoidCallback? onError}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on AdminFailure catch (e) {
      _error = e;
      onError?.call();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
