import 'package:taleria/data/budget_repository.dart';
import 'package:taleria/domain/budget_models.dart';
import 'package:taleria/domain/family_models.dart';

/// Kassenbuch im Speicher, mit denselben Regeln wie die Server-Funktionen
/// (keine Truhe im Minus, Belohnung erst nach Bestätigung und nur einmal).
/// Die echten Regeln testet tool/db_test.sh.
class FakeBudget implements BudgetRepository {
  final List<LedgerEntry> entries = [];
  final Map<String, List<FamilyTask>> tasks = {};
  final Map<String, List<SavingsGoal>> goals = {};
  final Map<String, AllowanceRule> allowances = {};
  final Map<String, String> entryChild = {};

  /// Für welchen Wunschschatz eine Buchung zurückgelegt ist.
  final Map<String, String> entryGoal = {};
  FailureKind? failWith;
  int _id = 0;

  /// Zeitpunkt „jetzt“ für die Heuer, in Tests verschiebbar.
  DateTime now = DateTime(2026, 10, 9, 12);

  void _check() {
    if (failWith != null) throw AppFailure(failWith!);
  }

  String _next(String prefix) => '$prefix-${_id++}';

  void _book(String childId, Pot pot, int amount, LedgerType type, {String? note, String? goalId}) {
    final entry = LedgerEntry(id: _next('e'), pot: pot, amountCents: amount, type: type, createdAt: now, note: note);
    entries.add(entry);
    entryChild[entry.id] = childId;
    if (goalId != null) entryGoal[entry.id] = goalId;
  }

  /// Für einen Wunschschatz zurückgelegt.
  int saved(String goalId) =>
      entries.where((e) => entryGoal[e.id] == goalId && e.pot == Pot.save).fold(0, (sum, e) => sum + e.amountCents);

  (String, int)? _findGoal(String goalId) {
    for (final e in goals.entries) {
      final i = e.value.indexWhere((g) => g.id == goalId);
      if (i >= 0) return (e.key, i);
    }
    return null;
  }

  int balance(String childId, Pot pot) =>
      entries.where((e) => entryChild[e.id] == childId && e.pot == pot).fold(0, (sum, e) => sum + e.amountCents);

  void _ensure(String childId, Pot pot, int amount) {
    if (balance(childId, pot) < amount) throw const AppFailure(FailureKind.notEnoughMoney);
  }

  @override
  Future<int> processDueAllowances(String childId) async {
    _check();
    final rule = allowances[childId];
    if (rule == null) return 0;
    var next = rule.nextRunAt;
    var paid = 0;
    while (!next.isAfter(now)) {
      _book(childId, Pot.spend, rule.amountCents, LedgerType.allowance);
      paid++;
      next = rule.interval == AllowanceInterval.weekly
          ? next.add(const Duration(days: 7))
          : DateTime(next.year, next.month + 1, next.day, next.hour);
    }
    allowances[childId] = AllowanceRule(amountCents: rule.amountCents, interval: rule.interval, nextRunAt: next);
    return paid;
  }

  @override
  Future<PotBalances> fetchBalances(String childId) async {
    _check();
    return PotBalances(
      spend: balance(childId, Pot.spend),
      save: balance(childId, Pot.save),
      give: balance(childId, Pot.give),
    );
  }

  @override
  Future<List<LedgerEntry>> fetchLedger(String childId, {int limit = 50}) async =>
      entries.where((e) => entryChild[e.id] == childId).toList().reversed.take(limit).toList();

  @override
  Future<AllowanceRule?> fetchAllowance(String childId) async => allowances[childId];

  @override
  Future<List<FamilyTask>> fetchTasks(String childId) async => [...?tasks[childId]];

  @override
  Future<List<SavingsGoal>> fetchGoals(String childId) async => [
    for (final g in goals[childId] ?? const <SavingsGoal>[]) g.withSaved(saved(g.id)),
  ];

  @override
  Future<Map<String, int>> fetchSubmittedTaskCounts() async => {
    for (final e in tasks.entries)
      if (e.value.any((t) => t.status == TaskStatus.submitted))
        e.key: e.value.where((t) => t.status == TaskStatus.submitted).length,
  };

  @override
  Future<void> setAllowance(
    String childId, {
    int? amountCents,
    AllowanceInterval? interval,
    DateTime? firstPayout,
  }) async {
    _check();
    if (amountCents == null || amountCents == 0) {
      allowances.remove(childId);
      return;
    }
    allowances[childId] = AllowanceRule(
      amountCents: amountCents,
      interval: interval ?? AllowanceInterval.weekly,
      nextRunAt: firstPayout ?? now,
    );
  }

  @override
  Future<void> createTask({
    required String parentId,
    required String childId,
    required String title,
    required int rewardCents,
    required bool isChore,
  }) async {
    _check();
    (tasks[childId] ??= []).insert(
      0,
      FamilyTask(
        id: _next('t'),
        title: title.trim(),
        rewardCents: isChore ? 0 : rewardCents,
        isChore: isChore,
        status: TaskStatus.open,
        createdAt: now,
      ),
    );
  }

  (String, int) _find(String taskId) {
    for (final e in tasks.entries) {
      final i = e.value.indexWhere((t) => t.id == taskId);
      if (i >= 0) return (e.key, i);
    }
    throw const AppFailure(FailureKind.notAllowed);
  }

  /// Wie auf dem Server: Melden setzt `submitted_at`, Bestätigen und
  /// Ablehnen setzen `reviewed_at`.
  void _replace(String taskId, TaskStatus status, {String? note}) {
    final (childId, i) = _find(taskId);
    final t = tasks[childId]![i];
    tasks[childId]![i] = FamilyTask(
      id: t.id,
      title: t.title,
      rewardCents: t.rewardCents,
      isChore: t.isChore,
      status: status,
      parentNote: note ?? t.parentNote,
      createdAt: t.createdAt,
      submittedAt: status == TaskStatus.submitted ? now : t.submittedAt,
      reviewedAt: status == TaskStatus.approved || status == TaskStatus.rejected ? now : t.reviewedAt,
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final (childId, i) = _find(taskId);
    tasks[childId]!.removeAt(i);
  }

  @override
  Future<void> submitTask(String taskId) async {
    _check();
    final (childId, i) = _find(taskId);
    if (!tasks[childId]![i].canSubmit) throw const AppFailure(FailureKind.unknown);
    _replace(taskId, TaskStatus.submitted);
  }

  @override
  Future<void> reviewTask(String taskId, {required bool approve, String? note}) async {
    _check();
    final (childId, i) = _find(taskId);
    final task = tasks[childId]![i];
    if (approve) {
      if (!task.canApprove) throw const AppFailure(FailureKind.unknown);
      _replace(taskId, TaskStatus.approved, note: note);
      if (task.rewardCents > 0) _book(childId, Pot.spend, task.rewardCents, LedgerType.task, note: task.title);
    } else {
      _replace(taskId, TaskStatus.rejected, note: note);
    }
  }

  @override
  Future<void> recordSpending(String childId, {required int amountCents, String? note}) async {
    _check();
    _ensure(childId, Pot.spend, amountCents);
    _book(childId, Pot.spend, -amountCents, LedgerType.purchase, note: note);
  }

  @override
  Future<void> bookManual(String childId, {required int amountCents, String? note}) async {
    _check();
    if (balance(childId, Pot.spend) + amountCents < 0) throw const AppFailure(FailureKind.notEnoughMoney);
    _book(childId, Pot.spend, amountCents, LedgerType.manual, note: note);
  }

  @override
  Future<void> moveGoalSavings(String goalId, int amountCents) async {
    _check();
    final found = _findGoal(goalId);
    if (found == null) throw const AppFailure(FailureKind.notAllowed);
    final (childId, i) = found;
    final goal = goals[childId]![i];
    if (goal.reached || amountCents == 0) throw const AppFailure(FailureKind.unknown);
    if (amountCents > 0) {
      _ensure(childId, Pot.spend, amountCents);
      if (saved(goalId) + amountCents > goal.targetCents) throw const AppFailure(FailureKind.unknown, 'zu viel');
    } else if (saved(goalId) + amountCents < 0) {
      throw const AppFailure(FailureKind.notEnoughMoney);
    }
    _book(childId, Pot.spend, -amountCents, LedgerType.transfer, note: goal.title);
    _book(childId, Pot.save, amountCents, LedgerType.transfer, note: goal.title, goalId: goalId);
  }

  @override
  Future<void> createGoal(String childId, {required String title, required int targetCents}) async {
    _check();
    (goals[childId] ??= []).add(SavingsGoal(id: _next('g'), title: title, targetCents: targetCents));
  }

  /// Wie auf dem Server: Das zurückgelegte Geld ist danach wieder frei.
  @override
  Future<void> deleteGoal(String goalId) async {
    final found = _findGoal(goalId);
    if (found == null) return;
    final (childId, i) = found;
    final goal = goals[childId]![i];
    if (goal.reached) return;
    final money = saved(goalId);
    if (money > 0) {
      _book(childId, Pot.save, -money, LedgerType.transfer, note: goal.title, goalId: goalId);
      _book(childId, Pot.spend, money, LedgerType.transfer, note: goal.title);
    }
    goals[childId]!.removeAt(i);
  }

  @override
  Future<void> redeemGoal(String goalId) async {
    _check();
    for (final e in goals.entries) {
      final i = e.value.indexWhere((g) => g.id == goalId);
      if (i < 0) continue;
      final goal = e.value[i];
      if (saved(goal.id) < goal.targetCents) throw const AppFailure(FailureKind.notEnoughMoney);
      _book(e.key, Pot.save, -goal.targetCents, LedgerType.goal, note: goal.title, goalId: goal.id);
      e.value[i] = SavingsGoal(id: goal.id, title: goal.title, targetCents: goal.targetCents, reachedAt: now);
    }
  }

  /// Wunschflaschen pro Kind (alle, auch entschiedene).
  final Map<String, List<WishBottle>> wishBottles = {};

  /// Station mit der Wunschflasche geschafft (schaltet sie frei, auch ohne Flasche).
  final Set<String> wishUnlocked = {};

  bool _due(WishBottle b) => b.isOpen && !b.remindAt.isAfter(now);

  @override
  Future<List<WishBottle>> fetchWishBottles(String childId) async {
    _check();
    return [
      for (final b in (wishBottles[childId] ?? const <WishBottle>[]).where((b) => b.isOpen).toList().reversed)
        WishBottle(
          id: b.id,
          title: b.title,
          priceCents: b.priceCents,
          isBig: b.isBig,
          remindAt: b.remindAt,
          due: _due(b),
        ),
    ];
  }

  @override
  Future<WishBottleStatus> fetchWishBottleStatus(String childId) async {
    _check();
    final all = wishBottles[childId] ?? const [];
    return WishBottleStatus(unlocked: all.isNotEmpty || wishUnlocked.contains(childId), due: all.where(_due).length);
  }

  @override
  Future<void> createWishBottle(String childId, WishDraft draft) async {
    _check();
    final list = wishBottles.putIfAbsent(childId, () => []);
    if (list.where((b) => b.isOpen).length >= 10) throw const AppFailure(FailureKind.unknown, 'Höchstens 10');
    final start = DateTime(now.year, now.month, now.day);
    list.add(
      WishBottle(
        id: _next('w'),
        title: draft.title.trim(),
        priceCents: draft.priceCents,
        isBig: draft.isBig,
        remindAt: start.add(Duration(days: WishBottle.waitDays(big: draft.isBig))),
      ),
    );
  }

  @override
  Future<void> decideWishBottle(String bottleId, {required bool keep, int? targetCents}) async {
    _check();
    for (final e in wishBottles.entries) {
      final i = e.value.indexWhere((b) => b.id == bottleId);
      if (i < 0) continue;
      final b = e.value[i];
      if (!b.isOpen) throw const AppFailure(FailureKind.unknown, 'schon entschieden');
      if (keep && !_due(b)) throw const AppFailure(FailureKind.unknown, 'treibt noch');
      final target = targetCents ?? b.priceCents;
      if (keep) {
        if (target == null || target < 100) throw const AppFailure(FailureKind.unknown, 'Preis fehlt');
        await createGoal(e.key, title: b.title, targetCents: target);
      }
      e.value[i] = WishBottle(
        id: b.id,
        title: b.title,
        priceCents: b.priceCents,
        isBig: b.isBig,
        remindAt: b.remindAt,
        decision: keep ? WishDecision.converted : WishDecision.dropped,
      );
    }
  }
}
