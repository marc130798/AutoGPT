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
}
