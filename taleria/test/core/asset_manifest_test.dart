import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/assets/asset_keys.dart';
import 'package:taleria/core/assets/asset_manifest.dart';

void main() {
  group('Echtes Manifest (assets/asset_manifest.json)', () {
    late TaleriaAssetManifest manifest;

    setUpAll(() {
      manifest = TaleriaAssetManifest.parse(File('assets/asset_manifest.json').readAsStringSync());
    });

    test('lässt sich fehlerfrei lesen', () {
      expect(manifest.length, greaterThan(0));
    });

    test('enthält alle festen Schlüssel aus dem Code', () {
      for (final key in AssetKeys.all) {
        expect(manifest.contains(key), isTrue, reason: '$key fehlt im Manifest');
      }
    });

    test('enthält Hintergrund, Ankunftsfilm und Orden für alle 15 Inseln', () {
      const slugs = [
        'hafen',
        'tauschinsel',
        'wunschinsel',
        'spar-insel',
        'taschengeld-bucht',
        'marktinsel',
        'werbe-riff',
        'verdienst-insel',
        'bank-insel',
        'zins-insel',
        'leih-lagune',
        'sicherheits-festung',
        'risiko-klippen',
        'zukunftsinsel',
        'schatzinsel',
      ];
      for (final slug in slugs) {
        expect(manifest.contains(AssetKeys.islandBackground(slug)), isTrue, reason: slug);
        expect(manifest.contains(AssetKeys.arrivalVideo(slug)), isTrue, reason: slug);
        expect(manifest.contains(AssetKeys.islandBadge(slug)), isTrue, reason: slug);
      }
    });

    test('Talo ist ein oranger Kreis', () {
      final talo = manifest.lookup(AssetKeys.talo);
      expect(talo.placeholder.label, 'Talo');
      expect(talo.placeholder.shape, PlaceholderShape.circle);
      expect(talo.type, AssetType.rive);
    });

    test('Bilder liegen unter assets/images/ und heißen wie ihr Schlüssel', () {
      for (final entry in manifest.entries.where((e) => e.type == AssetType.image)) {
        expect(entry.path, 'assets/images/${entry.key}.png');
      }
    });

    test('Jeder Pfad liegt in einem Ordner, den pubspec.yaml einbindet', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final entry in manifest.entries.where((e) => e.path != null)) {
        final folder = entry.path!.substring(0, entry.path!.lastIndexOf('/') + 1);
        expect(pubspec, contains('- $folder'), reason: '${entry.key}: $folder fehlt in pubspec.yaml');
      }
    });
  });

  group('Fehlerfälle', () {
    String manifestWith(String entry) => '{"version": 1, "assets": {$entry}}';

    test('unbekannter Schlüssel ergibt grauen Platzhalter statt Absturz', () {
      final manifest = TaleriaAssetManifest.parse(manifestWith(''));
      final entry = manifest.lookup('character.unbekannt');
      expect(entry.path, isNull);
      expect(entry.placeholder.label, 'character.unbekannt');
    });

    test('kaputtes JSON wird mit Meldung abgelehnt', () {
      expect(() => TaleriaAssetManifest.parse('{'), throwsA(isA<AssetManifestException>()));
    });

    test('falsche Farbe wird abgelehnt', () {
      expect(
        () => TaleriaAssetManifest.parse(
          manifestWith(
            '"character.x": {"type": "image", "path": null, "placeholder": {"label": "X", "color": "orange"}}',
          ),
        ),
        throwsA(isA<AssetManifestException>()),
      );
    });

    test('unbekannter Typ wird abgelehnt', () {
      expect(
        () => TaleriaAssetManifest.parse(
          manifestWith(
            '"character.x": {"type": "gif", "path": null, "placeholder": {"label": "X", "color": "#FFFFFF"}}',
          ),
        ),
        throwsA(isA<AssetManifestException>()),
      );
    });

    test('Pfad außerhalb von assets/ wird abgelehnt', () {
      expect(
        () => TaleriaAssetManifest.parse(
          manifestWith(
            '"character.x": {"type": "image", "path": "/etc/x.png", "placeholder": {"label": "X", "color": "#FFFFFF"}}',
          ),
        ),
        throwsA(isA<AssetManifestException>()),
      );
    });

    test('Schlüssel ohne Punkt wird abgelehnt', () {
      expect(
        () => TaleriaAssetManifest.parse(
          manifestWith('"talo": {"type": "image", "path": null, "placeholder": {"label": "X", "color": "#FFFFFF"}}'),
        ),
        throwsA(isA<AssetManifestException>()),
      );
    });
  });
}
