/// Spielregeln der echten Mini-Spiele: Kasse, Markt-Einkauf, Eisstand und
/// Tauschkette. Ohne Aussehen. Wie bei den Übungen kosten Fehler nichts; sie
/// zählen nur für die Sterne am Ende (immer mindestens einer).
library;

import 'dart:math';

import 'content_models.dart';

/// Sterne aus Fehlern: 0 bis 1 Fehler drei, 2 bis 3 Fehler zwei, sonst einer.
int starsForMistakes(int mistakes) => mistakes <= 1 ? 3 : (mistakes <= 3 ? 2 : 1);

/// Ergebnis beim Herausgeben an der Kasse.
enum TillCheck { right, tooMuch, tooLittle }

/// Kasse: Kunden bezahlen, das Kind legt das Wechselgeld und gibt es heraus.
class TillGame {
  TillGame(this.game);

  final GameInfo game;
  final List<int> placed = [];
  int _index = 0;
  int _mistakes = 0;
  TillCheck? _check;

  int get index => _index;
  int get total => game.customers.length;
  TillCustomer get current => game.customers[_index];
  int get change => current.change;
  int get sum => placed.fold(0, (a, b) => a + b);
  int get mistakes => _mistakes;

  /// Letzte Prüfung beim aktuellen Kunden, sonst `null`.
  TillCheck? get check => _check;
  bool get served => _check == TillCheck.right;

  /// Abstand zum richtigen Wechselgeld (für die Rückmeldung).
  int get difference => (sum - change).abs();
  bool get isLast => _index == total - 1;
  bool get finished => isLast && served;
  int get stars => starsForMistakes(_mistakes);

  void add(int value) {
    if (served) return;
    placed.add(value);
    _check = null;
  }

  void removeAt(int position) {
    if (served || position < 0 || position >= placed.length) return;
    placed.removeAt(position);
    _check = null;
  }

  void clear() {
    if (served) return;
    placed.clear();
    _check = null;
  }

  /// Wechselgeld herausgeben.
  TillCheck give() {
    if (served) return TillCheck.right;
    if (sum == change) return _check = TillCheck.right;
    _mistakes++;
    return _check = sum > change ? TillCheck.tooMuch : TillCheck.tooLittle;
  }

  void next() {
    if (!served || isLast) return;
    _index++;
    placed.clear();
    _check = null;
  }
}

/// Ergebnis beim Kaufen auf dem Markt.
enum MarketBuy { bought, notOnList, alreadyHave, notEnoughMoney }

/// Markt-Einkauf: alles auf der Liste kaufen, ohne dass das Geld ausgeht.
class MarketGame {
  MarketGame(this.game);

  final GameInfo game;

  /// Gekauft: Ding der Liste → Stand und Preis pro Stück.
  final Map<String, ({int stand, int price})> cart = {};

  int get budget => game.budget ?? 0;
  MarketNeed? needFor(String item) => game.needs.where((n) => n.item == item).firstOrNull;
  int get spent => [for (final n in game.needs) (cart[n.item]?.price ?? 0) * n.count].fold(0, (a, b) => a + b);
  int get left => budget - spent;
  bool get finished => game.needs.every((n) => cart.containsKey(n.item));

  /// Günstigster Preis pro Stück für [item] an allen Ständen.
  int cheapest(String item) =>
      game.stands.expand((s) => s.offers).where((o) => o.item == item).map((o) => o.price).fold(1 << 30, min);

  /// So wenig kostet die ganze Liste, wenn man überall vergleicht.
  int get cheapestTotal => [for (final n in game.needs) cheapest(n.item) * n.count].fold(0, (a, b) => a + b);

  /// Das Fehlende geht sich selbst zum günstigsten Preis nicht mehr aus.
  bool get stuck =>
      !finished &&
      [
            for (final n in game.needs)
              if (!cart.containsKey(n.item)) cheapest(n.item) * n.count,
          ].fold(0, (a, b) => a + b) >
          left;

  /// Drei Sterne, wenn überall der günstigste Stand gewählt wurde.
  int get stars => spent <= cheapestTotal ? 3 : 2;

  MarketBuy buy(int stand, MarketOffer offer) {
    final need = needFor(offer.item);
    if (need == null) return MarketBuy.notOnList;
    if (cart.containsKey(offer.item)) return MarketBuy.alreadyHave;
    if (offer.price * need.count > left) return MarketBuy.notEnoughMoney;
    cart[offer.item] = (stand: stand, price: offer.price);
    return MarketBuy.bought;
  }

  /// Zurücklegen: Das Geld kommt zurück.
  void putBack(String item) {
    if (finished) return;
    cart.remove(item);
  }
}

/// Ein Versuch am Eisstand.
class IceTry {
  const IceTry({required this.price, required this.customers, required this.sold, required this.stock});

  final int price;

  /// So viele wollten zu diesem Preis Eis.
  final int customers;
  final int sold;
  final int stock;

  int get earned => sold * price;
  int get melted => stock - sold;
  int get missed => customers - sold;
}

/// Eisstand: An jedem Tag einen Preis setzen und sehen, was passiert.
class IceStandGame {
  IceStandGame(this.game) : _price = min(game.priceMin + 1, game.priceMax);

  final GameInfo game;
  int _day = 0;
  int _price;
  IceTry? _last;
  final Set<int> _bestFound = {};

  int get index => _day;
  int get total => game.days.length;
  IceDay get day => game.days[_day];
  int get price => _price;
  IceTry? get last => _last;
  bool get isLast => _day == total - 1;

  /// Weiter geht es nach mindestens einem Versuch.
  bool get canContinue => _last != null;
  bool get finished => isLast && canContinue;

  /// Tage, an denen das Kind den besten Preis gefunden hat.
  int get bestDays => _bestFound.length;
  bool get bestFoundToday => _bestFound.contains(_day);
  int get stars => max(1, (3 * bestDays / total).ceil());

  static IceTry simulate(IceDay day, int price) {
    final customers = max(0, day.demand - day.drop * price);
    return IceTry(price: price, customers: customers, sold: min(customers, day.stock), stock: day.stock);
  }

  /// Höchste Einnahme des Tages bei den erlaubten Preisen.
  int bestEarned(IceDay day) =>
      [for (var p = game.priceMin; p <= game.priceMax; p++) simulate(day, p).earned].fold(0, max);

  /// Alle Preise mit der höchsten Einnahme.
  List<int> bestPrices(IceDay day) {
    final best = bestEarned(day);
    return [
      for (var p = game.priceMin; p <= game.priceMax; p++)
        if (simulate(day, p).earned == best) p,
    ];
  }

  void setPrice(int value) => _price = value.clamp(game.priceMin, game.priceMax);

  /// Stand öffnen: Wie viele kommen, was wird verkauft?
  IceTry open() {
    final result = simulate(day, _price);
    if (result.earned == bestEarned(day)) _bestFound.add(_day);
    return _last = result;
  }

  void next() {
    if (!canContinue || isLast) return;
    // Der Preis vom Vortag bleibt stehen, wie das Schild am Stand.
    _day++;
    _last = null;
  }
}

/// Ergebnis beim Antippen eines Händlers.
enum TradeResult { traded, refused, alreadyTraded }

/// Tauschkette: Mit dem, was man hat, so lange tauschen, bis man das Ziel hat.
class TradeChainGame {
  TradeChainGame(this.game) : _holding = game.start ?? '';

  final GameInfo game;
  String _holding;
  final Set<int> _used = {};
  final List<String> history = [];
  int _resets = 0;
  int? _refusedBy;

  String get holding => _holding;
  Set<int> get used => _used;

  /// Händler, der zuletzt abgelehnt hat, sonst `null`.
  int? get refusedBy => _refusedBy;
  bool get finished => _holding == game.goal;

  /// Niemand, mit dem man noch nicht getauscht hat, will das, was man hat.
  bool get stuck => !finished && !game.traders.indexed.any((e) => !_used.contains(e.$1) && e.$2.wants == _holding);
  int get resets => _resets;
  int get stars => _resets == 0 ? 3 : (_resets == 1 ? 2 : 1);

  TradeResult tap(int trader) {
    if (finished) return TradeResult.alreadyTraded;
    if (_used.contains(trader)) return TradeResult.alreadyTraded;
    final t = game.traders[trader];
    if (t.wants != _holding) {
      _refusedBy = trader;
      return TradeResult.refused;
    }
    history.add(_holding);
    _holding = t.has;
    _used.add(trader);
    _refusedBy = null;
    return TradeResult.traded;
  }

  /// Von vorn: wieder nur mit dem Start-Ding.
  void reset() {
    _holding = game.start ?? '';
    _used.clear();
    history.clear();
    _refusedBy = null;
    _resets++;
  }
}
