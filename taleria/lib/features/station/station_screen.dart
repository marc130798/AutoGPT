import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/assets/video_placeholder.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/sounds.dart';
import '../../services/station_controller.dart';
import '../child/games_screen.dart';
import '../common/dive_descent.dart';
import '../common/fog_reveal.dart';
import '../common/game_sign.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';
import '../progress/celebration.dart';
import '../progress/stats_card.dart';
import '../../services/encounter_controller.dart' show EncounterRun;
import 'dialog_sequence.dart';
import 'dive_header.dart';
import 'estimate_view.dart';
import 'game_views.dart';
import 'picture_story.dart';
import 'quiz_view.dart';
import 'station_stage.dart';

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
  StationStep? _lastStep;

  Sounds get _sounds => AppScope.of(context).sounds;

  /// Am Ende eine Fanfare (groß, wenn die Insel geschafft ist) und kurzes
  /// Vibrieren. Nach einer nicht bestandenen Prüfung keins von beiden.
  void _onStep() {
    final controller = _controller!;
    if (controller.step == _lastStep) return;
    _lastStep = controller.step;
    final result = controller.result;
    if (controller.step != StationStep.result || result == null || !result.passed) return;
    _sounds.effect(result.islandCompleted ? AssetKeys.soundIslandDone : AssetKeys.soundStationDone);
    _sounds.success();
  }

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
      )..addListener(_onStep);
      _controller!.start();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onStep);
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
        final diveGame = DiveGame.parse(content.dive?.game);
        final body = switch (controller.step) {
          StationStep.loading || StationStep.submitting => const Center(child: CircularProgressIndicator()),
          StationStep.warmUp => QuizView(
            run: controller.warmUp!,
            title: l10n.warmUpTitle,
            onAnswer: (i) {
              controller.answerWarmUp(i);
              if (controller.warmUp!.answeredCorrectly) _sounds.effect(AssetKeys.soundCorrect);
            },
            onNext: controller.nextWarmUp,
          ),
          StationStep.video => VideoPlaceholder(assetKey: content.videoKey!, onContinue: controller.next),
          StationStep.scene => DialogSequence(
            lines: content.scene,
            title: content.place,
            onDone: controller.next,
            // Beim Stopp auf See mit Schiff steht oben das Schiff (siehe _framed).
            stage: content.seaStop?.ship == null,
          ),
          StationStep.estimate => EstimateView(estimate: content.estimate!, onSubmit: controller.submitEstimate),
          StationStep.lesson when content.hasPictureStory => PictureStory(
            lines: content.lesson,
            onDone: controller.next,
            taps: content.taps,
            estimate: content.estimate,
            guess: controller.guess,
          ),
          StationStep.lesson => DialogSequence(
            lines: [
              ...content.lesson,
              // Ohne Bilder steht die Auflösung als letzte Zeile da.
              if (content.estimate case final e? when controller.guess != null)
                DialogLine(
                  speaker: e.reveal.speaker,
                  text: '${l10n.estimateYourGuess(e.display(controller.guess!))} ${e.reveal.text}',
                ),
            ],
            onDone: controller.next,
            stage: true,
          ),
          StationStep.game => GameStepView(
            game: content.game!.forLevel(controller.child.level),
            onDone: controller.next,
            onWish: AppScope.of(context).budget == null ? null : controller.createWishBottle,
            placeholder: _GamePlaceholder(game: content.game!, onContinue: controller.next),
          ),
          StationStep.quiz => QuizView(
            run: controller.quiz!,
            title: controller.isDive
                ? diveGame.title(l10n)
                : (controller.isExam ? l10n.stationExam : l10n.quizCheckTitle),
            hint: controller.isDive ? diveGame.hint(l10n) : null,
            header: controller.isDive
                ? DiveHeader(game: diveGame, results: controller.quiz!.results, stationId: widget.station.id)
                : null,
            answerIcon: controller.isDive ? diveGame.answerIcon : null,
            onAnswer: (i) {
              controller.answerQuiz(i);
              // Beim Tauchgang ist jede richtige Antwort eine Perle.
              if (controller.quiz!.answeredCorrectly) {
                _sounds.effect(controller.isDive ? AssetKeys.soundPearl : AssetKeys.soundCorrect);
              }
            },
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
          body: _fogged(
            controller.isSeaStop,
            _dived(
              controller.isDive,
              StationBackdrop(
                // Die Insel von innen, beim Tauchgang die Unterwasserwelt, beim
                // Stopp auf See das offene Meer.
                assetKey: controller.isDive
                    ? AssetKeys.underwaterBackground
                    : (controller.isSeaStop ? AssetKeys.mapBackground : AssetKeys.islandBackground(widget.island.slug)),
                // Unter Wasser oben das Wrack mit den Fischen zeigen.
                lift: controller.isDive ? 0.35 : 0,
                // Das Bild ist immer leicht verblasst, damit Texte und Figuren
                // hervortreten (Marcs Wunsch am 11.10.2026).
                faded: true,
                child: SafeArea(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(key: ValueKey(controller.step), child: _framed(controller, body)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Stopp auf See: Nebel zieht auf und lichtet sich (siehe [fogRoute]).
Widget _fogged(bool seaStop, Widget child) => seaStop ? FogReveal(child: child) : child;

/// Tauchgang: Der Bildschirm taucht zuerst ab.
Widget _dived(bool dive, Widget child) => dive ? DiveDescent(child: child) : child;

/// Legt den Inhalt eines Schritts auf Papier, darüber passende Figuren:
/// bei Fragen denkt Talo nach (richtig: beide freuen sich), beim Spiel
/// überlegt Tala, am Ende freuen sich beide. Unter Wasser bleibt die Bühne
/// leer, damit man die Unterwasserwelt sieht.
Widget _framed(StationController controller, Widget body) {
  final dive = controller.isDive;
  final failedExam = controller.isExam && controller.result != null && !controller.result!.passed;
  final ship = controller.station.content.seaStop?.ship;
  return switch (controller.step) {
    StationStep.loading || StationStep.submitting => body,
    // Stopp auf See mit Schiff: Oben liegt das Schiff auf dem Meer. In der
    // Szene taucht es aus dem Nebel auf, bei den Fragen bleibt es da.
    StationStep.scene when ship != null => StagePanel(stage: ShipStage(ship, emerge: true), open: true, child: body),
    StationStep.quiz when ship != null => StagePanel(stage: ShipStage(ship), open: true, child: body),
    // Die Bildergeschichte liegt ohne Blatt vor der Insel, das Bild ersetzt die Bühne.
    StationStep.lesson when controller.station.content.hasPictureStory => StagePanel(open: true, child: body),
    // Szene und Lehre bringen ihre Bühne selbst mit (aktueller Sprecher).
    StationStep.scene || StationStep.lesson => body,
    // Schätzen: Talo und Tala überlegen mit.
    StationStep.estimate => StagePanel(
      stage: const FigureStage(
        figures: [
          StageFigure(AssetKeys.talo, pose: CharacterPose.think),
          StageFigure(AssetKeys.tala, pose: CharacterPose.think),
        ],
      ),
      open: true,
      child: body,
    ),
    StationStep.warmUp => StagePanel(
      stage: quizStage(answered: controller.warmUp!.answered, correct: controller.warmUp!.answeredCorrectly),
      open: true,
      child: body,
    ),
    // Unter Wasser kein großes Blatt: nur Frage und Antworten sind eingerahmt.
    StationStep.quiz when dive => StagePanel(stage: const SizedBox.shrink(), open: true, child: body),
    StationStep.quiz => StagePanel(
      stage: quizStage(answered: controller.quiz!.answered, correct: controller.quiz!.answeredCorrectly),
      open: true,
      child: body,
    ),
    // Echte Mini-Spiele brauchen den ganzen Platz.
    StationStep.game when controller.station.content.game?.isRealGame ?? false => StagePanel(open: true, child: body),
    StationStep.game => StagePanel(
      stage: const FigureStage(
        figures: [
          StageFigure(AssetKeys.tala, pose: CharacterPose.think),
          StageFigure(AssetKeys.talo, active: false),
        ],
      ),
      open: true,
      child: body,
    ),
    StationStep.wreck => StagePanel(stage: const SizedBox.shrink(), open: true, child: body),
    StationStep.result when dive => StagePanel(stage: const SizedBox.shrink(), open: true, child: body),
    StationStep.result => StagePanel(
      open: true,
      stage: FigureStage(
        figures: [
          StageFigure(AssetKeys.talo, pose: failedExam ? CharacterPose.think : CharacterPose.happy),
          StageFigure(AssetKeys.tala, pose: failedExam ? CharacterPose.think : CharacterPose.happy),
        ],
      ),
      child: body,
    ),
    // Der Film (oder sein Platzhalter) steht frei vor der Insel.
    StationStep.video => Padding(padding: const EdgeInsets.all(12), child: body),
    StationStep.failed => StagePanel(child: body),
  };
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
    final result = controller.result!;
    final exam = controller.content.exam;
    final failedExam = controller.isExam && !result.passed;

    final page = Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Offen vor der Insel (Marcs Wunsch am 20.10.2026: kein großes leeres Blatt):
              // Titel, ein Stern pro Frage, darunter die Seemeilen mit dem Weg zum nächsten Rang.
              OpenFrame(
                child: Column(
                  children: [
                    Text(
                      failedExam
                          ? l10n.examFailedTitle
                          : (controller.isExam
                                ? l10n.examPassedTitle
                                : (controller.isDive
                                      ? l10n.diveResultTitle
                                      : (controller.isSeaStop ? l10n.seaStopDone : l10n.resultTitle))),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (controller.quiz case final quiz?) ...[
                      const SizedBox(height: 8),
                      AnswerStars(results: quiz.results, size: quiz.total > 6 ? 26 : 36),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      l10n.resultCorrect(result.correct, result.total),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (controller.isDive) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.divePearls(result.correct),
                        key: const ValueKey('dive-pearls'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (result.xpAwarded > 0) ...[
                const SizedBox(height: 12),
                _XpGain(xp: result.xpAwarded, stats: controller.statsAfter, rankForm: controller.child.rankForm),
              ],
              const SizedBox(height: 16),
              if (failedExam)
                OpenFrame(
                  child: Text(
                    l10n.examFailedBody(exam?.pass ?? 8),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              else if (controller.content.summary != null)
                SpeechBubble.line(controller.content.summary!),
              // Bonus: das echte Mini-Spiel der Station, kein Muss (Marc, 11.10.2026).
              if (!failedExam && controller.content.hasMiniGame) ...[
                const SizedBox(height: 24),
                _BonusGameCard(controller: controller),
              ],
              if (result.islandCompleted) ...[
                const SizedBox(height: 32),
                Center(child: IslandRewardEffect(badgeAssetKey: result.badge?.assetKey)),
                const SizedBox(height: 12),
                OpenFrame(
                  child: Column(
                    children: [
                      Text(
                        l10n.islandCompletedTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
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
                  ),
                ),
                if (details?.teaser case final teaser? when teaser.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _IslandTeaser(details: details!),
                ],
              ],
              if (result.find != null) ...[
                const SizedBox(height: 32),
                Center(child: RewardPop(assetKey: result.find!.assetKey)),
                const SizedBox(height: 12),
                OpenFrame(
                  child: Text(
                    l10n.diveFind(result.find!.title),
                    key: const ValueKey('dive-find'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
              if (result.rankUp != null) ...[
                const SizedBox(height: 32),
                Center(child: RewardPop(assetKey: AssetKeys.rank(result.rankUp!.code))),
                const SizedBox(height: 12),
                OpenFrame(
                  child: Text(
                    l10n.rankUpTitle(l10n.rank(result.rankUp, controller.child.rankForm)),
                    key: const ValueKey('result-rank-up'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
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
                  child: Text(
                    result.islandCompleted
                        ? l10n.islandCompletedButton
                        : (controller.isSeaStop ? l10n.seaStopBack : l10n.resultBack),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    // Geschafft: Konfetti über dem Ergebnis (nicht nach einer nicht bestandenen Prüfung).
    if (failedExam) return page;
    return Stack(
      children: [
        page,
        const Positioned.fill(child: ConfettiBurst()),
      ],
    );
  }
}

/// Seemeilen im Ergebnis: Sie zählen hoch, daneben das Rang-Abzeichen,
/// darunter füllt sich der Balken bis zum nächsten Rang (vom Stand vor der
/// Station bis jetzt). Ohne Stand vom Server nur die Seemeilen.
class _XpGain extends StatelessWidget {
  const _XpGain({required this.xp, required this.stats, required this.rankForm});

  final int xp;
  final ChildStats? stats;
  final RankForm? rankForm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final stats = this.stats;
    final after = stats?.progressToNextRank;
    double? before;
    if (stats != null && after != null && stats.nextRankXp != null) {
      final start = stats.rankMinXp ?? 0;
      final span = stats.nextRankXp! - start;
      before = span <= 0 ? after : ((stats.xp - xp - start) / span).clamp(0.0, after);
    }
    return GlassFrame(
      child: Row(
        children: [
          ClipOval(child: TaleriaAsset(AssetKeys.rank((stats?.rank ?? Rank.schiffsjunge).code), width: 52, height: 52)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seemeilen zählen sichtbar hoch.
                CountUp(
                  value: xp,
                  builder: (context, v) => Text(
                    l10n.doneXp(v),
                    key: const ValueKey('result-xp'),
                    style: theme.textTheme.titleLarge?.copyWith(color: palette.gold, fontWeight: FontWeight.w800),
                  ),
                ),
                if (stats != null && after != null && before != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      key: const ValueKey('result-rank-bar'),
                      tween: Tween(begin: before, end: after),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 10, color: palette.gold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(rankProgressText(l10n, stats, rankForm), style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bonus-Karte im Ergebnis: Das Mini-Spiel der Station ist freigespielt.
class _BonusGameCard extends StatelessWidget {
  const _BonusGameCard({required this.controller});

  final StationController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = controller.content.miniGame!;
    return Container(
      key: const ValueKey('bonus-game'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.gold, width: 2),
      ),
      child: Column(
        children: [
          // Startbild des Spiels mit dem Spiel-Zeichen in der Ecke, sonst nur das Zeichen.
          if (game.image case final image?) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: TaleriaAsset(
                      image,
                      key: const ValueKey('bonus-game-image'),
                      fit: BoxFit.cover,
                      fallback: const Center(child: GameSign(size: 56)),
                    ),
                  ),
                ),
                const Positioned(top: -10, left: -6, child: GameSign(size: 44)),
              ],
            ),
            const SizedBox(height: 10),
            Text(l10n.bonusGameTitle, style: theme.textTheme.titleMedium),
          ] else
            Row(
              children: [
                const GameSign(size: 48),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.bonusGameTitle, style: theme.textTheme.titleMedium)),
              ],
            ),
          const SizedBox(height: 8),
          Text(l10n.bonusGameBody(game.title), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              key: const ValueKey('bonus-game-play'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GameReplayScreen(
                    entry: GameEntry(island: controller.island, station: controller.station, unlocked: true),
                    level: controller.child.level,
                  ),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.bonusGamePlay),
            ),
          ),
        ],
      ),
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
    final task = controller.content.dive!.wreck!.forLevel(controller.child.level);
    final q = run.current;
    final chosen = run.chosen;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Unter Wasser ohne großes Blatt: nur Überschrift, Frage, Antworten
              // und Rückmeldung haben einen Rahmen, dazwischen sieht man das Wrack.
              GlassFrame(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(l10n.wreckTitle, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 12),
              for (final line in task.scene)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: SpeechBubble.line(line)),
              GlassFrame(
                child: Text(
                  q.question.question,
                  key: const ValueKey('wreck-question'),
                  textAlign: TextAlign.center,
                  style: questionStyle(context),
                ),
              ),
              const SizedBox(height: 12),
              for (final (i, answer) in q.answers.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnswerButton(
                    key: ValueKey('wreck-answer-$i'),
                    text: answer,
                    mark: chosen == null
                        ? AnswerMark.none
                        : (run.answeredCorrectly && i == q.correctDisplayIndex
                              ? AnswerMark.right
                              : (i == chosen ? AnswerMark.wrong : AnswerMark.none)),
                    onPressed: chosen == null
                        ? () {
                            controller.answerWreck(i);
                            if (controller.wreck!.answeredCorrectly) {
                              AppScope.of(context).sounds.effect(AssetKeys.soundCorrect);
                            }
                          }
                        : null,
                  ),
                ),
              if (chosen != null)
                GlassFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                  ),
                ),
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

/// Ausblick auf die nächste Insel nach dem Insel-Abschluss: Bild, Name und ein
/// paar Sätze von Talo und Tala, damit das Kind neugierig weitersegelt.
class _IslandTeaser extends StatelessWidget {
  const _IslandTeaser({required this.details});

  final IslandDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('island-teaser'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OpenFrame(
          child: Column(
            children: [
              Text(l10n.islandTeaserTitle, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              if (details.nextSlug case final slug?) ...[
                const SizedBox(height: 8),
                TaleriaAsset(AssetKeys.mapIsland(slug), height: 130),
              ],
              if (details.nextTitle case final title?) ...[
                const SizedBox(height: 4),
                Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              ],
            ],
          ),
        ),
        for (final line in details.teaser) ...[const SizedBox(height: 8), SpeechBubble.line(line)],
      ],
    );
  }
}
