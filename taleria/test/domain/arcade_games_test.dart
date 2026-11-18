import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:taleria/domain/arcade_games.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/features/map/map_layout.dart';

GullFlightGame _game() => GullFlightGame(width: 0.46, random: Random(1));

void main() {
  test('vor dem ersten Antippen schwebt Mia, nichts bewegt sich', () {
    final game = _game();
    for (var i = 0; i < 100; i++) {
      game.step(0.05);
    }
    expect(game.started, isFalse);
    expect(game.lives, GullFlightGame.hearts);
    expect(game.obstacles, isEmpty);
  });

  test('ohne Flattern fällt Mia ins Wasser: ein Herz weg, dann kurz sicher', () {
    final game = _game()..flap();
    var steps = 0;
    while (game.lives == 3 && steps++ < 200) {
      game.step(0.02);
    }
    expect(game.lives, 2);
    expect(game.safe, isTrue);
    expect(game.y, lessThan(GullFlightGame.sea));
  });

  test('drei Herzen, dann ist die Runde vorbei', () {
    final game = _game()..flap();
    for (var i = 0; i < 3000 && !game.over; i++) {
      game.step(0.02);
    }
    expect(game.over, isTrue);
    expect(game.lives, 0);
    game.step(0.02);
    expect(game.events, isEmpty, reason: 'nach dem Ende passiert nichts mehr');
  });

  test('Taler kommen in die Tasche, das Sparglas macht sie sicher', () {
    final game = _game()..flap();
    game.pickups
      ..add(GullPickup(x: game.birdX, y: game.y))
      ..add(GullPickup(x: game.birdX, y: game.y));
    game.step(0.001);
    expect(game.pocket, 2);
    expect(game.events, contains(ArcadeEvent.coin));
    game.pickups.add(GullPickup(x: game.birdX, y: game.y, jar: true));
    game.step(0.001);
    expect(game.saved, 2);
    expect(game.pocket, 0);
    expect(game.events, contains(ArcadeEvent.saved));
    expect(game.score, 2);
  });

  test('beim Anstoßen fällt die Hälfte der Tasche ins Meer, das Gesparte bleibt', () {
    final game = _game()..flap();
    game
      ..pocket = 5
      ..saved = 4
      ..y = GullFlightGame.sea;
    game.step(0.001);
    expect(game.lives, 2);
    expect(game.pocket, 2);
    expect(game.dropped, 3);
    expect(game.saved, 4);
  });

  test('alle 10 Taler wird es schneller und enger', () {
    final game = _game();
    final speed = game.speed, gap = game.gapHalf;
    game.collected = 10;
    expect(game.level, 2);
    expect(game.speed, greaterThan(speed));
    expect(game.gapHalf, lessThan(gap));
    game.collected = 500;
    expect(game.speed, lessThanOrEqualTo(0.5));
    expect(game.gapHalf, greaterThanOrEqualTo(0.115));
  });

  test('mit Flattern durch die Lücken kommt Mia weit (Lücken sind erreichbar)', () {
    final game = _game()..flap();
    // Ein einfacher Autopilot: flattern, wenn Mia unter die Mitte der nächsten Lücke sinkt.
    for (var i = 0; i < 1500 && !game.over; i++) {
      final next = game.obstacles.where((o) => o.x + GullFlightGame.obstacleWidth > game.birdX - 0.05).firstOrNull;
      final target = next?.centerAt(game.time) ?? 0.5;
      if (game.y > target + 0.03 && game.vy > -0.2) game.flap();
      game.step(0.02);
    }
    expect(game.lives, greaterThan(0), reason: '30 Sekunden ohne Verlust sind mit gutem Fliegen möglich');
    expect(game.collected, greaterThan(5));
  });

  test('Sterne nach Punkten, der erste fürs Mitspielen', () {
    final game = arcadeGames.firstWhere((g) => g.id == 'moewenflug');
    expect(game.starsFor(0), 1);
    expect(game.starsFor(game.starScores.$1), 2);
    expect(game.starsFor(game.starScores.$2), 3);
  });

  test('jedes Spiel liegt auf einer bekannten Insel und auf dem Bild', () {
    for (final game in arcadeGames) {
      if (game.spot case final spot?) {
        expect(spot.dx, inInclusiveRange(0, 1));
        expect(spot.dy, inInclusiveRange(0, 1));
      }
      expect(arcadeGamesOn(game.island), contains(game));
    }
    expect(arcadeGames.map((g) => g.id).toSet().length, arcadeGames.length);
  });

  group('Bootsbauers Kran', () {
    CraneGame crane() => CraneGame(width: 0.46, random: Random(3));

    test('genau die Bestellung: Punkte und neue Bestellung', () {
      final g = crane()..drop();
      g
        ..target = 3
        ..sum = 1
        ..held = CraneItem(x: 0, value: 2, phase: 0)
        ..state = 2
        ..hookY = CraneGame.top + 0.001;
      g.step(0.01);
      expect(g.points, 3);
      expect(g.delivered, 1);
      expect(g.sum, 0);
      expect(g.events, contains(ArcadeEvent.good));
      expect(g.lives, 3);
    });

    test('zu viel in der Kiste oder ein Stiefel kostet ein Herz', () {
      final g = crane()..drop();
      g
        ..target = 3
        ..sum = 2
        ..held = CraneItem(x: 0, value: 5, phase: 0)
        ..state = 2
        ..hookY = CraneGame.top + 0.001;
      g.step(0.01);
      expect(g.lives, 2);
      expect(g.sum, 0);
      g.safeUntil = 0;
      g
        ..held = CraneItem(x: 0, value: 0, phase: 0)
        ..state = 2
        ..hookY = CraneGame.top + 0.001;
      g.step(0.01);
      expect(g.lives, 1);
    });

    test('der Haken fängt, was unter ihm schwimmt', () {
      final g = crane()..drop();
      g.items
        ..clear()
        ..add(CraneItem(x: g.trolley, value: 2, phase: 0));
      for (var i = 0; i < 100 && g.held == null; i++) {
        g.step(0.02);
      }
      expect(g.held?.value, 2);
    });
  });

  group('Ottis Lieferboot', () {
    test('richtige Ware zählt, falsche Ware und Steine kosten ein Herz', () {
      final g = DeliveryGame(width: 0.46, random: Random(1))..moveTo(1);
      g.onCatch(LaneThing(lane: 1, y: 0, kind: g.current.wants));
      expect(g.points, 1);
      g.onCatch(LaneThing(lane: 1, y: 0, kind: 'rock'));
      expect(g.lives, 2);
      g.safeUntil = 0;
      final other = DeliveryGame.goods.firstWhere((x) => x != g.current.wants);
      g.onCatch(LaneThing(lane: 1, y: 0, kind: other));
      expect(g.lives, 1);
      expect(g.wrongGoods, 1);
    });

    test('nach 3 Lieferungen kommt der nächste Kunde', () {
      final g = DeliveryGame(width: 0.46, random: Random(1))..moveTo(1);
      final first = g.current;
      for (var i = 0; i < DeliveryGame.perCustomer; i++) {
        g.onCatch(LaneThing(lane: 1, y: 0, kind: g.current.wants));
      }
      expect(g.current, isNot(first));
      expect(g.events, contains(ArcadeEvent.good));
    });

    test('was in der Bahn des Boots unten ankommt, ist gefangen', () {
      final g = DeliveryGame(width: 0.46, random: Random(1))..moveTo(2);
      g.things.add(LaneThing(lane: 2, y: LaneGame.catchY - 0.01, kind: g.current.wants));
      g.step(0.02);
      expect(g.points, greaterThanOrEqualTo(1));
    });
  });

  group('Elsas Flaschenfänger', () {
    test('Brauchen zählt, ein gefangener Wunsch kostet ein Herz', () {
      final g = BottleGame(width: 0.46, random: Random(1))..moveTo(0);
      g.onCatch(LaneThing(lane: 0, y: 0, kind: BottleGame.needs.first));
      expect(g.points, 1);
      g.onCatch(LaneThing(lane: 0, y: 0, kind: BottleGame.wishes.first));
      expect(g.lives, 2);
      g.onMiss(LaneThing(lane: 1, y: 1, kind: BottleGame.wishes.first));
      expect(g.wishesLetGo, 1);
    });
  });

  group('Emmas Nussjagd', () {
    test('springen, Nüsse sammeln, im Versteck sicher', () {
      final g = NutRunGame(width: 0.46, random: Random(1))..jump();
      expect(g.onGround, isFalse);
      g.things
        ..clear()
        ..add(NutThing(x: g.emmaX, y: g.y - 0.04, type: NutThingType.nut));
      g.step(0.001);
      expect(g.carried, 1);
      g.things.add(NutThing(x: g.emmaX, y: NutRunGame.ground, type: NutThingType.hollow));
      g.step(0.001);
      expect(g.stored, 1);
      expect(g.carried, 0);
    });

    test('ein Pilz kostet ein Herz und die Hälfte der Nüsse', () {
      final g = NutRunGame(width: 0.46, random: Random(1));
      g
        ..started = true
        ..carried = 4;
      g.things.add(NutThing(x: g.emmaX, y: NutRunGame.ground, type: NutThingType.mushroom));
      g.step(0.001);
      expect(g.lives, 2);
      expect(g.carried, 2);
      expect(g.dropped, 2);
    });

    test('ohne Springen ist die Runde irgendwann vorbei', () {
      final g = NutRunGame(width: 0.46, random: Random(1))..jump();
      for (var i = 0; i < 4000 && !g.over; i++) {
        g.step(0.02);
      }
      expect(g.over, isTrue);
    });
  });

  group('Talas Perlentaucher', () {
    test('offene Muschel gibt eine Perle, geschlossene nicht, Qualle kostet ein Herz', () {
      final g = PearlDiveGame(width: 0.46, random: Random(1))..swimTo(0.2, 0.5);
      // Phase so, dass die Muschel jetzt offen ist.
      g.shells.add(PearlShell(x: g.x, y: g.y, phase: pi / 2));
      g.step(0.001);
      expect(g.pearls, 1);
      g.shells
        ..clear()
        ..add(PearlShell(x: g.x, y: g.y, phase: -pi / 2 - g.time * 1.4));
      g.step(0.001);
      expect(g.pearls, 1);
      g.jellies.add(Jelly(x: g.x, baseY: g.y, phase: 0, amp: 0));
      g.step(0.001);
      expect(g.lives, 2);
    });

    test('Tala schwimmt zum Finger', () {
      final g = PearlDiveGame(width: 0.46, random: Random(1))..swimTo(0.4, 0.7);
      for (var i = 0; i < 100; i++) {
        g.step(0.02);
        g.jellies.clear();
      }
      expect(g.x, closeTo(0.4, 0.01));
      expect(g.y, closeTo(0.7, 0.01));
    });
  });

  test('jede Spielart hat eine Runde, die läuft', () {
    for (final kind in ArcadeKind.values) {
      final round = newArcadeRound(kind, 0.46);
      expect(round.started, isFalse);
      round.step(0.1);
      expect(round.lives, ArcadeRound.hearts);
    }
  });

  group('Töne der Spiele', () {
    test('erstes Antippen meldet den Start, jede Aktion einen Ton', () {
      final g = GullFlightGame(width: 0.46, random: Random(1))..flap();
      g.step(0.01);
      expect(g.events, containsAllInOrder([ArcadeEvent.start, ArcadeEvent.action]));
      g.flap();
      g.step(0.01);
      expect(g.events, isNot(contains(ArcadeEvent.start)), reason: 'der Start klingt nur einmal');
      expect(g.events, contains(ArcadeEvent.action));
    });

    test('Kran: Haken fällt ins Wasser, ein Stiefel klingt eigen', () {
      final g = CraneGame(width: 0.46, random: Random(3))..drop();
      final all = <ArcadeEvent>[];
      for (var i = 0; i < 60; i++) {
        g.step(0.02);
        all.addAll(g.events);
      }
      expect(all, contains(ArcadeEvent.splash));
      g
        ..held = CraneItem(x: 0, value: 0, phase: 0)
        ..state = 2
        ..hookY = CraneGame.top + 0.001;
      g.step(0.01);
      expect(g.events, contains(ArcadeEvent.junk));
    });

    test('Bahnwechsel klingt nur, wenn sich die Bahn ändert', () {
      final g = DeliveryGame(width: 0.46, random: Random(1))..moveTo(1);
      g.step(0.01);
      expect(g.events, isNot(contains(ArcadeEvent.action)));
      g.moveTo(2);
      g.step(0.01);
      expect(g.events, contains(ArcadeEvent.action));
    });

    test('Emma: Sprung und Doppelsprung klingen, dreifach nicht', () {
      final g = NutRunGame(width: 0.46, random: Random(1))
        ..jump()
        ..jump()
        ..jump();
      g.step(0.001);
      expect(g.events.where((e) => e == ArcadeEvent.action), hasLength(2));
    });
  });

  test('Perlentaucher: Wer unten bei den Muscheln stehen bleibt, trifft auch Quallen', () {
    for (final seed in [1, 2, 3]) {
      final g = PearlDiveGame(width: 0.46, random: Random(seed))..swimTo(0.15, 1);
      for (var i = 0; i < 3000 && g.lives == ArcadeRound.hearts; i++) {
        g.step(0.02);
      }
      expect(g.lives, lessThan(ArcadeRound.hearts), reason: 'Seed $seed: unten ist man nicht mehr sicher');
    }
  });

  test('Tauch-Boje liegt im Meer unter dem Hafen, nicht auf der Insel', () {
    final layout = MapLayout.compute(
      width: 390,
      viewportHeight: 844,
      islands: [
        for (final (i, s) in ['hafen', 'tauschinsel', 'wunschinsel'].indexed)
          MapIsland(id: s, slug: s, title: s, sortOrder: i + 1, mapX: 0.5, mapY: 1.0 - i * 0.3, hasContent: true),
      ],
    );
    final spot = layout.diveBuoySpot(const Size(104, 112));
    final hafen = layout.centerOf('hafen');
    expect(spot.dy, greaterThan(hafen.dy), reason: 'unter dem Hafen');
    expect(spot.dy, lessThanOrEqualTo(layout.height), reason: 'noch auf der Karte');
    expect(spot.dx, inInclusiveRange(52, 390 - 52));
  });
}
