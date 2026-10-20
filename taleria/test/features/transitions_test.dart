import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/features/common/dive_descent.dart';
import 'package:taleria/features/progress/celebration.dart';
import 'package:taleria/features/station/station_stage.dart';

import '../test_helpers.dart';

/// Übergänge aus dem Animationsplan (CLAUDE.md, Abschnitt 11): Welle beim
/// Bildschirmwechsel, Abtauchen, Schatzkarte, Knöpfe, die nachgeben.
void main() {
  Widget app(Widget home, {bool reduceMotion = false, GlobalKey<NavigatorState>? navigator}) => AppScope(
    services: buildTestApp().services,
    child: MaterialApp(
      navigatorKey: navigator,
      theme: taleriaThemeForStage(1),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: home,
    ),
  );

  Finder wave() => find.byWidgetPredicate((w) => w is ClipPath && w.clipper.runtimeType.toString() == '_WaveClipper');

  for (final reduceMotion in [false, true]) {
    testWidgets('Bildschirmwechsel mit Welle${reduceMotion ? ': ohne Bewegung sofort' : ''}', (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(app(const Text('Startseite'), reduceMotion: reduceMotion, navigator: navigator));
      navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Karte'))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(wave(), reduceMotion ? findsNothing : findsOneWidget);
      await tester.pumpAndSettle();
      expect(wave(), findsNothing);
      expect(find.text('Karte'), findsOneWidget);

      // Zurück: Die Welle sinkt wieder.
      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(wave(), reduceMotion ? findsNothing : findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Startseite'), findsOneWidget);
    });
  }

  testWidgets('Tauchgang: Der Bildschirm taucht ab und wird wieder klar, Antippen geht durch', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      app(
        DiveDescent(
          child: Center(
            child: TextButton(onPressed: () => tapped = true, child: const Text('Frage')),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('dive-descent')), findsOneWidget);
    await tester.tap(find.text('Frage'));
    expect(tapped, isTrue);
    await tester.pump(DiveDescent.duration);
    await tester.pump();
    expect(find.byKey(const ValueKey('dive-descent')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(const DiveDescent(child: Text('Frage')), reduceMotion: true));
    await tester.pump();
    expect(find.byKey(const ValueKey('dive-descent')), findsNothing);
  });

  testWidgets('Schatzkarte: Das neue Stück fliegt erst nach dem Aufrollen hinein und bleibt drin', (tester) async {
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: Center(child: IslandRewardEffect(badgeAssetKey: 'badge.hafen')),
        ),
      ),
    );
    final piece = find.byKey(const ValueKey('map-piece'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(piece, findsNothing, reason: 'die Karte rollt sich noch auf');
    await tester.pump(const Duration(milliseconds: 700));
    expect(piece, findsOneWidget);
    await tester.pumpAndSettle();
    expect(piece, findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: Center(child: IslandRewardEffect(badgeAssetKey: 'badge.hafen')),
        ),
        reduceMotion: true,
      ),
    );
    await tester.pump();
    expect(piece, findsOneWidget, reason: 'ohne Bewegung sofort am Platz');
  });

  testWidgets('Antwort-Knopf gibt beim Antippen leicht nach', (tester) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: AnswerButton(text: 'Muschel', onPressed: () {}),
        ),
      ),
    );
    double scale() => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
    expect(scale(), 1);
    final gesture = await tester.startGesture(tester.getCenter(find.text('Muschel')));
    await tester.pump();
    expect(scale(), lessThan(1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(), 1);
  });
}
