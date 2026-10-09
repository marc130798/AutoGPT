import 'package:flutter/services.dart';

/// Ab dieser kürzeren Bildschirmseite (in logischen Punkten) gilt ein Gerät
/// als Tablet. Übliche Grenze in Flutter und Android.
const double tabletShortestSide = 600;

/// Smartphones: nur Hochformat (entschieden, CLAUDE.md Abschnitt 11).
/// Tablets: Hochformat als Hauptlayout, Querformat zusätzlich.
List<DeviceOrientation> allowedOrientations(double shortestSide) {
  if (shortestSide >= tabletShortestSide) {
    return const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ];
  }
  return const [DeviceOrientation.portraitUp];
}
