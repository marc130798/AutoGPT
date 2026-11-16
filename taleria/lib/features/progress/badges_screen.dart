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

  /// Heranzoomen an die Wand (0 = normal, 1 = nah).
  late final AnimationController _zoom = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

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
      await _zoom.forward();
    } on Object {
      // Ohne Verbindung zeigt die Seite selbst den Fehler; gefeiert wird dann nicht.
    }
  }

  Future<void> _hang() async {
    final slug = _ceremony?.slug;
    await _zoom.reverse();
    if (!mounted) return;
    setState(() {
      _ceremony = null;
      _justHung = slug;
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
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _zoom,
                // Die Wand kommt näher, als ginge man auf sie zu.
                builder: (context, child) =>
                    Transform.scale(scale: 1 + 0.15 * Curves.easeInOut.transform(_zoom.value), child: child),
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
                child: _HangCeremony(badge: ceremony, zoom: _zoom, onHang: _hang),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, this.hidden = false, this.glow = false});

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

/// Die Feier für einen neuen Orden: Es wird dunkler, der Orden fällt an
/// seinem Band herein und schwingt aus. Mit „An die Wand hängen“ fliegt er
/// klein an die Wand, die Wand zoomt wieder zurück.
class _HangCeremony extends StatefulWidget {
  const _HangCeremony({required this.badge, required this.zoom, required this.onHang});

  final BadgeInfo badge;

  /// Läuft mit dem Heranzoomen der Wand: hinein beim Start, hinaus beim Aufhängen.
  final Animation<double> zoom;
  final VoidCallback onHang;

  @override
  State<_HangCeremony> createState() => _HangCeremonyState();
}

class _HangCeremonyState extends State<_HangCeremony> with SingleTickerProviderStateMixin {
  /// Herabfallen und Ausschwingen (einmal, etwa zwei Sekunden).
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool _hanging = false;

  @override
  void initState() {
    super.initState();
    _swing.forward();
  }

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  void _hang() {
    if (_hanging) return;
    setState(() => _hanging = true);
    widget.onHang();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final calm = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_swing, widget.zoom]),
      builder: (context, _) {
        final z = widget.zoom.value;
        final t = calm ? 1.0 : _swing.value;
        // Erst fallen (das erste Viertel), dann gedämpft hin- und herschwingen.
        final drop = Curves.easeOutBack.transform((t / 0.25).clamp(0.0, 1.0));
        final swing = t < 0.25 ? 0.0 : 0.22 * exp(-4 * (t - 0.25)) * sin((t - 0.25) * 18);
        // Beim Aufhängen wird der Orden klein und verschwindet an der Wand.
        final size = _hanging ? 0.3 + 0.7 * z : 1.0;
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
                        radius: 0.6,
                        colors: [Color.fromRGBO(255, 214, 107, 0.4 * z), const Color(0x00FFD66B)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Opacity(
                opacity: z,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(0, -260 * (1 - drop)),
                      child: Transform.scale(
                        scale: size,
                        child: Transform.rotate(
                          angle: swing,
                          alignment: Alignment.topCenter,
                          child: Column(
                            children: [
                              // Der Nagel, an dem der Orden hängt.
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [Color(0xFFFFE9A8), Color(0xFF8A6A1E)]),
                                ),
                              ),
                              TaleriaAsset(widget.badge.assetKey, width: 220, height: 220),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!_hanging) ...[
                      const SizedBox(height: 12),
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
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
