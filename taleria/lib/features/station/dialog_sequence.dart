import 'package:flutter/material.dart';

import '../../domain/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';

/// Zeigt Dialogzeilen nacheinander. „Weiter“ blendet die nächste Zeile ein,
/// nach der letzten ruft der Knopf [onDone] auf.
class DialogSequence extends StatefulWidget {
  const DialogSequence({super.key, required this.lines, required this.onDone, this.title, this.doneLabel});

  final List<DialogLine> lines;
  final VoidCallback onDone;
  final String? title;

  /// Beschriftung des letzten Knopfs, Standard „Weiter“.
  final String? doneLabel;

  @override
  State<DialogSequence> createState() => _DialogSequenceState();
}

class _DialogSequenceState extends State<DialogSequence> {
  int _shown = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lines = widget.lines;
    final last = _shown >= lines.length;

    return Column(
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(widget.title!, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          ),
        Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.all(16),
            children: [
              for (final line in lines.take(_shown).toList().reversed)
                Padding(padding: const EdgeInsets.only(bottom: 16), child: SpeechBubble.line(line)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: last
                ? FilledButton(onPressed: widget.onDone, child: Text(widget.doneLabel ?? l10n.introNext))
                : OutlinedButton(onPressed: () => setState(() => _shown++), child: Text(l10n.introNext)),
          ),
        ),
      ],
    );
  }
}
