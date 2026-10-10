/// Regeln zum Freischalten auf Karte und Insel (CLAUDE.md, Abschnitt 8).
/// Der Server prüft dieselben Regeln noch einmal (submit_station).
library;

import 'content_models.dart';

enum IslandState {
  /// Inhalte noch nicht veröffentlicht: „Diese Insel taucht bald auf“.
  fog,

  /// Vorherige Insel noch nicht abgeschlossen.
  locked,
  open,
  completed,
}

enum StationState {
  locked,
  open,
  done,

  /// Wäre offen, aber das Schiff braucht erst Wind (Tempo, CLAUDE.md Abschnitt 8).
  noWind,
}

/// Zustand jeder Insel auf der Karte, in der Reihenfolge der Route.
Map<String, IslandState> islandStates(List<MapIsland> islands, ChildProgress progress) {
  final main = [...islands.where((i) => i.isMainRoute)]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final states = <String, IslandState>{};
  for (final island in islands) {
    // Wie island_unlocked() in der Datenbank: die Hauptroute-Insel mit der
    // nächstkleineren Reihenfolge muss abgeschlossen sein.
    final previous = main.where((m) => m.sortOrder < island.sortOrder).lastOrNull;
    final unlocked = previous == null || progress.completedIslandIds.contains(previous.id);
    states[island.id] = switch (island) {
      _ when progress.completedIslandIds.contains(island.id) => IslandState.completed,
      _ when !island.hasContent => IslandState.fog,
      _ when unlocked => IslandState.open,
      _ => IslandState.locked,
    };
  }
  return states;
}

/// Die Insel, an der das Schiff gerade liegt: die erste offene Insel der
/// Hauptroute, sonst die zuletzt abgeschlossene.
String? currentIslandId(List<MapIsland> islands, Map<String, IslandState> states) {
  final main = [...islands.where((i) => i.isMainRoute)]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  for (final island in main) {
    if (states[island.id] == IslandState.open) return island.id;
  }
  final completed = main.where((i) => states[i.id] == IslandState.completed);
  return completed.isEmpty ? (main.isEmpty ? null : main.first.id) : completed.last.id;
}

/// Ist die Station erledigt? Die Intro-Station gilt nach dem Intro als erledigt.
bool isStationDone(StationInfo station, ChildProgress progress, {required bool onboardingCompleted}) =>
    progress.doneStationIds.contains(station.id) || (station.content.isOnboarding && onboardingCompleted);

/// Zustand der Stationen einer offenen Insel: Pflichtstationen der Reihe nach,
/// Bonus-Stationen sind immer offen. Ohne Wind ([hasWind] `false`) wartet die
/// nächste neue Pflichtstation; Wiederholen und Bonus-Stationen gehen immer.
Map<String, StationState> stationStates(
  List<StationInfo> stations,
  ChildProgress progress, {
  required bool onboardingCompleted,
  bool hasWind = true,
}) {
  final sorted = [...stations]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final states = <String, StationState>{};
  var allEarlierDone = true;
  for (final station in sorted) {
    final done = isStationDone(station, progress, onboardingCompleted: onboardingCompleted);
    states[station.id] = switch (station) {
      _ when done => StationState.done,
      _ when !station.isRequired => StationState.open,
      // Ankerplätze brauchen keinen Wind, sie gehören zu den Stationen davor.
      _ when allEarlierDone => hasWind || station.isDive ? StationState.open : StationState.noWind,
      _ => StationState.locked,
    };
    if (station.isRequired && !done) allEarlierDone = false;
  }
  return states;
}

/// Stationen, deren Fragen ein Ankerplatz wiederholt: alle seit dem letzten
/// Ankerplatz, ohne Intro und Prüfung (wie submit_station() in der Datenbank).
List<StationInfo> stationsBeforeDive(List<StationInfo> stations, StationInfo dive) {
  final sorted = [...stations]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final previousDive = sorted.where((s) => s.isDive && s.sortOrder < dive.sortOrder).lastOrNull;
  return [
    for (final s in sorted)
      if (s.sortOrder < dive.sortOrder &&
          s.sortOrder > (previousDive?.sortOrder ?? -1) &&
          !s.isDive &&
          !s.isExam &&
          !s.content.isOnboarding)
        s,
  ];
}

/// Fortschritt auf der Hauptroute ist am Nebel angekommen: keine offene Insel
/// mehr, die nächste Insel liegt im Nebel (CLAUDE.md Abschnitt 8).
bool isFogAhead(List<MapIsland> islands, Map<String, IslandState> states) {
  final main = [...islands.where((i) => i.isMainRoute)]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  if (main.any((i) => states[i.id] == IslandState.open)) return false;
  final firstUnfinished = main.where((i) => states[i.id] != IslandState.completed).firstOrNull;
  return firstUnfinished != null && states[firstUnfinished.id] == IslandState.fog;
}

/// Die Station vor [station] mit eigenem Fragenpool (für „Weißt du noch?“).
StationInfo? previousQuizStation(List<StationInfo> stations, StationInfo station) {
  final earlier =
      stations
          .where((s) => s.sortOrder < station.sortOrder && !s.isExam && !s.isDive && !s.content.isOnboarding)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return earlier.isEmpty ? null : earlier.last;
}
