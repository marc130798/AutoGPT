import 'dart:async';

import 'package:taleria/data/auth_repository.dart';
import 'package:taleria/data/child_repository.dart';
import 'package:taleria/data/family_repository.dart';
import 'package:taleria/data/local_settings.dart';
import 'package:taleria/domain/avatar.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/domain/validators.dart';

/// Nachbau des Servers im Speicher. Bildet die wichtigsten Regeln der
/// Datenbank nach (wer was sehen darf), damit Oberfläche und Logik ohne
/// echten Server getestet werden können. Die echten Regeln testet
/// tool/db_test.sh.
class FakeBackend {
  /// Wenn `true`, startet nach der Registrierung keine Sitzung (E-Mail bestätigen).
  bool requireEmailConfirmation = false;

  /// Wenn gesetzt, schlägt jede Anfrage mit diesem Fehler fehl.
  FailureKind? failWith;

  final Map<String, ({String password, String userId})> accounts = {};
  final Map<String, ParentAccount> parentsByUser = {};
  final Map<String, String> pins = {};
  final Map<String, String> childParent = {};
  final List<ChildProfile> children = [];
  final Map<String, ({String childId, DateTime validUntil, bool used})> codes = {};
  final Map<String, String> devices = {};
  final StreamController<void> signedOutEvents = StreamController<void>.broadcast();
  final List<({String childId, String title, int targetCents})> savingsGoals = [];
  final Map<String, int> xpByChild = {};

  AuthUser? currentUser;
  int _nextId = 1;
  String nextCode = 'ABCD2345';

  String newId(String prefix) => '$prefix-${_nextId++}';

  void check() {
    final failure = failWith;
    if (failure != null) throw AppFailure(failure);
  }

  /// Registriert Eltern direkt (für Tests, die angemeldet starten).
  ParentAccount addParent({String email = 'eltern@test.invalid', String password = 'sehrgeheim123', String? pin}) {
    final userId = newId('user');
    accounts[email] = (password: password, userId: userId);
    final parent = ParentAccount(id: newId('parent'), userId: userId, hasPin: pin != null);
    parentsByUser[userId] = parent;
    if (pin != null) pins[parent.id] = pin;
    return parent;
  }

  /// Legt ein Kind an. Standard: Intro schon erledigt, damit Tests direkt im
  /// Kinderbereich starten.
  ChildProfile addChild(
    ParentAccount parent, {
    String nickname = 'Mila',
    int birthYear = 2015,
    bool onboardingCompleted = true,
  }) {
    final child = ChildProfile(
      id: newId('child'),
      nickname: nickname,
      birthYear: birthYear,
      level: LevelSetting.beginner,
      onboardingCompleted: onboardingCompleted,
      shipName: onboardingCompleted ? 'Seestern' : null,
      avatar: onboardingCompleted ? const AvatarConfig() : null,
    );
    children.add(child);
    childParent[child.id] = parent.id;
    return child;
  }

  void signInAs(String email) {
    currentUser = AuthUser(id: accounts[email]!.userId, isAnonymous: false);
  }

  /// Wie in der Datenbank: Eltern melden ein Kinder-Gerät ab.
  void signOutDevice(String deviceUserId) {
    devices.remove(deviceUserId);
    if (currentUser?.id == deviceUserId) {
      currentUser = null;
      signedOutEvents.add(null);
    }
  }

  ParentAccount? get currentParent => currentUser == null ? null : parentsByUser[currentUser!.id];

  /// Wie can_act_for_child() in der Datenbank.
  bool canActFor(String childId) {
    final user = currentUser;
    if (user == null) return false;
    if (user.isAnonymous) return devices[user.id] == childId;
    return childParent[childId] == currentParent?.id;
  }

  ChildProfile childById(String id) => children.firstWhere((c) => c.id == id);

  void replaceChild(ChildProfile child) {
    children[children.indexWhere((c) => c.id == child.id)] = child;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.backend);

  final FakeBackend backend;

  @override
  AuthUser? get currentUser => backend.currentUser;

  @override
  Stream<void> get signedOut => backend.signedOutEvents.stream;

  @override
  Future<bool> signUpParent({
    required String email,
    required String password,
    required String consentVersion,
    required bool marketingConsent,
    required String locale,
  }) async {
    backend.check();
    if (consentVersion.isEmpty) throw const AppFailure(FailureKind.unknown);
    if (backend.accounts.containsKey(email)) throw const AppFailure(FailureKind.emailTaken);
    backend.addParent(email: email, password: password);
    if (backend.requireEmailConfirmation) return false;
    backend.signInAs(email);
    return true;
  }

  @override
  Future<void> signInParent({required String email, required String password}) async {
    backend.check();
    final account = backend.accounts[email];
    if (account == null || account.password != password) throw const AppFailure(FailureKind.invalidCredentials);
    backend.signInAs(email);
  }

  @override
  Future<void> signInChildDevice() async {
    backend.check();
    backend.currentUser = AuthUser(id: backend.newId('device'), isAnonymous: true);
  }

  @override
  Future<void> signOut() async {
    backend.currentUser = null;
    backend.signedOutEvents.add(null);
  }
}

class FakeFamilyRepository implements FamilyRepository {
  FakeFamilyRepository(this.backend);

  final FakeBackend backend;

  ParentAccount _requireParent() {
    final parent = backend.currentParent;
    if (parent == null) throw const AppFailure(FailureKind.notAllowed);
    return parent;
  }

  void _requireOwnChild(String childId) {
    if (backend.childParent[childId] != _requireParent().id) throw const AppFailure(FailureKind.notAllowed);
  }

  @override
  Future<ParentAccount?> fetchParent() async {
    backend.check();
    final parent = backend.currentParent;
    if (parent == null) return null;
    return parent.copyWith(hasPin: backend.pins.containsKey(parent.id));
  }

  @override
  Future<List<ChildProfile>> fetchChildren() async {
    backend.check();
    final user = backend.currentUser;
    if (user == null) return [];
    if (user.isAnonymous) {
      final childId = backend.devices[user.id];
      return backend.children.where((c) => c.id == childId).toList();
    }
    final parent = backend.currentParent;
    return backend.children.where((c) => backend.childParent[c.id] == parent?.id).toList();
  }

  @override
  Future<ChildProfile> createChild({
    required String parentId,
    required String nickname,
    required int birthYear,
    required LevelSetting level,
  }) async {
    backend.check();
    if (_requireParent().id != parentId) throw const AppFailure(FailureKind.notAllowed);
    final child = ChildProfile(id: backend.newId('child'), nickname: nickname, birthYear: birthYear, level: level);
    backend.children.add(child);
    backend.childParent[child.id] = parentId;
    return child;
  }

  @override
  Future<ChildProfile> updateChild(ChildProfile child) async {
    backend.check();
    _requireOwnChild(child.id);
    final index = backend.children.indexWhere((c) => c.id == child.id);
    backend.children[index] = child;
    return child;
  }

  @override
  Future<void> deleteChild(String childId) async {
    backend.check();
    _requireOwnChild(childId);
    await signOutChildDevices(childId);
    backend.children.removeWhere((c) => c.id == childId);
    backend.childParent.remove(childId);
  }

  @override
  Future<LoginCode> createLoginCode(String childId) async {
    backend.check();
    _requireOwnChild(childId);
    backend.codes.removeWhere((_, v) => v.childId == childId && !v.used);
    final code = backend.nextCode;
    final validUntil = DateTime(2026, 10, 9, 14, 35);
    backend.codes[code] = (childId: childId, validUntil: validUntil, used: false);
    return LoginCode(code: code, validUntil: validUntil);
  }

  @override
  Future<ChildProfile?> redeemLoginCode(String code) async {
    backend.check();
    final user = backend.currentUser;
    if (user == null || !user.isAnonymous) throw const AppFailure(FailureKind.notAllowed);
    final entry = backend.codes[normalizeLoginCode(code)];
    if (entry == null || entry.used) return null;
    backend.codes[normalizeLoginCode(code)] = (childId: entry.childId, validUntil: entry.validUntil, used: true);
    backend.devices[user.id] = entry.childId;
    return backend.children.firstWhere((c) => c.id == entry.childId);
  }

  @override
  Future<int> countChildDevices(String childId) async {
    backend.check();
    _requireOwnChild(childId);
    return backend.devices.values.where((id) => id == childId).length;
  }

  @override
  Future<void> signOutChildDevices(String childId) async {
    backend.check();
    _requireOwnChild(childId);
    final deviceIds = backend.devices.entries.where((e) => e.value == childId).map((e) => e.key).toList();
    deviceIds.forEach(backend.signOutDevice);
  }

  @override
  Future<void> setParentPin(String pin) async {
    backend.check();
    backend.pins[_requireParent().id] = pin;
  }

  @override
  Future<PinCheckResult> verifyParentPin(String pin) async {
    backend.check();
    final stored = backend.pins[_requireParent().id];
    if (stored == null) return const PinCheckResult(PinCheckStatus.notSet);
    return PinCheckResult(stored == pin ? PinCheckStatus.ok : PinCheckStatus.wrong);
  }

  @override
  Future<void> deleteMyAccount() async {
    backend.check();
    final parent = _requireParent();
    for (final child in backend.children.where((c) => backend.childParent[c.id] == parent.id).toList()) {
      await deleteChild(child.id);
    }
    backend.parentsByUser.remove(parent.userId);
    backend.accounts.removeWhere((_, v) => v.userId == parent.userId);
  }
}

class FakeLocalSettings implements LocalSettings {
  final Map<String, String> values = {};

  @override
  Future<String?> activeChildId(String parentUserId) async => values[parentUserId];

  @override
  Future<void> setActiveChildId(String parentUserId, String? childId) async {
    if (childId == null) {
      values.remove(parentUserId);
    } else {
      values[parentUserId] = childId;
    }
  }
}

class FakeChildRepository implements ChildRepository {
  FakeChildRepository(this.backend);

  final FakeBackend backend;

  void _requireAccess(String childId) {
    backend.check();
    if (!backend.canActFor(childId)) throw const AppFailure(FailureKind.notAllowed);
  }

  @override
  Future<void> updateLook(String childId, {AvatarConfig? avatar, String? shipName}) async {
    _requireAccess(childId);
    final old = backend.childById(childId);
    backend.replaceChild(
      ChildProfile(
        id: old.id,
        nickname: old.nickname,
        birthYear: old.birthYear,
        level: old.level,
        stage: old.stage,
        avatar: avatar ?? old.avatar,
        shipName: shipName ?? old.shipName,
        onboardingCompleted: old.onboardingCompleted,
      ),
    );
  }

  @override
  Future<void> createSavingsGoal(String childId, {required String title, required int targetCents}) async {
    _requireAccess(childId);
    backend.savingsGoals.add((childId: childId, title: title.trim(), targetCents: targetCents));
  }

  @override
  Future<int> completeOnboarding(String childId) async {
    _requireAccess(childId);
    final old = backend.childById(childId);
    backend.replaceChild(
      ChildProfile(
        id: old.id,
        nickname: old.nickname,
        birthYear: old.birthYear,
        level: old.level,
        stage: old.stage,
        avatar: old.avatar,
        shipName: old.shipName,
        onboardingCompleted: true,
      ),
    );
    if (backend.xpByChild.containsKey(childId)) return 0;
    backend.xpByChild[childId] = 50;
    return 50;
  }
}
