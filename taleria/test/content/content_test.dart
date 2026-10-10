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

  test('Alle 20 Spiele der Inseln 1 bis 3 sind echte Spiele, kein Platzhalter mehr', () {
    final games = [
      for (final island in islands.take(3))
        for (final s in island.stations)
          if (s.game != null) s.game!['art'],
    ];
    expect(games, hasLength(20));
    expect(games.where((art) => !builtGames.contains(art) && art != 'wish_bottle'), isEmpty);
    expect(games.toSet(), {'sort', 'order', 'choice', 'coins', 'pick', 'number', 'wish_bottle'});
  });

  test('Meister Taleron ist die erste Begegnung, ab dem Start', () {
    final taleron = encounters.singleWhere((e) => e.type == 'taleron');
    expect(taleron.afterIsland, isNull);
    expect(taleron.questionCount, 3);
  });

  test('Stopps auf See: je zwei vor Tauschinsel und Wunschinsel, keine vor dem Hafen', () {
    final bySlug = {for (final i in islands) i.slug: i};
    expect(bySlug['hafen']!.seaStops, isEmpty);
    expect(bySlug['tauschinsel']!.seaStops.map((s) => s.kind), ['haendlerschiff', 'fischerboot']);
    expect(bySlug['wunschinsel']!.seaStops.map((s) => s.kind), ['haendlerschiff', 'tala_vergisst']);
    // Keine Frage eines Stopps steht wortgleich auch woanders.
    final stationTexts = {
      for (final i in islands)
        for (final st in i.stations)
          for (final q in st.questions) q.question,
    };
    for (final i in islands) {
      for (final stop in i.seaStops) {
        for (final q in stop.questions) {
          expect(stationTexts, isNot(contains(q.question)), reason: '${i.slug}: ${q.question}');
        }
      }
    }
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
        ...extra,
      }),
    );

    Map<String, dynamic> station({
      int questions = 6,
      String speaker = 'talo',
      List<String> wrong = const ['b', 'c'],
      List<Map<String, dynamic>>? lesson,
      String? sceneImage,
    }) => {
      'nr': 1,
      'typ': 'game',
      'titel': 'Station',
      'ort': 'Ort',
      'lernziel': 'Ziel',
      'dauer': '5 Min.',
      'szene': [
        {'wer': speaker, 'text': 'Hallo', 'bild': ?sceneImage},
      ],
      'erklaerung':
          lesson ??
          [
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

    test('Bildergeschichte: Bilder aus dem Manifest, erste Zeile mit Bild, nur in der Erklärung', () {
      expect(
        problems(
          islandWith(
            station(
              lesson: [
                {'wer': 'tala', 'text': 'Eins', 'bild': 'story.hafen.2.1'},
                {'wer': 'talo', 'text': 'Zwei'},
              ],
            ),
          ),
        ),
        isEmpty,
      );
      expect(
        problems(
          islandWith(
            station(
              lesson: [
                {'wer': 'tala', 'text': 'Eins', 'bild': 'story.gibtsnicht.1'},
              ],
            ),
          ),
        ),
        contains(contains('Bild story.gibtsnicht.1 fehlt')),
      );
      expect(
        problems(
          islandWith(
            station(
              lesson: [
                {'wer': 'tala', 'text': 'Eins'},
                {'wer': 'talo', 'text': 'Zwei', 'bild': 'story.hafen.2.1'},
              ],
            ),
          ),
        ),
        contains(contains('erste Zeile der Erklärung braucht ein "bild"')),
      );
      expect(
        problems(islandWith(station(sceneImage: 'story.hafen.2.1'))),
        contains(contains('"bild" gibt es nur in der Erklärung')),
      );
    });

    test('Inseln 1 bis 3: jede Erklärung ist eine Bildergeschichte, Stationen ohne Film', () {
      for (final island in islands.take(3)) {
        for (final s in island.stations.where((s) => s.lesson.isNotEmpty)) {
          expect(s.lesson.first.image, isNotNull, reason: '${island.slug} ${s.number}');
          expect(s.video, isNull, reason: '${island.slug} ${s.number}');
        }
      }
    });

    test('Stopps auf See: Art, Figur, Pool, nicht vor der ersten Insel', () {
      Map<String, dynamic> stop({String art = 'haendlerschiff', String figur = 'haendler', int questions = 6}) => {
        'art': art,
        'figur': figur,
        'titel': 'Ein Stopp',
        'seemeilen': 30,
        'szene': [
          {'wer': 'talo', 'text': 'Ahoi'},
        ],
        'abschluss': {'wer': 'talo', 'text': 'Weiter'},
        'quiz_anzahl': 3,
        'fragen': [
          for (var i = 0; i < questions; i++)
            {
              'frage': 'S$i',
              'richtig': 'a',
              'falsch': ['b', 'c'],
              'erklaerung': 'e',
            },
        ],
      };
      expect(
        problems(
          islandWith(
            station(),
            extra: {
              'reihenfolge': 1,
              'stopps_auf_see': [stop()],
            },
          ),
        ),
        contains(contains('vor der ersten Insel gibt es keine Stopps auf See')),
      );
      expect(
        problems(
          islandWith(
            station(),
            extra: {
              'reihenfolge': 2,
              'stopps_auf_see': [stop()],
            },
          ),
        ),
        isEmpty,
      );
      expect(
        problems(
          islandWith(
            station(),
            extra: {
              'reihenfolge': 2,
              'stopps_auf_see': [stop(art: 'piratenschiff')],
            },
          ),
        ),
        contains(contains('unbekannte Art')),
      );
      expect(
        problems(
          islandWith(
            station(),
            extra: {
              'reihenfolge': 2,
              'stopps_auf_see': [stop(figur: 'pirat')],
            },
          ),
        ),
        contains(contains('unbekannte Figur "pirat"')),
      );
      expect(
        problems(
          islandWith(
            station(),
            extra: {
              'reihenfolge': 2,
              'stopps_auf_see': [stop(questions: 5)],
            },
          ),
        ),
        contains(contains('mindestens doppelt so groß')),
      );
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

  group('Die Prüfung findet Fehler in den neuen Spielarten', () {
    Map<String, dynamic> done = {'wer': 'talo', 'text': 'Gut!'};
    List<String> problems(Map<String, dynamic> game) =>
        validateGame({'aufgabe': 'Los', 'geschafft': done, ...game}, 'test', knownAssetKeys: assetKeys);
    Map<String, dynamic> option(bool good) => {'text': 'Möglichkeit', 'gut': good, 'antwort': 'Antwort'};

    test('Entscheidungen: jede Runde braucht eine gute Möglichkeit', () {
      final round = {
        'frage': 'Was tun?',
        'optionen': [option(true), option(false)],
      };
      expect(
        problems({
          'art': 'choice',
          'runden': [round, round],
        }),
        isEmpty,
      );
      expect(
        problems({
          'art': 'choice',
          'runden': [
            round,
            {
              'frage': 'Was tun?',
              'optionen': [option(false), option(false)],
            },
          ],
        }),
        contains(contains('mindestens eine gute Möglichkeit')),
      );
    });

    test('Entscheidungen: unbekannte Figur in der Szene', () {
      expect(
        problems({
          'art': 'choice',
          'runden': [
            for (var i = 0; i < 2; i++)
              {
                'szene': [
                  {'wer': 'pirat', 'text': 'Arr!'},
                ],
                'frage': 'Was tun?',
                'optionen': [option(true), option(false)],
              },
          ],
        }),
        contains(contains('unbekannte Figur "pirat"')),
      );
    });

    test('Münzen legen: Betrag bis 50 Euro', () {
      expect(
        problems({
          'art': 'coins',
          'runden': [
            {'text': 'Lege 3,50 €.', 'betrag': 350},
            {'text': 'Lege 80 €.', 'betrag': 8000},
          ],
        }),
        contains(contains('Betrag 1 Cent bis 50 Euro')),
      );
    });

    test('Auswählen: die richtigen Teile müssen genau den Betrag ergeben', () {
      expect(
        problems({
          'art': 'pick',
          'modus': 'genau',
          'betrag': 10,
          'dinge': [
            {'text': 'Fisch', 'preis': 4, 'richtig': true},
            {'text': 'Brötchen', 'preis': 1, 'richtig': true},
            {'text': 'Serviette', 'preis': 2, 'hinweis': 'Gehört nicht dazu.'},
          ],
        }),
        contains(contains('ergeben 5 statt 10')),
      );
    });

    test('Rechnen: Erklärung nötig', () {
      expect(
        problems({
          'art': 'number',
          'runden': [
            {'frage': '12 mal 5?', 'antwort': 60},
          ],
        }),
        contains(contains('"erklaerung" nötig')),
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
