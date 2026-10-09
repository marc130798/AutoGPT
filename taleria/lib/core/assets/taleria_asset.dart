import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'asset_manifest.dart';
import 'asset_placeholder.dart';

/// Zeigt eine Grafik über ihren festen Schlüssel an.
///
/// Fehlt die Datei (oder kann die App diese Art noch nicht anzeigen),
/// erscheint der Platzhalter aus dem Manifest. Nie ein Absturz.
class TaleriaAsset extends StatefulWidget {
  const TaleriaAsset(this.assetKey, {super.key, this.width, this.height, this.fit = BoxFit.contain});

  final String assetKey;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<TaleriaAsset> createState() => _TaleriaAssetState();
}

class _TaleriaAssetState extends State<TaleriaAsset> {
  Future<bool>? _available;
  AssetEntry? _entry;
  AssetBundle? _bundle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(TaleriaAsset oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetKey != widget.assetKey) _resolve();
  }

  void _resolve() {
    final services = AppScope.of(context);
    final entry = services.manifest.lookup(widget.assetKey);
    if (entry.key != _entry?.key || entry.path != _entry?.path) {
      _entry = entry;
      _bundle = services.assets.bundle;
      _available = services.assets.isAvailable(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry!;
    final placeholder = AssetPlaceholder(entry: entry, width: widget.width, height: widget.height);
    return FutureBuilder<bool>(
      future: _available,
      builder: (context, snapshot) {
        if (snapshot.data != true) return placeholder;
        return switch (entry.type) {
          AssetType.image => Image.asset(
            entry.path!,
            bundle: _bundle,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (_, _, _) => placeholder,
          ),
          _ => placeholder,
        };
      },
    );
  }
}
