import 'package:flutter/material.dart';

/// Holzschild mit Nägeln für den Titel eines Mini-Spiels, groß auch als
/// Ersatz für das Logo auf dem Startbildschirm.
class WoodSign extends StatelessWidget {
  const WoodSign({super.key, required this.text, this.large = false});

  final String text;
  final bool large;

  static const _cream = Color(0xFFFFF4DC);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nailSize = large ? 10.0 : 7.0;
    Widget nail() => Container(
      width: nailSize,
      height: nailSize,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4A2E14)),
    );
    return Container(
      key: const ValueKey('wood-sign'),
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 22, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WoodColors.light, WoodColors.mid, WoodColors.dark],
        ),
        border: Border.all(color: WoodColors.edge, width: 2.5),
        boxShadow: const [BoxShadow(color: Color(0x66081C30), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          nail(),
          SizedBox(width: large ? 16 : 10),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: (large ? theme.textTheme.displaySmall : theme.textTheme.titleLarge)?.copyWith(
                color: _cream,
                fontWeight: FontWeight.w800,
                shadows: const [Shadow(color: Color(0x99000000), offset: Offset(1, 1.5), blurRadius: 2)],
              ),
            ),
          ),
          SizedBox(width: large ? 16 : 10),
          nail(),
        ],
      ),
    );
  }
}

/// Farben für Holz und Schrift darauf, gleich für alle Holzflächen.
abstract final class WoodColors {
  static const light = Color(0xFFC99560);
  static const mid = Color(0xFF9A6634);
  static const dark = Color(0xFF8B5A2B);
  static const edge = Color(0xFF5E3A1A);
  static const cream = Color(0xFFFFF4DC);
  static const brass = Color(0xFFFFD66B);

  /// Schrift auf Holz: hell mit kleinem Schatten, damit sie sich abhebt.
  static const textShadows = [Shadow(color: Color(0x99000000), offset: Offset(1, 1.5), blurRadius: 2)];
}

/// Holzfläche wie [WoodSign], aber für beliebigen Inhalt: Rang, Name und der
/// große Knopf zur Karte auf dem Schiffsdeck. Mit [onTap] sinkt sie beim
/// Antippen leicht ein wie ein echter Knopf.
class WoodPanel extends StatefulWidget {
  const WoodPanel({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.radius = 16,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Vorlesetext, wenn das Holz ein Knopf ist.
  final String? semanticLabel;

  @override
  State<WoodPanel> createState() => _WoodPanelState();
}

class _WoodPanelState extends State<WoodPanel> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    // Unter dem Holz eine dunkle Kante: Beim Antippen rutscht das Holz darauf.
    final depth = widget.onTap == null ? 0.0 : (_pressed ? 1.0 : 4.0);
    final panel = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      margin: EdgeInsets.only(top: 4 - depth),
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WoodColors.light, WoodColors.mid, WoodColors.dark],
        ),
        border: Border.all(color: WoodColors.edge, width: 2.5),
        boxShadow: [
          BoxShadow(color: WoodColors.edge, offset: Offset(0, depth)),
          BoxShadow(color: const Color(0x55081C30), blurRadius: 8, offset: Offset(0, depth + 3)),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: WoodColors.cream, shadows: WoodColors.textShadows),
        child: IconTheme.merge(
          data: const IconThemeData(color: WoodColors.brass),
          child: widget.child,
        ),
      ),
    );
    if (widget.onTap == null) return panel;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: panel,
      ),
    );
  }
}
