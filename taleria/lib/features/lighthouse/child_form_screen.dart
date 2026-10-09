import 'package:flutter/material.dart';

import '../../domain/family_models.dart';
import '../../domain/validators.dart';
import '../../l10n/app_localizations.dart';
import '../../services/lighthouse_controller.dart';
import '../common/busy_action.dart';
import '../common/button_spinner.dart';
import '../common/texts.dart';

/// Kinder-Profil anlegen oder bearbeiten. Nur Spitzname, Geburtsjahr, Niveau.
class ChildFormScreen extends StatefulWidget {
  const ChildFormScreen({super.key, required this.controller, this.child, this.now});

  final LighthouseController controller;

  /// `null` = neues Profil.
  final ChildProfile? child;

  /// Nur für Tests: heutiges Datum für die Auswahl der Geburtsjahre.
  final DateTime? now;

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nickname;
  late final List<int> _years;
  int? _birthYear;
  late LevelSetting _level;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final child = widget.child;
    _nickname = TextEditingController(text: child?.nickname ?? '');
    _years = selectableBirthYears(widget.now ?? DateTime.now());
    if (child != null && !_years.contains(child.birthYear)) _years.add(child.birthYear);
    _birthYear = child?.birthYear;
    _level = child?.level ?? LevelSetting.beginner;
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    final ok = await runWithFeedback(context, () async {
      final existing = widget.child;
      if (existing == null) {
        await widget.controller.createChild(nickname: _nickname.text, birthYear: _birthYear!, level: _level);
      } else {
        await widget.controller.updateChild(
          existing.copyWith(nickname: _nickname.text.trim(), birthYear: _birthYear, level: _level),
        );
      }
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.child == null ? l10n.childFormNewTitle : l10n.childFormEditTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                key: const ValueKey('nickname-field'),
                controller: _nickname,
                textCapitalization: TextCapitalization.words,
                maxLength: maxNicknameLength,
                decoration: InputDecoration(
                  labelText: l10n.nicknameLabel,
                  helperText: l10n.nicknameHint,
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => l10n.nicknameProblem(validateNickname(value ?? '')),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: const ValueKey('birth-year-field'),
                initialValue: _birthYear,
                decoration: InputDecoration(
                  labelText: l10n.birthYearLabel,
                  helperText: l10n.birthYearHint,
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                ),
                items: [for (final year in _years) DropdownMenuItem(value: year, child: Text('$year'))],
                onChanged: (year) => setState(() => _birthYear = year),
                validator: (year) => year == null ? l10n.birthYearMissing : null,
              ),
              const SizedBox(height: 24),
              Text(l10n.levelLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<LevelSetting>(
                segments: [
                  for (final level in LevelSetting.values) ButtonSegment(value: level, label: Text(l10n.level(level))),
                ],
                selected: {_level},
                onSelectionChanged: (selection) => setState(() => _level = selection.first),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy ? const ButtonSpinner() : Text(l10n.saveButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
