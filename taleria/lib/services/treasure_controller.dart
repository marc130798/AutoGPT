import 'package:flutter/foundation.dart';

import '../data/budget_repository.dart';
import '../domain/budget_models.dart';
import '../domain/family_models.dart';

/// Truhen, Heuer, Aufträge und Wunschschätze eines Kindes. Wird im
/// Kinderbereich (Schatztruhe, Aufträge) und im Leuchtturm genutzt.
class TreasureController extends ChangeNotifier {
  TreasureController({required this._budget, required this.childId});

  final BudgetRepository _budget;
  final String childId;

  PotBalances _balances = const PotBalances();
  List<LedgerEntry> _ledger = const [];
  List<FamilyTask> _tasks = const [];
  List<SavingsGoal> _goals = const [];
  AllowanceRule? _allowance;
  bool _loading = true;
  FailureKind? _failure;

  PotBalances get balances => _balances;
  List<LedgerEntry> get ledger => _ledger;
  List<FamilyTask> get tasks => _tasks;
  List<SavingsGoal> get goals => _goals;
  AllowanceRule? get allowance => _allowance;
  bool get loading => _loading;
  FailureKind? get failure => _failure;

  List<FamilyTask> tasksWith(TaskStatus status) => _tasks.where((t) => t.status == status).toList();

  /// Offene Wunschschätze zuerst, eingelöste danach.
  List<SavingsGoal> get openGoals => _goals.where((g) => !g.reached).toList();
  List<SavingsGoal> get reachedGoals => _goals.where((g) => g.reached).toList();

  /// Lädt alles neu. Fällige Heuer wird dabei zuerst gebucht.
  Future<void> load() async {
    _loading = _ledger.isEmpty && _tasks.isEmpty;
    _failure = null;
    notifyListeners();
    try {
      await _budget.processDueAllowances(childId);
      final results = await Future.wait([
        _budget.fetchBalances(childId),
        _budget.fetchLedger(childId),
        _budget.fetchTasks(childId),
        _budget.fetchGoals(childId),
        _budget.fetchAllowance(childId),
      ]);
      _balances = results[0] as PotBalances;
      _ledger = results[1] as List<LedgerEntry>;
      _tasks = results[2] as List<FamilyTask>;
      _goals = results[3] as List<SavingsGoal>;
      _allowance = results[4] as AllowanceRule?;
    } on AppFailure catch (e) {
      _failure = e.kind;
    }
    _loading = false;
    notifyListeners();
  }

  // Kind (und Eltern auf dem Eltern-Gerät)

  Future<void> submitTask(FamilyTask task) => _then(_budget.submitTask(task.id));

  Future<void> move({required Pot from, required Pot to, required int amountCents}) {
    _checkAmount(amountCents, from);
    return _then(_budget.movePots(childId, from: from, to: to, amountCents: amountCents));
  }

  Future<void> recordSpending({required Pot pot, required int amountCents, String? note}) {
    if (pot == Pot.save) throw ArgumentError.value(pot, 'pot', 'Aus der Schatztruhe wird nicht direkt ausgegeben');
    _checkAmount(amountCents, pot);
    return _then(_budget.recordSpending(childId, pot: pot, amountCents: amountCents, note: note));
  }

  Future<void> createGoal({required String title, required int targetCents}) =>
      _then(_budget.createGoal(childId, title: title, targetCents: targetCents));

  Future<void> deleteGoal(SavingsGoal goal) => _then(_budget.deleteGoal(goal.id));

  Future<void> redeemGoal(SavingsGoal goal) {
    if (!goal.canRedeem(_balances.save)) throw StateError('Noch nicht genug in der Schatztruhe');
    return _then(_budget.redeemGoal(goal.id));
  }

  // Nur Eltern

  Future<void> setAllowance({int? amountCents, AllowanceInterval? interval, DateTime? firstPayout}) =>
      _then(_budget.setAllowance(childId, amountCents: amountCents, interval: interval, firstPayout: firstPayout));

  Future<void> createTask({
    required String parentId,
    required String title,
    required int rewardCents,
    required bool isChore,
  }) => _then(
    _budget.createTask(parentId: parentId, childId: childId, title: title, rewardCents: rewardCents, isChore: isChore),
  );

  Future<void> deleteTask(FamilyTask task) => _then(_budget.deleteTask(task.id));

  Future<void> reviewTask(FamilyTask task, {required bool approve, String? note}) =>
      _then(_budget.reviewTask(task.id, approve: approve, note: note));

  Future<void> bookManual({required Pot pot, required int amountCents, String? note}) =>
      _then(_budget.bookManual(childId, pot: pot, amountCents: amountCents, note: note));

  /// Schon in der App prüfen, damit die Rückmeldung sofort kommt.
  /// Der Server prüft dasselbe noch einmal.
  void _checkAmount(int amountCents, Pot from) {
    if (amountCents <= 0) throw ArgumentError.value(amountCents, 'amountCents', 'muss größer als 0 sein');
    if (amountCents > _balances.of(from)) throw const NotEnoughMoney();
  }

  Future<void> _then(Future<void> action) async {
    await action;
    await load();
  }
}

/// Es ist nicht genug Guthaben in der Truhe.
class NotEnoughMoney implements Exception {
  const NotEnoughMoney();
}
