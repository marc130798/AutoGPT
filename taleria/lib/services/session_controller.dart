import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../data/family_repository.dart';
import '../data/local_settings.dart';
import '../domain/family_models.dart';
import '../domain/validators.dart';

/// Fassung des Einwilligungstextes, die bei der Registrierung gespeichert wird.
/// Bei jeder Änderung des Textes in app_de.arb hochzählen.
/// Der Text ist ein Entwurf und muss vor dem Start rechtlich geprüft werden.
const consentVersion = '2026-10-entwurf';

/// Wer benutzt die App gerade, und was darf er sehen?
sealed class SessionState {
  const SessionState();
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

/// Kein Server eingerichtet: nur die Vorschau ohne Konto.
class SessionOffline extends SessionState {
  const SessionOffline();
}

class SessionSignedOut extends SessionState {
  const SessionSignedOut();
}

/// Eltern-Sitzung. Ohne PIN muss erst eine festgelegt werden. Der Leuchtturm
/// ist nur offen, wenn [unlocked] (frisch angemeldet oder PIN eingegeben).
class SessionParent extends SessionState {
  const SessionParent(this.parent, {required this.unlocked, this.returnChild});

  final ParentAccount parent;
  final bool unlocked;

  /// Kind, das vor dem Tipp auf den Leuchtturm auf diesem Gerät gespielt hat.
  final ChildProfile? returnChild;
}

/// Kinderbereich. [onParentDevice]: Das Kind spielt auf dem Gerät der Eltern.
class SessionChild extends SessionState {
  const SessionChild(this.child, {required this.onParentDevice, this.parent});

  final ChildProfile child;
  final bool onParentDevice;
  final ParentAccount? parent;
}

/// Kinder-Gerät ohne gültige Verbindung zu einem Profil: Code eingeben.
class SessionChildUnlinked extends SessionState {
  const SessionChildUnlinked();
}

enum SessionProblemKind { noParentAccount, loadFailed }

class SessionProblem extends SessionState {
  const SessionProblem(this.kind, [this.failure = FailureKind.unknown]);

  final SessionProblemKind kind;
  final FailureKind failure;
}

/// Steuert Anmeldung, Eltern-Sperre und den Wechsel zwischen Leuchtturm und
/// Kinderbereich. Kennt kein Aussehen.
class SessionController extends ChangeNotifier {
  SessionController({required this._auth, required this._family, required this._settings, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Nach so langer Zeit im Hintergrund ist der Leuchtturm wieder gesperrt.
  static const relockAfter = Duration(minutes: 5);

  final AuthRepository? _auth;
  final FamilyRepository? _family;
  final LocalSettings _settings;
  final DateTime Function() _clock;

  SessionState _state = const SessionLoading();
  bool _unlocked = false;
  DateTime? _pausedAt;
  StreamSubscription<void>? _signedOutSubscription;

  SessionState get state => _state;

  Future<void> start() async {
    final auth = _auth;
    if (auth == null || _family == null) {
      _set(const SessionOffline());
      return;
    }
    // Endet die Sitzung von außen (z. B. Eltern melden das Kinder-Gerät ab),
    // zurück zum Start.
    _signedOutSubscription = auth.signedOut.listen((_) {
      _unlocked = false;
      unawaited(_evaluate());
    });
    await _evaluate();
  }

  Future<void> retry() => _evaluate();

  /// Lädt Profil und Rechte neu, z. B. nach dem Intro.
  Future<void> refresh() => _evaluate();

  // ---------------------------------------------------------------------------
  // Eltern
  // ---------------------------------------------------------------------------

  /// Gibt `false` zurück, wenn erst die E-Mail bestätigt werden muss.
  Future<bool> registerParent({required String email, required String password, required bool marketingConsent}) async {
    final hasSession = await _auth!.signUpParent(
      email: email,
      password: password,
      consentVersion: consentVersion,
      marketingConsent: marketingConsent,
      locale: 'de',
    );
    if (hasSession) {
      _unlocked = true;
      await _evaluate();
    }
    return hasSession;
  }

  /// Wer sich gerade mit Passwort angemeldet hat, braucht keine PIN.
  Future<void> signInParent({required String email, required String password}) async {
    await _auth!.signInParent(email: email, password: password);
    _unlocked = true;
    await _evaluate();
  }

  Future<void> setParentPin(String pin) async {
    if (validatePin(pin) != null) throw ArgumentError.value(pin, 'pin');
    await _family!.setParentPin(pin);
    _unlocked = true;
    await _evaluate();
  }

  Future<PinCheckResult> unlockWithPin(String pin) async {
    final result = await _family!.verifyParentPin(pin);
    if (result.status == PinCheckStatus.ok) {
      _unlocked = true;
      final user = _auth!.currentUser;
      if (user != null) await _settings.setActiveChildId(user.id, null);
      await _evaluate();
    }
    return result;
  }

  /// Gibt das Eltern-Gerät an ein Kind. Zurück geht es nur mit PIN.
  Future<void> handOverToChild(ChildProfile child) async {
    final user = _auth!.currentUser!;
    await _settings.setActiveChildId(user.id, child.id);
    _unlocked = false;
    await _evaluate();
  }

  /// Kind tippt auf dem Eltern-Gerät auf den Leuchtturm: PIN-Abfrage zeigen.
  void requestParentArea() {
    final current = _state;
    if (current is SessionChild && current.onParentDevice && current.parent != null) {
      _set(SessionParent(current.parent!, unlocked: false, returnChild: current.child));
    }
  }

  /// Von der PIN-Abfrage zurück zum Kind, ohne etwas zu öffnen. Lädt das
  /// Profil neu, damit z. B. ein gerade gestalteter Avatar zu sehen ist.
  Future<void> returnToChild() async {
    if (_state is SessionParent && (_state as SessionParent).returnChild != null) {
      await _evaluate();
    }
  }

  Future<void> deleteAccount() async {
    await _family!.deleteMyAccount();
    await _signOutQuietly();
  }

  // ---------------------------------------------------------------------------
  // Kinder-Gerät
  // ---------------------------------------------------------------------------

  /// Löst einen Anmelde-Code ein. `false` bei falschem oder abgelaufenem Code.
  Future<bool> redeemChildCode(String input) async {
    final auth = _auth!;
    if (auth.currentUser == null) await auth.signInChildDevice();
    final child = await _family!.redeemLoginCode(normalizeLoginCode(input));
    if (child == null) return false;
    await _evaluate();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Allgemein
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    _unlocked = false;
    await _auth!.signOut();
    await _evaluate();
  }

  /// App geht in den Hintergrund oder kommt zurück. Nach [relockAfter] im
  /// Hintergrund ist der Leuchtturm wieder gesperrt.
  void appPaused() => _pausedAt = _clock();

  void appResumed() {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    final current = _state;
    if (pausedAt == null || current is! SessionParent || !current.unlocked) return;
    if (_clock().difference(pausedAt) >= relockAfter) {
      _unlocked = false;
      _set(SessionParent(current.parent, unlocked: false));
    }
  }

  Future<void> _signOutQuietly() async {
    _unlocked = false;
    try {
      await _auth!.signOut();
    } on AppFailure {
      // Das Konto ist schon gelöscht, die lokale Sitzung ist trotzdem weg.
    }
    await _evaluate();
  }

  Future<void> _evaluate() async {
    final auth = _auth!;
    final family = _family!;
    final user = auth.currentUser;
    try {
      if (user == null) {
        _set(const SessionSignedOut());
        return;
      }
      if (user.isAnonymous) {
        final children = await family.fetchChildren();
        _set(children.isEmpty ? const SessionChildUnlinked() : SessionChild(children.first, onParentDevice: false));
        return;
      }

      final parent = await family.fetchParent();
      if (parent == null) {
        _set(const SessionProblem(SessionProblemKind.noParentAccount));
        return;
      }

      final activeChildId = await _settings.activeChildId(user.id);
      if (activeChildId != null) {
        final children = await family.fetchChildren();
        final child = children.where((c) => c.id == activeChildId).firstOrNull;
        if (child != null) {
          _set(SessionChild(child, onParentDevice: true, parent: parent));
          return;
        }
        await _settings.setActiveChildId(user.id, null);
      }
      _set(SessionParent(parent, unlocked: _unlocked));
    } on AppFailure catch (e) {
      _set(SessionProblem(SessionProblemKind.loadFailed, e.kind));
    }
  }

  void _set(SessionState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _signedOutSubscription?.cancel();
    super.dispose();
  }
}
