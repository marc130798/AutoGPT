import 'dart:math';
import 'dart:ui';

import '../../domain/content_models.dart';

/// Wo Inseln, Route und Schiff auf der Karte liegen. Reine Rechnung ohne
/// Aussehen, damit sie sich testen lässt.
///
/// Die Inselbilder sind breiter als hoch (Blick schräg von oben, BILDER.md),
/// deshalb hat jede Insel ein Feld von [islandWidth] × [islandHeight].
class MapLayout {
  MapLayout._({
    required this.width,
    required this.height,
    required this.islandWidth,
    required this.islandHeight,
    required this._centers,
    required this.route,
  });

  factory MapLayout.compute({required double width, required double viewportHeight, required List<MapIsland> islands}) {
    final islandWidth = (width * 0.56).clamp(170.0, 300.0);
    final islandHeight = islandWidth * artAspect;
    // Pro Insel: das Bild, darunter das Namensband und etwas Meer. Die Inseln
    // liegen in der Datenbank etwas enger als eine Zeile (0,06 bis 0,065 von
    // 15), deshalb der Zuschlag.
    final rowHeight = islandHeight * 1.12 + 56;
    final top = islandHeight * 0.75 + 24;
    final bottom = islandHeight * 0.5 + 64;
    final height = max(viewportHeight, max(1, islands.length) * rowHeight + top + bottom);
    final minX = islandWidth / 2 + 4;
    final maxX = max(minX, width - islandWidth / 2 - 4);
    final centers = {
      for (final island in islands)
        island.id: Offset((island.mapX * width).clamp(minX, maxX), top + island.mapY * (height - top - bottom)),
    };
    final route = [...islands.where((i) => i.isMainRoute)]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return MapLayout._(
      width: width,
      height: height,
      islandWidth: islandWidth,
      islandHeight: islandHeight,
      centers: centers,
      route: route,
    );
  }

  /// Höhe zu Breite eines Inselbilds.
  static const artAspect = 0.62;

  final double width;
  final double height;
  final double islandWidth;
  final double islandHeight;
  final Map<String, Offset> _centers;

  /// Inseln der Hauptroute in Fahrtrichtung (Hafen zuerst).
  final List<MapIsland> route;

  double get shipSize => islandWidth * 0.42;

  Offset centerOf(String islandId) => _centers[islandId] ?? Offset(width / 2, height / 2);

  /// Stelle einer Insel auf der Route (`-1`, wenn sie nicht dazugehört).
  int routeIndexOf(String? islandId) => route.indexWhere((i) => i.id == islandId);

  /// Kurve von Routen-Insel [index] zur nächsten als kubische Bézierkurve
  /// (Catmull-Rom durch die Inselmitten, damit die Route weich schwingt).
  List<Offset> segment(int index) {
    Offset at(int i) => centerOf(route[i.clamp(0, route.length - 1)].id);
    final p0 = at(index - 1), p1 = at(index), p2 = at(index + 1), p3 = at(index + 2);
    return [p1, p1 + (p2 - p0) / 6, p2 - (p3 - p1) / 6, p2];
  }

  Offset pointOn(int index, double t) {
    final s = segment(index);
    final u = 1 - t;
    return s[0] * (u * u * u) + s[1] * (3 * u * u * t) + s[2] * (3 * u * t * t) + s[3] * (t * t * t);
  }

  /// Wo das Schiff neben einer Insel ankert: auf der Seite zur Kartenmitte,
  /// bei Inseln in der Mitte rechts (dort liegt beim Hafen der Steg).
  Offset shipAnchor(String islandId) {
    final c = centerOf(islandId);
    final side = c.dx > width / 2 + 1 ? -1.0 : 1.0;
    final x = (c.dx + side * islandWidth * 0.55)
        .clamp(shipSize / 2, max(shipSize / 2, width - shipSize / 2))
        .toDouble();
    return Offset(x, c.dy + islandHeight * 0.2);
  }

  /// Schiff auf der Fahrt von Routen-Insel [from] nach [to], [t] von 0 bis 1.
  /// Es folgt der Route und gleitet dabei vom einen Ankerplatz zum anderen.
  ({Offset position, bool movingLeft}) travel(int from, int to, double t) {
    Offset at(double q) {
      final steps = max(1, to - from);
      final scaled = (q.clamp(0.0, 1.0) * steps);
      final k = min(steps - 1, scaled.floor());
      final local = scaled - k;
      final onRoute = pointOn(from + k, local);
      final offFrom = shipAnchor(route[from].id) - centerOf(route[from].id);
      final offTo = shipAnchor(route[to].id) - centerOf(route[to].id);
      return onRoute + Offset.lerp(offFrom, offTo, q.clamp(0.0, 1.0))!;
    }

    // Blickrichtung für die ganze Fahrt gleich, damit das Schiff nicht hin und her springt.
    return (position: at(t), movingLeft: at(1).dx < at(0).dx);
  }

  /// Scroll-Abstand (Karte unten verankert), bei dem [y] in der Mitte steht.
  double offsetToShow(double y, double viewportHeight) =>
      (height - y - viewportHeight / 2).clamp(0.0, max(0.0, height - viewportHeight));
}
