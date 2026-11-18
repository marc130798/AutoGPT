/// Inhalte der Inseln als Dateien (content/stufe1/*.json) und ihre Prüfung.
///
/// Die Dateien sind die einzige Quelle der Inhalte. Sie haben deutsche
/// Feldnamen, damit Marc sie lesen und ändern kann. Daraus erzeugt
/// tool/build_seed.dart die Dateien supabase/seed.sql (Testumgebung) und
/// supabase/inhalte_live.sql (geprüfter Import für die Live-Datenbank).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
  Question({
    required this.question,
    required this.right,
    required this.wrong,
    required this.explanation,
    this.station,
    this.beginner,
  });

  final String question;
  final String right;
  final List<String> wrong;
  final String explanation;

  /// Fassung für Einsteiger mit ganzen Zahlen (`"einsteiger"`), nötig bei Beträgen mit Komma.
  final Question? beginner;

  /// Für quiz_questions.beginner und Wrack-Aufgaben: wie die Datenbank sie speichert.
  Map<String, dynamic>? get beginnerDb => beginner == null
      ? null
      : {
          'question': beginner!.question,
          'answers': beginner!.answers,
          'correct_index': 0,
          'explanation': beginner!.explanation,
        };

  /// Alle Texte der Frage (zum Prüfen auf Kommazahlen).
  String get allText => [question, ...answers, explanation].join(' ');

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
    this.miniGame,
    this.estimate,
    this.taps = const [],
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

  /// Echtes Mini-Spiel als Bonus nach der Station („minispiel“), kein Muss.
  final Map<String, dynamic>? miniGame;

  /// Schätzfrage vor der Erklärung („schaetzfrage“, INSELN.md Anhang).
  final Map<String, dynamic>? estimate;

  /// Antipp-Momente zwischen den Bildern der Erklärung („antippen“).
  final List<Map<String, dynamic>> taps;
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
    if (miniGame != null) 'mini_game': gameToDb(miniGame!),
    if (estimate != null) 'estimate': estimateToDb(estimate!),
    if (taps.isNotEmpty) 'taps': [for (final t in taps) tapToDb(t)],
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
/// Echte Mini-Spiele mit eigener Spielwelt (Startbild, Sterne, auf der
/// Startseite nochmal spielbar):
///   * till        Kasse: Kunden bezahlen, das Kind gibt Wechselgeld heraus
///   * market      Markt-Einkauf: Einkaufsliste, Geld, Preise an Ständen vergleichen
///   * ice_stand   Eisstand: an jedem Tag einen Preis setzen (Angebot und Nachfrage)
///   * trade_chain Tauschkette: tauschen, bis man das Ziel-Ding hat
///   * backpack    Rucksack packen: für jeden Ausflug mit Talern einpacken, was man wirklich braucht
///   * winter_store  Emmas Wintervorrat: jeden Herbsttag gleich essen oder für den Winter vergraben
///   * piggy_bank    Sparschwein füttern: Sparplan wählen, Woche für Woche füttern, Versuchungen
///   * glitter_shop  Glitzerladen: Verkaufstricks erkennen und nur kaufen, was auf der Liste steht
///   * kiosk_week    Mias Kiosk-Woche: mit dem Taschengeld einer Woche Wünsche kaufen oder lassen, Nötiges bezahlen
///   * logbook       Kurts Logbuch: Kassenzettel als Einnahme oder Ausgabe eintragen, größte Ausgabe finden
const builtGames = {'sort', 'order', 'choice', 'coins', 'pick', 'number', ...realGames};
const realGames = {
  'till',
  'market',
  'ice_stand',
  'trade_chain',
  'backpack',
  'winter_store',
  'piggy_bank',
  'glitter_shop',
  'kiosk_week',
  'logbook',
};

/// Verkaufstricks im Glitzerladen: Inhaltsdatei → Datenbank (wie `shopTricks` in der App).
const shopTricks = {
  'nur_heute': 'hurry',
  'alle_haben': 'everyone',
  'falscher_rabatt': 'fake_sale',
  'gratis_dazu': 'free_extra',
  'glitzer': 'sparkle',
};

/// Wetter am Eisstand: Inhaltsdatei → Datenbank.
const iceWeather = {'sonne': 'sun', 'wolken': 'clouds', 'regen': 'rain'};

/// Euro-Münzen und -Scheine in Cent für das Spiel „coins“.
const coinValues = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000];

/// Spiel-Daten für stations.content.game (englische Schlüssel).
Map<String, dynamic> gameToDb(Map<String, dynamic> g) {
  final type = g['art'];
  final easy = beginnerGame(g);
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
      if (type == 'choice' && g['haendler'] != null) ...{
        'traders': [
          for (final t in (g['haendler'] as List).cast<Map<String, dynamic>>())
            {'figure': t['wer'], 'name': t['name'], 'has': t['hat'], 'wants': t['will']},
        ],
        'images': ?g['bilder'],
      },
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
      if (realGames.contains(type)) ...{'image': ?g['startbild'], 'images': ?g['bilder']},
      if (type == 'till') ...{
        'items': [
          for (final d in ((g['preistafel'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {'text': d['text'], 'price': d['preis']},
        ],
        'customers': [
          for (final k in ((g['kunden'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {'figure': k['wer'], 'name': ?k['name'], 'text': k['text'], 'price': k['preis'], 'paid': k['bezahlt']},
        ],
      },
      if (type == 'market') ...{
        'budget': g['geld'],
        'needs': [
          for (final d in ((g['liste'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {'item': d['ding'], 'count': d['anzahl'] ?? 1},
        ],
        'stands': [
          for (final st in ((g['staende'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {
              'figure': st['wer'],
              'name': st['name'],
              'image': ?st['bild'],
              'offers': [
                for (final o in ((st['angebote'] as List?) ?? const []).cast<Map<String, dynamic>>())
                  {'item': o['ding'], 'price': o['preis']},
              ],
            },
        ],
      },
      if (type == 'ice_stand') ...{
        'price_min': g['preis_von'],
        'price_max': g['preis_bis'],
        'days': [
          for (final d in ((g['tage'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {
              'weather': iceWeather[d['wetter']],
              'scene': lines(d['szene']),
              'image': ?d['bild'],
              'stock': d['vorrat'],
              'demand': d['kunden'],
              'drop': d['weniger_pro_taler'],
            },
        ],
      },
      if (type == 'trade_chain') ...{
        'start': g['start'],
        'goal': g['ziel'],
        'traders': [
          for (final t in ((g['haendler'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {'figure': t['wer'], 'name': t['name'], 'has': t['hat'], 'wants': t['will']},
        ],
        'dead_end': ?line(g['sackgasse']),
      },
      if (type == 'backpack') ...{
        'items': [
          for (final d in ((g['dinge'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {'text': d['text'], 'price': d['preis']},
        ],
        'trips': [
          for (final a in ((g['ausfluege'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {
              'title': a['titel'],
              'scene': lines(a['szene']),
              'image': ?a['bild'],
              'budget': a['taler'],
              'needs': [
                for (final b in ((a['braucht'] as List?) ?? const []).cast<Map<String, dynamic>>())
                  {'item': b['ding'], 'missing': b['fehlt']},
              ],
            },
        ],
      },
      if (type == 'winter_store') ...{
        'days': [
          for (final t in ((g['tage'] as List?) ?? const []).cast<Map<String, dynamic>>()) {'scene': lines(t['szene'])},
        ],
        'now': g['jetzt'],
        'later': g['spaeter'],
        'need': g['winter'],
        'knock': ?line(g['gustav_klopft']),
        'share': ?line(g['teilen']),
        'keep': ?line(g['behalten']),
        'hungry': ?line(g['zu_wenig']),
      },
      if (type == 'piggy_bank') ...{
        'goal': g['ziel'],
        'goal_price': g['ziel_taler'],
        'income': g['taschengeld'],
        'plans': g['plaene'],
        'weeks': [
          for (final w in ((g['wochen'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {
              'scene': lines(w['szene']),
              if (w['ereignis'] case final Map<String, dynamic> e)
                'event': {
                  'kind': e['art'] == 'geschenk' ? 'gift' : 'temptation',
                  'speaker': e['wer'],
                  'name': ?e['name'],
                  'text': e['text'],
                  'item': ?e['ding'],
                  'price': e['taler'],
                },
            },
        ],
      },
      if (type == 'glitter_shop') ...{
        'budget': g['geld'],
        'offers': [
          for (final o in ((g['angebote'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {
              'item': o['ding'],
              'speaker': o['wer'] ?? 'elsa',
              'name': ?o['name'],
              'text': o['text'],
              'trick': shopTricks[o['trick']],
              'price': o['preis'],
              'needed': o['gebraucht'] == true,
              'reveal': o['aufloesung'],
            },
        ],
      },
      if (type == 'kiosk_week') ...{
        'budget': g['geld'],
        'kiosk_days': [
          for (final t in ((g['tage'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {
              'day': t['tag'],
              'scene': lines(t['szene']),
              'item': t['ding'],
              'price': t['preis'],
              'must': t['muss'] == true,
            },
        ],
        'broke': ?line(g['zu_wenig']),
      },
      if (type == 'logbook') ...{
        'log_start': g['start'],
        'log_entries': [
          for (final z in ((g['zettel'] as List?) ?? const []).cast<Map<String, dynamic>>())
            {
              'text': z['text'],
              'amount': z['taler'],
              'kind': z['art'] == 'ein' ? 'in' : 'out',
              'group': z['wofuer'] ?? '',
            },
        ],
      },
      'done': ?line(g['geschafft']),
      if (easy != null) 'beginner': gameToDb(easy),
    },
  };
}

/// Arten der Schätzfrage: Inhaltsdatei → Datenbank.
const estimateKinds = {'regler': 'slider', 'zahl': 'wheel', 'auswahl': 'choice'};

/// Arten der Antipp-Momente: Inhaltsdatei → Datenbank.
const tapKinds = {'tippen': 'tap', 'wischen': 'swipe', 'ziehen': 'drag', 'umdrehen': 'flip'};

/// Zeichen für Antipp-Momente. Die Liste muss in der App gleich sein
/// (`tapSymbols` in `lib/features/station/tap_moment_view.dart`).
const tapSymbols = {
  'muenze',
  'truhe',
  'hand',
  'hammer',
  'fisch',
  'preisschild',
  'waage',
  'besen',
  'anker',
  'flagge',
  'tuer',
  'sonne',
  'regen',
  'karte',
  'netz',
  'beutel',
  'rucksack',
  'flasche',
  'kleidung',
  'daumen',
  'winken',
  'foto',
  'buch',
  'liste',
  'wellen',
  'stern',
  'spielzeug',
  'schiff',
  'herz',
  'brot',
  'fernrohr',
  'laterne',
  'glocke',
  'stempel',
  'kalender',
  'schluessel',
  'werkzeug',
  'tafel',
};

/// Schätzfrage für stations.content.estimate (englische Schlüssel).
Map<String, dynamic> estimateToDb(Map<String, dynamic> e) {
  final reveal = e['aufloesung'] as Map<String, dynamic>?;
  return {
    'speaker': e['wer'],
    'question': e['frage'],
    'kind': estimateKinds[e['art']],
    'min': ?e['von'],
    'max': ?e['bis'],
    'step': ?e['schritt'],
    'start': ?e['start'],
    'unit': ?e['einheit'],
    'unit_one': ?e['einheit_eins'],
    'options': ?e['optionen'],
    'answer': ?e['loesung'],
    'reveal': {'speaker': reveal?['wer'], 'text': reveal?['text']},
  };
}

/// Antipp-Moment für stations.content.taps (englische Schlüssel).
Map<String, dynamic> tapToDb(Map<String, dynamic> t) => {
  'after': t['nach_bild'],
  'kind': tapKinds[t['art']],
  'text': t['text'],
  'symbol': ?t['zeichen'],
  'image': ?t['bild'],
  'count': ?t['anzahl'],
  'back': ?t['rueckseite'],
  'done': ?t['danach'],
};

/// Spiel für Einsteiger: die Felder aus `"einsteiger"` ersetzen die normalen.
Map<String, dynamic>? beginnerGame(Map<String, dynamic> g) {
  final easy = g['einsteiger'];
  if (easy is! Map<String, dynamic>) return null;
  return {...g, ...easy}..remove('einsteiger');
}

/// Betrag mit Komma im Text, zum Beispiel 3,50 €.
final commaNumber = RegExp(r'\d,\d');

/// Ganze Zahl für Einsteiger: ganze Euro oder nur Cent (unter 1 Euro).
bool wholeCents(Object? cents) => cents is int && (cents < 100 || cents % 100 == 0);

/// Beträge in Cent in einem Spiel (Münzen legen, Kasse, Markt).
List<Object?> gameAmounts(Map<String, dynamic> g) {
  List<Map<String, dynamic>> list(Object? raw) => ((raw as List?) ?? const []).cast<Map<String, dynamic>>();
  return switch (g['art']) {
    'coins' => [for (final r in list(g['runden'])) r['betrag']],
    'till' => [
      for (final k in list(g['kunden'])) ...[k['preis'], k['bezahlt']],
      for (final d in list(g['preistafel'])) d['preis'],
    ],
    'market' => [
      g['geld'],
      for (final st in list(g['staende']))
        for (final o in list(st['angebote'])) o['preis'],
    ],
    _ => const [],
  };
}

/// Braucht das Spiel eine Fassung mit ganzen Zahlen (Komma im Text oder Cent-Beträge)?
bool gameNeedsBeginner(Map<String, dynamic> g) {
  // „plaene“ ist eine Zahlenliste ([3,5,7]), keine Kommazahl.
  final plain = {...g}
    ..remove('einsteiger')
    ..remove('plaene');
  return commaNumber.hasMatch(jsonEncode(plain)) || !gameAmounts(plain).every(wholeCents);
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
    this.wreckSceneBeginner,
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

  /// Szene der Einsteiger-Fassung, sonst dieselbe wie [wreckScene].
  final List<Line>? wreckSceneBeginner;
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
        if (wreckQuestion.beginnerDb case final easy?)
          'beginner': {
            'scene': [for (final l in wreckSceneBeginner ?? wreckScene) l.toDb()],
            ...easy,
          },
      },
    },
  };
}

/// Bilder der Bildergeschichte, die die App selbst zeichnet (`"bild": "drawing:<name>"`),
/// weil es auf genaue Zahlen ankommt. Gleiche Liste in lib/features/station/story_drawings.dart.
const storyDrawings = {
  'euro_coins',
  'cents_to_euro',
  'comma_amount',
  'euro_notes',
  'big_coins_first',
  'nets_year',
  'nets_cost',
  'coins_week',
  'savings_plan',
};

/// Arten von Stopps auf See (CLAUDE.md Abschnitt 8, Begegnungen auf See).
const seaStopKinds = {'haendlerschiff', 'fischerboot', 'angeberschiff', 'tala_vergisst'};

/// Stopp auf See: Pflicht auf der Route vor einer Insel (entschieden mit Marc
/// am 10.10.2026). Wiederholt die Insel davor mit einer Szene und Fragen.
/// In der Datenbank eine Pflichtstation der Insel mit dem Typ sea_stop, vor
/// ihrer ersten Station.
class SeaStop {
  SeaStop({
    required this.kind,
    required this.figure,
    this.ship,
    required this.title,
    required this.xp,
    required this.scene,
    required this.summary,
    required this.quizShow,
    required this.questions,
  });

  /// haendlerschiff, fischerboot, angeberschiff oder tala_vergisst.
  final String kind;

  /// Figur auf der Karte (Asset-Schlüssel `character.<figure>`).
  final String figure;

  /// Schiff der Figur (Asset-Schlüssel `ship.…`), auf der Karte und im Stopp.
  final String? ship;
  final String title;
  final int xp;
  final List<Line> scene;
  final Line? summary;
  final int? quizShow;
  final List<Question> questions;

  Map<String, dynamic> toDbContent(int index) => {
    'title': title,
    'kind': 'sea_stop',
    'stop': {'type': kind, 'figure': figure, 'index': index, 'ship': ?ship},
    'scene': [for (final l in scene) l.toDb()],
    if (summary != null) 'summary': summary!.toDb(),
    'quiz': {'show': quizShow},
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
    this.learnKid = const [],
    required this.fog,
    required this.arrivalVideo,
    required this.arrivalScene,
    required this.badge,
    required this.task,
    required this.prompts,
    required this.stations,
    this.dives = const [],
    this.seaStops = const [],
    this.status = 'entwurf',
    this.teaser = const [],
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

  /// „Das lernst du hier“ auf der Insel: 2 bis 4 kurze Punkte in Kindersprache
  /// (`lernziel_kind`); [goal] ist für Eltern geschrieben.
  final List<String> learnKid;

  /// Insel liegt im Nebel: noch keine Stationen.
  final bool fog;
  final String? arrivalVideo;
  final List<Line> arrivalScene;
  final String? badge;
  final Map<String, dynamic>? task;
  final List<String> prompts;
  final List<Station> stations;
  final List<Dive> dives;

  /// Stopps auf See auf der Route vor dieser Insel, in Fahrtrichtung.
  final List<SeaStop> seaStops;

  /// entwurf, pruefung oder freigegeben (gilt für alles auf der Insel).
  final String status;

  /// Ausblick auf die nächste Insel nach dem Insel-Abschluss (`ausblick`, 1 bis 3 Zeilen),
  /// damit das Kind neugierig weitersegelt.
  final List<Line> teaser;

  /// Nächste Insel der Hauptroute, gesetzt von [loadIslands].
  Island? next;

  /// Status in der Datenbank (draft, review, published).
  String get dbStatus => contentStatuses[status] ?? 'draft';

  /// Inhalt für islands.content.
  Map<String, dynamic> toDbContent() => {
    'goal': goal,
    if (learnKid.isNotEmpty) 'learn': learnKid,
    'access': access == 'gratis' ? 'free' : 'premium',
    if (arrivalVideo != null || arrivalScene.isNotEmpty)
      'arrival': {
        'video_key': ?arrivalVideo,
        'scene': [for (final l in arrivalScene) l.toDb()],
      },
    'badge': ?badge,
    if (task != null) 'real_life_task': {'title': task!['titel'], 'text': task!['text']},
    if (teaser.isNotEmpty)
      'teaser': {
        'scene': [for (final l in teaser) l.toDb()],
        if (next != null) 'next_slug': next!.slug,
        if (next != null) 'next_title': next!.title,
      },
  };
}

/// Liest alle Inhaltsdateien eines Ordners, sortiert nach Reihenfolge.
List<Island> loadIslands(Directory dir) {
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final islands = [for (final f in files) parseIsland(f.uri.pathSegments.last, f.readAsStringSync())];
  islands.sort((a, b) => a.order.compareTo(b.order));
  for (var i = 0; i + 1 < islands.length; i++) {
    islands[i].next = islands[i + 1];
  }
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

  Question question(Map<String, dynamic> q, String where) {
    final easy = q['einsteiger'];
    return Question(
      question: text(q, 'frage', where),
      right: text(q, 'richtig', where),
      wrong: [for (final w in (q['falsch'] as List? ?? const [])) w as String],
      explanation: text(q, 'erklaerung', where),
      station: q['station'] as int?,
      beginner: easy is Map<String, dynamic>
          ? question({...q, ...easy}..remove('einsteiger'), '$where, Einsteiger')
          : null,
    );
  }

  List<Question> questions(Object? raw, String where) => [
    for (final (i, q) in ((raw as List?) ?? const []).indexed)
      question(q as Map<String, dynamic>, '$where, Frage ${i + 1}'),
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
        miniGame: s['minispiel'] as Map<String, dynamic>?,
        estimate: s['schaetzfrage'] as Map<String, dynamic>?,
        taps: ((s['antippen'] as List?) ?? const []).cast<Map<String, dynamic>>(),
        summary: abschluss == null ? null : lines([abschluss], '$where, Abschluss').single,
        quizShow: s['quiz_anzahl'] as int?,
        examShow: pruefung?['anzahl'] as int?,
        examReview: pruefung?['rueckblick'] as int?,
        examPass: pruefung?['bestehen'] as int?,
        questions: questions(s['fragen'], where),
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
    learnKid: [for (final l in (json['lernziel_kind'] as List? ?? const [])) l as String],
    fog: json['nebel'] == true,
    arrivalVideo: ankunft?['film'] as String?,
    arrivalScene: lines(ankunft?['szene'], '$file, Ankunft'),
    badge: json['orden'] as String?,
    task: json['auftrag'] as Map<String, dynamic>?,
    prompts: [for (final p in (json['kombuesen_fragen'] as List? ?? const [])) p as String],
    stations: stations,
    status: json['status'] as String? ?? 'entwurf',
    teaser: lines(json['ausblick'], '$file, Ausblick'),
    seaStops: [
      for (final (k, raw) in ((json['stopps_auf_see'] as List?) ?? const []).indexed)
        () {
          final st = raw as Map<String, dynamic>;
          final where = '$file, Stopp auf See ${k + 1}';
          final abschluss = st['abschluss'] as Map<String, dynamic>?;
          return SeaStop(
            kind: text(st, 'art', where),
            figure: text(st, 'figur', where),
            ship: st['schiff'] as String?,
            title: text(st, 'titel', where),
            xp: st['seemeilen'] as int? ?? 0,
            scene: lines(st['szene'], '$where, Szene'),
            summary: abschluss == null ? null : lines([abschluss], '$where, Abschluss').single,
            quizShow: st['quiz_anzahl'] as int?,
            questions: questions(st['fragen'], where),
          );
        }(),
    ],
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
            wreckSceneBeginner: (wrack['einsteiger'] as Map<String, dynamic>?)?['szene'] == null
                ? null
                : lines((wrack['einsteiger'] as Map<String, dynamic>)['szene'], '$where, Wrack, Einsteiger'),
            wreckQuestion: question(wrack, '$where, Wrack'),
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

  // Einsteiger rechnen nur mit ganzen Zahlen (Marc, 11.10.2026): Jede Frage
  // mit Kommazahl braucht eine Zwillingsfrage ohne Komma.
  void whole(Question q, String w) {
    final easy = q.beginner;
    check(
      !commaNumber.hasMatch(q.allText) || easy != null,
      '$w: Kommazahl, aber keine Fassung für Einsteiger ("einsteiger")',
    );
    if (easy == null) return;
    check(!commaNumber.hasMatch(easy.allText), '$w, Einsteiger: noch eine Kommazahl');
    check(easy.wrong.length == 2, '$w, Einsteiger: genau 2 falsche Antworten nötig');
    check(easy.answers.toSet().length == easy.answers.length, '$w, Einsteiger: Antworten doppelt');
  }

  void wholeGame(Map<String, dynamic>? g, String w) {
    if (g == null) return;
    final easy = beginnerGame(g);
    check(!gameNeedsBeginner(g) || easy != null, '$w: Kommazahl oder Cent-Betrag, aber keine Fassung für Einsteiger');
    if (easy == null) return;
    check(!gameNeedsBeginner(easy), '$w, Einsteiger: noch Kommazahlen oder Beträge, die keine ganzen Euro sind');
    problems.addAll(validateGame(easy, '$w, Einsteiger', knownAssetKeys: knownAssetKeys));
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
    // Kinder lesen auf der Insel „Das lernst du hier“, nicht das Lernziel für Eltern.
    if (island.stations.isNotEmpty) {
      check(
        island.learnKid.length >= 2 && island.learnKid.length <= 4,
        '$w: "lernziel_kind" braucht 2 bis 4 kurze Punkte für Kinder',
      );
    }
    for (final l in island.learnKid) {
      check(l.trim().isNotEmpty && l.length <= 70, '$w: Punkt in "lernziel_kind" leer oder länger als 70 Zeichen');
    }
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
      check(island.seaStops.isEmpty, '$w: Insel im Nebel hat noch keine Stopps auf See');
      check(island.status == 'entwurf', '$w: Insel im Nebel bleibt Entwurf');
      continue;
    }
    check(island.stations.isNotEmpty, '$w: Insel ohne Stationen muss "nebel": true haben');
    check(island.badge != null && island.badge!.trim().length >= 2, '$w: "orden" fehlt');
    // Ausblick auf die nächste Insel (Marc, 29.10.2026: Kinder sollen neugierig bleiben).
    if (index + 1 < islands.length) {
      check(island.teaser.isNotEmpty && island.teaser.length <= 3, '$w: "ausblick" braucht 1 bis 3 Zeilen');
    }
    for (final line in island.teaser) {
      check(knownAssetKeys.contains('character.${line.speaker}'), '$w, Ausblick: unbekannte Figur "${line.speaker}"');
    }
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
          if (image.startsWith('drawing:')) {
            final name = image.substring('drawing:'.length);
            check(storyDrawings.contains(name), '$sw: unbekannte Zeichnung "$name"');
          } else {
            check(knownAssetKeys.contains(image), '$sw: Bild $image fehlt im Asset-Manifest');
          }
        }
      }

      for (final (i, q) in s.questions.indexed) {
        final qw = '$sw, Frage ${i + 1}';
        check(q.wrong.length == 2, '$qw: genau 2 falsche Antworten nötig (3 Antworten insgesamt)');
        whole(q, qw);
        check(q.answers.map((a) => a.trim()).toSet().length == q.answers.length, '$qw: Antworten doppelt');
        check(q.answers.every((a) => a.trim().isNotEmpty), '$qw: leere Antwort');
      }
      final texts = s.questions.map((q) => q.question.trim()).toList();
      check(texts.toSet().length == texts.length, '$sw: eine Frage kommt doppelt vor');

      final game = s.game;
      if (game != null && builtGames.contains(game['art'])) {
        problems.addAll(validateGame(game, sw, knownAssetKeys: knownAssetKeys));
      }
      // Die Übung ist Pflicht, das echte Mini-Spiel ein Bonus danach (Marc, 11.10.2026).
      check(game == null || !realGames.contains(game['art']), '$sw: echte Mini-Spiele gehören unter "minispiel"');
      wholeGame(game, '$sw, Spiel');
      wholeGame(s.miniGame, '$sw, Mini-Spiel');
      final mini = s.miniGame;
      if (mini != null) {
        check(
          realGames.contains(mini['art']),
          '$sw: "minispiel" muss ein echtes Mini-Spiel sein (${realGames.join(', ')})',
        );
        check(game != null, '$sw: ein Mini-Spiel gibt es nur zusammen mit einer Übung');
        problems.addAll(validateGame(mini, '$sw, Mini-Spiel', knownAssetKeys: knownAssetKeys));
      }

      // Schätzfrage und Antipp-Momente (INSELN.md, Aufbau jeder Station): Jede
      // Station mit Bildergeschichte hat beides, außer dem Intro.
      final story = s.lesson.any((l) => l.image != null);
      if (story && !s.isIntro && !s.isExam) {
        check(s.estimate != null, '$sw: "schaetzfrage" fehlt (vor jeder Erklärung)');
        check(s.taps.length >= min(2, s.lesson.length), '$sw: mindestens 2 Antipp-Momente ("antippen") nötig');
      }
      if (s.estimate case final e?) {
        problems.addAll(validateEstimate(e, '$sw, Schätzfrage', knownAssetKeys: knownAssetKeys));
      }
      for (final (k, t) in s.taps.indexed) {
        problems.addAll(
          validateTap(t, '$sw, Antipp-Moment ${k + 1}', slides: s.lesson.length, knownAssetKeys: knownAssetKeys),
        );
      }
      final afters = [for (final t in s.taps) t['nach_bild']];
      check(afters.toSet().length == afters.length, '$sw: zwei Antipp-Momente nach demselben Bild');

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
      whole(d.wreckQuestion, '$dw, Wrack');
      for (final line in d.wreckScene) {
        check(knownAssetKeys.contains('character.${line.speaker}'), '$dw: unbekannte Figur "${line.speaker}"');
      }
      previous = d.after;
    }

    // Stopps auf See: auf der Route vor der Insel, also nie vor der ersten.
    check(island.seaStops.isEmpty || island.order > 1, '$w: vor der ersten Insel gibt es keine Stopps auf See');
    for (final (k, st) in island.seaStops.indexed) {
      final sw = '$w, Stopp auf See ${k + 1}';
      check(seaStopKinds.contains(st.kind), '$sw: unbekannte Art "${st.kind}"');
      check(knownAssetKeys.contains('character.${st.figure}'), '$sw: unbekannte Figur "${st.figure}"');
      if (st.ship case final ship?) {
        check(ship.startsWith('ship.') && knownAssetKeys.contains(ship), '$sw: unbekanntes Schiff "$ship"');
      }
      check(st.scene.isNotEmpty && st.summary != null, '$sw: Szene und Abschluss nötig');
      for (final line in [...st.scene, ?st.summary]) {
        check(knownAssetKeys.contains('character.${line.speaker}'), '$sw: unbekannte Figur "${line.speaker}"');
      }
      final show = st.quizShow;
      check(show != null && show > 0, '$sw: "quiz_anzahl" fehlt');
      if (show != null) {
        check(
          st.questions.length >= 2 * show,
          '$sw: Pool (${st.questions.length}) muss mindestens doppelt so groß sein wie $show',
        );
      }
      for (final (i, q) in st.questions.indexed) {
        check(q.wrong.length == 2, '$sw, Frage ${i + 1}: genau 2 falsche Antworten nötig (3 Antworten insgesamt)');
        whole(q, '$sw, Frage ${i + 1}');
      }
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

  void figure(Object? who, String w) {
    check(who is String && who.isNotEmpty, '$w: "wer" fehlt');
    if (knownAssetKeys != null && who is String) {
      check(knownAssetKeys.contains('character.$who'), '$w: unbekannte Figur "$who"');
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

  // Bilder der echten Mini-Spiele: Startbild, Dinge und Stände.
  if (knownAssetKeys != null && (realGames.contains(type) || game['bilder'] != null)) {
    final images = [
      game['startbild'],
      ...((game['bilder'] as Map<String, dynamic>?) ?? const {}).values,
      for (final st in ((game['staende'] as List?) ?? const []).cast<Map<String, dynamic>>()) st['bild'],
      for (final a in ((game['ausfluege'] as List?) ?? const []).cast<Map<String, dynamic>>()) a['bild'],
    ].whereType<String>();
    for (final image in images) {
      check(knownAssetKeys.contains(image), '$w: unbekanntes Bild "$image"');
    }
  }

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
      // Optional: Tafel „Wer hat was?“, damit sich niemand merken muss, wer was hat.
      if (game['haendler'] != null) {
        final traders = (game['haendler'] as List).cast<Map<String, dynamic>>();
        check(traders.length >= 2 && traders.length <= 3, '$w: 2 bis 3 Händler auf der Tafel');
        for (final (i, t) in traders.indexed) {
          final tw = '$w, Händler ${i + 1}';
          figure(t['wer'], tw);
          check(text(t['name']) && text(t['hat']) && text(t['will']), '$tw: "name", "hat" und "will" nötig');
        }
      }
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
    case 'till':
      final customers = (game['kunden'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      check(customers.length >= 3 && customers.length <= 8, '$w: 3 bis 8 Kunden');
      for (final (i, k) in customers.indexed) {
        final kw = '$w, Kunde ${i + 1}';
        figure(k['wer'], kw);
        check(text(k['text']), '$kw: "text" fehlt');
        final price = k['preis'], paid = k['bezahlt'];
        check(price is int && price > 0, '$kw: "preis" in Cent fehlt');
        check(paid is int && price is int && paid > price, '$kw: "bezahlt" muss mehr sein als der Preis');
        if (paid is int && price is int) check(paid - price <= 5000, '$kw: höchstens 50 Euro Wechselgeld');
      }
      final board = (game['preistafel'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      check(
        board.every((d) => text(d['text']) && d['preis'] is int && (d['preis'] as int) > 0),
        '$w: jede Zeile der Preistafel braucht Text und Preis',
      );
    case 'market':
      final budget = game['geld'];
      final needs = (game['liste'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final stands = (game['staende'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      check(budget is int && budget > 0, '$w: "geld" in Cent fehlt');
      check(needs.length >= 2 && needs.length <= 5, '$w: 2 bis 5 Dinge auf der Liste');
      check(stands.length >= 2 && stands.length <= 4, '$w: 2 bis 4 Stände');
      check(
        needs.every(
          (n) => text(n['ding']) && (n['anzahl'] == null || (n['anzahl'] is int && (n['anzahl'] as int) > 0)),
        ),
        '$w: jedes Ding auf der Liste braucht einen Namen und eine Anzahl ab 1',
      );
      for (final (i, st) in stands.indexed) {
        final sw = '$w, Stand ${i + 1}';
        figure(st['wer'], sw);
        check(text(st['name']), '$sw: "name" fehlt');
        final offers = (st['angebote'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        check(offers.isNotEmpty, '$sw: keine Angebote');
        check(
          offers.every((o) => text(o['ding']) && o['preis'] is int && (o['preis'] as int) > 0),
          '$sw: jedes Angebot braucht Ding und Preis',
        );
      }
      // Vergleichen muss sich lohnen: günstig geht es, überall teuer nicht.
      final prices = <String, List<int>>{};
      for (final st in stands) {
        for (final o in ((st['angebote'] as List?) ?? const []).cast<Map<String, dynamic>>()) {
          if (o['preis'] is int) prices.putIfAbsent('${o['ding']}', () => []).add(o['preis'] as int);
        }
      }
      var cheap = 0, dear = 0;
      for (final n in needs) {
        final p = prices['${n['ding']}'] ?? const [];
        final count = (n['anzahl'] as int?) ?? 1;
        check(p.length >= 2, '$w: "${n['ding']}" muss es an mindestens 2 Ständen geben');
        if (p.isNotEmpty) {
          cheap += p.reduce(min) * count;
          dear += p.reduce(max) * count;
        }
      }
      if (budget is int) {
        check(cheap <= budget, '$w: selbst überall am günstigsten kostet die Liste $cheap Cent, mehr als $budget');
        check(dear > budget, '$w: überall am teuersten reicht das Geld auch, Vergleichen lohnt sich nicht');
      }
    case 'ice_stand':
      final from = game['preis_von'], to = game['preis_bis'];
      check(
        from is int && to is int && from >= 1 && to > from && to <= 20,
        '$w: "preis_von" und "preis_bis" (1 bis 20 Taler)',
      );
      final days = (game['tage'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      check(days.length >= 2 && days.length <= 4, '$w: 2 bis 4 Tage');
      for (final (i, d) in days.indexed) {
        final dw = '$w, Tag ${i + 1}';
        check(iceWeather.containsKey(d['wetter']), '$dw: "wetter" muss sonne, wolken oder regen sein');
        for (final (k, l) in ((d['szene'] as List?) ?? const []).indexed) {
          speaker(l, '$dw, Szene ${k + 1}');
        }
        for (final key in ['vorrat', 'kunden', 'weniger_pro_taler']) {
          check(d[key] is int && (d[key] as int) > 0, '$dw: "$key" muss eine Zahl ab 1 sein');
        }
        final image = d['bild'];
        if (image != null && knownAssetKeys != null) {
          check(knownAssetKeys.contains(image), '$dw: unbekanntes Bild "$image"');
        }
        // Der beste Preis darf nicht am Rand liegen, sonst gibt es nichts abzuwägen.
        if (from is int && to is int && d['vorrat'] is int && d['kunden'] is int && d['weniger_pro_taler'] is int) {
          int earned(int p) =>
              min(max(0, (d['kunden'] as int) - (d['weniger_pro_taler'] as int) * p), d['vorrat'] as int) * p;
          final best = [for (var p = from; p <= to; p++) earned(p)].reduce(max);
          check(earned(from) < best && earned(to) < best, '$dw: der beste Preis liegt am Rand');
        }
      }
    case 'trade_chain':
      final start = game['start'], goal = game['ziel'];
      check(text(start) && text(goal) && start != goal, '$w: "start" und "ziel" fehlen oder sind gleich');
      final traders = (game['haendler'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      check(traders.length >= 3 && traders.length <= 6, '$w: 3 bis 6 Händler');
      for (final (i, t) in traders.indexed) {
        final tw = '$w, Händler ${i + 1}';
        figure(t['wer'], tw);
        check(text(t['name']) && text(t['hat']) && text(t['will']), '$tw: "name", "hat" und "will" nötig');
      }
      if (game['sackgasse'] != null) speaker(game['sackgasse'], '$w, "sackgasse"');
      // Lösbar: Kette vom Start zum Ziel, jeder Händler tauscht nur einmal.
      bool solvable(String holding, Set<int> used) {
        if (holding == goal) return true;
        for (final (i, t) in traders.indexed) {
          if (!used.contains(i) && t['will'] == holding && solvable('${t['hat']}', {...used, i})) return true;
        }
        return false;
      }
      if (text(start) && text(goal)) check(solvable(start as String, {}), '$w: vom Start kommt man nicht zum Ziel');
    case 'backpack':
      check(items.length >= 5 && items.length <= 10, '$w: 5 bis 10 Dinge im Packhaus');
      final prices = <String, int>{};
      for (final (i, d) in items.indexed) {
        final price = d['preis'];
        check(
          text(d['text']) && price is int && price >= 1 && price <= 20,
          '$w, Ding ${i + 1}: "text" und "preis" (1 bis 20 Taler)',
        );
        if (text(d['text']) && price is int) {
          check(!prices.containsKey(d['text']), '$w: "${d['text']}" gibt es doppelt');
          prices['${d['text']}'] = price;
        }
      }
      final all = prices.values.fold(0, (a, b) => a + b);
      final trips = (game['ausfluege'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      check(trips.length >= 2 && trips.length <= 4, '$w: 2 bis 4 Ausflüge');
      final needed = <String>{};
      for (final (i, a) in trips.indexed) {
        final aw = '$w, Ausflug ${i + 1}';
        check(text(a['titel']), '$aw: "titel" fehlt');
        final scene = (a['szene'] as List?) ?? const [];
        check(scene.isNotEmpty, '$aw: "szene" fehlt (daraus erkennt das Kind, was es braucht)');
        for (final (k, l) in scene.indexed) {
          speaker(l, '$aw, Szene ${k + 1}');
        }
        final budget = a['taler'];
        check(budget is int && budget > 0, '$aw: "taler" muss eine Zahl ab 1 sein');
        final needs = (a['braucht'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        check(needs.isNotEmpty && needs.length <= 4, '$aw: 1 bis 4 Dinge unter "braucht"');
        var cost = 0;
        for (final b in needs) {
          final item = b['ding'];
          check(prices.containsKey(item), '$aw: "$item" gibt es nicht im Packhaus');
          check(text(b['fehlt']), '$aw: bei "$item" fehlt "fehlt" (was passiert ohne)');
          cost += prices[item] ?? 0;
          needed.add('$item');
        }
        if (budget is int) {
          check(cost <= budget, '$aw: das Nötige kostet $cost Taler, mehr als $budget');
          // Abwägen: Alles zusammen passt nie hinein.
          check(budget < all, '$aw: mit $budget Talern passt alles hinein, es gibt nichts abzuwägen');
        }
        // Verlockung: Mindestens ein Ding wird auf diesem Ausflug nicht gebraucht.
        check(needs.length < prices.length, '$aw: jedes Ding wird gebraucht, nichts verlockt');
      }
      // Wünsche: Mindestens ein Ding braucht Tala auf keinem Ausflug.
      check(
        prices.keys.any((d) => !needed.contains(d)),
        '$w: jedes Ding wird irgendwo gebraucht, kein reiner Wunsch dabei',
      );
    case 'winter_store':
      final days = (game['tage'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final now = game['jetzt'], later = game['spaeter'], need = game['winter'];
      check(days.length >= 4 && days.length <= 8, '$w: 4 bis 8 Herbsttage');
      for (final (i, t) in days.indexed) {
        for (final (k, l) in ((t['szene'] as List?) ?? const []).indexed) {
          speaker(l, '$w, Tag ${i + 1}, Szene ${k + 1}');
        }
      }
      check(now is int && now >= 1, '$w: "jetzt" muss eine Zahl ab 1 sein');
      check(later is int && now is int && later > now, '$w: "spaeter" muss mehr sein als "jetzt" (Geduld lohnt sich)');
      for (final key in ['gustav_klopft', 'teilen', 'behalten', 'zu_wenig']) {
        speaker(game[key], '$w, "$key"');
      }
      if (need is int && later is int && days.isNotEmpty) {
        // Mindestens ein Tag darf Emma essen, aber nicht an der Hälfte der Tage.
        check(need <= later * (days.length - 1), '$w: "winter" verlangt, dass Emma nie isst');
        check(
          need > later * (days.length - (days.length + 1) ~/ 2),
          '$w: "winter" ist zu leicht, Essen an jedem zweiten Tag reicht',
        );
      } else {
        problems.add('$w: "winter" (Nüsse für den Winter) fehlt');
      }
    case 'piggy_bank':
      final price = game['ziel_taler'], income = game['taschengeld'];
      final plans = ((game['plaene'] as List?) ?? const []).whereType<int>().toList();
      final weeks = (game['wochen'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      check(text(game['ziel']), '$w: "ziel" fehlt');
      check(price is int && price > 0, '$w: "ziel_taler" fehlt');
      check(income is int && income > 0 && income <= 20, '$w: "taschengeld" (1 bis 20 Taler pro Woche)');
      check(weeks.length >= 3 && weeks.length <= 8, '$w: 3 bis 8 Wochen');
      check(plans.length >= 2 && plans.length <= 4, '$w: 2 bis 4 Pläne');
      if (income is int) {
        check(plans.every((p) => p >= 1 && p <= income), '$w: jeder Plan zwischen 1 und dem Taschengeld');
      }
      if (price is int) {
        // Planen muss sich lohnen: ein Plan reicht, einer nicht.
        check(plans.any((p) => p * weeks.length >= price), '$w: kein Plan reicht für das Ziel');
        check(plans.any((p) => p * weeks.length < price), '$w: jeder Plan reicht, es gibt nichts zu rechnen');
      }
      for (final (i, wk) in weeks.indexed) {
        final ww = '$w, Woche ${i + 1}';
        for (final (k, l) in ((wk['szene'] as List?) ?? const []).indexed) {
          speaker(l, '$ww, Szene ${k + 1}');
        }
        if (wk['ereignis'] case final Map<String, dynamic> e) {
          check(e['art'] == 'versuchung' || e['art'] == 'geschenk', '$ww: "art" muss versuchung oder geschenk sein');
          speaker(e, '$ww, Ereignis');
          check(e['taler'] is int && (e['taler'] as int) > 0, '$ww: "taler" fehlt');
          if (e['art'] == 'versuchung') check(text(e['ding']), '$ww: "ding" fehlt');
        }
      }
    case 'glitter_shop':
      final budget = game['geld'];
      final offers = (game['angebote'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      check(budget is int && budget > 0, '$w: "geld" in Talern fehlt');
      check(offers.length >= 3 && offers.length <= 6, '$w: 3 bis 6 Angebote');
      var neededCost = 0;
      for (final (i, o) in offers.indexed) {
        final ow = '$w, Angebot ${i + 1}';
        speaker({'wer': o['wer'] ?? 'elsa', 'text': o['text']}, ow);
        check(text(o['ding']), '$ow: "ding" fehlt');
        check(shopTricks.containsKey(o['trick']), '$ow: "trick" muss einer von ${shopTricks.keys.join(', ')} sein');
        check(o['preis'] is int && (o['preis'] as int) > 0, '$ow: "preis" in Talern fehlt');
        check(text(o['aufloesung']), '$ow: "aufloesung" fehlt (was hinter dem Trick steckt)');
        if (o['gebraucht'] == true && o['preis'] is int) neededCost += o['preis'] as int;
      }
      check(offers.any((o) => o['gebraucht'] == true), '$w: mindestens ein Ding steht auf Talas Liste');
      check(offers.any((o) => o['gebraucht'] != true), '$w: mindestens ein Ding ist nur Verlockung');
      if (budget is int) check(neededCost <= budget, '$w: die Liste kostet $neededCost Taler, mehr als $budget');
    case 'kiosk_week':
      final budget = game['geld'];
      final days = (game['tage'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      check(budget is int && budget > 0 && budget <= 30, '$w: "geld" (1 bis 30 Taler für die Woche)');
      check(days.length >= 5 && days.length <= 7, '$w: 5 bis 7 Tage');
      var must = 0, all = 0;
      for (final (i, t) in days.indexed) {
        final tw = '$w, Tag ${i + 1}';
        check(text(t['tag']), '$tw: "tag" fehlt (zum Beispiel Montag)');
        check(text(t['ding']), '$tw: "ding" fehlt');
        check(t['preis'] is int && (t['preis'] as int) > 0, '$tw: "preis" in Talern fehlt');
        for (final (k, l) in ((t['szene'] as List?) ?? const []).indexed) {
          speaker(l, '$tw, Szene ${k + 1}');
        }
        if (t['preis'] is int) {
          all += t['preis'] as int;
          if (t['muss'] == true) must += t['preis'] as int;
        }
      }
      if (budget is int) {
        // Planen muss sich lohnen: das Nötige passt, alles zusammen nicht.
        check(must <= budget, '$w: das Nötige kostet $must Taler, mehr als $budget');
        check(all > budget, '$w: alles zusammen passt in $budget Taler, es gibt nichts zu entscheiden');
      }
      check(days.any((t) => t['muss'] == true), '$w: mindestens ein Tag mit etwas Nötigem');
      check(days.isEmpty || days.first['muss'] != true, '$w: der erste Tag ist ein Wunsch, kein Muss');
    case 'logbook':
      final start = game['start'];
      final slips = (game['zettel'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      check(start is int && start >= 0, '$w: "start" (Taler am Anfang) fehlt');
      check(slips.length >= 5 && slips.length <= 10, '$w: 5 bis 10 Zettel');
      var balance = start is int ? start : 0;
      final groups = <String, int>{};
      for (final (i, z) in slips.indexed) {
        final zw = '$w, Zettel ${i + 1}';
        check(text(z['text']), '$zw: "text" fehlt');
        check(z['art'] == 'ein' || z['art'] == 'aus', '$zw: "art" muss ein oder aus sein');
        check(z['taler'] is int && (z['taler'] as int) > 0, '$zw: "taler" fehlt');
        if (z['taler'] is int) {
          balance += z['art'] == 'ein' ? z['taler'] as int : -(z['taler'] as int);
          check(balance >= 0, '$zw: der Stand im Logbuch wird negativ');
        }
        if (z['art'] == 'aus') {
          check(text(z['wofuer']), '$zw: "wofuer" fehlt (Gruppe der Ausgabe)');
          if (z['taler'] is int) {
            final group = z['wofuer'] as String? ?? '';
            groups[group] = (groups[group] ?? 0) + (z['taler'] as int);
          }
        }
      }
      check(slips.any((z) => z['art'] == 'ein') && slips.any((z) => z['art'] == 'aus'), '$w: Einnahmen und Ausgaben');
      check(groups.length >= 2 && groups.length <= 4, '$w: 2 bis 4 Gruppen bei den Ausgaben');
      if (groups.isNotEmpty) {
        final most = groups.values.reduce((a, b) => a > b ? a : b);
        check(groups.values.where((v) => v == most).length == 1, '$w: die größte Ausgabe-Gruppe muss eindeutig sein');
      }
    default:
      problems.add('$w: unbekannte Spielart "$type"');
  }
  return problems;
}

/// Prüft eine Schätzfrage: Art, Frage, Bereich, Lösung im Bereich, Auflösung.
List<String> validateEstimate(Map<String, dynamic> e, String w, {Set<String>? knownAssetKeys}) {
  final problems = <String>[];
  void check(bool ok, String message) {
    if (!ok) problems.add(message);
  }

  bool text(Object? v) => v is String && v.trim().isNotEmpty;
  void speaker(Object? raw, String where) {
    if (raw is! Map<String, dynamic>) {
      problems.add('$where: Zeile fehlt');
      return;
    }
    check(text(raw['text']), '$where: Text fehlt');
    if (knownAssetKeys != null) {
      check(knownAssetKeys.contains('character.${raw['wer']}'), '$where: unbekannte Figur "${raw['wer']}"');
    }
  }

  check(estimateKinds.containsKey(e['art']), '$w: "art" muss regler, zahl oder auswahl sein');
  check(text(e['frage']), '$w: "frage" fehlt');
  speaker({'wer': e['wer'], 'text': e['frage']}, w);
  if (e['aufloesung'] is Map<String, dynamic>) {
    speaker(e['aufloesung'], '$w, Auflösung');
  } else {
    problems.add('$w: "aufloesung" fehlt (Satz am Ende der Erklärung)');
  }
  // Ganze Zahlen, damit Einsteiger mitschätzen können.
  check(!commaNumber.hasMatch(jsonEncode(e)), '$w: Schätzfragen nur mit ganzen Zahlen');
  final answer = e['loesung'];
  if (e['art'] == 'auswahl') {
    final options = (e['optionen'] as List?) ?? const [];
    check(options.length >= 2 && options.length <= 4 && options.every(text), '$w: 2 bis 4 "optionen"');
    check(
      answer == null || (answer is int && answer >= 0 && answer < options.length),
      '$w: "loesung" ist keine Möglichkeit',
    );
  } else {
    final from = e['von'], to = e['bis'], step = e['schritt'] ?? 1;
    check(from is int && to is int && to > from, '$w: "von" und "bis" (ganze Zahlen, bis größer als von)');
    check(step is int && step > 0, '$w: "schritt" muss eine Zahl ab 1 sein');
    if (from is int && to is int && step is int && step > 0) {
      check((to - from) % step == 0, '$w: "bis" liegt nicht im Schritt-Raster');
      if (e['art'] == 'zahl') check((to - from) ~/ step <= 120, '$w: höchstens 120 Zahlen auf dem Zahlenrad');
      bool onGrid(Object? v) => v is int && v >= from && v <= to && (v - from) % step == 0;
      check(answer == null || onGrid(answer), '$w: "loesung" liegt nicht zwischen von und bis (im Raster)');
      check(e['start'] == null || onGrid(e['start']), '$w: "start" liegt nicht zwischen von und bis (im Raster)');
    }
    check(e['einheit'] == null || text(e['einheit']), '$w: leere "einheit"');
  }
  return problems;
}

/// Prüft einen Antipp-Moment: Art, Text, Platz zwischen den Bildern, Zeichen oder Bild.
List<String> validateTap(Map<String, dynamic> t, String w, {required int slides, Set<String>? knownAssetKeys}) {
  final problems = <String>[];
  void check(bool ok, String message) {
    if (!ok) problems.add(message);
  }

  bool text(Object? v) => v is String && v.trim().isNotEmpty;
  check(tapKinds.containsKey(t['art']), '$w: "art" muss tippen, wischen, ziehen oder umdrehen sein');
  check(text(t['text']), '$w: "text" fehlt (was das Kind tun soll)');
  final after = t['nach_bild'];
  check(after is int && after >= 1 && after <= slides, '$w: "nach_bild" muss 1 bis $slides sein (nach diesem Bild)');
  final symbol = t['zeichen'], image = t['bild'];
  check(symbol != null || image != null, '$w: "zeichen" oder "bild" fehlt');
  if (symbol != null) check(tapSymbols.contains(symbol), '$w: unbekanntes Zeichen "$symbol"');
  if (image != null && knownAssetKeys != null) check(knownAssetKeys.contains(image), '$w: unbekanntes Bild "$image"');
  final count = t['anzahl'];
  check(count == null || (count is int && count >= 1 && count <= 5), '$w: "anzahl" 1 bis 5');
  if (t['art'] == 'umdrehen') check(text(t['rueckseite']), '$w: beim Umdrehen fehlt die "rueckseite"');
  check(t['danach'] == null || text(t['danach']), '$w: leeres "danach"');
  return problems;
}

// -----------------------------------------------------------------------------
// Begegnungen auf See (content/begegnungen.json)
// -----------------------------------------------------------------------------

/// Arten von Begegnungen wie in der Datenbank (encounters.type).
const encounterTypes = {'taleron', 'haendlerschiff', 'fischerboot', 'angeberschiff', 'tala_vergisst', 'taleron_trial'};

/// Meister Talerons Prüfung (`art: taleron_trial`): Inseln, Bestehensgrenze und Orden.
class EncounterTrial {
  EncounterTrial({
    required this.islands,
    required this.pass,
    required this.badgeSlug,
    required this.badgeTitle,
    required this.badgeAsset,
    required this.notPassed,
  });

  /// Slugs der Inseln, aus denen die Fragen kommen.
  final List<String> islands;

  /// So viele richtige Antworten (erster Versuch) braucht der Orden.
  final int pass;
  final String badgeSlug;
  final String badgeTitle;
  final String badgeAsset;

  /// Was Taleron sagt, wenn es noch nicht gereicht hat.
  final Line notPassed;
}

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
    this.trial,
  });

  final String slug;
  final String type;

  /// Nur bei Meister Talerons Prüfung.
  final EncounterTrial? trial;
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

  List<Line> get allLines => [...firstScene, ...scene, right, wrong, success, ?trial?.notPassed];

  /// Inhalt für encounters.content.
  Map<String, dynamic> toDbContent() => {
    'first_scene': [for (final l in firstScene) l.toDb()],
    'scene': [for (final l in scene) l.toDb()],
    'right': right.toDb(),
    'wrong': wrong.toDb(),
    'success': success.toDb(),
    if (trial != null) ...{
      'not_passed': trial!.notPassed.toDb(),
      'trial': {'islands': trial!.islands, 'pass': trial!.pass, 'badge': trial!.badgeSlug},
    },
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
          trial: e['pruefung'] == null
              ? null
              : () {
                  final p = e['pruefung'] as Map<String, dynamic>;
                  final w = '$where, Prüfung';
                  final orden = (p['orden'] as Map<String, dynamic>?) ?? (throw ContentException('$w: "orden" fehlt'));
                  return EncounterTrial(
                    islands: [for (final s in (p['inseln'] as List?) ?? const []) s as String],
                    pass: p['bestehen'] as int? ?? 0,
                    badgeSlug: text(orden, 'slug', '$w, Orden'),
                    badgeTitle: text(orden, 'titel', '$w, Orden'),
                    badgeAsset: text(orden, 'bild', '$w, Orden'),
                    notPassed: line(p['nicht_bestanden'], '$w, "nicht_bestanden"'),
                  );
                }(),
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
    final trial = e.trial;
    if (e.type == 'taleron_trial') {
      check(trial != null, '$w: Prüfung braucht "pruefung" (inseln, bestehen, orden, nicht_bestanden)');
      check(e.questionCount >= 6 && e.questionCount <= 12, '$w: 6 bis 12 Fragen');
      check(e.afterIsland != null, '$w: Prüfung braucht "ab_insel"');
      if (trial != null) {
        check(trial.islands.isNotEmpty, '$w: Prüfung braucht Inseln');
        for (final s in trial.islands) {
          check(slugs.contains(s), '$w: unbekannte Insel "$s" in der Prüfung');
        }
        check(trial.pass >= 1 && trial.pass <= e.questionCount, '$w: "bestehen" muss 1 bis ${e.questionCount} sein');
        check(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(trial.badgeSlug), '$w: Slug des Ordens ist ungültig');
        check(!slugs.contains(trial.badgeSlug), '$w: Slug des Ordens ist schon der Orden einer Insel');
        check(trial.badgeTitle.length <= 60, '$w: Titel des Ordens ist länger als 60 Zeichen');
        check(knownAssetKeys.contains(trial.badgeAsset), '$w: Bild ${trial.badgeAsset} fehlt im Asset-Manifest');
      }
    } else {
      check(trial == null, '$w: "pruefung" nur bei Art taleron_trial');
      check(e.questionCount >= 3 && e.questionCount <= 5, '$w: 3 bis 5 Fragen');
    }
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
    // Stopps auf See auf der Route vor der Insel: Pflicht, vor Station 1 (Reihenfolge 1, 2, ...).
    for (final (k, st) in island.seaStops.indexed) {
      final sid = _id('stage$stage/${island.slug}/sea${k + 1}');
      b
        ..writeln('-- Stopp auf See ${k + 1}: ${st.title}')
        ..writeln(
          'insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)',
        )
        ..writeln("values ($sid, $iid, ${k + 1}, 'sea_stop', true, ${st.xp}, ${_json(st.toDbContent(k + 1))}, $status)")
        ..writeln('on conflict (id) do update set')
        ..writeln('  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,')
        ..writeln('  content = excluded.content, status = excluded.status;');
      for (final (i, q) in st.questions.indexed) {
        final qname = 'stage$stage/${island.slug}/sea${k + 1}/q${i + 1}';
        questionIds.add(_id(qname));
        b
          ..writeln(
            'insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)',
          )
          ..writeln(
            "values (${_id(qname)}, $sid, ${_lit(q.question)}, ${_json(q.answers)}, 0, ${_lit(q.explanation)}, null, $status, "
            "${q.beginnerDb == null ? 'null' : _json(q.beginnerDb!)})",
          )
          ..writeln('on conflict (id) do update set')
          ..writeln(
            '  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,',
          )
          ..writeln('  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;');
      }
      b.writeln();
    }
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
            'insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)',
          )
          ..writeln(
            'values (${_id(qname)}, $sid, ${_lit(q.question)}, ${_json(q.answers)}, 0, ${_lit(q.explanation)}, '
            "${q.station ?? 'null'}, $status, ${q.beginnerDb == null ? 'null' : _json(q.beginnerDb!)})",
          )
          ..writeln('on conflict (id) do update set')
          ..writeln(
            '  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,',
          )
          ..writeln(
            '  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,',
          )
          ..writeln('  beginner = excluded.beginner;');
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
    final trial = e.trial;
    if (trial != null) {
      // Siegel nach den Inselorden (sort_order ab 100), Status wie die Prüfung.
      final order = 100 + encounters.where((x) => x.trial != null).toList().indexOf(e);
      b
        ..writeln('insert into public.badges (id, slug, kind, island_id, title, asset_key, sort_order, status)')
        ..writeln(
          "values (${_id('badge/${trial.badgeSlug}')}, ${_lit(trial.badgeSlug)}, 'taleron', null, "
          "${_lit(trial.badgeTitle)}, ${_lit(trial.badgeAsset)}, $order, ${_lit(e.dbStatus)})",
        )
        ..writeln('on conflict (id) do update set')
        ..writeln('  title = excluded.title, asset_key = excluded.asset_key, sort_order = excluded.sort_order,')
        ..writeln('  status = excluded.status;')
        ..writeln();
    }
  }

  b.writeln('commit;');
  return b.toString();
}
