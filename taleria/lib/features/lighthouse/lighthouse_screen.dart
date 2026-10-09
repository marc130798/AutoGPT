import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/family_models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/lighthouse_controller.dart';
import '../common/busy_action.dart';
import '../common/environment_banner.dart';
import '../common/texts.dart';
import '../dev/asset_gallery_screen.dart';
import 'child_detail_screen.dart';
import 'child_form_screen.dart';
import 'pin_screens.dart';

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
      _controller = LighthouseController(family: AppScope.of(context).family!, parent: widget.parent);
      _controller!.load();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => ChildFormScreen(controller: controller))),
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
                          leading: CircleAvatar(child: Text(child.nickname.characters.first.toUpperCase())),
                          title: Text(child.nickname),
                          subtitle: Text(l10n.childSubtitle(child.birthYear, l10n.level(child.level))),
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
