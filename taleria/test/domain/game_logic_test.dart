import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/domain/game_logic.dart';
import 'package:taleria/domain/progress_logic.dart';
import 'package:taleria/domain/quiz_logic.dart';

void main() {
  const sortGame = GameInfo(
    type: 'sort',
    title: 'Zwei Körbe',
    baskets: ['Brauche ich', 'Wünsche ich mir'],
    items: [
      GameItem(text: 'Wasser', basket: 0),
      GameItem(text: 'Spielkonsole', basket: 1),
      GameItem(text: 'Handy', hint: 'Darüber kann man streiten.'),
    ],
  );

  group('Sortieren', () {
    test('falscher Korb: nochmal, richtiger Korb: weiter, dazwischen passt überall', () {
      final game = SortGame(sortGame, Random(1));
      final seen = <String>{};
      while (true) {
        final item = game.current;
        seen.add(item.text);
        if (item.basket != null) {
          game.choose(1 - item.basket!);
          expect(game.answeredCorrectly, isFalse);
          game.next();
          expect(game.current.text, item.text, reason: 'erst weiter, wenn es stimmt');
          game.retry();
          game.choose(item.basket!);
        } else {
          game.choose(1);
        }
        expect(game.answeredCorrectly, isTrue);
        if (game.isLast) break;
        game.next();
      }
      expect(game.finished, isTrue);
      expect(seen, {'Wasser', 'Spielkonsole', 'Handy'});
    });

    test('Spielbar nur mit Körben und Dingen', () {
      expect(sortGame.isPlayable, isTrue);
      expect(const GameInfo(type: 'sort', title: 'x', baskets: ['a']).isPlayable, isFalse);
      expect(const GameInfo(type: 'coins', title: 'Münzschublade').isPlayable, isFalse);
    });
  });

  group('Reihenfolge', () {
    const orderGame = GameInfo(
      type: 'order',
      title: 'Zeitstrahl',
      items: [
        GameItem(text: 'Muscheln'),
        GameItem(text: 'Münzen'),
        GameItem(text: 'Scheine'),
      ],
    );

    test('nur das nächste Ding passt, Fehler kosten nichts', () {
      final game = OrderGame(orderGame, Random(2));
      expect(game.tap(2), isFalse);
      expect(game.wrongTap, 2);
      expect(game.tap(0), isTrue);
      expect(game.wrongTap, isNull);
      expect(game.tap(0), isFalse, reason: 'schon gelegt');
      expect(game.tap(1), isTrue);
      expect(game.tap(2), isTrue);
      expect(game.finished, isTrue);
      expect(game.lastPlaced?.text, 'Scheine');
    });
  });

  group('Tauchgang', () {
    StationInfo station(String id, int order, {StationType type = StationType.game, bool onboarding = false}) =>
        StationInfo(
          id: id,
          islandId: 'i',
          sortOrder: order,
          type: type,
          isRequired: true,
          xpReward: 100,
          content: StationContent(title: id, isOnboarding: onboarding),
        );
    final stations = [
      station('s1', 10, onboarding: true),
      station('s2', 20),
      station('d1', 25, type: StationType.reviewStop),
      station('s3', 30),
      station('s4', 40),
      station('d2', 45, type: StationType.reviewStop),
      station('exam', 80, type: StationType.exam),
    ];

    test('Fragen nur aus den Stationen seit dem letzten Ankerplatz', () {
      expect(stationsBeforeDive(stations, stations[2]).map((s) => s.id), ['s2']);
      expect(stationsBeforeDive(stations, stations[5]).map((s) => s.id), ['s3', 's4']);
    });

    test('Ankerplätze brauchen keinen Wind', () {
      final states = stationStates(
        stations,
        const ChildProgress(doneStationIds: {'s2'}),
        onboardingCompleted: true,
        hasWind: false,
      );
      expect(states['d1'], StationState.open);
      expect(states['s3'], StationState.locked);
    });

    test('„Weißt du noch?“ überspringt den Ankerplatz', () {
      expect(previousQuizStation(stations, stations[3])?.id, 's2');
    });

    test('Perlentauchen nimmt abwechselnd aus beiden Stationen', () {
      QuizQuestion q(String station, int i) => QuizQuestion(
        id: '$station-$i',
        stationId: station,
        question: '?',
        answers: const ['a', 'b', 'c'],
        correctIndex: 0,
      );
      final picked = pickDiveQuestions(
        [
          [for (var i = 0; i < 6; i++) q('s3', i)],
          [for (var i = 0; i < 6; i++) q('s4', i)],
        ],
        4,
        Random(3),
      );
      expect(picked, hasLength(4));
      expect(picked.where((p) => p.stationId == 's3'), hasLength(2));
      expect(
        pickDiveQuestions(
          [
            [q('s2', 1), q('s2', 2)],
          ],
          4,
          Random(1),
        ),
        hasLength(2),
        reason: 'kleiner Pool',
      );
    });
  });

  group('Wie es auf der Hauptroute weitergeht', () {
    MapIsland island(String id, int order, {bool content = true, String access = 'free'}) => MapIsland(
      id: id,
      slug: id,
      title: id,
      sortOrder: order,
      mapX: 0.5,
      mapY: 0.5,
      hasContent: content,
      access: access,
    );
    final islands = [island('a', 1), island('b', 2, access: 'premium'), island('c', 3, content: false)];

    test('Nebel voraus: keine offene Insel mehr, die nächste liegt im Nebel', () {
      final states = islandStates(islands, const ChildProgress(completedIslandIds: {'a', 'b'}));
      expect(routeBlock(islands, states), RouteBlock.fog);
    });

    test('Ohne Abo: die nächste Insel gehört zum Abo, die Insel danach bleibt gesperrt', () {
      final states = islandStates(islands, const ChildProgress(completedIslandIds: {'a'}), premium: false);
      expect(states['b'], IslandState.premium);
      expect(routeBlock(islands, states), RouteBlock.premium);
    });

    test('Mit Abo ist die Premium-Insel offen', () {
      final states = islandStates(islands, const ChildProgress(completedIslandIds: {'a'}));
      expect(states['b'], IslandState.open);
      expect(routeBlock(islands, states), isNull);
    });

    test('Abgeschlossene Premium-Inseln bleiben abgeschlossen, auch ohne Abo', () {
      final states = islandStates(islands, const ChildProgress(completedIslandIds: {'a', 'b'}), premium: false);
      expect(states['b'], IslandState.completed);
    });
  });
}
