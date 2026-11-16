import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/features/lighthouse/guide_screen.dart';
import 'package:taleria/l10n/app_localizations_de.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

void main() {
  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(ValueKey(key));
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('Leuchtturm: Anleitung für Eltern mit allen Themen zum Aufklappen', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    backend.addChild(parent);
    backend.signInAs('eltern@test.invalid');
    await tester.pumpWidget(buildTestApp(backend: backend, content: FakeContent()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('pin-gate-field')), '2468');
    await tapText(tester, 'Öffnen');

    await tapKey(tester, 'open-guide');
    expect(find.byType(GuideScreen), findsOneWidget);
    final chapters = guideChapters(AppLocalizationsDe());
    expect(chapters, hasLength(12));
    for (final c in chapters) {
      expect(find.byKey(ValueKey('guide-${c.id}')), findsOneWidget);
      expect(find.text(c.title), findsOneWidget);
    }
    // Das erste Thema ist offen, die anderen klappen beim Antippen auf.
    final reward = chapters.firstWhere((c) => c.id == 'reward');
    expect(find.text(reward.body), findsNothing);
    await tester.ensureVisible(find.text(reward.title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(reward.title));
    await tester.pumpAndSettle();
    expect(find.text(reward.body), findsOneWidget);
  });
}
