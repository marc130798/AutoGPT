import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../l10n/app_localizations.dart';
import 'station_stage.dart';

/// Zeichen für Antipp-Momente. Die Liste muss im Werkzeug gleich sein
/// (`tapSymbols` in `tool/content/content_model.dart`).
const tapSymbols = <String, IconData>{
  'muenze': Icons.monetization_on_rounded,
  'truhe': Icons.inventory_2_rounded,
  'hand': Icons.pan_tool_rounded,
  'hammer': Icons.hardware_rounded,
  'fisch': Icons.set_meal_rounded,
  'preisschild': Icons.sell_rounded,
  'waage': Icons.scale_rounded,
  'besen': Icons.cleaning_services_rounded,
  'anker': Icons.anchor_rounded,
  'flagge': Icons.flag_rounded,
  'tuer': Icons.door_front_door_rounded,
  'sonne': Icons.wb_sunny_rounded,
  'regen': Icons.umbrella_rounded,
  'karte': Icons.map_rounded,
  'netz': Icons.grid_on_rounded,
  'beutel': Icons.shopping_bag_rounded,
  'rucksack': Icons.backpack_rounded,
  'flasche': Icons.local_drink_rounded,
  'kleidung': Icons.checkroom_rounded,
  'daumen': Icons.thumb_up_rounded,
  'winken': Icons.waving_hand_rounded,
  'foto': Icons.photo_camera_rounded,
  'buch': Icons.menu_book_rounded,
  'liste': Icons.checklist_rounded,
  'wellen': Icons.waves_rounded,
  'stern': Icons.star_rounded,
  'spielzeug': Icons.toys_rounded,
  'schiff': Icons.sailing_rounded,
  'herz': Icons.favorite_rounded,
  'brot': Icons.bakery_dining_rounded,
  'fernrohr': Icons.visibility_rounded,
  'laterne': Icons.light_rounded,
  'glocke': Icons.notifications_rounded,
  'stempel': Icons.approval_rounded,
  'kalender': Icons.calendar_month_rounded,
  'schluessel': Icons.key_rounded,
  'werkzeug': Icons.build_rounded,
  'tafel': Icons.cast_for_education_rounded,
};

/// Antipp-Moment zwischen zwei Bildern der Erklärung (INSELN.md): antippen,
/// wischen, ziehen oder umdrehen. Keine Prüfung: „Weiter“ geht immer, auch
/// ohne Aktion. Nach der Aktion klingt eine Münze und der Satz danach erscheint.
class TapMomentView extends StatefulWidget {
  const TapMomentView({super.key, required this.moment, this.done = false, required this.onDone});

  final TapMoment moment;

  /// Schon geschafft (beim Zurückblättern).
  final bool done;
  final VoidCallback onDone;

  @override
  State<TapMomentView> createState() => _TapMomentViewState();
}

class _TapMomentViewState extends State<TapMomentView> with SingleTickerProviderStateMixin {
  late bool _done = widget.done;
  int _hits = 0;

  /// Wie weit das Ding beim Wischen zur Seite geschoben ist.
  double _dx = 0;

  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  bool get _motion => AppScope.of(context).sceneMotion && !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Das Ziel pulsiert sanft, bis das Kind es geschafft hat (nicht bei „Bewegung reduzieren“).
    if (_motion && !_done) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _finish() {
    if (_done) return;
    _pulse.stop();
    setState(() => _done = true);
    AppScope.of(context).sounds.effect(AssetKeys.soundCoin);
    widget.onDone();
  }

  void _hit() {
    if (++_hits >= widget.moment.count) {
      _finish();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final m = widget.moment;
    final after = m.done ?? (m.kind == 'flip' ? null : l10n.tapDone);

    return Column(
      key: const ValueKey('tap-moment'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OpenFrame(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded, color: palette.coral),
                  const SizedBox(width: 6),
                  Text(
                    l10n.tapBadge,
                    style: theme.textTheme.titleLarge?.copyWith(color: palette.coral, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                m.text,
                key: const ValueKey('tap-text'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: switch (m.kind) {
            'swipe' => _swipe(context),
            'drag' => _drag(context),
            'flip' => _flip(context),
            _ => _tap(context),
          },
        ),
        if (_done && after != null) ...[
          const SizedBox(height: 16),
          OpenFrame(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              key: const ValueKey('tap-done'),
              children: [
                Icon(Icons.star_rounded, color: palette.gold, size: 32),
                const SizedBox(width: 10),
                Expanded(child: Text(after, style: theme.textTheme.titleMedium)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Antippen, bei „anzahl“ mehrmals (zum Beispiel dreimal mit dem Hammer).
  Widget _tap(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final left = widget.moment.count - _hits;
    return Column(
      children: [
        GestureDetector(
          key: const ValueKey('tap-target'),
          onTap: _done ? null : _hit,
          child: _Pulse(
            pulse: _pulse,
            child: _Thing(moment: widget.moment, size: 128, done: _done),
          ),
        ),
        if (!_done && widget.moment.count > 1) ...[
          const SizedBox(height: 8),
          OpenFrame(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              l10n.tapCountLeft(left),
              key: const ValueKey('tap-count'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ],
    );
  }

  /// Wischen: das Ding zur Seite schieben. Antippen geht auch.
  Widget _swipe(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Column(
      children: [
        GestureDetector(
          key: const ValueKey('tap-target'),
          onTap: _done ? null : _finish,
          onHorizontalDragUpdate: _done ? null : (d) => setState(() => _dx = (_dx + d.delta.dx).clamp(-140.0, 140.0)),
          onHorizontalDragEnd: _done
              ? null
              : (d) {
                  final far = _dx.abs() > 60 || (d.primaryVelocity ?? 0).abs() > 400;
                  setState(() => _dx = 0);
                  if (far) _finish();
                },
          child: AnimatedSlide(
            offset: Offset(_dx / 128, 0),
            duration: _dx == 0 && _motion ? const Duration(milliseconds: 200) : Duration.zero,
            child: _Pulse(
              pulse: _pulse,
              child: _Thing(moment: widget.moment, size: 128, done: _done),
            ),
          ),
        ),
        if (!_done) ...[
          const SizedBox(height: 8),
          OpenFrame(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swipe_rounded, color: palette.seaDeep),
                const SizedBox(width: 6),
                Text(l10n.tapSwipeHint),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Ziehen: das Ding auf das Ziel daneben legen. Antippen legt es auch hin.
  Widget _drag(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    const size = 104.0;
    final thing = _Thing(moment: widget.moment, size: size);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: size,
          child: _done
              ? null
              : Draggable<TapMoment>(
                  key: const ValueKey('tap-target'),
                  data: widget.moment,
                  feedback: Material(type: MaterialType.transparency, child: thing),
                  childWhenDragging: Opacity(opacity: 0.3, child: thing),
                  child: GestureDetector(
                    onTap: _finish,
                    child: _Pulse(pulse: _pulse, child: thing),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded, size: 36, color: palette.gold),
        ),
        DragTarget<TapMoment>(
          key: const ValueKey('tap-drop'),
          onAcceptWithDetails: (_) => _finish(),
          builder: (context, candidates, _) => Container(
            width: size + 16,
            height: size + 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: candidates.isNotEmpty
                  ? Color.alphaBlend(palette.gold.withValues(alpha: 0.35), palette.paper)
                  : palette.paper.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.gold, width: 3),
            ),
            child: _done
                ? _Thing(moment: widget.moment, size: size, done: true)
                : Text(
                    l10n.tapDropHere,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: palette.seaDeep),
                  ),
          ),
        ),
      ],
    );
  }

  /// Umdrehen: eine Karte mit dem Zeichen vorn und dem Satz hinten.
  Widget _flip(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    Widget card(Widget child) => Container(
      width: 260,
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.gold, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x44081C30), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: child,
    );
    final front = card(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Thing(moment: widget.moment, size: 88),
          const SizedBox(height: 8),
          Text(l10n.tapFlipHint, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
    final back = card(
      Text(
        widget.moment.back ?? '',
        key: const ValueKey('tap-back'),
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(color: palette.ink),
      ),
    );
    return GestureDetector(
      key: const ValueKey('tap-target'),
      onTap: _done ? null : _finish,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: widget.done ? 1 : 0, end: _done ? 1 : 0),
        duration: _motion ? const Duration(milliseconds: 500) : Duration.zero,
        curve: Curves.easeInOut,
        builder: (context, t, _) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(t * pi),
          child: t < 0.5
              ? _Pulse(pulse: _pulse, child: front)
              : Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: back),
        ),
      ),
    );
  }
}

/// Sanftes Pulsieren, damit das Kind sieht, wo es tippen kann.
class _Pulse extends StatelessWidget {
  const _Pulse({required this.pulse, required this.child});

  final AnimationController pulse;
  final Widget child;

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: pulse, curve: Curves.easeInOut)),
    child: child,
  );
}

/// Das Ding des Antipp-Moments: ein Bild oder ein Zeichen im goldenen Kreis.
class _Thing extends StatelessWidget {
  const _Thing({required this.moment, required this.size, this.done = false});

  final TapMoment moment;
  final double size;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final image = moment.image;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.paper,
            border: Border.all(color: palette.gold, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x44081C30), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: image != null
              ? TaleriaAsset(image, fit: BoxFit.contain)
              : Icon(tapSymbols[moment.symbol] ?? Icons.touch_app_rounded, size: size * 0.55, color: palette.seaDeep),
        ),
        if (done)
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: size * 0.16,
              backgroundColor: palette.success,
              child: Icon(Icons.check_rounded, color: Colors.white, size: size * 0.2),
            ),
          ),
      ],
    );
  }
}
