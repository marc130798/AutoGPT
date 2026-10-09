import 'package:flutter/material.dart';

import 'taleria_palette.dart';

/// Mindestgröße für alles, was man antippen kann (CLAUDE.md Abschnitt 11).
const double minTapTarget = 48;

/// Liefert das Aussehen passend zur Stufe des Kindes.
///
/// Gebaut wird nur Stufe 1. Für jede andere Stufe gibt es bis auf Weiteres
/// ebenfalls das Stufe-1-Theme. Eine spätere Stufe 2 bekommt hier ein eigenes.
ThemeData taleriaThemeForStage(int stage) {
  return switch (stage) {
    _ => _buildTheme(TaleriaPalette.stage1),
  };
}

ThemeData _buildTheme(TaleriaPalette palette) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: palette.sea,
    primary: palette.seaDeep,
    secondary: palette.gold,
    surface: palette.paper,
    error: palette.coral,
  );

  // Etwas größere Schrift, gut lesbar für 10-Jährige.
  final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
  final textTheme = base.textTheme
      .copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.4),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.4),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      )
      .apply(bodyColor: palette.ink, displayColor: palette.ink);

  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  const buttonSize = Size(minTapTarget * 2, minTapTarget);

  return base.copyWith(
    scaffoldBackgroundColor: palette.paper,
    textTheme: textTheme,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: [palette],
    appBarTheme: AppBarTheme(backgroundColor: palette.seaDeep, foregroundColor: palette.paper, centerTitle: true),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        backgroundColor: palette.seaDeep,
        foregroundColor: palette.paper,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        foregroundColor: palette.seaDeep,
        side: BorderSide(color: palette.seaDeep, width: 2),
        textStyle: textTheme.labelLarge,
      ),
    ),
  );
}
