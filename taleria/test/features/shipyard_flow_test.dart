import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/avatar.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Werft: Teile mit Seemeilen freischalten, nichts kaufen.
void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.dragUntilVisible(finder, find.byType(Scrollable).first, const Offset(0, -200));
    }
    await Scrollable.ensureVisible(tester.element(finder.last), alignment: 0.5);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await scrollTo(tester, find.text(text));
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await scrollTo(tester, find.byKey(ValueKey(key)));
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('Werft: freie Teile anziehen, gesperrte bleiben zu', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    final content = FakeContent();
    final progress = FakeProgress(content)..extraXp = 1200;

    await tester.pumpWidget(buildTestApp(backend: backend, content: content, progress: progress));
    await tester.pumpAndSettle();
    await tapText(tester, 'Ich habe einen Code');
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tapText(tester, 'An Bord gehen');

    // Vier Teile sind schon frei und leuchten, bis das Kind die Werft öffnet.
    await scrollTo(tester, find.byKey(const ValueKey('home-shipyard')));
    expect(find.text('4 neue Teile frei'), findsOneWidget);
    await tapKey(tester, 'home-shipyard');

    expect(find.text('Werft'), findsWidgets);
    expect(find.textContaining('Hier kann man nichts kaufen'), findsOneWidget);
    expect(find.text('Noch 300 Seemeilen bis: Wellen-Flagge'), findsOneWidget);
    expect(find.textContaining('€'), findsNothing);

    // Gesperrt: nur ein Hinweis, nichts ändert sich.
    await tapKey(tester, 'look-flag_wave');
    expect(find.text('Das wird ab 1.500 Seemeilen frei. Segel einfach weiter!'), findsOneWidget);
    expect(backend.childById(mila.id).avatar?.flag ?? ShipFlag.taleria, ShipFlag.taleria);

    // Frei: wird sofort gespeichert.
    await tapKey(tester, 'look-flag_stripes');
    expect(backend.childById(mila.id).avatar!.flag, ShipFlag.stripes);
    await tapKey(tester, 'look-scarf_red');
    expect(backend.childById(mila.id).avatar!.scarf, Scarf.red);
    expect(backend.childById(mila.id).avatar!.flag, ShipFlag.stripes);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('home-shipyard')));
    expect(find.text('4 neue Teile frei'), findsNothing);
    expect(find.byKey(const ValueKey('ship-flag-stripes')), findsWidgets);
  });
}
