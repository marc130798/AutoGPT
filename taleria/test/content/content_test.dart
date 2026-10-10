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

  test('Inseln 1 bis 3: Ankerplätze nach Station 2, 4 und 6, je mit Wrack und Fund', () {
    for (final island in islands.take(3)) {
      expect([for (final d in island.dives) d.after], [2, 4, 6], reason: island.slug);
      expect(island.dives.map((d) => d.find).toSet(), hasLength(3), reason: '${island.slug}: drei verschiedene Funde');
    }
  });

  test('Sechs Stationen haben ein echtes Mini-Spiel (Sortieren oder Reihenfolge)', () {
    final built = [
      for (final island in islands)
        for (final s in island.stations)
          if (builtGames.contains(s.game?['art'])) '${island.slug}/${s.number}',
    ];
    expect(built, hasLength(6));
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

  test('supabase/inhalte_live.sql ist aktuell (sonst: dart run tool/build_seed.dart)', () {
    expect(
      File('supabase/inhalte_live.sql').readAsStringSync(),
      buildSeedSql(islands, encounters: encounters, target: SeedTarget.live),
    );
  });

  group('Status und Live-Import', () {
    test('Ohne Angabe ist alles Entwurf', () {
      expect(islands.map((i) => i.status).toSet(), {'entwurf'});
      expect(encounters.map((e) => e.status).toSet(), {'entwurf'});
    });

    test('Der Live-Import hat keine Test-Einstellungen', () {
      expect(buildSeedSql(islands, encounters: encounters), contains('content_preview'));
      final live = buildSeedSql(islands, encounters: encounters, target: SeedTarget.live);
      expect(live, isNot(contains('app_settings')));
      expect(live, contains('LIVE-Datenbank'));
    });

    test('Freigegebene Insel: erst alles auf der Insel, dann die Insel veröffentlichen', () {
      final json = jsonDecode(File('content/stufe1/01-hafen.json').readAsStringSync()) as Map<String, dynamic>;
      final hafen = parseIsland('01-hafen.json', jsonEncode({...json, 'status': 'freigegeben'}));
      final sql = buildSeedSql([hafen], target: SeedTarget.live);
      expect(sql, isNot(contains("'draft'")));
      expect(
        sql.indexOf("update public.islands set status = 'published'"),
        greaterThan(sql.lastIndexOf('insert into public.conversation_prompts')),
      );
      expect(
        RegExp(r'insert into public\.islands \([^)]*status').hasMatch(sql),
        isFalse,
        reason: 'neue Inseln starten als Entwurf',
      );
    });
  });

  group('Die Prüfung findet Fehler', () {
    Island islandWith(Map<String, dynamic> station, {Map<String, dynamic> extra = const {}}) => parseIsland(
      'test.json',
      jsonEncode({
        ...extra,
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

    test('unbekannter Status', () {
      expect(problems(islandWith(station(), extra: {'status': 'fertig'})), contains(contains('"status" muss')));
    });

    Island fogIsland({String status = 'entwurf'}) => parseIsland(
      'nebel.json',
      jsonEncode({
        'slug': 'hafen',
        'titel': 'Nebel',
        'reihenfolge': 1,
        'gruppe': 1,
        'zugang': 'gratis',
        'lernziel': 'Test',
        'nebel': true,
        'status': status,
      }),
    );

    test('Insel im Nebel bleibt Entwurf', () {
      expect(problems(fogIsland(status: 'freigegeben')), contains(contains('bleibt Entwurf')));
    });

    test('freigegeben, aber eine Insel davor noch nicht', () {
      expect(
        validateIslands([
          fogIsland(),
          islandWith(station(), extra: {'status': 'freigegeben'}),
        ], knownAssetKeys: assetKeys),
        contains(contains('Inseln davor noch nicht: hafen')),
      );
    });
  });

  group('Die Prüfung findet Fehler in Spielen', () {
    Map<String, dynamic> sortGame(List<Map<String, dynamic>> items) => {
      'art': 'sort',
      'aufgabe': 'Sortiere',
      'koerbe': ['A', 'B'],
      'dinge': items,
      'geschafft': {'wer': 'talo', 'text': 'Gut!'},
    };
    final four = [
      for (var i = 0; i < 4; i++) <String, dynamic>{'text': 'Ding $i', 'korb': i % 2},
    ];

    test('gültiges Sortier-Spiel', () => expect(validateGame(sortGame(four), 'test'), isEmpty));
    test('unbekannter Korb', () {
      expect(
        validateGame(
          sortGame([
            ...four,
            {'text': 'X', 'korb': 5},
          ]),
          'test',
        ),
        contains(contains('unbekannten Korb')),
      );
    });
    test('passt überall hin, aber ohne Hinweis', () {
      expect(
        validateGame(
          sortGame([
            ...four,
            {'text': 'X', 'korb': null},
          ]),
          'test',
        ),
        contains(contains('Hinweis')),
      );
    });
    test('Reihenfolge braucht von und bis', () {
      expect(
        validateGame({
          'art': 'order',
          'aufgabe': 'Ordne',
          'dinge': [
            for (var i = 0; i < 3; i++) {'text': 'Ding $i'},
          ],
          'geschafft': {'wer': 'talo', 'text': 'Gut!'},
        }, 'test'),
        contains(contains('"von" und "bis"')),
      );
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
    test('unbekannter Status', () => expect(problems({'status': 'live'}), contains(contains('"status" muss'))));
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
