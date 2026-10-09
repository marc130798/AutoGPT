import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/budget_models.dart';
import '../../domain/family_models.dart';
import '../../domain/money.dart';
import '../../domain/validators.dart';
import '../../l10n/app_localizations.dart';
import '../../services/treasure_controller.dart';
import '../common/button_spinner.dart';
import '../common/texts.dart';

/// Was im Betrags-Dialog eingegeben wurde.
class AmountInput {
  const AmountInput({required this.amountCents, this.from, this.to, this.pot, this.note, this.title});

  final int amountCents;
  final Pot? from;
  final Pot? to;
  final Pot? pot;
  final String? note;
  final String? title;
}

/// Ein Dialog für alle Beträge: Umbuchen (von/nach), Ausgabe (mit Notiz),
/// Wunschschatz (mit Titel), Korrektur der Eltern (Truhe, auch negativ).
/// [onSubmit] führt die Buchung aus. Fehler erscheinen im Dialog.
Future<bool> showAmountDialog(
  BuildContext context, {
  required String title,
  required Future<void> Function(AmountInput input) onSubmit,
  bool chooseFromTo = false,
  bool choosePot = false,
  bool withNote = false,
  bool withTitle = false,
  bool allowNegative = false,
  bool parentWording = false,
  String? amountLabel,
  String? hint,
  Pot initialFrom = Pot.spend,
  Pot initialTo = Pot.save,
}) async {
  final done = await showDialog<bool>(
    context: context,
    builder: (_) => _AmountDialog(
      title: title,
      onSubmit: onSubmit,
      chooseFromTo: chooseFromTo,
      choosePot: choosePot,
      withNote: withNote,
      withTitle: withTitle,
      allowNegative: allowNegative,
      parentWording: parentWording,
      amountLabel: amountLabel,
      hint: hint,
      initialFrom: initialFrom,
      initialTo: initialTo,
    ),
  );
  return done ?? false;
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.title,
    required this.onSubmit,
    required this.chooseFromTo,
    required this.choosePot,
    required this.withNote,
    required this.withTitle,
    required this.allowNegative,
    required this.parentWording,
    required this.amountLabel,
    required this.hint,
    required this.initialFrom,
    required this.initialTo,
  });

  final String title;
  final Future<void> Function(AmountInput input) onSubmit;
  final bool chooseFromTo;
  final bool choosePot;
  final bool withNote;
  final bool withTitle;
  final bool allowNegative;
  final bool parentWording;
  final String? amountLabel;
  final String? hint;
  final Pot initialFrom;
  final Pot initialTo;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _title = TextEditingController();
  late Pot _from = widget.initialFrom;
  late Pot _to = widget.initialTo;
  Pot _pot = Pot.spend;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _title.dispose();
    super.dispose();
  }

  int? _parsedAmount() {
    final text = _amount.text.trim();
    final negative = widget.allowNegative && text.startsWith('-');
    final cents = parseEuroInput(negative ? text.substring(1) : text);
    if (cents == null) return null;
    return negative ? -cents : cents;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      await widget.onSubmit(
        AmountInput(
          amountCents: _parsedAmount()!,
          from: widget.chooseFromTo ? _from : null,
          to: widget.chooseFromTo ? _to : null,
          pot: widget.choosePot ? _pot : null,
          note: widget.withNote && _note.text.trim().isNotEmpty ? _note.text.trim() : null,
          title: widget.withTitle ? _title.text.trim() : null,
        ),
      );
    } on NotEnoughMoney {
      error = l10n.notEnoughMoney;
    } on AppFailure catch (e) {
      error = l10n.failure(e.kind);
    }
    if (!mounted) return;
    if (error == null) {
      navigator.pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  Widget _potPicker(String label, Pot value, ValueChanged<Pot> onChanged, {Pot? exclude}) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<Pot>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        for (final pot in Pot.values)
          if (pot != exclude)
            DropdownMenuItem(
              value: pot,
              child: Text(l10n.pot(pot, parent: widget.parentWording)),
            ),
      ],
      onChanged: (pot) {
        if (pot != null) setState(() => onChanged(pot));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.hint != null) ...[Text(widget.hint!), const SizedBox(height: 12)],
            if (widget.withTitle) ...[
              TextFormField(
                key: const ValueKey('amount-dialog-title'),
                controller: _title,
                maxLength: maxWishTitleLength,
                decoration: InputDecoration(labelText: l10n.goalTitleLabel, border: const OutlineInputBorder()),
                validator: (v) => validateWishTitle(v ?? '') == null ? null : l10n.wishTitleTooShort,
              ),
              const SizedBox(height: 8),
            ],
            if (widget.chooseFromTo) ...[
              _potPicker(l10n.moveFrom, _from, (p) {
                _from = p;
                if (_to == p) _to = Pot.values.firstWhere((o) => o != p);
              }),
              const SizedBox(height: 12),
              _potPicker(l10n.moveTo, _to, (p) => _to = p, exclude: _from),
              const SizedBox(height: 12),
            ],
            if (widget.choosePot) ...[_potPicker(l10n.potLabel, _pot, (p) => _pot = p), const SizedBox(height: 12)],
            TextFormField(
              key: const ValueKey('amount-dialog-amount'),
              controller: _amount,
              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: widget.allowNegative),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(widget.allowNegative ? r'[0-9,.\-]' : r'[0-9,.]')),
              ],
              decoration: InputDecoration(
                labelText: widget.amountLabel ?? l10n.amountLabel,
                hintText: l10n.amountHint,
                suffixText: '€',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final text = (v ?? '').trim();
                final unsigned = widget.allowNegative && text.startsWith('-') ? text.substring(1) : text;
                return l10n.amountProblem(validateAmount(unsigned));
              },
            ),
            if (widget.withNote) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('amount-dialog-note'),
                controller: _note,
                maxLength: 80,
                decoration: InputDecoration(labelText: l10n.noteLabel, border: const OutlineInputBorder()),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        FilledButton(
          key: const ValueKey('amount-dialog-submit'),
          onPressed: _busy ? null : _submit,
          child: _busy ? const ButtonSpinner() : Text(widget.withTitle ? l10n.saveButton : l10n.bookButton),
        ),
      ],
    );
  }
}
