import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/character_image.dart';
import '../../core/theme/taleria_palette.dart';

/// Talo oder Tala, die leben: Sie atmen leicht und wippen (nur mit
/// `sceneMotion` und ohne „Bewegung reduzieren“). Antippen: Die Figur hüpft,
/// freut sich und sagt einen kurzen Satz aus [lines], jedes Mal den nächsten.
/// Nur zum Spaß, es gibt nichts zu gewinnen.
class LivelyFigure extends StatefulWidget {
  const LivelyFigure({
    super.key,
    required this.character,
    required this.lines,
    this.pose = CharacterPose.wave,
    this.width = 112,
    this.height = 140,
    this.phase = 0,
    this.bubbleToLeft = false,
  });

  final String character;
  final CharacterPose pose;

  /// Die Sprechblase wächst nach links (für eine Figur am rechten Rand),
  /// sonst nach rechts, damit sie nicht aus dem Bild ragt.
  final bool bubbleToLeft;

  /// Sätze beim Antippen, der Reihe nach.
  final List<String> lines;
  final double width;
  final double height;

  /// Verschiebt das Atmen, damit zwei Figuren nicht im Gleichtakt atmen (0 bis 1).
  final double phase;

  @override
  State<LivelyFigure> createState() => _LivelyFigureState();
}

class _LivelyFigureState extends State<LivelyFigure> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  /// Hüpfer und Sprechblase nach dem Antippen (läuft einmal und hört auf).
  late final AnimationController _reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  int _next = 0;
  String? _saying;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = AppScope.of(context).sceneMotion && !MediaQuery.disableAnimationsOf(context);
    if (motion && !_breath.isAnimating) {
      _breath.repeat();
      _breath.value = widget.phase % 1;
    } else if (!motion && _breath.isAnimating) {
      _breath.stop();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _reaction.dispose();
    super.dispose();
  }

  void _tap() {
    if (widget.lines.isEmpty) return;
    setState(() {
      _saying = widget.lines[_next % widget.lines.length];
      _next++;
    });
    _reaction.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _saying = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      key: ValueKey('lively-${widget.character}'),
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_breath, _reaction]),
              builder: (context, child) {
                final t = _breath.value * 2 * pi;
                final r = _reaction.value;
                // Kurzer Hüpfer am Anfang der Reaktion.
                final hop = r < 0.25 ? sin(r / 0.25 * pi) * 14 : 0.0;
                return Transform.translate(
                  offset: Offset(0, -hop + sin(t) * 1.5),
                  child: Transform.scale(
                    scaleX: 1 - sin(t) * 0.006,
                    scaleY: 1 + sin(t) * 0.014,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                );
              },
              child: CharacterImage(
                widget.character,
                pose: _saying == null ? widget.pose : CharacterPose.happy,
                width: widget.width,
                height: widget.height,
                alignment: Alignment.bottomCenter,
              ),
            ),
            if (_saying != null)
              Positioned(
                bottom: widget.height - 8,
                left: widget.bubbleToLeft ? null : 0,
                right: widget.bubbleToLeft ? 0 : null,
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _reaction, curve: const Interval(0, 0.12)),
                  child: Container(
                    key: ValueKey('lively-says-${widget.character}'),
                    constraints: const BoxConstraints(maxWidth: 170),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: palette.paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.gold, width: 2),
                    ),
                    child: Text(
                      _saying!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Leichtes Atmen für eine Figur, zum Beispiel auf der Bühne einer Station.
/// Nur mit `sceneMotion` und ohne „Bewegung reduzieren“, sonst steht sie still.
class Breathing extends StatefulWidget {
  const Breathing({super.key, required this.child, this.phase = 0});

  final Widget child;

  /// Verschiebt das Atmen (0 bis 1), damit nicht alle im Gleichtakt atmen.
  final double phase;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = AppScope.of(context).sceneMotion && !MediaQuery.disableAnimationsOf(context);
    if (motion && !_breath.isAnimating) {
      _breath.repeat();
      _breath.value = widget.phase % 1;
    } else if (!motion && _breath.isAnimating) {
      _breath.stop();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _breath,
    builder: (context, child) {
      final t = _breath.value * 2 * pi;
      return Transform.scale(
        scaleX: 1 - sin(t) * 0.006,
        scaleY: 1 + sin(t) * 0.014,
        alignment: Alignment.bottomCenter,
        child: child,
      );
    },
    child: widget.child,
  );
}

/// Schaukeln wie auf dem Meer: leicht kippen und heben, zum Beispiel der
/// Avatar im Bullauge oder das eigene Schiff. Nur mit `sceneMotion` und ohne
/// „Bewegung reduzieren“.
class SeaSway extends StatefulWidget {
  const SeaSway({super.key, required this.child, this.amount = 1, this.phase = 0});

  final Widget child;

  /// Stärke (1 = sanft).
  final double amount;
  final double phase;

  @override
  State<SeaSway> createState() => _SeaSwayState();
}

class _SeaSwayState extends State<SeaSway> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = AppScope.of(context).sceneMotion && !MediaQuery.disableAnimationsOf(context);
    if (motion && !_clock.isAnimating) {
      _clock.repeat();
      _clock.value = widget.phase % 1;
    } else if (!motion && _clock.isAnimating) {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    builder: (context, child) {
      final t = _clock.value * 2 * pi;
      return Transform.translate(
        offset: Offset(0, sin(t * 2) * 1.5 * widget.amount),
        child: Transform.rotate(angle: sin(t) * 0.035 * widget.amount, child: child),
      );
    },
    child: widget.child,
  );
}
