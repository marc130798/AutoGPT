import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/asset_placeholder.dart';
import '../../core/assets/character_image.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';

/// Hintergrund einer Station: das Bild der Insel von innen, beim Tauchgang
/// die Unterwasserwelt. Fehlt das Bild, ein Verlauf von Meer zu Sand.
class StationBackdrop extends StatelessWidget {
  const StationBackdrop({super.key, required this.assetKey, required this.child, this.lift = 0});

  final String assetKey;
  final Widget child;

  /// Um diesen Anteil der Höhe nach oben geschoben (und größer gezeigt), damit
  /// oben auf der Bühne etwas aus der Bildmitte zu sehen ist, zum Beispiel das
  /// Wrack statt nur Sonnenstrahlen.
  final double lift;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final shift = constraints.maxHeight * lift;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: -shift,
              height: constraints.maxHeight + shift,
              child: TaleriaAsset(
                assetKey,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.3),
                fallback: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [palette.sea, palette.sand],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: child),
          ],
        );
      },
    );
  }
}

/// Oben eine Bühne vor dem Hintergrund (zum Beispiel Figuren, die gerade
/// sprechen), darunter der Inhalt auf einem Blatt Papier. Ohne [stage] nur
/// das Papier.
class StagePanel extends StatelessWidget {
  const StagePanel({super.key, this.stage, required this.child});

  final Widget? stage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Etwa ein Viertel der Höhe, auf kleinen Bildschirmen weniger.
        final stageHeight = (constraints.maxHeight * 0.24).clamp(0.0, 180.0);
        return Column(
          children: [
            if (stage != null)
              SizedBox(
                height: stageHeight,
                width: double.infinity,
                child: Padding(padding: const EdgeInsets.only(top: 8), child: stage),
              ),
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(10, stage == null ? 10 : 0, 10, 10),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: palette.paper.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2C27A), width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x55081C30), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Eine Figur auf der Bühne: Schlüssel (zum Beispiel `character.olga`), bei
/// Talo und Tala auf Wunsch eine Pose. Die gerade aktive Figur ist größer.
class StageFigure {
  const StageFigure(this.character, {this.pose, this.active = true});

  final String character;
  final CharacterPose? pose;
  final bool active;
}

/// Figuren nebeneinander, mit den Füßen unten auf der Bühne.
class FigureStage extends StatelessWidget {
  const FigureStage({super.key, required this.figures});

  final List<StageFigure> figures;

  @override
  Widget build(BuildContext context) {
    final manifest = AppScope.of(context).manifest;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        // Bei mehreren Figuren und schmalem Bildschirm etwas schmaler, nie breiter als Platz ist.
        final width = figures.isEmpty
            ? 0.0
            : (height * 0.8).clamp(0.0, (constraints.maxWidth - 16) / figures.length - 12).toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final figure in figures)
              Padding(
                key: ValueKey('stage-${figure.character}'),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: AnimatedScale(
                  scale: figure.active ? 1 : 0.8,
                  alignment: Alignment.bottomCenter,
                  duration: const Duration(milliseconds: 250),
                  child: AnimatedOpacity(
                    opacity: figure.active ? 1 : 0.85,
                    duration: const Duration(milliseconds: 250),
                    child: CharacterImage(
                      figure.character,
                      pose: figure.pose,
                      width: width,
                      height: height,
                      alignment: Alignment.bottomCenter,
                      fallback: Align(
                        alignment: Alignment.bottomCenter,
                        child: AssetPlaceholder(
                          entry: manifest.lookup(figure.character),
                          width: height * 0.6,
                          height: height * 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Bühne zu einem Gespräch: wer schon gesprochen hat, steht da (höchstens
/// drei, die zuletzt sprachen), wer gerade spricht, ist vorn. Talo und Tala
/// winken bei der ersten Zeile.
FigureStage dialogStage(List<DialogLine> lines, int shown) {
  final visible = lines.take(shown).toList();
  if (visible.isEmpty) return const FigureStage(figures: []);
  final current = visible.last.speaker;
  // Zuletzt gesprochen zuerst, jede Figur einmal.
  final recent = <String>[];
  for (final line in visible.reversed) {
    if (!recent.contains(line.speaker)) recent.add(line.speaker);
    if (recent.length == 3) break;
  }
  // Auf der Bühne in der Reihenfolge, in der sie dazukamen.
  final order = <String>{for (final line in visible) line.speaker}.where(recent.contains).toList();
  return FigureStage(
    figures: [
      for (final speaker in order)
        StageFigure(
          'character.$speaker',
          pose: speaker == current && shown == 1 ? CharacterPose.wave : null,
          active: speaker == current,
        ),
    ],
  );
}

/// Bühne bei einer Frage: Talo denkt nach, Tala hört zu. Nach einer richtigen
/// Antwort freuen sich beide.
FigureStage quizStage({required bool answered, required bool correct}) {
  final happy = answered && correct;
  return FigureStage(
    figures: [
      StageFigure(AssetKeys.talo, pose: happy ? CharacterPose.happy : CharacterPose.think),
      StageFigure(AssetKeys.tala, pose: happy ? CharacterPose.happy : CharacterPose.think, active: happy),
    ],
  );
}
