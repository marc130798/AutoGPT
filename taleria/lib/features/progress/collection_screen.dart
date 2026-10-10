import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/texts.dart';

/// Unterwasser-Sammlung: Perlen aus den Tauchgängen und Funde aus den Wracks.
/// Rein zum Anschauen, nie kaufbar (CLAUDE.md Abschnitt 8).
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, required this.childId, required this.pearls});

  final String childId;
  final int pearls;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late Future<List<CollectibleInfo>> _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items = AppScope.of(context).progress!.fetchCollection(widget.childId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.collectionTitle)),
      body: SafeArea(
        child: FutureBuilder<List<CollectibleInfo>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.failure(error is AppFailure ? error.kind : FailureKind.unknown)),
                ),
              );
            }
            final items = snapshot.data;
            if (items == null) return const Center(child: CircularProgressIndicator());
            final found = items.where((i) => i.found).length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Center(child: TaleriaAsset(AssetKeys.underwaterBackground, width: 260, height: 110)),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const ClipOval(child: TaleriaAsset(AssetKeys.pearl, width: 48, height: 48)),
                    title: Text(
                      l10n.collectionPearls(widget.pearls),
                      key: const ValueKey('collection-pearls'),
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(l10n.diveHint),
                  ),
                ),
                const SizedBox(height: 8),
                if (found == 0) ...[
                  Text(l10n.collectionEmpty, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                ],
                for (final item in items)
                  Card(
                    key: ValueKey('find-${item.slug}'),
                    child: ListTile(
                      minTileHeight: 72,
                      leading: Opacity(
                        opacity: item.found ? 1 : 0.3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TaleriaAsset(item.assetKey, width: 52, height: 52),
                        ),
                      ),
                      title: Text(item.title),
                      subtitle: Text(item.found ? l10n.collectionFoundOn(formatDate(item.foundAt!)) : l10n.badgeNotYet),
                      trailing: item.found ? null : const Icon(Icons.lock_outline),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
