import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/avatar.dart';
import '../domain/family_models.dart';
import 'backend_errors.dart';

/// Was ein Kind (oder seine Eltern für es) selbst speichern darf:
/// Avatar, Schiffsname, Form der Rang-Namen, Wunschschätze und der Abschluss des Intros.
/// Die Rechte prüft die Datenbank (can_act_for_child).
abstract interface class ChildRepository {
  Future<void> updateLook(String childId, {AvatarConfig? avatar, String? shipName, RankForm? rankForm});

  Future<void> createSavingsGoal(String childId, {required String title, required int targetCents});

  /// Schließt das Intro ab. Gibt die gutgeschriebenen Seemeilen zurück
  /// (0, wenn es schon vorher abgeschlossen war).
  Future<int> completeOnboarding(String childId);
}

class SupabaseChildRepository implements ChildRepository {
  SupabaseChildRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<void> updateLook(String childId, {AvatarConfig? avatar, String? shipName, RankForm? rankForm}) => guardBackend(
    () => _client.rpc<void>(
      'update_child_look',
      params: {
        'p_child_id': childId,
        'p_avatar': avatar?.toJson(),
        'p_ship_name': shipName?.trim(),
        'p_rank_form': rankForm?.name,
      },
    ),
  );

  @override
  Future<void> createSavingsGoal(String childId, {required String title, required int targetCents}) => guardBackend(
    () =>
        _client.from('savings_goals').insert({'child_id': childId, 'title': title.trim(), 'target_cents': targetCents}),
  );

  @override
  Future<int> completeOnboarding(String childId) =>
      guardBackend(() => _client.rpc<int>('complete_onboarding', params: {'p_child_id': childId}));
}
