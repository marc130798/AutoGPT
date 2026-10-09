import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/family_models.dart';
import '../../domain/validators.dart';
import '../../l10n/app_localizations.dart';
import '../../services/lighthouse_controller.dart';
import '../common/busy_action.dart';
import '../common/texts.dart';
import 'child_form_screen.dart';

/// Ein Kinder-Profil im Leuchtturm: Gerät anmelden, hier spielen lassen,
/// Geräte abmelden, bearbeiten, löschen.
class ChildDetailScreen extends StatefulWidget {
  const ChildDetailScreen({super.key, required this.controller, required this.childId});

  final LighthouseController controller;
  final String childId;

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  LoginCode? _code;
  int? _deviceCount;

  @override
  void initState() {
    super.initState();
    _loadDeviceCount();
  }

  Future<void> _loadDeviceCount() async {
    try {
      final count = await widget.controller.countDevices(widget.childId);
      if (mounted) setState(() => _deviceCount = count);
    } on AppFailure {
      // Anzahl ist nur ein Hinweis. Ohne Verbindung einfach weglassen.
    }
  }

  Future<void> _createCode() async {
    await runWithFeedback(context, () async {
      final code = await widget.controller.createLoginCode(widget.childId);
      if (mounted) setState(() => _code = code);
    });
  }

  Future<void> _signOutDevices() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final ok = await runWithFeedback(context, () => widget.controller.signOutDevices(widget.childId));
    if (!ok) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.childDetailSignedOut)));
    await _loadDeviceCount();
  }

  Future<void> _delete(ChildProfile child) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await confirmDestructive(
      context,
      title: l10n.deleteChildTitle(child.nickname),
      body: l10n.deleteChildBody,
    );
    if (!confirmed || !mounted) return;
    final ok = await runWithFeedback(context, () => widget.controller.deleteChild(child.id));
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = AppScope.of(context).session;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final child = widget.controller.childById(widget.childId);
        if (child == null) return const Scaffold();
        final code = _code;

        return Scaffold(
          appBar: AppBar(title: Text(child.nickname)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.childSubtitle(child.birthYear, l10n.level(child.level)), style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                _Section(
                  title: l10n.childDetailCodeHeading,
                  body: l10n.childDetailCodeBody,
                  children: [
                    if (code != null) ...[
                      SelectableText(
                        formatLoginCode(code.code),
                        key: const ValueKey('login-code'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.childDetailCodeValid(formatClockTime(code.validUntil)), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(onPressed: _createCode, child: Text(l10n.childDetailCreateCode)),
                    if (_deviceCount != null) ...[
                      const SizedBox(height: 12),
                      Text(l10n.childDetailDevices(_deviceCount!)),
                      if (_deviceCount! > 0)
                        TextButton(onPressed: _signOutDevices, child: Text(l10n.childDetailSignOutDevices)),
                    ],
                  ],
                ),
                _Section(
                  title: l10n.childDetailPlayHereHeading,
                  body: l10n.childDetailPlayHereBody,
                  children: [
                    OutlinedButton(
                      onPressed: () => runWithFeedback(context, () => session.handOverToChild(child)),
                      child: Text(l10n.childDetailPlayHereButton(child.nickname)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.childDetailEdit),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChildFormScreen(controller: widget.controller, child: child),
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  title: Text(l10n.childDetailDelete, style: TextStyle(color: theme.colorScheme.error)),
                  onTap: () => _delete(child),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body, required this.children});

  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(body),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
