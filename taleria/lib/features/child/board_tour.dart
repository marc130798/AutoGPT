import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';
import '../common/menu_music.dart';
import '../common/scene_background.dart';
import '../intro/speech_bubble.dart';

/// Eine Station des Rundgangs: Bild, Name, wo sie auf der Startseite liegt,
/// und wer sie erklärt.
typedef TourStop = ({
  String image,
  IconData icon,
  String title,
  String where,
  Speaker speaker,
  CharacterPose? pose,
  String text,
});

/// Alle Bereiche der Startseite in der Reihenfolge, in der man sie dort
/// von oben nach unten findet (die Karte zuerst, sie ist das Wichtigste).
List<TourStop> tourStops(AppLocalizations l10n) => [
  (
    image: AssetKeys.iconMap,
    icon: Icons.map_outlined,
    title: l10n.tourMapTitle,
    where: l10n.tourMapWhere,
    speaker: Speaker.talo,
    pose: CharacterPose.wave,
    text: l10n.tourMapBody,
  ),
  (
    image: AssetKeys.rank('schiffsjunge'),
    icon: Icons.military_tech_outlined,
    title: l10n.tourRankTitle,
    where: l10n.tourRankWhere,
    speaker: Speaker.talo,
    pose: CharacterPose.happy,
    text: l10n.tourRankBody,
  ),
  (
    image: AssetKeys.iconTreasure,
    icon: Icons.inventory_2_outlined,
    title: l10n.tourChestTitle,
    where: l10n.tourChestWhere,
    speaker: Speaker.tala,
    pose: CharacterPose.wave,
    text: l10n.tourChestBody,
  ),
  (
    image: AssetKeys.iconTasks,
    icon: Icons.checklist,
    title: l10n.tourTasksTitle,
    where: l10n.tourTasksWhere,
    speaker: Speaker.tala,
    pose: null,
    text: l10n.tourTasksBody,
  ),
  (
    image: AssetKeys.iconBadges,
    icon: Icons.emoji_events_outlined,
    title: l10n.tourBadgesTitle,
    where: l10n.tourBadgesWhere,
    speaker: Speaker.talo,
    pose: CharacterPose.happy,
    text: l10n.tourBadgesBody,
  ),
  (
    image: AssetKeys.iconCollection,
    icon: Icons.water_drop_outlined,
    title: l10n.tourCollectionTitle,
    where: l10n.tourCollectionWhere,
    speaker: Speaker.tala,
    pose: CharacterPose.happy,
    text: l10n.tourCollectionBody,
  ),
  (
    image: AssetKeys.lighthouse,
    icon: Icons.light_outlined,
    title: l10n.tourLighthouseTitle,
    where: l10n.tourLighthouseWhere,
    speaker: Speaker.talo,
    pose: null,
    text: l10n.tourLighthouseBody,
  ),
];

/// Rundgang „Was ist wo?“: Talo und Tala zeigen nacheinander jeden Bereich
/// der Startseite mit seinem Bild und sagen, wo er liegt. Kommt in der
/// Einführung und jederzeit über den Knopf oben auf der Startseite.
class BoardTour extends StatefulWidget {
  const BoardTour({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<BoardTour> createState() => _BoardTourState();
}

class _BoardTourState extends State<BoardTour> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final stops = tourStops(l10n);
    final stop = stops[_index];
    final last = _index == stops.length - 1;

    return Column(
      children: [
        Expanded(
          child: ListView(
            key: ValueKey('tour-stop-$_index'),
            padding: const EdgeInsets.all(16),
            children: [
              PaperCard(
                child: Column(
                  children: [
                    Text(l10n.tourTitle, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TaleriaAsset(
                      stop.image,
                      width: 150,
                      height: 130,
                      fallback: Icon(stop.icon, size: 96, color: palette.seaDeep),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stop.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.place, size: 20, color: palette.coral),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${l10n.tourWhere} ',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                TextSpan(text: stop.where),
                              ],
                            ),
                            key: const ValueKey('tour-where'),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SpeechBubble(speaker: stop.speaker, pose: stop.pose, text: stop.text),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < stops.length; i++)
                    Container(
                      margin: const EdgeInsets.all(4),
                      width: i == _index ? 14 : 10,
                      height: i == _index ? 14 : 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index ? palette.gold : palette.paper.withValues(alpha: 0.85),
                        border: Border.all(color: palette.seaDeep.withValues(alpha: 0.4)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_index > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('tour-back'),
                    style: OutlinedButton.styleFrom(backgroundColor: palette.paper.withValues(alpha: 0.9)),
                    onPressed: () => setState(() => _index--),
                    child: Text(l10n.tourBack),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: FilledButton(
                  key: const ValueKey('tour-next'),
                  onPressed: last ? widget.onDone : () => setState(() => _index++),
                  child: Text(last ? l10n.tourDone : l10n.introNext),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Der Rundgang als eigene Seite, auf dem Schiffsdeck der Startseite.
class BoardTourScreen extends StatelessWidget {
  const BoardTourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MenuMusic(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.tourButton)),
        body: SceneBackground(
          assetKey: AssetKeys.homeBackground,
          child: SafeArea(child: BoardTour(onDone: () => Navigator.of(context).pop())),
        ),
      ),
    );
  }
}
