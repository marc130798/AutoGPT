import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/content_models.dart';
import '../../domain/family_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/game_sign.dart';
import '../common/menu_music.dart';
import '../common/scene_background.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';
import '../station/real_game_flow.dart';
import '../station/station_stage.dart';

/// Ein echtes Mini-Spiel auf der Seite „Spiele“: wo es herkommt und ob das
/// Kind die Station schon geschafft hat.
class GameEntry {
  const GameEntry({required this.island, required this.station, required this.unlocked});

  final MapIsland island;
  final StationInfo station;
  final bool unlocked;

  GameInfo get game => station.content.miniGame!;
}

/// Lädt alle echten Mini-Spiele der Inseln, die das Kind sehen darf, in der
/// Reihenfolge der Reise. Freigespielt ist ein Spiel, wenn die Station geschafft ist.
Future<List<GameEntry>> loadGameEntries(AppServices services, ChildProfile child) async {
  final content = services.content!;
  final islands = [...await content.fetchMap(child.stage)]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final done = (await services.progress!.fetchProgress(child.id)).doneStationIds;
  final entries = <GameEntry>[];
  for (final island in islands.where((i) => i.hasContent)) {
    final List<StationInfo> stations;
    try {
      stations = await content.fetchStations(island.id);
    } on AppFailure {
      continue;
    }
    for (final station in stations) {
      if (!station.content.hasMiniGame) continue;
      entries.add(GameEntry(island: island, station: station, unlocked: done.contains(station.id)));
    }
  }
  return entries;
}

/// Seite „Spiele“ (von der Startseite): alle echten Mini-Spiele. Geschaffte
/// kann das Kind nochmal spielen, nur zum Spaß, ohne Seemeilen und ohne
/// Server. Die anderen zeigen, auf welcher Insel sie warten.
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key, required this.child});

  final ChildProfile child;

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  Future<List<GameEntry>>? _entries;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entries ??= loadGameEntries(AppScope.of(context), widget.child);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return MenuMusic(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.gamesTitle)),
        body: SceneBackground(
          assetKey: AssetKeys.mapBackground,
          child: SafeArea(
            child: FutureBuilder<List<GameEntry>>(
              future: _entries,
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
                final entries = snapshot.data;
                if (entries == null) return const Center(child: CircularProgressIndicator());
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SpeechBubble(speaker: Speaker.talo, pose: CharacterPose.happy, text: l10n.gamesIntro),
                    const SizedBox(height: 16),
                    if (entries.isEmpty) PaperCard(child: Text(l10n.gamesEmpty, style: theme.textTheme.bodyLarge)),
                    for (final entry in entries)
                      PaperCard(
                        key: ValueKey('games-${entry.station.id}'),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        // Eigenes Material, damit man das Antippen auf dem Papier sieht.
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            minTileHeight: 88,
                            enabled: entry.unlocked,
                            leading: _GameCover(
                              key: ValueKey('games-cover-${entry.station.id}'),
                              image: entry.game.image,
                              unlocked: entry.unlocked,
                            ),
                            title: Text(entry.game.title, style: theme.textTheme.titleMedium),
                            subtitle: Text(
                              entry.unlocked
                                  ? l10n.gamesWhere(entry.island.title, entry.station.displayNumber)
                                  : l10n.gamesLocked(entry.island.title, entry.station.displayNumber),
                            ),
                            trailing: Icon(entry.unlocked ? Icons.play_circle_fill_rounded : Icons.lock_outline),
                            onTap: entry.unlocked
                                ? () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => GameReplayScreen(entry: entry, level: widget.child.level),
                                    ),
                                  )
                                : null,
                          ),
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

/// Startbild eines Spiels in der Liste, mit kleinem Spiel-Zeichen in der Ecke.
/// Gesperrte Spiele sind grau und blass. Ohne Startbild nur das Spiel-Zeichen.
class _GameCover extends StatelessWidget {
  const _GameCover({super.key, required this.image, required this.unlocked});

  final String? image;
  final bool unlocked;

  static const double _size = 72;

  /// Graustufen für gesperrte Spiele.
  static const _grey = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    final Widget cover = image == null
        ? const GameSign(size: 56)
        : SizedBox.square(
            dimension: _size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: TaleriaAsset(
                      image,
                      fit: BoxFit.cover,
                      fallback: const Center(child: GameSign(size: 56)),
                    ),
                  ),
                ),
                const Positioned(right: -6, bottom: -6, child: GameSign(size: 28)),
              ],
            ),
          );
    if (unlocked) return cover;
    return Opacity(
      opacity: 0.5,
      child: ColorFiltered(colorFilter: _grey, child: cover),
    );
  }
}

/// Nochmal spielen: das Spiel vor seiner Insel, ohne Station und ohne Belohnung.
class GameReplayScreen extends StatelessWidget {
  const GameReplayScreen({super.key, required this.entry, required this.level});

  final GameEntry entry;

  /// Einsteiger spielen mit ganzen Euro, Fortgeschrittene mit Komma.
  final LevelSetting level;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.game.title)),
      body: StationBackdrop(
        assetKey: AssetKeys.islandBackground(entry.island.slug),
        child: SafeArea(
          child: StagePanel(
            child: RealGameFlow(
              game: entry.game.forLevel(level),
              replay: true,
              onDone: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}
