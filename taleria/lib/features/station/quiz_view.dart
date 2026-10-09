import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';
import '../../services/station_controller.dart';

/// Eine Frage mit drei Antworten. Nach dem Tipp: richtig oder nicht,
/// dazu die Erklärung von Talo oder Tala. Falsche Antworten kosten nichts.
class QuizView extends StatelessWidget {
  const QuizView({
    super.key,
    required this.run,
    required this.title,
    required this.onAnswer,
    required this.onNext,
    this.hint,
  });

  final QuizRun run;
  final String title;
  final String? hint;
  final ValueChanged<int> onAnswer;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final q = run.current;
    final chosen = run.chosen;

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
              Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(hint!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 8),
              Text(
                l10n.quizProgress(run.index + 1, run.total),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
              Text(q.question.question, key: const ValueKey('quiz-question'), style: theme.textTheme.titleMedium),
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
                      backgroundColor: colorFor(i)?.withValues(alpha: 0.15),
                      side: BorderSide(color: colorFor(i) ?? palette.seaDeep, width: colorFor(i) == null ? 2 : 3),
                    ),
                    onPressed: chosen == null ? () => onAnswer(i) : null,
                    child: Text(answer, style: theme.textTheme.bodyLarge),
                  ),
                ),
              if (chosen != null) ...[
                const SizedBox(height: 8),
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
}
