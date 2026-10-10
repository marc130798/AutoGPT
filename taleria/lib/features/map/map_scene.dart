import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/progress_logic.dart';
import '../../l10n/app_localizations.dart';
import 'map_painters.dart';

/// Eine längliche Wolke: Bild aus BILDER.md oder die gezeichnete Ersatz-Wolke.
/// Jede zweite ist gespiegelt, damit nicht alle gleich aussehen.
class MapCloud extends StatelessWidget {
  const MapCloud({super.key, required this.index, required this.width, required this.height});

  final int index;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: index.isOdd,
      child: TaleriaAsset(
        AssetKeys.mapClouds[index % AssetKeys.mapClouds.length],
        width: width,
        height: height,
        fit: BoxFit.fill,
        fallback: CustomPaint(
          size: Size(width, height),
          painter: CloudPainter(seed: index),
        ),
      ),
    );
  }
}

/// Die Insel, wie sie auf der Karte liegt: Bild oder gezeichnete Ersatz-Insel.
///
/// Das Bild füllt die Breite und steht unten auf der Kante des Felds. Hohe
/// Dinge wie ein Turm ragen oben über das Feld hinaus, so sind alle Inseln
/// gleich breit, egal wie hoch sie sind.
class IslandArt extends StatelessWidget {
  const IslandArt({super.key, required this.slug, required this.width, required this.height});

  final String slug;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      alignment: Alignment.bottomCenter,
      minHeight: 0,
      maxHeight: double.infinity,
      child: TaleriaAsset(
        AssetKeys.mapIsland(slug),
        width: width,
        fit: BoxFit.fitWidth,
        fallback: CustomPaint(size: Size(width, height), painter: FallbackIslandPainter(slug)),
      ),
    );
  }
}

/// Namensband unter einer Insel.
class MapLabel extends StatelessWidget {
  const MapLabel({super.key, required this.title, required this.state});

  final String title;
  final IslandState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final theme = Theme.of(context);
    final fog = state == IslandState.fog;
    final icon = switch (state) {
      IslandState.completed => Icon(Icons.check_circle, color: palette.gold, size: 18),
      IslandState.locked || IslandState.premium => const Icon(Icons.lock, color: Color(0xFF7D8894), size: 16),
      _ => null,
    };
    return Opacity(
      opacity: fog ? 0.78 : 1,
      child: CustomPaint(
        painter: const _RibbonTailsPainter(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: palette.paper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.ink.withValues(alpha: 0.15)),
            boxShadow: const [BoxShadow(color: Color(0x33081C30), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon, const SizedBox(width: 6)],
              Flexible(
                child: Text(
                  fog ? l10n.mapIslandFogTitle(title) : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.ink.withValues(alpha: fog ? 0.7 : 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Die Enden des Namensbands links und rechts.
class _RibbonTailsPainter extends CustomPainter {
  const _RibbonTailsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFD9C49A);
    final h = size.height, w = size.width;
    canvas.drawPath(
      Path()
        ..moveTo(8, 5)
        ..lineTo(-11, 7)
        ..lineTo(-4, h / 2 + 2)
        ..lineTo(-11, h + 3)
        ..lineTo(8, h)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w - 8, 5)
        ..lineTo(w + 11, 7)
        ..lineTo(w + 4, h / 2 + 2)
        ..lineTo(w + 11, h + 3)
        ..lineTo(w - 8, h)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RibbonTailsPainter oldDelegate) => false;
}

/// Gesperrte Inseln wirken blasser und etwas bläulich.
const _dimmed = ColorFilter.matrix(<double>[
  0.5, 0.3, 0.08, 0, 4, //
  0.18, 0.58, 0.08, 0, 6,
  0.18, 0.32, 0.42, 0, 12,
  0, 0, 0, 1, 0,
]);

/// Eine Insel auf der Karte: Wasser drumherum, Bild, Flagge, Schloss, Nebel
/// und Namensband. Antippen öffnet die Insel (oder zeigt einen Hinweis).
class MapIslandMarker extends StatelessWidget {
  const MapIslandMarker({
    super.key,
    required this.island,
    required this.state,
    required this.width,
    required this.height,
    required this.clock,
    required this.onTap,
    this.glow = false,
    this.lock,
  });

  /// Platz unter dem Bild für das Namensband.
  static const labelSpace = 40.0;

  final MapIsland island;
  final IslandState state;
  final double width;
  final double height;
  final Animation<double> clock;
  final VoidCallback onTap;

  /// Leuchten: Hier liegt das Schiff und die Insel ist offen.
  final bool glow;

  /// `null` = kein Schloss, sonst 0 (zu) bis 1 (aufgesprungen).
  final double? lock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fog = state == IslandState.fog;
    final phase = (stableSeed(island.slug) % 628) / 100;
    Widget art = IslandArt(slug: island.slug, width: width, height: height);
    if (lock != null && lock! < 0.45) art = ColorFiltered(colorFilter: _dimmed, child: art);
    if (fog) art = Opacity(opacity: 0.4, child: art);

    return Semantics(
      button: true,
      label: fog ? l10n.mapIslandFogTitle(island.title) : island.title,
      child: GestureDetector(
        key: ValueKey('island-${island.slug}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height + labelSpace,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: width,
                height: height,
                child: CustomPaint(
                  painter: IslandWaterPainter(clock: clock, phase: phase, glow: glow),
                ),
              ),
              Positioned(left: 0, top: 0, width: width, height: height, child: art),
              if (state == IslandState.completed)
                Positioned(
                  left: width * 0.5,
                  top: height * 0.06,
                  width: height * 0.32,
                  height: height * 0.36,
                  child: CustomPaint(
                    painter: FlagPainter(clock: clock, phase: phase),
                  ),
                ),
              if (lock != null)
                Positioned(
                  left: width / 2 - height * 0.2,
                  top: height * 0.18,
                  width: height * 0.4,
                  height: height * 0.4,
                  child: CustomPaint(painter: LockPainter(unlock: lock!)),
                ),
              if (fog)
                for (var k = 0; k < 3; k++) _fogCloud(k, phase),
              Positioned(
                left: -24,
                right: -24,
                top: height - 4,
                child: Center(
                  child: MapLabel(title: island.title, state: state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wolken, die langsam über eine Insel im Nebel ziehen.
  Widget _fogCloud(int k, double phase) {
    const lefts = [-0.12, 0.32, 0.06];
    const tops = [-0.05, 0.1, 0.38];
    const sizes = [0.72, 0.78, 0.9];
    final w = width * sizes[k], h = w * 0.5;
    return AnimatedBuilder(
      animation: clock,
      builder: (context, child) {
        final t = sceneSeconds(clock);
        final dx = osc(t, 2, phase + k * 2.1) * width * 0.08;
        return Positioned(left: width * lefts[k] + dx, top: height * tops[k], width: w, height: h, child: child!);
      },
      child: IgnorePointer(
        child: MapCloud(index: k + island.sortOrder, width: w, height: h),
      ),
    );
  }
}

/// Das Schiff der Crew. Es wippt auf den Wellen und zieht beim Fahren eine
/// Spur hinter sich her.
class MapShip extends StatelessWidget {
  const MapShip({super.key, required this.size, required this.clock, required this.facingLeft, required this.moving});

  final double size;
  final Animation<double> clock;
  final bool facingLeft;
  final bool moving;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).mapYouAreHere,
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, child) {
          final t = sceneSeconds(clock);
          return Transform.translate(
            offset: Offset(0, osc(t, 17) * size * 0.03),
            child: Transform.rotate(angle: osc(t, 13, 1) * 0.04, child: child),
          );
        },
        child: Transform.flip(
          flipX: facingLeft,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              children: [
                if (moving)
                  Positioned.fill(
                    child: CustomPaint(painter: WakePainter(clock: clock)),
                  ),
                Positioned.fill(
                  child: TaleriaAsset(
                    AssetKeys.crewShip,
                    width: size,
                    height: size,
                    fallback: const CustomPaint(painter: ShipPainter()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nebel-Start: Beim Öffnen der Karte liegen Wolken über allem und ziehen
/// dann auseinander. [progress] 0 = alles zu, 1 = Karte frei. Antippen
/// überspringt.
class FogIntro extends StatelessWidget {
  const FogIntro({super.key, required this.progress, required this.onSkip});

  final Animation<double> progress;
  final VoidCallback onSkip;

  static final List<({double x, double y, double size, int index})> _clouds = () {
    final rnd = Random(11);
    return [
      for (var row = 0; row < 5; row++)
        for (var col = 0; col < 3; col++)
          (
            x: -0.1 + col * 0.6 + (rnd.nextDouble() - 0.5) * 0.25,
            y: -0.05 + row * 0.27 + (rnd.nextDouble() - 0.5) * 0.12,
            size: 0.85 + rnd.nextDouble() * 0.4,
            index: row * 3 + col,
          ),
    ];
  }();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final p = progress.value;
        if (p >= 1) return const SizedBox.shrink();
        final q = Curves.easeInOut.transform(((p - 0.08) / 0.92).clamp(0.0, 1.0));
        return ExcludeSemantics(
          child: GestureDetector(
            key: const ValueKey('map-fog-intro'),
            behavior: HitTestBehavior.opaque,
            onTap: onSkip,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth, h = constraints.maxHeight;
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: const Color(0xFFEAF1F6).withValues(alpha: (1 - p * 1.8).clamp(0.0, 1.0)),
                      ),
                    ),
                    for (final cloud in _clouds) _cloud(cloud, w, h, q),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _cloud(({double x, double y, double size, int index}) cloud, double w, double h, double q) {
    final cw = w * cloud.size, ch = cw * 0.5;
    final pos = Offset(cloud.x * w, cloud.y * h);
    var dir = pos - Offset(w / 2, h / 2);
    dir = dir.distance < 1 ? const Offset(0, -1) : dir / dir.distance;
    final moved = pos + dir * w * 1.1 * q;
    return Positioned(
      left: moved.dx - cw / 2,
      top: moved.dy - ch / 2,
      width: cw,
      height: ch,
      child: Opacity(
        opacity: (1 - q * q).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 1 + q * 0.5,
          child: MapCloud(index: cloud.index, width: cw, height: ch),
        ),
      ),
    );
  }
}
