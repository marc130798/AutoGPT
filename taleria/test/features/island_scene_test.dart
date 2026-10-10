import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/assets/asset_manifest.dart';
import 'package:taleria/features/island/island_scene.dart';

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

  test('Kaputter Weg im Manifest wird mit Meldung abgelehnt', () {
    const source =
        '{"assets": {"island.x.background": {"type": "image", "path": "assets/images/x.png", '
        '"placeholder": {"label": "X", "color": "#112233"}, "route": [[0.5, 1.4], [0.2, 0.1]]}}}';
    expect(() => TaleriaAssetManifest.parse(source), throwsA(isA<AssetManifestException>()));
  });
}
