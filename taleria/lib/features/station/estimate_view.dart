import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'station_stage.dart';

/// Schätzfrage vor der Erklärung: „Was glaubst du?“ mit Schieberegler,
/// Zahlenrad oder Auswahl. Es gibt kein Richtig oder Falsch; die Auflösung
/// kommt am Ende der Bildergeschichte.
class EstimateView extends StatefulWidget {
  const EstimateView({super.key, required this.estimate, required this.onSubmit});

  final EstimateQuestion estimate;
  final ValueChanged<int> onSubmit;

  @override
  State<EstimateView> createState() => _EstimateViewState();
}

class _EstimateViewState extends State<EstimateView> {
  late int _value = widget.estimate.initial;
  late final FixedExtentScrollController _wheel = FixedExtentScrollController(
    initialItem: widget.estimate.isChoice ? 0 : widget.estimate.values.indexOf(widget.estimate.initial),
  );

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final e = widget.estimate;
    final chosen = !e.isChoice || _value >= 0;

    final Widget input = switch (e.kind) {
      'choice' => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, option) in e.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChoiceOption(
                key: ValueKey('estimate-option-$i'),
                text: option,
                selected: _value == i,
                onTap: () => setState(() => _value = i),
              ),
            ),
        ],
      ),
      'wheel' => OpenFrame(
        child: Column(
          children: [
            Text(l10n.estimateWheelHint, style: theme.textTheme.bodySmall),
            SizedBox(
              height: 168,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Markierung der gewählten Zahl.
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: palette.gold.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: palette.gold, width: 2),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    key: const ValueKey('estimate-wheel'),
                    controller: _wheel,
                    itemExtent: 48,
                    diameterRatio: 1.6,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => setState(() => _value = e.values[i]),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: e.values.length,
                      builder: (context, i) => Center(
                        child: Text(
                          e.display(e.values[i]),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: e.values[i] == _value ? FontWeight.w800 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      _ => OpenFrame(
        child: Column(
          children: [
            Text(
              e.display(_value),
              key: const ValueKey('estimate-value'),
              style: theme.textTheme.headlineMedium?.copyWith(color: palette.seaDeep, fontWeight: FontWeight.w800),
            ),
            Slider(
              key: const ValueKey('estimate-slider'),
              value: _value.toDouble(),
              min: e.min.toDouble(),
              max: e.max.toDouble(),
              divisions: (e.max - e.min) ~/ e.step,
              label: e.display(_value),
              onChanged: (v) => setState(() => _value = (v / e.step).round() * e.step),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.display(e.min), style: theme.textTheme.bodySmall),
                Text(e.display(e.max), style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    };

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OpenFrame(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  l10n.estimateBadge,
                  key: const ValueKey('estimate-badge'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(color: palette.coral, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              SpeechBubble.line(
                DialogLine(speaker: e.speaker, text: e.question),
                key: const ValueKey('estimate-question'),
              ),
              const SizedBox(height: 8),
              OpenFrame(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(l10n.estimateHint, style: theme.textTheme.bodySmall),
              ),
              const SizedBox(height: 16),
              input,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('estimate-submit'),
              onPressed: chosen ? () => widget.onSubmit(_value) : null,
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: Text(l10n.estimateSubmit),
            ),
          ),
        ),
      ],
    );
  }
}

/// Eine Möglichkeit bei der Schätzfrage: gewählt mit goldenem Rand, ohne Richtig oder Falsch.
class _ChoiceOption extends StatelessWidget {
  const _ChoiceOption({super.key, required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final paper = StagePanel.isOpen(context) ? GlassFrame.fill(context) : null;
    return PressDip(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: selected
              ? Color.alphaBlend(palette.gold.withValues(alpha: 0.35), paper ?? palette.paper)
              : paper,
          side: BorderSide(color: selected ? palette.gold : palette.seaDeep, width: selected ? 3 : 2),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: palette.seaDeep),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.ink,
                  fontWeight: selected ? FontWeight.w700 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
