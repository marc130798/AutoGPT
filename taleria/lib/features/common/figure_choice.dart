import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/avatar.dart';
import '../../l10n/app_localizations.dart';
import 'avatar_view.dart';

/// Wahl der eigenen Figur: Löwe oder Löwin, zwei große Karten mit Bild.
/// Im Intro und in der Werft (dort jederzeit umstellbar, nichts kostet etwas).
class FigureChoice extends StatelessWidget {
  const FigureChoice({super.key, required this.avatar, required this.onChoose, this.size = 140});

  final AvatarConfig avatar;
  final ValueChanged<PlayerFigure> onChoose;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Row(
      children: [
        for (final (i, figure) in PlayerFigure.values.indexed) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              button: true,
              selected: avatar.figure == figure,
              label: figure == PlayerFigure.lion ? l10n.figureLion : l10n.figureLioness,
              excludeSemantics: true,
              child: InkWell(
                key: ValueKey('figure-${figure.name}'),
                borderRadius: BorderRadius.circular(22),
                onTap: () => onChoose(figure),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: avatar.figure == figure
                        ? Color.alphaBlend(palette.gold.withValues(alpha: 0.22), palette.paper)
                        : palette.paper,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: avatar.figure == figure ? palette.gold : palette.ink.withValues(alpha: 0.15),
                      width: avatar.figure == figure ? 4 : 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      AvatarView(
                        avatar: avatar.copyWith(figure: figure),
                        pose: avatar.figure == figure ? CharacterPose.wave : null,
                        size: size,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        figure == PlayerFigure.lion ? l10n.figureLion : l10n.figureLioness,
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Wahl der Kleiderfarbe im Intro: alle Farben auf einmal, neutral, ohne
/// Einteilung nach Junge oder Mädchen (Marcs Wunsch am 17.11.2026). Später
/// lässt sich die Farbe in der Werft jederzeit ändern.
class ClothesStartChoice extends StatelessWidget {
  const ClothesStartChoice({super.key, required this.avatar, required this.onChoose});

  final AvatarConfig avatar;
  final ValueChanged<ClothesColor> onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in ClothesColor.values)
          Semantics(
            button: true,
            selected: avatar.clothes == c,
            label: l10n.lookName('clothes_${c.name}'),
            excludeSemantics: true,
            child: InkWell(
              key: ValueKey('clothes-${c.name}'),
              customBorder: const CircleBorder(),
              onTap: () => onChoose(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatar.clothes == c
                      ? Color.alphaBlend(palette.gold.withValues(alpha: 0.25), palette.paper)
                      : palette.paper,
                  border: Border.all(
                    color: avatar.clothes == c ? palette.gold : palette.ink.withValues(alpha: 0.15),
                    width: avatar.clothes == c ? 4 : 1.5,
                  ),
                ),
                child: StripeSwatch(color: clothesSwatch(c), size: 44),
              ),
            ),
          ),
      ],
    );
  }
}

/// Kleiner runder Farbpunkt mit weißen Streifen, wie das Shirt.
class StripeSwatch extends StatelessWidget {
  const StripeSwatch({super.key, required this.color, this.size = 34});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x33000000), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color, Colors.white, Colors.white, color, color, Colors.white, Colors.white, color, color],
          stops: const [0, 0.2, 0.2, 0.4, 0.4, 0.6, 0.6, 0.8, 0.8, 1],
        ),
      ),
    );
  }
}
