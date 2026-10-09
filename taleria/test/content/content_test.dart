import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/content/content_model.dart';

void main() {
  final islands = loadIslands(Directory('content/stufe1'));
  final manifest = jsonDecode(File('assets/asset_manifest.json').readAsStringSync()) as Map<String, dynamic>;
  final assetKeys = (manifest['assets'] as Map<String, dynamic>).keys.toSet();

  test('Alle Inhaltsdateien halten die Regeln ein', () {
    expect(validateIslands(islands, knownAssetKeys: assetKeys), isEmpty);
  });

  test('15 Inseln, 1 bis 3 komplett, 4 bis 15 im Nebel', () {
    expect(islands, hasLength(15));
    expect([for (final i in islands) i.order], List.generate(15, (i) => i + 1));
    for (final island in islands.take(3)) {
      expect(island.fog, isFalse, reason: island.slug);
      expect(island.stations, hasLength(8), reason: '${island.slug}: 7 Stationen und Prüfung');
    }
    for (final island in islands.skip(3)) {
      expect(island.fog, isTrue, reason: island.slug);
    }
  });

  test('Gratis sind nur Hafen und Tauschinsel', () {
    expect([for (final i in islands.where((i) => i.access == 'gratis')) i.slug], ['hafen', 'tauschinsel']);
  });

  test('supabase/seed.sql ist aktuell (sonst: dart run tool/build_seed.dart)', () {
    expect(File('supabase/seed.sql').readAsStringSync(), buildSeedSql(islands));
  });

  group('Die Prüfung findet Fehler', () {
    Island islandWith(Map<String, dynamic> station) => parseIsland(
      'test.json',
      jsonEncode({
        'slug': 'test',
        'titel': 'Test',
        'reihenfolge': 2,
        'gruppe': 1,
        'zugang': 'gratis',
        'lernziel': 'Test',
        'stationen': [
          station,
          {
            'nr': 2,
            'typ': 'exam',
            'titel': 'Prüfung',
            'ort': 'Ort',
            'lernziel': 'Ziel',
            'dauer': '5 Min.',
            'pruefung': {'anzahl': 1, 'rueckblick': 1, 'bestehen': 2},
            'fragen': [
              {
                'frage': 'P1',
                'richtig': 'a',
                'falsch': ['b', 'c'],
                'erklaerung': 'e',
                'station': 1,
              },
              {
                'frage': 'P2',
                'richtig': 'a',
                'falsch': ['b', 'c'],
                'erklaerung': 'e',
                'station': 1,
              },
            ],
          },
        ],
      }),
    );

    Map<String, dynamic> station({
      int questions = 6,
      String speaker = 'talo',
      List<String> wrong = const ['b', 'c'],
    }) => {
      'nr': 1,
      'typ': 'game',
      'titel': 'Station',
      'ort': 'Ort',
      'lernziel': 'Ziel',
      'dauer': '5 Min.',
      'szene': [
        {'wer': speaker, 'text': 'Hallo'},
      ],
      'erklaerung': [
        {'wer': 'tala', 'text': 'So geht das.'},
      ],
      'abschluss': {'wer': 'talo', 'text': 'Fertig.'},
      'quiz_anzahl': 3,
      'fragen': [
        for (var i = 0; i < questions; i++) {'frage': 'Frage $i', 'richtig': 'a', 'falsch': wrong, 'erklaerung': 'e'},
      ],
    };

    List<String> problems(Island island) => validateIslands([island], knownAssetKeys: assetKeys);

    test('gültige Insel', () => expect(problems(islandWith(station())), isEmpty));

    test('zu kleiner Pool', () {
      expect(problems(islandWith(station(questions: 5))), contains(contains('mindestens 6 Fragen')));
    });

    test('unbekannte Figur', () {
      expect(problems(islandWith(station(speaker: 'pirat'))), contains(contains('unbekannte Figur')));
    });

    test('nicht genau 3 Antworten', () {
      expect(problems(islandWith(station(wrong: ['b']))), contains(contains('genau 2 falsche Antworten')));
    });
  });
}
