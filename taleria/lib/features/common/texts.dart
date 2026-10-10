import '../../domain/budget_models.dart';
import '../../domain/family_models.dart';
import '../../domain/money.dart';
import '../../domain/progress_models.dart';
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
    FailureKind.notEnoughMoney => notEnoughMoney,
    FailureKind.noWind => windNeededShort,
    FailureKind.premiumRequired => failurePremiumRequired,
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

  String? amountProblem(AmountProblem? problem) => switch (problem) {
    null => null,
    AmountProblem.invalid => amountInvalid,
    AmountProblem.zero => amountZero,
    AmountProblem.tooLarge => amountTooLarge(formatCents(maxAmountCents)),
  };

  /// Name einer Truhe im Kinderbereich oder im Elternbereich (Glossar).
  String pot(Pot pot, {required bool parent}) => switch (pot) {
    Pot.spend => parent ? parentPotSpend : potSpendChild,
    Pot.save => parent ? parentPotSave : potSaveChild,
    Pot.give => parent ? parentPotGive : potGiveChild,
  };

  String interval(AllowanceInterval interval) => switch (interval) {
    AllowanceInterval.weekly => allowanceWeekly,
    AllowanceInterval.monthly => allowanceMonthly,
  };

  String ledgerType(LedgerType type) => switch (type) {
    LedgerType.allowance => ledgerAllowance,
    LedgerType.task => ledgerTask,
    LedgerType.transfer => ledgerTransfer,
    LedgerType.manual => ledgerManual,
    LedgerType.goal => ledgerGoal,
    LedgerType.purchase => ledgerPurchase,
    LedgerType.donation => ledgerDonation,
  };

  String taskStatus(TaskStatus status) => switch (status) {
    TaskStatus.open => taskStatusOpen,
    TaskStatus.submitted => taskStatusSubmitted,
    TaskStatus.approved => taskStatusApproved,
    TaskStatus.rejected => taskStatusRejected,
  };

  /// Name eines Rangs in der Form, die das Kind gewählt hat (Schiffsjunge
  /// oder Schiffsmädchen …). Noch nicht gewählt: beide Formen.
  String rank(Rank? rank, RankForm? form) {
    final code = rank?.code ?? 'none';
    return switch (form) {
      RankForm.junge => rankName(code),
      RankForm.maedchen => rankNameMaedchen(code),
      null => rankNameOpen(code),
    };
  }

  /// Tempo als Geschichte (CLAUDE.md Abschnitt 8): „Das Schiff braucht Wind,
  /// die nächste Station erreichst du am Donnerstag.“ Nie als Countdown.
  String windNeededFor(PaceStatus pace) {
    final next = pace.nextRelease;
    return next == null ? windNeededSoon : windNeeded(weekday('${next.weekday}'));
  }

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

/// Datum als „16.10.2026“.
String formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year}';
}
