import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';

/// Vorschau der Karte am Ende des Intros: Hintergrund und Schiff im Hafen.
/// Die echte Karte mit allen Inseln ist IslandMapScreen.
class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const TaleriaAsset(AssetKeys.mapBackground, fit: BoxFit.cover),
        // Der Hafen liegt unten, die Route führt nach oben (CLAUDE.md).
        Align(
          alignment: const Alignment(0, 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TaleriaAsset(AssetKeys.crewShip, width: 96, height: 64),
              const SizedBox(height: 8),
              TaleriaAsset(AssetKeys.islandBackground('hafen'), width: 140, height: 80),
            ],
          ),
        ),
      ],
    );
  }
}

/// Karte rollt sich von oben nach unten auf (etwa 1 Sekunde).
class MapReveal extends StatefulWidget {
  const MapReveal({super.key, required this.child});

  final Widget child;

  @override
  State<MapReveal> createState() => _MapRevealState();
}

class _MapRevealState extends State<MapReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Transform(
        alignment: Alignment.topCenter,
        transform: Matrix4.diagonal3Values(1, curve.value.clamp(0.0, 1.2), 1),
        child: Opacity(opacity: _controller.value, child: child),
      ),
      child: widget.child,
    );
  }
}
