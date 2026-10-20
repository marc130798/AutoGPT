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
              // Oben klein, was gerade dran ist und wie weit; darunter groß die
              // Frage (Marcs Test am 20.10.2026: erst die Frage, wenig Text).
              _frame(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: palette.seaDeep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        QuizDots(results: run.results, current: run.index),
                      ],
                    ),
                    // Wie das Spiel geht, nur bei der ersten Frage.
                    if (hint != null && run.index == 0) ...[
                      const SizedBox(height: 4),
                      Text(hint, style: theme.textTheme.bodySmall),
                    ],
                    if (header != null) ...[const SizedBox(height: 8), header],
                    const SizedBox(height: 12),
                    Text(
                      q.question.question,
                      key: const ValueKey('quiz-question'),
                      textAlign: TextAlign.center,
                      style: questionStyle(context),
                    ),
                    const SizedBox(height: 4),
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

/// Die Frage groß und gut lesbar (Fragen, Wrack, Begegnungen).
TextStyle? questionStyle(BuildContext context) =>
    Theme.of(context).textTheme.headlineSmall
        ?.copyWith(color: context.palette.ink, fontWeight: FontWeight.w700, height: 1.25);

/// Fortschritt als Punkte statt „Frage 2 von 5“: beantwortet grün oder rot,
/// die aktuelle Frage golden und größer, die kommenden grau.
class QuizDots extends StatelessWidget {
  const QuizDots({super.key, required this.results, required this.current, this.label});

  final List<bool?> results;
  final int current;

  /// Was Vorlesen sagt, Standard „Frage 2 von 5“.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Semantics(
      label: label ?? l10n.quizProgress(current + 1, results.length),
      excludeSemantics: true,
      child: Row(
        key: const ValueKey('quiz-progress'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, result) in results.indexed)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: i == current ? 13 : 9,
              height: i == current ? 13 : 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: switch (result) {
                  true => palette.success,
                  false => palette.coral,
                  null when i == current => palette.gold,
                  null => palette.placeholderBorder.withValues(alpha: 0.5),
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Fortschritt in Übungen als Punkte in einem kleinen Rahmen statt „Aufgabe 2
/// von 4“ (Marcs Wunsch am 20.10.2026). In Übungen wird probiert, bis es
/// stimmt: Geschaffte sind grün, die aktuelle golden, gelöst auch grün.
/// Vorlesen sagt [label].
class StepDots extends StatelessWidget {
  const StepDots({
    super.key,
    required this.total,
    required this.current,
    required this.label,
    this.currentDone = false,
  });

  final int total;
  final int current;
  final String label;
  final bool currentDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassFrame(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: QuizDots(
          results: [for (var i = 0; i < total; i++) i < current || (i == current && currentDone) ? true : null],
          current: current,
          label: label,
        ),
      ),
    );
  }
}
