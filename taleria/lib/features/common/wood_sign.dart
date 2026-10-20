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
          colors: [Color(0xFFC99560), Color(0xFF9A6634), Color(0xFF8B5A2B)],
        ),
        border: Border.all(color: const Color(0xFF5E3A1A), width: 2.5),
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
