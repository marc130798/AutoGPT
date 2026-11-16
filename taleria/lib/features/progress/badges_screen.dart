import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/menu_music.dart';
import '../common/page_intro.dart';
import '../common/scene_background.dart';
import '../common/taleria_app_bar.dart';
import '../common/texts.dart';
import '../common/wood_sign.dart';
import '../intro/speech_bubble.dart';
import 'showcase.dart';
import '../common/play_effect.dart';

/// Orden-Sammlung des Kindes als Ehrenwand: verdiente Orden hängen an einem
/// Nagel, die anderen sind blass und warten noch („Noch nicht gefunden“).
/// Ist seit dem letzten Besuch ein Orden dazugekommen, zoomt die Wand heran,
/// der Orden schwingt herein und das Kind hängt ihn selbst auf (Wunsch von
/// Marc, 16.11.2026).
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key, required this.childId});

  final String childId;

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> with SingleTickerProviderStateMixin {
  Future<List<BadgeInfo>>? _badges;

  /// Der neue Orden, der gerade aufgehängt wird (`null` = keine Feier).
  BadgeInfo? _ceremony;

  /// Der Orden, der nach dem Aufhängen kurz leuchtet.
  String? _justHung;

  /// Heranzoomen an die Wand (0 = normal, 1 = nah), genau auf den leeren
  /// Platz des neuen Ordens.
  late final AnimationController _zoom = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  /// Der Platz des neuen Ordens an der Wand und die ganze Seite, zum Messen.
  final _slotKey = GlobalKey();
  final _bodyKey = GlobalKey();

  /// Mitte des Ordens an seinem Platz, in Koordinaten der Seite.
  Offset? _target;
  Alignment _zoomAlignment = Alignment.center;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_badges != null) return;
    _badges = AppScope.of(context).progress!.fetchBadges(widget.childId);
    unawaited(_checkNew());
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  /// Gibt es mehr Orden als beim letzten Besuch, wird der neueste gefeiert.
  Future<void> _checkNew() async {
    final settings = AppScope.of(context).settings;
    try {
      final badges = await _badges!;
      final earned = badges.where((b) => b.earned).toList()..sort((a, b) => a.earnedAt!.compareTo(b.earnedAt!));
      final seen = await settings.badgesSeen(widget.childId);
      // Gleich merken: Verlässt das Kind die Seite, kommt die Feier nicht noch einmal.
      if (earned.length != seen) await settings.setBadgesSeen(widget.childId, earned.length);
      if (!mounted || earned.length <= seen) return;
      setState(() => _ceremony = earned.last);
      // Den leeren Platz sichtbar machen und ausmessen, bevor die Wand heranzoomt.
      await WidgetsBinding.instance.endOfFrame;
      final slot = _slotKey.currentContext;
      if (slot != null && slot.mounted) {
        await Scrollable.ensureVisible(slot, alignment: 0.6);
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!mounted) return;
      _measure();
      await _zoom.forward();
    } on Object {
      // Ohne Verbindung zeigt die Seite selbst den Fehler; gefeiert wird dann nicht.
    }
  }

  /// Wo genau das Bild des neuen Ordens an der Wand hängen wird.
  void _measure() {
    final tile = _slotKey.currentContext?.findRenderObject() as RenderBox?;
    final body = _bodyKey.currentContext?.findRenderObject() as RenderBox?;
    if (tile == null || body == null || !tile.attached) return;
    final topLeft = tile.localToGlobal(Offset.zero, ancestor: body);
    final center = topLeft + Offset(tile.size.width / 2, ShowcaseTile.wallImageCenter);
    setState(() {
      _target = center;
      _zoomAlignment = Alignment(center.dx / body.size.width * 2 - 1, center.dy / body.size.height * 2 - 1);
    });
  }

  /// Der Orden fliegt nach hinten an seinen Platz, die Wand zoomt zurück.
  void _hang() => _zoom.reverse();

  void _done() {
    if (!mounted) return;
    setState(() {
      _justHung = _ceremony?.slug;
      _ceremony = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ceremony = _ceremony;
    return MenuMusic(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: TaleriaAppBar(title: l10n.badgesTitle),
        body: Stack(
          key: _bodyKey,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _zoom,
                // Die Wand kommt näher, genau auf den leeren Platz zu.
                builder: (context, child) => Transform.scale(
                  scale: 1 + 0.25 * Curves.easeInOut.transform(_zoom.value),
                  alignment: _zoomAlignment,
                  child: child,
                ),
                child: SceneBackground(
                  assetKey: AssetKeys.badgesBackground,
                  child: SafeArea(
                    child: FutureBuilder<List<BadgeInfo>>(
                      future: _badges,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          final error = snapshot.error;
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(l10n.failure(error is AppFailure ? error.kind : FailureKind.unknown)),
                            ),
                          );
                        }
                        final badges = snapshot.data;
                        if (badges == null) return const Center(child: CircularProgressIndicator());
                        final earned = badges.where((b) => b.earned).length;
                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            PageIntro(
                              childId: widget.childId,
                              page: 'badges',
                              children: [
                                SpeechBubble(speaker: Speaker.talo, pose: CharacterPose.happy, text: l10n.badgesIntro),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (earned == 0) PaperCard(child: Text(l10n.badgesEmpty, style: theme.textTheme.bodyLarge)),
                            const SizedBox(height: 8),
                            ShowcaseGrid(
                              children: [
                                for (final badge in badges)
                                  _BadgeTile(
                                    key: badge.slug == ceremony?.slug ? _slotKey : null,
                                    badge: badge,
                                    // Während der Feier ist der Platz an der Wand noch leer.
                                    hidden: badge.slug == ceremony?.slug,
                                    glow: badge.slug == _justHung,
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (ceremony != null)
              Positioned.fill(
                child: _HangCeremony(badge: ceremony, zoom: _zoom, target: _target, onHang: _hang, onDone: _done),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({super.key, required this.badge, this.hidden = false, this.glow = false});

  final BadgeInfo badge;
  final bool hidden;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Opacity(
      opacity: hidden ? 0 : 1,
      child: ShowcaseTile(
        key: ValueKey('badge-${badge.slug}'),
        assetKey: badge.assetKey,
        title: badge.title,
        caption: badge.earned ? l10n.badgeEarnedOn(formatDate(badge.earnedAt!)) : l10n.badgeNotYet,
        earned: badge.earned,
        wall: true,
        glow: glow,
      ),
    );
  }
}

/// Die Feier für einen neuen Orden: Es wird dunkler, der Orden fällt groß
/// vorne an seinem Band herein und schwingt aus. Mit „An die Wand hängen“
/// fliegt er in einem kleinen Bogen nach hinten an seinen Nagel an der Wand
/// und wird dabei so klein wie die anderen Orden.
class _HangCeremony extends StatefulWidget {
  const _HangCeremony({
    required this.badge,
    required this.zoom,
    required this.target,
    required this.onHang,
    required this.onDone,
  });

  final BadgeInfo badge;

  /// Läuft mit dem Heranzoomen der Wand: hinein beim Start, hinaus beim Aufhängen.
  final Animation<double> zoom;

  /// Mitte des Platzes an der Wand (`null` = nicht messbar, dann in der Mitte).
  final Offset? target;
  final VoidCallback onHang;
  final VoidCallback onDone;

  @override
  State<_HangCeremony> createState() => _HangCeremonyState();
}

class _HangCeremonyState extends State<_HangCeremony> with TickerProviderStateMixin {
  static const double _bigSize = 220;

  /// Herabfallen und Ausschwingen (einmal, gut zwei Sekunden).
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  /// Flug nach hinten an die Wand.
  late final AnimationController _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    _swing.forward();
  }

  @override
  void dispose() {
    _swing.dispose();
    _fly.dispose();
    super.dispose();
  }

  Future<void> _hang() async {
    if (_fly.isAnimating || _fly.isCompleted) return;
    widget.onHang();
    await _fly.forward();
    if (mounted) playEffect(context, AssetKeys.soundBadgeHang);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final calm = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: Listenable.merge([_swing, _fly, widget.zoom]),
        builder: (context, _) {
          final z = widget.zoom.value;
          final t = calm ? 1.0 : _swing.value;
          final f = Curves.easeInOutCubic.transform(_fly.value);
          // Erst fallen (das erste Viertel), dann gedämpft hin- und herschwingen.
          final drop = Curves.easeOutBack.transform((t / 0.25).clamp(0.0, 1.0));
          final swing = t < 0.25 ? 0.0 : 0.22 * exp(-4 * (t - 0.25)) * sin((t - 0.25) * 18);
          final start = Offset(constraints.maxWidth / 2, constraints.maxHeight * 0.4 - 280 * (1 - drop));
          final target = widget.target ?? start;
          // Auf dem Weg nach hinten ein kleiner Bogen nach oben.
          final center = Offset.lerp(start, target, f)! - Offset(0, 70 * sin(pi * f));
          final size = _bigSize + (ShowcaseTile.wallImageSize - _bigSize) * f;
          final textOpacity = (1 - _fly.value * 3).clamp(0.0, 1.0) * z.clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _hang,
                  child: ColoredBox(
                    color: Color.fromRGBO(8, 20, 34, 0.82 * z),
                    // Hinter dem Orden ein warmer Lichtschein.
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(
                            center.dx / constraints.maxWidth * 2 - 1,
                            center.dy / constraints.maxHeight * 2 - 1,
                          ),
                          radius: 0.6 * (1 - f) + 0.2,
                          colors: [Color.fromRGBO(255, 214, 107, 0.4 * z), const Color(0x00FFD66B)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: center.dx - size / 2,
                top: center.dy - size / 2,
                width: size,
                height: size,
                child: Transform.rotate(
                  angle: swing * (1 - f),
                  alignment: Alignment.topCenter,
                  child: TaleriaAsset(widget.badge.assetKey, width: size, height: size),
                ),
              ),
              if (textOpacity > 0)
                Positioned(
                  left: 16,
                  right: 16,
                  top: constraints.maxHeight * 0.4 + _bigSize / 2 + 8,
                  child: Opacity(
                    opacity: textOpacity,
                    child: Column(
                      children: [
                        Text(
                          l10n.badgeCeremonyTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: WoodColors.cream,
                            shadows: WoodColors.textShadows,
                          ),
                        ),
                        WoodSign(text: widget.badge.title),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const ValueKey('badge-hang'),
                          onPressed: _hang,
                          icon: const Icon(Icons.push_pin_rounded),
                          label: Text(l10n.badgeCeremonyHang),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
