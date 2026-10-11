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
  });

  final QuizRun run;
  final String title;
  final String? hint;

  /// Über der Frage, zum Beispiel Perlen oder das Zahlenschloss beim Tauchgang.
  final Widget? header;

  /// Vor jeder Antwort, zum Beispiel ein Fisch beim Fischschwarm.
  final IconData? answerIcon;

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
                  child: AnswerButton(
                    key: ValueKey('answer-$i'),
                    text: answer,
                    icon: answerIcon,
                    mark: _markFor(i),
                    onPressed: chosen == null ? () => onAnswer(i) : null,
                  ),
                ),
              if (chosen != null)
                KeyedSubtree(
                  key: _feedbackKey,
                  child: _frame(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_open) const SizedBox(height: 8),
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

  /// Ohne Blatt darunter ([StagePanel.open]) bekommen Frage und Rückmeldung
  /// je einen eigenen Rahmen, sonst liegt alles auf dem Blatt.
  bool get _open => StagePanel.isOpen(context);

  Widget _frame(Widget child) => OpenFrame(child: child);

  /// Nach dem Antippen: richtige Antwort grün, falsch gewählte rot.
  AnswerMark _markFor(int i) {
    final chosen = widget.run.chosen;
    if (chosen == null) return AnswerMark.none;
    if (i == widget.run.current.correctDisplayIndex) return AnswerMark.right;
    if (i == chosen) return AnswerMark.wrong;
    return AnswerMark.none;
  }
}
