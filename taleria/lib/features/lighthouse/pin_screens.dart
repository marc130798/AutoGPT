import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/family_models.dart';
import '../../domain/validators.dart';
import '../../l10n/app_localizations.dart';
import '../../services/session_controller.dart';
import '../common/busy_action.dart';
import '../common/button_spinner.dart';
import '../common/texts.dart';

/// Eltern-PIN festlegen (nach der Registrierung) oder ändern (im Leuchtturm).
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key, this.onSave});

  /// Zum Ändern im Leuchtturm. Ohne: erste PIN über die Sitzung festlegen.
  final Future<void> Function(String pin)? onSave;

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pin = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final session = AppScope.of(context).session;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final onSave = widget.onSave;
      if (onSave == null) {
        await session.setParentPin(_pin.text);
      } else {
        await onSave(_pin.text);
        messenger.showSnackBar(SnackBar(content: Text(l10n.pinChanged)));
        navigator.pop();
      }
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setPinTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(l10n.setPinBody, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              _PinField(
                key: const ValueKey('pin-field'),
                controller: _pin,
                label: l10n.pinLabel,
                validator: (value) => l10n.pinProblem(validatePin(value ?? '')),
              ),
              const SizedBox(height: 16),
              _PinField(
                key: const ValueKey('pin-repeat-field'),
                controller: _repeat,
                label: l10n.pinRepeatLabel,
                validator: (value) => value == _pin.text ? null : l10n.pinMismatch,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy ? const ButtonSpinner() : Text(l10n.pinSaveButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PIN-Abfrage vor dem Leuchtturm (Eltern-Sperre).
class PinGateScreen extends StatefulWidget {
  const PinGateScreen({super.key, required this.state});

  final SessionParent state;

  @override
  State<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<PinGateScreen> {
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final session = AppScope.of(context).session;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      final result = await session.unlockWithPin(_pin.text);
      error = switch (result.status) {
        PinCheckStatus.ok => null,
        PinCheckStatus.wrong || PinCheckStatus.notSet => l10n.pinWrong,
        PinCheckStatus.locked => l10n.pinLocked(formatClockTime(result.lockedUntil ?? DateTime.now())),
      };
    } on AppFailure catch (e) {
      error = l10n.failure(e.kind);
    }
    if (!mounted) return;
    _pin.clear();
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = AppScope.of(context).session;
    final returnChild = widget.state.returnChild;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.lighthouseTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(child: TaleriaAsset(AssetKeys.lighthouse, width: 96, height: 96)),
            const SizedBox(height: 16),
            Text(l10n.pinGateBody, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            _PinField(
              key: const ValueKey('pin-gate-field'),
              controller: _pin,
              label: l10n.pinLabel,
              errorText: _error,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const ButtonSpinner() : Text(l10n.pinGateUnlock),
            ),
            const SizedBox(height: 8),
            if (returnChild != null)
              OutlinedButton(
                onPressed: () => runWithFeedback(context, session.returnToChild),
                child: Text(l10n.pinBackToChild),
              )
            else
              TextButton(
                onPressed: () => session.signOut(),
                child: Text(l10n.pinForgot, textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.errorText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 8),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        errorMaxLines: 3,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
      validator: validator,
      onFieldSubmitted: onSubmitted,
    );
  }
}
