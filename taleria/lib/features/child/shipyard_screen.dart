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
import 'ship_dock.dart';
import '../common/wood_sign.dart';
import '../common/page_intro.dart';
import '../common/scene_background.dart';
import '../common/ship_flag.dart';
import '../common/texts.dart';
import '../intro/speech_bubble.dart';
import '../common/taleria_app_bar.dart';

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
    if (!item.isUnlocked(widget.xp, _avatar.logbooks)) {
      // Ein neuer Hinweis ersetzt den alten, statt sich hinten anzustellen.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              item.logbook != null ? l10n.shipyardLockedLogbook : l10n.shipyardLocked(l10n.ranksFrom(item.minXp)),
            ),
          ),
        );
      return;
    }
    await _save(wearLook(_avatar, item));
  }

  /// Schatzcode aus dem Logbuch einlösen: schaltet ein Teil frei, tragen muss das Kind es selbst.
  Future<void> _enterCode() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final island = await showDialog<String>(context: context, builder: (_) => const _CodeDialog());
    if (island == null || !mounted) return;
    if (_avatar.logbooks.contains(island)) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.shipyardCodeUsed)));
      return;
    }
    final saved = await _save(_avatar.copyWith(logbooks: {..._avatar.logbooks, island}));
    final item = logbookItem(island);
    if (saved && item != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.shipyardCodeUnlocked(l10n.lookName(item.id)))));
    }
  }

  /// Speichert den Avatar (Teile und eingelöste Codes). Bei einem Fehler bleibt der alte Stand.
  Future<bool> _save(AvatarConfig next) async {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final before = _avatar;
    setState(() {
      _avatar = next;
      _saving = true;
    });
    try {
      await services.children!.updateLook(widget.child.id, avatar: _avatar);
      await services.session.refresh();
      return true;
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() => _avatar = before);
        messenger.showSnackBar(SnackBar(content: Text(l10n.failure(e.kind))));
      }
      return false;
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
        extendBodyBehindAppBar: true,
        appBar: TaleriaAppBar(title: l10n.shipyardTitle),
        body: SceneBackground(
          assetKey: AssetKeys.shipyardBackground,
          fallbackKey: AssetKeys.homeBackground,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PageIntro(
                  childId: widget.child.id,
                  page: 'shipyard',
                  children: [SpeechBubble(speaker: Speaker.tala, pose: CharacterPose.happy, text: l10n.shipyardIntro)],
                ),
                const SizedBox(height: 8),
                // Das eigene Schiff schwimmt im Hafenbecken, davor das Kind.
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ShipDock(flag: _avatar.flag),
                    Positioned(
                      left: -4,
                      bottom: -14,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFFBF0),
                          border: Border.all(color: const Color(0xFFB8862B), width: 4),
                          boxShadow: const [BoxShadow(color: Color(0x55081C30), blurRadius: 8, offset: Offset(0, 4))],
                        ),
                        child: ClipOval(
                          child: AvatarView(key: const ValueKey('shipyard-avatar'), avatar: _avatar, size: 78),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Seemeilen und das nächste Teil, dazu der Schatzcode aus dem Logbuch.
                WoodPanel(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.statsXp(widget.xp),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(color: WoodColors.brass),
                      ),
                      Text(
                        next == null
                            ? l10n.shipyardAllUnlocked
                            : l10n.shipyardNext(next.minXp - widget.xp, l10n.lookName(next.id)),
                        key: const ValueKey('shipyard-next'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: WoodColors.cream,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_saving) ...[const SizedBox(height: 8), const LinearProgressIndicator()],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: FilledButton.icon(
                    key: const ValueKey('shipyard-code'),
                    onPressed: _saving ? null : _enterCode,
                    icon: const Icon(Icons.vpn_key_rounded),
                    label: Text(l10n.shipyardCodeButton),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.shipyardLogbookHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: const [Shadow(color: Color(0xCC000000), offset: Offset(0, 1), blurRadius: 3)],
                  ),
                ),
                const SizedBox(height: 16),
                for (final slot in LookSlot.values)
                  PaperCard(
                    key: ValueKey('shipyard-${slot.name}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.lookSlot(slot.name), style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final item in lookOptions(slot))
                              _LookOption(
                                item: item,
                                avatar: _avatar,
                                unlocked: item.isUnlocked(widget.xp, _avatar.logbooks),
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
                  item.logbook != null ? l10n.shipyardFromLogbook : l10n.ranksFrom(item.minXp),
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

/// Eingabe des Schatzcodes. Gibt die Insel zurück, wenn der Code passt.
class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _code = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final island = logbookForCode(_code.text);
    if (island == null) {
      setState(() => _wrong = true);
      return;
    }
    Navigator.of(context).pop(island);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.shipyardCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.shipyardCodeHint),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('shipyard-code-field'),
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.shipyardCodeLabel,
              errorText: _wrong ? l10n.shipyardCodeWrong : null,
            ),
            onChanged: (_) {
              if (_wrong) setState(() => _wrong = false);
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          key: const ValueKey('shipyard-code-submit'),
          onPressed: _submit,
          child: Text(l10n.shipyardCodeSubmit),
        ),
      ],
    );
  }
}
