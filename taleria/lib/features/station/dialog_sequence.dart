import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/sounds.dart';
import '../common/wood_sign.dart';
import '../intro/speech_bubble.dart';
import 'station_stage.dart';

/// Zeigt Dialogzeilen nacheinander. „Weiter“ blendet die nächste Zeile ein,
/// nach der letzten ruft der Knopf [onDone] auf.
///
/// Mit [stage] steht die Figur, die spricht, groß vor dem Hintergrund und
/// das Gespräch liegt direkt darunter ohne Blatt ([StagePanel] mit `open`).
/// [title] ist der Ort, als Holzschild oben.
class DialogSequence extends StatefulWidget {
  const DialogSequence({
    super.key,
    required this.lines,
    required this.onDone,
    this.title,
    this.doneLabel,
    this.stage = false,
    this.voicePrefix,
  });

  final List<DialogLine> lines;
  final VoidCallback onDone;
  final String? title;

  /// Beschriftung des letzten Knopfs, Standard „Weiter“.
  final String? doneLabel;

  /// Figuren auf einer Bühne über dem Gespräch zeigen.
  final bool stage;

  /// Anfang der Sprachaufnahmen, zum Beispiel `voice.hafen.2.szene.`: Jede
  /// neue Zeile wird vorgelesen (`<prefix><nr>.mp3`, Nummer ab 1). Zeilen
  /// ohne Aufnahme bleiben still.
  final String? voicePrefix;

  @override
  State<DialogSequence> createState() => _DialogSequenceState();
}

class _DialogSequenceState extends State<DialogSequence> {
  int _shown = 1;
  Sounds? _sounds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final first = _sounds == null;
    _sounds = AppScope.of(context).sounds;
    if (first) WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  void _speak() {
    final prefix = widget.voicePrefix;
    if (prefix == null || !mounted) return;
    _sounds?.voice('$prefix$_shown.mp3');
  }

  void _more() {
    setState(() => _shown++);
    _speak();
  }

  void _done() {
    if (widget.voicePrefix != null) _sounds?.stopVoice();
    widget.onDone();
  }

  @override
  void dispose() {
    if (widget.voicePrefix != null) _sounds?.stopVoice();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lines = widget.lines;
    final last = _shown >= lines.length;
    final bubbles = [
      for (final line in lines.take(_shown))
        Padding(padding: const EdgeInsets.only(bottom: 16), child: SpeechBubble.line(line)),
    ];
    final sign = widget.title == null
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Center(child: WoodSign(text: widget.title!)),
          );
    final button = Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: last
            ? FilledButton(onPressed: _done, child: Text(widget.doneLabel ?? l10n.introNext))
            : OutlinedButton(onPressed: _more, child: Text(l10n.introNext)),
      ),
    );

    if (!widget.stage) {
      return Column(
        children: [
          ?sign,
          Expanded(
            child: ListView(reverse: true, padding: const EdgeInsets.all(16), children: bubbles.reversed.toList()),
          ),
          button,
        ],
      );
    }

    // Mit Bühne: Ortsschild oben, die Figur so groß wie Platz ist und direkt
    // darunter die Sprechblasen, damit keine leere Fläche dazwischen bleibt
    // (Marcs Wunsch am 20.10.2026). Bei vielen Zeilen scrollen nur die Blasen.
    return StagePanel(
      open: true,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            ?sign,
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: min(300, constraints.maxHeight * 0.42)),
                  child: Padding(padding: const EdgeInsets.only(top: 8), child: dialogStage(lines, _shown)),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.5),
              child: SingleChildScrollView(
                key: const ValueKey('dialog-bubbles'),
                reverse: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(mainAxisSize: MainAxisSize.min, children: bubbles),
              ),
            ),
            button,
          ],
        ),
      ),
    );
  }
}
