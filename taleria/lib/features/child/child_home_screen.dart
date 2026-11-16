import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../core/theme/taleria_theme.dart' show displayFont;
import '../../domain/avatar.dart';
import '../../domain/family_models.dart';
import '../../domain/budget_models.dart';
import '../../domain/daily_greeting.dart';
import '../../domain/money.dart';
import '../../domain/progress_models.dart';
import '../../domain/shipyard.dart';
import '../../l10n/app_localizations.dart';
import '../../services/child_stats_controller.dart';
import '../../services/session_controller.dart';
import '../common/avatar_view.dart';
import '../common/busy_action.dart';
import '../common/texts.dart';
import '../common/wood_sign.dart';
import '../common/lively_figure.dart';
import '../common/menu_music.dart';
import '../common/scene_background.dart';
import '../home/preview_home_screen.dart' show IntroVideoScreen;
import '../intro/speech_bubble.dart';
import '../map/island_map_screen.dart';
import '../map/map_painters.dart';
import '../progress/badges_screen.dart';
import '../progress/collection_screen.dart';
import '../progress/rank_ladder_screen.dart';
import '../treasure/tasks_screen.dart';
import '../treasure/treasure_screen.dart';
import 'board_tour.dart';
import 'games_screen.dart';

import 'lighthouse_button.dart';

import 'rank_form_choice.dart';
import 'shipyard_screen.dart';
import 'sound_button.dart';

/// Kinderbereich nach dem Intro: Startseite auf dem Schiffsdeck. Oben Rang
/// und Leuchtturm, darunter die Crew (Talo, das Kind, Tala) mit dem Satz des
/// Tages, ein großes Holzschild zur Karte und die Bereiche als Bilder auf dem
/// Deck (Entwurf vom 16.11.2026 mit Marc, BILDER.md Abschnitt 4r). Keine Preise,
/// keine Kauf-Knöpfe, keine Links nach außen.
class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key, required this.state});

  final SessionChild state;

  @override
  Widget build(BuildContext context) {
    // Meeresrauschen, solange die Startseite vorn ist.
    return MenuMusic(
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _DeckBackground()),
            // Möwen am Himmel und Glitzern auf dem Meer (nur mit Bewegung).
            const Positioned.fill(child: IgnorePointer(child: _DeckLife())),
            SafeArea(child: _HomeBody(state: state)),
          ],
        ),
      ),
    );
  }
}

/// Einmalige Frage, wie die Ränge heißen sollen (für Kinder, die vor der
/// Frage in der Einführung angefangen haben). Verschwindet nach der Wahl.
class _RankFormCard extends StatefulWidget {
  const _RankFormCard({required this.childId});

  final String childId;

  @override
  State<_RankFormCard> createState() => _RankFormCardState();
}

class _RankFormCardState extends State<_RankFormCard> {
  bool _busy = false;

  Future<void> _choose(RankForm form) async {
    final services = AppScope.of(context);
    setState(() => _busy = true);
    await runWithFeedback(context, () async {
      await services.children!.updateLook(widget.childId, rankForm: form);
      await services.session.refresh();
    });
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PaperCard(
      key: const ValueKey('home-rank-form'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpeechBubble(speaker: Speaker.tala, pose: CharacterPose.think, text: l10n.rankFormQuestion),
          const SizedBox(height: 16),
          RankFormChoice(busy: _busy, onChoose: _choose),
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

/// Bewegung auf dem Deck: ab und zu ein Möwenschwarm oben am Himmel und
/// Lichtpunkte, die auf dem Meer glitzern. Steht still bei „Bewegung
/// reduzieren“ und in Tests (`sceneMotion`).
class _DeckLife extends StatefulWidget {
  const _DeckLife();

  @override
  State<_DeckLife> createState() => _DeckLifeState();
}

class _DeckLifeState extends State<_DeckLife> with SingleTickerProviderStateMixin {
  // Eine Minute pro Durchlauf, wie die Uhr der Karte.
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(minutes: 1));
  bool _motion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = AppScope.of(context).sceneMotion && !MediaQuery.disableAnimationsOf(context);
    if (_motion && !_clock.isAnimating) {
      // Gleich zu Beginn ein Schwarm, damit man ihn sieht.
      _clock.value = 0.06;
      _clock.repeat();
    } else if (!_motion && _clock.isAnimating) {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_motion) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: constraints.maxHeight * 0.4,
            child: CustomPaint(painter: SeagullPainter(clock: _clock)),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _GlitterPainter(clock: _clock)),
          ),
        ],
      ),
    );
  }
}

/// Lichtpunkte, die langsam auf- und abglimmen (wie Sonne auf dem Wasser).
class _GlitterPainter extends CustomPainter {
  _GlitterPainter({required this.clock}) : super(repaint: clock);

  final Animation<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = sceneSeconds(clock);
    final rnd = Random(7);
    for (var i = 0; i < 14; i++) {
      final x = rnd.nextDouble() * size.width;
      // Im oberen Teil, wo das Meer hinter dem Deck zu sehen ist.
      final y = size.height * (0.12 + rnd.nextDouble() * 0.3);
      final glow = max(0.0, osc(t, 10 + rnd.nextInt(8), rnd.nextDouble() * 6));
      if (glow < 0.05) continue;
      final r = 2.0 + 3.0 * glow;
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.75 * glow);
      canvas.drawCircle(Offset(x, y), r * 0.45, paint);
      canvas
        ..drawLine(Offset(x - r * 1.6, y), Offset(x + r * 1.6, y), paint..strokeWidth = 1.4)
        ..drawLine(Offset(x, y - r * 1.6), Offset(x, y + r * 1.6), paint);
    }
  }

  @override
  bool shouldRepaint(_GlitterPainter old) => false;
}

/// Talo links, das Kind in der Mitte mit seinem Namen, Tala rechts. Talo und
/// Tala winken und sagen beim Antippen etwas.
class _Crew extends StatelessWidget {
  const _Crew({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: LivelyFigure(
                  character: AssetKeys.talo,
                  phase: 0,
                  width: 116,
                  height: 150,
                  lines: [l10n.livelyTalo1, l10n.livelyTalo2, l10n.livelyTalo3, l10n.livelyTalo4],
                ),
              ),
            ),
            // Das Kind selbst: Löwe oder Löwin, winkt; Antippen lässt es etwas sagen.
            LivelyFigure(
              character: avatarKey(child.avatar ?? const AvatarConfig()),
              phase: 0.25,
              width: 124,
              height: 170,
              lines: [l10n.livelyKid1, l10n.livelyKid2, l10n.livelyKid3],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: LivelyFigure(
                  character: AssetKeys.tala,
                  phase: 0.5,
                  width: 116,
                  height: 156,
                  bubbleToLeft: true,
                  lines: [l10n.livelyTala1, l10n.livelyTala2, l10n.livelyTala3, l10n.livelyTala4],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _NameSign(
          nickname: child.nickname,
          shipName: child.shipName,
          flag: (child.avatar ?? const AvatarConfig()).flag,
        ),
      ],
    );
  }
}

/// Holzschild mit dem Namen des Kindes, darunter sein Schiff. Die Begrüßung
/// liest der Bildschirmleser vor.
class _NameSign extends StatelessWidget {
  const _NameSign({required this.nickname, required this.shipName, required this.flag});

  final String nickname;
  final String? shipName;
  final ShipFlag flag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      label: l10n.childHomeWelcome(nickname),
      excludeSemantics: true,
      child: WoodPanel(
        key: const ValueKey('home-name'),
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
        radius: 14,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(nickname, style: theme.textTheme.headlineSmall?.copyWith(color: WoodColors.cream, height: 1.2)),
            if (shipName != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlaggedShip(flag: flag, size: 26),
                  const SizedBox(width: 4),
                  Text(
                    l10n.childHomeShip(shipName!),
                    style: theme.textTheme.labelLarge?.copyWith(color: WoodColors.cream, fontSize: 14),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Holzschild oben: Rang mit Abzeichen, Seemeilen und ein Balken bis zum
/// nächsten Rang. Weht Fahrtwind, steht er als kleines Zeichen daneben.
/// Antippen öffnet alle Ränge (dort stehen auch die Erklärungen).
class _RankPlaque extends StatelessWidget {
  const _RankPlaque({required this.stats, required this.rankForm, required this.onTap});

  final ChildStats stats;
  final RankForm? rankForm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rank = stats.rank;
    final progress = stats.nextRankNeedsCertificate ? 0.0 : stats.progressToNextRank;
    final wind = !stats.streakPaused && stats.streakWeeks > 0;
    return WoodPanel(
      key: const ValueKey('stats-open-ranks'),
      onTap: onTap,
      semanticLabel: '${l10n.rank(rank, rankForm)}, ${l10n.statsXp(stats.xp)}. ${l10n.ranksOpen}',
      padding: const EdgeInsets.fromLTRB(5, 5, 12, 6),
      radius: 30,
      child: Row(
        children: [
          Opacity(
            opacity: rank == null ? 0.5 : 1,
            child: ClipOval(
              child: TaleriaAsset(AssetKeys.rank((rank ?? Rank.schiffsjunge).code), width: 40, height: 40),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.rank(rank, rankForm),
                    key: const ValueKey('stats-rank'),
                    maxLines: 1,
                    style: theme.textTheme.titleLarge?.copyWith(color: WoodColors.cream, fontSize: 18, height: 1.1),
                  ),
                ),
                Text(
                  l10n.statsXp(stats.xp),
                  key: const ValueKey('stats-xp'),
                  style: theme.textTheme.labelMedium?.copyWith(color: WoodColors.brass, fontWeight: FontWeight.w800),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      color: WoodColors.brass,
                      backgroundColor: const Color(0x55000000),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (wind) ...[
            const SizedBox(width: 6),
            const Icon(Icons.air_rounded, size: 20),
            Text('${stats.streakWeeks}', style: theme.textTheme.labelLarge?.copyWith(color: WoodColors.cream)),
          ],
        ],
      ),
    );
  }
}

/// Satz des Tages von Talo oder Tala (jeden Tag ein anderer, ohne Druck),
/// als Sprechblase über der Crew. Die Spitze zeigt auf den, der spricht.
class _GreetingBubble extends StatelessWidget {
  const _GreetingBubble({required this.greeting, required this.rankForm});

  final DailyGreeting greeting;
  final RankForm? rankForm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final g = greeting;
    final text = switch (g.kind) {
      GreetingKind.wind => l10n.greetingWind,
      GreetingKind.waitWind => l10n.greetingWaitWind(l10n.weekday('${g.date!.weekday}')),
      GreetingKind.rankSoon => l10n.greetingRankSoon(g.number, l10n.rank(g.rank, rankForm)),
      GreetingKind.goalReady => l10n.greetingGoalReady(g.title!),
      GreetingKind.goalSoon => l10n.greetingGoalSoon(g.title!, formatCents(g.number)),
      GreetingKind.streak => l10n.greetingStreak(g.number),
      GreetingKind.reviews => l10n.greetingReviews,
      GreetingKind.tip => switch (g.number) {
        0 => l10n.greetingTip0,
        1 => l10n.greetingTip1,
        2 => l10n.greetingTip2,
        3 => l10n.greetingTip3,
        4 => l10n.greetingTip4,
        _ => l10n.greetingTip5,
      },
    };
    final tala = g.speaker == 'tala';
    final (name, color) = tala ? (l10n.speakerTala, palette.tala) : (l10n.speakerTalo, palette.talo);
    return Semantics(
      container: true,
      label: '$name: $text',
      excludeSemantics: true,
      child: Column(
        key: const ValueKey('home-greeting'),
        crossAxisAlignment: tala ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x33081C30), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(fontFamily: displayFont, color: color),
                ),
                Text(text, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: CustomPaint(size: const Size(22, 12), painter: _BubbleTail()),
          ),
        ],
      ),
    );
  }
}

/// Spitze der Sprechblase, nach unten zur sprechenden Figur.
class _BubbleTail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BubbleTail old) => false;
}

/// Ein Bereich als Bild auf dem Deck (Schatztruhe, Aufträge, Orden …), ohne
/// Kasten: das Bild, darunter der Name auf einem hellen Schildchen. [count]
/// erscheint als Zahl am Bild: golden für Sammelstände, korallenrot, wenn
/// etwas auf das Kind wartet ([attention]). [hint] steht klein darunter.
class _DeckItem extends StatefulWidget {
  const _DeckItem({
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
    this.art,
  });

  final String image;

  /// Statt des Bilds [image] ein gezeichnetes Bild (zum Beispiel das eigene Schiff).
  final Widget? art;
  final IconData fallbackIcon;
  final String label;
  final VoidCallback onTap;
  final int count;
  final bool attention;
  final String? hint;
  final Key? hintKey;
  final String? semanticLabel;

  @override
  State<_DeckItem> createState() => _DeckItemState();
}

class _DeckItemState extends State<_DeckItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final w = widget;
    return Semantics(
      button: true,
      label: w.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: w.onTap,
        // Beim Antippen wird das Bild kurz etwas kleiner, wie ein Knopf.
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1,
          duration: const Duration(milliseconds: 90),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 78,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      w.art ??
                          TaleriaAsset(
                            w.image,
                            height: 78,
                            width: 104,
                            fallback: Icon(w.fallbackIcon, size: 52, color: palette.seaDeep),
                          ),
                      if (w.count > 0)
                        Positioned(
                          top: -4,
                          right: 0,
                          child: _CountBubble(count: w.count, attention: w.attention),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xF2FFF8E6),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Color(0x33081C30), offset: Offset(0, 2))],
                  ),
                  // Eine Zeile, notfalls etwas kleiner: „Sammlung“ brach in schmalen Spalten mitten im Wort um.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      w.label,
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w800,
                        color: palette.ink,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
                if (w.hint != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: palette.coral.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      w.hint!,
                      key: w.hintKey,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
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

/// Das große Holzschild zur Karte, das Wichtigste auf der Startseite.
class _MapSign extends StatelessWidget {
  const _MapSign({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return WoodPanel(
      onTap: onTap,
      semanticLabel: l10n.childHomeMapButton,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
      child: Row(
        children: [
          const TaleriaAsset(AssetKeys.iconMap, width: 104, height: 70, fallback: Icon(Icons.map_rounded, size: 48)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.childHomeMapButton,
              style: theme.textTheme.headlineMedium?.copyWith(color: WoodColors.cream, shadows: WoodColors.textShadows),
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, size: 34),
        ],
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
    return _DeckItem(
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
    return _DeckItem(
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

/// Alles auf dem Deck. Lädt Rang, Funde und Wunschschätze neu, wenn das Kind
/// von einer anderen Seite zurückkommt.
class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.state});

  final SessionChild state;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  ChildStatsController? _controller;

  /// Funde, die das Kind in der Sammlung schon gesehen hat (auf diesem Gerät).
  int _collectionSeen = 0;

  /// Werft-Teile, die das Kind schon gesehen hat (auf diesem Gerät).
  int _shipyardSeen = 0;

  /// Wunschschätze für den Satz des Tages („Für den Ball fehlen nur noch …“).
  List<SavingsGoal> _goals = const [];

  ChildProfile get _child => widget.state.child;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final progress = AppScope.of(context).progress;
    if (_controller == null && progress != null) {
      _controller = ChildStatsController(progress: progress, childId: _child.id)..load();
      unawaited(_controller!.markAppOpened());
      unawaited(_loadCollectionSeen());
      unawaited(_loadGoals());
    }
  }

  /// Ohne Wunschschätze sagt Talo eben etwas anderes; Fehler stören hier nicht.
  Future<void> _loadGoals() async {
    final budget = AppScope.of(context).budget;
    if (budget == null) return;
    try {
      final goals = await budget.fetchGoals(_child.id);
      if (mounted) setState(() => _goals = goals);
    } on AppFailure {
      // Kein Satz über Wunschschätze.
    }
  }

  Future<void> _loadCollectionSeen() async {
    final settings = AppScope.of(context).settings;
    final seen = await settings.collectionSeen(_child.id);
    final shipyard = await settings.lookUnlocksSeen(_child.id);
    if (mounted) {
      setState(() {
        _collectionSeen = seen;
        _shipyardSeen = shipyard;
      });
    }
  }

  /// Öffnet die Werft; danach gelten alle freien Teile als gesehen.
  Future<void> _openShipyard(ChildStats stats) async {
    final settings = AppScope.of(context).settings;
    final unlocked = unlockedShipyardCount(stats.xp);
    setState(() => _shipyardSeen = unlocked);
    await settings.setLookUnlocksSeen(_child.id, unlocked);
    await _open(ShipyardScreen(child: _child, xp: stats.xp));
  }

  /// Öffnet die Sammlung; danach gelten alle Funde als gesehen.
  Future<void> _openCollection(ChildStats stats) async {
    final settings = AppScope.of(context).settings;
    setState(() => _collectionSeen = stats.finds);
    await settings.setCollectionSeen(_child.id, stats.finds);
    await _open(CollectionScreen(childId: _child.id, pearls: stats.pearls));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _controller?.load();
    if (mounted) await _loadGoals();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;
    final child = _child;
    return ListenableBuilder(
      listenable: controller ?? const AlwaysStoppedAnimation(0),
      builder: (context, _) {
        final stats = controller?.stats;
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          children: [
            Row(
              children: [
                const SoundButton(),
                const SizedBox(width: 6),
                Expanded(
                  child: stats == null
                      ? const SizedBox.shrink()
                      : _RankPlaque(
                          stats: stats,
                          rankForm: child.rankForm,
                          onTap: () => _open(RankLadderScreen(stats: stats, rankForm: child.rankForm)),
                        ),
                ),
                const SizedBox(width: 6),
                LighthouseButton(state: widget.state),
              ],
            ),
            const SizedBox(height: 6),
            if (stats != null)
              _GreetingBubble(
                greeting: dailyGreeting(day: DateTime.now(), stats: stats, goals: _goals),
                rankForm: child.rankForm,
              ),
            _Crew(child: child),
            const SizedBox(height: 14),
            // Wer vor dieser Frage schon gespielt hat, wählt einmal hier.
            if (child.rankForm == null) ...[_RankFormCard(childId: child.id), const SizedBox(height: 14)],
            _MapSign(onTap: () => _open(IslandMapScreen(child: child))),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _TreasureButton(childId: child.id)),
                Expanded(child: _TasksButton(childId: child.id)),
                Expanded(
                  child: stats == null
                      ? const SizedBox.shrink()
                      : Builder(
                          builder: (context) {
                            final fresh = max(0, unlockedShipyardCount(stats.xp) - _shipyardSeen);
                            return _DeckItem(
                              key: const ValueKey('home-shipyard'),
                              image: '',
                              art: FlaggedShip(flag: (child.avatar ?? const AvatarConfig()).flag, size: 78),
                              fallbackIcon: Icons.sailing_rounded,
                              label: l10n.childHomeShipyardTile,
                              semanticLabel: l10n.childHomeShipyardTile,
                              count: fresh,
                              attention: true,
                              hint: fresh > 0 ? l10n.childHomeShipyardNew(fresh) : null,
                              hintKey: const ValueKey('child-home-shipyard-new'),
                              onTap: () => _openShipyard(stats),
                            );
                          },
                        ),
                ),
              ],
            ),
            if (stats != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DeckItem(
                      key: const ValueKey('home-badges'),
                      image: AssetKeys.iconBadges,
                      fallbackIcon: Icons.military_tech_outlined,
                      label: l10n.childHomeBadgesTile,
                      semanticLabel: l10n.badgesButton(stats.badgeCount),
                      count: stats.badgeCount,
                      onTap: () => _open(BadgesScreen(childId: child.id)),
                    ),
                  ),
                  Expanded(
                    // Die Zahl leuchtet nur für neue Funde, die das Kind noch nicht gesehen hat.
                    child: _DeckItem(
                      key: const ValueKey('home-collection'),
                      image: AssetKeys.iconCollection,
                      fallbackIcon: Icons.scuba_diving,
                      label: l10n.childHomeCollectionTile,
                      semanticLabel: l10n.collectionButton(stats.finds),
                      count: max(0, stats.finds - _collectionSeen),
                      attention: true,
                      hint: stats.finds > _collectionSeen
                          ? l10n.childHomeNewFinds(stats.finds - _collectionSeen)
                          : null,
                      hintKey: const ValueKey('child-home-new-finds'),
                      onTap: () => _openCollection(stats),
                    ),
                  ),
                  Expanded(
                    child: _DeckItem(
                      key: const ValueKey('home-games'),
                      image: AssetKeys.iconGames,
                      fallbackIcon: Icons.sports_esports_rounded,
                      label: l10n.childHomeGamesTile,
                      semanticLabel: l10n.childHomeGamesTile,
                      onTap: () => _open(GamesScreen(child: child)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            // Hilfen, die man selten braucht: klein am Ende.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _DeckLink(
                  key: const ValueKey('tour-button'),
                  icon: Icons.explore_rounded,
                  label: l10n.tourButton,
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BoardTourScreen())),
                ),
                _DeckLink(
                  icon: Icons.play_circle_outline_rounded,
                  label: l10n.childHomeIntroAgain,
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IntroVideoScreen())),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Kleiner heller Knopf am Ende der Startseite (Rundgang, Intro).
class _DeckLink extends StatelessWidget {
  const _DeckLink({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.paper.withValues(alpha: 0.9),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: palette.seaDeep),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: palette.seaDeep, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
