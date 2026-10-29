import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/avatar.dart';
import '../../domain/family_models.dart';
import '../../domain/shipyard.dart';
import '../../l10n/app_localizations.dart';
import '../common/avatar_view.dart';
import '../common/menu_music.dart';
import '../common/page_intro.dart';
import '../common/scene_background.dart';
import '../common/ship_flag.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';

/// Werft: Mit Seemeilen schaltet das Kind Jacken, Hüte, Halstücher und
/// Flaggen fürs Schiff frei. Nichts kostet etwas und nichts ist kaufbar.
/// Gewählt wird sofort gespeichert (Avatar-JSON über update_child_look).
class ShipyardScreen extends StatefulWidget {
  const ShipyardScreen({super.key, required this.child, required this.xp});

  final ChildProfile child;
  final int xp;

  @override
  State<ShipyardScreen> createState() => _ShipyardScreenState();
}

class _ShipyardScreenState extends State<ShipyardScreen> {
  late AvatarConfig _avatar = widget.child.avatar ?? const AvatarConfig();
  bool _saving = false;

  Future<void> _choose(LookItem item) async {
    final l10n = AppLocalizations.of(context);
    if (!item.unlockedAt(widget.xp)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.shipyardLocked(l10n.ranksFrom(item.minXp)))));
      return;
    }
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final before = _avatar;
    setState(() {
      _avatar = wearLook(_avatar, item);
      _saving = true;
    });
    try {
      await services.children!.updateLook(widget.child.id, avatar: _avatar);
      await services.session.refresh();
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _avatar = before);
      messenger.showSnackBar(SnackBar(content: Text(l10n.failure(e.kind))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final next = nextShipyardItem(widget.xp);
    return MenuMusic(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.shipyardTitle)),
        body: SceneBackground(
          assetKey: AssetKeys.homeBackground,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PageIntro(
                  childId: widget.child.id,
                  page: 'shipyard',
                  children: [SpeechBubble(speaker: Speaker.tala, pose: CharacterPose.happy, text: l10n.shipyardIntro)],
                ),
                const SizedBox(height: 12),
                PaperCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AvatarView(key: const ValueKey('shipyard-avatar'), avatar: _avatar, size: 120),
                          FlaggedShip(flag: _avatar.flag, size: 110),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.statsXp(widget.xp), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        next == null
                            ? l10n.shipyardAllUnlocked
                            : l10n.shipyardNext(next.minXp - widget.xp, l10n.lookName(next.id)),
                        key: const ValueKey('shipyard-next'),
                        textAlign: TextAlign.center,
                      ),
                      if (_saving) ...[const SizedBox(height: 8), const LinearProgressIndicator()],
                    ],
                  ),
                ),
                for (final slot in LookSlot.values)
                  PaperCard(
                    key: ValueKey('shipyard-${slot.name}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PaperHeading(l10n.lookSlot(slot.name)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final item in lookOptions(slot))
                              _LookOption(
                                item: item,
                                avatar: _avatar,
                                unlocked: item.unlockedAt(widget.xp),
                                selected: wearsLook(_avatar, item),
                                onTap: () => _choose(item),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Das eigene Schiff mit der gewählten Flagge am Mast.
class FlaggedShip extends StatelessWidget {
  const FlaggedShip({super.key, required this.flag, this.size = 64});

  final ShipFlag flag;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: size * 0.12,
            child: TaleriaAsset(AssetKeys.crewShip, width: size, height: size),
          ),
          Positioned(
            left: size * 0.4,
            top: -size * 0.12,
            child: ShipFlagView(flag: flag, size: size * 0.34),
          ),
        ],
      ),
    );
  }
}

class _LookOption extends StatelessWidget {
  const _LookOption({
    required this.item,
    required this.avatar,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  final LookItem item;
  final AvatarConfig avatar;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final preview = switch (item.slot) {
      LookSlot.flag => ShipFlagView(flag: item.value as ShipFlag, size: 54),
      LookSlot.outfit => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AvatarPalette.outfit[item.value as OutfitColor],
          shape: BoxShape.circle,
          border: Border.all(color: palette.ink.withValues(alpha: 0.2), width: 2),
        ),
      ),
      _ => AvatarView(avatar: wearLook(avatar, item), size: 60),
    };
    return Semantics(
      button: true,
      selected: selected,
      label: unlocked ? l10n.lookName(item.id) : l10n.shipyardLockedLabel(l10n.lookName(item.id)),
      child: InkWell(
        key: ValueKey('look-${item.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 92,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          decoration: BoxDecoration(
            color: selected ? palette.gold.withValues(alpha: 0.25) : palette.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? palette.gold : palette.ink.withValues(alpha: 0.15),
              width: selected ? 3 : 1.5,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(opacity: unlocked ? 1 : 0.35, child: preview),
                    if (!unlocked) Icon(Icons.lock_rounded, color: palette.ink.withValues(alpha: 0.7)),
                    if (selected)
                      Positioned(right: 0, top: 0, child: Icon(Icons.check_circle, color: palette.gold, size: 22)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.lookName(item.id),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (!unlocked)
                Text(
                  l10n.ranksFrom(item.minXp),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
