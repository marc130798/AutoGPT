import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/family_models.dart';
import '../../domain/validators.dart';
import '../../l10n/app_localizations.dart';
import '../common/button_spinner.dart';
import '../common/texts.dart';

/// Eltern: registrieren (mit Einwilligung) oder anmelden.
class ParentAuthScreen extends StatelessWidget {
  const ParentAuthScreen({super.key, this.startWithLogin = false});

  final bool startWithLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      initialIndex: startWithLogin ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.parentAuthTitle),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: l10n.parentAuthRegisterTab),
              Tab(text: l10n.parentAuthLoginTab),
            ],
          ),
        ),
        body: const SafeArea(child: TabBarView(children: [_RegisterForm(), _LoginForm()])),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _consent = false;
  // Newsletter nie vorausgewählt (MARKETING.md).
  bool _marketing = false;
  bool _showConsentError = false;
  bool _busy = false;
  bool _waitingForConfirmation = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _showConsentError = !_consent);
    if (!valid || !_consent) return;

    final l10n = AppLocalizations.of(context);
    final session = AppScope.of(context).session;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final hasSession = await session.registerParent(
        email: _email.text,
        password: _password.text,
        marketingConsent: _marketing,
      );
      if (!mounted) return;
      setState(() => _waitingForConfirmation = !hasSession);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = l10n.failure(e.kind));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_waitingForConfirmation) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.mark_email_read_outlined, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(l10n.checkEmailTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.checkEmailBody, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          FilledButton(onPressed: () => DefaultTabController.of(context).animateTo(1), child: Text(l10n.loginButton)),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _EmailField(controller: _email),
          const SizedBox(height: 16),
          _PasswordField(controller: _password, showHint: true),
          const SizedBox(height: 16),
          CheckboxListTile(
            key: const ValueKey('consent-checkbox'),
            value: _consent,
            onChanged: (v) => setState(() {
              _consent = v ?? false;
              if (_consent) _showConsentError = false;
            }),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.consentLabel),
            subtitle: _showConsentError
                ? Text(l10n.consentRequired, style: TextStyle(color: theme.colorScheme.error))
                : null,
          ),
          CheckboxListTile(
            key: const ValueKey('marketing-checkbox'),
            value: _marketing,
            onChanged: (v) => setState(() => _marketing = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.marketingLabel),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy ? const ButtonSpinner() : Text(l10n.registerButton),
          ),
          const SizedBox(height: 24),
          Text(l10n.noFinancialAdvice, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final session = AppScope.of(context).session;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.signInParent(email: _email.text, password: _password.text);
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = l10n.failure(e.kind));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _EmailField(controller: _email),
          const SizedBox(height: 16),
          // Beim Anmelden keine Längenprüfung: alte Passwörter sollen weiter gehen.
          _PasswordField(controller: _password, showHint: false),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy ? const ButtonSpinner() : Text(l10n.loginButton),
          ),
        ],
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      key: const ValueKey('email-field'),
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(labelText: l10n.emailLabel, border: const OutlineInputBorder()),
      validator: (value) => l10n.emailProblem(validateEmail(value ?? '')),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller, required this.showHint});

  final TextEditingController controller;

  /// Bei der Registrierung: Mindestlänge anzeigen und prüfen.
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      key: const ValueKey('password-field'),
      controller: controller,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: [showHint ? AutofillHints.newPassword : AutofillHints.password],
      decoration: InputDecoration(
        labelText: l10n.passwordLabel,
        helperText: showHint ? l10n.passwordHint(minPasswordLength) : null,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (!showHint) return (value ?? '').isEmpty ? l10n.passwordEmpty : null;
        return l10n.passwordProblem(validatePassword(value ?? ''));
      },
    );
  }
}
