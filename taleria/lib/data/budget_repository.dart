import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/budget_models.dart';
import 'backend_errors.dart';

/// Heuer, Aufträge, Truhen und Wunschschätze. Alle Buchungen laufen über
/// Server-Funktionen; Rechte und Regeln prüft die Datenbank.
abstract interface class BudgetRepository {
  /// Bucht fällige Heuer-Zahlungen. Gibt die Anzahl zurück.
  Future<int> processDueAllowances(String childId);

  Future<PotBalances> fetchBalances(String childId);

  Future<List<LedgerEntry>> fetchLedger(String childId, {int limit = 50});

  Future<AllowanceRule?> fetchAllowance(String childId);

  Future<List<FamilyTask>> fetchTasks(String childId);

  Future<List<SavingsGoal>> fetchGoals(String childId);

  /// Eltern: Anzahl gemeldeter Aufgaben pro Kind (für den Leuchtturm).
  Future<Map<String, int>> fetchSubmittedTaskCounts();

  /// Eltern: Heuer festlegen. [amountCents] `null` beendet die Heuer.
  Future<void> setAllowance(String childId, {int? amountCents, AllowanceInterval? interval, DateTime? firstPayout});

  Future<void> createTask({
    required String parentId,
    required String childId,
    required String title,
    required int rewardCents,
    required bool isChore,
  });

  Future<void> deleteTask(String taskId);

  Future<void> submitTask(String taskId);

  Future<void> reviewTask(String taskId, {required bool approve, String? note});

  Future<void> movePots(String childId, {required Pot from, required Pot to, required int amountCents});

  Future<void> recordSpending(String childId, {required Pot pot, required int amountCents, String? note});

  Future<void> bookManual(String childId, {required Pot pot, required int amountCents, String? note});

  Future<void> createGoal(String childId, {required String title, required int targetCents});

  Future<void> deleteGoal(String goalId);

  Future<void> redeemGoal(String goalId);

  /// Offene Wunschflaschen, neueste zuerst.
  Future<List<WishBottle>> fetchWishBottles(String childId);

  Future<WishBottleStatus> fetchWishBottleStatus(String childId);

  Future<void> createWishBottle(String childId, WishDraft draft);

  /// [keep] = Wunschschatz daraus machen (erst nach der Wartezeit), sonst loslassen.
  /// [targetCents] ist nötig, wenn die Flasche keinen Preis hat.
  Future<void> decideWishBottle(String bottleId, {required bool keep, int? targetCents});
}

class SupabaseBudgetRepository implements BudgetRepository {
  SupabaseBudgetRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<int> processDueAllowances(String childId) =>
      guardBackend(() => _client.rpc<int>('process_due_allowances', params: {'p_child_id': childId}));

  @override
  Future<PotBalances> fetchBalances(String childId) => guardBackend(() async {
    final rows = await _client.rpc<List<dynamic>>('pot_balances', params: {'p_child_id': childId});
    final byPot = {
      for (final r in rows.cast<Map<String, dynamic>>()) r['pot'] as String: (r['balance_cents'] as num).toInt(),
    };
    return PotBalances(spend: byPot['spend'] ?? 0, save: byPot['save'] ?? 0, give: byPot['give'] ?? 0);
  });

  @override
  Future<List<LedgerEntry>> fetchLedger(String childId, {int limit = 50}) => guardBackend(() async {
    final rows = await _client
        .from('ledger_entries')
        .select('id, pot, amount_cents, entry_type, note, created_at')
        .eq('child_id', childId)
        .order('created_at', ascending: false)
        .limit(limit);
    return [
      for (final r in rows)
        LedgerEntry(
          id: r['id'] as String,
          pot: Pot.fromCode(r['pot'] as String),
          amountCents: r['amount_cents'] as int,
          type: LedgerType.values.byName(r['entry_type'] as String),
          note: r['note'] as String?,
          createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
        ),
    ];
  });

  @override
  Future<AllowanceRule?> fetchAllowance(String childId) => guardBackend(() async {
    final row = await _client
        .from('allowance_rules')
        .select('amount_cents, interval, next_run_at')
        .eq('child_id', childId)
        .maybeSingle();
    if (row == null) return null;
    return AllowanceRule(
      amountCents: row['amount_cents'] as int,
      interval: AllowanceInterval.fromCode(row['interval'] as String),
      nextRunAt: DateTime.parse(row['next_run_at'] as String).toLocal(),
    );
  });

  @override
  Future<List<FamilyTask>> fetchTasks(String childId) => guardBackend(() async {
    final rows = await _client
        .from('tasks')
        .select('id, title, reward_cents, is_chore, status, parent_note, created_at')
        .eq('child_id', childId)
        .order('created_at', ascending: false);
    return [
      for (final r in rows)
        FamilyTask(
          id: r['id'] as String,
          title: r['title'] as String,
          rewardCents: r['reward_cents'] as int,
          isChore: r['is_chore'] as bool,
          status: TaskStatus.values.byName(r['status'] as String),
          parentNote: r['parent_note'] as String?,
          createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
        ),
    ];
  });

  @override
  Future<List<SavingsGoal>> fetchGoals(String childId) => guardBackend(() async {
    final rows = await _client
        .from('savings_goals')
        .select('id, title, target_cents, reached_at')
        .eq('child_id', childId)
        .order('created_at');
    return [
      for (final r in rows)
        SavingsGoal(
          id: r['id'] as String,
          title: r['title'] as String,
          targetCents: r['target_cents'] as int,
          reachedAt: r['reached_at'] == null ? null : DateTime.parse(r['reached_at'] as String).toLocal(),
        ),
    ];
  });

  @override
  Future<Map<String, int>> fetchSubmittedTaskCounts() => guardBackend(() async {
    final rows = await _client.from('tasks').select('child_id').eq('status', 'submitted');
    final counts = <String, int>{};
    for (final r in rows) {
      final id = r['child_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  });

  @override
  Future<void> setAllowance(String childId, {int? amountCents, AllowanceInterval? interval, DateTime? firstPayout}) =>
      guardBackend(
        () => _client.rpc<void>(
          'set_allowance',
          params: {
            'p_child_id': childId,
            'p_amount_cents': amountCents,
            'p_interval': interval?.code ?? 'weekly',
            'p_first_payout': firstPayout?.toUtc().toIso8601String(),
          },
        ),
      );

  @override
  Future<void> createTask({
    required String parentId,
    required String childId,
    required String title,
    required int rewardCents,
    required bool isChore,
  }) => guardBackend(
    () => _client.from('tasks').insert({
      'parent_id': parentId,
      'child_id': childId,
      'title': title.trim(),
      'reward_cents': isChore ? 0 : rewardCents,
      'is_chore': isChore,
    }),
  );

  @override
  Future<void> deleteTask(String taskId) => guardBackend(() => _client.from('tasks').delete().eq('id', taskId));

  @override
  Future<void> submitTask(String taskId) =>
      guardBackend(() => _client.rpc<void>('submit_task', params: {'p_task_id': taskId}));

  @override
  Future<void> reviewTask(String taskId, {required bool approve, String? note}) => guardBackend(
    () => _client.rpc<void>('review_task', params: {'p_task_id': taskId, 'p_approve': approve, 'p_note': note}),
  );

  @override
  Future<void> movePots(String childId, {required Pot from, required Pot to, required int amountCents}) => guardBackend(
    () => _client.rpc<void>(
      'move_between_pots',
      params: {'p_child_id': childId, 'p_from': from.code, 'p_to': to.code, 'p_amount_cents': amountCents},
    ),
  );

  @override
  Future<void> recordSpending(String childId, {required Pot pot, required int amountCents, String? note}) =>
      guardBackend(
        () => _client.rpc<void>(
          'record_spending',
          params: {'p_child_id': childId, 'p_pot': pot.code, 'p_amount_cents': amountCents, 'p_note': note},
        ),
      );

  @override
  Future<void> bookManual(String childId, {required Pot pot, required int amountCents, String? note}) => guardBackend(
    () => _client.rpc<void>(
      'book_manual',
      params: {'p_child_id': childId, 'p_pot': pot.code, 'p_amount_cents': amountCents, 'p_note': note},
    ),
  );

  @override
  Future<void> createGoal(String childId, {required String title, required int targetCents}) => guardBackend(
    () =>
        _client.from('savings_goals').insert({'child_id': childId, 'title': title.trim(), 'target_cents': targetCents}),
  );

  @override
  Future<void> deleteGoal(String goalId) => guardBackend(() => _client.from('savings_goals').delete().eq('id', goalId));

  @override
  Future<void> redeemGoal(String goalId) =>
      guardBackend(() => _client.rpc<void>('redeem_savings_goal', params: {'p_goal_id': goalId}));

  @override
  Future<List<WishBottle>> fetchWishBottles(String childId) => guardBackend(() async {
    final rows = await _client.rpc<List<dynamic>>('open_wish_bottles', params: {'p_child_id': childId});
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        WishBottle(
          id: r['id'] as String,
          title: r['title'] as String,
          priceCents: r['price_cents'] as int?,
          isBig: r['is_big'] as bool? ?? false,
          remindAt: DateTime.parse(r['remind_at'] as String).toLocal(),
          due: r['due'] as bool? ?? false,
        ),
    ];
  });

  @override
  Future<WishBottleStatus> fetchWishBottleStatus(String childId) => guardBackend(() async {
    final result = await _client.rpc<Map<String, dynamic>>('wish_bottle_status', params: {'p_child_id': childId});
    return WishBottleStatus(unlocked: result['unlocked'] as bool? ?? false, due: (result['due'] as num?)?.toInt() ?? 0);
  });

  @override
  Future<void> createWishBottle(String childId, WishDraft draft) => guardBackend(
    () => _client.rpc<void>(
      'create_wish_bottle',
      params: {
        'p_child_id': childId,
        'p_title': draft.title.trim(),
        'p_price_cents': draft.priceCents,
        'p_big': draft.isBig,
      },
    ),
  );

  @override
  Future<void> decideWishBottle(String bottleId, {required bool keep, int? targetCents}) => guardBackend(
    () => _client.rpc<void>(
      'decide_wish_bottle',
      params: {'p_bottle_id': bottleId, 'p_keep': keep, 'p_target_cents': targetCents},
    ),
  );
}
