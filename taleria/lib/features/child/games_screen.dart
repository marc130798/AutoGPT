import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/arcade_games.dart';
import '../../domain/content_models.dart';
import '../arcade/arcade_screen.dart';
import '../../domain/family_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/game_sign.dart';
import '../common/menu_music.dart';
import '../common/page_intro.dart';
import '../common/scene_background.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';
import '../station/real_game_flow.dart';
import '../station/station_stage.dart';
import '../common/taleria_app_bar.dart';

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

/// Ein richtiges Spiel auf der Seite „Spiele“.
class ArcadeEntry {
  const ArcadeEntry({required this.game, required this.island, required this.unlocked});

  final ArcadeGame game;
  final MapIsland island;
  final bool unlocked;
}

/// Lädt die richtigen Spiele der Inseln, die das Kind sehen darf.
Future<List<ArcadeEntry>> loadArcadeEntries(AppServices services, ChildProfile child) async {
  final content = services.content!;
  final islands = [...await content.fetchMap(child.stage)]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final done = (await services.progress!.fetchProgress(child.id)).doneStationIds;
  final entries = <ArcadeEntry>[];
  for (final island in islands.where((i) => i.hasContent)) {
    final games = arcadeGamesOn(island.slug);
    if (games.isEmpty) continue;
    final List<StationInfo> stations;
    try {
      stations = await content.fetchStations(island.id);
    } on AppFailure {
      continue;
    }
    for (final game in games) {
      entries.add(
        ArcadeEntry(game: game, island: island, unlocked: arcadeUnlocked(game, stations, (s) => done.contains(s.id))),
      );
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
  /// Beides zusammen laden, damit die Liste nicht nachträglich springt.
  Future<(List<GameEntry>, List<ArcadeEntry>)>? _entries;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entries ??= _load(AppScope.of(context));
  }

  Future<(List<GameEntry>, List<ArcadeEntry>)> _load(AppServices services) async {
    // Fehler bei den richtigen Spielen sollen die Mini-Spiele nicht verdecken.
    final arcade = loadArcadeEntries(services, widget.child).catchError((Object _) => <ArcadeEntry>[]);
    final games = await loadGameEntries(services, widget.child);
    return (games, await arcade);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return MenuMusic(
      enterSound: AssetKeys.soundDice,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: TaleriaAppBar(title: l10n.gamesTitle),
        body: SceneBackground(
          assetKey: AssetKeys.mapBackground,
          child: SafeArea(
            child: FutureBuilder<(List<GameEntry>, List<ArcadeEntry>)>(
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
                final data = snapshot.data;
                if (data == null) return const Center(child: CircularProgressIndicator());
                final (entries, arcade) = data;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PageIntro(
                      childId: widget.child.id,
                      page: 'games',
                      voices: const ['voice.app.gamesIntro.mp3'],
                      children: [SpeechBubble(speaker: Speaker.talo, pose: CharacterPose.happy, text: l10n.gamesIntro)],
                    ),
                    const SizedBox(height: 16),
                    if (arcade.isNotEmpty) ...[
                      PaperHeading(l10n.arcadeSection),
                      for (final entry in arcade) _ArcadeTile(entry: entry, childId: widget.child.id),
                      const SizedBox(height: 8),
                      PaperHeading(l10n.arcadeThinkSection),
                    ],
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

/// Zeile für ein richtiges Spiel: Spiel-Zeichen, Name, Ort, Rekord.
class _ArcadeTile extends StatefulWidget {
  const _ArcadeTile({required this.entry, required this.childId});

  final ArcadeEntry entry;
  final String childId;

  @override
  State<_ArcadeTile> createState() => _ArcadeTileState();
}

class _ArcadeTileState extends State<_ArcadeTile> {
  int _best = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBest();
  }

  void _loadBest() => AppScope.of(context).settings.arcadeBest(widget.childId, widget.entry.game.id).then((best) {
    if (mounted) setState(() => _best = best);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entry = widget.entry;
    final where = entry.unlocked
        ? l10n.arcadeWhere(entry.island.title, arcadePlace(l10n, entry.game))
        : entry.game.afterDive
        ? l10n.arcadeLockedDive(entry.island.title)
        : l10n.arcadeLocked(entry.island.title, entry.game.afterStation);
    return PaperCard(
      key: ValueKey('arcade-${entry.game.id}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          minTileHeight: 88,
          enabled: entry.unlocked,
          leading: _GameCover(image: arcadeCover(entry.game.kind), unlocked: entry.unlocked, contain: true),
          title: Text(arcadeTitle(l10n, entry.game), style: theme.textTheme.titleMedium),
          subtitle: Text(entry.unlocked && _best > 0 ? '$where\n${l10n.arcadeBest(_best)}' : where),
          trailing: Icon(entry.unlocked ? Icons.play_circle_fill_rounded : Icons.lock_outline),
          onTap: entry.unlocked
              ? () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ArcadeScreen(game: entry.game, childId: widget.childId),
                    ),
                  );
                  if (mounted) _loadBest();
                }
              : null,
        ),
      ),
    );
  }
}

/// Startbild eines Spiels in der Liste, mit kleinem Spiel-Zeichen in der Ecke.
/// Gesperrte Spiele sind grau und blass. Ohne Startbild nur das Spiel-Zeichen.
class _GameCover extends StatelessWidget {
  const _GameCover({super.key, required this.image, required this.unlocked, this.contain = false});

  final String? image;
  final bool unlocked;

  /// Freigestellte Figur statt Startbild: ganz zeigen, auf hellem Grund.
  final bool contain;

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
                    child: ColoredBox(
                      color: contain ? const Color(0xFFDFF1FB) : const Color(0x00000000),
                      child: TaleriaAsset(
                        image,
                        fit: contain ? BoxFit.contain : BoxFit.cover,
                        fallback: const Center(child: GameSign(size: 56)),
                      ),
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
      extendBodyBehindAppBar: true,
      appBar: TaleriaAppBar(title: entry.game.title),
      body: StationBackdrop(
        assetKey: AssetKeys.islandBackground(entry.island.slug),
        faded: true,
        child: SafeArea(
          child: StagePanel(
            open: true,
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
