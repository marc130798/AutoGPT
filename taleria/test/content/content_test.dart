import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/content/content_model.dart';

void main() {
  final islands = loadIslands(Directory('content/stufe1'));
  final manifest = jsonDecode(File('assets/asset_manifest.json').readAsStringSync()) as Map<String, dynamic>;
  final assetKeys = (manifest['assets'] as Map<String, dynamic>).keys.toSet();
  final encounters = parseEncounters('begegnungen.json', File('content/begegnungen.json').readAsStringSync());

  test('Alle Inhaltsdateien halten die Regeln ein', () {
    expect(validateIslands(islands, knownAssetKeys: assetKeys), isEmpty);
    expect(validateEncounters(encounters, islands: islands, knownAssetKeys: assetKeys), isEmpty);
  });

  test('Jede Insel mit Inhalt hat einen Orden', () {
    expect(
      [for (final i in islands.where((i) => !i.fog)) i.badge],
      ['Erster Landgang', 'Meistertauscher', 'Klarer Kompass'],
    );
  });

  test('Meister Taleron ist die erste Begegnung, ab dem Start', () {
    final taleron = encounters.singleWhere((e) => e.type == 'taleron');
    expect(taleron.afterIsland, isNull);
    expect(taleron.questionCount, 3);
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
    expect(File('supabase/seed.sql').readAsStringSync(), buildSeedSql(islands, encounters: encounters));
  });

  group('Die Prüfung findet Fehler', () {
    Island islandWith(Map<String, dynamic> station) => parseIsland(
      'test.json',
      jsonEncode({
        'slug': 'tauschinsel',
        'titel': 'Test',
        'orden': 'Test-Orden',
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

  group('Die Prüfung findet Fehler in Begegnungen', () {
    Map<String, dynamic> line(String who) => {'wer': who, 'text': 'Hallo'};
    List<String> problems(Map<String, dynamic> changes) => validateEncounters(
      parseEncounters(
        'test.json',
        jsonEncode({
          'begegnungen': [
            {
              'slug': 'test',
              'art': 'taleron',
              'titel': 'Test',
              'bild': 'character.taleron',
              'erste_begegnung': [line('taleron')],
              'szene': [line('taleron')],
              'richtig': line('taleron'),
              'falsch': line('taleron'),
              'geschafft': line('taleron'),
              ...changes,
            },
          ],
        }),
      ),
      islands: islands,
      knownAssetKeys: assetKeys,
    );

    test('gültige Begegnung', () => expect(problems({}), isEmpty));
    test('unbekannte Art', () => expect(problems({'art': 'piratenschiff'}), contains(contains('unbekannte Art'))));
    test('zu viele Fragen', () => expect(problems({'fragen': 6}), contains(contains('3 bis 5 Fragen'))));
    test('unbekannte Insel', () => expect(problems({'ab_insel': 'atlantis'}), contains(contains('unbekannte Insel'))));
    test('unbekannte Figur', () {
      expect(
        problems({
          'szene': [line('pirat')],
        }),
        contains(contains('unbekannte Figur')),
      );
    });
  });
}
