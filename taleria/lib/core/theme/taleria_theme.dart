import 'package:flutter/material.dart';

import 'taleria_palette.dart';
import 'wave_transition.dart';

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

/// Bildschirmwechsel mit einer Welle, auf allen Geräten gleich.
/// Gefüllte Knöpfe stehen etwas hervor und sinken beim Antippen ein wie ein
/// echter Knopf (Animationsplan, CLAUDE.md Abschnitt 11). Einmal angelegt,
/// damit zwei Themes gleich bleiben (sonst blendet die App sie ineinander).
final _waveTransitions = PageTransitionsTheme(
  builders: {for (final platform in TargetPlatform.values) platform: const WavePageTransitionsBuilder()},
);

final _pressElevation = WidgetStateProperty.resolveWith<double>(
  (states) => states.contains(WidgetState.disabled) || states.contains(WidgetState.pressed) ? 0 : 3,
);

ThemeData _buildTheme(TaleriaPalette palette) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: palette.sea,
    primary: palette.seaDeep,
    secondary: palette.gold,
    surface: palette.paper,
    error: palette.coral,
  );

  // Etwas größere Schrift, gut lesbar für 10-Jährige.
  // Roboto liegt in der App (pubspec.yaml); Pfeile kommen aus „TaleriaZeichen“.
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamilyFallback: const ['TaleriaZeichen'],
  );
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
    pageTransitionsTheme: _waveTransitions,
    appBarTheme: AppBarTheme(backgroundColor: palette.seaDeep, foregroundColor: palette.paper, centerTitle: true),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        backgroundColor: palette.seaDeep,
        foregroundColor: palette.paper,
        textStyle: textTheme.labelLarge,
        shadowColor: const Color(0x88081C30),
        animationDuration: const Duration(milliseconds: 90),
      ).copyWith(elevation: _pressElevation),
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
