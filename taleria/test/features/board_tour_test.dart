import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Rundgang „Was ist wo?“ von der Startseite aus.
void main() {
  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Startseite: „Was ist wo?“ zeigt alle Bereiche und führt zurück', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    final content = FakeContent();
    await tester.pumpWidget(buildTestApp(backend: backend, content: content, progress: FakeProgress(content)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ich habe einen Code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tester.tap(find.text('An Bord gehen'));
    await tester.pumpAndSettle();

    await tapKey(tester, 'tour-button');
    expect(find.text('Rundgang an Bord'), findsOneWidget);
    final titles = <String>[];
    for (var i = 0; i < 7; i++) {
      final where = tester.widget<Text>(find.byKey(const ValueKey('tour-where'))).textSpan!.toPlainText();
      expect(where, startsWith('Wo? Auf der Startseite'), reason: 'jede Station sagt, wo sie liegt');
      titles.add(where);
      if (i < 6) await tapKey(tester, 'tour-next');
    }
    expect(titles.toSet(), hasLength(7));
    expect(find.text('Verstanden!'), findsOneWidget);
    await tapKey(tester, 'tour-next');
    expect(find.text('Rundgang an Bord'), findsNothing);
    expect(find.byKey(const ValueKey('tour-button')), findsOneWidget, reason: 'zurück auf der Startseite');
  });
}
