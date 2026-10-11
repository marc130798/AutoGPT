import 'dart:math';
import 'dart:ui';

import '../../domain/content_models.dart';

/// Ein Liegeplatz des Schiffs: an einer Insel der Route oder an einem Stopp
/// auf See. [u] ist die Stelle auf der Route (Insel i = i, dazwischen
/// Bruchteile), [anchor] wo das Schiff dort liegt, [scale] seine Größe.
typedef ShipBerth = ({double u, Offset anchor, double scale});

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
    // Dazu Meer zwischen zwei Inseln für die Stopps auf See.
    final rowHeight = islandHeight * 1.12 + 56 + seaGap;
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

  /// Zusätzliches Meer zwischen zwei Inseln. Dort liegen die Stopps auf See
  /// versetzt übereinander (unten links, oben rechts), und unten rechts hat
  /// eine Begegnung auf See Platz (Meister Taleron).
  static const seaGap = 330.0;

  /// Größe einer Stopp-Marke mit Namen (wie `SeaStopMarker.labelWidth` und `.height`).
  static const seaStopWidth = 108.0;
  static const seaStopHeight = 100.0;

  /// So weit liegt die Mitte eines Stopps links oder rechts vom Weg.
  static const seaStopSide = 60.0;

  /// So weit ragen Inselbilder höchstens über ihr Feld hinaus (der Turm der
  /// Tauschinsel: Bild fast so hoch wie breit, Feld nur 0,62 so hoch).
  /// Stopps auf See halten diesen Abstand zur Insel darunter.
  double get artOverflow => islandWidth * 0.33;

  /// Platz unter jeder Insel für ihr Namensband (wie `MapIslandMarker.labelSpace`).
  static const islandLabelSpace = 40.0;

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

  /// So groß ist das Schiff, während es an einem Stopp auf See liegt.
  static const stopShipScale = 0.75;

  /// Liegeplatz des Schiffs an einer Insel der Route.
  ShipBerth islandBerth(String islandId) =>
      (u: max(0, routeIndexOf(islandId)).toDouble(), anchor: shipAnchor(islandId), scale: 1.0);

  /// Liegeplatz neben Stopp [k] von [count] vor Routen-Insel [index]: längsseits
  /// auf der Seite zum Weg hin (der erste Stopp liegt links vom Weg, das Schiff
  /// also rechts daneben; beim zweiten umgekehrt), auf Höhe seines Schiffs.
  ShipBerth stopBerth(int index, int count, int k) {
    final spot = seaStopSpots(index, count)[k];
    final size = shipSize * stopShipScale;
    final side = k.isEven ? 1.0 : -1.0;
    final x = (spot.dx + side * (seaStopWidth / 2 + size / 2 - 4)).clamp(size / 2, max(size / 2, width - size / 2));
    final lower = centerOf(route[index - 1].id), upper = centerOf(route[index].id);
    final t = lower.dy == upper.dy ? 0.5 : ((lower.dy - spot.dy) / (lower.dy - upper.dy)).clamp(0.0, 1.0);
    return (u: index - 1 + t, anchor: Offset(x.toDouble(), spot.dy + 6), scale: stopShipScale);
  }

  /// Wo das Schiff an [anchor] mit Größe [scale] zu sehen ist (für Abstände).
  Rect shipRect(Offset anchor, double scale) {
    final size = shipSize * scale;
    return Rect.fromLTWH(anchor.dx - size / 2, anchor.dy - size * 0.75, size, size);
  }

  /// Punkt auf der Route an der Stelle [u] (Insel i = i, dazwischen Bruchteile).
  Offset _routeAt(double u) {
    final seg = min(max(0, u.floor()), max(0, route.length - 2));
    return pointOn(seg, (u - seg).clamp(0.0, 1.0));
  }

  /// Schiff auf der Fahrt von Liegeplatz [from] nach [to], [t] von 0 bis 1. Es
  /// folgt der Route und gleitet dabei vom einen Liegeplatz zum anderen.
  ({Offset position, bool movingLeft, double scale}) sail(ShipBerth from, ShipBerth to, double t) {
    final offFrom = from.anchor - _routeAt(from.u), offTo = to.anchor - _routeAt(to.u);
    Offset at(double q) => _routeAt(from.u + (to.u - from.u) * q) + Offset.lerp(offFrom, offTo, q)!;
    final q = t.clamp(0.0, 1.0);
    // Blickrichtung für die ganze Fahrt gleich, damit das Schiff nicht hin und her springt.
    return (position: at(q), movingLeft: at(1).dx < at(0).dx, scale: from.scale + (to.scale - from.scale) * q);
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
  ({Offset position, bool movingLeft}) travel(int from, int to, double t) {
    final step = sail(islandBerth(route[from].id), islandBerth(route[to].id), t);
    return (position: step.position, movingLeft: step.movingLeft);
  }

  /// Freies Meer vor Routen-Insel [index]: von ihrem Namensband bis kurz über
  /// die Insel davor (`null` für die erste Insel).
  ({double top, double bottom})? _seaBand(int index) {
    if (index <= 0 || index >= route.length) return null;
    final lower = centerOf(route[index - 1].id), upper = centerOf(route[index].id);
    return (top: upper.dy + islandHeight / 2 + islandLabelSpace, bottom: lower.dy - islandHeight / 2 - artOverflow);
  }

  /// Wo die Route auf der Höhe [y] im Meer vor Routen-Insel [index] verläuft.
  double _routeX(int index, double y) {
    final lower = centerOf(route[index - 1].id), upper = centerOf(route[index].id);
    final t = lower.dy == upper.dy ? 0.5 : ((lower.dy - y) / (lower.dy - upper.dy)).clamp(0.0, 1.0);
    return pointOn(index - 1, t).dx;
  }

  /// Wo [count] Stopps auf See vor Routen-Insel [index] liegen: im Meer
  /// zwischen ihr und der Insel davor, abwechselnd links und rechts vom Weg.
  /// Der erste liegt unten links (er kommt auf der Fahrt zuerst), der zweite
  /// oben rechts. Neben dem ersten bleibt Platz für eine Begegnung auf See.
  /// Leer für die erste Insel.
  List<Offset> seaStopSpots(int index, int count) {
    final band = _seaBand(index);
    if (band == null || count <= 0) return const [];
    const margin = 56.0;
    final low = band.bottom - seaStopHeight / 2;
    final high = min(low, band.top + seaStopHeight / 2);
    double yOf(int k) => count == 1 ? low : low + (high - low) * k / (count - 1);
    return [
      for (var k = 0; k < count; k++)
        Offset(
          (_routeX(index, yOf(k)) + (k.isEven ? -seaStopSide : seaStopSide)).clamp(margin, max(margin, width - margin)),
          yOf(k),
        ),
    ];
  }

  /// Wo eine Begegnung auf See ([size] groß, linke obere Ecke) auftaucht,
  /// solange das Schiff an [islandId] liegt: im Meer davor, nie auf einer
  /// Insel, nie auf einem Stopp (siehe [seaStopSpots]) und nie auf dem, was in
  /// [avoid] liegt (zum Beispiel das Schiff an einem Stopp). Zuerst unten rechts
  /// neben dem ersten Stopp, sonst der nächste freie Platz neben einem Stopp
  /// oder dem Schiff, zuletzt zwischen den Stopps.
  /// Ohne nächste Insel neben dem Schiff, auf der Seite weg von der Insel.
  Offset encounterSpot(String islandId, Size size, {List<Rect> avoid = const []}) {
    Offset fit(Offset o) => Offset(o.dx.clamp(8.0, max(8.0, width - size.width - 8)), o.dy);
    final index = routeIndexOf(islandId) + 1;
    final band = _seaBand(index);
    if (band == null) {
      final anchor = shipAnchor(islandId);
      final outward = anchor.dx >= centerOf(islandId).dx;
      return fit(
        Offset(outward ? anchor.dx + shipSize / 2 : anchor.dx - shipSize / 2 - size.width, anchor.dy - size.height),
      );
    }
    // Höchstens zwei Stopps: der erste unten links, der zweite oben rechts.
    final stops = [
      for (final spot in seaStopSpots(index, 2))
        Rect.fromCenter(center: spot, width: seaStopWidth, height: seaStopHeight),
    ];
    final first = stops.first, second = stops.last;
    final low = max(band.top, band.bottom - size.height);
    final middle = (second.bottom + first.top) / 2;
    final blocked = [...stops, ...avoid];
    // Neben jedem Stopp und neben dem, was ausgewichen werden muss, jeweils
    // rechts und links, unten und oben; zuletzt zwischen den Stopps.
    final candidates = [
      for (final rect in [first, second, ...avoid])
        for (final y in [low, band.top]) ...[Offset(rect.right + 12, y), Offset(rect.left - 12 - size.width, y)],
      Offset(_routeX(index, middle) - size.width / 2, middle - size.height / 2),
    ];
    for (final candidate in candidates) {
      final box = fit(candidate) & size;
      if (box.top >= band.top - 0.5 && box.bottom <= band.bottom + 0.5 && !blocked.any(box.overlaps)) {
        return box.topLeft;
      }
    }
    return fit(candidates.first);
  }

  /// Scroll-Abstand (Karte unten verankert), bei dem [y] in der Mitte steht.
  double offsetToShow(double y, double viewportHeight) =>
      (height - y - viewportHeight / 2).clamp(0.0, max(0.0, height - viewportHeight));
}
