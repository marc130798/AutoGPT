/// Budget und Aufgaben (alles virtuell). Ohne Aussehen, ohne Supabase.
library;

/// Die drei Truhen. Kinderbereich: Bordkasse, Schatztruhe, Glückstruhe.
/// Elternbereich: Ausgeben, Sparen, Verschenken.
enum Pot {
  spend('spend'),
  save('save'),
  give('give');

  const Pot(this.code);

  final String code;

  static Pot fromCode(String code) => Pot.values.firstWhere((p) => p.code == code);
}

class PotBalances {
  const PotBalances({this.spend = 0, this.save = 0, this.give = 0});

  final int spend;
  final int save;
  final int give;

  int of(Pot pot) => switch (pot) {
    Pot.spend => spend,
    Pot.save => save,
    Pot.give => give,
  };

  int get total => spend + save + give;
}

enum LedgerType { allowance, task, transfer, manual, goal, purchase, donation }

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.pot,
    required this.amountCents,
    required this.type,
    required this.createdAt,
    this.note,
  });

  final String id;
  final Pot pot;
  final int amountCents;
  final LedgerType type;
  final DateTime createdAt;
  final String? note;
}

enum AllowanceInterval {
  weekly('weekly'),
  monthly('monthly');

  const AllowanceInterval(this.code);

  final String code;

  static AllowanceInterval fromCode(String code) => AllowanceInterval.values.firstWhere((i) => i.code == code);
}

class AllowanceRule {
  const AllowanceRule({required this.amountCents, required this.interval, required this.nextRunAt});

  final int amountCents;
  final AllowanceInterval interval;
  final DateTime nextRunAt;
}

enum TaskStatus { open, submitted, approved, rejected }

class FamilyTask {
  const FamilyTask({
    required this.id,
    required this.title,
    required this.rewardCents,
    required this.isChore,
    required this.status,
    this.parentNote,
    this.createdAt,
  });

  final String id;
  final String title;
  final int rewardCents;
  final bool isChore;
  final TaskStatus status;
  final String? parentNote;
  final DateTime? createdAt;

  /// Das Kind kann melden: offen oder nach Ablehnung erneut.
  bool get canSubmit => status == TaskStatus.open || status == TaskStatus.rejected;

  /// Eltern können bestätigen: offen oder gemeldet.
  bool get canApprove => status == TaskStatus.open || status == TaskStatus.submitted;
}

class SavingsGoal {
  const SavingsGoal({required this.id, required this.title, required this.targetCents, this.reachedAt});

  final String id;
  final String title;
  final int targetCents;
  final DateTime? reachedAt;

  bool get reached => reachedAt != null;

  /// Fortschritt 0 bis 1 anhand des Guthabens der Schatztruhe.
  double progress(int saveBalanceCents) => reached ? 1 : (saveBalanceCents / targetCents).clamp(0, 1).toDouble();

  bool canRedeem(int saveBalanceCents) => !reached && saveBalanceCents >= targetCents;
}
