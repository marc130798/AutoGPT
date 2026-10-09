import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/domain/progress_logic.dart';

MapIsland island(String id, int order, {bool content = true, String route = 'main'}) => MapIsland(
  id: id,
  slug: id,
  title: id,
  sortOrder: order,
  mapX: 0.5,
  mapY: 1 - order / 20,
  hasContent: content,
  routeType: route,
);

StationInfo station(String id, int order, {bool required = true, bool onboarding = false, String type = 'game'}) =>
    StationInfo(
      id: id,
      islandId: 'i',
      sortOrder: order,
      type: StationInfo.parseType(type),
      isRequired: required,
      xpReward: 100,
      content: StationContent(title: id, isOnboarding: onboarding),
    );

void main() {
  group('Inseln auf der Karte', () {
    final islands = [island('hafen', 1), island('tausch', 2), island('wunsch', 3), island('spar', 4, content: false)];

    test('Am Anfang: erste Insel offen, die nächsten gesperrt, Nebel bleibt Nebel', () {
      final states = islandStates(islands, const ChildProgress());
      expect(states, {
        'hafen': IslandState.open,
        'tausch': IslandState.locked,
        'wunsch': IslandState.locked,
        'spar': IslandState.fog,
      });
      expect(currentIslandId(islands, states), 'hafen');
    });

    test('Abschluss öffnet die nächste Insel', () {
      final states = islandStates(islands, const ChildProgress(completedIslandIds: {'hafen'}));
      expect(states['hafen'], IslandState.completed);
      expect(states['tausch'], IslandState.open);
      expect(states['wunsch'], IslandState.locked);
      expect(currentIslandId(islands, states), 'tausch');
    });

    test('Nach der letzten Insel mit Inhalt kommt der Nebel', () {
      final states = islandStates(islands, const ChildProgress(completedIslandIds: {'hafen', 'tausch', 'wunsch'}));
      expect(states['spar'], IslandState.fog);
      expect(currentIslandId(islands, states), 'wunsch');
    });

    test('Nebeninseln öffnen sich mit der Hauptroute davor', () {
      final withSide = [...islands, island('neben', 2, route: 'side')];
      final states = islandStates(withSide, const ChildProgress(completedIslandIds: {'hafen'}));
      expect(states['neben'], IslandState.open);
    });

    test('Ein Abschluss bleibt, auch wenn die Insel später im Nebel wäre', () {
      final states = islandStates([
        island('hafen', 1, content: false),
      ], const ChildProgress(completedIslandIds: {'hafen'}));
      expect(states['hafen'], IslandState.completed);
    });
  });

  group('Stationen auf einer Insel', () {
    final stations = [
      station('s1', 1, onboarding: true, type: 'practice'),
      station('s2', 2),
      station('s3', 3),
      station('bonus', 4, required: false),
      station('exam', 5, type: 'exam'),
    ];

    test('Vor dem Intro: nur das Intro und Bonus offen', () {
      final states = stationStates(stations, const ChildProgress(), onboardingCompleted: false);
      expect(states['s1'], StationState.open);
      expect(states['s2'], StationState.locked);
      expect(states['bonus'], StationState.open);
      expect(states['exam'], StationState.locked);
    });

    test('Nach dem Intro: Station 2 offen, der Rest der Reihe nach', () {
      final states = stationStates(stations, const ChildProgress(doneStationIds: {'s2'}), onboardingCompleted: true);
      expect(states['s1'], StationState.done);
      expect(states['s2'], StationState.done);
      expect(states['s3'], StationState.open);
      expect(states['exam'], StationState.locked);
    });

    test('Bonus-Station hält die Prüfung nicht auf', () {
      final states = stationStates(
        stations,
        const ChildProgress(doneStationIds: {'s2', 's3'}),
        onboardingCompleted: true,
      );
      expect(states['bonus'], StationState.open);
      expect(states['exam'], StationState.open);
    });

    test('Weißt du noch? nimmt die Station davor, nie das Intro oder die Prüfung', () {
      expect(previousQuizStation(stations, stations[1]), isNull);
      expect(previousQuizStation(stations, stations[2])?.id, 's2');
      expect(previousQuizStation(stations, stations[4])?.id, 'bonus');
    });
  });
}
