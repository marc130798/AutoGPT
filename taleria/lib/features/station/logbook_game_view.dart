import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import 'game_frame.dart';
import 'game_scene.dart' show gameCardShape;
import 'quiz_view.dart' show StepDots;

/// Kurts Logbuch: Kassenzettel als Einnahme oder Ausgabe eintragen, der Stand
/// läuft mit. Am Ende Balken je Gruppe: Wofür ging am meisten Geld drauf?
class LogbookGameView extends StatefulWidget {
  const LogbookGameView({super.key, required this.game, required this.onFinished});

  final GameInfo game;
  final ValueChanged<int> onFinished;

  @override
  State<LogbookGameView> createState() => _LogbookGameViewState();
}

class _LogbookGameViewState extends State<LogbookGameView> {
  late final LogbookGame _game = LogbookGame(widget.game);
  bool _wrong = false;
  String? _wrongGroup;

  void _book(bool income) {
    final ok = _game.book(income: income);
    if (ok) playGameSound(context, AssetKeys.soundPaper);
    setState(() => _wrong = !ok);
  }

  void _guess(String group) {
    final ok = _game.guessBiggest(group);
    if (ok) playGameSound(context, AssetKeys.soundCorrect);
    setState(() => _wrongGroup = ok ? null : group);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;

    final Widget button;
    if (game.finished) {
      button = FilledButton(
        key: const ValueKey('game-finish'),
        onPressed: () => widget.onFinished(game.stars),
        child: Text(l10n.realGameToResult),
      );
    } else if (!game.allBooked) {
      button = Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              key: const ValueKey('logbook-income'),
              style: FilledButton.styleFrom(backgroundColor: palette.success),
              onPressed: () => _book(true),
              icon: const Icon(Icons.south_west_rounded),
              label: Text(l10n.logbookIncome),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              key: const ValueKey('logbook-expense'),
              style: FilledButton.styleFrom(backgroundColor: palette.coral),
              onPressed: () => _book(false),
              icon: const Icon(Icons.north_east_rounded),
              label: Text(l10n.logbookExpense),
            ),
          ),
        ],
      );
    } else {
      // Am Ende tippt das Kind einen Balken an; dafür gibt es keinen Knopf unten.
      button = const SizedBox.shrink();
    }

    return GameFrame(
      game: widget.game,
      button: button,
      children: [
        _logbook(context),
        const SizedBox(height: 10),
        if (!game.allBooked) ...[
          StepDots(
            total: game.entries.length,
            current: game.index,
            label: l10n.logbookSlip(game.index + 1, game.entries.length),
          ),
          const SizedBox(height: 8),
          _slip(context, game.current),
          if (_wrong) ...[
            const SizedBox(height: 8),
            Text(
              l10n.logbookWrong,
              key: const ValueKey('logbook-wrong'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(color: palette.coral),
            ),
          ],
        ] else ...[
          Text(
            game.finished ? l10n.logbookRight(game.biggest) : l10n.logbookChart,
            key: ValueKey(game.finished ? 'logbook-right' : 'logbook-chart'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: game.finished ? palette.success : null,
            ),
          ),
          const SizedBox(height: 8),
          for (final e in game.spending.entries) ...[_bar(context, e.key, e.value), const SizedBox(height: 6)],
          if (_wrongGroup != null && !game.finished)
            Text(
              l10n.logbookWrongGroup,
              key: const ValueKey('logbook-wrong-group'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(color: palette.coral),
            ),
        ],
      ],
    );
  }

  /// Das Logbuch: Stand und die schon eingetragenen Zettel.
  Widget _logbook(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    return Card(
      color: palette.paper,
      shape: gameCardShape,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 32, color: palette.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.logbookBalance(game.balance),
                    key: const ValueKey('logbook-balance'),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            for (final e in game.booked.reversed.take(3))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${e.income ? '+' : '−'} ${l10n.logbookEntry(e.text, e.amount)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: e.income ? palette.success : palette.coral),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Ein Kassenzettel zum Eintragen.
  Widget _slip(BuildContext context, LogbookEntry entry) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('logbook-slip-${_game.index}'),
      color: const Color(0xFFFFFBF0),
      shape: gameCardShape,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, size: 34, color: Color(0xFF8A6A3D)),
            const SizedBox(width: 10),
            Expanded(child: Text(l10n.logbookEntry(entry.text, entry.amount), style: theme.textTheme.titleMedium)),
          ],
        ),
      ),
    );
  }

  /// Ein Balken je Gruppe; Antippen beantwortet die Frage am Ende.
  Widget _bar(BuildContext context, String group, int amount) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final most = game.spending.values.fold(0, (a, b) => a > b ? a : b);
    final highlight = game.finished && group == game.biggest;
    return InkWell(
      key: ValueKey('logbook-bar-$group'),
      borderRadius: BorderRadius.circular(12),
      onTap: game.finished ? null : () => _guess(group),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: highlight ? palette.success : palette.gold, width: highlight ? 3 : 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.logbookGroup(group, amount), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: most == 0 ? 0 : amount / most,
                minHeight: 14,
                color: highlight ? palette.success : palette.coral,
                backgroundColor: palette.sand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
