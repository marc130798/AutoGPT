import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
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
                            minTileHeight: 80,
                            enabled: entry.unlocked,
                            leading: Opacity(opacity: entry.unlocked ? 1 : 0.4, child: const GameSign(size: 52)),
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
            child: RealGameFlow(game: entry.game, replay: true, onDone: () => Navigator.of(context).pop()),
          ),
        ),
      ),
    );
  }
}
