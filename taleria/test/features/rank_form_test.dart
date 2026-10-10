import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/domain/progress_models.dart';
import 'package:taleria/features/common/texts.dart';
import 'package:taleria/l10n/app_localizations.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Rang-Namen für Mädchen und Jungen: Das Kind wählt, Eltern können ändern.
void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.dragUntilVisible(finder, find.byType(Scrollable).last, const Offset(0, -200));
    }
    await Scrollable.ensureVisible(tester.element(finder.last), alignment: 0.5);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await scrollTo(tester, finder);
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  test('Rang-Namen in beiden Formen, ohne Wahl beide zusammen', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('de'));
    expect(
      [for (final r in Rank.values) l10n.rank(r, RankForm.junge)],
      ['Schiffsjunge', 'Matrose', 'Bootsmann', 'Steuermann', 'Kapitän'],
    );
    expect(
      [for (final r in Rank.values) l10n.rank(r, RankForm.maedchen)],
      ['Schiffsmädchen', 'Matrosin', 'Bootsfrau', 'Steuerfrau', 'Kapitänin'],
    );
    expect(l10n.rank(Rank.matrose, null), 'Matrose/Matrosin');
    expect(l10n.rank(null, RankForm.maedchen), 'Neu an Bord');
  });

  testWidgets('Startseite fragt einmal, danach heißen alle Ränge passend', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent, rankFormChosen: false);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    final content = FakeContent();
    await tester.pumpWidget(buildTestApp(backend: backend, content: content, progress: FakeProgress(content)));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Ich habe einen Code'));
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tap(tester, find.text('An Bord gehen'));

    expect(find.byKey(const ValueKey('home-rank-form')), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('stats-rank')));
    expect(tester.widget<Text>(find.byKey(const ValueKey('stats-rank'))).data, 'Schiffsjunge/Schiffsmädchen');

    await tap(tester, find.byKey(const ValueKey('rank-form-maedchen')));
    expect(backend.childById(mila.id).rankForm, RankForm.maedchen);
    expect(find.byKey(const ValueKey('home-rank-form')), findsNothing, reason: 'nur einmal gefragt');
    await scrollTo(tester, find.byKey(const ValueKey('stats-rank')));
    expect(tester.widget<Text>(find.byKey(const ValueKey('stats-rank'))).data, 'Schiffsmädchen');
    expect(find.text('Noch 1.450 Seemeilen bis Matrosin'), findsOneWidget);
  });

  testWidgets('Leuchtturm: Eltern ändern die Rang-Namen', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent, rankForm: RankForm.junge);
    backend.signInAs('eltern@test.invalid');
    await tester.pumpWidget(buildTestApp(backend: backend, content: FakeContent()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('pin-gate-field')), '2468');
    await tap(tester, find.text('Öffnen'));
    await tap(tester, find.text('Mila'));

    await tap(tester, find.byKey(const ValueKey('parent-rank-form-maedchen')));
    expect(backend.childById(mila.id).rankForm, RankForm.maedchen);
  });
}
