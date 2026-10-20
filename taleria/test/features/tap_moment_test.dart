import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/assets/asset_keys.dart';
import 'package:taleria/core/theme/taleria_theme.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/features/station/picture_story.dart';
import 'package:taleria/features/station/station_stage.dart';
import 'package:taleria/features/station/tap_moment_view.dart';
import 'package:taleria/l10n/app_localizations.dart';
import 'package:taleria/services/sounds.dart';

import '../../tool/content/content_model.dart' as tool;
import '../fakes.dart';
import '../test_helpers.dart';

/// Antipp-Momente zwischen den Bildern der Erklärung (INSELN.md): antippen,
/// wischen, ziehen, umdrehen. Keine Prüfung, „Weiter“ geht immer.
void main() {
  late Sounds sounds;

  Future<void> pump(WidgetTester tester, Widget child) async {
    sounds = Sounds(settings: FakeLocalSettings());
    await tester.pumpWidget(
      AppScope(
        services: buildTestApp(sounds: sounds).services,
        child: MaterialApp(
          theme: taleriaThemeForStage(1),
          locale: const Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: StagePanel(
              open: true,
              child: ListView(padding: const EdgeInsets.all(16), children: [child]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder key(String k) => find.byKey(ValueKey(k));

  test('Zeichen: App und Werkzeug kennen dieselben', () {
    expect(tapSymbols.keys.toSet(), tool.tapSymbols);
  });

  test('Alle Antipp-Momente der Inseln 1 bis 3 haben ein Zeichen der App oder ein Bild', () {
    final islands = tool.loadIslands(Directory('content/stufe1'));
    var count = 0;
    for (final island in islands) {
      for (final station in island.stations) {
        for (final t in station.toDbContent()['taps'] as List? ?? const []) {
          final moment = TapMoment.fromJson(t as Map<String, dynamic>);
          expect(moment.image != null || tapSymbols.containsKey(moment.symbol), isTrue, reason: moment.text);
          if (moment.kind == 'flip') expect(moment.back, isNotEmpty, reason: moment.text);
          count++;
        }
      }
    }
    expect(count, greaterThanOrEqualTo(40), reason: '20 Stationen mit je 2');
  });

  test('Seiten: nach Bild n die Antipp-Momente mit after == n, am Ende die Auflösung', () {
    const a = TapMoment(after: 1, kind: 'tap', text: 'A');
    const b = TapMoment(after: 3, kind: 'flip', text: 'B', back: 'Rückseite');
    final pages = storyPages(3, [b, a], reveal: true);
    expect(pages.map((p) => p.runtimeType), [LinePage, TapPage, LinePage, LinePage, TapPage, RevealPage]);
    expect((pages[1] as TapPage).moment, a);
    expect((pages[4] as TapPage).moment, b);
  });

  testWidgets('Antippen: dreimal mit dem Hammer, dann der Satz danach und ein Münzklang', (tester) async {
    var done = 0;
    await pump(
      tester,
      TapMomentView(
        moment: const TapMoment(
          after: 1,
          kind: 'tap',
          text: 'Tipp dreimal mit dem Hammer auf den Nagel.',
          symbol: 'hammer',
          count: 3,
          done: 'Das Boot ist wieder dicht.',
        ),
        onDone: () => done++,
      ),
    );
    expect(find.text('Mach mit!'), findsOneWidget);
    expect(find.byIcon(Icons.hardware_rounded), findsOneWidget);
    expect(find.text('Noch 3-mal'), findsOneWidget);

    await tester.tap(key('tap-target'));
    await tester.pumpAndSettle();
    expect(find.text('Noch 2-mal'), findsOneWidget);
    expect(key('tap-done'), findsNothing);

    await tester.tap(key('tap-target'));
    await tester.tap(key('tap-target'));
    await tester.pumpAndSettle();
    expect(find.text('Das Boot ist wieder dicht.'), findsOneWidget);
    expect(key('tap-count'), findsNothing);
    expect(done, 1);
    expect(sounds.playedEffects, [AssetKeys.soundCoin]);

    // Weiter tippen ändert nichts mehr.
    await tester.tap(key('tap-target'));
    await tester.pumpAndSettle();
    expect(done, 1);
  });

  testWidgets('Wischen: das Ding zur Seite schieben; ein kleiner Schubs reicht nicht', (tester) async {
    await pump(
      tester,
      TapMomentView(
        moment: const TapMoment(
          after: 1,
          kind: 'swipe',
          text: 'Wisch den Staub von der alten Kiste.',
          symbol: 'besen',
          done: 'Darunter liegen Muscheln.',
        ),
        onDone: () {},
      ),
    );
    expect(find.text('Wisch zur Seite'), findsOneWidget);
    await tester.timedDrag(key('tap-target'), const Offset(30, 0), const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(key('tap-done'), findsNothing);

    await tester.drag(key('tap-target'), const Offset(150, 0));
    await tester.pumpAndSettle();
    expect(find.text('Darunter liegen Muscheln.'), findsOneWidget);
    expect(find.text('Wisch zur Seite'), findsNothing);
  });

  testWidgets('Ziehen: das Ding auf das Ziel legen, ohne eigenen Satz „Super gemacht!“', (tester) async {
    await pump(
      tester,
      TapMomentView(
        moment: const TapMoment(after: 1, kind: 'drag', text: 'Leg die Münze auf die Theke.', symbol: 'muenze'),
        onDone: () {},
      ),
    );
    expect(find.text('Hierher'), findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(key('tap-target')));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(key('tap-drop')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Super gemacht!'), findsOneWidget);
    expect(find.text('Hierher'), findsNothing);
    expect(key('tap-target'), findsNothing, reason: 'die Münze liegt jetzt im Ziel');
  });

  testWidgets('Ziehen: Antippen legt das Ding auch hin', (tester) async {
    await pump(
      tester,
      TapMomentView(
        moment: const TapMoment(after: 1, kind: 'drag', text: 'Zieh Tala zum Stand.', image: 'character.tala'),
        onDone: () {},
      ),
    );
    await tester.tap(key('tap-target'));
    await tester.pumpAndSettle();
    expect(key('tap-done'), findsOneWidget);
  });

  testWidgets('Umdrehen: die Karte zeigt die Rückseite, ohne Satz danach', (tester) async {
    await pump(
      tester,
      TapMomentView(
        moment: const TapMoment(
          after: 2,
          kind: 'flip',
          text: 'Dreh das Preisschild um.',
          symbol: 'preisschild',
          back: 'Preise ändern sich.',
        ),
        onDone: () {},
      ),
    );
    expect(find.text('Antippen zum Umdrehen'), findsOneWidget);
    expect(key('tap-back'), findsNothing);
    await tester.tap(key('tap-target'));
    await tester.pumpAndSettle();
    expect(find.text('Preise ändern sich.'), findsOneWidget);
    expect(find.text('Antippen zum Umdrehen'), findsNothing);
    expect(key('tap-done'), findsNothing);
  });

  testWidgets('Bildergeschichte: Antipp-Moment nach Bild 1, „Weiter“ geht auch ohne Mitmachen', (tester) async {
    var finished = false;
    await tester.pumpWidget(const SizedBox());
    sounds = Sounds(settings: FakeLocalSettings());
    await tester.pumpWidget(
      AppScope(
        services: buildTestApp(sounds: sounds).services,
        child: MaterialApp(
          theme: taleriaThemeForStage(1),
          locale: const Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: StagePanel(
              open: true,
              child: PictureStory(
                lines: const [
                  DialogLine(speaker: 'talo', text: 'Eins'),
                  DialogLine(speaker: 'tala', text: 'Zwei'),
                ],
                taps: const [
                  TapMoment(after: 1, kind: 'tap', text: 'Tipp die Truhe an.', symbol: 'truhe', done: 'Offen!'),
                ],
                onDone: () => finished = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> next() async {
      await tester.tap(key('story-next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Eins'), findsOneWidget);
    await next();
    expect(find.text('Tipp die Truhe an.'), findsOneWidget);
    // Ohne Mitmachen weiter, dann zurück und mitmachen.
    await next();
    expect(find.text('Zwei'), findsOneWidget);
    await tester.tap(key('story-back'));
    await tester.pumpAndSettle();
    await tester.tap(key('tap-target'));
    await tester.pumpAndSettle();
    expect(find.text('Offen!'), findsOneWidget);

    // Vor und zurück: Der Moment bleibt geschafft.
    await next();
    await tester.tap(key('story-back'));
    await tester.pumpAndSettle();
    expect(find.text('Offen!'), findsOneWidget);
    expect(sounds.playedEffects, [AssetKeys.soundCoin], reason: 'nur einmal geklungen');

    await next();
    await next();
    expect(finished, isTrue);
  });
}
