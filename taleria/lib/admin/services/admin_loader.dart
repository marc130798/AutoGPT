import 'package:flutter/foundation.dart';

import '../data/admin_failure.dart';

/// Lädt eine Seite des Adminbereichs (Übersicht, Inhalte, Protokoll) und merkt sich Fehler.
class AdminLoader<T> extends ChangeNotifier {
  AdminLoader(this._load);

  final Future<T> Function() _load;

  T? _data;
  T? get data => _data;

  AdminFailure? _error;
  AdminFailure? get error => _error;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _load();
    } on AdminFailure catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
