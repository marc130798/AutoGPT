import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/domain/real_games.dart';

void main() {
  test('Sterne: wenige Fehler drei, einige zwei, sonst einer, nie keiner', () {
    expect(
      [
        for (final m in [0, 1, 2, 3, 4, 9]) starsForMistakes(m),
      ],
      [3, 3, 2, 2, 1, 1],
    );
  });

  test('Kasse: zu wenig, zu viel, richtig; erst danach der nächste Kunde', () {
    const game = GameInfo(
      type: 'till',
      title: 'Kasse',
      customers: [
        TillCustomer(figure: 'talo', text: 'Eins', price: 350, paid: 500),
        TillCustomer(figure: 'tala', text: 'Zwei', price: 45, paid: 100),
      ],
    );
    final till = TillGame(game);
    till.next();
    expect(till.index, 0, reason: 'ohne Herausgeben geht es nicht weiter');
    till.add(100);
    expect(till.give(), TillCheck.tooLittle);
    expect(till.difference, 50);
    till.add(100);
    expect(till.give(), TillCheck.tooMuch);
    till.removeAt(1);
    till.add(50);
    expect(till.give(), TillCheck.right);
    till.add(5);
    expect(till.placed, [100, 50], reason: 'nach dem Herausgeben bleibt das Wechselgeld liegen');
    till.next();
    till
      ..add(50)
      ..add(5);
    expect(till.give(), TillCheck.right);
    expect(till.finished, isTrue);
    expect(till.mistakes, 2);
    expect(till.stars, 2);
  });

  test('Markt: Liste, zu wenig Geld, zurücklegen, Sterne nach dem günstigsten Einkauf', () {
    const game = GameInfo(
      type: 'market',
      title: 'Markt',
      budget: 300,
      needs: [
        MarketNeed(item: 'Brot', count: 2),
        MarketNeed(item: 'Saft'),
      ],
      stands: [
        MarketStand(
          figure: 'haendler',
          name: 'A',
          offers: [
            MarketOffer(item: 'Brot', price: 80),
            MarketOffer(item: 'Saft', price: 150),
            MarketOffer(item: 'Bonbons', price: 50),
          ],
        ),
        MarketStand(
          figure: 'tala',
          name: 'B',
          offers: [
            MarketOffer(item: 'Brot', price: 50),
            MarketOffer(item: 'Saft', price: 120),
          ],
        ),
      ],
    );
    final market = MarketGame(game);
    expect(market.cheapestTotal, 220);
    expect(market.buy(0, game.stands[0].offers[2]), MarketBuy.notOnList);
    expect(market.buy(0, game.stands[0].offers[0]), MarketBuy.bought);
    expect(market.left, 140);
    expect(market.buy(1, game.stands[1].offers[0]), MarketBuy.alreadyHave);
    expect(market.buy(0, game.stands[0].offers[1]), MarketBuy.notEnoughMoney);
    expect(market.stuck, isFalse, reason: 'Saft für 1,20 € geht sich noch aus');
    expect(market.buy(1, game.stands[1].offers[1]), MarketBuy.bought);
    expect(market.finished, isTrue);
    expect(market.stars, 2);

    final best = MarketGame(game)
      ..buy(1, game.stands[1].offers[0])
      ..buy(1, game.stands[1].offers[1]);
    expect(best.left, 80);
    expect(best.stars, 3);

    final stuck = MarketGame(game)..buy(0, game.stands[0].offers[0]);
    stuck.cart['Brot'] = (stand: 0, price: 100);
    expect(stuck.stuck, isTrue);
    stuck.putBack('Brot');
    expect(stuck.left, 300);
  });

  test('Eisstand: Kunden, Verkauf, bester Preis und Sterne', () {
    const sun = IceDay(weather: 'sun', stock: 20, demand: 40, drop: 5);
    const rain = IceDay(weather: 'rain', stock: 20, demand: 10, drop: 2);
    const game = GameInfo(type: 'ice_stand', title: 'Eis', days: [sun, rain], priceMin: 1, priceMax: 8);
    final ice = IceStandGame(game);
    expect(ice.price, 2);
    final cheap = ice.open();
    expect((cheap.customers, cheap.sold, cheap.earned, cheap.missed, cheap.melted), (30, 20, 40, 10, 0));
    expect(ice.bestPrices(sun), [4]);
    expect(ice.bestPrices(rain), [2, 3]);
    ice.setPrice(4);
    expect(ice.open().earned, 80);
    expect(ice.bestFoundToday, isTrue);
    ice.next();
    expect(ice.price, 4, reason: 'der Preis vom Vortag bleibt');
    expect(ice.open().melted, 18);
    expect(ice.finished, isTrue);
    expect(ice.stars, 2);
    ice.setPrice(99);
    expect(ice.price, 8);
  });

  test('Tauschkette: Ablehnung, Sackgasse, von vorn, Ziel', () {
    const game = GameInfo(
      type: 'trade_chain',
      title: 'Tausch',
      start: 'Eimer',
      goal: 'Seil',
      traders: [
        Trader(figure: 'greta', name: 'Greta', has: 'Seil', wants: 'Fisch'),
        Trader(figure: 'olga', name: 'Olga', has: 'Muschel', wants: 'Eimer'),
        Trader(figure: 'otti', name: 'Otti', has: 'Fisch', wants: 'Eimer'),
      ],
    );
    final chain = TradeChainGame(game);
    expect(chain.tap(0), TradeResult.refused);
    expect(chain.refusedBy, 0);
    expect(chain.tap(1), TradeResult.traded);
    expect(chain.stuck, isTrue);
    chain.reset();
    expect((chain.holding, chain.used.isEmpty, chain.resets), ('Eimer', true, 1));
    expect(chain.tap(2), TradeResult.traded);
    expect(chain.tap(2), TradeResult.alreadyTraded);
    expect(chain.tap(0), TradeResult.traded);
    expect(chain.finished, isTrue);
    expect(chain.history, ['Eimer', 'Fisch']);
    expect(chain.stars, 2);
  });

  test('Rucksack: zu teuer, umkehren, nachpacken, sparen, Sterne', () {
    const game = GameInfo(
      type: 'backpack',
      title: 'Ausflüge',
      items: [
        GameItem(text: 'Wasser', price: 2),
        GameItem(text: 'Jacke', price: 4),
        GameItem(text: 'Brille', price: 4),
        GameItem(text: 'Bonbons', price: 1),
      ],
      trips: [
        BackpackTrip(
          title: 'Regen',
          budget: 7,
          needs: [
            BackpackNeed(item: 'Wasser', missing: 'Durst'),
            BackpackNeed(item: 'Jacke', missing: 'Nass'),
          ],
        ),
        BackpackTrip(
          title: 'Strand',
          budget: 5,
          needs: [BackpackNeed(item: 'Wasser', missing: 'Durst')],
        ),
      ],
    );
    final bag = BackpackGame(game);
    expect(bag.left, 7);
    expect(bag.pack('Brille'), BackpackPack.packed);
    expect(bag.pack('Jacke'), BackpackPack.notEnough, reason: '4 + 4 sind mehr als 7 Taler');
    expect(bag.pack('Wasser'), BackpackPack.packed);
    expect(bag.left, 1);

    // Ohne Jacke losgehen: umkehren, das zählt als Fehler.
    expect(bag.go(), isFalse);
    expect(bag.missing.map((n) => n.item), ['Jacke']);
    expect(bag.mistakes, 1);
    expect(bag.gone, isFalse);

    // Brille raus, Jacke rein.
    bag.unpack('Brille');
    expect(bag.pack('Jacke'), BackpackPack.packed);
    expect(bag.extras, isEmpty);
    expect(bag.go(), isTrue);
    expect(bag.gone, isTrue);
    expect(bag.saved, 1, reason: 'ein Taler übrig');
    expect(bag.pack('Bonbons'), BackpackPack.alreadyGone);

    bag.next();
    expect(bag.index, 1);
    expect(bag.packed, isEmpty);
    expect(bag.missing, isEmpty);
    bag.pack('Wasser');
    bag.pack('Bonbons');
    expect(bag.extras, ['Bonbons'], reason: 'nicht gebraucht, aber erlaubt');
    expect(bag.go(), isTrue);
    expect(bag.finished, isTrue);
    expect(bag.saved, 3);
    expect(bag.stars, 3, reason: 'ein Fehler kostet noch keinen Stern');
  });

  test('Wintervorrat: zu wenig gespart, von vorn, teilen, Sterne', () {
    final game = GameInfo.fromJson({
      'type': 'winter_store',
      'title': 'Wintervorrat',
      'now': 1,
      'later': 3,
      'need': 9,
      'days': [
        for (var i = 0; i < 4; i++) {'scene': []},
      ],
    });
    final w = WinterStoreGame(game);
    expect(game.isPlayable, isTrue);
    expect(game.isRealGame, isTrue);
    w
      ..eat()
      ..eat()
      ..store()
      ..eat();
    expect((w.winter, w.stored, w.eaten, w.enough, w.mistakes), (true, 3, 3, false, 1));
    w.store();
    expect(w.stored, 3, reason: 'Im Winter gibt es nichts mehr zu sammeln');

    w.restart();
    w
      ..store()
      ..store()
      ..store()
      ..store();
    expect((w.stored, w.surplus, w.finished), (12, 3, false));
    expect(w.gustavEaten, 4);
    w.decideShare(true);
    expect((w.shared, w.finished, w.stars), (true, true, 3));
  });

  test('Sparschwein: Plan, Versuchung, Geschenk, verpasst und geschafft', () {
    final game = GameInfo.fromJson({
      'type': 'piggy_bank',
      'title': 'Sparschwein',
      'goal': 'Laterne',
      'goal_price': 20,
      'income': 8,
      'plans': [3, 5],
      'weeks': [
        {'scene': []},
        {
          'scene': [],
          'event': {
            'kind': 'temptation',
            'speaker': 'haendler',
            'text': 'Zuckerwatte!',
            'item': 'Zuckerwatte',
            'price': 4,
          },
        },
        {
          'scene': [],
          'event': {'kind': 'gift', 'speaker': 'tala', 'text': 'Von Oma', 'price': 2},
        },
        {'scene': []},
      ],
    });
    final pig = PiggyBankGame(game);
    expect(pig.planTotal(5), 20);
    pig.choosePlan(5);
    pig.feed();
    expect((pig.pig, pig.pocket), (5, 3));
    pig.nextWeek();
    pig.feed();
    expect(pig.eventOpen, isTrue);
    pig.nextWeek();
    expect(pig.week, 1, reason: 'Erst entscheiden, dann weiter');
    pig.buy(fromPig: true);
    expect(pig.pig, 6);
    expect(pig.bought, ['Zuckerwatte']);
    pig.nextWeek();
    pig.feed();
    pig.takeGift(intoPig: true);
    pig.nextWeek();
    pig.feed();
    pig.nextWeek();
    expect((pig.over, pig.pig, pig.reached, pig.mistakes), (true, 18, false, 1));

    pig.restart();
    pig.choosePlan(5);
    for (var i = 0; i < 4; i++) {
      pig.feed();
      if (pig.current.event?.gift == false) pig.buy(fromPig: false);
      if (pig.current.event?.gift == true) pig.takeGift(intoPig: false);
      pig.nextWeek();
    }
    expect((pig.finished, pig.pig, pig.stars), (true, 20, 3));
  });

  test('Glitzerladen: Trick erkennen, Liste, zurückgeben, Sterne', () {
    final game = GameInfo.fromJson({
      'type': 'glitter_shop',
      'title': 'Glitzerladen',
      'budget': 6,
      'offers': [
        {'item': 'Spange', 'text': 'Nur heute!', 'trick': 'hurry', 'price': 4, 'needed': false, 'reveal': 'Druck'},
        {'item': 'Seil', 'text': 'Statt 10 nur 4', 'trick': 'fake_sale', 'price': 4, 'needed': true, 'reveal': 'Preis'},
      ],
    });
    final shop = GlitterShopGame(game);
    expect(game.isPlayable, isTrue);
    expect(shop.trickOptions, hasLength(3));
    expect(shop.trickOptions, contains('hurry'));
    shop.decide(buy: true);
    expect(shop.offerDone, isFalse, reason: 'Zuerst den Trick erkennen');
    expect(shop.guess('everyone'), ShopGuess.wrong);
    expect(shop.guess('everyone'), ShopGuess.wrong);
    expect(shop.mistakes, 1, reason: 'Derselbe falsche Trick zählt nur einmal');
    expect(shop.guess('hurry'), ShopGuess.right);
    shop.decide(buy: true);
    expect((shop.money, shop.mistakes), (2, 2));
    expect(shop.extras, ['Spange']);
    shop.next();

    shop.guess('fake_sale');
    shop.decide(buy: false);
    expect((shop.wrongSkip, shop.offerDone, shop.mistakes), (true, false, 3));
    expect(shop.canAfford, isFalse);
    shop.giveBack('Spange');
    expect(shop.money, 6);
    shop.decide(buy: true);
    expect((shop.finished, shop.money, shop.stars), (true, 2, 2));
    expect(shop.bought, ['Seil']);
  });
}
