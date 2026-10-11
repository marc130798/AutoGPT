import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';

/// Das Spiel-Zeichen: ein Steuerkreuz auf goldenem Grund. Steht auf dem
/// Startbild, an Stationen auf der Insel und auf der Seite „Spiele“.
class GameSign extends StatelessWidget {
  const GameSign({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.gold,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size / 14),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Icon(Icons.sports_esports_rounded, size: size * 0.6, color: palette.ink),
    );
  }
}
