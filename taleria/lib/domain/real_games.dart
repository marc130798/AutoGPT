/// Spielregeln der echten Mini-Spiele: Kasse, Markt-Einkauf, Eisstand,
/// Tauschkette und Rucksack packen. Ohne Aussehen. Wie bei den Übungen kosten Fehler nichts; sie
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

/// Ergebnis beim Einpacken.
enum BackpackPack { packed, notEnough, alreadyGone }

/// Rucksack packen: Für jeden Ausflug mit den Talern einpacken, was Tala
/// wirklich braucht. Beim Losgehen zeigt sich, was fehlt; dann packt das Kind
/// nach. Übrige Taler kommen in Talas Schatztruhe.
class BackpackGame {
  BackpackGame(this.game);

  final GameInfo game;
  int _trip = 0;
  int _mistakes = 0;
  int _saved = 0;
  bool _gone = false;
  List<BackpackNeed> _missing = const [];

  /// Eingepackt, in der Reihenfolge des Einpackens.
  final List<String> packed = [];

  int get index => _trip;
  int get total => game.trips.length;
  BackpackTrip get trip => game.trips[_trip];
  bool get isLast => _trip == total - 1;
  int get mistakes => _mistakes;
  int get stars => starsForMistakes(_mistakes);

  /// Ausflug geschafft: alles dabei, Tala ist losgegangen.
  bool get gone => _gone;
  bool get finished => isLast && _gone;

  /// Was beim letzten Losgehen gefehlt hat.
  List<BackpackNeed> get missing => _missing;

  /// Preis eines Dings im Packhaus (in Talern).
  int price(String item) => game.items.where((i) => i.text == item).firstOrNull?.price ?? 0;
  int get spent => packed.fold(0, (sum, item) => sum + price(item));
  int get left => trip.budget - spent;

  /// Eingepackt, aber auf diesem Ausflug nicht gebraucht.
  List<String> get extras => [
    for (final item in packed)
      if (!trip.needs.any((n) => n.item == item)) item,
  ];

  /// Taler, die auf allen geschafften Ausflügen übrig blieben.
  int get saved => _saved;

  BackpackPack pack(String item) {
    if (_gone) return BackpackPack.alreadyGone;
    if (packed.contains(item)) return BackpackPack.packed;
    if (price(item) > left) return BackpackPack.notEnough;
    packed.add(item);
    return BackpackPack.packed;
  }

  void unpack(String item) {
    if (_gone) return;
    packed.remove(item);
  }

  /// Losgehen: Fehlt etwas, zählt es als Fehler und Tala kommt zurück.
  bool go() {
    if (_gone) return true;
    _missing = [
      for (final need in trip.needs)
        if (!packed.contains(need.item)) need,
    ];
    if (_missing.isNotEmpty) {
      _mistakes++;
      return false;
    }
    _gone = true;
    _saved += left;
    return true;
  }

  void next() {
    if (!_gone || isLast) return;
    _trip++;
    packed.clear();
    _missing = const [];
    _gone = false;
  }
}

/// Emmas Wintervorrat: An jedem Herbsttag isst Emma gleich ([eat], wenige
/// Nüsse) oder vergräbt sie für später ([store], mehr Nüsse). Danach kommt der
/// Winter: Reicht der Vorrat, klopft Gustav hungrig an und das Kind entscheidet,
/// ob Emma teilt. Reicht er nicht, beginnt der Herbst von vorn (ein Fehler).
class WinterStoreGame {
  WinterStoreGame(this.game) : spec = game.winter!;

  final GameInfo game;
  final WinterStoreSpec spec;

  int _day = 0;
  int _eaten = 0;
  int _stored = 0;
  int _mistakes = 0;
  bool? _shared;

  /// Was an jedem Tag gewählt wurde (true = gewartet).
  final List<bool> choices = [];

  int get day => _day;
  int get days => spec.days.length;
  int get eaten => _eaten;
  int get stored => _stored;
  int get need => spec.need;
  int get mistakes => _mistakes;
  int get stars => starsForMistakes(_mistakes);

  /// Gustav isst jeden Tag alles sofort.
  int get gustavEaten => days * spec.now;

  /// Herbst vorbei: Jetzt ist Winter.
  bool get winter => _day >= days;
  bool get enough => _stored >= spec.need;

  /// Was nach dem Winter übrig bleibt (zum Teilen).
  int get surplus => max(0, _stored - spec.need);

  /// null = noch nicht entschieden (oder nichts zum Teilen).
  bool? get shared => _shared;

  /// Geschafft: genug im Vorrat und über das Teilen entschieden (falls etwas übrig ist).
  bool get finished => winter && enough && (surplus == 0 || _shared != null);

  void eat() => _choose(false);
  void store() => _choose(true);

  void _choose(bool wait) {
    if (winter) return;
    choices.add(wait);
    if (wait) {
      _stored += spec.later;
    } else {
      _eaten += spec.now;
    }
    _day++;
    if (winter && !enough) _mistakes++;
  }

  void decideShare(bool share) {
    if (!winter || !enough || surplus == 0 || _shared != null) return;
    _shared = share;
  }

  /// Reicht der Vorrat nicht: noch einmal von vorn.
  void restart() {
    _day = 0;
    _eaten = 0;
    _stored = 0;
    _shared = null;
    choices.clear();
  }
}

/// Sparschwein füttern: Zuerst einen Sparbetrag pro Woche wählen ([choosePlan]),
/// dann jede Woche füttern ([feed]); der Rest kommt in die Hosentasche. In
/// manchen Wochen lockt etwas zum Kaufen oder es gibt ein Geschenk. Am Ende
/// zählt, ob das Schwein genug für den Wunschschatz hat; sonst von vorn.
class PiggyBankGame {
  PiggyBankGame(this.game) : spec = game.piggy!;

  final GameInfo game;
  final PiggyBankSpec spec;

  int? _plan;
  int _week = 0;
  bool _fed = false;
  bool _eventDone = false;
  int _pig = 0;
  int _pocket = 0;
  int _mistakes = 0;
  final List<String> bought = [];

  int? get plan => _plan;
  int get week => _week;
  int get weeks => spec.weeks.length;
  PiggyWeek get current => spec.weeks[min(_week, weeks - 1)];
  int get pig => _pig;
  int get pocket => _pocket;
  int get mistakes => _mistakes;
  int get stars => starsForMistakes(_mistakes);
  bool get fed => _fed;
  bool get started => _plan != null;

  /// Was der Plan ohne Geschenke und Käufe ergibt.
  int planTotal(int amount) => amount * weeks;

  /// Die Woche ist fertig: gefüttert und das Ereignis entschieden.
  bool get weekDone => _fed && (current.event == null || _eventDone);
  bool get eventOpen => _fed && current.event != null && !_eventDone;
  bool get over => _week >= weeks;
  bool get reached => _pig >= spec.goalPrice;
  bool get finished => over && reached;

  void choosePlan(int amount) {
    if (started || !spec.plans.contains(amount)) return;
    _plan = amount;
  }

  void feed() {
    if (!started || over || _fed) return;
    _pig += _plan!;
    _pocket += spec.income - _plan!;
    _fed = true;
  }

  bool get canBuyFromPocket => _pocket >= (current.event?.price ?? 0);
  bool get canBuyFromPig => _pig >= (current.event?.price ?? 0);

  /// Versuchung: aus der Hosentasche kaufen, aus dem Schwein kaufen oder lassen.
  void buy({required bool fromPig}) {
    final event = current.event;
    if (!eventOpen || event == null || event.gift) return;
    if (fromPig ? !canBuyFromPig : !canBuyFromPocket) return;
    if (fromPig) {
      _pig -= event.price;
    } else {
      _pocket -= event.price;
    }
    bought.add(event.item);
    _eventDone = true;
  }

  void skip() {
    if (eventOpen && !(current.event?.gift ?? true)) _eventDone = true;
  }

  /// Geschenk: ins Schwein oder in die Hosentasche.
  void takeGift({required bool intoPig}) {
    final event = current.event;
    if (!eventOpen || event == null || !event.gift) return;
    if (intoPig) {
      _pig += event.price;
    } else {
      _pocket += event.price;
    }
    _eventDone = true;
  }

  void nextWeek() {
    if (!weekDone || over) return;
    _week++;
    _fed = false;
    _eventDone = false;
    if (over && !reached) _mistakes++;
  }

  /// Nicht gereicht: neuer Plan, alles von vorn.
  void restart() {
    _plan = null;
    _week = 0;
    _fed = false;
    _eventDone = false;
    _pig = 0;
    _pocket = 0;
    bought.clear();
  }
}

/// Ergebnis beim Trick-Erkennen im Glitzerladen.
enum ShopGuess { right, wrong }

/// Elsas Glitzerladen: Elsa preist jedes Ding mit einem Verkaufstrick an. Das
/// Kind erkennt den Trick ([guess]) und entscheidet dann, ob Tala das Ding
/// wirklich braucht ([decide]). Falscher Trick und Gekauftes, das nicht auf
/// der Liste steht, zählen als Fehler; ein Ding von der Liste muss mit.
class GlitterShopGame {
  GlitterShopGame(this.game);

  final GameInfo game;
  int _offer = 0;
  int _mistakes = 0;
  bool _spotted = false;
  bool? _bought;
  bool _wrongSkip = false;
  late int _money = game.budget ?? 0;
  final List<String> bought = [];
  final Set<String> wrongTricks = {};

  int get index => _offer;
  int get total => game.offers.length;
  ShopOffer get offer => game.offers[min(_offer, total - 1)];
  bool get isLast => _offer == total - 1;
  int get money => _money;
  int get mistakes => _mistakes;
  int get stars => starsForMistakes(_mistakes);
  bool get spotted => _spotted;

  /// null = noch nicht entschieden.
  bool? get decision => _bought;

  /// Ein Ding von der Liste wurde abgelehnt.
  bool get wrongSkip => _wrongSkip;
  bool get offerDone => _bought != null;
  bool get finished => isLast && offerDone;

  /// Drei Möglichkeiten: der richtige Trick und zwei andere, fest pro Angebot gemischt.
  List<String> get trickOptions {
    final others = [
      for (final t in shopTricks)
        if (t != offer.trick) t,
    ]..shuffle(Random(_offer + 7));
    return [offer.trick, ...others.take(2)]..shuffle(Random(_offer + 3));
  }

  ShopGuess guess(String trick) {
    if (_spotted) return ShopGuess.right;
    if (trick == offer.trick) {
      _spotted = true;
      return ShopGuess.right;
    }
    if (wrongTricks.add(trick)) _mistakes++;
    return ShopGuess.wrong;
  }

  bool get canAfford => _money >= offer.price;

  /// Kaufen oder lassen. Ein Ding von der Liste lässt sich nicht weglassen.
  void decide({required bool buy}) {
    if (!_spotted || offerDone) return;
    if (!buy && offer.needed) {
      if (!_wrongSkip) _mistakes++;
      _wrongSkip = true;
      return;
    }
    if (buy) {
      if (!canAfford) return;
      _money -= offer.price;
      bought.add(offer.item);
      if (!offer.needed) _mistakes++;
    }
    _bought = buy;
  }

  /// Unnötig Gekauftes zurückgeben, damit die Taler für die Liste reichen.
  void giveBack(String item) {
    final o = game.offers.where((o) => o.item == item && !o.needed).firstOrNull;
    if (o == null || !bought.remove(item)) return;
    _money += o.price;
  }

  /// Gekauft, aber nicht auf der Liste.
  List<String> get extras => [
    for (final item in bought)
      if (!game.offers.any((o) => o.item == item && o.needed)) item,
  ];

  void next() {
    if (!offerDone || isLast) return;
    _offer++;
    _spotted = false;
    _bought = null;
    _wrongSkip = false;
    wrongTricks.clear();
  }
}

/// Mias Kiosk-Woche: Mit dem Taschengeld einer Woche kommt das Kind jeden Tag
/// am Kiosk vorbei. Wünsche darf es kaufen oder lassen, Nötiges (zum
/// Beispiel die Busfahrt) muss bezahlt werden. Reicht das Geld dafür nicht
/// mehr, beginnt die Woche von vorn (ein Fehler für die Sterne).
class KioskWeekGame {
  KioskWeekGame(this.game);

  final GameInfo game;

  int _day = 0;
  int _money = 0;
  int _mistakes = 0;
  bool _broke = false;
  final List<String> bought = [];

  List<KioskDay> get days => game.kioskDays;
  int get budget => game.budget ?? 0;
  int get day => _day;
  int get money => _money;
  int get mistakes => _mistakes;
  int get stars => starsForMistakes(_mistakes);
  bool get finished => _day >= days.length;
  KioskDay get current => days[min(_day, days.length - 1)];

  /// Das Geld reicht nicht für etwas, das sein muss: die Woche beginnt neu.
  bool get broke => _broke;

  bool get canPay => _money >= current.price;

  /// Was in der Woche noch bezahlt werden muss (ab heute).
  int get mustLeft => [
    for (final d in days.skip(_day))
      if (d.must) d.price,
  ].fold(0, (a, b) => a + b);

  void start() {
    _day = 0;
    _money = budget;
    _broke = false;
    bought.clear();
  }

  /// Kaufen (bei einem Wunsch) oder bezahlen (bei etwas Nötigem).
  void buy() {
    if (finished || _broke) return;
    if (!canPay) {
      if (current.must) {
        _broke = true;
        _mistakes++;
      }
      return;
    }
    _money -= current.price;
    bought.add(current.item);
    _day++;
  }

  /// Einen Wunsch auslassen. Nötiges lässt sich nicht auslassen.
  void skip() {
    if (finished || _broke || current.must) return;
    _day++;
  }

  /// Nach einer Pleite: die Woche noch einmal, mit vollem Taschengeld.
  void restart() => start();
}

/// Kurts Logbuch: Kassenzettel kommen der Reihe nach; das Kind trägt jeden als
/// Einnahme oder Ausgabe ein, der Stand läuft mit. Am Ende zeigt ein Balken je
/// Gruppe, wofür das meiste Geld ausgegeben wurde, und das Kind tippt die
/// größte Gruppe an. Falsch Eingetragenes zählt nur für die Sterne.
class LogbookGame {
  LogbookGame(this.game) : _balance = game.logStart;

  final GameInfo game;

  int _index = 0;
  int _balance;
  int _mistakes = 0;
  bool _done = false;

  List<LogbookEntry> get entries => game.logEntries;
  int get index => _index;
  int get balance => _balance;
  int get mistakes => _mistakes;
  int get stars => starsForMistakes(_mistakes);
  bool get allBooked => _index >= entries.length;
  bool get finished => _done;
  LogbookEntry get current => entries[min(_index, entries.length - 1)];

  /// Eingetragene Zettel.
  List<LogbookEntry> get booked => entries.take(_index).toList();

  /// Ausgaben je Gruppe, in der Reihenfolge, in der die Gruppen vorkommen.
  Map<String, int> get spending {
    final out = <String, int>{};
    for (final e in entries) {
      if (!e.income) out[e.group] = (out[e.group] ?? 0) + e.amount;
    }
    return out;
  }

  /// Die Gruppe mit den meisten Ausgaben.
  String get biggest => spending.entries.reduce((a, b) => b.value > a.value ? b : a).key;

  /// Zettel eintragen: richtig ist es, wenn Einnahme und Ausgabe stimmen.
  bool book({required bool income}) {
    if (allBooked) return false;
    if (income != current.income) {
      _mistakes++;
      return false;
    }
    _balance += current.income ? current.amount : -current.amount;
    _index++;
    return true;
  }

  /// Am Ende: Wofür ging am meisten Geld drauf?
  bool guessBiggest(String group) {
    if (!allBooked || _done) return false;
    if (group != biggest) {
      _mistakes++;
      return false;
    }
    _done = true;
    return true;
  }
}
