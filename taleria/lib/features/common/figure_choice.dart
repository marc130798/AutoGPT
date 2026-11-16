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
                    color: avatar.figure == figure ? palette.gold.withValues(alpha: 0.22) : palette.paper,
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
