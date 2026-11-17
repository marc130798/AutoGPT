import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/menu_music.dart';
import '../common/page_intro.dart';
import '../common/scene_background.dart';
import '../common/texts.dart';
import '../common/wood_sign.dart';
import '../intro/speech_bubble.dart';
import 'showcase.dart';
import '../common/taleria_app_bar.dart';

/// Taucherfunde (früher „Unterwasser-Sammlung“): oben die Perlen und wie
/// viele Funde schon da sind, darunter die Funde nach Inseln geordnet, jede
/// Insel mit ihrem Bild und „1 von 3 gefunden“. So sieht das Kind, wo es noch
/// tauchen kann. Rein zum Anschauen, nie kaufbar (CLAUDE.md Abschnitt 8).
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, required this.childId, required this.pearls});

  final String childId;
  final int pearls;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late Future<List<CollectibleInfo>> _items;

  /// Inseln der Karte, für Namen und Bilder der Abschnitte (leer, wenn das
  /// nicht lädt: dann stehen alle Funde in einem Abschnitt).
  List<MapIsland> _islands = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    _items = services.progress!.fetchCollection(widget.childId);
    services.content
        ?.fetchMap(1)
        .then((islands) {
          if (mounted) setState(() => _islands = islands);
        })
        .catchError((Object _) {});
  }

  /// Funde je Insel, in der Reihenfolge der Karte. Die Insel steckt vorn im
  /// Namen des Funds (`hafen-fund-1`).
  List<(MapIsland?, List<CollectibleInfo>)> _byIsland(List<CollectibleInfo> items) {
    final groups = <(MapIsland?, List<CollectibleInfo>)>[];
    final rest = [...items];
    final islands = [..._islands]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final island in islands) {
      final mine = rest.where((i) => i.slug.startsWith('${island.slug}-')).toList();
      if (mine.isEmpty) continue;
      rest.removeWhere(mine.contains);
      groups.add((island, mine));
    }
    if (rest.isNotEmpty) groups.add((null, rest));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return MenuMusic(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: TaleriaAppBar(title: l10n.collectionTitle),
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
                    PageIntro(
                      childId: widget.childId,
                      page: 'collection',
                      voices: const ['voice.app.collectionIntro.mp3'],
                      children: [
                        SpeechBubble(speaker: Speaker.tala, pose: CharacterPose.happy, text: l10n.collectionIntro),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Treasure(pearls: widget.pearls, found: found, total: items.length),
                    const SizedBox(height: 12),
                    if (found == 0) ...[
                      PaperCard(child: Text(l10n.collectionEmpty, style: theme.textTheme.bodyLarge)),
                      const SizedBox(height: 12),
                    ],
                    for (final (island, finds) in _byIsland(items)) ...[
                      if (island != null) _IslandHeader(island: island, finds: finds),
                      const SizedBox(height: 8),
                      ShowcaseGrid(
                        children: [
                          for (final item in finds)
                            ShowcaseTile(
                              key: ValueKey('find-${item.slug}'),
                              assetKey: item.assetKey,
                              title: item.title,
                              caption: item.found
                                  ? l10n.collectionFoundOn(formatDate(item.foundAt!))
                                  : l10n.badgeNotYet,
                              earned: item.found,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
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

/// Oben: die Perlen in ihrer Muschel und wie viele Funde schon da sind.
class _Treasure extends StatelessWidget {
  const _Treasure({required this.pearls, required this.found, required this.total});

  final int pearls;
  final int found;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return PaperCard(
      child: Row(
        children: [
          const TaleriaAsset(AssetKeys.pearl, width: 76, height: 76),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.collectionPearls(pearls),
                  key: const ValueKey('collection-pearls'),
                  style: theme.textTheme.headlineSmall,
                ),
                Text(l10n.diveHint, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  l10n.collectionFoundTotal(found, total),
                  style: theme.textTheme.titleMedium?.copyWith(color: palette.seaDeep),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : found / total,
                    minHeight: 8,
                    color: palette.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Überschrift eines Abschnitts: kleines Bild der Insel, ihr Name und wie
/// viele ihrer Funde schon da sind.
class _IslandHeader extends StatelessWidget {
  const _IslandHeader({required this.island, required this.finds});

  final MapIsland island;
  final List<CollectibleInfo> finds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final found = finds.where((f) => f.found).length;
    return WoodPanel(
      key: ValueKey('collection-island-${island.slug}'),
      padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
      child: Row(
        children: [
          TaleriaAsset(AssetKeys.mapIsland(island.slug), width: 58, height: 44, fallback: const SizedBox.shrink()),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              island.title,
              style: theme.textTheme.titleLarge?.copyWith(color: WoodColors.cream, fontSize: 19),
            ),
          ),
          Text(
            l10n.collectionIslandCount(found, finds.length),
            style: theme.textTheme.labelLarge?.copyWith(color: WoodColors.brass),
          ),
        ],
      ),
    );
  }
}
