import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/family_models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/lighthouse_controller.dart';
import '../common/avatar_view.dart';
import '../common/busy_action.dart';
import '../common/environment_banner.dart';
import '../common/texts.dart';
import '../dev/asset_gallery_screen.dart';
import 'child_budget_screen.dart';
import 'child_detail_screen.dart';
import 'child_form_screen.dart';
import 'logbooks_screen.dart';
import 'pin_screens.dart';
import 'subscription_screen.dart';

/// Leuchtturm: der Bereich für Eltern. Ruhiger, erwachsener Stil.
class LighthouseScreen extends StatefulWidget {
  const LighthouseScreen({super.key, required this.parent});

  final ParentAccount parent;

  @override
  State<LighthouseScreen> createState() => _LighthouseScreenState();
}

class _LighthouseScreenState extends State<LighthouseScreen> {
  LighthouseController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = LighthouseController(
        family: AppScope.of(context).family!,
        budget: AppScope.of(context).budget,
        progress: AppScope.of(context).progress,
        parent: widget.parent,
      );
      _controller!.load();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openSubscription() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SubscriptionScreen(controller: _controller!)));
  }

  /// Gratis gibt es ein Kinder-Profil; weitere mit dem Abo.
  Future<void> _addChild() async {
    final controller = _controller!;
    if (controller.canAddChild) {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => ChildFormScreen(controller: controller)));
      return;
    }
    final l10n = AppLocalizations.of(context);
    final toSubscription = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.childLimitTitle),
        content: Text(l10n.childLimitBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.childLimitButton)),
        ],
      ),
    );
    if ((toSubscription ?? false) && mounted) _openSubscription();
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final session = AppScope.of(context).session;
    final confirmed = await confirmDestructive(context, title: l10n.deleteAccountTitle, body: l10n.deleteAccountBody);
    if (!confirmed || !mounted) return;
    await runWithFeedback(context, session.deleteAccount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final controller = _controller!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _LighthouseHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const EnvironmentBanner(),
                        const SizedBox(height: 16),
                        if (controller.pendingTotal > 0) ...[
                          Card(
                            key: const ValueKey('pending-overview'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: Text(l10n.pendingOverviewTitle, style: theme.textTheme.titleMedium),
                                ),
                                for (final child in controller.children)
                                  if (controller.pendingFor(child.id) > 0)
                                    ListTile(
                                      leading: const Icon(Icons.task_alt),
                                      title: Text(child.nickname),
                                      subtitle: Text(l10n.pendingTasks(controller.pendingFor(child.id))),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                ChildBudgetScreen(child: child, parentId: controller.parent.id),
                                          ),
                                        );
                                        await controller.loadPendingTasks();
                                      },
                                    ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(l10n.lighthouseChildrenHeading, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        if (controller.loading)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (controller.loadFailure != null) ...[
                          Text(l10n.failure(controller.loadFailure!)),
                          TextButton(onPressed: controller.load, child: Text(l10n.retryButton)),
                        ] else if (controller.children.isEmpty)
                          Text(l10n.lighthouseNoChildren, style: theme.textTheme.bodyLarge)
                        else
                          for (final child in controller.children)
                            _ChildCard(
                              child: child,
                              lines: [
                                l10n.childSubtitle(child.birthYear, l10n.level(child.level)),
                                if (child.shipName != null) l10n.lighthouseChildShip(child.shipName!),
                                if (!child.onboardingCompleted) l10n.lighthouseIntroPending,
                                if (controller.statsFor(child.id) case final stats?) ...[
                                  if (stats.rank != null)
                                    l10n.parentLevel(stats.rank!.level, l10n.rank(stats.rank, child.rankForm)),
                                  stats.lastActiveAt == null
                                      ? l10n.lastActiveNever
                                      : l10n.lastActive(formatDate(stats.lastActiveAt!)),
                                ],
                              ],
                              pending: controller.pendingFor(child.id) > 0
                                  ? l10n.pendingTasks(controller.pendingFor(child.id))
                                  : null,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ChildDetailScreen(controller: controller, childId: child.id),
                                ),
                              ),
                            ),
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          onPressed: _addChild,
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: Text(l10n.lighthouseAddChild),
                        ),
                        const SizedBox(height: 16),
                        // Logbücher zum Ausdrucken (PDF), mit Schatzcode für die Werft.
                        _SettingsCard(
                          children: [
                            ListTile(
                              key: const ValueKey('open-logbooks'),
                              leading: const Icon(Icons.menu_book_rounded),
                              title: Text(l10n.logbooksTitle),
                              subtitle: Text(l10n.logbooksTeaser),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  Navigator.of(context)
                                      .push(MaterialPageRoute<void>(builder: (_) => const LogbooksScreen())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(l10n.lighthouseAccountHeading, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        _SettingsCard(
                          children: [
                            ListTile(
                              key: const ValueKey('open-subscription'),
                              leading: const Icon(Icons.workspace_premium_outlined),
                              title: Text(l10n.lighthouseSubscription),
                              subtitle: Text(
                                controller.subscription.premium ? l10n.subscriptionPremium : l10n.subscriptionFree,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _openSubscription,
                            ),
                            ListTile(
                              leading: const Icon(Icons.pin_outlined),
                              title: Text(l10n.lighthouseChangePin),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => SetPinScreen(onSave: controller.changePin)),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.logout),
                              title: Text(l10n.signOutButton),
                              onTap: () => runWithFeedback(context, services.session.signOut),
                            ),
                            ListTile(
                              leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
                              title: Text(
                                l10n.lighthouseDeleteAccount,
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                              onTap: _deleteAccount,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(l10n.lighthouseDeviceHeading, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        _SettingsCard(
                          children: [
                            ListenableBuilder(
                              listenable: services.sounds,
                              builder: (context, _) => SwitchListTile(
                                key: const ValueKey('music-switch'),
                                secondary: const Icon(Icons.music_note_outlined),
                                title: Text(l10n.lighthouseMusic),
                                subtitle: Text(l10n.lighthouseMusicHint),
                                value: services.sounds.musicAllowed,
                                onChanged: services.sounds.setMusicAllowed,
                              ),
                            ),
                            ListenableBuilder(
                              listenable: services.sounds,
                              builder: (context, _) => SwitchListTile(
                                key: const ValueKey('vibration-switch'),
                                secondary: const Icon(Icons.vibration_rounded),
                                title: Text(l10n.lighthouseVibration),
                                subtitle: Text(l10n.lighthouseVibrationHint),
                                value: services.sounds.vibrationAllowed,
                                onChanged: services.sounds.setVibrationAllowed,
                              ),
                            ),
                            if (services.config.isTest)
                              ListTile(
                                leading: const Icon(Icons.image_outlined),
                                title: Text(l10n.lighthouseShowAssets),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () =>
                                    Navigator.of(context)
                                        .push(MaterialPageRoute<void>(builder: (_) => const AssetGalleryScreen())),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(l10n.noFinancialAdvice, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Kopf des Leuchtturms: Abendhimmel über dem Meer, rechts der Leuchtturm,
/// links Titel und ein kurzer Satz. Ersetzt den blauen Balken.
class _LighthouseHeader extends StatelessWidget {
  const _LighthouseHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 12, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF17304D), Color(0xFF1F4E79), Color(0xFF3A86A8)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.lighthouseTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(color: const Color(0xFFFFF4DC)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.lighthouseWelcome,
                    style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFFD6E8F2)),
                  ),
                ],
              ),
            ),
          ),
          const TaleriaAsset(AssetKeys.lighthouse, width: 78, height: 120, fallback: SizedBox(width: 78, height: 120)),
        ],
      ),
    );
  }
}

/// Ein Kind in der Liste: Figur, Name, die wichtigsten Angaben und, falls
/// Aufgaben auf eine Bestätigung warten, ein Hinweis in Koralle.
class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child, required this.lines, required this.onTap, this.pending});

  final ChildProfile child;
  final List<String> lines;
  final String? pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.seaDeep.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle, color: palette.sand),
                child: ClipOval(
                  child: Center(
                    child: child.avatar == null
                        ? Text(child.nickname.characters.first.toUpperCase(), style: theme.textTheme.headlineSmall)
                        : AvatarView(avatar: child.avatar!, size: 56),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.nickname, style: theme.textTheme.titleLarge),
                    for (final line in lines)
                      Text(
                        line,
                        style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink.withValues(alpha: 0.75)),
                      ),
                    if (pending != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: palette.coral, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          pending!,
                          style: theme.textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.seaDeep),
            ],
          ),
        ),
      ),
    );
  }
}

/// Weiße Karte mit abgerundeten Ecken für eine Gruppe von Einstellungen.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.seaDeep.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 56, color: palette.seaDeep.withValues(alpha: 0.1)),
            child,
          ],
        ],
      ),
    );
  }
}
