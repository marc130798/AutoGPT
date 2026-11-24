/// Inhalte und Fortschritt auf der Inselkarte. Ohne Aussehen, ohne Supabase.
library;

import 'family_models.dart';
import 'progress_models.dart';

/// Eine Insel auf der Karte (aus map_islands()).
class MapIsland {
  const MapIsland({
    required this.id,
    required this.slug,
    required this.title,
    required this.sortOrder,
    required this.mapX,
    required this.mapY,
    required this.hasContent,
    this.group,
    this.routeType = 'main',
    this.access = 'free',
  });

  final String id;
  final String slug;
  final String title;
  final int? group;
  final int sortOrder;

  /// Position auf der Karte, jeweils 0 bis 1 (y: 0 oben, 1 unten).
  final double mapX;
  final double mapY;
  final String routeType;

  /// `false` = Insel liegt im Nebel (Inhalte noch nicht veröffentlicht).
  final bool hasContent;

  /// free oder premium (Abo-Rechte, CLAUDE.md Abschnitt 8).
  final String access;

  bool get isMainRoute => routeType == 'main';
  bool get isPremium => access == 'premium';
}

/// Eine Zeile Dialog von Talo, Tala oder einer anderen Figur.
class DialogLine {
  const DialogLine({required this.speaker, required this.text, this.name, this.image});

  factory DialogLine.fromJson(Map<String, dynamic> json) => DialogLine(
    speaker: json['speaker'] as String? ?? 'talo',
    text: json['text'] as String? ?? '',
    name: json['name'] as String?,
    image: json['image'] as String?,
  );

  /// Figur, passend zum Asset-Schlüssel `character.<speaker>`.
  final String speaker;
  final String text;

  /// Angezeigter Name, wenn es nicht Talo oder Tala ist.
  final String? name;

  /// Bild der Bildergeschichte (Asset-Schlüssel), nur in der Erklärung.
  /// Zeilen ohne Bild zeigen das Bild davor.
  final String? image;
}

/// Auftrag fürs echte Leben zu einer Insel.
class RealLifeTask {
  const RealLifeTask({required this.title, required this.text});

  final String title;
  final String text;
}

/// Kombüsen-Frage: Gesprächsidee für die Familie zu einer Insel.
class ConversationPrompt {
  const ConversationPrompt({required this.id, required this.islandId, required this.text});

  final String id;
  final String islandId;
  final String text;
}

class IslandDetails {
  const IslandDetails({
    required this.id,
    required this.slug,
    required this.title,
    this.goal,
    this.learn = const [],
    this.arrivalVideoKey,
    this.arrivalScene = const [],
    this.badge,
    this.realLifeTask,
    this.teaser = const [],
    this.nextSlug,
    this.nextTitle,
    this.explain = const [],
    this.explainAsk,
  });

  factory IslandDetails.fromRow(Map<String, dynamic> row) {
    final content = (row['content'] as Map<String, dynamic>?) ?? const {};
    final arrival = content['arrival'] as Map<String, dynamic>?;
    final task = content['real_life_task'] as Map<String, dynamic>?;
    final teaser = content['teaser'] as Map<String, dynamic>?;
    final together = content['together'] as Map<String, dynamic>?;
    return IslandDetails(
      id: row['id'] as String,
      slug: row['slug'] as String,
      title: row['title'] as String,
      goal: content['goal'] as String?,
      learn: [for (final l in (content['learn'] as List?) ?? const []) l as String],
      arrivalVideoKey: arrival?['video_key'] as String?,
      arrivalScene: [
        for (final l in (arrival?['scene'] as List?) ?? const []) DialogLine.fromJson(l as Map<String, dynamic>),
      ],
      badge: content['badge'] as String?,
      realLifeTask: task == null
          ? null
          : RealLifeTask(title: task['title'] as String? ?? '', text: task['text'] as String? ?? ''),
      teaser: [for (final l in (teaser?['scene'] as List?) ?? const []) DialogLine.fromJson(l as Map<String, dynamic>)],
      nextSlug: teaser?['next_slug'] as String?,
      nextTitle: teaser?['next_title'] as String?,
      explain: [for (final p in (together?['explain'] as List?) ?? const []) p as String],
      explainAsk: together?['ask'] as String?,
    );
  }

  /// „Erklär's deinen Eltern“: 3 Punkte, die das Kind nach der Insel erklärt.
  final List<String> explain;

  /// Nachfrage für die Eltern dazu.
  final String? explainAsk;

  /// Ausblick auf die nächste Insel nach dem Abschluss (macht neugierig aufs Weitersegeln).
  final List<DialogLine> teaser;
  final String? nextSlug;
  final String? nextTitle;

  final String id;
  final String slug;
  final String title;
  final String? goal;

  /// „Das lernst du hier“: kurze Punkte in Kindersprache ([goal] ist für Eltern).
  final List<String> learn;
  final String? arrivalVideoKey;
  final List<DialogLine> arrivalScene;

  /// Name des Ordens für diese Insel.
  final String? badge;

  /// Auftrag fürs echte Leben (Eltern bestätigen, INSELN.md).
  final RealLifeTask? realLifeTask;

  bool get hasArrival => arrivalScene.isNotEmpty || arrivalVideoKey != null;
}

enum StationType { video, quiz, game, practice, reviewStop, exam, seaStop }

class ExamRules {
  const ExamRules({required this.show, required this.review, required this.pass});

  /// Fragen aus der eigenen Prüfung.
  final int show;

  /// Rückblick-Fragen aus Prüfungen früherer Inseln.
  final int review;

  /// Bestanden ab so vielen richtigen Antworten.
  final int pass;
}

/// Ein Ding in einem Mini-Spiel (Sortieren oder Reihenfolge).
class GameItem {
  const GameItem({required this.text, this.basket, this.hint, this.price, this.required = false});

  final String text;

  /// Sortieren: richtiger Korb; `null` = passt in jeden Korb (dazwischen).
  final int? basket;
  final String? hint;

  /// Auswählen: Preis in Talern und ob das Ding dazugehört.
  final int? price;
  final bool required;
}

/// Eine Möglichkeit im Entscheidungs-Spiel mit der Rückmeldung darauf.
class GameOption {
  const GameOption({required this.text, required this.good, required this.reply});

  final String text;

  /// Gute Wahl? Mehrere Möglichkeiten dürfen gut sein (dann zeigt die Rückmeldung den Verzicht).
  final bool good;
  final String reply;
}

/// Eine Runde: Entscheidung (Szene, Frage, Möglichkeiten), Betrag legen oder Rechenaufgabe.
class GameRound {
  const GameRound({
    required this.question,
    this.scene = const [],
    this.options = const [],
    this.amount,
    this.unit,
    this.hint,
    this.explanation,
  });

  factory GameRound.fromJson(Map<String, dynamic> json) => GameRound(
    question: json['question'] as String? ?? '',
    scene: [for (final l in (json['scene'] as List?) ?? const []) DialogLine.fromJson(l as Map<String, dynamic>)],
    options: [
      for (final o in (json['options'] as List?) ?? const [])
        GameOption(
          text: (o as Map<String, dynamic>)['text'] as String? ?? '',
          good: o['good'] as bool? ?? false,
          reply: o['reply'] as String? ?? '',
        ),
    ],
    amount: (json['amount'] as num?)?.toInt(),
    unit: json['unit'] as String?,
    hint: json['hint'] as String?,
    explanation: json['explanation'] as String?,
  );

  final String question;
  final List<DialogLine> scene;
  final List<GameOption> options;

  /// Münzen legen: Betrag in Cent. Rechnen: die richtige Zahl.
  final int? amount;
  final String? unit;
  final String? hint;
  final String? explanation;
}

/// Kunde an der Kasse: kauft etwas für [price] und bezahlt mit [paid] (beides
/// in Cent). Das Kind gibt das Wechselgeld heraus.
class TillCustomer {
  const TillCustomer({required this.figure, required this.text, required this.price, required this.paid, this.name});

  factory TillCustomer.fromJson(Map<String, dynamic> json) => TillCustomer(
    figure: json['figure'] as String? ?? 'talo',
    name: json['name'] as String?,
    text: json['text'] as String? ?? '',
    price: (json['price'] as num?)?.toInt() ?? 0,
    paid: (json['paid'] as num?)?.toInt() ?? 0,
  );

  /// Figur (Asset-Schlüssel `character.<figure>`).
  final String figure;
  final String? name;
  final String text;
  final int price;
  final int paid;

  int get change => paid - price;
}

/// Markt-Einkauf: ein Ding auf der Einkaufsliste, [count] Stück.
class MarketNeed {
  const MarketNeed({required this.item, this.count = 1});

  final String item;
  final int count;
}

/// Angebot an einem Marktstand: Preis pro Stück in Cent.
class MarketOffer {
  const MarketOffer({required this.item, required this.price});

  final String item;
  final int price;
}

/// Marktstand mit Figur und Angeboten.
class MarketStand {
  const MarketStand({required this.figure, required this.name, required this.offers, this.image});

  factory MarketStand.fromJson(Map<String, dynamic> json) => MarketStand(
    figure: json['figure'] as String? ?? 'talo',
    name: json['name'] as String? ?? '',
    image: json['image'] as String?,
    offers: [
      for (final o in (json['offers'] as List?) ?? const [])
        MarketOffer(
          item: (o as Map<String, dynamic>)['item'] as String? ?? '',
          price: (o['price'] as num?)?.toInt() ?? 0,
        ),
    ],
  );

  final String figure;
  final String name;
  final List<MarketOffer> offers;

  /// Bild des Stands (Asset-Schlüssel), sonst der Kopf der Figur.
  final String? image;
}

/// Ein Tag am Eisstand. Zum Preis p (in Talern) kommen
/// `max(0, demand - drop * p)` Kunden; verkauft wird höchstens [stock].
class IceDay {
  const IceDay({
    required this.weather,
    required this.stock,
    required this.demand,
    required this.drop,
    this.scene = const [],
    this.image,
  });

  factory IceDay.fromJson(Map<String, dynamic> json) => IceDay(
    weather: json['weather'] as String? ?? 'sun',
    scene: [for (final l in (json['scene'] as List?) ?? const []) DialogLine.fromJson(l as Map<String, dynamic>)],
    image: json['image'] as String?,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    demand: (json['demand'] as num?)?.toInt() ?? 0,
    drop: (json['drop'] as num?)?.toInt() ?? 0,
  );

  /// sun, clouds oder rain.
  final String weather;
  final List<DialogLine> scene;

  /// Bild des Tages (Asset-Schlüssel), sonst nur das Wetter.
  final String? image;
  final int stock;
  final int demand;
  final int drop;
}

/// Händler in der Tauschkette: gibt [has] nur gegen [wants].
class Trader {
  const Trader({required this.figure, required this.name, required this.has, required this.wants});

  factory Trader.fromJson(Map<String, dynamic> json) => Trader(
    figure: json['figure'] as String? ?? 'talo',
    name: json['name'] as String? ?? '',
    has: json['has'] as String? ?? '',
    wants: json['wants'] as String? ?? '',
  );

  final String figure;
  final String name;
  final String has;
  final String wants;
}

/// Rucksack packen: Was auf einem Ausflug fehlt, und was dann passiert.
class BackpackNeed {
  const BackpackNeed({required this.item, required this.missing});

  factory BackpackNeed.fromJson(Map<String, dynamic> json) =>
      BackpackNeed(item: json['item'] as String? ?? '', missing: json['missing'] as String? ?? '');

  final String item;

  /// Was passiert, wenn das Ding fehlt („Ohne Regenjacke wird Tala nass.“).
  final String missing;
}

/// Ein Ausflug im Spiel „Rucksack packen“ mit Taler-Budget.
class BackpackTrip {
  const BackpackTrip({
    required this.title,
    required this.budget,
    required this.needs,
    this.scene = const [],
    this.image,
  });

  factory BackpackTrip.fromJson(Map<String, dynamic> json) => BackpackTrip(
    title: json['title'] as String? ?? '',
    scene: [for (final l in (json['scene'] as List?) ?? const []) DialogLine.fromJson(l as Map<String, dynamic>)],
    image: json['image'] as String?,
    budget: (json['budget'] as num?)?.toInt() ?? 0,
    needs: [for (final n in (json['needs'] as List?) ?? const []) BackpackNeed.fromJson(n as Map<String, dynamic>)],
  );

  final String title;
  final List<DialogLine> scene;

  /// Bild des Ausflugs (Asset-Schlüssel), sonst ein Symbol.
  final String? image;

  /// Taler für diesen Ausflug.
  final int budget;

  /// Was Tala auf diesem Ausflug wirklich braucht.
  final List<BackpackNeed> needs;
}

/// Ein Tag in Mias Kiosk-Woche: Angebot am Kiosk oder etwas, das sein muss.
class KioskDay {
  const KioskDay({
    required this.day,
    required this.item,
    required this.price,
    this.must = false,
    this.scene = const [],
  });

  factory KioskDay.fromJson(Map<String, dynamic> json) => KioskDay(
    day: json['day'] as String? ?? '',
    item: json['item'] as String? ?? '',
    price: (json['price'] as num?)?.toInt() ?? 0,
    must: json['must'] as bool? ?? false,
    scene: [for (final l in (json['scene'] as List?) ?? const []) DialogLine.fromJson(l as Map<String, dynamic>)],
  );

  final String day;
  final String item;

  /// Preis in Talern.
  final int price;

  /// Muss bezahlt werden (zum Beispiel die Busfahrt), kein Wunsch.
  final bool must;
  final List<DialogLine> scene;
}

/// Ein Kassenzettel in Kurts Logbuch.
class LogbookEntry {
  const LogbookEntry({required this.text, required this.amount, required this.income, required this.group});

  factory LogbookEntry.fromJson(Map<String, dynamic> json) => LogbookEntry(
    text: json['text'] as String? ?? '',
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    income: json['kind'] == 'in',
    group: json['group'] as String? ?? '',
  );

  final String text;

  /// Betrag in Talern.
  final int amount;

  /// Einnahme (sonst Ausgabe).
  final bool income;

  /// Wofür (bei Ausgaben), zum Beispiel „Süßes“.
  final String group;
}

/// Emmas Wintervorrat: Herbsttage, an denen Emma wählt, ob sie gleich isst
/// oder Nüsse für den Winter vergräbt.
class WinterStoreSpec {
  const WinterStoreSpec({
    required this.days,
    required this.now,
    required this.later,
    required this.need,
    this.knock,
    this.share,
    this.keep,
    this.hungry,
  });

  factory WinterStoreSpec.fromJson(Map<String, dynamic> json) {
    DialogLine? line(Object? raw) => raw is Map<String, dynamic> ? DialogLine.fromJson(raw) : null;
    return WinterStoreSpec(
      days: [
        for (final d in (json['days'] as List?) ?? const [])
          [
            for (final l in ((d as Map<String, dynamic>)['scene'] as List?) ?? const [])
              DialogLine.fromJson(l as Map<String, dynamic>),
          ],
      ],
      now: (json['now'] as num?)?.toInt() ?? 1,
      later: (json['later'] as num?)?.toInt() ?? 3,
      need: (json['need'] as num?)?.toInt() ?? 0,
      knock: line(json['knock']),
      share: line(json['share']),
      keep: line(json['keep']),
      hungry: line(json['hungry']),
    );
  }

  /// Ein Eintrag pro Herbsttag: was an diesem Tag gesagt wird.
  final List<List<DialogLine>> days;

  /// Nüsse, die Emma isst, wenn sie nicht wartet.
  final int now;

  /// Nüsse, die in den Vorrat kommen, wenn sie wartet.
  final int later;

  /// So viele Nüsse braucht Emma für den Winter.
  final int need;

  /// Gustav klopft hungrig an; Antwort beim Teilen und beim Behalten.
  final DialogLine? knock;
  final DialogLine? share;
  final DialogLine? keep;

  /// Der Vorrat reicht nicht.
  final DialogLine? hungry;
}

/// Ereignis in einer Woche des Sparschwein-Spiels.
class PiggyEvent {
  const PiggyEvent({required this.gift, required this.line, required this.item, required this.price});

  factory PiggyEvent.fromJson(Map<String, dynamic> json) => PiggyEvent(
    gift: json['kind'] == 'gift',
    line: DialogLine.fromJson(json),
    item: json['item'] as String? ?? '',
    price: (json['price'] as num?)?.toInt() ?? 0,
  );

  /// Geschenk (Taler dazu) oder Versuchung (etwas zum Kaufen).
  final bool gift;
  final DialogLine line;
  final String item;
  final int price;
}

/// Sparschwein füttern: Plan wählen, Woche für Woche füttern, Versuchungen.
class PiggyBankSpec {
  const PiggyBankSpec({
    required this.goal,
    required this.goalPrice,
    required this.income,
    required this.plans,
    required this.weeks,
  });

  factory PiggyBankSpec.fromJson(Map<String, dynamic> json) => PiggyBankSpec(
    goal: json['goal'] as String? ?? '',
    goalPrice: (json['goal_price'] as num?)?.toInt() ?? 0,
    income: (json['income'] as num?)?.toInt() ?? 0,
    plans: [for (final p in (json['plans'] as List?) ?? const []) (p as num).toInt()],
    weeks: [
      for (final w in (json['weeks'] as List?) ?? const [])
        PiggyWeek(
          scene: [
            for (final l in ((w as Map<String, dynamic>)['scene'] as List?) ?? const [])
              DialogLine.fromJson(l as Map<String, dynamic>),
          ],
          event: w['event'] is Map<String, dynamic> ? PiggyEvent.fromJson(w['event'] as Map<String, dynamic>) : null,
        ),
    ],
  );

  /// Wunschschatz und sein Preis in Talern.
  final String goal;
  final int goalPrice;

  /// Taschengeld pro Woche in Talern.
  final int income;

  /// Mögliche Sparbeträge pro Woche.
  final List<int> plans;
  final List<PiggyWeek> weeks;
}

class PiggyWeek {
  const PiggyWeek({this.scene = const [], this.event});

  final List<DialogLine> scene;
  final PiggyEvent? event;
}

/// Verkaufstricks im Glitzerladen. Die Namen stehen in den Übersetzungen.
const shopTricks = ['hurry', 'everyone', 'fake_sale', 'free_extra', 'sparkle'];

/// Ein Angebot im Glitzerladen: Elsa preist ein Ding mit einem Trick an.
class ShopOffer {
  const ShopOffer({
    required this.item,
    required this.pitch,
    required this.trick,
    required this.price,
    required this.needed,
    required this.reveal,
  });

  factory ShopOffer.fromJson(Map<String, dynamic> json) => ShopOffer(
    item: json['item'] as String? ?? '',
    pitch: DialogLine.fromJson({'speaker': 'elsa', ...json}),
    trick: json['trick'] as String? ?? '',
    price: (json['price'] as num?)?.toInt() ?? 0,
    needed: json['needed'] as bool? ?? false,
    reveal: json['reveal'] as String? ?? '',
  );

  final String item;

  /// Was Elsa sagt.
  final DialogLine pitch;

  /// Einer aus [shopTricks].
  final String trick;
  final int price;

  /// Steht auf Talas Liste?
  final bool needed;

  /// Was hinter dem Trick steckt.
  final String reveal;
}

class GameInfo {
  const GameInfo({
    required this.type,
    required this.title,
    this.description,
    this.task,
    this.items = const [],
    this.baskets = const [],
    this.from,
    this.to,
    this.done,
    this.rounds = const [],
    this.target,
    this.exactTarget = false,
    this.customers = const [],
    this.budget,
    this.needs = const [],
    this.stands = const [],
    this.days = const [],
    this.priceMin = 1,
    this.priceMax = 8,
    this.start,
    this.goal,
    this.traders = const [],
    this.deadEnd,
    this.trips = const [],
    this.winter,
    this.piggy,
    this.offers = const [],
    this.kioskDays = const [],
    this.broke,
    this.logStart = 0,
    this.logEntries = const [],
    this.beginner,
    this.wholeNumbers = false,
    this.image,
    this.images = const {},
  });

  factory GameInfo.fromJson(Map<String, dynamic> game, {bool wholeNumbers = false}) => GameInfo(
    wholeNumbers: wholeNumbers,
    image: game['image'] as String?,
    images: {
      for (final e in ((game['images'] as Map<String, dynamic>?) ?? const {}).entries)
        if (e.value is String) e.key: e.value as String,
    },
    beginner: game['beginner'] is Map<String, dynamic>
        ? GameInfo.fromJson(game['beginner'] as Map<String, dynamic>, wholeNumbers: true)
        : null,
    type: game['type'] as String? ?? '',
    title: game['title'] as String? ?? '',
    description: game['description'] as String?,
    task: game['task'] as String?,
    items: [
      for (final i in (game['items'] as List?) ?? const [])
        GameItem(
          text: (i as Map<String, dynamic>)['text'] as String? ?? '',
          basket: i['basket'] as int?,
          hint: i['hint'] as String?,
          price: (i['price'] as num?)?.toInt(),
          required: i['required'] as bool? ?? false,
        ),
    ],
    rounds: [for (final r in (game['rounds'] as List?) ?? const []) GameRound.fromJson(r as Map<String, dynamic>)],
    target: (game['target'] as num?)?.toInt(),
    exactTarget: game['exact'] as bool? ?? false,
    baskets: [for (final b in (game['baskets'] as List?) ?? const []) b as String],
    from: game['from'] as String?,
    to: game['to'] as String?,
    done: game['done'] is Map<String, dynamic> ? DialogLine.fromJson(game['done'] as Map<String, dynamic>) : null,
    customers: [
      for (final c in (game['customers'] as List?) ?? const []) TillCustomer.fromJson(c as Map<String, dynamic>),
    ],
    budget: (game['budget'] as num?)?.toInt(),
    needs: [
      for (final n in (game['needs'] as List?) ?? const [])
        MarketNeed(
          item: (n as Map<String, dynamic>)['item'] as String? ?? '',
          count: (n['count'] as num?)?.toInt() ?? 1,
        ),
    ],
    stands: [for (final s in (game['stands'] as List?) ?? const []) MarketStand.fromJson(s as Map<String, dynamic>)],
    days: [for (final d in (game['days'] as List?) ?? const []) IceDay.fromJson(d as Map<String, dynamic>)],
    priceMin: (game['price_min'] as num?)?.toInt() ?? 1,
    priceMax: (game['price_max'] as num?)?.toInt() ?? 8,
    start: game['start'] as String?,
    goal: game['goal'] as String?,
    traders: [for (final t in (game['traders'] as List?) ?? const []) Trader.fromJson(t as Map<String, dynamic>)],
    deadEnd: game['dead_end'] is Map<String, dynamic>
        ? DialogLine.fromJson(game['dead_end'] as Map<String, dynamic>)
        : null,
    trips: [for (final t in (game['trips'] as List?) ?? const []) BackpackTrip.fromJson(t as Map<String, dynamic>)],
    winter: game['type'] == 'winter_store' ? WinterStoreSpec.fromJson(game) : null,
    piggy: game['type'] == 'piggy_bank' ? PiggyBankSpec.fromJson(game) : null,
    offers: [for (final o in (game['offers'] as List?) ?? const []) ShopOffer.fromJson(o as Map<String, dynamic>)],
    kioskDays: [
      for (final d in (game['kiosk_days'] as List?) ?? const []) KioskDay.fromJson(d as Map<String, dynamic>),
    ],
    broke: game['broke'] is Map<String, dynamic> ? DialogLine.fromJson(game['broke'] as Map<String, dynamic>) : null,
    logStart: (game['log_start'] as num?)?.toInt() ?? 0,
    logEntries: [
      for (final e in (game['log_entries'] as List?) ?? const []) LogbookEntry.fromJson(e as Map<String, dynamic>),
    ],
  );

  /// Echte Mini-Spiele mit eigener Spielwelt (Startbild, Sterne, auf der
  /// Startseite nochmal spielbar). Die anderen Spielarten sind Übungen.
  static const realGames = {
    'till',
    'market',
    'ice_stand',
    'trade_chain',
    'backpack',
    'winter_store',
    'piggy_bank',
    'glitter_shop',
    'kiosk_week',
    'logbook',
  };

  /// sort, order, choice, coins, pick, number, wish_bottle, die echten Spiele
  /// till, market, ice_stand, trade_chain, backpack, winter_store, piggy_bank,
  /// glitter_shop oder eine Spielart, die
  /// erst später gebaut wird (Platzhalter).
  final String type;
  final String title;
  final String? description;
  final String? task;
  final List<GameItem> items;
  final List<String> baskets;
  final String? from;
  final String? to;
  final DialogLine? done;

  /// Entscheidungen, Beträge oder Rechenaufgaben.
  final List<GameRound> rounds;

  /// Auswählen: Zielbetrag in Talern, genau ([exactTarget]) oder höchstens (Budget).
  final int? target;
  final bool exactTarget;

  /// Kasse: Kunden der Reihe nach; [items] ist die Preistafel (Preise in Cent).
  final List<TillCustomer> customers;

  /// Markt-Einkauf: Geld in Cent, Einkaufsliste und Stände.
  final int? budget;
  final List<MarketNeed> needs;
  final List<MarketStand> stands;

  /// Eisstand: Tage und erlaubte Preise in Talern.
  final List<IceDay> days;
  final int priceMin;
  final int priceMax;

  /// Tauschkette: Tala hat [start] und will [goal]; [deadEnd] sagt, wenn es nicht weitergeht.
  final String? start;
  final String? goal;
  final List<Trader> traders;
  final DialogLine? deadEnd;

  /// Rucksack packen: Ausflüge; [items] sind die Dinge im Packhaus (Preise in Talern).
  final List<BackpackTrip> trips;

  /// Emmas Wintervorrat (`winter_store`).
  final WinterStoreSpec? winter;

  /// Sparschwein füttern (`piggy_bank`).
  final PiggyBankSpec? piggy;

  /// Glitzerladen (`glitter_shop`): Angebote mit Verkaufstricks; [budget] in Talern.
  final List<ShopOffer> offers;

  /// Mias Kiosk-Woche (`kiosk_week`): Tage am Kiosk, [budget] in Talern für die Woche;
  /// [broke] sagt Mia, wenn das Geld für etwas Nötiges nicht mehr reicht.
  final List<KioskDay> kioskDays;
  final DialogLine? broke;

  /// Kurts Logbuch (`logbook`): Taler am Anfang und Kassenzettel der Reihe nach.
  final int logStart;
  final List<LogbookEntry> logEntries;

  /// Fassung mit ganzen Zahlen für Einsteiger, falls das Spiel Kommazahlen hat.
  final GameInfo? beginner;

  /// Beträge ohne Komma anzeigen (Einsteiger): „3 €“, „80 ct“.
  final bool wholeNumbers;

  /// Startbild des Mini-Spiels (Asset-Schlüssel).
  final String? image;

  /// Bilder der Dinge im Spiel: Name (zum Beispiel „Eimer“) → Asset-Schlüssel.
  final Map<String, String> images;

  /// Das Spiel für ein Kind: Einsteiger bekommen die Fassung mit ganzen Zahlen.
  GameInfo forLevel(LevelSetting level) => level == LevelSetting.beginner && beginner != null ? beginner! : this;

  /// Echtes Mini-Spiel (nicht nur eine Übung)?
  bool get isRealGame => realGames.contains(type);

  /// Hat die App für diese Spielart schon eine Spielmechanik?
  bool get isPlayable => switch (type) {
    'sort' => baskets.length >= 2 && items.isNotEmpty,
    'order' => items.length >= 2,
    'choice' => rounds.isNotEmpty && rounds.every((r) => r.options.any((o) => o.good)),
    'coins' => rounds.isNotEmpty && rounds.every((r) => (r.amount ?? 0) > 0),
    'pick' => items.isNotEmpty && target != null && items.every((i) => i.price != null),
    'number' => rounds.isNotEmpty && rounds.every((r) => r.amount != null),
    'wish_bottle' => true,
    'till' => customers.isNotEmpty && customers.every((c) => c.change > 0),
    'market' => budget != null && needs.isNotEmpty && stands.isNotEmpty,
    'ice_stand' => days.isNotEmpty && priceMin >= 1 && priceMax > priceMin,
    'trade_chain' => start != null && goal != null && traders.isNotEmpty,
    'backpack' => trips.isNotEmpty && items.isNotEmpty && items.every((i) => i.price != null),
    'winter_store' => (winter?.days.isNotEmpty ?? false) && winter!.need > 0,
    'piggy_bank' => (piggy?.weeks.isNotEmpty ?? false) && piggy!.plans.isNotEmpty && piggy!.goalPrice > 0,
    'glitter_shop' => budget != null && offers.isNotEmpty && offers.every((o) => shopTricks.contains(o.trick)),
    'kiosk_week' => budget != null && kioskDays.isNotEmpty,
    'logbook' => logEntries.isNotEmpty,
    _ => false,
  };
}

/// Aufgabe im Wrack: eine Frage mit drei Antworten, ohne Punkte.
class WreckTask {
  const WreckTask({
    required this.question,
    required this.answers,
    required this.correctIndex,
    this.scene = const [],
    this.explanation,
    this.beginner,
  });

  factory WreckTask.fromJson(Map<String, dynamic> wreck) => WreckTask(
    scene: [for (final l in (wreck['scene'] as List?) ?? const []) DialogLine.fromJson(l as Map<String, dynamic>)],
    question: wreck['question'] as String? ?? '',
    answers: [for (final a in (wreck['answers'] as List?) ?? const []) a as String],
    correctIndex: wreck['correct_index'] as int? ?? 0,
    explanation: wreck['explanation'] as String?,
    beginner: wreck['beginner'] is Map<String, dynamic>
        ? WreckTask.fromJson(wreck['beginner'] as Map<String, dynamic>)
        : null,
  );

  /// Fassung mit ganzen Zahlen für Einsteiger.
  final WreckTask? beginner;

  WreckTask forLevel(LevelSetting level) => level == LevelSetting.beginner && beginner != null ? beginner! : this;

  final List<DialogLine> scene;
  final String question;
  final List<String> answers;
  final int correctIndex;
  final String? explanation;

  /// Als Quizfrage, damit dieselbe Mechanik wie bei Begegnungen greift.
  QuizQuestion asQuestion(String stationId) => QuizQuestion(
    id: '$stationId/wreck',
    stationId: stationId,
    question: question,
    answers: answers,
    correctIndex: correctIndex,
    explanation: explanation,
  );
}

/// Tauchgang an einem Ankerplatz (CLAUDE.md Abschnitt 8).
class DiveInfo {
  const DiveInfo({required this.game, required this.questions, this.wreck});

  /// pearls, treasure_chest, fish_swarm oder shell_count. Gebaut ist pearls,
  /// die anderen zeigen bis zu ihrem Bau das Perlentauchen.
  final String game;
  final int questions;
  final WreckTask? wreck;
}

/// Stopp auf See (stations.content.stop): welche Art, welche Figur auf der
/// Karte zu sehen ist und der wievielte Stopp vor der Insel.
class SeaStopInfo {
  const SeaStopInfo({required this.type, required this.figure, required this.index, this.ship});

  /// haendlerschiff, fischerboot, angeberschiff oder tala_vergisst.
  final String type;

  /// Figur (Asset-Schlüssel `character.<figure>`).
  final String figure;
  final int index;

  /// Schiff der Figur (Asset-Schlüssel `ship.…`): auf der Karte statt des
  /// Kopfes und im Stopp oben auf dem Meer. `null`: nur die Figur.
  final String? ship;
}

/// Inhalt einer Station (stations.content).
/// Schätzfrage vor der Erklärung (INSELN.md, Aufbau jeder Station): Das Kind
/// schätzt mit Schieberegler, Zahlenrad oder Auswahl. Es gibt kein Richtig
/// oder Falsch; aufgelöst wird am Ende der Erklärung ([reveal]).
class EstimateQuestion {
  const EstimateQuestion({
    required this.speaker,
    required this.question,
    required this.kind,
    required this.reveal,
    this.min = 0,
    this.max = 10,
    this.step = 1,
    this.start,
    this.unit,
    this.unitOne,
    this.options = const [],
    this.answer,
  });

  factory EstimateQuestion.fromJson(Map<String, dynamic> json) => EstimateQuestion(
    speaker: json['speaker'] as String? ?? 'talo',
    question: json['question'] as String? ?? '',
    kind: json['kind'] as String? ?? 'slider',
    reveal: DialogLine.fromJson((json['reveal'] as Map<String, dynamic>?) ?? const {}),
    min: (json['min'] as num?)?.toInt() ?? 0,
    max: (json['max'] as num?)?.toInt() ?? 10,
    step: (json['step'] as num?)?.toInt() ?? 1,
    start: (json['start'] as num?)?.toInt(),
    unit: json['unit'] as String?,
    unitOne: json['unit_one'] as String?,
    options: [for (final o in (json['options'] as List?) ?? const []) o as String],
    answer: (json['answer'] as num?)?.toInt(),
  );

  /// Wer fragt (Talo, Tala oder eine Inselfigur).
  final String speaker;
  final String question;

  /// slider (Schieberegler), wheel (Zahlenrad) oder choice (Auswahl).
  final String kind;

  /// Auflösung am Ende der Erklärung.
  final DialogLine reveal;
  final int min;
  final int max;
  final int step;

  /// Startwert von Regler und Zahlenrad (sonst die Mitte).
  final int? start;

  /// Einheit hinter der Zahl, zum Beispiel „Jahre“; [unitOne] für genau 1 („Jahr“).
  final String? unit;
  final String? unitOne;

  /// Möglichkeiten bei der Auswahl.
  final List<String> options;

  /// Lösung: Zahl oder Stelle in [options]; `null` bei einer eigenen Schätzung ohne feste Lösung.
  final int? answer;

  bool get isChoice => kind == 'choice';

  /// Alle Werte von Regler und Zahlenrad.
  List<int> get values => [for (var v = min; v <= max; v += step) v];

  /// Startwert: [start] oder der Wert in der Mitte.
  int get initial {
    if (isChoice) return -1;
    final all = values;
    final wanted = start ?? all[all.length ~/ 2];
    return all.reduce((a, b) => (a - wanted).abs() <= (b - wanted).abs() ? a : b);
  }

  /// So wird eine Schätzung angezeigt: „2.600 Jahre“, „1 Jahr“ oder die gewählte Möglichkeit.
  String display(int value) {
    if (isChoice) return value >= 0 && value < options.length ? options[value] : '';
    final number = groupThousands(value);
    final u = value == 1 && unitOne != null ? unitOne : unit;
    return u == null ? number : '$number $u';
  }

  /// Die Schätzung trifft die Lösung genau.
  bool isExact(int value) => answer != null && value == answer;
}

/// Zahl mit Punkt als Tausender-Trennzeichen, zum Beispiel 2.600.
String groupThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Antipp-Moment zwischen zwei Bildern der Erklärung (INSELN.md): eine kleine
/// Aktion, die zum Inhalt passt. Keine Prüfung, es geht immer weiter.
class TapMoment {
  const TapMoment({
    required this.after,
    required this.kind,
    required this.text,
    this.symbol,
    this.image,
    this.count = 1,
    this.back,
    this.done,
  });

  factory TapMoment.fromJson(Map<String, dynamic> json) => TapMoment(
    after: (json['after'] as num?)?.toInt() ?? 1,
    kind: json['kind'] as String? ?? 'tap',
    text: json['text'] as String? ?? '',
    symbol: json['symbol'] as String?,
    image: json['image'] as String?,
    count: (json['count'] as num?)?.toInt() ?? 1,
    back: json['back'] as String?,
    done: json['done'] as String?,
  );

  /// Nach dem wievielten Bild der Erklärung (1 = nach dem ersten).
  final int after;

  /// tap (antippen), swipe (wischen), drag (ziehen) oder flip (umdrehen).
  final String kind;

  /// Was das Kind tun soll, zum Beispiel „Wisch den Staub von der Kiste.“
  final String text;

  /// Zeichen aus einer festen Liste (zum Beispiel `coin`), sonst [image].
  final String? symbol;

  /// Bild eines Dings (Asset-Schlüssel), statt eines Zeichens.
  final String? image;

  /// Wie oft angetippt wird (zum Beispiel dreimal mit dem Hammer).
  final int count;

  /// Beim Umdrehen: was auf der Rückseite steht.
  final String? back;

  /// Was nach der Aktion zu sehen ist, zum Beispiel „Darunter liegen Muscheln.“
  final String? done;
}

class StationContent {
  const StationContent({
    required this.title,
    this.place,
    this.goal,
    this.minutes,
    this.isOnboarding = false,
    this.videoKey,
    this.scene = const [],
    this.lesson = const [],
    this.game,
    this.miniGame,
    this.summary,
    this.quizShow,
    this.exam,
    this.number,
    this.dive,
    this.seaStop,
    this.estimate,
    this.taps = const [],
  });

  factory StationContent.fromJson(Map<String, dynamic> json) {
    List<DialogLine> lines(Object? raw) => [
      for (final l in (raw as List?) ?? const []) DialogLine.fromJson(l as Map<String, dynamic>),
    ];
    final game = json['game'] as Map<String, dynamic>?;
    final miniGame = json['mini_game'] as Map<String, dynamic>?;
    final exam = json['exam'] as Map<String, dynamic>?;
    final summary = json['summary'] as Map<String, dynamic>?;
    final dive = json['dive'] as Map<String, dynamic>?;
    final wreck = dive?['wreck'] as Map<String, dynamic>?;
    final stop = json['stop'] as Map<String, dynamic>?;
    final estimate = json['estimate'] as Map<String, dynamic>?;
    return StationContent(
      estimate: estimate == null ? null : EstimateQuestion.fromJson(estimate),
      taps: [for (final t in (json['taps'] as List?) ?? const []) TapMoment.fromJson(t as Map<String, dynamic>)],
      seaStop: stop == null
          ? null
          : SeaStopInfo(
              type: stop['type'] as String? ?? 'haendlerschiff',
              figure: stop['figure'] as String? ?? 'talo',
              index: stop['index'] as int? ?? 1,
              ship: stop['ship'] as String?,
            ),
      title: json['title'] as String? ?? '',
      place: json['place'] as String?,
      goal: json['goal'] as String?,
      minutes: json['minutes'] as String?,
      isOnboarding: json['kind'] == 'onboarding',
      videoKey: json['video_key'] as String?,
      scene: lines(json['scene']),
      lesson: lines(json['lesson']),
      game: game == null ? null : GameInfo.fromJson(game),
      miniGame: miniGame == null ? null : GameInfo.fromJson(miniGame),
      summary: summary == null ? null : DialogLine.fromJson(summary),
      quizShow: (json['quiz'] as Map<String, dynamic>?)?['show'] as int?,
      exam: exam == null
          ? null
          : ExamRules(
              show: exam['show'] as int? ?? 10,
              review: exam['review'] as int? ?? 0,
              pass: exam['pass'] as int? ?? 8,
            ),
      number: json['number'] as int?,
      dive: dive == null
          ? null
          : DiveInfo(
              game: dive['game'] as String? ?? 'pearls',
              questions: dive['questions'] as int? ?? 4,
              wreck: wreck == null ? null : WreckTask.fromJson(wreck),
            ),
    );
  }

  final String title;
  final String? place;
  final String? goal;
  final String? minutes;
  final bool isOnboarding;
  final String? videoKey;
  final List<DialogLine> scene;
  final List<DialogLine> lesson;

  /// Die Erklärung ist eine Bildergeschichte (mindestens eine Zeile hat ein Bild).
  bool get hasPictureStory => lesson.any((l) => l.image != null);

  /// Schätzfrage vor der Erklärung (`null` = keine).
  final EstimateQuestion? estimate;

  /// Antipp-Momente zwischen den Bildern der Erklärung.
  final List<TapMoment> taps;

  /// Übung der Station (Pflicht).
  final GameInfo? game;

  /// Echtes Mini-Spiel als Bonus nach der Station (kein Muss, siehe [GameInfo.isRealGame]).
  final GameInfo? miniGame;

  /// Station mit spielbarem Mini-Spiel (Spiel-Zeichen auf der Insel).
  bool get hasMiniGame => miniGame != null && miniGame!.isRealGame && miniGame!.isPlayable;
  final DialogLine? summary;
  final int? quizShow;
  final ExamRules? exam;

  /// Angezeigte Nummer (Station 3 oder Ankerplatz 2).
  final int? number;

  /// Nur bei Ankerplätzen.
  final DiveInfo? dive;

  /// Nur bei Stopps auf See: Art, Figur auf der Karte, Nummer.
  final SeaStopInfo? seaStop;
}

class StationInfo {
  const StationInfo({
    required this.id,
    required this.islandId,
    required this.sortOrder,
    required this.type,
    required this.isRequired,
    required this.xpReward,
    required this.content,
  });

  /// Eine Zeile aus der Tabelle `stations`.
  factory StationInfo.fromRow(Map<String, dynamic> r) => StationInfo(
    id: r['id'] as String,
    islandId: r['island_id'] as String,
    sortOrder: r['sort_order'] as int,
    type: StationInfo.parseType(r['type'] as String?),
    isRequired: r['is_required'] as bool,
    xpReward: r['xp_reward'] as int,
    content: StationContent.fromJson((r['content'] as Map<String, dynamic>?) ?? const {}),
  );

  final String id;
  final String islandId;
  final int sortOrder;
  final StationType type;
  final bool isRequired;
  final int xpReward;
  final StationContent content;

  bool get isExam => type == StationType.exam;

  /// Ankerplatz mit Tauchgang.
  bool get isDive => type == StationType.reviewStop;

  /// Stopp auf See: Pflicht auf der Route vor der Insel, zu der er gehört.
  bool get isSeaStop => type == StationType.seaStop;

  /// Nummer für die Anzeige (bei älteren Inhalten ohne Nummer die Reihenfolge).
  int get displayNumber => content.number ?? sortOrder;

  static StationType parseType(String? value) => switch (value) {
    'video' => StationType.video,
    'quiz' => StationType.quiz,
    'practice' => StationType.practice,
    'review_stop' => StationType.reviewStop,
    'exam' => StationType.exam,
    'sea_stop' => StationType.seaStop,
    _ => StationType.game,
  };
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.stationId,
    required this.question,
    required this.answers,
    required this.correctIndex,
    this.explanation,
    this.coversStation,
    this.beginner,
  });

  /// Zwillingsfrage mit ganzen Zahlen für Einsteiger (quiz_questions.beginner):
  /// Frage, Antworten (gleiche Anzahl, richtige an derselben Stelle) und Erklärung.
  final ({String question, List<String> answers, String? explanation})? beginner;

  /// Die Frage für ein Kind: Einsteiger bekommen den Zwilling ohne Komma.
  /// Gleiche Kennung und gleiche richtige Stelle, damit die Auswertung gleich bleibt.
  QuizQuestion forLevel(LevelSetting level) {
    final easy = beginner;
    if (level != LevelSetting.beginner || easy == null || easy.answers.length != answers.length) return this;
    return QuizQuestion(
      id: id,
      stationId: stationId,
      question: easy.question,
      answers: easy.answers,
      correctIndex: correctIndex,
      explanation: easy.explanation,
      coversStation: coversStation,
    );
  }

  final String id;
  final String stationId;
  final String question;

  /// Antworten in der gespeicherten Reihenfolge (vor dem Mischen).
  final List<String> answers;
  final int correctIndex;
  final String? explanation;

  /// Bei Prüfungsfragen: zu welcher Station der Insel die Frage gehört.
  final int? coversStation;
}

/// Was das Kind schon geschafft hat.
class ChildProgress {
  const ChildProgress({
    this.doneStationIds = const {},
    this.completedIslandIds = const {},
    this.islandCompletedAt = const {},
    this.stationCompletedAt = const {},
  });

  final Set<String> doneStationIds;

  /// Wann eine Station erledigt wurde (für den Wochenbericht im Leuchtturm).
  final Map<String, DateTime> stationCompletedAt;
  final Set<String> completedIslandIds;

  /// Wann eine Insel abgeschlossen wurde (für den Leuchtturm).
  final Map<String, DateTime> islandCompletedAt;
}

/// Antwort des Servers nach dem Abgeben einer Station.
class StationResult {
  const StationResult({
    required this.correct,
    required this.total,
    required this.passed,
    required this.xpAwarded,
    required this.islandCompleted,
    this.rankUp,
    this.badge,
    this.windLeft,
    this.find,
  });

  factory StationResult.fromJson(Map<String, dynamic> json) => StationResult(
    correct: json['correct'] as int,
    total: json['total'] as int,
    passed: json['passed'] as bool,
    xpAwarded: json['xp_awarded'] as int,
    islandCompleted: json['island_completed'] as bool,
    rankUp: Rank.parse(json['rank_up']),
    badge: json['badge'] is Map<String, dynamic> ? BadgeInfo.fromJson(json['badge'] as Map<String, dynamic>) : null,
    windLeft: json['wind_left'] as int?,
    find: json['find'] is Map<String, dynamic> ? CollectibleInfo.fromJson(json['find'] as Map<String, dynamic>) : null,
  );

  final int correct;
  final int total;
  final bool passed;
  final int xpAwarded;
  final bool islandCompleted;

  /// Neuer Rang durch diese Station, sonst `null`.
  final Rank? rankUp;

  /// Orden der Insel, wenn sie mit dieser Station abgeschlossen wurde.
  final BadgeInfo? badge;

  /// Wind für weitere neue Stationen (`null` bei freier Fahrt oder Bonus-Station).
  final int? windLeft;

  /// Neuer Fund aus dem Tauchgang, sonst `null`.
  final CollectibleInfo? find;
}
