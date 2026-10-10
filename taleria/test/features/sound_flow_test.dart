import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/assets/asset_keys.dart';
import 'package:taleria/services/sounds.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Meeresrauschen im Hauptmenü, Lautsprecher-Knopf, Töne bei richtigen
/// Antworten und Schalter im Leuchtturm.
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

  /// Kind mit erledigtem Intro auf seinem eigenen Gerät, auf der Startseite.
  Future<({FakeContent content, Sounds sounds, FakeLocalSettings settings})> startOnHome(WidgetTester tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    final content = FakeContent();
    final settings = FakeLocalSettings();
    final sounds = Sounds(settings: settings);
    await tester.pumpWidget(
      buildTestApp(
        backend: backend,
        content: content,
        progress: FakeProgress(content),
        settings: settings,
        sounds: sounds,
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Ich habe einen Code');
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tapText(tester, 'An Bord gehen');
    return (content: content, sounds: sounds, settings: settings);
  }

  testWidgets('Meeresrauschen auf Startseite und Karte, still auf der Insel', (tester) async {
    final (:content, :sounds, :settings) = await startOnHome(tester);
    expect(sounds.playingMusic, AssetKeys.musicHome);

    await tapText(tester, 'Zur Karte');
    expect(sounds.playingMusic, AssetKeys.musicHome, reason: 'läuft auf der Karte weiter');

    await tapKey(tester, 'island-hafen');
    expect(sounds.playingMusic, isNull, reason: 'auf der Insel keine Musik');

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(sounds.playingMusic, AssetKeys.musicHome);
  });

  testWidgets('Lautsprecher-Knopf schaltet Musik und Töne aus und wieder an', (tester) async {
    final (:content, :sounds, :settings) = await startOnHome(tester);
    expect(find.text('Ton an'), findsOneWidget);

    await tapKey(tester, 'sound-toggle');
    expect(sounds.enabled, isFalse);
    expect(sounds.playingMusic, isNull);
    expect(settings.sound, isFalse, reason: 'bleibt auf diesem Gerät gespeichert');
    expect(find.text('Ton aus'), findsOneWidget);

    await tapKey(tester, 'sound-toggle');
    expect(sounds.playingMusic, AssetKeys.musicHome);
  });

  testWidgets('Richtige Antworten klingen, am Ende eine Fanfare; falsche bleiben still', (tester) async {
    final (:content, :sounds, :settings) = await startOnHome(tester);
    await tapText(tester, 'Zur Karte');
    await tapKey(tester, 'island-hafen');
    await tapKey(tester, 'station-2');

    for (var i = 0; i < 40 && find.byKey(const ValueKey('quiz-question')).evaluate().isEmpty; i++) {
      if (find.byKey(const ValueKey('choice-question')).evaluate().isNotEmpty) {
        while (find.byKey(const ValueKey('game-done')).evaluate().isEmpty) {
          for (var option = 0; option < 4; option++) {
            await tapKey(tester, 'choice-option-$option');
            if (find.byKey(const ValueKey('game-retry')).evaluate().isEmpty) break;
            await tapKey(tester, 'game-retry');
          }
          if (find.byKey(const ValueKey('game-done')).evaluate().isEmpty) await tapKey(tester, 'game-next');
        }
        await tapKey(tester, 'game-done');
      } else {
        await tapText(tester, 'Weiter');
      }
    }

    // Erste Frage falsch: kein Ton.
    final first = tester.widget<Text>(find.byKey(const ValueKey('quiz-question'))).data!;
    final wrong = content.wrongAnswerFor(first);
    await tapText(tester, wrong);
    expect(sounds.playedEffects, isEmpty);
    await tapText(tester, 'Nächste Frage');

    while (find.byKey(const ValueKey('quiz-question')).evaluate().isNotEmpty) {
      final question = tester.widget<Text>(find.byKey(const ValueKey('quiz-question'))).data!;
      await tapText(tester, content.rightAnswerFor(question));
      await tapText(tester, find.text('Fertig').evaluate().isEmpty ? 'Nächste Frage' : 'Fertig');
    }
    expect(sounds.playedEffects.where((e) => e == AssetKeys.soundCorrect), hasLength(4));
    expect(sounds.playedEffects.last, AssetKeys.soundStationDone);
  });

  testWidgets('Leuchtturm: Eltern schalten die Musik im Hauptmenü aus', (tester) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    backend.addChild(parent);
    final settings = FakeLocalSettings();
    final sounds = Sounds(settings: settings);
    backend.signInAs('eltern@test.invalid');
    await tester.pumpWidget(buildTestApp(backend: backend, content: FakeContent(), settings: settings, sounds: sounds));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('pin-gate-field')), '2468');
    await tapText(tester, 'Öffnen');

    await tapKey(tester, 'music-switch');
    expect(sounds.musicAllowed, isFalse);
    expect(settings.music, isFalse);
    expect(sounds.enabled, isTrue, reason: 'Töne bei richtigen Antworten bleiben');
  });
}
