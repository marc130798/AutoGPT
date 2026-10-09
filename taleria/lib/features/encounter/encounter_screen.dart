import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/encounter_controller.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';
import '../progress/celebration.dart';
import '../station/dialog_sequence.dart';

/// Begegnung auf See (Kontrollfahrt): Eine Figur taucht auf und stellt
/// Rätsel zu früheren Stationen. Falsche Antworten kosten nichts: Die Figur
/// erklärt, und das Kind versucht es gleich noch einmal. Gibt beim Schließen
/// das Ergebnis zurück (oder `null`, wenn das Kind vorher abbricht).
class EncounterScreen extends StatefulWidget {
  const EncounterScreen({super.key, required this.childId, required this.offer});

  final String childId;
  final EncounterOffer offer;

  @override
  State<EncounterScreen> createState() => _EncounterScreenState();
}

class _EncounterScreenState extends State<EncounterScreen> {
  EncounterController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final services = AppScope.of(context);
      _controller = EncounterController(
        content: services.content!,
        progress: services.progress!,
        childId: widget.childId,
        offer: widget.offer,
        random: services.random,
      )..start();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final body = switch (controller.step) {
          EncounterStep.loading || EncounterStep.submitting => const Center(child: CircularProgressIndicator()),
          EncounterStep.intro => Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: RiseFromWater(child: TaleriaAsset(controller.encounter.assetKey, width: 120, height: 120)),
              ),
              Expanded(
                child: DialogSequence(lines: widget.offer.openingScene, onDone: controller.introDone),
              ),
            ],
          ),
          EncounterStep.question => _RiddleView(controller: controller),
          EncounterStep.result => _ResultView(controller: controller),
          EncounterStep.failed => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 64),
                const SizedBox(height: 16),
                Text(l10n.failure(controller.failure ?? FailureKind.unknown), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(onPressed: controller.retryAfterFailure, child: Text(l10n.retryButton)),
              ],
            ),
          ),
        };
        return Scaffold(
          appBar: AppBar(title: Text(controller.encounter.title)),
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(key: ValueKey(controller.step), child: body),
            ),
          ),
        );
      },
    );
  }
}

class _RiddleView extends StatelessWidget {
  const _RiddleView({required this.controller});

  final EncounterController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final run = controller.run!;
    final q = run.current;
    final chosen = run.chosen;
    final encounter = controller.encounter;

    Color? colorFor(int i) {
      if (chosen == null) return null;
      if (run.answeredCorrectly && i == q.correctDisplayIndex) return palette.success;
      if (i == chosen) return palette.coral;
      return null;
    }

    final reaction = run.answeredCorrectly ? encounter.right : encounter.wrong;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(child: TaleriaAsset(encounter.assetKey, width: 96, height: 96)),
              const SizedBox(height: 8),
              Text(
                l10n.encounterProgress(run.index + 1, run.total),
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
                    onPressed: chosen == null ? () => controller.answer(i) : null,
                    child: Text(answer, style: theme.textTheme.bodyLarge),
                  ),
                ),
              if (chosen != null) ...[
                const SizedBox(height: 8),
                if (reaction != null)
                  SpeechBubble.line(reaction)
                else
                  Text(
                    run.answeredCorrectly ? l10n.quizCorrect : l10n.quizWrong,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: run.answeredCorrectly ? palette.success : palette.coral,
                    ),
                  ),
                if (q.question.explanation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    q.question.explanation!,
                    key: const ValueKey('encounter-explanation'),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: chosen != null && !run.answeredCorrectly
                ? OutlinedButton(
                    key: const ValueKey('encounter-retry'),
                    onPressed: controller.retry,
                    child: Text(l10n.encounterTryAgain),
                  )
                : FilledButton(
                    key: const ValueKey('encounter-next'),
                    onPressed: chosen == null ? null : controller.next,
                    child: Text(run.isLast ? l10n.encounterFinish : l10n.encounterNext),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.controller});

  final EncounterController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final result = controller.result!;
    final success = controller.encounter.success;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(l10n.encounterDoneTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (success != null) SpeechBubble.line(success),
              const SizedBox(height: 16),
              Text(
                l10n.encounterFirstTry(result.correct, result.total),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (result.xpAwarded > 0)
                Text(
                  l10n.doneXp(result.xpAwarded),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(color: palette.gold, fontWeight: FontWeight.w800),
                )
              else
                Text(l10n.encounterNoXpToday, textAlign: TextAlign.center),
              if (result.rankUp != null) ...[
                const SizedBox(height: 24),
                Center(child: RewardPop(assetKey: AssetKeys.rank(result.rankUp!.code))),
                const SizedBox(height: 12),
                Text(
                  l10n.rankUpTitle(l10n.rank(result.rankUp)),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.air, color: palette.seaDeep),
                  const SizedBox(width: 8),
                  Text(l10n.streakWeeks(result.streakWeeks), style: theme.textTheme.bodyLarge),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => Navigator.of(context).pop(result), child: Text(l10n.encounterBack)),
          ),
        ),
      ],
    );
  }
}

/// Markierung auf der Karte: Eine Begegnung taucht einmal aus dem Wasser auf.
class EncounterMapButton extends StatelessWidget {
  const EncounterMapButton({super.key, required this.encounter, required this.onTap});

  final Encounter encounter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final theme = Theme.of(context);
    return RiseFromWater(
      child: Semantics(
        button: true,
        label: l10n.mapEncounterButton(encounter.title),
        child: GestureDetector(
          key: const ValueKey('encounter-marker'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TaleriaAsset(encounter.assetKey, width: 72, height: 72),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.paper.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.gold, width: 2),
                ),
                child: Text(
                  l10n.mapEncounterButton(encounter.title),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
