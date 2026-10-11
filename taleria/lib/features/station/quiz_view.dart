import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';
import '../../services/station_controller.dart';
import 'station_stage.dart';

/// Eine Frage mit drei Antworten. Nach dem Tipp: richtig oder nicht,
/// dazu die Erklärung von Talo oder Tala. Falsche Antworten kosten nichts.
/// Nach dem Tipp rollt die Liste so weit, dass die Rückmeldung zu sehen ist.
class QuizView extends StatefulWidget {
  const QuizView({
    super.key,
    required this.run,
    required this.title,
    required this.onAnswer,
    required this.onNext,
    this.hint,
    this.header,
    this.answerIcon,
    this.framed = false,
  });

  final QuizRun run;
  final String title;
  final String? hint;

  /// Über der Frage, zum Beispiel Perlen oder das Zahlenschloss beim Tauchgang.
  final Widget? header;

  /// Vor jeder Antwort, zum Beispiel ein Fisch beim Fischschwarm.
  final IconData? answerIcon;

  /// Ohne großes Blatt darunter (Tauchgang): Frage, Antworten und
  /// Rückmeldung bekommen je einen eigenen Rahmen ([GlassFrame]).
  final bool framed;
  final ValueChanged<int> onAnswer;
  final VoidCallback onNext;

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  final _feedbackKey = GlobalKey();

  /// Frage, zu deren Rückmeldung schon gerollt wurde.
  int? _shownFeedbackFor;

  void _revealFeedback() {
    if (_shownFeedbackFor == widget.run.index) return;
    _shownFeedbackFor = widget.run.index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _feedbackKey.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(
        target,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final run = widget.run;
    final title = widget.title;
    final hint = widget.hint;
    final header = widget.header;
    final answerIcon = widget.answerIcon;
    final onAnswer = widget.onAnswer;
    final onNext = widget.onNext;
    final q = run.current;
    final chosen = run.chosen;
    if (chosen != null) _revealFeedback();

    Color? colorFor(int i) {
      if (chosen == null) return null;
      if (i == q.correctDisplayIndex) return palette.success;
      if (i == chosen) return palette.coral;
      return null;
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _frame(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                    if (hint != null) ...[
                      const SizedBox(height: 4),
                      Text(hint, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                    ],
                    if (header != null) ...[const SizedBox(height: 12), header],
                    const SizedBox(height: 8),
                    Text(
                      l10n.quizProgress(run.index + 1, run.total),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(q.question.question, key: const ValueKey('quiz-question'), style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final (i, answer) in q.answers.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    key: ValueKey('answer-$i'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor: _answerFill(context, colorFor(i)),
                      side: BorderSide(color: colorFor(i) ?? palette.seaDeep, width: colorFor(i) == null ? 2 : 3),
                    ),
                    onPressed: chosen == null ? () => onAnswer(i) : null,
                    child: answerIcon == null
                        ? Text(answer, style: theme.textTheme.bodyLarge)
                        : Row(
                            children: [
                              Icon(answerIcon, color: colorFor(i) ?? palette.sea),
                              const SizedBox(width: 12),
                              Expanded(child: Text(answer, style: theme.textTheme.bodyLarge)),
                            ],
                          ),
                  ),
                ),
              if (chosen != null)
                KeyedSubtree(
                  key: _feedbackKey,
                  child: _frame(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.framed) const SizedBox(height: 8),
                        Text(
                          run.answeredCorrectly ? l10n.quizCorrect : l10n.quizWrong,
                          key: const ValueKey('quiz-feedback'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: run.answeredCorrectly ? palette.success : palette.coral,
                          ),
                        ),
                        if (q.question.explanation != null) ...[
                          const SizedBox(height: 4),
                          Text(q.question.explanation!, style: theme.textTheme.bodyLarge),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: chosen == null ? null : onNext,
              child: Text(run.isLast ? l10n.quizFinish : l10n.quizNext),
            ),
          ),
        ),
      ],
    );
  }

  /// Mit [QuizView.framed] ein eigener Rahmen, sonst liegt alles auf dem Blatt.
  Widget _frame(Widget child) => widget.framed ? GlassFrame(child: child) : child;

  /// Hintergrund einer Antwort: nach dem Antippen grün oder rot getönt; ohne
  /// Blatt darunter immer auf Papier, damit man sie vor dem Bild lesen kann.
  Color? _answerFill(BuildContext context, Color? tint) {
    if (!widget.framed) return tint?.withValues(alpha: 0.15);
    final paper = GlassFrame.fill(context);
    return tint == null ? paper : Color.alphaBlend(tint.withValues(alpha: 0.18), paper);
  }
}
