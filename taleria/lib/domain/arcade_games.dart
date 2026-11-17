import 'dart:ui' show Offset;

import 'arcade/arcade_round.dart';
import 'arcade/crane.dart';
import 'arcade/gull_flight.dart';
import 'arcade/lanes.dart';
import 'arcade/nut_run.dart';
import 'arcade/pearl_dive.dart';
import 'content_models.dart';

export 'arcade/arcade_round.dart';
export 'arcade/crane.dart';
export 'arcade/gull_flight.dart';
export 'arcade/lanes.dart';
export 'arcade/nut_run.dart';
export 'arcade/pearl_dive.dart';

/// Richtige Spiele mit Geschick (Marcs Wunsch am 17.11.2026): drei Leben, es
/// wird immer schneller, am Ende Punkte, Rekord und bis zu drei Sterne. Das
/// Lernen läuft nebenbei mit. Jedes Spiel liegt an einem Ort, den es auf dem
/// Inselbild schon gibt, und öffnet sich nach einer Station dieser Insel.
/// Ein verlorenes Leben kostet nichts außer der Runde: kein Geld, keine
/// Seemeilen, keine Wartezeit; „Nochmal“ geht sofort.
enum ArcadeKind { crane, delivery, bottles, nutRun, gullFlight, pearlDive }

class ArcadeGame {
  const ArcadeGame({
    required this.id,
    required this.kind,
    required this.island,
    required this.spot,
    required this.afterStation,
    required this.starScores,
    this.afterDive = false,
  });

  /// Fester Name, unter dem das Gerät den Rekord merkt.
  final String id;
  final ArcadeKind kind;

  /// Slug der Insel, auf der das Spiel liegt.
  final String island;

  /// Ort auf dem Inselbild (0 bis 1), zum Beispiel der lange Steg; `null` =
  /// nur auf der Seite „Spiele“.
  final Offset? spot;

  /// Offen, sobald die Station mit dieser Nummer geschafft ist.
  final int afterStation;

  /// Stattdessen offen nach dem ersten Tauchgang (Ankerplatz) der Insel.
  final bool afterDive;

  /// Punkte für den zweiten und dritten Stern (der erste ist fürs Mitspielen).
  final (int, int) starScores;

  int starsFor(int score) => score >= starScores.$2
      ? 3
      : score >= starScores.$1
      ? 2
      : 1;
}

/// Alle richtigen Spiele in der Reihenfolge der Reise.
const arcadeGames = [
  ArcadeGame(
    id: 'kran',
    kind: ArcadeKind.crane,
    island: 'hafen',
    spot: Offset(0.88, 0.71),
    afterStation: 4,
    starScores: (20, 50),
  ),
  ArcadeGame(
    id: 'perlentaucher',
    kind: ArcadeKind.pearlDive,
    island: 'hafen',
    spot: null,
    afterStation: 0,
    afterDive: true,
    starScores: (12, 30),
  ),
  ArcadeGame(
    id: 'lieferboot',
    kind: ArcadeKind.delivery,
    island: 'tauschinsel',
    spot: Offset(0.22, 0.94),
    afterStation: 1,
    starScores: (12, 30),
  ),
  ArcadeGame(
    id: 'flaschenfaenger',
    kind: ArcadeKind.bottles,
    island: 'wunschinsel',
    spot: Offset(0.77, 0.86),
    afterStation: 1,
    starScores: (12, 30),
  ),
  ArcadeGame(
    id: 'nussjagd',
    kind: ArcadeKind.nutRun,
    island: 'spar-insel',
    spot: Offset(0.78, 0.47),
    afterStation: 1,
    starScores: (20, 50),
  ),
  ArcadeGame(
    id: 'moewenflug',
    kind: ArcadeKind.gullFlight,
    island: 'taschengeld-bucht',
    spot: Offset(0.79, 0.6),
    afterStation: 1,
    starScores: (25, 60),
  ),
];

/// Die Spiele einer Insel.
List<ArcadeGame> arcadeGamesOn(String islandSlug) => [
  for (final game in arcadeGames)
    if (game.island == islandSlug) game,
];

/// Ist das Spiel offen? Ja, sobald auf seiner Insel die Station
/// [ArcadeGame.afterStation] geschafft ist (Ankerplätze und Stopps zählen nicht).
bool arcadeUnlocked(ArcadeGame game, Iterable<StationInfo> stations, bool Function(StationInfo) done) {
  if (game.afterDive) {
    final dives = stations.where((s) => s.isDive).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return dives.isNotEmpty && done(dives.first);
  }
  return stations.any((s) => !s.isDive && !s.isSeaStop && s.displayNumber == game.afterStation && done(s));
}

/// Neue Runde des passenden Spiels.
ArcadeRound newArcadeRound(ArcadeKind kind, double width) => switch (kind) {
  ArcadeKind.gullFlight => GullFlightGame(width: width),
  ArcadeKind.crane => CraneGame(width: width),
  ArcadeKind.delivery => DeliveryGame(width: width),
  ArcadeKind.bottles => BottleGame(width: width),
  ArcadeKind.nutRun => NutRunGame(width: width),
  ArcadeKind.pearlDive => PearlDiveGame(width: width),
};
