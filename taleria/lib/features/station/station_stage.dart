import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/asset_placeholder.dart';
import '../../core/assets/character_image.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/lively_figure.dart';
import '../common/figure_names.dart';
import '../common/fog_reveal.dart';
import 'figure_head.dart';

/// Hintergrund einer Station: das Bild der Insel von innen, beim Tauchgang
/// die Unterwasserwelt. Fehlt das Bild, ein Verlauf von Meer zu Sand.
class StationBackdrop extends StatelessWidget {
  const StationBackdrop({super.key, required this.assetKey, required this.child, this.lift = 0, this.faded = false});

  final String assetKey;
  final Widget child;

  /// Bild leicht verblasst (heller Schleier), zum Beispiel bei Gesprächen,
  /// damit die Sprechblasen hervortreten (Marcs Wunsch am 11.10.2026). Der
  /// Schleier blendet weich ein und aus.
  final bool faded;

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
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  key: const ValueKey('backdrop-veil'),
                  opacity: faded ? 1 : 0,
                  duration: const Duration(milliseconds: 350),
                  child: ColoredBox(color: palette.paper.withValues(alpha: 0.45)),
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

/// Bühne bei einem Stopp auf See: das Schiff der Figur auf dem Meer. Mit
/// [emerge] taucht es auf, sobald sich der Nebel lichtet (erste Szene).
class ShipStage extends StatelessWidget {
  const ShipStage(this.assetKey, {super.key, this.emerge = false});

  final String assetKey;
  final bool emerge;

  @override
  Widget build(BuildContext context) {
    final ship = TaleriaAsset(assetKey, key: const ValueKey('stop-ship'), alignment: Alignment.bottomCenter);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: emerge ? EmergeFromSea(child: ship) : ship,
    );
  }
}

/// Oben eine Bühne vor dem Hintergrund (zum Beispiel Figuren, die gerade
/// sprechen), darunter der Inhalt auf einem Blatt Papier. Ohne [stage] nur
/// das Papier. Mit [open] gibt es kein großes Blatt: Der Inhalt liegt direkt
/// vor dem Bild, und nur Text bekommt einen Rahmen ([GlassFrame],
/// [AnswerButton]). So sieht man mehr vom Bild (Marcs Wunsch am 11.10.2026:
/// erst unter Wasser, dann überall, wo ein Bild dahinter liegt).
class StagePanel extends StatelessWidget {
  const StagePanel({super.key, this.stage, required this.child, this.open = false});

  final Widget? stage;
  final Widget child;
  final bool open;

  /// Liegt der Inhalt ohne Blatt vor dem Bild? Dann rahmen Fragen, Gespräche
  /// und Knöpfe sich selbst ein.
  static bool isOpen(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_OpenPanel>() != null;

  /// Knöpfe ohne Blatt darunter: umrandete Knöpfe auf Papier, gesperrte gut lesbar.
  static ThemeData _openTheme(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final fill = GlassFrame.fill(context);
    return theme.copyWith(
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: (theme.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
          backgroundColor: WidgetStatePropertyAll(fill),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: (theme.textButtonTheme.style ?? const ButtonStyle()).copyWith(
          backgroundColor: WidgetStatePropertyAll(fill),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: (theme.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? fill : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? palette.ink.withValues(alpha: 0.45) : null,
          ),
        ),
      ),
    );
  }

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
            if (open)
              Expanded(
                child: _OpenPanel(
                  child: Theme(data: _openTheme(context), child: child),
                ),
              )
            else
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

/// Rahmt [child] nur ein, wenn kein Blatt darunter liegt ([StagePanel.open]);
/// auf dem Blatt bleibt es, wie es ist.
class OpenFrame extends StatelessWidget {
  const OpenFrame({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => StagePanel.isOpen(context) ? GlassFrame(padding: padding, child: child) : child;
}

/// Merkt für die Kinder eines [StagePanel] mit `open`, dass kein Blatt darunter liegt.
class _OpenPanel extends InheritedWidget {
  const _OpenPanel({required super.child});

  @override
  bool updateShouldNotify(_OpenPanel oldWidget) => false;
}

/// Wie eine Antwort nach dem Antippen aussieht.
enum AnswerMark { none, right, wrong }

/// Eine Antwort in Fragen, Wrack und Begegnungen. Nach dem Antippen ist die
/// richtige Antwort grün gefüllt mit Haken und die falsch gewählte rot mit
/// Kreuz (Marcs Wunsch am 11.10.2026, damit man es besser erkennt). Ohne Blatt
/// darunter ([StagePanel.open]) liegt jede Antwort auf Papier.
class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.text,
    this.mark = AnswerMark.none,
    this.onPressed,
    this.icon,
    this.center = false,
  });

  final String text;
  final AnswerMark mark;
  final VoidCallback? onPressed;

  /// Vor der Antwort, zum Beispiel ein Fisch beim Fischschwarm.
  final IconData? icon;

  /// Text in der Mitte (Körbe und Möglichkeiten in Übungen).
  final bool center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final color = switch (mark) {
      AnswerMark.right => palette.success,
      AnswerMark.wrong => palette.coral,
      AnswerMark.none => null,
    };
    final paper = StagePanel.isOpen(context) ? GlassFrame.fill(context) : null;
    final fill = color == null ? paper : Color.alphaBlend(color.withValues(alpha: 0.38), paper ?? palette.paper);
    final markIcon = switch (mark) {
      AnswerMark.right => Icons.check_circle_rounded,
      AnswerMark.wrong => Icons.cancel_rounded,
      AnswerMark.none => null,
    };
    // Ist die Antwort der Name einer Inselfigur, zeigt der Knopf ihr Gesicht und das Tier.
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final figure = l10n == null ? null : figureNamed(l10n, text);
    return _MarkMotion(
      mark: mark,
      child: PressDip(
        enabled: onPressed != null,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: fill,
            disabledBackgroundColor: fill,
            side: BorderSide(color: color ?? palette.seaDeep, width: color == null ? 2 : 3),
          ),
          onPressed: onPressed,
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon, color: color ?? palette.sea), const SizedBox(width: 12)],
              if (figure != null) ...[FigureHead(figure, size: 44), const SizedBox(width: 12)],
              Expanded(
                child: Text(
                  figure == null ? text : figureLabel(l10n!, figure, text),
                  textAlign: center ? TextAlign.center : null,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: palette.ink,
                    fontWeight: color == null ? null : FontWeight.w700,
                  ),
                ),
              ),
              if (markIcon != null) ...[const SizedBox(width: 8), Icon(markIcon, color: color, size: 28)],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ein Knopf gibt beim Antippen leicht nach wie ein echter Knopf: Solange der
/// Finger drauf ist, ist er ein kleines Stück kleiner (Animationsplan).
class PressDip extends StatefulWidget {
  const PressDip({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressDip> createState() => _PressDipState();
}

class _PressDipState extends State<PressDip> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled ? (_) => _set(true) : null,
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 90),
      child: widget.child,
    ),
  );
}

/// Bewegung, sobald eine Antwort markiert wird: richtig springt kurz hoch,
/// falsch wackelt leicht hin und her (ohne Alarm). Bei „Bewegung reduzieren“
/// bleibt es ruhig.
class _MarkMotion extends StatefulWidget {
  const _MarkMotion({required this.mark, required this.child});

  final AnswerMark mark;
  final Widget child;

  @override
  State<_MarkMotion> createState() => _MarkMotionState();
}

class _MarkMotionState extends State<_MarkMotion> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(_MarkMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    final marked = oldWidget.mark == AnswerMark.none && widget.mark != AnswerMark.none;
    if (marked && !MediaQuery.disableAnimationsOf(context)) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final t = _controller.value;
      if (!_controller.isAnimating || t == 0) return child!;
      final offset = widget.mark == AnswerMark.wrong
          ? Offset(sin(t * 3 * 2 * pi) * 7 * (1 - t), 0)
          : Offset(0, -sin(t * pi) * 8);
      return Transform.translate(offset: offset, child: child);
    },
  );
}

/// Rahmen um Frage, Rückmeldung oder Überschrift, wenn kein großes Blatt
/// darunter liegt ([StagePanel.open]): Papier nur dort, wo Text steht,
/// dazwischen sieht man das Bild (Marcs Wunsch am 11.10.2026 für die Tauchgänge).
class GlassFrame extends StatelessWidget {
  const GlassFrame({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Füllung für Antwort-Knöpfe ohne Papier darunter.
  static Color fill(BuildContext context) => context.palette.paper.withValues(alpha: 0.93);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2C27A), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x44081C30), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: child,
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
            for (final (i, figure) in figures.indexed)
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
                    child: Breathing(
                      phase: i * 0.37,
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
                            width: min(height * 0.6, width),
                            height: min(height * 0.6, width),
                          ),
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
