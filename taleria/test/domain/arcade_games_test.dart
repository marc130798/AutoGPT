import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/arcade_games.dart';

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
      ..add(GullPickup(x: GullFlightGame.birdX, y: game.y))
      ..add(GullPickup(x: GullFlightGame.birdX, y: game.y));
    game.step(0.001);
    expect(game.pocket, 2);
    expect(game.events, contains(GullEvent.coin));
    game.pickups.add(GullPickup(x: GullFlightGame.birdX, y: game.y, jar: true));
    game.step(0.001);
    expect(game.saved, 2);
    expect(game.pocket, 0);
    expect(game.events, contains(GullEvent.saved));
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
      final next = game.obstacles
          .where((o) => o.x + GullFlightGame.obstacleWidth > GullFlightGame.birdX - 0.05)
          .firstOrNull;
      final target = next?.centerAt(game.time) ?? 0.5;
      if (game.y > target + 0.03 && game.vy > -0.2) game.flap();
      game.step(0.02);
    }
    expect(game.lives, greaterThan(0), reason: '30 Sekunden ohne Verlust sind mit gutem Fliegen möglich');
    expect(game.collected, greaterThan(5));
  });

  test('Sterne nach Punkten, der erste fürs Mitspielen', () {
    final game = arcadeGames.first;
    expect(game.starsFor(0), 1);
    expect(game.starsFor(game.starScores.$1), 2);
    expect(game.starsFor(game.starScores.$2), 3);
  });

  test('jedes Spiel liegt auf einer bekannten Insel und auf dem Bild', () {
    for (final game in arcadeGames) {
      expect(game.spot.dx, inInclusiveRange(0, 1));
      expect(game.spot.dy, inInclusiveRange(0, 1));
      expect(arcadeGamesOn(game.island), contains(game));
    }
    expect(arcadeGames.map((g) => g.id).toSet().length, arcadeGames.length);
  });
}
