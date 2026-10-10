import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';

/// Lautsprecher-Knopf auf der Startseite: schaltet Musik und Töne an oder
/// aus (gilt für dieses Gerät).
class SoundButton extends StatelessWidget {
  const SoundButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final sounds = AppScope.of(context).sounds;
    return ListenableBuilder(
      listenable: sounds,
      builder: (context, _) {
        final on = sounds.enabled;
        return DeckRoundButton(
          key: const ValueKey('sound-toggle'),
          icon: on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          iconColor: on ? palette.seaDeep : palette.placeholderBorder,
          label: on ? l10n.soundOnLabel : l10n.soundOffLabel,
          tooltip: on ? l10n.soundTurnOff : l10n.soundTurnOn,
          toggled: on,
          onTap: () => sounds.setEnabled(!on),
        );
      },
    );
  }
}

/// Runder Knopf oben auf der Startseite (Messingrand, Papier) mit kurzer
/// Beschriftung darunter, zum Beispiel „Ton an“ oder „Was ist wo?“.
class DeckRoundButton extends StatelessWidget {
  const DeckRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
    this.toggled,
  });

  final IconData icon;
  final String label;

  /// Vorlesetext und Hinweis beim langen Drücken.
  final String tooltip;
  final VoidCallback onTap;
  final Color? iconColor;

  /// Für Schalter (an oder aus), sonst `null`.
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        toggled: toggled,
        label: tooltip,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(top: 6, bottom: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.paper.withValues(alpha: 0.92),
                    border: Border.all(color: const Color(0xFFB8862B), width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x44081C30), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Icon(icon, size: 30, color: iconColor ?? palette.seaDeep),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.paper.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w800, color: palette.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
