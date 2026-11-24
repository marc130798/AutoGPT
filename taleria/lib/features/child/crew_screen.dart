import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/crew_controller.dart';
import '../common/menu_music.dart';
import '../common/page_intro.dart';
import '../common/play_effect.dart';
import '../common/scene_background.dart';
import '../common/taleria_app_bar.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';

/// „Crew“ (Kinderbereich): Aufgaben, die das Kind nur gemeinsam mit den Eltern
/// schafft. „Erklär's deinen Eltern“ nach jeder geschafften Insel und das
/// Crew-Abenteuer jeder erreichten Insel. Danach sagen die Eltern einen Code
/// (aus dem Leuchtturm), das Kind gibt ihn ein und bekommt einen Crew-Stern.
class CrewScreen extends StatefulWidget {
  const CrewScreen({super.key, required this.child});

  final ChildProfile child;

  @override
  State<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends State<CrewScreen> {
  CrewController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    _controller ??= CrewController(content: services.content!, progress: services.progress!, child: widget.child)
      ..load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _enterCode(CrewTask task) async {
    final controller = _controller!;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final unlockedBefore = controller.nextReward?.$1;
    final result = await showDialog<CrewRedeemResult>(
      context: context,
      builder: (_) => _CodeDialog(onSubmit: (code) => controller.redeem(task, code)),
    );
    if (result == null || !mounted) return;
    if (result.status == CrewRedeemStatus.ok) {
      playEffect(context, AssetKeys.soundCorrect);
      final newItem = unlockedBefore != null && (unlockedBefore.crewStars ?? 99) <= result.stars
          ? unlockedBefore
          : null;
      await showDialog<void>(
        context: context,
        builder: (_) => _StarDialog(result: result, newItem: newItem == null ? null : l10n.lookName(newItem.id)),
      );
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.crewCodeMessage(result.status.name, result.triesLeft ?? 0))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller!;
    return MenuMusic(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: TaleriaAppBar(title: l10n.crewTitle),
        body: SceneBackground(
          assetKey: AssetKeys.homeBackground,
          child: SafeArea(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.loading) return const Center(child: CircularProgressIndicator());
                if (controller.failure != null) {
                  return Center(
                    child: PaperCard(
                      margin: const EdgeInsets.all(24),
                      child: Text(l10n.failure(controller.failure!), textAlign: TextAlign.center),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PageIntro(
                      childId: widget.child.id,
                      page: 'crew',
                      children: [SpeechBubble(speaker: Speaker.talo, pose: CharacterPose.happy, text: l10n.crewIntro)],
                    ),
                    const SizedBox(height: 12),
                    _StarsCard(controller: controller),
                    if (controller.tasks.isEmpty) PaperCard(child: Text(l10n.crewNone)),
                    for (final task in controller.open) _TaskCard(task: task, onCode: () => _enterCode(task)),
                    if (controller.finished.isNotEmpty) ...[
                      PaperHeading(l10n.crewFinishedHeading),
                      for (final task in controller.finished) _TaskCard(task: task),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Crew-Sterne und das nächste Teil in der Werft.
class _StarsCard extends StatelessWidget {
  const _StarsCard({required this.controller});

  final CrewController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final next = controller.nextReward;
    return PaperCard(
      key: const ValueKey('crew-stars'),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: palette.gold, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.crewStars(controller.stars), style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  next == null ? l10n.crewAllUnlocked : l10n.crewNextItem(next.$2, l10n.lookName(next.$1.id)),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, this.onCode});

  final CrewTask task;
  final VoidCallback? onCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final explain = task.kind == CrewKind.explain;
    final done = task.done;
    return PaperCard(
      key: ValueKey('crew-task-${task.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                explain ? Icons.record_voice_over_rounded : Icons.groups_rounded,
                color: explain ? palette.sea : palette.coral,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  explain ? l10n.crewExplainHeading : l10n.crewAdventureHeading,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Text('+${task.kind.xp}', style: theme.textTheme.labelLarge?.copyWith(color: palette.gold)),
            ],
          ),
          const SizedBox(height: 6),
          if (explain) ...[
            Text(l10n.crewExplainIntro(task.island.title), style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            for (final point in task.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.star_rounded, size: 20, color: palette.gold),
                    const SizedBox(width: 6),
                    Expanded(child: Text(point, style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
          ] else ...[
            Text(task.title, style: theme.textTheme.titleMedium),
            if (task.text case final text?) ...[
              const SizedBox(height: 4),
              Text(text, style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: 4),
            Text(l10n.crewAdventureIsland(task.island.title), style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 10),
          if (done != null)
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: palette.success),
                const SizedBox(width: 6),
                Text(l10n.crewDoneOn(formatDate(done.doneAt)), style: theme.textTheme.bodyMedium),
              ],
            )
          else
            FilledButton.icon(
              key: ValueKey('crew-code-${task.id}'),
              onPressed: onCode,
              icon: const Icon(Icons.pin_rounded),
              label: Text(l10n.crewEnterCode),
            ),
        ],
      ),
    );
  }
}

/// Code der Eltern eingeben (4 Ziffern). Gibt das Ergebnis vom Server zurück.
class _CodeDialog extends StatefulWidget {
  const _CodeDialog({required this.onSubmit});

  final Future<CrewRedeemResult> Function(String code) onSubmit;

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.trim().length != 4 || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.onSubmit(_code.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = AppLocalizations.of(context).failure(e.kind);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.crewCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.crewCodeHint),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('crew-code-field'),
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 12),
            decoration: InputDecoration(hintText: '····', errorText: _error),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          key: const ValueKey('crew-code-submit'),
          onPressed: _code.text.trim().length == 4 && !_busy ? _submit : null,
          child: Text(l10n.crewCodeSubmit),
        ),
      ],
    );
  }
}

/// Feier nach dem richtigen Code: Seemeilen, Crew-Stern, vielleicht ein neues Werft-Teil.
class _StarDialog extends StatelessWidget {
  const _StarDialog({required this.result, this.newItem});

  final CrewRedeemResult result;
  final String? newItem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return AlertDialog(
      key: const ValueKey('crew-star-dialog'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: palette.gold, size: 96),
          Text(l10n.crewCodeOkTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(l10n.crewCodeOk(result.xpAwarded, result.stars), textAlign: TextAlign.center),
          if (newItem case final item?) ...[
            const SizedBox(height: 12),
            Text(
              l10n.crewNewItem(item),
              key: const ValueKey('crew-new-item'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: palette.coral),
            ),
          ],
        ],
      ),
      actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.crewCodeOkButton))],
    );
  }
}
