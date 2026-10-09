import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/family_models.dart';
import '../../domain/validators.dart';
import '../../l10n/app_localizations.dart';
import '../common/button_spinner.dart';
import '../common/texts.dart';

/// Kinder-Gerät: Anmeldecode der Eltern eingeben.
class ChildCodeScreen extends StatefulWidget {
  const ChildCodeScreen({super.key});

  @override
  State<ChildCodeScreen> createState() => _ChildCodeScreenState();
}

class _ChildCodeScreenState extends State<ChildCodeScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!isCompleteLoginCode(_controller.text)) {
      setState(() => _error = l10n.childCodeIncomplete);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = AppScope.of(context).session;
    String? error;
    try {
      final ok = await session.redeemChildCode(_controller.text);
      if (!ok) error = l10n.childCodeInvalid;
    } on AppFailure catch (e) {
      error = l10n.failure(e.kind);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: canPop ? AppBar(title: Text(l10n.childCodeTitle)) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (!canPop) ...[
              Text(l10n.childCodeTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
            ],
            const Center(child: TaleriaAsset(AssetKeys.talo, width: 110, height: 110)),
            const SizedBox(height: 24),
            Text(l10n.childCodeBody, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            TextField(
              key: const ValueKey('child-code-field'),
              controller: _controller,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: loginCodeLength + 1,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9 -]'))],
              style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4),
              decoration: InputDecoration(
                labelText: l10n.childCodeLabel,
                hintText: 'ABCD 2345',
                errorText: _error,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const ButtonSpinner() : Text(l10n.childCodeButton),
            ),
          ],
        ),
      ),
    );
  }
}
