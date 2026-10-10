import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
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
      appBar: AppBar(title: Text(l10n.lighthouseTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addChild,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text(l10n.lighthouseAddChild),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                                      builder: (_) => ChildBudgetScreen(child: child, parentId: controller.parent.id),
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
                      Card(
                        child: ListTile(
                          minTileHeight: 64,
                          leading: child.avatar == null
                              ? CircleAvatar(child: Text(child.nickname.characters.first.toUpperCase()))
                              : AvatarView(avatar: child.avatar!, size: 48),
                          title: Text(child.nickname),
                          subtitle: Text(
                            [
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
                              if (controller.pendingFor(child.id) > 0)
                                l10n.pendingTasks(controller.pendingFor(child.id)),
                            ].join('\n'),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ChildDetailScreen(controller: controller, childId: child.id),
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 32),
                  Text(l10n.lighthouseAccountHeading, style: theme.textTheme.titleLarge),
                  ListTile(
                    key: const ValueKey('open-subscription'),
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: Text(l10n.lighthouseSubscription),
                    subtitle: Text(controller.subscription.premium ? l10n.subscriptionPremium : l10n.subscriptionFree),
                    onTap: _openSubscription,
                  ),
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
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: Text(l10n.lighthouseChangePin),
                    onTap: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => SetPinScreen(onSave: controller.changePin))),
                  ),
                  if (services.config.isTest)
                    ListTile(
                      leading: const Icon(Icons.image_outlined),
                      title: Text(l10n.lighthouseShowAssets),
                      onTap: () =>
                          Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => const AssetGalleryScreen())),
                    ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(l10n.signOutButton),
                    onTap: () => runWithFeedback(context, services.session.signOut),
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
                    title: Text(l10n.lighthouseDeleteAccount, style: TextStyle(color: theme.colorScheme.error)),
                    onTap: _deleteAccount,
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.noFinancialAdvice, style: theme.textTheme.bodySmall),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
