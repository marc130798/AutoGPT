import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../admin_texts.dart';
import '../services/admin_session.dart';
import 'admin_widgets.dart';

/// Anmeldung mit E-Mail und Passwort.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key, required this.session});

  final AdminSession session;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_email.text.trim().isEmpty || _password.text.isEmpty || widget.session.busy) return;
    widget.session.signIn(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return AdminNarrowPage(
      children: [
        Text(AdminTexts.loginTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(AdminTexts.loginHint),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('admin-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username],
          decoration: const InputDecoration(labelText: AdminTexts.email),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('admin-password'),
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(labelText: AdminTexts.password),
          onSubmitted: (_) => _submit(),
        ),
        if (session.error != null) AdminErrorText(session.error!),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('admin-sign-in'),
          onPressed: session.busy ? null : _submit,
          child: const Text(AdminTexts.signIn),
        ),
      ],
    );
  }
}

/// Eingabe des 6-stelligen Codes (beim Einrichten und bei jeder Anmeldung).
class _CodeForm extends StatefulWidget {
  const _CodeForm({required this.session, required this.onSubmit});

  final AdminSession session;
  final Future<void> Function(String code) onSubmit;

  @override
  State<_CodeForm> createState() => _CodeFormState();
}

class _CodeFormState extends State<_CodeForm> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (_code.text.trim().length != 6 || widget.session.busy) return;
    widget.onSubmit(_code.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('mfa-code'),
          controller: _code,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          decoration: const InputDecoration(labelText: AdminTexts.mfaCode),
          onSubmitted: (_) => _submit(),
        ),
        if (session.error != null) AdminErrorText(session.error!),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('mfa-confirm'),
          onPressed: session.busy ? null : _submit,
          child: const Text(AdminTexts.mfaConfirm),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: session.busy ? null : session.signOut, child: const Text(AdminTexts.signOut)),
      ],
    );
  }
}

/// Erste Anmeldung: Zwei-Faktor-App einrichten.
class AdminMfaSetupScreen extends StatelessWidget {
  const AdminMfaSetupScreen({super.key, required this.session});

  final AdminSession session;

  @override
  Widget build(BuildContext context) {
    final setup = session.setup;
    final theme = Theme.of(context);
    return AdminNarrowPage(
      children: [
        Text(AdminTexts.mfaSetupTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(AdminTexts.mfaSetupBody),
        if (setup != null) ...[
          const SizedBox(height: 12),
          _CopyBox(label: AdminTexts.mfaSecretLabel, value: setup.groupedSecret, copyValue: setup.secret),
          const SizedBox(height: 8),
          const Text(AdminTexts.mfaLinkLabel),
          _CopyBox(label: null, value: setup.uri, copyValue: setup.uri, small: true),
        ],
        const SizedBox(height: 16),
        const Text(AdminTexts.mfaSetupCodeHint),
        const SizedBox(height: 8),
        _CodeForm(session: session, onSubmit: session.confirmSetup),
      ],
    );
  }
}

/// Jede weitere Anmeldung: Code aus der App.
class AdminMfaVerifyScreen extends StatelessWidget {
  const AdminMfaVerifyScreen({super.key, required this.session});

  final AdminSession session;

  @override
  Widget build(BuildContext context) {
    return AdminNarrowPage(
      children: [
        Text(AdminTexts.mfaVerifyTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(AdminTexts.mfaVerifyBody),
        const SizedBox(height: 16),
        _CodeForm(session: session, onSubmit: session.verify),
      ],
    );
  }
}

class AdminNotAdminScreen extends StatelessWidget {
  const AdminNotAdminScreen({super.key, required this.session});

  final AdminSession session;

  @override
  Widget build(BuildContext context) {
    return AdminNarrowPage(
      children: [
        Text(AdminTexts.notAdminTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(AdminTexts.notAdminBody),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: session.backToLogin, child: const Text(AdminTexts.backToLogin)),
      ],
    );
  }
}

/// Text zum Abtippen mit Kopier-Knopf.
class _CopyBox extends StatelessWidget {
  const _CopyBox({required this.label, required this.value, required this.copyValue, this.small = false});

  final String? label;
  final String value;
  final String copyValue;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        title: label == null ? null : Text(label!),
        subtitle: SelectableText(
          value,
          key: ValueKey(small ? 'mfa-uri' : 'mfa-secret'),
          style: small
              ? theme.textTheme.bodySmall
              : theme.textTheme.titleLarge?.copyWith(fontFamily: 'monospace', letterSpacing: 2),
        ),
        trailing: IconButton(
          tooltip: AdminTexts.mfaCopy,
          icon: const Icon(Icons.copy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: copyValue));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AdminTexts.mfaCopied)));
            }
          },
        ),
      ),
    );
  }
}
