import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../../domain/budget_models.dart';
import '../../domain/family_models.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/texts.dart';

/// Ein Wunsch für die Wunschflasche: was, ungefähr wie teuer (freiwillig),
/// klein oder groß. Die Größe folgt dem Preis, bis das Kind selbst wählt.
class WishBottleForm extends StatefulWidget {
  const WishBottleForm({super.key, required this.submitLabel, required this.onSubmit});

  final String submitLabel;

  /// Wirft [AppFailure], wenn der Server ablehnt; die Meldung erscheint im Formular.
  final Future<void> Function(WishDraft draft) onSubmit;

  @override
  State<WishBottleForm> createState() => _WishBottleFormState();
}

class _WishBottleFormState extends State<WishBottleForm> {
  final _title = TextEditingController();
  final _price = TextEditingController();
  bool? _chosenBig;
  bool _busy = false;
  bool _tried = false;
  FailureKind? _failure;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    super.dispose();
  }

  int? get _priceCents => _price.text.trim().isEmpty ? null : parseEuroInput(_price.text);
  bool get _priceValid => _price.text.trim().isEmpty || validateAmount(_price.text) == null;
  bool get _titleValid => _title.text.trim().length >= 2;
  bool get _big => _chosenBig ?? WishBottle.suggestBig(_priceCents);

  Future<void> _submit() async {
    setState(() => _tried = true);
    if (!_titleValid || !_priceValid || _busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await widget.onSubmit(WishDraft(title: _title.text.trim(), priceCents: _priceCents, isBig: _big));
    } on AppFailure catch (e) {
      if (mounted) setState(() => _failure = e.kind);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const ValueKey('wish-title'),
          controller: _title,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.wishBottleTitleLabel,
            errorText: _tried && !_titleValid ? l10n.wishBottleTitleTooShort : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          key: const ValueKey('wish-price'),
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.wishBottlePriceLabel,
            suffixText: '€',
            errorText: _priceValid ? null : l10n.amountProblem(validateAmount(_price.text)!),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(l10n.wishBottleSmall, key: const ValueKey('wish-small'))),
            ButtonSegment(value: true, label: Text(l10n.wishBottleBig, key: const ValueKey('wish-big'))),
          ],
          selected: {_big},
          onSelectionChanged: (value) => setState(() => _chosenBig = value.single),
        ),
        const SizedBox(height: 4),
        Text(
          _big ? l10n.wishBottleBigHint : l10n.wishBottleSmallHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        if (_failure != null) ...[
          const SizedBox(height: 8),
          Text(l10n.failure(_failure!), style: TextStyle(color: context.palette.coral)),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('wish-submit'),
          onPressed: _busy ? null : _submit,
          icon: const Icon(Icons.water_drop_outlined),
          label: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

/// Dialog „Neue Wunschflasche“ in der Schatztruhe.
Future<void> showWishBottleDialog(BuildContext context, {required Future<void> Function(WishDraft) onSubmit}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.wishBottleNew),
      content: SingleChildScrollView(
        child: WishBottleForm(
          submitLabel: l10n.wishBottleThrow,
          onSubmit: (draft) async {
            await onSubmit(draft);
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.cancel))],
    ),
  );
}
