import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/features/map/map_layout.dart';

void main() {
  // Die echten Positionen aus der Datenbank (content/stufe1).
  const positions = [
    (0.5, 0.96), (0.28, 0.9), (0.72, 0.84), (0.5, 0.765), (0.28, 0.7), //
    (0.72, 0.635), (0.5, 0.57), (0.28, 0.505), (0.72, 0.44), (0.5, 0.375),
    (0.28, 0.31), (0.72, 0.245), (0.5, 0.18), (0.28, 0.115), (0.72, 0.05),
  ];
  final islands = [
    for (final (i, (x, y)) in positions.indexed)
      MapIsland(id: 'i$i', slug: 's$i', title: 'Insel $i', sortOrder: i + 1, mapX: x, mapY: y, hasContent: i < 3),
  ];

  for (final width in [360.0, 390.0, 430.0, 820.0]) {
    test('Breite $width: Inseln passen auf den Bildschirm und überlappen nicht', () {
      final layout = MapLayout.compute(width: width, viewportHeight: 700, islands: islands);
      for (final island in islands) {
        final c = layout.centerOf(island.id);
        expect(c.dx - layout.islandWidth / 2, greaterThanOrEqualTo(0), reason: island.title);
        expect(c.dx + layout.islandWidth / 2, lessThanOrEqualTo(width), reason: island.title);
        expect(c.dy - layout.islandHeight / 2, greaterThanOrEqualTo(0), reason: island.title);
        expect(c.dy + layout.islandHeight / 2 + 40, lessThanOrEqualTo(layout.height), reason: island.title);
      }
      // Benachbarte Inseln der Route: Bild und Namensband der oberen enden
      // über dem Bild der unteren.
      for (var i = 0; i < islands.length - 1; i++) {
        final lower = layout.centerOf(islands[i].id), upper = layout.centerOf(islands[i + 1].id);
        expect(upper.dy + layout.islandHeight / 2 + 36, lessThan(lower.dy - layout.islandHeight / 2 + 1), reason: '$i');
      }
    });
  }

  test('Route führt vom Hafen zur Schatzinsel, Fahrt endet an den Ankerplätzen', () {
    final layout = MapLayout.compute(width: 390, viewportHeight: 700, islands: islands.reversed.toList());
    expect(layout.route.first.id, 'i0');
    expect(layout.route.last.id, 'i14');
    expect(layout.pointOn(0, 0), layout.centerOf('i0'));
    expect(layout.pointOn(0, 1), layout.centerOf('i1'));

    final start = layout.travel(0, 1, 0).position, end = layout.travel(0, 1, 1).position;
    expect((start - layout.shipAnchor('i0')).distance, lessThan(0.001));
    expect((end - layout.shipAnchor('i1')).distance, lessThan(0.001));
    // Vom Steg rechts am Hafen zur Tauschinsel (links): Das Schiff fährt nach links.
    expect(layout.travel(0, 1, 0.5).movingLeft, isTrue);
    // Von der Wunschinsel (rechts, Schiff links davon) zur Spar-Insel (Mitte, Schiff rechts).
    expect(layout.travel(2, 3, 0.5).movingLeft, isFalse);
    // Über zwei Inseln hinweg kommt es an der mittleren vorbei.
    final middle = layout.travel(0, 2, 0.5).position;
    expect((middle - layout.centerOf('i1')).distance, lessThan(layout.islandWidth));
  });

  test('Ankerplatz liegt neben der Insel, zur Kartenmitte hin', () {
    final layout = MapLayout.compute(width: 390, viewportHeight: 700, islands: islands);
    final left = layout.centerOf('i1'), right = layout.centerOf('i2'), middle = layout.centerOf('i0');
    expect(layout.shipAnchor('i1').dx, greaterThan(left.dx));
    expect(layout.shipAnchor('i2').dx, lessThan(right.dx));
    expect(layout.shipAnchor('i0').dx, greaterThan(middle.dx));
  });

  test('Scroll-Abstand zeigt eine Insel in der Mitte, ohne über den Rand zu gehen', () {
    final layout = MapLayout.compute(width: 390, viewportHeight: 700, islands: islands);
    expect(layout.offsetToShow(layout.height, 700), 0);
    expect(layout.offsetToShow(0, 700), layout.height - 700);
    final y = layout.centerOf('i5').dy;
    // Karte unten verankert: sichtbar ist [Höhe - Abstand - 700, Höhe - Abstand].
    final offset = layout.offsetToShow(y, 700);
    expect(layout.height - offset - 350, closeTo(y, 0.001));
  });
}
