/// Spielregeln der Mini-Spiele: Sortieren, Reihenfolge, Entscheidungen,
/// Münzen legen, Auswählen und Rechnen. Ohne Aussehen. Falsche Versuche kosten
/// nichts, das Kind probiert weiter, bis alles stimmt (CLAUDE.md: kein Druck).
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

/// Entscheidungen: pro Runde eine Situation mit Möglichkeiten. Eine gute Wahl
/// führt weiter, nach einer weniger guten zeigt die Rückmeldung warum, und das
/// Kind wählt noch einmal.
class ChoiceGame {
  ChoiceGame(this.game, Random random)
    : _orders = [for (final r in game.rounds) List.generate(r.options.length, (i) => i)..shuffle(random)];

  final GameInfo game;
  final List<List<int>> _orders;
  int _index = 0;
  int? _chosen;

  int get index => _index;
  int get total => game.rounds.length;
  GameRound get current => game.rounds[_index];

  /// Stellen der Möglichkeiten in der angezeigten (gemischten) Reihenfolge.
  List<int> get optionOrder => _orders[_index];

  /// Gewählte Möglichkeit (Stelle in den Daten), sonst `null`.
  int? get chosen => _chosen;
  GameOption? get chosenOption => _chosen == null ? null : current.options[_chosen!];
  bool get answered => _chosen != null;
  bool get answeredWell => chosenOption?.good ?? false;
  bool get isLast => _index == total - 1;
  bool get finished => isLast && answeredWell;

  void choose(int option) {
    if (answeredWell) return;
    _chosen = option;
  }

  void retry() {
    if (answered && !answeredWell) _chosen = null;
  }

  void next() {
    if (!answeredWell || isLast) return;
    _index++;
    _chosen = null;
  }
}

/// Münzen legen: Münzen und Scheine antippen, bis der Betrag genau stimmt.
class CoinsGame {
  CoinsGame(this.game);

  /// Euro-Münzen und -Scheine in Cent.
  static const values = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000];

  /// Ab diesem Wert ist es ein Schein.
  static const firstNote = 500;

  /// So wenige Münzen und Scheine reichen für [cents] (beim Euro immer mit den größten zuerst).
  static int fewestPieces(int cents) {
    var rest = cents;
    var count = 0;
    for (final v in values.reversed) {
      count += rest ~/ v;
      rest %= v;
    }
    return count;
  }

  final GameInfo game;
  final List<int> placed = [];
  int _index = 0;

  int get index => _index;
  int get total => game.rounds.length;
  GameRound get current => game.rounds[_index];
  int get target => current.amount ?? 0;
  int get sum => placed.fold(0, (a, b) => a + b);
  bool get exact => sum == target;
  bool get tooMuch => sum > target;
  bool get isLast => _index == total - 1;
  bool get finished => isLast && exact;

  /// Geschafft, aber mit mehr Münzen als nötig.
  bool get couldUseFewer => exact && placed.length > fewestPieces(target);

  void add(int value) {
    if (exact) return;
    placed.add(value);
  }

  void removeAt(int position) {
    if (exact || position < 0 || position >= placed.length) return;
    placed.removeAt(position);
  }

  void clear() {
    if (!exact) placed.clear();
  }

  void next() {
    if (!exact || isLast) return;
    _index++;
    placed.clear();
  }
}

/// Ergebnis einer Prüfung beim Auswählen.
enum PickResult { solved, tooMuch, tooLittle, wrongItem, missingItem }

/// Auswählen: Dinge antippen, bis der Betrag genau stimmt (Preis-Säule) oder
/// das Wichtige im Budget ist (Rucksack).
class PickGame {
  PickGame(this.game);

  final GameInfo game;
  final Set<int> selected = {};
  PickResult? _result;

  /// Ding, auf das sich die letzte Rückmeldung bezieht (falsch gewählt oder vergessen).
  int? hintItem;

  PickResult? get result => _result;
  bool get solved => _result == PickResult.solved;
  int get target => game.target ?? 0;
  int get sum => selected.fold(0, (a, i) => a + (game.items[i].price ?? 0));

  void toggle(int item) {
    if (solved) return;
    if (!selected.remove(item)) selected.add(item);
    _result = null;
    hintItem = null;
  }

  PickResult check() {
    final items = game.items;
    final missing = [
      for (final (i, item) in items.indexed)
        if (item.required && !selected.contains(i)) i,
    ];
    if (game.exactTarget) {
      final wrong = selected.where((i) => !items[i].required).toList()..sort();
      if (wrong.isNotEmpty) {
        hintItem = wrong.first;
        return _result = PickResult.wrongItem;
      }
      if (missing.isNotEmpty) return _result = PickResult.tooLittle;
      return _result = PickResult.solved;
    }
    if (sum > target) return _result = PickResult.tooMuch;
    if (missing.isNotEmpty) {
      hintItem = missing.first;
      return _result = PickResult.missingItem;
    }
    return _result = PickResult.solved;
  }
}

/// Rechnen: Zahl eingeben. Nach einem falschen Versuch gibt es einen Tipp und
/// auf Wunsch die Lösung mit Erklärung.
class NumberGame {
  NumberGame(this.game);

  final GameInfo game;
  int _index = 0;
  bool _correct = false;
  bool _revealed = false;
  int _wrongTries = 0;

  int get index => _index;
  int get total => game.rounds.length;
  GameRound get current => game.rounds[_index];
  bool get correct => _correct;
  bool get revealed => _revealed;
  int get wrongTries => _wrongTries;

  /// Richtig gelöst oder Lösung angesehen: Es geht weiter.
  bool get canContinue => _correct || _revealed;
  bool get isLast => _index == total - 1;
  bool get finished => isLast && canContinue;

  bool submit(int value) {
    if (canContinue) return _correct;
    if (value == current.amount) {
      _correct = true;
    } else {
      _wrongTries++;
    }
    return _correct;
  }

  /// Erst nach einem falschen Versuch.
  void reveal() {
    if (_wrongTries > 0) _revealed = true;
  }

  void next() {
    if (!canContinue || isLast) return;
    _index++;
    _correct = false;
    _revealed = false;
    _wrongTries = 0;
  }
}
