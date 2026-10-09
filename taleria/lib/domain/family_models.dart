/// Datenmodelle für Konten und Kinder-Profile. Ohne Aussehen, ohne Supabase.
library;

import 'avatar.dart';

enum LevelSetting {
  beginner('beginner'),
  advanced('advanced');

  const LevelSetting(this.code);

  /// Wert in der Datenbank.
  final String code;

  static LevelSetting fromCode(String? code) =>
      LevelSetting.values.firstWhere((l) => l.code == code, orElse: () => LevelSetting.beginner);
}

class ParentAccount {
  const ParentAccount({required this.id, required this.userId, required this.hasPin});

  final String id;
  final String userId;
  final bool hasPin;

  ParentAccount copyWith({bool? hasPin}) => ParentAccount(id: id, userId: userId, hasPin: hasPin ?? this.hasPin);
}

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.nickname,
    required this.birthYear,
    required this.level,
    this.stage = 1,
    this.avatar,
    this.shipName,
    this.onboardingCompleted = false,
  });

  final String id;
  final String nickname;
  final int birthYear;
  final LevelSetting level;

  /// Stufe 1 (10 bis 14) oder später Stufe 2. Bestimmt Theme und Inhalte.
  final int stage;

  /// `null`, solange das Kind noch keinen Avatar gestaltet hat.
  final AvatarConfig? avatar;

  /// Name des Schiffs, `null` vor der Schiffstaufe.
  final String? shipName;

  /// Intro (Station 1 des Hafens) abgeschlossen?
  final bool onboardingCompleted;

  ChildProfile copyWith({String? nickname, int? birthYear, LevelSetting? level}) => ChildProfile(
    id: id,
    nickname: nickname ?? this.nickname,
    birthYear: birthYear ?? this.birthYear,
    level: level ?? this.level,
    stage: stage,
    avatar: avatar,
    shipName: shipName,
    onboardingCompleted: onboardingCompleted,
  );
}

/// Neu erzeugter Anmelde-Code. Der Code wird nur dieses eine Mal angezeigt.
class LoginCode {
  const LoginCode({required this.code, required this.validUntil});

  final String code;
  final DateTime validUntil;
}

enum PinCheckStatus { ok, wrong, locked, notSet }

class PinCheckResult {
  const PinCheckResult(this.status, {this.lockedUntil});

  final PinCheckStatus status;

  /// Bei [PinCheckStatus.locked]: ab wann es wieder geht.
  final DateTime? lockedUntil;
}

/// Angemeldete Person laut Supabase Auth.
class AuthUser {
  const AuthUser({required this.id, required this.isAnonymous});

  final String id;

  /// `true` bei Kinder-Geräten (anonyme Sitzung).
  final bool isAnonymous;
}

/// Was schiefgehen kann, ohne technische Details. Die Oberfläche zeigt dazu
/// einen passenden Text aus den Übersetzungsdateien.
enum FailureKind {
  network,
  invalidCredentials,
  emailNotConfirmed,
  emailTaken,
  weakPassword,
  rateLimited,
  notAllowed,

  /// Nicht genug Guthaben in der Truhe.
  notEnoughMoney,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure(this.kind, [this.detail]);

  final FailureKind kind;

  /// Nur für Fehlersuche, nie in der Oberfläche anzeigen.
  final String? detail;

  @override
  String toString() => 'AppFailure($kind${detail == null ? '' : ': $detail'})';
}
