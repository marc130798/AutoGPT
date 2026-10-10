import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/assets/asset_manifest.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/features/island/island_scene.dart';

import '../fake_content.dart';
import '../test_helpers.dart';

void main() {
  test('Wegmarken liegen in gleichen Abständen auf dem Weg, vom Steg nach oben', () {
    const route = [Offset(0.5, 1), Offset(0.5, 0)];
    final spots = placeAlongRoute(route, 5, const Size(100, 200), from: 0, to: 1);
    expect(spots.map((s) => s.dy).toList(), [1, 0.75, 0.5, 0.25, 0]);
    expect(spots.every((s) => s.dx == 0.5), isTrue);
  });

  test('Abstände werden in Bildpunkten gemessen, nicht in Anteilen', () {
    // Erst 0,5 nach rechts (bei 400 Punkten Breite = 200), dann 0,5 nach oben (bei 200 Höhe = 100).
    const route = [Offset(0, 1), Offset(0.5, 1), Offset(0.5, 0.5)];
    final spots = placeAlongRoute(route, 4, const Size(400, 200), from: 0, to: 1);
    expect(spots[1].dx, closeTo(0.25, 1e-9));
    expect(spots[1].dy, closeTo(1, 1e-9));
    expect(spots[2].dx, closeTo(0.5, 1e-9));
    expect(spots[3], const Offset(0.5, 0.5));
  });

  test('Neben dem Weg: abwechselnd links und rechts, gleich weit entfernt', () {
    const route = [Offset(0.5, 1), Offset(0.5, 0)];
    const size = Size(200, 400);
    final spots = staggerBeside(placeAlongRoute(route, 4, size, from: 0, to: 1), size, 20);
    final xs = spots.map((s) => s.dx * size.width).toList();
    expect(xs[0], closeTo(120, 1e-9));
    expect(xs[1], closeTo(80, 1e-9));
    expect(xs[2], closeTo(120, 1e-9));
    expect(xs[3], closeTo(80, 1e-9));
  });

  test('Ohne Stationen keine Wegmarken, Standard-Weg führt von unten nach oben', () {
    expect(placeAlongRoute(defaultIslandRoute, 0, const Size(100, 100)), isEmpty);
    expect(defaultIslandRoute.first.dy, greaterThan(defaultIslandRoute.last.dy));
  });

  test('Hafen-Bild hat einen Weg im Manifest, Punkte von 0 bis 1', () {
    final route = realManifest().lookup('island.hafen.background').route!;
    expect(route.length, greaterThan(5));
    expect(route.every((p) => p.dx >= 0 && p.dx <= 1 && p.dy >= 0 && p.dy <= 1), isTrue);
    expect(route.first.dy, greaterThan(route.last.dy), reason: 'Start unten am Steg');
  });

  test('Ankerplätze liegen am Wasser, die anderen Stationen auf dem Weg', () {
    final content = FakeContent();
    final hafen = content.mapIslands.firstWhere((i) => i.slug == 'hafen');
    final stations = [...content.stations[hafen.id]!.where((s) => s.isRequired)]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final entry = realManifest().lookup('island.hafen.background');
    expect(entry.dives, hasLength(3));
    final dives = diveSpots(entry.dives, stations);
    final spots = placeStations(entry.route!, stations, const Size(390, 693), dives);
    final diveIndexes = [
      for (final (i, s) in stations.indexed)
        if (s.isDive) i,
    ];
    expect(diveIndexes, hasLength(3));
    expect([for (final i in diveIndexes) spots[i]], entry.dives, reason: 'am Strand, der Reihe nach');
    // Die anderen Stationen bleiben auf dem Weg, vom Steg nach oben.
    final path = [
      for (final (i, s) in stations.indexed)
        if (!s.isDive) spots[i].dy,
    ];
    expect(path, [...path]..sort((a, b) => b.compareTo(a)));
  });

  test('Ohne Stellen am Wasser liegen Ankerplätze auf dem Weg', () {
    final content = FakeContent();
    final hafen = content.mapIslands.firstWhere((i) => i.slug == 'hafen');
    final stations = content.stations[hafen.id]!.where((s) => s.isRequired).toList();
    expect(diveSpots(null, stations), isNull);
    expect(diveSpots(const [Offset(0.1, 0.5)], stations), isNull, reason: 'zu wenige Stellen');
    final spots = placeStations(defaultIslandRoute, stations, const Size(390, 693), null);
    expect(spots, hasLength(stations.length));
  });

  test('Jede Insel mit Bild hat genug Stellen am Wasser für ihre Ankerplätze', () {
    final content = FakeContent();
    final manifest = realManifest();
    for (final island in content.mapIslands) {
      final entry = manifest.lookup('island.${island.slug}.background');
      if (entry.path == null) continue;
      final dives = (content.stations[island.id] ?? const <StationInfo>[]).where((s) => s.isDive).length;
      expect(entry.dives?.length ?? 0, greaterThanOrEqualTo(dives), reason: island.slug);
    }
  });

  test('Kaputter Weg im Manifest wird mit Meldung abgelehnt', () {
    const source =
        '{"assets": {"island.x.background": {"type": "image", "path": "assets/images/x.png", '
        '"placeholder": {"label": "X", "color": "#112233"}, "route": [[0.5, 1.4], [0.2, 0.1]]}}}';
    expect(() => TaleriaAssetManifest.parse(source), throwsA(isA<AssetManifestException>()));
  });
}
