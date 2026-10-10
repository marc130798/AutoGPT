import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
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

/// Kinderbereich nach dem Intro: Startseite auf dem Schiffsdeck mit Talo,
/// Tala, dem Avatar im Bullauge, dem eigenen Schiff und großen Bild-Kacheln
/// (Bilder aus BILDER.md, Abschnitt 4). Keine Preise, keine Kauf-Knöpfe,
/// keine Links nach außen.
class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key, required this.state});

  final SessionChild state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final child = state.child;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _DeckBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: LighthouseButton(state: state),
                ),
                const SizedBox(height: 8),
                _CrewHeader(avatar: child.avatar ?? const AvatarConfig()),
                const SizedBox(height: 12),
                _WelcomeCard(nickname: child.nickname, shipName: child.shipName),
                const SizedBox(height: 16),
                _ProgressSection(
                  state: state,
                  budgetRow: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _TreasureButton(childId: child.id)),
                        const SizedBox(width: 12),
                        Expanded(child: _TasksButton(childId: child.id)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.palette.paper.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IntroVideoScreen())),
                      child: Text(l10n.childHomeIntroAgain),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hintergrund: Blick vom Schiffsdeck aufs Meer. Ohne Bild ein Verlauf von
/// Himmel über Meer zu Holz.
class _DeckBackground extends StatelessWidget {
  const _DeckBackground();

  @override
  Widget build(BuildContext context) {
    return const TaleriaAsset(
      AssetKeys.homeBackground,
      fit: BoxFit.cover,
      alignment: Alignment.bottomCenter,
      fallback: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8FD3F4), Color(0xFF3FB6D3), Color(0xFFC8A06A)],
            stops: [0, 0.6, 1],
          ),
        ),
      ),
    );
  }
}

/// Talo links, der Avatar des Kindes im Bullauge in der Mitte, Tala rechts.
class _CrewHeader extends StatelessWidget {
  const _CrewHeader({required this.avatar});

  final AvatarConfig avatar;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Align(alignment: Alignment.bottomCenter, child: TaleriaAsset(AssetKeys.talo, width: 112, height: 140)),
        ),
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.paper,
            border: Border.all(color: const Color(0xFFB8862B), width: 7),
            boxShadow: const [BoxShadow(color: Color(0x55081C30), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: ClipOval(
            child: Center(child: AvatarView(avatar: avatar, size: 112)),
          ),
        ),
        const Expanded(
          child: Align(alignment: Alignment.bottomCenter, child: TaleriaAsset(AssetKeys.tala, width: 112, height: 140)),
        ),
      ],
    );
  }
}

/// Begrüßung und das eigene Schiff mit seinem Namen.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.nickname, required this.shipName});

  final String nickname;
  final String? shipName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: palette.paper.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.gold.withValues(alpha: 0.7), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33081C30), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Text(
            l10n.childHomeWelcome(nickname),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: palette.ink),
          ),
          if (shipName != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TaleriaAsset(AssetKeys.crewShip, width: 64, height: 56),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.childHomeShip(shipName!),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Große Kachel mit Bild für die Startseite (Schatztruhe, Aufträge, Orden,
/// Sammlung). [count] erscheint als Zahl am Bild: golden für Sammelstände,
/// korallenrot, wenn etwas auf das Kind wartet ([attention]).
class _HomeTile extends StatelessWidget {
  const _HomeTile({
    super.key,
    required this.image,
    required this.fallbackIcon,
    required this.label,
    required this.onTap,
    this.count = 0,
    this.attention = false,
    this.hint,
    this.hintKey,
    this.semanticLabel,
  });

  final String image;
  final IconData fallbackIcon;
  final String label;
  final VoidCallback onTap;
  final int count;
  final bool attention;
  final String? hint;
  final Key? hintKey;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: palette.paper.withValues(alpha: 0.95),
        elevation: 3,
        shadowColor: const Color(0x66081C30),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.gold.withValues(alpha: 0.7), width: 2),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 76,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      TaleriaAsset(image, height: 76, fallback: Icon(fallbackIcon, size: 52, color: palette.seaDeep)),
                      if (count > 0)
                        Positioned(
                          top: -6,
                          right: -18,
                          child: _CountBubble(count: count, attention: attention),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: palette.ink),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(hint!, key: hintKey, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBubble extends StatelessWidget {
  const _CountBubble({required this.count, required this.attention});

  final int count;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: attention ? palette.coral : palette.gold,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.paper, width: 2),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
      ),
    );
  }
}

/// Die große Kachel zur Karte, das Wichtigste auf der Startseite.
class _MapTile extends StatelessWidget {
  const _MapTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Material(
      color: palette.seaDeep,
      elevation: 4,
      shadowColor: const Color(0x66081C30),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: palette.gold, width: 2.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              TaleriaAsset(
                AssetKeys.iconMap,
                width: 120,
                height: 84,
                fallback: Icon(Icons.map, size: 56, color: palette.paper),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.childHomeMapButton,
                  style: theme.textTheme.headlineSmall?.copyWith(color: palette.paper, fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.gold, size: 36),
            ],
          ),
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
    return _HomeTile(
      image: AssetKeys.iconTreasure,
      fallbackIcon: Icons.inventory_2_outlined,
      label: l10n.childHomeTreasureButton,
      onTap: _open,
      count: _due,
      attention: true,
      hint: _due > 0 ? l10n.childHomeWishDue(_due) : null,
      hintKey: const ValueKey('child-home-wish-due'),
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
    return _HomeTile(
      image: AssetKeys.iconTasks,
      fallbackIcon: Icons.checklist,
      label: l10n.childHomeTasksButton,
      onTap: _openTasks,
      count: _open,
      attention: true,
      hint: _open > 0 ? l10n.childHomeTasksOpen(_open) : null,
      hintKey: const ValueKey('child-home-open-tasks'),
    );
  }
}

/// Rang, Seemeilen und Fahrtwind, dazu der Weg zur Karte und zu den Orden.
/// Lädt neu, wenn das Kind von der Karte oder den Orden zurückkommt.
class _ProgressSection extends StatefulWidget {
  const _ProgressSection({required this.state, required this.budgetRow});

  final SessionChild state;

  /// Schatztruhe und Aufträge, zwischen Karte und Orden.
  final Widget budgetRow;

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
            _MapTile(onTap: () => _open(IslandMapScreen(child: _child))),
            const SizedBox(height: 12),
            widget.budgetRow,
            if (stats != null) ...[
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _HomeTile(
                        key: const ValueKey('home-badges'),
                        image: AssetKeys.iconBadges,
                        fallbackIcon: Icons.military_tech_outlined,
                        label: l10n.childHomeBadgesTile,
                        semanticLabel: l10n.badgesButton(stats.badgeCount),
                        count: stats.badgeCount,
                        onTap: () => _open(BadgesScreen(childId: _child.id)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HomeTile(
                        key: const ValueKey('home-collection'),
                        image: AssetKeys.iconCollection,
                        fallbackIcon: Icons.scuba_diving,
                        label: l10n.childHomeCollectionTile,
                        semanticLabel: l10n.collectionButton(stats.finds),
                        count: stats.finds,
                        onTap: () => _open(CollectionScreen(childId: _child.id, pearls: stats.pearls)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
