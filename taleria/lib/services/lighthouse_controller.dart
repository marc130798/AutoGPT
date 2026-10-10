import 'package:flutter/foundation.dart';

import '../data/budget_repository.dart';
import '../data/content_repository.dart';
import '../data/family_repository.dart';
import '../domain/family_models.dart';
import '../domain/progress_models.dart';
import '../domain/validators.dart';

/// Kinder-Profile im Leuchtturm: laden, anlegen, ändern, löschen, Codes.
class LighthouseController extends ChangeNotifier {
  LighthouseController({required this._family, required this.parent, this._budget, this._progress});

  final FamilyRepository _family;
  final BudgetRepository? _budget;
  final ProgressRepository? _progress;
  final ParentAccount parent;

  Map<String, int> _pendingTasks = const {};
  Map<String, ChildStats> _stats = const {};

  /// Wie viele gemeldete Aufgaben bei diesem Kind auf Bestätigung warten.
  int pendingFor(String childId) => _pendingTasks[childId] ?? 0;

  /// Gemeldete Aufgaben aller Kinder zusammen.
  int get pendingTotal => _children.fold(0, (sum, c) => sum + pendingFor(c.id));

  /// Level, Fortschritt und letzter Tag an Bord, sobald geladen.
  ChildStats? statsFor(String childId) => _stats[childId];

  List<ChildProfile> _children = const [];
  bool _loading = true;
  FailureKind? _loadFailure;

  List<ChildProfile> get children => _children;
  bool get loading => _loading;
  FailureKind? get loadFailure => _loadFailure;

  Future<void> load() async {
    _loading = true;
    _loadFailure = null;
    notifyListeners();
    try {
      _children = await _family.fetchChildren();
    } on AppFailure catch (e) {
      _loadFailure = e.kind;
    }
    _loading = false;
    notifyListeners();
    await loadPendingTasks();
    await loadStats();
  }

  /// Kurze Übersicht pro Kind. Nur ein Hinweis: Fehler werden weggelassen.
  Future<void> loadStats() async {
    final progress = _progress;
    if (progress == null) return;
    final stats = <String, ChildStats>{};
    for (final child in _children.where((c) => c.onboardingCompleted)) {
      try {
        stats[child.id] = await progress.fetchStats(child.id);
      } on AppFailure {
        // Ohne Verbindung einfach ohne Übersicht.
      }
    }
    _stats = stats;
    notifyListeners();
  }

  Future<void> loadPendingTasks() async {
    final budget = _budget;
    if (budget == null) return;
    try {
      _pendingTasks = await budget.fetchSubmittedTaskCounts();
      notifyListeners();
    } on AppFailure {
      // Nur ein Hinweis. Ohne Verbindung einfach weglassen.
    }
  }

  Future<ChildProfile> createChild({
    required String nickname,
    required int birthYear,
    required LevelSetting level,
  }) async {
    _checkNickname(nickname);
    final child = await _family.createChild(
      parentId: parent.id,
      nickname: nickname.trim(),
      birthYear: birthYear,
      level: level,
    );
    _children = [..._children, child];
    notifyListeners();
    return child;
  }

  Future<ChildProfile> updateChild(ChildProfile child) async {
    _checkNickname(child.nickname);
    final updated = await _family.updateChild(child);
    _children = [for (final c in _children) c.id == updated.id ? updated : c];
    notifyListeners();
    return updated;
  }

  Future<void> deleteChild(String childId) async {
    await _family.deleteChild(childId);
    _children = _children.where((c) => c.id != childId).toList();
    notifyListeners();
  }

  ChildProfile? childById(String id) => _children.where((c) => c.id == id).firstOrNull;

  Future<LoginCode> createLoginCode(String childId) => _family.createLoginCode(childId);

  Future<int> countDevices(String childId) => _family.countChildDevices(childId);

  Future<void> signOutDevices(String childId) => _family.signOutChildDevices(childId);

  Future<void> changePin(String pin) {
    if (validatePin(pin) != null) throw ArgumentError.value(pin, 'pin');
    return _family.setParentPin(pin);
  }

  static void _checkNickname(String nickname) {
    if (validateNickname(nickname) != null) throw ArgumentError.value(nickname, 'nickname');
  }
}
