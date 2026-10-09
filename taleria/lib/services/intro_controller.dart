import 'package:flutter/foundation.dart';

import '../data/child_repository.dart';
import '../domain/avatar.dart';
import '../domain/family_models.dart';
import '../domain/validators.dart';

/// Abschnitte des Intros (Station 1 des Hafens, INSELN.md):
/// Film, Talo und Tala erzählen, Avatar, Schiffstaufe, Rundgang,
/// erster Wunschschatz, Abschluss, Karte öffnet sich.
enum IntroStep { film, story, avatar, ship, tour, wish, done, map }

/// Ablauf des Intros. Speichert jeden Abschnitt sofort, damit nach einem
/// Abbruch nichts verloren geht. Kennt kein Aussehen.
class IntroController extends ChangeNotifier {
  IntroController({required this._repository, required this.child})
    : _avatar = child.avatar ?? const AvatarConfig(),
      _shipName = child.shipName ?? '';

  final ChildRepository _repository;
  final ChildProfile child;

  IntroStep _step = IntroStep.film;
  AvatarConfig _avatar;
  String _shipName;
  bool _busy = false;
  int _earnedXp = 0;
  bool _wishCreated = false;

  IntroStep get step => _step;
  AvatarConfig get avatar => _avatar;
  String get shipName => _shipName;
  bool get busy => _busy;

  /// Seemeilen aus dem Abschluss (für die Anzeige „+50 Seemeilen“).
  int get earnedXp => _earnedXp;
  bool get wishCreated => _wishCreated;

  void filmFinished() => _go(IntroStep.story, from: IntroStep.film);

  /// Das Kind sagt „Ja, ich bin dabei!“.
  void joinCrew() => _go(IntroStep.avatar, from: IntroStep.story);

  void updateAvatar(AvatarConfig avatar) {
    _avatar = avatar;
    notifyListeners();
  }

  Future<void> saveAvatar() => _run(IntroStep.avatar, IntroStep.ship, () {
    return _repository.updateLook(child.id, avatar: _avatar);
  });

  Future<void> christenShip(String name) {
    if (validateShipName(name) != null) throw ArgumentError.value(name, 'name');
    return _run(IntroStep.ship, IntroStep.tour, () async {
      await _repository.updateLook(child.id, shipName: name.trim());
      _shipName = name.trim();
    });
  }

  void tourFinished() => _go(IntroStep.wish, from: IntroStep.tour);

  /// Erster Wunschschatz. [euros] sind ganze Euro, geschätzt ist in Ordnung.
  Future<void> saveWish({required String title, required int euros}) {
    if (validateWishTitle(title) != null) throw ArgumentError.value(title, 'title');
    if (validateWishEuros('$euros') != null) throw ArgumentError.value(euros, 'euros');
    return _run(IntroStep.wish, IntroStep.done, () async {
      await _repository.createSavingsGoal(child.id, title: title, targetCents: eurosToCents(euros));
      _wishCreated = true;
      await _complete();
    });
  }

  /// „Weiß ich noch nicht“: Der Wunschschatz kann später angelegt werden.
  Future<void> skipWish() => _run(IntroStep.wish, IntroStep.done, _complete);

  void openMap() => _go(IntroStep.map, from: IntroStep.done);

  Future<void> _complete() async {
    _earnedXp = await _repository.completeOnboarding(child.id);
  }

  void _go(IntroStep to, {required IntroStep from}) {
    if (_step != from) return;
    _step = to;
    notifyListeners();
  }

  /// Führt eine Speicher-Aktion aus und geht erst bei Erfolg weiter.
  /// Fehler gehen an die Oberfläche, der Abschnitt bleibt offen.
  Future<void> _run(IntroStep from, IntroStep to, Future<void> Function() action) async {
    if (_step != from || _busy) return;
    _busy = true;
    notifyListeners();
    try {
      await action();
      _step = to;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
