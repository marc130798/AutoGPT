import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/video_placeholder.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/family_models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/station_controller.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';
import '../progress/celebration.dart';
import '../../core/assets/taleria_asset.dart';
import '../../services/encounter_controller.dart' show EncounterRun;
import 'dialog_sequence.dart';
import 'game_views.dart';
import 'quiz_view.dart';

/// Eine Station von Anfang bis Ende. Gibt beim Schließen das Ergebnis
/// zurück (oder `null`, wenn das Kind vorher abbricht).
class StationScreen extends StatefulWidget {
  const StationScreen({
    super.key,
    required this.child,
    required this.island,
    required this.station,
    required this.allStations,
    this.details,
  });

  final ChildProfile child;
  final MapIsland island;
  final StationInfo station;
  final List<StationInfo> allStations;
  final IslandDetails? details;

  @override
  State<StationScreen> createState() => _StationScreenState();
}

class _StationScreenState extends State<StationScreen> {
  StationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final services = AppScope.of(context);
      _controller = StationController(
        content: services.content!,
        progress: services.progress!,
        settings: services.settings,
        child: widget.child,
        island: widget.island,
        station: widget.station,
        allStations: widget.allStations,
        budget: services.budget,
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
        final content = controller.content;
        final body = switch (controller.step) {
          StationStep.loading || StationStep.submitting => const Center(child: CircularProgressIndicator()),
          StationStep.warmUp => QuizView(
            run: controller.warmUp!,
            title: l10n.warmUpTitle,
            hint: l10n.warmUpHint,
            onAnswer: controller.answerWarmUp,
            onNext: controller.nextWarmUp,
          ),
          StationStep.video => VideoPlaceholder(assetKey: content.videoKey!, onContinue: controller.next),
          StationStep.scene => DialogSequence(lines: content.scene, title: content.place, onDone: controller.next),
          StationStep.lesson => DialogSequence(lines: content.lesson, onDone: controller.next),
          StationStep.game => GameStepView(
            game: content.game!,
            onDone: controller.next,
            onWish: AppScope.of(context).budget == null ? null : controller.createWishBottle,
            placeholder: _GamePlaceholder(game: content.game!, onContinue: controller.next),
          ),
          StationStep.quiz => QuizView(
            run: controller.quiz!,
            title: controller.isDive ? l10n.diveTitle : (controller.isExam ? l10n.stationExam : l10n.quizCheckTitle),
            hint: controller.isDive ? l10n.diveHint : null,
            onAnswer: controller.answerQuiz,
            onNext: controller.nextQuiz,
          ),
          StationStep.wreck => _WreckView(controller: controller),
          StationStep.result => _ResultView(controller: controller, details: widget.details),
          StationStep.failed => _FailedView(
            failure: controller.failure ?? FailureKind.unknown,
            onRetry: controller.retryAfterFailure,
          ),
        };
        return Scaffold(
          appBar: AppBar(title: Text(content.title)),
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

/// Bis Schritt 7 ein Platzhalter für das Mini-Spiel der Station.
class _GamePlaceholder extends StatelessWidget {
  const _GamePlaceholder({required this.game, required this.onContinue});

  final GameInfo game;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.extension_outlined, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.gamePlaceholderTitle(game.title),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (game.description != null) ...[
                const SizedBox(height: 12),
                Text(game.description!, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: 16),
              Text(l10n.gamePlaceholderBody, textAlign: TextAlign.center),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onContinue, child: Text(l10n.introNext)),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.controller, required this.details});

  final StationController controller;
  final IslandDetails? details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final result = controller.result!;
    final exam = controller.content.exam;
    final failedExam = controller.isExam && !result.passed;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                failedExam
                    ? l10n.examFailedTitle
                    : (controller.isExam
                          ? l10n.examPassedTitle
                          : (controller.isDive ? l10n.diveResultTitle : l10n.resultTitle)),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.resultCorrect(result.correct, result.total),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (controller.isDive) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.divePearls(result.correct),
                  key: const ValueKey('dive-pearls'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ],
              if (result.xpAwarded > 0) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.doneXp(result.xpAwarded),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(color: palette.gold, fontWeight: FontWeight.w800),
                ),
              ],
              const SizedBox(height: 24),
              if (failedExam)
                Text(
                  l10n.examFailedBody(exam?.pass ?? 8),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                )
              else if (controller.content.summary != null)
                SpeechBubble.line(controller.content.summary!),
              if (result.islandCompleted) ...[
                const SizedBox(height: 32),
                Center(child: IslandRewardEffect(badgeAssetKey: result.badge?.assetKey)),
                const SizedBox(height: 12),
                Text(l10n.islandCompletedTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                if ((result.badge?.title ?? details?.badge) case final badge?) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.islandCompletedBadge(badge),
                    key: const ValueKey('result-badge'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
                const SizedBox(height: 8),
                Text(l10n.islandCompletedNext, textAlign: TextAlign.center),
              ],
              if (result.find != null) ...[
                const SizedBox(height: 32),
                Center(child: RewardPop(assetKey: result.find!.assetKey)),
                const SizedBox(height: 12),
                Text(
                  l10n.diveFind(result.find!.title),
                  key: const ValueKey('dive-find'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ],
              if (result.rankUp != null) ...[
                const SizedBox(height: 32),
                Center(child: RewardPop(assetKey: AssetKeys.rank(result.rankUp!.code))),
                const SizedBox(height: 12),
                Text(
                  l10n.rankUpTitle(l10n.rank(result.rankUp)),
                  key: const ValueKey('result-rank-up'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (failedExam) ...[
                FilledButton(onPressed: controller.retryExam, child: Text(l10n.examRetry)),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: () => Navigator.of(context).pop(result), child: Text(l10n.resultBack)),
              ] else
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(result),
                  child: Text(result.islandCompleted ? l10n.islandCompletedButton : l10n.resultBack),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.failure, required this.onRetry});

  final FailureKind failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 64),
          const SizedBox(height: 16),
          Text(l10n.failure(failure), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton(onPressed: onRetry, child: Text(l10n.retryButton)),
        ],
      ),
    );
  }
}

/// Aufgabe im Wrack: Szene, eine Frage, probieren, bis es stimmt. Ohne Punkte.
class _WreckView extends StatelessWidget {
  const _WreckView({required this.controller});

  final StationController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final EncounterRun run = controller.wreck!;
    final task = controller.content.dive!.wreck!;
    final q = run.current;
    final chosen = run.chosen;

    Color? colorFor(int i) {
      if (chosen == null) return null;
      if (run.answeredCorrectly && i == q.correctDisplayIndex) return palette.success;
      if (i == chosen) return palette.coral;
      return null;
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.wreckTitle, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              const Center(child: TaleriaAsset(AssetKeys.underwaterBackground, width: 220, height: 90)),
              const SizedBox(height: 12),
              for (final line in task.scene)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: SpeechBubble.line(line)),
              Text(q.question.question, key: const ValueKey('wreck-question'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final (i, answer) in q.answers.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    key: ValueKey('wreck-answer-$i'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor: colorFor(i)?.withValues(alpha: 0.15),
                      side: BorderSide(color: colorFor(i) ?? palette.seaDeep, width: colorFor(i) == null ? 2 : 3),
                    ),
                    onPressed: chosen == null ? () => controller.answerWreck(i) : null,
                    child: Text(answer, style: theme.textTheme.bodyLarge),
                  ),
                ),
              if (chosen != null) ...[
                Text(
                  run.answeredCorrectly ? l10n.quizCorrect : l10n.quizWrong,
                  key: const ValueKey('wreck-feedback'),
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
            child: chosen != null && !run.answeredCorrectly
                ? OutlinedButton(
                    key: const ValueKey('wreck-retry'),
                    onPressed: controller.retryWreck,
                    child: Text(l10n.encounterTryAgain),
                  )
                : FilledButton(
                    key: const ValueKey('wreck-done'),
                    onPressed: run.finished ? controller.finishWreck : null,
                    child: Text(l10n.wreckDone),
                  ),
          ),
        ),
      ],
    );
  }
}
