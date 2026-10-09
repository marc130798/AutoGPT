/// Inhalte der Inseln als Dateien (content/stufe1/*.json) und ihre Prüfung.
///
/// Die Dateien sind die Quelle für die Seed-Daten der Testumgebung. Sie haben
/// deutsche Feldnamen, damit Marc sie lesen und ändern kann. Daraus erzeugt
/// tool/build_seed.dart die Datei supabase/seed.sql.
library;

import 'dart:convert';
import 'dart:io';

/// Stationstypen wie in der Datenbank (stations.type).
const stationTypes = {'video', 'quiz', 'game', 'practice', 'review_stop', 'exam'};

/// Mindestgröße eines Stations-Check-Pools (CLAUDE.md, Abschnitt 11).
const minCheckPool = 6;

class ContentException implements Exception {
  ContentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class Line {
  Line(this.speaker, this.text, this.name);

  final String speaker;
  final String text;
  final String? name;

  Map<String, dynamic> toDb() => {'speaker': speaker, 'text': text, 'name': ?name};
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
    'place': place,
    'goal': goal,
    'minutes': minutes,
    if (isIntro) 'kind': 'onboarding',
    'video_key': ?video,
    if (scene.isNotEmpty) 'scene': [for (final l in scene) l.toDb()],
    if (lesson.isNotEmpty) 'lesson': [for (final l in lesson) l.toDb()],
    if (game != null) 'game': {'type': game!['art'], 'title': game!['titel'], 'description': game!['beschreibung']},
    if (summary != null) 'summary': summary!.toDb(),
    if (quizShow != null) 'quiz': {'show': quizShow},
    if (isExam) 'exam': {'show': examShow, 'review': examReview, 'pass': examPass},
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

  for (final island in islands) {
    final w = island.file;
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
      continue;
    }
    check(island.stations.isNotEmpty, '$w: Insel ohne Stationen muss "nebel": true haben');

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

      for (final (i, q) in s.questions.indexed) {
        final qw = '$sw, Frage ${i + 1}';
        check(q.wrong.length == 2, '$qw: genau 2 falsche Antworten nötig (3 Antworten insgesamt)');
        check(q.answers.map((a) => a.trim()).toSet().length == q.answers.length, '$qw: Antworten doppelt');
        check(q.answers.every((a) => a.trim().isNotEmpty), '$qw: leere Antwort');
      }
      final texts = s.questions.map((q) => q.question.trim()).toList();
      check(texts.toSet().length == texts.length, '$sw: eine Frage kommt doppelt vor');

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
  }
  return problems;
}

// -----------------------------------------------------------------------------
// SQL
// -----------------------------------------------------------------------------

String _lit(String value) => "'${value.replaceAll("'", "''")}'";
String _json(Object value) => '${_lit(jsonEncode(value))}::jsonb';
String _id(String name) => "md5(${_lit('taleria:$name')})::uuid";

/// Erzeugt supabase/seed.sql. Alle Inhalte sind Entwürfe (`draft`), die
/// Testumgebung zeigt sie über die Inhalts-Vorschau.
String buildSeedSql(List<Island> islands, {int stage = 1}) {
  final b = StringBuffer()
    ..writeln('-- Seed-Daten für die TESTUMGEBUNG. Nie in die Live-Datenbank einspielen.')
    ..writeln('-- Automatisch erzeugt aus content/stufe1/*.json mit: dart run tool/build_seed.dart')
    ..writeln('-- Nicht von Hand ändern, sondern die Inhaltsdateien bearbeiten und neu erzeugen.')
    ..writeln()
    ..writeln('begin;')
    ..writeln()
    ..writeln('-- Inhalts-Vorschau: Kinder sehen in der Testumgebung auch Entwürfe.')
    ..writeln("insert into public.app_settings (key, value) values ('content_preview', 'true'::jsonb)")
    ..writeln('on conflict (key) do update set value = excluded.value;')
    ..writeln();

  for (final island in islands) {
    final iid = _id('stage$stage/${island.slug}');
    b
      ..writeln('-- ${island.order}. ${island.title}${island.fog ? ' (Nebel)' : ''}')
      ..writeln(
        'insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)',
      )
      ..writeln(
        'values ($iid, ${_lit(island.slug)}, $stage, ${island.group}, ${island.order}, ${island.mapX}, ${island.mapY}, '
        "'main', ${_lit(island.title)}, 'draft', ${_json(island.toDbContent())})",
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
          "values ($sid, $iid, ${s.number}, ${_lit(s.type)}, true, ${s.xp}, ${_json(s.toDbContent())}, 'draft')",
        )
        ..writeln('on conflict (id) do update set')
        ..writeln('  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,')
        ..writeln('  content = excluded.content;');
      for (final (i, q) in s.questions.indexed) {
        final qname = 'stage$stage/${island.slug}/station${s.number}/q${i + 1}';
        questionIds.add(_id(qname));
        b
          ..writeln(
            'insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)',
          )
          ..writeln(
            'values (${_id(qname)}, $sid, ${_lit(q.question)}, ${_json(q.answers)}, 0, ${_lit(q.explanation)}, '
            "${q.station ?? 'null'}, 'draft')",
          )
          ..writeln('on conflict (id) do update set')
          ..writeln(
            '  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,',
          )
          ..writeln('  explanation = excluded.explanation, covers_station = excluded.covers_station;');
      }
      b.writeln();
    }

    // Fragen, die aus der Datei entfernt wurden, auch aus der Datenbank löschen.
    if (island.stations.isNotEmpty) {
      b
        ..writeln('delete from public.quiz_questions q using public.stations s')
        ..writeln('where q.station_id = s.id and s.island_id = $iid')
        ..writeln('  and q.id not in (${questionIds.join(', ')});')
        ..writeln();
    }

    for (final (i, p) in island.prompts.indexed) {
      b
        ..writeln('insert into public.conversation_prompts (id, island_id, text, status)')
        ..writeln("values (${_id('stage$stage/${island.slug}/prompt${i + 1}')}, $iid, ${_lit(p)}, 'draft')")
        ..writeln('on conflict (id) do update set text = excluded.text;');
    }
    if (island.prompts.isNotEmpty) b.writeln();
  }

  b.writeln('commit;');
  return b.toString();
}
