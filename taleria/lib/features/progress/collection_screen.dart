import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/menu_music.dart';
import '../common/scene_background.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';

/// Unterwasser-Sammlung: Perlen aus den Tauchgängen und Funde aus den Wracks,
/// jeder Fund mit eigenem Bild. Die Unterwasserwelt liegt hinter der ganzen
/// Seite, oben erklärt Tala. Rein zum Anschauen, nie kaufbar (CLAUDE.md Abschnitt 8).
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
    return MenuMusic(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.collectionTitle)),
        body: SceneBackground(
          assetKey: AssetKeys.underwaterBackground,
          child: SafeArea(
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
                    SpeechBubble(speaker: Speaker.tala, pose: CharacterPose.happy, text: l10n.collectionIntro),
                    const SizedBox(height: 16),
                    PaperCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                    if (found == 0) PaperCard(child: Text(l10n.collectionEmpty, style: theme.textTheme.bodyLarge)),
                    for (final item in items)
                      PaperCard(
                        key: ValueKey('find-${item.slug}'),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          minTileHeight: 80,
                          leading: Opacity(
                            opacity: item.found ? 1 : 0.3,
                            child: TaleriaAsset(item.assetKey, width: 64, height: 64),
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            item.found ? l10n.collectionFoundOn(formatDate(item.foundAt!)) : l10n.badgeNotYet,
                          ),
                          trailing: item.found ? null : const Icon(Icons.lock_outline),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
