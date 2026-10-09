import 'package:flutter/material.dart';

/// Farben der Welt von Taleria.
///
/// Alle Farben kommen aus dem Theme, nie fest aus einem Widget. So kann eine
/// spätere Stufe 2 ein anderes Aussehen bekommen, ohne den Code umzubauen.
@immutable
class TaleriaPalette extends ThemeExtension<TaleriaPalette> {
  const TaleriaPalette({
    required this.sea,
    required this.seaDeep,
    required this.sand,
    required this.gold,
    required this.coral,
    required this.ink,
    required this.paper,
    required this.talo,
    required this.tala,
    required this.taleron,
    required this.placeholderBorder,
    required this.success,
  });

  /// Palette für Stufe 1 (10 bis 14 Jahre): freundlich, aber nicht babyhaft.
  static const stage1 = TaleriaPalette(
    sea: Color(0xFF3E8FB0),
    seaDeep: Color(0xFF24476B),
    sand: Color(0xFFF3E3C3),
    gold: Color(0xFFD4A62A),
    coral: Color(0xFFE5675A),
    ink: Color(0xFF1C2B3A),
    paper: Color(0xFFFFFBF2),
    talo: Color(0xFFE8792B),
    tala: Color(0xFFF29CB7),
    taleron: Color(0xFF2E8B7A),
    placeholderBorder: Color(0xFF8A96A3),
    success: Color(0xFF2E8B57),
  );

  final Color sea;
  final Color seaDeep;
  final Color sand;
  final Color gold;
  final Color coral;
  final Color ink;
  final Color paper;

  /// Erkennungsfarben der Hauptfiguren (FIGUREN.md).
  final Color talo;
  final Color tala;
  final Color taleron;

  final Color placeholderBorder;

  /// Rückmeldung „richtig“ im Quiz.
  final Color success;

  @override
  TaleriaPalette copyWith({
    Color? sea,
    Color? seaDeep,
    Color? sand,
    Color? gold,
    Color? coral,
    Color? ink,
    Color? paper,
    Color? talo,
    Color? tala,
    Color? taleron,
    Color? placeholderBorder,
    Color? success,
  }) {
    return TaleriaPalette(
      sea: sea ?? this.sea,
      seaDeep: seaDeep ?? this.seaDeep,
      sand: sand ?? this.sand,
      gold: gold ?? this.gold,
      coral: coral ?? this.coral,
      ink: ink ?? this.ink,
      paper: paper ?? this.paper,
      talo: talo ?? this.talo,
      tala: tala ?? this.tala,
      taleron: taleron ?? this.taleron,
      placeholderBorder: placeholderBorder ?? this.placeholderBorder,
      success: success ?? this.success,
    );
  }

  @override
  TaleriaPalette lerp(TaleriaPalette? other, double t) {
    if (other == null) return this;
    return TaleriaPalette(
      sea: Color.lerp(sea, other.sea, t)!,
      seaDeep: Color.lerp(seaDeep, other.seaDeep, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      talo: Color.lerp(talo, other.talo, t)!,
      tala: Color.lerp(tala, other.tala, t)!,
      taleron: Color.lerp(taleron, other.taleron, t)!,
      placeholderBorder: Color.lerp(placeholderBorder, other.placeholderBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

extension TaleriaPaletteContext on BuildContext {
  TaleriaPalette get palette => Theme.of(this).extension<TaleriaPalette>() ?? TaleriaPalette.stage1;
}
