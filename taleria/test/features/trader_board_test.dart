import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/features/station/choice_game_view.dart';
import 'package:taleria/l10n/app_localizations.dart';

import '../../tool/content/content_model.dart';
import '../test_helpers.dart';

/// Tauschinsel Station 1: Die Tafel „Wer hat was?“ bleibt in jeder Runde sichtbar
/// (Marcs Test am 29.10.2026: man wusste nicht mehr, wer was hatte).
void main() {
  testWidgets('Wer will was?: Tafel mit allen Händlern in jeder Runde', (tester) async {
    final island = jsonDecode(File('content/stufe1/02-tauschinsel.json').readAsStringSync()) as Map<String, dynamic>;
    final station = (island['stationen'] as List).first as Map<String, dynamic>;
    final game = GameInfo.fromJson(jsonDecode(jsonEncode(gameToDb(station['spiel'] as Map<String, dynamic>))));
    expect(game.traders.map((t) => t.name), ['Greta', 'Bruno', 'Otti']);

    final app = buildTestApp();
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      AppScope(
        services: app.services,
        child: MaterialApp(
          theme: taleriaThemeForStage(1),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChoiceGameView(game: game, onDone: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wer hat was?'), findsOneWidget);
    for (final text in ['hat: Seil', 'will: Äpfel', 'hat: Äpfel', 'will: Fisch', 'hat: Fisch', 'will: Eimer']) {
      expect(
        find.descendant(of: find.byKey(const ValueKey('trader-board')), matching: find.text(text)),
        findsOneWidget,
      );
    }

    // Nach der ersten Runde steht die Tafel immer noch da.
    await tester.tap(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('Bruno')).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('game-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trader-board')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
