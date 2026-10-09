import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_manifest.dart';
import '../../core/assets/taleria_asset.dart';
import '../../l10n/app_localizations.dart';

/// Übersicht aller Einträge im Asset-Manifest (nur Testumgebung).
/// So sieht Marc auf einen Blick, welche Grafiken noch fehlen.
class AssetGalleryScreen extends StatefulWidget {
  const AssetGalleryScreen({super.key});

  @override
  State<AssetGalleryScreen> createState() => _AssetGalleryScreenState();
}

class _AssetGalleryScreenState extends State<AssetGalleryScreen> {
  Future<int>? _availableCount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    _availableCount ??= Future.wait(services.manifest.entries.map(services.assets.isAvailable))
        .then((results) => results.where((available) => available).length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final theme = Theme.of(context);

    final byCategory = <String, List<AssetEntry>>{};
    for (final entry in services.manifest.entries) {
      byCategory.putIfAbsent(entry.category, () => []).add(entry);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assetGalleryTitle)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (services.manifestError != null)
                    Text(l10n.assetManifestError, style: TextStyle(color: theme.colorScheme.error)),
                  Text(l10n.assetGalleryHint),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: _availableCount,
                    builder: (context, snapshot) => Text(
                      l10n.assetGalleryCount(snapshot.data ?? 0, services.manifest.length),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final MapEntry(key: category, value: entries) in byCategory.entries) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(child: Text(category, style: theme.textTheme.titleLarge)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) => _AssetTile(entry: entries[index]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.entry});

  final AssetEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Center(child: TaleriaAsset(entry.key, width: 96, height: 96))),
        const SizedBox(height: 4),
        Text(
          entry.key,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
