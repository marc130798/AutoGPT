import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/avatar.dart';
import '../../domain/family_models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/child_stats_controller.dart';
import '../../services/session_controller.dart';
import '../common/avatar_view.dart';
import '../home/preview_home_screen.dart' show IntroVideoScreen;
import '../map/island_map_screen.dart';
import '../progress/badges_screen.dart';
import '../progress/collection_screen.dart';
import '../progress/stats_card.dart';
import '../treasure/tasks_screen.dart';
import '../treasure/treasure_screen.dart';
import 'lighthouse_button.dart';

/// Kinderbereich nach dem Intro: Avatar, Schiff und der Weg zur Karte.
/// Keine Preise, keine Kauf-Knöpfe, keine Links nach außen.
class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key, required this.state});

  final SessionChild state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final child = state.child;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const TaleriaAsset(AssetKeys.talo, width: 88, height: 88),
                    const SizedBox(width: 12),
                    AvatarView(avatar: child.avatar ?? const AvatarConfig(), size: 140),
                    const SizedBox(width: 12),
                    const TaleriaAsset(AssetKeys.tala, width: 88, height: 88),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.childHomeWelcome(child.nickname),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                if (child.shipName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.childHomeShip(child.shipName!),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
                const SizedBox(height: 24),
                _ProgressSection(state: state),
                const SizedBox(height: 12),
                _TreasureButton(childId: child.id),
                const SizedBox(height: 12),
                _TasksButton(childId: child.id),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IntroVideoScreen())),
                  child: Text(l10n.childHomeIntroAgain),
                ),
              ],
            ),
            Positioned(top: 8, right: 8, child: LighthouseButton(state: state)),
          ],
        ),
      ),
    );
  }
}

/// Knopf zur Schatztruhe. Sind Wunschflaschen angespült, steht darunter ein Hinweis
/// (statt einer Push-Nachricht, CLAUDE.md Abschnitt 10). Lädt neu nach der Rückkehr.
class _TreasureButton extends StatefulWidget {
  const _TreasureButton({required this.childId});

  final String childId;

  @override
  State<_TreasureButton> createState() => _TreasureButtonState();
}

class _TreasureButtonState extends State<_TreasureButton> {
  int _due = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final budget = AppScope.of(context).budget;
    if (budget == null) return;
    try {
      final status = await budget.fetchWishBottleStatus(widget.childId);
      if (mounted) setState(() => _due = status.due);
    } on Object {
      // Nur ein Hinweis: Ohne Verbindung erscheint er einfach nicht.
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TreasureScreen(childId: widget.childId)));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: Badge(isLabelVisible: _due > 0, label: Text('$_due'), child: const Icon(Icons.inventory_2_outlined)),
          onPressed: _open,
          label: Text(l10n.childHomeTreasureButton),
        ),
        if (_due > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.childHomeWishDue(_due),
              key: const ValueKey('child-home-wish-due'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

/// Knopf zu den Aufträgen mit der Zahl der Aufträge, die das Kind melden kann.
/// Lädt die Zahl neu, wenn das Kind von den Aufträgen zurückkommt.
class _TasksButton extends StatefulWidget {
  const _TasksButton({required this.childId});

  final String childId;

  @override
  State<_TasksButton> createState() => _TasksButtonState();
}

class _TasksButtonState extends State<_TasksButton> {
  int _open = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final budget = AppScope.of(context).budget;
    if (budget == null) return;
    try {
      final tasks = await budget.fetchTasks(widget.childId);
      if (mounted) setState(() => _open = tasks.where((t) => t.canSubmit).length);
    } on Object {
      // Nur ein Hinweis: Ohne Verbindung zeigt der Knopf einfach keine Zahl.
    }
  }

  Future<void> _openTasks() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TasksScreen(childId: widget.childId)));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: Badge(isLabelVisible: _open > 0, label: Text('$_open'), child: const Icon(Icons.checklist)),
          onPressed: _openTasks,
          label: Text(l10n.childHomeTasksButton),
        ),
        if (_open > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.childHomeTasksOpen(_open),
              key: const ValueKey('child-home-open-tasks'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

/// Rang, Seemeilen und Fahrtwind, dazu der Weg zur Karte und zu den Orden.
/// Lädt neu, wenn das Kind von der Karte oder den Orden zurückkommt.
class _ProgressSection extends StatefulWidget {
  const _ProgressSection({required this.state});

  final SessionChild state;

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  ChildStatsController? _controller;

  ChildProfile get _child => widget.state.child;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final progress = AppScope.of(context).progress;
    if (_controller == null && progress != null) {
      _controller = ChildStatsController(progress: progress, childId: _child.id)..load();
      unawaited(_controller!.markAppOpened());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _controller?.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;
    return ListenableBuilder(
      listenable: controller ?? const AlwaysStoppedAnimation(0),
      builder: (context, _) {
        final stats = controller?.stats;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stats != null) ...[StatsCard(stats: stats), const SizedBox(height: 16)],
            FilledButton(
              onPressed: () => _open(IslandMapScreen(child: _child)),
              child: Text(l10n.childHomeMapButton),
            ),
            if (stats != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.military_tech_outlined),
                onPressed: () => _open(BadgesScreen(childId: _child.id)),
                label: Text(l10n.badgesButton(stats.badgeCount)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.scuba_diving),
                onPressed: () => _open(CollectionScreen(childId: _child.id, pearls: stats.pearls)),
                label: Text(l10n.collectionButton(stats.finds)),
              ),
            ],
          ],
        );
      },
    );
  }
}
