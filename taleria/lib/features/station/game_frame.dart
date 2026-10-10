import 'package:flutter/material.dart';

import '../../domain/content_models.dart';

/// Gemeinsamer Rahmen aller Mini-Spiele: Titel, Aufgabe, Inhalt, Knopf unten.
class GameFrame extends StatelessWidget {
  const GameFrame({super.key, required this.game, required this.children, required this.button});

  final GameInfo game;
  final List<Widget> children;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(game.title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              if (game.task != null) ...[
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
