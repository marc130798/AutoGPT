import 'package:flutter/foundation.dart';

import '../data/admin_failure.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

/// Support: Familie per E-Mail suchen, Abo von Hand, Konto löschen.
/// Jeder Schritt braucht einen Grund; die Datenbank schreibt ihn ins Audit-Log.
class SupportController extends ChangeNotifier {
  SupportController(this._repository, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final AdminRepository _repository;
  final DateTime Function() _now;

  /// Mindestlänge eines Grundes (wie in der Datenbank).
  static const minReasonLength = 5;

  FamilyInfo? _family;
  FamilyInfo? get family => _family;

  /// Letzte Suche ohne Treffer.
  bool _notFound = false;
  bool get notFound => _notFound;

  /// Das gesuchte Konto wurde gelöscht.
  bool _deleted = false;
  bool get deleted => _deleted;

  String? _lastEmail;
  String? _lastReason;

  /// Grund der letzten Suche, als Vorschlag für die nächsten Schritte.
  String get lastReason => _lastReason ?? '';

  AdminFailure? _error;
  AdminFailure? get error => _error;

  bool _busy = false;
  bool get busy => _busy;

  static bool isReasonValid(String reason) => reason.trim().length >= minReasonLength;

  Future<void> search({required String email, required String reason}) => _run(() async {
    _deleted = false;
    _lastEmail = email.trim();
    _lastReason = reason.trim();
    _family = await _repository.findFamily(email: _lastEmail!, reason: _lastReason!);
    _notFound = _family == null;
  });

  Future<void> grantPremium({required ManualPremiumDuration duration, required String reason}) => _run(() async {
    final family = _family;
    if (family == null) return;
    await _repository.setPremium(
      parentId: family.parentId,
      active: true,
      validUntil: duration.validUntil(_now()),
      reason: reason.trim(),
    );
    await _reload(reason);
  });

  Future<void> revokePremium({required String reason}) => _run(() async {
    final family = _family;
    if (family == null) return;
    await _repository.setPremium(parentId: family.parentId, active: false, reason: reason.trim());
    await _reload(reason);
  });

  Future<void> deleteFamily({required String reason}) => _run(() async {
    final family = _family;
    if (family == null) return;
    await _repository.deleteFamily(parentId: family.parentId, reason: reason.trim());
    _family = null;
    _notFound = false;
    _deleted = true;
  });

  /// Nach einer Änderung die Familie neu laden (auch das landet mit Grund im Audit-Log).
  Future<void> _reload(String reason) async {
    final email = _lastEmail;
    if (email == null) return;
    _family = await _repository.findFamily(email: email, reason: reason.trim());
    _notFound = _family == null;
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on AdminFailure catch (e) {
      _error = e;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
