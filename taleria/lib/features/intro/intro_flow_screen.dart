import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/assets/video_placeholder.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/avatar.dart';
import '../../domain/validators.dart';
import '../../l10n/app_localizations.dart';
import '../../services/intro_controller.dart';
import '../../services/session_controller.dart';
import '../child/lighthouse_button.dart';
import '../common/avatar_view.dart';
import '../common/busy_action.dart';
import '../common/button_spinner.dart';
import '../map/map_screen.dart';
import 'speech_bubble.dart';

/// Das Intro: Film, Geschichte, Avatar, Schiffstaufe, Rundgang,
/// erster Wunschschatz, Abschluss und die Karte öffnet sich.
class IntroFlowScreen extends StatefulWidget {
  const IntroFlowScreen({super.key, required this.state});

  final SessionChild state;

  @override
  State<IntroFlowScreen> createState() => _IntroFlowScreenState();
}

class _IntroFlowScreenState extends State<IntroFlowScreen> {
  IntroController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= IntroController(repository: AppScope.of(context).children!, child: widget.state.child);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final step = controller.step;
        final body = switch (step) {
          IntroStep.film => VideoPlaceholder(assetKey: AssetKeys.introVideo, onContinue: controller.filmFinished),
          IntroStep.story => _StoryStep(onJoin: controller.joinCrew),
          IntroStep.avatar => _AvatarStep(controller: controller),
          IntroStep.ship => _ShipStep(controller: controller),
          IntroStep.tour => _TourStep(onDone: controller.tourFinished),
          IntroStep.wish => _WishStep(controller: controller),
          IntroStep.done => _DoneStep(controller: controller),
          IntroStep.map => const _MapStep(),
        };
        final dark = step == IntroStep.film;
        return Scaffold(
          backgroundColor: dark ? context.palette.seaDeep : null,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(key: ValueKey(step), child: body),
                  ),
                ),
                // Auf dem Eltern-Gerät führt der Leuchtturm jederzeit zur PIN.
                if (widget.state.onParentDevice)
                  Positioned(top: 4, right: 4, child: LighthouseButton(state: widget.state)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Geschichte
// -----------------------------------------------------------------------------

class _StoryStep extends StatefulWidget {
  const _StoryStep({required this.onJoin});

  final VoidCallback onJoin;

  @override
  State<_StoryStep> createState() => _StoryStepState();
}

class _StoryStepState extends State<_StoryStep> {
  int _shown = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lines = [
      (Speaker.talo, l10n.introStoryTalo1),
      (Speaker.tala, l10n.introStoryTala1),
      (Speaker.talo, l10n.introStoryTalo2),
      (Speaker.tala, l10n.introStoryTala2),
      (Speaker.talo, l10n.introStoryTalo3),
    ];
    final last = _shown >= lines.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.all(16),
            children: [
              for (final (speaker, text) in lines.take(_shown).toList().reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SpeechBubble(speaker: speaker, text: text),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: last
                ? FilledButton(onPressed: widget.onJoin, child: Text(l10n.introJoinButton))
                : OutlinedButton(onPressed: () => setState(() => _shown++), child: Text(l10n.introNext)),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Avatar
// -----------------------------------------------------------------------------

class _AvatarStep extends StatelessWidget {
  const _AvatarStep({required this.controller});

  final IntroController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final avatar = controller.avatar;
    void update(AvatarConfig a) => controller.updateAvatar(a);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.avatarTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Center(
                child: AvatarView(key: const ValueKey('avatar-preview'), avatar: avatar, size: 180),
              ),
              _ColorRow(
                title: l10n.avatarSkin,
                colors: [for (final s in SkinTone.values) AvatarPalette.skin[s]!],
                selected: avatar.skin.index,
                onSelect: (i) => update(avatar.copyWith(skin: SkinTone.values[i])),
              ),
              _ChipRow(
                title: l10n.avatarHairStyle,
                labels: [
                  l10n.avatarHairShort,
                  l10n.avatarHairLong,
                  l10n.avatarHairCurly,
                  l10n.avatarHairBraid,
                  l10n.avatarHairNone,
                ],
                selected: avatar.hairStyle.index,
                onSelect: (i) => update(avatar.copyWith(hairStyle: HairStyle.values[i])),
              ),
              _ColorRow(
                title: l10n.avatarHairColor,
                colors: [for (final c in HairColor.values) AvatarPalette.hair[c]!],
                selected: avatar.hairColor.index,
                onSelect: (i) => update(avatar.copyWith(hairColor: HairColor.values[i])),
              ),
              _ColorRow(
                title: l10n.avatarOutfit,
                colors: [for (final c in OutfitColor.values) AvatarPalette.outfit[c]!],
                selected: avatar.outfit.index,
                onSelect: (i) => update(avatar.copyWith(outfit: OutfitColor.values[i])),
              ),
              _ChipRow(
                title: l10n.avatarHat,
                labels: [l10n.avatarHatNone, l10n.avatarHatCaptain, l10n.avatarHatBandana, l10n.avatarHatStraw],
                selected: avatar.hat.index,
                onSelect: (i) => update(avatar.copyWith(hat: Hat.values[i])),
              ),
            ],
          ),
        ),
        _BottomButton(
          label: l10n.avatarDone,
          busy: controller.busy,
          onPressed: () => runWithFeedback(context, controller.saveAvatar),
        ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.title, required this.colors, required this.selected, required this.onSelect});

  final String title;
  final List<Color> colors;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return _Section(
      title: title,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < colors.length; i++)
            Semantics(
              button: true,
              selected: i == selected,
              label: l10n.avatarColorOption(title, i + 1),
              child: InkResponse(
                onTap: () => onSelect(i),
                radius: 28,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: i == selected ? palette.ink : palette.placeholderBorder,
                      width: i == selected ? 4 : 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.title, required this.labels, required this.selected, required this.onSelect});

  final String title;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < labels.length; i++)
            ChoiceChip(
              label: Text(labels[i]),
              selected: i == selected,
              onSelected: (_) => onSelect(i),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Schiffstaufe
// -----------------------------------------------------------------------------

class _ShipStep extends StatefulWidget {
  const _ShipStep({required this.controller});

  final IntroController controller;

  @override
  State<_ShipStep> createState() => _ShipStepState();
}

class _ShipStepState extends State<_ShipStep> {
  late final TextEditingController _name = TextEditingController(text: widget.controller.shipName);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final problem = validateShipName(_name.text);
    setState(
      () => _error = switch (problem) {
        null => null,
        ShipNameProblem.tooShort => l10n.shipNameTooShort,
        ShipNameProblem.tooLong => l10n.shipNameTooLong,
        ShipNameProblem.invalidCharacters => l10n.nicknameInvalid,
      },
    );
    if (problem != null) return;
    await runWithFeedback(context, () => widget.controller.christenShip(_name.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.shipTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              const Center(child: TaleriaAsset(AssetKeys.crewShip, width: 200, height: 120)),
              const SizedBox(height: 16),
              SpeechBubble(speaker: Speaker.tala, text: l10n.shipBody),
              const SizedBox(height: 24),
              TextField(
                key: const ValueKey('ship-name-field'),
                controller: _name,
                maxLength: maxShipNameLength,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.shipLabel,
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final suggestion in l10n.shipSuggestions.split('|'))
                    ActionChip(
                      label: Text(suggestion),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onPressed: () => setState(() {
                        _name.text = suggestion;
                        _error = null;
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
        _BottomButton(label: l10n.shipButton, busy: widget.controller.busy, onPressed: _submit),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Rundgang
// -----------------------------------------------------------------------------

class _TourStep extends StatefulWidget {
  const _TourStep({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_TourStep> createState() => _TourStepState();
}

class _TourStepState extends State<_TourStep> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stops = [
      (Icons.map_outlined, l10n.tourMapTitle, Speaker.talo, l10n.tourMapBody),
      (Icons.inventory_2_outlined, l10n.tourChestTitle, Speaker.tala, l10n.tourChestBody),
      (Icons.menu_book_outlined, l10n.tourLogbookTitle, Speaker.talo, l10n.tourLogbookBody),
    ];
    final (icon, title, speaker, text) = stops[_index];
    final last = _index == stops.length - 1;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.tourTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 24),
              Icon(icon, size: 96, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              SpeechBubble(speaker: speaker, text: text),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < stops.length; i++)
                    Container(
                      margin: const EdgeInsets.all(4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        _BottomButton(
          label: last ? l10n.tourDone : l10n.introNext,
          busy: false,
          onPressed: last ? widget.onDone : () => setState(() => _index++),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Erster Wunschschatz
// -----------------------------------------------------------------------------

class _WishStep extends StatefulWidget {
  const _WishStep({required this.controller});

  final IntroController controller;

  @override
  State<_WishStep> createState() => _WishStepState();
}

class _WishStepState extends State<_WishStep> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _euros = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _euros.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await runWithFeedback(
      context,
      () => widget.controller.saveWish(title: _title.text, euros: int.parse(_euros.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = widget.controller.busy;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.wishTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 16),
                SpeechBubble(speaker: Speaker.tala, text: l10n.wishBody),
                const SizedBox(height: 24),
                TextFormField(
                  key: const ValueKey('wish-title-field'),
                  controller: _title,
                  maxLength: maxWishTitleLength,
                  decoration: InputDecoration(labelText: l10n.wishTitleLabel, border: const OutlineInputBorder()),
                  validator: (value) => switch (validateWishTitle(value ?? '')) {
                    null => null,
                    WishTitleProblem.tooShort => l10n.wishTitleTooShort,
                    WishTitleProblem.tooLong => l10n.wishTitleTooLong,
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('wish-amount-field'),
                  controller: _euros,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                  decoration: InputDecoration(
                    labelText: l10n.wishAmountLabel,
                    helperText: l10n.wishAmountHint,
                    suffixText: '€',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => validateWishEuros(value ?? '') == null ? null : l10n.wishAmountInvalid,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(onPressed: busy ? null : _save, child: busy ? const ButtonSpinner() : Text(l10n.wishSave)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: busy ? null : () => runWithFeedback(context, widget.controller.skipWish),
                  child: Text(l10n.wishSkip),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Abschluss und Karte
// -----------------------------------------------------------------------------

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.controller});

  final IntroController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: AvatarView(avatar: controller.avatar, size: 160)),
              const SizedBox(height: 16),
              Text(
                l10n.doneTitle(controller.child.nickname),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Center(child: TaleriaAsset(AssetKeys.rank('schiffsjunge'), width: 88, height: 88)),
              const SizedBox(height: 8),
              Text(l10n.doneRank, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              if (controller.earnedXp > 0) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.doneXp(controller.earnedXp),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(color: palette.gold, fontWeight: FontWeight.w800),
                ),
              ],
              if (controller.wishCreated) ...[
                const SizedBox(height: 16),
                Text(l10n.doneWish, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
        _BottomButton(label: l10n.doneMapButton, busy: false, onPressed: controller.openMap),
      ],
    );
  }
}

class _MapStep extends StatelessWidget {
  const _MapStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = AppScope.of(context).session;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.mapOpenTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              child: MapReveal(child: MapView()),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.mapOpenBody, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        ),
        _BottomButton(
          label: l10n.mapStartButton,
          busy: false,
          // Das Intro ist schon gespeichert. Neu laden zeigt den Kinderbereich.
          onPressed: () => runWithFeedback(context, session.refresh),
        ),
      ],
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: busy ? null : onPressed, child: busy ? const ButtonSpinner() : Text(label)),
      ),
    );
  }
}
