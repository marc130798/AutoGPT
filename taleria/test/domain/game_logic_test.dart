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

  group('Entscheidungen', () {
    const game = GameInfo(
      type: 'choice',
      title: 'Tauschkette',
      rounds: [
        GameRound(
          question: 'Wer hat Äpfel?',
          options: [
            GameOption(text: 'Bruno', good: true, reply: 'Richtig.'),
            GameOption(text: 'Otti', good: false, reply: 'Otti hat Fisch.'),
          ],
        ),
        GameRound(
          question: 'Eis oder sparen?',
          options: [
            GameOption(text: 'Eis', good: true, reply: 'Dafür dauert das Fernrohr länger.'),
            GameOption(text: 'Sparen', good: true, reply: 'Dafür heute kein Eis.'),
          ],
        ),
      ],
    );

    test('weniger gute Wahl: Rückmeldung und nochmal, gute Wahl: weiter', () {
      final c = ChoiceGame(game, Random(3));
      expect(c.optionOrder.toSet(), {0, 1}, reason: 'Möglichkeiten werden gemischt angezeigt');
      c.choose(1);
      expect([c.answered, c.answeredWell, c.chosenOption!.reply], [true, false, 'Otti hat Fisch.']);
      c.next();
      expect(c.index, 0, reason: 'erst weiter nach einer guten Wahl');
      c.retry();
      c.choose(0);
      expect(c.answeredWell, isTrue);
      c.choose(1);
      expect(c.chosen, 0, reason: 'nach einer guten Wahl bleibt sie stehen');
      c.next();
      c.choose(1);
      expect(c.finished, isTrue, reason: 'mehrere gute Möglichkeiten sind erlaubt');
    });

    test('spielbar nur, wenn jede Runde eine gute Möglichkeit hat', () {
      expect(game.isPlayable, isTrue);
      expect(
        const GameInfo(
          type: 'choice',
          title: 'x',
          rounds: [
            GameRound(
              question: 'q',
              options: [GameOption(text: 'a', good: false, reply: 'r')],
            ),
          ],
        ).isPlayable,
        isFalse,
      );
    });
  });

  group('Münzen legen', () {
    const game = GameInfo(
      type: 'coins',
      title: 'Münzschublade',
      rounds: [
        GameRound(question: 'Lege 3,50 €.', amount: 350),
        GameRound(question: 'Wechselgeld', amount: 55),
      ],
    );

    test('so wenige Münzen wie möglich', () {
      expect(CoinsGame.fewestPieces(350), 3);
      expect(CoinsGame.fewestPieces(185), 5);
      expect(CoinsGame.fewestPieces(55), 2);
      expect(CoinsGame.fewestPieces(250), 2);
    });

    test('zu viel, wegnehmen, genau; mit mehr Münzen als nötig gibt es einen Hinweis', () {
      final c = CoinsGame(game);
      c
        ..add(200)
        ..add(200);
      expect([c.sum, c.tooMuch, c.exact], [400, true, false]);
      c
        ..removeAt(1)
        ..add(100)
        ..add(20)
        ..add(20);
      expect(c.tooMuch, isFalse);
      c.add(10);
      expect([c.exact, c.couldUseFewer], [true, true]);
      c.add(1);
      expect(c.sum, 350, reason: 'nach dem Treffer zählt nichts mehr dazu');
      c.next();
      expect([c.index, c.sum, c.target], [1, 0, 55]);
      c
        ..add(50)
        ..add(5);
      expect([c.finished, c.couldUseFewer], [true, false]);
    });
  });

  group('Auswählen', () {
    const stack = GameInfo(
      type: 'pick',
      title: 'Preis-Säule',
      target: 7,
      exactTarget: true,
      items: [
        GameItem(text: 'Fisch', price: 4, required: true),
        GameItem(text: 'Brötchen', price: 1, required: true),
        GameItem(text: 'Miete', price: 2, required: true),
        GameItem(text: 'Goldene Serviette', price: 2, hint: 'Gehört nicht dazu.'),
      ],
    );
    const backpack = GameInfo(
      type: 'pick',
      title: 'Rucksack',
      target: 10,
      items: [
        GameItem(text: 'Wasser', price: 2, required: true, hint: 'Wasser brauchst du.'),
        GameItem(text: 'Jacke', price: 4, required: true, hint: 'Die Jacke brauchst du.'),
        GameItem(text: 'Kompass', price: 6, hint: 'Schön, aber nicht wichtig.'),
        GameItem(text: 'Bonbons', price: 1, hint: 'Lecker.'),
      ],
    );

    test('genau: falsches Teil zeigt den Hinweis, fehlende Teile „fehlt noch etwas“', () {
      final p = PickGame(stack)
        ..toggle(0)
        ..toggle(3);
      expect(p.check(), PickResult.wrongItem);
      expect(p.hintItem, 3);
      p.toggle(3);
      expect(p.check(), PickResult.tooLittle);
      p
        ..toggle(1)
        ..toggle(2);
      expect(p.sum, 7);
      expect(p.check(), PickResult.solved);
      p.toggle(0);
      expect(p.selected, contains(0), reason: 'nach dem Lösen bleibt alles, wie es ist');
    });

    test('Budget: zu teuer, Wichtiges vergessen, dann passt es (Extras erlaubt)', () {
      final p = PickGame(backpack)
        ..toggle(0)
        ..toggle(1)
        ..toggle(2);
      expect(p.check(), PickResult.tooMuch);
      p
        ..toggle(2)
        ..toggle(1);
      expect(p.check(), PickResult.missingItem);
      expect(backpack.items[p.hintItem!].text, 'Jacke');
      p
        ..toggle(1)
        ..toggle(3);
      expect(p.check(), PickResult.solved);
    });
  });

  group('Rechnen', () {
    const game = GameInfo(
      type: 'number',
      title: 'Netz-Rechnung',
      rounds: [
        GameRound(question: '12 mal 5?', amount: 60, hint: '12 Monate', explanation: '12 × 5 = 60'),
        GameRound(question: '60 minus 20?', amount: 40, explanation: '60 − 20 = 40'),
      ],
    );

    test('falsch: Tipp und Lösung auf Wunsch, richtig: weiter', () {
      final n = NumberGame(game);
      n.reveal();
      expect(n.revealed, isFalse, reason: 'Lösung erst nach einem Versuch');
      expect(n.submit(50), isFalse);
      expect(n.wrongTries, 1);
      n.reveal();
      expect(n.canContinue, isTrue);
      n.next();
      expect([n.index, n.wrongTries, n.revealed], [1, 0, false]);
      expect(n.submit(40), isTrue);
      expect(n.finished, isTrue);
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
