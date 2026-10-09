import '../../domain/family_models.dart';
import '../../domain/validators.dart';
import '../../l10n/app_localizations.dart';

/// Übersetzt Gründe aus Logik und Daten in Texte für die Oberfläche.
extension TaleriaTexts on AppLocalizations {
  String failure(FailureKind kind) => switch (kind) {
    FailureKind.network => failureNetwork,
    FailureKind.invalidCredentials => failureInvalidCredentials,
    FailureKind.emailNotConfirmed => failureEmailNotConfirmed,
    FailureKind.emailTaken => failureEmailTaken,
    FailureKind.weakPassword => failureWeakPassword,
    FailureKind.rateLimited => failureRateLimited,
    FailureKind.notAllowed => failureNotAllowed,
    FailureKind.unknown => failureUnknown,
  };

  String? emailProblem(EmailProblem? problem) => switch (problem) {
    null => null,
    EmailProblem.empty => emailEmpty,
    EmailProblem.invalid => emailInvalid,
  };

  String? passwordProblem(PasswordProblem? problem) => switch (problem) {
    null => null,
    PasswordProblem.tooShort => passwordTooShort(minPasswordLength),
  };

  String? pinProblem(PinProblem? problem) => switch (problem) {
    null => null,
    PinProblem.format => pinFormat,
    PinProblem.tooSimple => pinTooSimple,
  };

  String? nicknameProblem(NicknameProblem? problem) => switch (problem) {
    null => null,
    NicknameProblem.tooShort => nicknameTooShort,
    NicknameProblem.tooLong => nicknameTooLong,
    NicknameProblem.invalidCharacters => nicknameInvalid,
  };

  String level(LevelSetting level) => switch (level) {
    LevelSetting.beginner => levelBeginner,
    LevelSetting.advanced => levelAdvanced,
  };
}

/// Uhrzeit als „14:35“, ohne Countdown (CLAUDE.md: kein Druck).
String formatClockTime(DateTime time) {
  final local = time.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}
