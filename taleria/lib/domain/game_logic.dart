/// Spielregeln der Mini-Spiele „Sortieren“ und „Reihenfolge“ (Schritt 7).
/// Ohne Aussehen. Falsche Versuche kosten nichts, das Kind probiert weiter,
/// bis alles stimmt (CLAUDE.md: kein Druck).
library;

import 'dart:math';

import 'content_models.dart';

/// Sortieren: ein Ding nach dem anderen in den passenden Korb.
class SortGame {
  SortGame(this.game, Random random) : _order = List.generate(game.items.length, (i) => i)..shuffle(random);

  final GameInfo game;
  final List<int> _order;
  int _index = 0;
  int? _choice;

  int get index => _index;
  int get total => _order.length;
  GameItem get current => game.items[_order[_index]];

  /// Gewählter Korb im aktuellen Versuch, sonst `null`.
  int? get choice => _choice;
  bool get answered => _choice != null;

  /// Dinge „dazwischen“ (ohne festen Korb) passen in jeden Korb.
  bool get answeredCorrectly => answered && (current.basket == null || current.basket == _choice);
  bool get isLast => _index == _order.length - 1;
  bool get finished => isLast && answeredCorrectly;

  void choose(int basket) {
    if (answeredCorrectly) return;
    _choice = basket;
  }

  /// Nach einem falschen Korb: nochmal wählen.
  void retry() {
    if (answered && !answeredCorrectly) _choice = null;
  }

  void next() {
    if (!answeredCorrectly || isLast) return;
    _index++;
    _choice = null;
  }
}

/// Reihenfolge: Dinge der Reihe nach antippen (von … bis …).
class OrderGame {
  OrderGame(this.game, Random random) : shuffled = List.generate(game.items.length, (i) => i)..shuffle(random);

  final GameInfo game;

  /// Stellen der Dinge in der Reihenfolge, in der sie angezeigt werden.
  final List<int> shuffled;

  /// Schon richtig gelegte Dinge (Stellen in der richtigen Reihenfolge).
  final List<int> placed = [];

  /// Zuletzt falsch angetipptes Ding, sonst `null`.
  int? wrongTap;

  bool get finished => placed.length == game.items.length;
  GameItem? get lastPlaced => placed.isEmpty ? null : game.items[placed.last];

  /// `true`, wenn [item] das nächste Ding in der Reihe ist.
  bool tap(int item) {
    if (finished || placed.contains(item)) return false;
    if (item == placed.length) {
      placed.add(item);
      wrongTap = null;
      return true;
    }
    wrongTap = item;
    return false;
  }
}
