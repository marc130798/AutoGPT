import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../l10n/app_localizations.dart';

/// Gemeinsamer Rahmen aller Mini-Spiele: Titel, Aufgabe, Inhalt, Knopf unten.
/// Übungen (Tipp-Aufgaben) tragen oben das Schild „Übung“; bei echten Spielen
/// steht die Aufgabe schon auf dem Startbild.
class GameFrame extends StatelessWidget {
  const GameFrame({super.key, required this.game, required this.children, required this.button});

  final GameInfo game;
  final List<Widget> children;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Übungen tragen neben dem Titel das Schild „Übung“.
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  if (!game.isRealGame)
                    Container(
                      key: const ValueKey('practice-label'),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: palette.sand, borderRadius: BorderRadius.circular(12)),
                      child: Text(AppLocalizations.of(context).practiceLabel, style: theme.textTheme.labelMedium),
                    ),
                  Text(game.title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                ],
              ),
              if (game.task != null && !game.isRealGame) ...[
                const SizedBox(height: 4),
                Text(game.task!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, child: button),
        ),
      ],
    );
  }
}
