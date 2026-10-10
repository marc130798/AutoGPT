import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/features/map/map_painters.dart';

import '../fake_content.dart';
import '../fakes.dart';
import '../test_helpers.dart';

/// Die bewegte Karte: Nebel-Start, Schiff segelt zur neuen Insel, Schloss
/// springt auf. Die Szene bewegt sich ständig (Wellen), deshalb hier `pump`
/// mit Zeitangabe statt `pumpAndSettle`.
void main() {
  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// Kind auf seinem Gerät; öffnet die Karte, ohne auf Ruhe zu warten.
  Future<({FakeLocalSettings settings, String childId})> openMap(
    WidgetTester tester, {
    bool hafenDone = false,
    bool stopsDone = true,
    String? lastShip,
  }) async {
    final backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    final mila = backend.addChild(parent);
    backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
    final content = FakeContent();
    final progress = FakeProgress(content);
    if (hafenDone) progress.completedIslands.add('island-hafen');
    if (hafenDone && stopsDone) progress.done.addAll(['island-tauschinsel/sea1', 'island-tauschinsel/sea2']);
    final settings = FakeLocalSettings();
    if (lastShip != null) settings.ships[mila.id] = lastShip;

    await tester.pumpWidget(
      buildTestApp(backend: backend, content: content, progress: progress, settings: settings, sceneMotion: true),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Ich habe einen Code');
    await tester.enterText(find.byKey(const ValueKey('child-code-field')), 'ABCD2345');
    await tapText(tester, 'An Bord gehen');
    await tester.ensureVisible(find.text('Zur Karte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zur Karte'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return (settings: settings, childId: mila.id);
  }

  Finder lockOn(String slug) => find.descendant(
    of: find.byKey(ValueKey('island-$slug')),
    matching: find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LockPainter),
  );

  testWidgets('Nebel-Start: Wolken liegen über der Karte und ziehen auseinander', (tester) async {
    final (:settings, :childId) = await openMap(tester);
    expect(find.byKey(const ValueKey('map-fog-intro')), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey('map-fog-intro')), findsNothing);
    expect(find.text('Hafen von Taleria'), findsOneWidget);
    // Beim ersten Besuch merkt sich das Gerät, wo das Schiff liegt.
    expect(settings.ships[childId], 'island-hafen');
  });

  testWidgets('Antippen überspringt den Nebel-Start', (tester) async {
    await openMap(tester);
    await tester.tap(find.byKey(const ValueKey('map-fog-intro')));
    await tester.pump();
    expect(find.byKey(const ValueKey('map-fog-intro')), findsNothing);
  });

  testWidgets('Neue Insel offen: Schiff segelt hin, dann springt das Schloss auf', (tester) async {
    final (:settings, :childId) = await openMap(tester, hafenDone: true, lastShip: 'island-hafen');
    // Sofort gemerkt, damit die Fahrt nicht noch einmal kommt.
    expect(settings.ships[childId], 'island-tauschinsel');

    // Während des Nebel-Starts und der Fahrt hängt das Schloss noch an der Tauschinsel.
    await tester.pump(const Duration(seconds: 3));
    expect(lockOn('tauschinsel'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(lockOn('tauschinsel'), findsOneWidget);

    // Angekommen: Schloss springt auf und verschwindet.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(lockOn('tauschinsel'), findsNothing);
    // Die Wunschinsel bleibt verschlossen.
    expect(lockOn('wunschinsel'), findsOneWidget);
  });

  testWidgets('Stopps auf See: Schiff wartet am Hafen, die Tauschinsel bleibt zu', (tester) async {
    final (:settings, :childId) = await openMap(tester, hafenDone: true, stopsDone: false, lastShip: 'island-hafen');
    await tester.pump(const Duration(seconds: 3));
    expect(settings.ships[childId], 'island-hafen', reason: 'erst nach den Stopps fährt das Schiff weiter');
    expect(lockOn('tauschinsel'), findsOneWidget);
    expect(find.byKey(const ValueKey('sea-stop-tauschinsel-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('sea-stop-tauschinsel-2')), findsOneWidget);
    expect(find.text('Das Händlerschiff'), findsOneWidget);
    expect(find.text('Das Fischerboot'), findsOneWidget);
  });

  testWidgets('Bewegung reduziert: kein Nebel-Start, keine Fahrt', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final (:settings, :childId) = await openMap(tester, hafenDone: true, lastShip: 'island-hafen');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-fog-intro')), findsNothing);
    expect(lockOn('tauschinsel'), findsNothing);
    expect(settings.ships[childId], 'island-tauschinsel');
  });
}

/// Nur für den Test: Barrierefreiheits-Einstellungen des Geräts.
class FakeAccessibilityFeatures implements AccessibilityFeatures {
  const FakeAccessibilityFeatures({this.disableAnimations = false});

  @override
  final bool disableAnimations;

  @override
  bool get accessibleNavigation => false;
  @override
  bool get boldText => false;
  @override
  bool get highContrast => false;
  @override
  bool get invertColors => false;
  @override
  bool get onOffSwitchLabels => false;
  @override
  bool get reduceMotion => disableAnimations;
  @override
  bool get supportsAnnounce => false;
  @override
  bool get autoPlayAnimatedImages => true;
  @override
  bool get autoPlayVideos => true;
  @override
  bool get deterministicCursor => false;
}
