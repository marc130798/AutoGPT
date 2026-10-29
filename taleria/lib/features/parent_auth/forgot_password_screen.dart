import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/family_models.dart';
import '../../domain/validators.dart';
import '../../l10n/app_localizations.dart';
import '../common/button_spinner.dart';
import '../common/texts.dart';

/// Passwort vergessen: Code per E-Mail anfordern, dann Code und neues Passwort
/// eingeben. Danach ist der Leuchtturm offen (die Seite schließt sich von
/// selbst, weil sich die Sitzung ändert).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.email = ''});

  final String email;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email.trim());
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await action();
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = l10n.failure(e.kind));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode({bool again = false}) async {
    if (!again && !_emailForm.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final session = AppScope.of(context).session;
    await _run(() async {
      await session.requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        if (again) _info = l10n.resetSentAgain;
      });
    });
  }

  Future<void> _save() async {
    if (!_resetForm.currentState!.validate()) return;
    final session = AppScope.of(context).session;
    await _run(() => session.resetPassword(email: _email.text.trim(), code: _code.text, newPassword: _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final messages = [
      if (_info != null) ...[const SizedBox(height: 16), Text(_info!, key: const ValueKey('reset-info'))],
      if (_error != null) ...[
        const SizedBox(height: 16),
        Text(
          _error!,
          key: const ValueKey('reset-error'),
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetTitle)),
      body: SafeArea(
        child: _codeSent
            ? Form(
                key: _resetForm,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Icon(Icons.mark_email_read_outlined, size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      l10n.resetCodeSent(_email.text.trim()),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const ValueKey('reset-code-field'),
                      controller: _code,
                      keyboardType: TextInputType.number,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      decoration: InputDecoration(labelText: l10n.resetCodeLabel, border: const OutlineInputBorder()),
                      validator: (value) => validateResetCode(value ?? '') == null ? null : l10n.resetCodeInvalidFormat,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('reset-password-field'),
                      controller: _password,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: l10n.resetNewPasswordLabel,
                        helperText: l10n.passwordHint(minPasswordLength),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => l10n.passwordProblem(validatePassword(value ?? '')),
                    ),
                    ...messages,
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const ValueKey('reset-save'),
                      onPressed: _busy ? null : _save,
                      child: _busy ? const ButtonSpinner() : Text(l10n.resetSave),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('reset-send-again'),
                      onPressed: _busy ? null : () => _sendCode(again: true),
                      child: Text(l10n.resetSendAgain),
                    ),
                  ],
                ),
              )
            : Form(
                key: _emailForm,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(l10n.resetIntro, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const ValueKey('reset-email-field'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: l10n.emailLabel, border: const OutlineInputBorder()),
                      validator: (value) => l10n.emailProblem(validateEmail(value ?? '')),
                    ),
                    ...messages,
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const ValueKey('reset-send'),
                      onPressed: _busy ? null : _sendCode,
                      child: _busy ? const ButtonSpinner() : Text(l10n.resetSendCode),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
