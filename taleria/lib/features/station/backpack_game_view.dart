import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';
import 'game_scene.dart';

/// Rucksack packen: Für jeden Ausflug liest das Kind, wohin es geht, und
/// packt mit den Talern ein, was Tala wirklich braucht. Beim Losgehen zeigt
/// sich, was gefehlt hat; dann packt es nach. Übrige Taler werden gespart.
class BackpackGameView extends StatefulWidget {
  const BackpackGameView({super.key, required this.game, required this.onFinished});

  final GameInfo game;
  final ValueChanged<int> onFinished;

  @override
  State<BackpackGameView> createState() => _BackpackGameViewState();
}

class _BackpackGameViewState extends State<BackpackGameView> {
  late final BackpackGame _game = BackpackGame(widget.game);

  /// Letztes Einpacken war zu teuer.
  bool _notEnough = false;

  /// Zahl der Versuche, damit die Rückmeldung bei jedem Losgehen neu erscheint.
  int _tries = 0;

  /// Rückmeldung: Nach dem Losgehen scrollt die Seite dorthin.
  final _resultKey = GlobalKey();

  /// Für die Flugbahn: der Rucksack und jedes Ding im Packhaus.
  final _bagKey = GlobalKey();
  final _itemKeys = <String, GlobalKey>{};

  void _tapItem(String item) {
    if (_game.packed.contains(item)) {
      setState(() {
        _game.unpack(item);
        _notEnough = false;
      });
      return;
    }
    final result = _game.pack(item);
    setState(() => _notEnough = result == BackpackPack.notEnough);
    if (result == BackpackPack.packed) {
      playGameSound(context, AssetKeys.soundCoin);
      // Das Ding fliegt in den Rucksack.
      final image = widget.game.images[item];
      final from = _itemKeys[item];
      if (image != null && from != null) {
        flyThing(context, from: from, to: _bagKey, child: GameThumb(image, size: 48));
      }
    }
  }

  void _go() {
    final ok = _game.go();
    if (ok) playGameSound(context, AssetKeys.soundCorrect);
    setState(() {
      _notEnough = false;
      _tries++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resultKey.currentContext;
      if (target != null && mounted) {
        Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300), alignment: 0.9);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final trip = game.trip;

    final Widget button;
    if (game.finished) {
      button = FilledButton(
        key: const ValueKey('game-finish'),
        onPressed: () => widget.onFinished(game.stars),
        child: Text(l10n.realGameToResult),
      );
    } else if (game.gone) {
      button = FilledButton(
        key: const ValueKey('backpack-next'),
        onPressed: () => setState(game.next),
        child: Text(l10n.backpackNextTrip),
      );
    } else {
      button = FilledButton.icon(
        key: const ValueKey('backpack-go'),
        onPressed: game.packed.isEmpty ? null : _go,
        icon: const Icon(Icons.hiking_rounded),
        label: Text(l10n.backpackGo),
      );
    }

    return GameFrame(
      scene: false,
      game: widget.game,
      button: button,
      children: [
        Text(
          l10n.backpackTrip(game.index + 1, game.total),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
        Text(
          trip.title,
          key: ValueKey('backpack-trip-${game.index}'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (trip.image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: TaleriaAsset(
                trip.image!,
                fit: BoxFit.cover,
                fallback: ColoredBox(
                  color: palette.sea.withValues(alpha: 0.2),
                  child: Icon(Icons.hiking_rounded, size: 64, color: palette.seaDeep),
                ),
              ),
            ),
          ),
        for (final line in trip.scene) ...[const SizedBox(height: 8), SpeechBubble.line(line)],
        const SizedBox(height: 12),
        _bag(context),
        KeyedSubtree(key: _resultKey, child: _feedback(context)),
        const SizedBox(height: 12),
        Text(l10n.backpackShelf, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in widget.game.items)
                  SizedBox(
                    key: _itemKeys.putIfAbsent(item.text, GlobalKey.new),
                    width: width,
                    child: _ShelfItem(
                      key: ValueKey('backpack-item-${item.text}'),
                      name: item.text,
                      price: item.price ?? 0,
                      image: widget.game.images[item.text],
                      packed: game.packed.contains(item.text),
                      onTap: game.gone ? null : () => _tapItem(item.text),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Der Rucksack: übrige Taler und was schon drin ist.
  Widget _bag(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    return Card(
      key: _bagKey,
      color: palette.paper,
      shape: gameCardShape,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.backpack_outlined, color: palette.seaDeep),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.backpackBag, style: theme.textTheme.titleSmall)),
                Text(
                  l10n.backpackLeft(game.left, game.trip.budget),
                  key: const ValueKey('backpack-left'),
                  style: theme.textTheme.titleSmall?.copyWith(color: palette.seaDeep),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (game.packed.isEmpty)
              Text(l10n.backpackEmpty, textAlign: TextAlign.center, style: theme.textTheme.bodySmall)
            else ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final item in game.packed)
                    Semantics(
                      button: !game.gone,
                      label: game.gone ? item : l10n.backpackUnpack(item),
                      excludeSemantics: true,
                      child: ActionChip(
                        key: ValueKey('backpack-packed-$item'),
                        avatar: widget.game.images[item] == null ? null : GameThumb(widget.game.images[item], size: 24),
                        label: Text(item),
                        onPressed: game.gone ? null : () => _tapItem(item),
                      ),
                    ),
                ],
              ),
              if (!game.gone) ...[
                const SizedBox(height: 4),
                Text(l10n.backpackUnpackHint, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Rückmeldung: zu teuer, umgekehrt (was fehlte) oder geschafft.
  Widget _feedback(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;

    if (game.gone) {
      final extras = game.extras;
      return Padding(
        key: ValueKey('backpack-gone-$_tries'),
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.backpackGone,
              key: const ValueKey('backpack-gone'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: palette.success),
            ),
            if (extras.isNotEmpty)
              Text(
                l10n.backpackExtras(extras.join(', ')),
                key: const ValueKey('backpack-extras'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            if (game.left > 0)
              Text(
                l10n.backpackSaved(game.left),
                key: const ValueKey('backpack-saved'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            if (game.finished && game.saved > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.backpackSavedTotal(game.saved),
                key: const ValueKey('backpack-saved-total'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(color: palette.gold),
              ),
            ],
          ],
        ),
      );
    }

    if (game.missing.isNotEmpty) {
      return Padding(
        key: ValueKey('backpack-back-$_tries'),
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SpeechBubble.line(DialogLine(speaker: 'tala', text: l10n.backpackBack)),
            for (final need in game.missing)
              Padding(
                key: ValueKey('backpack-missing-${need.item}'),
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Schon nachgepackt: Haken, sonst Warnzeichen.
                    Icon(
                      game.packed.contains(need.item) ? Icons.check_circle : Icons.error_outline_rounded,
                      size: 22,
                      color: game.packed.contains(need.item) ? palette.success : palette.coral,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(need.missing, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    if (_notEnough) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l10n.backpackNotEnough,
          key: const ValueKey('game-feedback'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(color: palette.coral),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Ein Ding im Packhaus mit Bild, Namen und Preis. Eingepackt: goldener Rand und Haken.
class _ShelfItem extends StatelessWidget {
  const _ShelfItem({
    super.key,
    required this.name,
    required this.price,
    required this.image,
    required this.packed,
    required this.onTap,
  });

  final String name;
  final int price;
  final String? image;
  final bool packed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: packed,
      child: Material(
        color: packed ? palette.sand.withValues(alpha: 0.8) : palette.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: packed ? palette.gold : palette.placeholderBorder, width: packed ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (image != null)
                      GameThumb(image, size: 48)
                    else
                      Icon(Icons.inventory_2_outlined, size: 40, color: palette.seaDeep),
                    if (packed)
                      Positioned(right: -6, top: -6, child: Icon(Icons.check_circle, size: 20, color: palette.success)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
                Text(l10n.gameTaler(price), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
