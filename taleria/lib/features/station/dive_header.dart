import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';

/// Spielarten des Tauchgangs (CLAUDE.md Abschnitt 8). Die Fragen sind dieselben,
/// nur die Unterwasserwelt drumherum wechselt.
enum DiveGame {
  pearls,
  treasureChest,
  fishSwarm;

  /// Aus `content.dive.game`. Muscheln zählen und Unbekanntes zeigen das Perlentauchen.
  static DiveGame parse(String? code) => switch (code) {
    'treasure_chest' => DiveGame.treasureChest,
    'fish_swarm' => DiveGame.fishSwarm,
    _ => DiveGame.pearls,
  };

  String title(AppLocalizations l10n) => switch (this) {
    DiveGame.pearls => l10n.diveTitle,
    DiveGame.treasureChest => l10n.diveChestTitle,
    DiveGame.fishSwarm => l10n.diveFishTitle,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    DiveGame.pearls => l10n.diveHint,
    DiveGame.treasureChest => l10n.diveChestHint,
    DiveGame.fishSwarm => l10n.diveFishHint,
  };

  /// Beim Fischschwarm trägt jede Antwort einen Fisch.
  IconData? get answerIcon => this == DiveGame.fishSwarm ? Icons.set_meal_outlined : null;
}

/// Ziffern des Zahlenschlosses, fest pro Ankerplatz.
List<int> chestCode(String stationId, int length) {
  var seed = 0;
  for (final c in stationId.codeUnits) {
    seed = (seed * 31 + c) & 0x7fffffff;
  }
  return [for (var i = 0; i < length; i++) (seed ~/ _pow10(i)) % 10];
}

int _pow10(int i) {
  var v = 1;
  for (var k = 0; k < i; k++) {
    v *= 10;
  }
  return v;
}

/// Über den Fragen: gesammelte Perlen oder das Zahlenschloss der Truhe.
class DiveHeader extends StatelessWidget {
  const DiveHeader({super.key, required this.game, required this.results, required this.stationId});

  final DiveGame game;

  /// Pro Frage: richtig, falsch oder noch offen (`null`).
  final List<bool?> results;
  final String stationId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final theme = Theme.of(context);
    switch (game) {
      case DiveGame.pearls || DiveGame.fishSwarm:
        return Row(
          key: const ValueKey('dive-pearls'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gefundene Perlen glänzen, offene sind ein leerer Kreis.
            for (final r in results)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: r == true ? const _Pearl() : Icon(Icons.circle_outlined, color: palette.placeholderBorder),
                ),
              ),
          ],
        );
      case DiveGame.treasureChest:
        final code = chestCode(stationId, results.length);
        final open = results.every((r) => r != null);
        return Column(
          key: const ValueKey('dive-chest'),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(open ? Icons.lock_open : Icons.lock, color: palette.gold),
                const SizedBox(width: 8),
                for (final (i, r) in results.indexed)
                  Container(
                    width: 36,
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: r == null ? palette.sand : palette.paper,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.seaDeep, width: 2),
                    ),
                    child: Text(r == null ? '?' : '${code[i]}', style: theme.textTheme.titleLarge),
                  ),
              ],
            ),
            if (open) ...[
              const SizedBox(height: 4),
              Text(l10n.diveChestOpen, style: theme.textTheme.titleMedium?.copyWith(color: palette.gold)),
            ],
          ],
        );
    }
  }
}

/// Eine schimmernde Perle: weiß mit hellem Glanzpunkt und zartem Rosa am Rand.
class _Pearl extends StatelessWidget {
  const _Pearl();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        key: const ValueKey('pearl-found'),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.35, -0.4),
            radius: 0.9,
            colors: [Colors.white, Color(0xFFF4EEF0), Color(0xFFD9C8D2)],
            stops: [0, 0.45, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: context.palette.seaDeep.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
