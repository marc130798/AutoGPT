import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/app_scope.dart';
import 'package:taleria/core/assets/asset_keys.dart';
import 'package:taleria/core/assets/character_image.dart';

import '../test_helpers.dart';

void main() {
  Widget host(Map<String, Uint8List> files, Widget child) => AppScope(
    services: buildTestApp(files: files).services,
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );

  Finder imageAt(String path) =>
      find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == path);

  const base = 'assets/images/character.talo.png';
  const wave = 'assets/images/character.talo.wave.png';

  testWidgets('Pose vorhanden: die App zeigt das Bild der Pose', (tester) async {
    await tester.pumpWidget(
      host({base: tinyPng, wave: tinyPng}, const CharacterImage(AssetKeys.talo, pose: CharacterPose.wave, width: 50)),
    );
    await tester.pumpAndSettle();
    expect(imageAt(wave), findsOneWidget);
    expect(imageAt(base), findsNothing);
  });

  testWidgets('Pose fehlt: die App zeigt das Grundbild der Figur', (tester) async {
    await tester.pumpWidget(
      host({base: tinyPng}, const CharacterImage(AssetKeys.talo, pose: CharacterPose.wave, width: 50)),
    );
    await tester.pumpAndSettle();
    expect(imageAt(base), findsOneWidget);
  });

  testWidgets('Beide Bilder fehlen: der Platzhalter von Talo, kein Absturz', (tester) async {
    await tester.pumpWidget(
      host({}, const CharacterImage(AssetKeys.talo, pose: CharacterPose.happy, width: 50, height: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Talo'), findsOneWidget);
  });

  test('Schlüssel der Posen', () {
    expect(AssetKeys.pose(AssetKeys.tala, CharacterPose.think), 'character.tala.think');
    expect(AssetKeys.all, contains('character.talo.wave'));
  });
}
