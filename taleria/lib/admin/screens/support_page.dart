import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../admin_scope.dart';
import '../admin_texts.dart';
import '../domain/admin_models.dart';
import '../services/support_controller.dart';
import 'admin_widgets.dart';

/// Support: Eltern-Konto per E-Mail suchen, Abo von Hand, Konto löschen.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key, required this.role});

  final AdminRole role;

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _email = TextEditingController();
  final _reason = TextEditingController();
  SupportController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= SupportController(AdminScope.of(context).repository!);
  }

  @override
  void dispose() {
    _email.dispose();
    _reason.dispose();
    _controller?.dispose();
    super.dispose();
  }

  bool get _canSearch => _email.text.trim().contains('@') && SupportController.isReasonValid(_reason.text);

  Future<void> _grant(FamilyInfo family) async {
    final result = await showDialog<(ManualPremiumDuration, String)>(
      context: context,
      builder: (_) => _GrantDialog(reason: _controller!.lastReason),
    );
    if (result != null) await _controller!.grantPremium(duration: result.$1, reason: result.$2);
  }

  Future<void> _revoke(FamilyInfo family) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReasonDialog(
        title: AdminTexts.revokeTitle,
        body: AdminTexts.revokeBody,
        action: AdminTexts.revokePremium,
        reason: _controller!.lastReason,
      ),
    );
    if (reason != null) await _controller!.revokePremium(reason: reason);
  }

  Future<void> _delete(FamilyInfo family) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteDialog(email: family.email, reason: _controller!.lastReason),
    );
    if (reason != null) await _controller!.deleteFamily(reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final family = controller.family;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(AdminTexts.support, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(AdminTexts.supportHint),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('support-email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: AdminTexts.email),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('support-reason'),
                    controller: _reason,
                    decoration: const InputDecoration(labelText: AdminTexts.reason),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      key: const ValueKey('support-search'),
                      onPressed: _canSearch && !controller.busy
                          ? () => controller.search(email: _email.text, reason: _reason.text)
                          : null,
                      icon: const Icon(Icons.search),
                      label: const Text(AdminTexts.search),
                    ),
                  ),
                ],
              ),
            ),
            if (controller.error != null) AdminErrorText(controller.error!),
            if (controller.busy) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
            if (controller.notFound)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(AdminTexts.notFound)),
            if (controller.deleted)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(AdminTexts.deleted)),
            if (family != null) ...[
              const SizedBox(height: 16),
              _FamilyCard(
                family: family,
                canChange: widget.role.changesFamilies && !controller.busy,
                onGrant: () => _grant(family),
                onRevoke: () => _revoke(family),
                onDelete: () => _delete(family),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.family,
    required this.canChange,
    required this.onGrant,
    required this.onRevoke,
    required this.onDelete,
  });

  final FamilyInfo family;
  final bool canChange;
  final VoidCallback onGrant;
  final VoidCallback onRevoke;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? date(DateTime? d) => d == null ? null : AdminTexts.date(d);
    return Card(
      key: const ValueKey('support-family'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(family.email, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(AdminTexts.familyCreated(AdminTexts.date(family.createdAt))),
            Text(AdminTexts.familyConsent(family.consentVersion, date(family.consentAt))),
            Text(AdminTexts.familyMarketing(family.marketingConsent)),
            Text(AdminTexts.familyChildren(family.children)),
            Text(AdminTexts.familyLastActive(date(family.lastActiveAt))),
            const SizedBox(height: 8),
            Text(AdminTexts.familyPremium(family.premium), key: const ValueKey('support-premium')),
            for (final e in family.entitlements) Text('· ${AdminTexts.entitlement(e, date(e.validUntil))}'),
            if (canChange) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: const ValueKey('support-grant'),
                    onPressed: onGrant,
                    child: const Text(AdminTexts.grantPremium),
                  ),
                  if (family.hasManualPremium)
                    OutlinedButton(
                      key: const ValueKey('support-revoke'),
                      onPressed: onRevoke,
                      child: const Text(AdminTexts.revokePremium),
                    ),
                  OutlinedButton(
                    key: const ValueKey('support-delete'),
                    style: OutlinedButton.styleFrom(foregroundColor: context.palette.coral),
                    onPressed: onDelete,
                    child: const Text(AdminTexts.deleteFamily),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Feld für den Grund, vorbelegt mit dem Grund der Suche.
class _ReasonField extends StatelessWidget {
  const _ReasonField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final valid = SupportController.isReasonValid(controller.text);
    return TextField(
      key: const ValueKey('dialog-reason'),
      controller: controller,
      decoration: InputDecoration(labelText: AdminTexts.reason, errorText: valid ? null : AdminTexts.reasonTooShort),
      onChanged: (_) => onChanged(),
    );
  }
}

class _GrantDialog extends StatefulWidget {
  const _GrantDialog({required this.reason});

  final String reason;

  @override
  State<_GrantDialog> createState() => _GrantDialogState();
}

class _GrantDialogState extends State<_GrantDialog> {
  late final _reason = TextEditingController(text: widget.reason);
  var _duration = ManualPremiumDuration.threeMonths;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AdminTexts.grantTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(AdminTexts.grantBody),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final d in ManualPremiumDuration.values)
                  ChoiceChip(
                    key: ValueKey('duration-${d.name}'),
                    label: Text(AdminTexts.duration(d)),
                    selected: _duration == d,
                    onSelected: (_) => setState(() => _duration = d),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _ReasonField(controller: _reason, onChanged: () => setState(() {})),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AdminTexts.cancel)),
        FilledButton(
          key: const ValueKey('dialog-confirm'),
          onPressed: SupportController.isReasonValid(_reason.text)
              ? () => Navigator.pop(context, (_duration, _reason.text))
              : null,
          child: const Text(AdminTexts.save),
        ),
      ],
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.body, required this.action, required this.reason});

  final String title;
  final String body;
  final String action;
  final String reason;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  late final _reason = TextEditingController(text: widget.reason);

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.body),
            const SizedBox(height: 12),
            _ReasonField(controller: _reason, onChanged: () => setState(() {})),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AdminTexts.cancel)),
        FilledButton(
          key: const ValueKey('dialog-confirm'),
          onPressed: SupportController.isReasonValid(_reason.text) ? () => Navigator.pop(context, _reason.text) : null,
          child: Text(widget.action),
        ),
      ],
    );
  }
}

/// Löschen nur, wenn die E-Mail-Adresse noch einmal eingetippt ist.
class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.email, required this.reason});

  final String email;
  final String reason;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  late final _reason = TextEditingController(text: widget.reason);
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _ready =>
      SupportController.isReasonValid(_reason.text) &&
      _confirm.text.trim().toLowerCase() == widget.email.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AdminTexts.deleteTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(AdminTexts.deleteBody),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('dialog-confirm-email'),
              controller: _confirm,
              decoration: InputDecoration(labelText: AdminTexts.email, hintText: widget.email),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _ReasonField(controller: _reason, onChanged: () => setState(() {})),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AdminTexts.cancel)),
        FilledButton(
          key: const ValueKey('dialog-confirm'),
          style: FilledButton.styleFrom(backgroundColor: context.palette.coral),
          onPressed: _ready ? () => Navigator.pop(context, _reason.text) : null,
          child: const Text(AdminTexts.deleteConfirm),
        ),
      ],
    );
  }
}
