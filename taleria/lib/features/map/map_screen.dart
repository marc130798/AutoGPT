import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../l10n/app_localizations.dart';

/// Die Inselkarte. In Schritt 3 nur Hintergrund und Schiff im Hafen;
/// die Inseln mit Stationen kommen in Schritt 4 aus der Datenbank.
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

/// Karte aus dem Kinderbereich heraus öffnen.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: const MapView(),
    );
  }
}
