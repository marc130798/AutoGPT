import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/family_models.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Rang antippen: alle Ränge als Zeitstrahl mit Seemeilen.
void main() {
  Future<void> openLadder(WidgetTester tester, {required RankForm form, required int xp}) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent, rankForm: form);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    final content = FakeContent();
    final progress = FakeProgress(content)..extraXp = xp;
    await tester.pumpWidget(buildTestApp(backend: backend, content: content, progress: progress));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ich habe einen Code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tester.tap(find.text('An Bord gehen'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('stats-open-ranks')),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.tap(find.byKey(const ValueKey('stats-open-ranks')));
    await tester.pumpAndSettle();
  }

  Finder inStep(String code, String text) =>
      find.descendant(of: find.byKey(ValueKey('rank-step-$code')), matching: find.text(text));

  testWidgets('Zeitstrahl zeigt Grenzen, Geschafftes und wo das Kind steht', (tester) async {
    await openLadder(tester, form: RankForm.junge, xp: 1650);
    expect(find.text('Deine Ränge'), findsOneWidget);
    expect(find.text('1.650 Seemeilen'), findsOneWidget);
    expect(find.text('Noch 2.350 Seemeilen bis Bootsmann'), findsOneWidget);
    expect(inStep('schiffsjunge', 'Geschafft'), findsOneWidget);
    expect(inStep('schiffsjunge', 'gleich zu Beginn'), findsOneWidget);
    expect(inStep('matrose', 'Hier bist du'), findsOneWidget);
    expect(inStep('matrose', 'ab 1.500 Seemeilen'), findsOneWidget);
    expect(inStep('bootsmann', 'ab 4.000 Seemeilen'), findsOneWidget);
    expect(inStep('kapitaen', 'mit der Goldenen Schatzkarte'), findsOneWidget);
    expect(find.text('Hier bist du'), findsOneWidget);
  });

  testWidgets('Rang-Namen in der gewählten Form', (tester) async {
    await openLadder(tester, form: RankForm.maedchen, xp: 50);
    expect(inStep('schiffsjunge', 'Schiffsmädchen'), findsOneWidget);
    expect(inStep('kapitaen', 'Kapitänin'), findsOneWidget);
    expect(find.textContaining('Ganz oben wartet Kapitänin'), findsOneWidget);
  });
}
