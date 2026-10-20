import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';

/// Ob Bewegungen gezeigt werden dürfen (Bedienungshilfen: Animationen reduzieren).
bool _animate(BuildContext context) => !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

// Belohnungen nach dem Animationsplan (CLAUDE.md, Abschnitt 11): höchstens
// 1 bis 2 Sekunden, nie im Weg (Knöpfe gehen sofort), bei „Bewegung
// reduzieren“ sofort fertig.

/// Schatzkarten-Effekt nach dem Insel-Abschluss (INSELN.md): Das Kartenstück
/// erscheint, leuchtet golden, Funken steigen auf; danach kommt der Orden.
/// Etwa 3,5 Sekunden, einmalig, ohne Ton. Bei reduzierten Animationen sofort fertig.
class IslandRewardEffect extends StatefulWidget {
  const IslandRewardEffect({super.key, this.badgeAssetKey});

  /// Bild des Ordens (`badge.<slug>`), `null` ohne Orden.
  final String? badgeAssetKey;

  @override
  State<IslandRewardEffect> createState() => _IslandRewardEffectState();
}

class _IslandRewardEffectState extends State<IslandRewardEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (_animate(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = context.palette.gold;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // 0 bis 0,6: Kartenstück und Funken. 0,55 bis 1: Orden.
        final piece = Curves.easeOutBack.transform((t / 0.4).clamp(0.0, 1.0));
        final glow = sin((t / 0.6).clamp(0.0, 1.0) * pi);
        final badge = Curves.elasticOut.transform(((t - 0.55) / 0.45).clamp(0.0, 1.0));
        // Der Orden dreht sich einmal, dann läuft ein Glanz darüber.
        final spin = Curves.easeOutCubic.transform(((t - 0.55) / 0.3).clamp(0.0, 1.0));
        final shine = ((t - 0.82) / 0.18).clamp(0.0, 1.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 170,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gold.withValues(alpha: 0.2 + 0.6 * glow),
                          blurRadius: 12 + 24 * glow,
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.3 + 0.7 * piece,
                    child: Opacity(
                      opacity: piece.clamp(0.0, 1.0),
                      child: const TaleriaAsset(AssetKeys.mapBackground, width: 160, height: 100),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(child: CustomPaint(painter: _SparklePainter(t.clamp(0.0, 0.6) / 0.6, gold))),
                  ),
                ],
              ),
            ),
            if (widget.badgeAssetKey != null)
              SizedBox(
                height: 150,
                child: Center(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..scaleByDouble(badge, badge, 1, 1)
                      ..rotateY((1 - spin) * 2 * pi),
                    child: _Shine(
                      progress: shine,
                      // Orden mit Band (Hochformat); der Platzhalter ist ein Kreis.
                      child: TaleriaAsset(widget.badgeAssetKey!, width: 104, height: 146),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Funken, die vom Kartenstück aufsteigen und verblassen. Feste Positionen,
/// damit es auf jedem Gerät gleich aussieht.
class _SparklePainter extends CustomPainter {
  _SparklePainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final paint = Paint()..color = color.withValues(alpha: 1 - progress);
    final center = size.center(Offset.zero);
    for (var i = 0; i < 14; i++) {
      final angle = i / 14 * 2 * pi;
      final distance = 30 + 70 * progress + (i % 3) * 8;
      final point = center + Offset(cos(angle) * distance, sin(angle) * distance * 0.7 - 30 * progress);
      canvas.drawCircle(point, 3.5 - 2 * progress + (i % 2), paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Ein Bild, das einmal federnd erscheint (neuer Rang, Orden). Bei
/// reduzierten Animationen sofort da.
class RewardPop extends StatelessWidget {
  const RewardPop({super.key, required this.assetKey, this.size = 96});

  final String assetKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final gold = context.palette.gold;
    final image = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.6), blurRadius: 18, spreadRadius: 2)],
      ),
      child: ClipOval(
        child: TaleriaAsset(assetKey, width: size, height: size),
      ),
    );
    if (!_animate(context)) return image;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: image,
    );
  }
}

/// Etwas taucht einmal aus dem Wasser auf (Begegnung auf See). Kein Dauer-Wackeln.
class RiseFromWater extends StatelessWidget {
  const RiseFromWater({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!_animate(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 24 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}

/// Ein heller Streifen, der einmal schräg über ein Bild läuft (Glanz).
class _Shine extends StatelessWidget {
  const _Shine({required this.progress, required this.child});

  /// 0 = noch nicht, 1 = vorbei.
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return child;
    final center = -0.3 + 1.6 * progress;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0x00FFFFFF), Color(0xCCFFFFFF), Color(0x00FFFFFF)],
        stops: [(center - 0.15).clamp(0.0, 1.0), center.clamp(0.0, 1.0), (center + 0.15).clamp(0.0, 1.0)],
      ).createShader(bounds),
      child: child,
    );
  }
}

/// Eine Zahl, die sichtbar hochzählt (Seemeilen, Taler), statt einfach da zu
/// sein. Ändert sich [value] später, zählt sie vom alten Stand weiter.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.from = 0, required this.builder});

  final int value;

  /// Startwert beim ersten Zeigen.
  final int from;
  final Widget Function(BuildContext context, int value) builder;

  @override
  Widget build(BuildContext context) {
    if (!_animate(context)) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from.toDouble(), end: value.toDouble()),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(context, v.round()),
    );
  }
}

/// Konfetti beim Abschluss einer Station: einmal von oben herab, etwa 1,8
/// Sekunden. Liegt über dem Inhalt und fängt kein Antippen ab.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (_animate(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colors = [palette.gold, palette.coral, palette.sea, palette.success, palette.talo];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          key: const ValueKey('confetti'),
          size: Size.infinite,
          painter: _ConfettiPainter(_controller.value, colors),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress, this.colors);

  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    // Feste Zufallszahlen: auf jedem Gerät dasselbe Muster.
    final random = Random(7);
    final fade = progress < 0.75 ? 1.0 : (1 - progress) / 0.25;
    for (var i = 0; i < 48; i++) {
      final x = random.nextDouble() * size.width;
      final delay = random.nextDouble() * 0.3;
      final speed = 0.7 + random.nextDouble() * 0.6;
      final p = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final y = -20 + p * speed * (size.height * 0.9);
      final sway = sin((p * 4 + i) * pi) * 14;
      final paint = Paint()..color = colors[i % colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate(p * 6 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 8, height: 12), const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Taler fliegen einzeln in die Truhe, die Truhe hüpft beim Auffangen.
/// Startet, wenn [to] größer ist als [from] (beim ersten Zeigen) oder als
/// der Stand davor (neues Geld, während die Seite offen ist).
class CoinsIntoChest extends StatefulWidget {
  const CoinsIntoChest({super.key, required this.chest, required this.size, required this.from, required this.to});

  final Widget chest;
  final double size;

  /// Cent vorher und jetzt.
  final int from;
  final int to;

  @override
  State<CoinsIntoChest> createState() => _CoinsIntoChestState();
}

class _CoinsIntoChestState extends State<CoinsIntoChest> with SingleTickerProviderStateMixin {
  static const _gap = 150;
  static const _flight = 400;
  static const _bounce = 220;

  late final AnimationController _controller = AnimationController(vsync: this);
  int _coins = 0;
  bool _started = false;

  /// Ein Taler pro Euro, mindestens 1, höchstens 5.
  void _play(int cents) {
    if (cents <= 0 || !_animate(context)) return;
    _coins = (cents / 100).ceil().clamp(1, 5);
    _controller
      ..duration = Duration(milliseconds: (_coins - 1) * _gap + _flight + _bounce)
      ..forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play(widget.to - widget.from);
  }

  @override
  void didUpdateWidget(CoinsIntoChest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.to > oldWidget.to) _play(widget.to - oldWidget.to);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = context.palette.gold;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final ms = _controller.value * (_controller.duration?.inMilliseconds ?? 0);
        final running = _controller.isAnimating;
        var bump = 0.0;
        for (var i = 0; i < _coins && running; i++) {
          final x = (ms - i * _gap - _flight) / _bounce;
          if (x > 0 && x < 1) bump = max(bump, sin(x * pi));
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(scale: 1 + 0.12 * bump, child: widget.chest),
            if (running)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey('coins-flying'),
                    painter: _CoinsPainter(ms: ms, coins: _coins, gap: _gap, flight: _flight, gold: gold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Taler auf einem Bogen von rechts oben (wo der Betrag steht) in die Truhe.
class _CoinsPainter extends CustomPainter {
  _CoinsPainter({required this.ms, required this.coins, required this.gap, required this.flight, required this.gold});

  final double ms;
  final int coins;
  final int gap;
  final int flight;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 1.8, 10);
    final end = Offset(size.width / 2, size.height * 0.45);
    final rim = Paint()..color = Color.lerp(gold, const Color(0xFF6B4A12), 0.45)!;
    final face = Paint()..color = gold;
    final shine = Paint()..color = const Color(0x99FFFFFF);
    for (var i = 0; i < coins; i++) {
      final p = ((ms - i * gap) / flight).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      final eased = Curves.easeIn.transform(p);
      final point = Offset.lerp(start, end, eased)! + Offset(0, -sin(p * pi) * 26);
      final r = 11.0 - 3 * eased;
      canvas.drawCircle(point, r, rim);
      canvas.drawCircle(point, r - 2, face);
      canvas.drawCircle(point + Offset(-r * 0.3, -r * 0.3), r * 0.25, shine);
    }
  }

  @override
  bool shouldRepaint(_CoinsPainter oldDelegate) => oldDelegate.ms != ms;
}
