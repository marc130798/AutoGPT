/// Inhalte der Inseln als Dateien (content/stufe1/*.json) und ihre Prüfung.
///
/// Die Dateien sind die einzige Quelle der Inhalte. Sie haben deutsche
/// Feldnamen, damit Marc sie lesen und ändern kann. Daraus erzeugt
/// tool/build_seed.dart die Dateien supabase/seed.sql (Testumgebung) und
/// supabase/inhalte_live.sql (geprüfter Import für die Live-Datenbank).
library;

import 'dart:convert';
import 'dart:io';

/// Stationstypen wie in der Datenbank (stations.type).
const stationTypes = {'video', 'quiz', 'game', 'practice', 'review_stop', 'exam'};

/// Mindestgröße eines Stations-Check-Pools (CLAUDE.md, Abschnitt 11).
const minCheckPool = 6;

/// Seemeilen für einen Tauchgang.
const diveXp = 50;

/// Status einer Insel oder Begegnung in den Dateien und in der Datenbank.
/// Kinder sehen in der Live-Datenbank nur „freigegeben“ (CLAUDE.md Abschnitt 10).
const contentStatuses = {'entwurf': 'draft', 'pruefung': 'review', 'freigegeben': 'published'};

class ContentException implements Exception {
  ContentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class Line {
  Line(this.speaker, this.text, this.name, {this.image});

  final String speaker;
  final String text;
  final String? name;

  /// Bild der Bildergeschichte zu dieser Zeile (nur in der Erklärung, `"bild"`).
  /// Zeilen ohne Bild zeigen das Bild davor.
  final String? image;

  Map<String, dynamic> toDb() => {'speaker': speaker, 'text': text, 'name': ?name, 'image': ?image};
}

class Question {
  Question({required this.question, required this.right, required this.wrong, required this.explanation, this.station});

  final String question;
  final String right;
  final List<String> wrong;
  final String explanation;

  /// Bei Prüfungsfragen: zu welcher Station die Frage gehört.
  final int? station;

  /// In der Datenbank steht die richtige Antwort vorn, die App mischt.
  List<String> get answers => [right, ...wrong];
}

class Station {
  Station({
    required this.number,
    required this.type,
    required this.xp,
    required this.title,
    required this.place,
    required this.goal,
    required this.minutes,
    required this.isIntro,
    required this.video,
    required this.scene,
    required this.lesson,
    required this.game,
    required this.summary,
    required this.quizShow,
    required this.examShow,
    required this.examReview,
    required this.examPass,
    required this.questions,
  });

  final int number;
  final String type;
  final int xp;
  final String title;
  final String place;
  final String goal;
  final String minutes;
  final bool isIntro;
  final String? video;
  final List<Line> scene;
  final List<Line> lesson;
  final Map<String, dynamic>? game;
  final Line? summary;
  final int? quizShow;
  final int? examShow;
  final int? examReview;
  final int? examPass;
  final List<Question> questions;

  bool get isExam => type == 'exam';

  /// Inhalt für stations.content (englische Schlüssel, wie die App sie liest).
  Map<String, dynamic> toDbContent() => {
    'title': title,
    'number': number,
    'place': place,
    'goal': goal,
    'minutes': minutes,
    if (isIntro) 'kind': 'onboarding',
    'video_key': ?video,
    if (scene.isNotEmpty) 'scene': [for (final l in scene) l.toDb()],
    if (lesson.isNotEmpty) 'lesson': [for (final l in lesson) l.toDb()],
    if (game != null) 'game': gameToDb(game!),
    if (summary != null) 'summary': summary!.toDb(),
    if (quizShow != null) 'quiz': {'show': quizShow},
    if (isExam) 'exam': {'show': examShow, 'review': examReview, 'pass': examPass},
  };
}

/// Mini-Spiele mit eigener Spielmechanik in der App. Andere Spielarten zeigen
/// bis zu ihrem Bau einen Platzhalter. Alle sind reine Daten: Neue Spiele dieser
/// Arten brauchen kein App-Update.
///   * sort     Dinge in Körbe sortieren
///   * order    Dinge in die richtige Reihenfolge bringen
///   * choice   Entscheidungen: Situation, Möglichkeiten, Rückmeldung
///   * coins    Beträge mit Münzen und Scheinen legen (auch Wechselgeld)
///   * pick     Teile auswählen, bis ein Betrag genau stimmt oder das Budget reicht
///   * number   Rechnen: eine Zahl als Antwort
const builtGames = {'sort', 'order', 'choice', 'coins', 'pick', 'number'};

/// Euro-Münzen und -Scheine in Cent für das Spiel „coins“.
const coinValues = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000];

/// Spiel-Daten für stations.content.game (englische Schlüssel).
Map<String, dynamic> gameToDb(Map<String, dynamic> g) {
  final type = g['art'];
  Map<String, dynamic>? line(Object? raw) =>
      raw is Map<String, dynamic> ? {'speaker': raw['wer'], 'text': raw['text'], 'name': ?raw['name']} : null;
  List<Map<String, dynamic>> lines(Object? raw) => [for (final l in (raw as List?) ?? const []) line(l)!];
  List<Map<String, dynamic>> rounds() => ((g['runden'] as List?) ?? const []).cast<Map<String, dynamic>>();
  return {
    'type': type,
    'title': g['titel'],
    'description': g['beschreibung'],
    if (builtGames.contains(type)) ...{
      'task': g['aufgabe'],
      if (type == 'sort' || type == 'order' || type == 'pick')
        'items': [
          for (final d in (g['dinge'] as List).cast<Map<String, dynamic>>())
            {
              'text': d['text'],
              if (type == 'sort') 'basket': d['korb'],
              if (type == 'pick') ...{'price': d['preis'], 'required': d['richtig'] == true},
              'hint': ?d['hinweis'],
            },
        ],
      if (type == 'sort') 'baskets': g['koerbe'],
      if (type == 'order') ...{'from': g['von'], 'to': g['bis']},
      if (type == 'pick') ...{'target': g['betrag'], 'exact': g['modus'] == 'genau'},
      if (type == 'choice')
        'rounds': [
          for (final r in rounds())
            {
              'scene': lines(r['szene']),
              'question': r['frage'],
              'options': [
                for (final o in (r['optionen'] as List).cast<Map<String, dynamic>>())
                  {'text': o['text'], 'good': o['gut'] == true, 'reply': o['antwort']},
              ],
            },
        ],
      if (type == 'coins')
        'rounds': [
          for (final r in rounds()) {'question': r['text'], 'amount': r['betrag']},
        ],
      if (type == 'number')
        'rounds': [
          for (final r in rounds())
            {
              'question': r['frage'],
              'amount': r['antwort'],
              'unit': ?r['einheit'],
              'hint': ?r['tipp'],
              'explanation': r['erklaerung'],
            },
        ],
      'done': ?line(g['geschafft']),
    },
  };
}

/// Spielarten der Tauchgänge (INSELN.md). Bis eine Spielart gebaut ist, zeigt
/// die App das Perlentauchen.
const diveGames = {
  'perlentauchen': 'pearls',
  'schatztruhe': 'treasure_chest',
  'fischschwarm': 'fish_swarm',
  'muscheln': 'shell_count',
};

/// Ankerplatz mit Tauchgang nach einer Station (CLAUDE.md Abschnitt 8).
class Dive {
  Dive({
    required this.after,
    required this.title,
    required this.game,
    required this.questions,
    required this.find,
    required this.wreckScene,
    required this.wreckQuestion,
    this.findImage = 'collectible.wreck_item',
  });

  /// Nummer der Station, nach der der Ankerplatz liegt.
  final int after;
  final String title;
  final String game;
  final int questions;

  /// Fund für die Unterwasser-Sammlung.
  final String find;

  /// Bild des Funds (`fund_bild`), ohne Angabe das allgemeine Fundstück.
  final String findImage;
  final List<Line> wreckScene;
  final Question wreckQuestion;

  Map<String, dynamic> toDbContent(int number) => {
    'title': title,
    'kind': 'dive',
    'number': number,
    'dive': {
      'game': diveGames[game] ?? 'pearls',
      'questions': questions,
      'wreck': {
        'scene': [for (final l in wreckScene) l.toDb()],
        'question': wreckQuestion.question,
        'answers': wreckQuestion.answers,
        'correct_index': 0,
        'explanation': wreckQuestion.explanation,
      },
    },
  };
}

class Island {
  Island({
    required this.file,
    required this.slug,
    required this.title,
    required this.order,
    required this.group,
    required this.access,
    required this.mapX,
    required this.mapY,
    required this.goal,
    required this.fog,
    required this.arrivalVideo,
    required this.arrivalScene,
    required this.badge,
    required this.task,
    required this.prompts,
    required this.stations,
    this.dives = const [],
    this.status = 'entwurf',
  });

  final String file;
  final String slug;
  final String title;
  final int order;
  final int group;
  final String access;
  final double mapX;
  final double mapY;
  final String goal;

  /// Insel liegt im Nebel: noch keine Stationen.
  final bool fog;
  final String? arrivalVideo;
  final List<Line> arrivalScene;
  final String? badge;
  final Map<String, dynamic>? task;
  final List<String> prompts;
  final List<Station> stations;
  final List<Dive> dives;

  /// entwurf, pruefung oder freigegeben (gilt für alles auf der Insel).
  final String status;

  /// Status in der Datenbank (draft, review, published).
  String get dbStatus => contentStatuses[status] ?? 'draft';

  /// Inhalt für islands.content.
  Map<String, dynamic> toDbContent() => {
    'goal': goal,
    'access': access == 'gratis' ? 'free' : 'premium',
    if (arrivalVideo != null || arrivalScene.isNotEmpty)
      'arrival': {
        'video_key': ?arrivalVideo,
        'scene': [for (final l in arrivalScene) l.toDb()],
      },
    'badge': ?badge,
    if (task != null) 'real_life_task': {'title': task!['titel'], 'text': task!['text']},
  };
}

/// Liest alle Inhaltsdateien eines Ordners, sortiert nach Reihenfolge.
List<Island> loadIslands(Directory dir) {
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final islands = [for (final f in files) parseIsland(f.uri.pathSegments.last, f.readAsStringSync())];
  islands.sort((a, b) => a.order.compareTo(b.order));
  return islands;
}

Island parseIsland(String file, String source) {
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(source) as Map<String, dynamic>;
  } on FormatException catch (e) {
    throw ContentException('$file: kein gültiges JSON (${e.message})');
  }
  String text(Map<String, dynamic> m, String key, String where) {
    final value = m[key];
    if (value is! String || value.trim().isEmpty) throw ContentException('$where: "$key" fehlt');
    return value;
  }

  List<Line> lines(Object? raw, String where) => [
    for (final (i, l) in ((raw as List?) ?? const []).indexed)
      Line(
        text(l as Map<String, dynamic>, 'wer', '$where, Zeile ${i + 1}'),
        text(l, 'text', '$where, Zeile ${i + 1}'),
        l['name'] as String?,
        image: l['bild'] as String?,
      ),
  ];

  final karte = json['karte'] as Map<String, dynamic>?;
  final ankunft = json['ankunft'] as Map<String, dynamic>?;
  final stations = <Station>[];
  for (final raw in (json['stationen'] as List?) ?? const []) {
    final s = raw as Map<String, dynamic>;
    final where = '$file, Station ${s['nr']}';
    final pruefung = s['pruefung'] as Map<String, dynamic>?;
    final abschluss = s['abschluss'] as Map<String, dynamic>?;
    stations.add(
      Station(
        number: s['nr'] as int,
        type: text(s, 'typ', where),
        xp: s['seemeilen'] as int? ?? 0,
        title: text(s, 'titel', where),
        place: text(s, 'ort', where),
        goal: text(s, 'lernziel', where),
        minutes: text(s, 'dauer', where),
        isIntro: s['art'] == 'intro',
        video: s['film'] as String?,
        scene: lines(s['szene'], '$where, Szene'),
        lesson: lines(s['erklaerung'], '$where, Erklärung'),
        game: s['spiel'] as Map<String, dynamic>?,
        summary: abschluss == null ? null : lines([abschluss], '$where, Abschluss').single,
        quizShow: s['quiz_anzahl'] as int?,
        examShow: pruefung?['anzahl'] as int?,
        examReview: pruefung?['rueckblick'] as int?,
        examPass: pruefung?['bestehen'] as int?,
        questions: [
          for (final (i, q) in ((s['fragen'] as List?) ?? const []).indexed)
            Question(
              question: text(q as Map<String, dynamic>, 'frage', '$where, Frage ${i + 1}'),
              right: text(q, 'richtig', '$where, Frage ${i + 1}'),
              wrong: [for (final w in (q['falsch'] as List? ?? const [])) w as String],
              explanation: text(q, 'erklaerung', '$where, Frage ${i + 1}'),
              station: q['station'] as int?,
            ),
        ],
      ),
    );
  }

  return Island(
    file: file,
    slug: text(json, 'slug', file),
    title: text(json, 'titel', file),
    order: json['reihenfolge'] as int,
    group: json['gruppe'] as int,
    access: text(json, 'zugang', file),
    mapX: (karte?['x'] as num?)?.toDouble() ?? 0.5,
    mapY: (karte?['y'] as num?)?.toDouble() ?? 0.5,
    goal: text(json, 'lernziel', file),
    fog: json['nebel'] == true,
    arrivalVideo: ankunft?['film'] as String?,
    arrivalScene: lines(ankunft?['szene'], '$file, Ankunft'),
    badge: json['orden'] as String?,
    task: json['auftrag'] as Map<String, dynamic>?,
    prompts: [for (final p in (json['kombuesen_fragen'] as List? ?? const [])) p as String],
    stations: stations,
    status: json['status'] as String? ?? 'entwurf',
    dives: [
      for (final raw in (json['tauchgaenge'] as List?) ?? const [])
        () {
          final d = raw as Map<String, dynamic>;
          final where = '$file, Tauchgang nach Station ${d['nach']}';
          final wrack = d['wrack'] as Map<String, dynamic>? ?? const {};
          return Dive(
            after: d['nach'] as int,
            title: text(d, 'titel', where),
            game: text(d, 'spiel', where),
            questions: d['fragen'] as int? ?? 4,
            find: text(d, 'fund', where),
            findImage: d['fund_bild'] as String? ?? 'collectible.wreck_item',
            wreckScene: lines(wrack['szene'], '$where, Wrack'),
            wreckQuestion: Question(
              question: text(wrack, 'frage', '$where, Wrack'),
              right: text(wrack, 'richtig', '$where, Wrack'),
              wrong: [for (final w in (wrack['falsch'] as List? ?? const [])) w as String],
              explanation: text(wrack, 'erklaerung', '$where, Wrack'),
            ),
          );
        }(),
    ],
  );
}

/// Prüft die Regeln aus CLAUDE.md und INSELN.md. Gibt alle Probleme zurück
/// (leere Liste = alles in Ordnung).
List<String> validateIslands(List<Island> islands, {required Set<String> knownAssetKeys}) {
  final problems = <String>[];
  void check(bool ok, String message) {
    if (!ok) problems.add(message);
  }

  final slugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
  final orders = [for (final i in islands) i.order];
  check(
    orders.toSet().length == orders.length && orders.every((o) => o >= 1),
    'Reihenfolge der Inseln ist doppelt oder ungültig: $orders',
  );
  check(islands.map((i) => i.slug).toSet().length == islands.length, 'Ein Slug kommt doppelt vor');

  final statuses = contentStatuses.keys.join(', ');
  for (final (index, island) in islands.indexed) {
    final w = island.file;
    check(contentStatuses.containsKey(island.status), '$w: "status" muss $statuses sein');
    if (island.status == 'freigegeben') {
      final before = islands.take(index).where((i) => i.status != 'freigegeben').map((i) => i.slug);
      check(before.isEmpty, '$w: freigegeben, aber diese Inseln davor noch nicht: ${before.join(', ')}');
    }
    check(slugPattern.hasMatch(island.slug), '$w: Slug "${island.slug}" ist ungültig');
    check(island.title.length <= 60, '$w: Titel ist länger als 60 Zeichen');
    check({'gratis', 'premium'}.contains(island.access), '$w: Zugang muss gratis oder premium sein');
    check(
      island.mapX >= 0 && island.mapX <= 1 && island.mapY >= 0 && island.mapY <= 1,
      '$w: Kartenposition liegt außerhalb 0 bis 1',
    );
    for (final line in island.arrivalScene) {
      check(knownAssetKeys.contains('character.${line.speaker}'), '$w, Ankunft: unbekannte Figur "${line.speaker}"');
    }
    if (island.arrivalVideo != null) {
      check(knownAssetKeys.contains(island.arrivalVideo), '$w: Film ${island.arrivalVideo} fehlt im Asset-Manifest');
    }

    if (island.fog) {
      check(island.stations.isEmpty, '$w: Insel im Nebel darf noch keine Stationen haben');
      check(island.status == 'entwurf', '$w: Insel im Nebel bleibt Entwurf');
      continue;
    }
    check(island.stations.isNotEmpty, '$w: Insel ohne Stationen muss "nebel": true haben');
    check(island.badge != null && island.badge!.trim().length >= 2, '$w: "orden" fehlt');
    check(knownAssetKeys.contains('badge.${island.slug}'), '$w: Bild badge.${island.slug} fehlt im Asset-Manifest');

    final numbers = [for (final s in island.stations) s.number];
    check(
      numbers.length == numbers.toSet().length && numbers.every((n) => n >= 1 && n <= numbers.length),
      '$w: Stationsnummern müssen 1 bis ${numbers.length} sein: $numbers',
    );
    final exams = island.stations.where((s) => s.isExam).toList();
    check(exams.length == 1, '$w: genau eine Abschlussprüfung nötig');
    check(island.stations.last.isExam, '$w: die Abschlussprüfung muss die letzte Station sein');

    final regular = island.stations.where((s) => !s.isExam && !s.isIntro).map((s) => s.number).toSet();

    for (final s in island.stations) {
      final sw = '$w, Station ${s.number}';
      check(stationTypes.contains(s.type), '$sw: unbekannter Typ "${s.type}"');
      check(s.xp >= 0, '$sw: Seemeilen dürfen nicht negativ sein');
      if (s.video != null) check(knownAssetKeys.contains(s.video), '$sw: Film ${s.video} fehlt im Asset-Manifest');
      for (final line in [...s.scene, ...s.lesson, ?s.summary]) {
        check(knownAssetKeys.contains('character.${line.speaker}'), '$sw: unbekannte Figur "${line.speaker}"');
      }
      // Bildergeschichte: Bilder nur in der Erklärung, die erste Zeile braucht eins.
      for (final line in [...s.scene, ?s.summary]) {
        check(line.image == null, '$sw: "bild" gibt es nur in der Erklärung');
      }
      if (s.lesson.any((l) => l.image != null)) {
        check(s.lesson.first.image != null, '$sw: die erste Zeile der Erklärung braucht ein "bild"');
      }
      for (final line in s.lesson) {
        if (line.image case final image?) {
          check(knownAssetKeys.contains(image), '$sw: Bild $image fehlt im Asset-Manifest');
        }
      }

      for (final (i, q) in s.questions.indexed) {
        final qw = '$sw, Frage ${i + 1}';
        check(q.wrong.length == 2, '$qw: genau 2 falsche Antworten nötig (3 Antworten insgesamt)');
        check(q.answers.map((a) => a.trim()).toSet().length == q.answers.length, '$qw: Antworten doppelt');
        check(q.answers.every((a) => a.trim().isNotEmpty), '$qw: leere Antwort');
      }
      final texts = s.questions.map((q) => q.question.trim()).toList();
      check(texts.toSet().length == texts.length, '$sw: eine Frage kommt doppelt vor');

      final game = s.game;
      if (game != null && builtGames.contains(game['art'])) {
        problems.addAll(validateGame(game, sw, knownAssetKeys: knownAssetKeys));
      }

      if (s.isIntro) {
        check(s.questions.isEmpty, '$sw: das Intro hat keine Fragen');
        check(s.number == 1 && island.order == 1, '$sw: das Intro ist Station 1 der ersten Insel');
      } else if (s.isExam) {
        final show = s.examShow, review = s.examReview, pass = s.examPass;
        check(show != null && review != null && pass != null, '$sw: Prüfung braucht anzahl, rueckblick, bestehen');
        if (show == null || review == null || pass == null) continue;
        check(pass <= show + review, '$sw: Bestehensgrenze höher als die Zahl der Fragen');
        check(
          s.questions.length >= 2 * show,
          '$sw: Pool (${s.questions.length}) muss mindestens doppelt so groß sein wie $show',
        );
        check(island.order == 1 ? review == 0 : review > 0, '$sw: Rückblick-Fragen erst ab Insel 2');
        check(
          s.questions.every((q) => q.station != null && regular.contains(q.station)),
          '$sw: jede Prüfungsfrage braucht eine gültige "station"',
        );
        final covered = s.questions.map((q) => q.station).toSet();
        check(
          covered.containsAll(regular),
          '$sw: Prüfung deckt nicht alle Stationen ab, fehlt: ${regular.difference(covered)}',
        );
        check(show >= regular.length, '$sw: zu wenige Prüfungsfragen, um jede Station einmal abzufragen');
      } else {
        final show = s.quizShow;
        check(show != null && show > 0, '$sw: "quiz_anzahl" fehlt');
        if (show == null) continue;
        check(
          s.questions.length >= 2 * show,
          '$sw: Pool (${s.questions.length}) muss mindestens doppelt so groß sein wie $show',
        );
        check(s.questions.length >= minCheckPool, '$sw: mindestens $minCheckPool Fragen pro Station');
        check(
          s.scene.isNotEmpty && s.lesson.isNotEmpty && s.summary != null,
          '$sw: Szene, Erklärung und Abschluss nötig',
        );
      }
    }

    // Ankerplätze: nach Station 2, 4 und 6 (Schatzinsel ohne), Fragen aus den Stationen davor.
    final afters = [for (final d in island.dives) d.after];
    check(afters.toSet().length == afters.length, '$w: zwei Tauchgänge nach derselben Station');
    var previous = 0;
    for (final d in island.dives) {
      final dw = '$w, Tauchgang nach Station ${d.after}';
      check(regular.contains(d.after), '$dw: muss nach einer normalen Station liegen');
      check(diveGames.containsKey(d.game), '$dw: unbekanntes Spiel "${d.game}"');
      check(d.questions >= 3 && d.questions <= 4, '$dw: 3 bis 4 Fragen');
      check(d.find.trim().length >= 2 && d.find.length <= 60, '$dw: Fund braucht einen Namen (bis 60 Zeichen)');
      check(knownAssetKeys.contains(d.findImage), '$dw: Bild ${d.findImage} fehlt im Asset-Manifest');
      final pool = island.stations
          .where((s) => !s.isExam && s.number > previous && s.number <= d.after)
          .expand((s) => s.questions)
          .length;
      check(pool >= d.questions, '$dw: zu wenige Fragen in den Stationen davor ($pool)');
      check(d.wreckQuestion.wrong.length == 2, '$dw: Wrack-Aufgabe braucht genau 2 falsche Antworten');
      for (final line in d.wreckScene) {
        check(knownAssetKeys.contains('character.${line.speaker}'), '$dw: unbekannte Figur "${line.speaker}"');
      }
      previous = d.after;
    }
  }
  return problems;
}

/// Prüft die Daten eines Mini-Spiels. Mit [knownAssetKeys] auch die Figuren in Szenen.
List<String> validateGame(Map<String, dynamic> game, String where, {Set<String>? knownAssetKeys}) {
  final problems = <String>[];
  void check(bool ok, String message) {
    if (!ok) problems.add(message);
  }

  bool text(Object? value) => value is String && value.trim().isNotEmpty;
  void speaker(Object? raw, String w) {
    if (raw is! Map<String, dynamic>) {
      problems.add('$w: Zeile fehlt');
      return;
    }
    check(text(raw['text']), '$w: Text fehlt');
    if (knownAssetKeys != null) {
      check(knownAssetKeys.contains('character.${raw['wer']}'), '$w: unbekannte Figur "${raw['wer']}"');
    }
  }

  final w = '$where, Spiel';
  final type = game['art'];
  check(text(game['aufgabe']), '$w: "aufgabe" fehlt');
  if (game['geschafft'] is Map<String, dynamic>) {
    speaker(game['geschafft'], '$w, "geschafft"');
  } else {
    problems.add('$w: "geschafft" fehlt');
  }
  final items = (game['dinge'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final rounds = (game['runden'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

  switch (type) {
    case 'sort':
      check(items.every((d) => text(d['text'])), '$w: jedes Ding braucht einen Text');
      final baskets = (game['koerbe'] as List?) ?? const [];
      check(baskets.length >= 2 && baskets.length <= 4, '$w: 2 bis 4 Körbe');
      check(items.length >= 4 && items.length <= 10, '$w: 4 bis 10 Dinge zum Sortieren');
      for (final d in items) {
        final basket = d['korb'];
        check(
          basket == null || (basket is int && basket >= 0 && basket < baskets.length),
          '$w: "${d['text']}" hat einen unbekannten Korb',
        );
        check(basket != null || d['hinweis'] != null, '$w: "${d['text']}" passt überall hin und braucht einen Hinweis');
      }
    case 'order':
      check(items.every((d) => text(d['text'])), '$w: jedes Ding braucht einen Text');
      check(items.length >= 3 && items.length <= 7, '$w: 3 bis 7 Dinge in der Reihenfolge');
      check(game['von'] is String && game['bis'] is String, '$w: "von" und "bis" fehlen');
    case 'choice':
      check(rounds.length >= 2 && rounds.length <= 8, '$w: 2 bis 8 Runden');
      for (final (i, r) in rounds.indexed) {
        final rw = '$w, Runde ${i + 1}';
        check(text(r['frage']), '$rw: "frage" fehlt');
        for (final (k, l) in ((r['szene'] as List?) ?? const []).indexed) {
          speaker(l, '$rw, Szene ${k + 1}');
        }
        final options = (r['optionen'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        check(options.length >= 2 && options.length <= 4, '$rw: 2 bis 4 Möglichkeiten');
        check(options.any((o) => o['gut'] == true), '$rw: mindestens eine gute Möglichkeit');
        check(
          options.every((o) => text(o['text']) && text(o['antwort'])),
          '$rw: jede Möglichkeit braucht Text und Antwort',
        );
      }
    case 'coins':
      check(rounds.length >= 2 && rounds.length <= 6, '$w: 2 bis 6 Runden');
      for (final (i, r) in rounds.indexed) {
        final amount = r['betrag'];
        check(text(r['text']), '$w, Runde ${i + 1}: "text" fehlt');
        check(amount is int && amount > 0 && amount <= 5000, '$w, Runde ${i + 1}: Betrag 1 Cent bis 50 Euro');
      }
    case 'pick':
      final target = game['betrag'];
      check(game['modus'] == 'genau' || game['modus'] == 'hoechstens', '$w: "modus" muss genau oder hoechstens sein');
      check(target is int && target > 0, '$w: "betrag" fehlt');
      check(items.length >= 3 && items.length <= 10, '$w: 3 bis 10 Dinge');
      check(
        items.every((d) => text(d['text']) && d['preis'] is int && (d['preis'] as int) > 0),
        '$w: jedes Ding braucht Text und Preis',
      );
      final required = items.where((d) => d['richtig'] == true).toList();
      check(required.isNotEmpty, '$w: mindestens ein richtiges Ding');
      check(
        items.where((d) => d['richtig'] != true).every((d) => text(d['hinweis'])),
        '$w: falsche Dinge brauchen einen Hinweis',
      );
      if (target is int && required.isNotEmpty) {
        final sum = required.fold<int>(0, (s, d) => s + ((d['preis'] as int?) ?? 0));
        if (game['modus'] == 'genau') {
          check(sum == target, '$w: die richtigen Dinge ergeben $sum statt $target');
        } else {
          check(sum <= target, '$w: die richtigen Dinge kosten $sum, mehr als $target');
          check(required.every((d) => text(d['hinweis'])), '$w: richtige Dinge brauchen einen Hinweis');
        }
      }
    case 'number':
      check(rounds.isNotEmpty && rounds.length <= 6, '$w: 1 bis 6 Runden');
      for (final (i, r) in rounds.indexed) {
        final rw = '$w, Runde ${i + 1}';
        check(text(r['frage']) && text(r['erklaerung']), '$rw: "frage" und "erklaerung" nötig');
        check(r['antwort'] is int && (r['antwort'] as int) >= 0, '$rw: "antwort" muss eine ganze Zahl sein');
      }
    default:
      problems.add('$w: unbekannte Spielart "$type"');
  }
  return problems;
}

// -----------------------------------------------------------------------------
// Begegnungen auf See (content/begegnungen.json)
// -----------------------------------------------------------------------------

/// Arten von Begegnungen wie in der Datenbank (encounters.type).
const encounterTypes = {'taleron', 'haendlerschiff', 'fischerboot', 'angeberschiff', 'tala_vergisst'};

class Encounter {
  Encounter({
    required this.slug,
    required this.type,
    required this.title,
    required this.assetKey,
    required this.questionCount,
    required this.xp,
    required this.afterIsland,
    required this.firstScene,
    required this.scene,
    required this.right,
    required this.wrong,
    required this.success,
    this.status = 'entwurf',
  });

  final String slug;
  final String type;
  final String title;
  final String assetKey;
  final int questionCount;
  final int xp;

  /// Slug der Insel, nach deren Abschluss die Begegnung auftaucht (null = sofort).
  final String? afterIsland;
  final List<Line> firstScene;
  final List<Line> scene;
  final Line right;
  final Line wrong;
  final Line success;

  /// entwurf, pruefung oder freigegeben.
  final String status;

  String get dbStatus => contentStatuses[status] ?? 'draft';

  List<Line> get allLines => [...firstScene, ...scene, right, wrong, success];

  /// Inhalt für encounters.content.
  Map<String, dynamic> toDbContent() => {
    'first_scene': [for (final l in firstScene) l.toDb()],
    'scene': [for (final l in scene) l.toDb()],
    'right': right.toDb(),
    'wrong': wrong.toDb(),
    'success': success.toDb(),
  };
}

List<Encounter> parseEncounters(String file, String source) {
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(source) as Map<String, dynamic>;
  } on FormatException catch (e) {
    throw ContentException('$file: kein gültiges JSON (${e.message})');
  }
  String text(Map<String, dynamic> m, String key, String where) {
    final value = m[key];
    if (value is! String || value.trim().isEmpty) throw ContentException('$where: "$key" fehlt');
    return value;
  }

  Line line(Object? raw, String where) {
    if (raw is! Map<String, dynamic>) throw ContentException('$where fehlt');
    return Line(text(raw, 'wer', where), text(raw, 'text', where), raw['name'] as String?);
  }

  List<Line> lines(Object? raw, String where) => [
    for (final (i, l) in ((raw as List?) ?? const []).indexed) line(l, '$where, Zeile ${i + 1}'),
  ];

  return [
    for (final raw in (json['begegnungen'] as List?) ?? const [])
      () {
        final e = raw as Map<String, dynamic>;
        final where = '$file, Begegnung ${e['slug']}';
        return Encounter(
          slug: text(e, 'slug', where),
          type: text(e, 'art', where),
          title: text(e, 'titel', where),
          assetKey: text(e, 'bild', where),
          questionCount: e['fragen'] as int? ?? 3,
          xp: e['seemeilen'] as int? ?? 20,
          afterIsland: e['ab_insel'] as String?,
          firstScene: lines(e['erste_begegnung'], '$where, erste Begegnung'),
          scene: lines(e['szene'], '$where, Szene'),
          right: line(e['richtig'], '$where, "richtig"'),
          wrong: line(e['falsch'], '$where, "falsch"'),
          success: line(e['geschafft'], '$where, "geschafft"'),
          status: e['status'] as String? ?? 'entwurf',
        );
      }(),
  ];
}

/// Prüft die Begegnungen (leere Liste = alles in Ordnung).
List<String> validateEncounters(
  List<Encounter> encounters, {
  required List<Island> islands,
  required Set<String> knownAssetKeys,
}) {
  final problems = <String>[];
  void check(bool ok, String message) {
    if (!ok) problems.add(message);
  }

  final slugs = islands.map((i) => i.slug).toSet();
  check(encounters.map((e) => e.slug).toSet().length == encounters.length, 'Begegnungen: ein Slug kommt doppelt vor');
  for (final e in encounters) {
    final w = 'Begegnung ${e.slug}';
    check(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(e.slug), '$w: Slug ist ungültig');
    check(contentStatuses.containsKey(e.status), '$w: "status" muss ${contentStatuses.keys.join(', ')} sein');
    check(encounterTypes.contains(e.type), '$w: unbekannte Art "${e.type}"');
    check(e.title.length <= 60, '$w: Titel ist länger als 60 Zeichen');
    check(knownAssetKeys.contains(e.assetKey), '$w: Bild ${e.assetKey} fehlt im Asset-Manifest');
    check(e.questionCount >= 3 && e.questionCount <= 5, '$w: 3 bis 5 Fragen');
    check(e.xp >= 0 && e.xp <= 200, '$w: Seemeilen 0 bis 200');
    check(e.afterIsland == null || slugs.contains(e.afterIsland), '$w: unbekannte Insel "${e.afterIsland}"');
    check(e.firstScene.isNotEmpty && e.scene.isNotEmpty, '$w: erste Begegnung und Szene nötig');
    for (final l in e.allLines) {
      check(knownAssetKeys.contains('character.${l.speaker}'), '$w: unbekannte Figur "${l.speaker}"');
    }
  }
  return problems;
}

// -----------------------------------------------------------------------------
// SQL
// -----------------------------------------------------------------------------

String _lit(String value) => "'${value.replaceAll("'", "''")}'";
String _json(Object value) => '${_lit(jsonEncode(value))}::jsonb';
String _id(String name) => "md5(${_lit('taleria:$name')})::uuid";

/// Wohin die erzeugten Inhalte gehen.
enum SeedTarget {
  /// supabase/seed.sql: Inhalte plus Inhalts-Vorschau und Test-Abo.
  test,

  /// supabase/inhalte_live.sql: nur Inhalte, ohne Test-Einstellungen.
  live,
}

/// Erzeugt die SQL-Datei mit allen Inhalten. Der Status kommt aus den Dateien
/// („status“ je Insel und Begegnung, Standard „entwurf“). Eine Insel wird erst
/// am Ende ihres Blocks veröffentlicht, damit ihre Pflichtstationen schon da
/// sind (die Datenbank verbietet neue Pflichtstationen an veröffentlichten Inseln).
/// Die Datei darf beliebig oft eingespielt werden.
String buildSeedSql(
  List<Island> islands, {
  List<Encounter> encounters = const [],
  int stage = 1,
  SeedTarget target = SeedTarget.test,
}) {
  final b = StringBuffer();
  if (target == SeedTarget.test) {
    b
      ..writeln('-- Seed-Daten für die TESTUMGEBUNG. Nie in die Live-Datenbank einspielen.')
      ..writeln('-- Automatisch erzeugt aus content/stufe1/*.json mit: dart run tool/build_seed.dart')
      ..writeln('-- Nicht von Hand ändern, sondern die Inhaltsdateien bearbeiten und neu erzeugen.')
      ..writeln()
      ..writeln('begin;')
      ..writeln()
      ..writeln('-- Inhalts-Vorschau: Kinder sehen in der Testumgebung auch Entwürfe.')
      ..writeln("insert into public.app_settings (key, value) values ('content_preview', 'true'::jsonb)")
      ..writeln('on conflict (key) do update set value = excluded.value;')
      ..writeln()
      ..writeln('-- Test-Abo: Eltern können das Abo im Leuchtturm testweise ein- und ausschalten.')
      ..writeln("insert into public.app_settings (key, value) values ('test_purchases', 'true'::jsonb)")
      ..writeln('on conflict (key) do update set value = excluded.value;')
      ..writeln();
  } else {
    b
      ..writeln('-- Inhalte für die LIVE-Datenbank (geprüfter Import, CLAUDE.md Abschnitt 10).')
      ..writeln('-- Automatisch erzeugt aus content/stufe1/*.json mit: dart run tool/build_seed.dart')
      ..writeln('-- Nicht von Hand ändern, sondern die Inhaltsdateien bearbeiten und neu erzeugen.')
      ..writeln('-- Kinder sehen nur Inhalte mit "status": "freigegeben". Keine Test-Einstellungen.')
      ..writeln('-- Darf beliebig oft eingespielt werden. Veröffentlichte Inhalte schützt die Datenbank:')
      ..writeln('-- Pflichtstationen und Prüfungsfragen lassen sich korrigieren, aber nicht entfernen.')
      ..writeln()
      ..writeln('begin;')
      ..writeln();
  }

  for (final island in islands) {
    final iid = _id('stage$stage/${island.slug}');
    final status = _lit(island.dbStatus);
    b
      ..writeln('-- ${island.order}. ${island.title}${island.fog ? ' (Nebel)' : ''}, Status: ${island.status}')
      ..writeln(
        'insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)',
      )
      ..writeln(
        'values ($iid, ${_lit(island.slug)}, $stage, ${island.group}, ${island.order}, ${island.mapX}, ${island.mapY}, '
        "'main', ${_lit(island.title)}, ${_json(island.toDbContent())})",
      )
      ..writeln('on conflict (id) do update set')
      ..writeln('  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,')
      ..writeln('  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;')
      ..writeln();

    final questionIds = <String>[];
    for (final s in island.stations) {
      final sid = _id('stage$stage/${island.slug}/station${s.number}');
      b
        ..writeln(
          'insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)',
        )
        ..writeln(
          "values ($sid, $iid, ${s.number * 10}, ${_lit(s.type)}, true, ${s.xp}, ${_json(s.toDbContent())}, $status)",
        )
        ..writeln('on conflict (id) do update set')
        ..writeln('  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,')
        ..writeln('  content = excluded.content, status = excluded.status;');
      for (final (i, q) in s.questions.indexed) {
        final qname = 'stage$stage/${island.slug}/station${s.number}/q${i + 1}';
        questionIds.add(_id(qname));
        b
          ..writeln(
            'insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)',
          )
          ..writeln(
            'values (${_id(qname)}, $sid, ${_lit(q.question)}, ${_json(q.answers)}, 0, ${_lit(q.explanation)}, '
            "${q.station ?? 'null'}, $status)",
          )
          ..writeln('on conflict (id) do update set')
          ..writeln(
            '  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,',
          )
          ..writeln(
            '  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status;',
          );
      }
      b.writeln();
    }

    // Ankerplätze zwischen den Stationen (Reihenfolge: Station × 10, Ankerplatz + 5).
    for (final (k, d) in island.dives.indexed) {
      final did = _id('stage$stage/${island.slug}/dive${k + 1}');
      b
        ..writeln('-- Ankerplatz ${k + 1}: ${d.title}')
        ..writeln(
          'insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)',
        )
        ..writeln(
          "values ($did, $iid, ${d.after * 10 + 5}, 'review_stop', true, $diveXp, ${_json(d.toDbContent(k + 1))}, $status)",
        )
        ..writeln('on conflict (id) do update set')
        ..writeln('  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,')
        ..writeln('  status = excluded.status;')
        ..writeln('insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)')
        ..writeln(
          "values (${_id('stage$stage/${island.slug}/dive${k + 1}/find')}, ${_lit('${island.slug}-fund-${k + 1}')}, "
          "'wreck_item', ${_lit(d.find)}, ${_lit(d.findImage)}, $did, ${island.order * 10 + k + 1}, $status)",
        )
        ..writeln('on conflict (id) do update set')
        ..writeln('  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,')
        ..writeln('  sort_order = excluded.sort_order,')
        ..writeln('  status = excluded.status;')
        ..writeln();
    }

    // Fragen, die aus der Datei entfernt wurden, auch aus der Datenbank löschen.
    if (island.stations.isNotEmpty) {
      b
        ..writeln('delete from public.quiz_questions q using public.stations s')
        ..writeln('where q.station_id = s.id and s.island_id = $iid')
        ..writeln('  and q.id not in (${questionIds.join(', ')});')
        ..writeln();
    }

    if (island.badge != null) {
      b
        ..writeln('insert into public.badges (id, slug, kind, island_id, title, asset_key, sort_order, status)')
        ..writeln(
          "values (${_id('stage$stage/${island.slug}/badge')}, ${_lit(island.slug)}, 'island', $iid, "
          "${_lit(island.badge!)}, ${_lit('badge.${island.slug}')}, ${island.order}, $status)",
        )
        ..writeln('on conflict (id) do update set')
        ..writeln('  title = excluded.title, asset_key = excluded.asset_key, sort_order = excluded.sort_order,')
        ..writeln('  status = excluded.status;')
        ..writeln();
    }

    for (final (i, p) in island.prompts.indexed) {
      b
        ..writeln('insert into public.conversation_prompts (id, island_id, text, status)')
        ..writeln("values (${_id('stage$stage/${island.slug}/prompt${i + 1}')}, $iid, ${_lit(p)}, $status)")
        ..writeln('on conflict (id) do update set text = excluded.text, status = excluded.status;');
    }
    if (island.prompts.isNotEmpty) b.writeln();

    b
      ..writeln('-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.')
      ..writeln('update public.islands set status = $status where id = $iid and status <> $status;')
      ..writeln();
  }

  b
    ..writeln('-- Orden für Inseln, die schon vor ihrem Orden abgeschlossen waren.')
    ..writeln('insert into public.child_badges (child_id, badge_id)')
    ..writeln(
      'select c.child_id, b.id from public.island_completions c join public.badges b on b.island_id = c.island_id',
    )
    ..writeln('on conflict on constraint child_badges_once do nothing;')
    ..writeln();

  for (final e in encounters) {
    final after = e.afterIsland == null ? 'null' : _id('stage$stage/${e.afterIsland}');
    b
      ..writeln('-- Begegnung: ${e.title}, Status: ${e.status}')
      ..writeln(
        'insert into public.encounters (id, slug, type, title, asset_key, question_count, xp_reward, after_island_id, content, status)',
      )
      ..writeln(
        "values (${_id('encounter/${e.slug}')}, ${_lit(e.slug)}, ${_lit(e.type)}, ${_lit(e.title)}, ${_lit(e.assetKey)}, "
        "${e.questionCount}, ${e.xp}, $after, ${_json(e.toDbContent())}, ${_lit(e.dbStatus)})",
      )
      ..writeln('on conflict (id) do update set')
      ..writeln('  type = excluded.type, title = excluded.title, asset_key = excluded.asset_key,')
      ..writeln('  question_count = excluded.question_count, xp_reward = excluded.xp_reward,')
      ..writeln('  after_island_id = excluded.after_island_id, content = excluded.content, status = excluded.status;')
      ..writeln();
  }

  b.writeln('commit;');
  return b.toString();
}
