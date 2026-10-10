/// Seemeilen, Ränge, Orden, Tempo (Wind), Fahrtwind und Begegnungen.
/// Ohne Aussehen, ohne Supabase. Berechnet wird alles auf dem Server
/// (child_stats, submit_station, submit_encounter).
library;

import 'content_models.dart';

/// Ränge in der Reihenfolge der Reise (Glossar: Rang im Kinderbereich, Level bei den Eltern).
enum Rank {
  schiffsjunge('schiffsjunge'),
  matrose('matrose'),
  bootsmann('bootsmann'),
  steuermann('steuermann'),
  kapitaen('kapitaen');

  const Rank(this.code);

  final String code;

  /// Level für die Eltern (1 bis 5).
  int get level => index + 1;

  static Rank? parse(Object? code) {
    for (final rank in values) {
      if (rank.code == code) return rank;
    }
    return null;
  }
}

/// Tempo: Wind für neue Stationen (CLAUDE.md Abschnitt 8).
class PaceStatus {
  const PaceStatus({required this.free, this.stationsPerWeek, this.wind, this.nextRelease});

  factory PaceStatus.fromJson(Map<String, dynamic> json) => PaceStatus(
    free: json['free'] as bool? ?? true,
    stationsPerWeek: json['stations_per_week'] as int?,
    wind: json['wind'] as int?,
    nextRelease: json['next_release'] == null ? null : DateTime.parse(json['next_release'] as String),
  );

  /// Freie Fahrt: kein Wind nötig.
  static const freeSailing = PaceStatus(free: true);

  final bool free;

  /// 2, 3 oder 4; `null` bei freier Fahrt.
  final int? stationsPerWeek;

  /// So viele neue Stationen darf das Kind gerade beginnen (`null` bei freier Fahrt).
  final int? wind;

  /// Nächster Freigabetag, wenn gerade kein Wind da ist.
  final DateTime? nextRelease;

  bool get hasWind => free || (wind ?? 0) > 0;
}

/// Alles für die Startseite des Kindes (child_stats()).
class ChildStats {
  const ChildStats({
    required this.xp,
    this.rank,
    this.rankMinXp,
    this.nextRank,
    this.nextRankXp,
    this.nextRankNeedsCertificate = false,
    this.streakWeeks = 0,
    this.streakPaused = false,
    this.badgeCount = 0,
    this.reviewsDue = 0,
    this.pace = PaceStatus.freeSailing,
    this.pearls = 0,
    this.finds = 0,
    this.lastActiveAt,
    this.premium = true,
  });

  factory ChildStats.fromJson(Map<String, dynamic> json) => ChildStats(
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    rank: Rank.parse(json['rank']),
    rankMinXp: json['rank_min_xp'] as int?,
    nextRank: Rank.parse(json['next_rank']),
    nextRankXp: json['next_rank_xp'] as int?,
    nextRankNeedsCertificate: json['next_rank_needs_certificate'] as bool? ?? false,
    streakWeeks: json['streak_weeks'] as int? ?? 0,
    streakPaused: json['streak_paused'] as bool? ?? false,
    badgeCount: json['badge_count'] as int? ?? 0,
    reviewsDue: json['reviews_due'] as int? ?? 0,
    pearls: (json['pearls'] as num?)?.toInt() ?? 0,
    finds: json['finds'] as int? ?? 0,
    premium: json['premium'] as bool? ?? true,
    lastActiveAt: json['last_active_at'] == null ? null : DateTime.parse(json['last_active_at'] as String),
    pace: json['pace'] is Map<String, dynamic>
        ? PaceStatus.fromJson(json['pace'] as Map<String, dynamic>)
        : PaceStatus.freeSailing,
  );

  final int xp;
  final Rank? rank;
  final int? rankMinXp;
  final Rank? nextRank;

  /// Seemeilen für den nächsten Rang; `null`, wenn er nur mit der Goldenen Schatzkarte kommt.
  final int? nextRankXp;
  final bool nextRankNeedsCertificate;
  final int streakWeeks;
  final bool streakPaused;
  final int badgeCount;
  final int reviewsDue;
  final PaceStatus pace;

  /// Perlen aus Tauchgängen und Funde in der Unterwasser-Sammlung.
  final int pearls;
  final int finds;

  /// Zuletzt an Bord (Station, Begegnung oder Wiederholung), `null` = noch nie.
  final DateTime? lastActiveAt;

  /// Das Eltern-Konto hat das Abo (Premium-Inseln offen).
  final bool premium;

  /// Fehlende Seemeilen bis zum nächsten Rang (`null`, wenn es nicht um Seemeilen geht).
  int? get xpToNextRank => nextRankXp == null ? null : (nextRankXp! - xp).clamp(0, nextRankXp!);

  /// Fortschritt zum nächsten Rang, 0 bis 1 (`null`, wenn es nicht um Seemeilen geht).
  double? get progressToNextRank {
    final target = nextRankXp;
    if (target == null) return null;
    final start = rankMinXp ?? 0;
    if (target <= start) return 1;
    return ((xp - start) / (target - start)).clamp(0.0, 1.0);
  }
}

/// Ein Orden (Glossar: Orden im Kinderbereich, Abzeichen bei den Eltern).
class BadgeInfo {
  const BadgeInfo({
    required this.id,
    required this.slug,
    required this.title,
    required this.assetKey,
    this.sortOrder = 0,
    this.earnedAt,
  });

  factory BadgeInfo.fromJson(Map<String, dynamic> json) => BadgeInfo(
    id: json['id'] as String,
    slug: json['slug'] as String,
    title: json['title'] as String,
    assetKey: json['asset_key'] as String,
    sortOrder: json['sort_order'] as int? ?? 0,
  );

  final String id;
  final String slug;
  final String title;
  final String assetKey;
  final int sortOrder;

  /// `null` = noch nicht verdient.
  final DateTime? earnedAt;

  bool get earned => earnedAt != null;

  BadgeInfo earnedOn(DateTime date) =>
      BadgeInfo(id: id, slug: slug, title: title, assetKey: assetKey, sortOrder: sortOrder, earnedAt: date);
}

/// Ein Fund für die Unterwasser-Sammlung (nur Optik, nie kaufbar).
class CollectibleInfo {
  const CollectibleInfo({
    required this.id,
    required this.slug,
    required this.kind,
    required this.title,
    required this.assetKey,
    this.foundAt,
  });

  factory CollectibleInfo.fromJson(Map<String, dynamic> json) => CollectibleInfo(
    id: json['id'] as String,
    slug: json['slug'] as String,
    kind: json['kind'] as String? ?? 'wreck_item',
    title: json['title'] as String,
    assetKey: json['asset_key'] as String,
  );

  final String id;
  final String slug;

  /// pearl, shell oder wreck_item
  final String kind;
  final String title;
  final String assetKey;

  /// `null` = noch nicht gefunden.
  final DateTime? foundAt;

  bool get found => foundAt != null;

  CollectibleInfo foundOn(DateTime date) =>
      CollectibleInfo(id: id, slug: slug, kind: kind, title: title, assetKey: assetKey, foundAt: date);
}

/// Vorlage einer Begegnung auf See (encounters).
class Encounter {
  const Encounter({
    required this.id,
    required this.slug,
    required this.type,
    required this.title,
    required this.assetKey,
    required this.questionCount,
    required this.xpReward,
    this.firstScene = const [],
    this.scene = const [],
    this.right,
    this.wrong,
    this.success,
  });

  factory Encounter.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] as Map<String, dynamic>?) ?? const {};
    List<DialogLine> lines(Object? raw) => [
      for (final l in (raw as List?) ?? const []) DialogLine.fromJson(l as Map<String, dynamic>),
    ];
    DialogLine? line(Object? raw) => raw is Map<String, dynamic> ? DialogLine.fromJson(raw) : null;
    return Encounter(
      id: json['id'] as String,
      slug: json['slug'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      assetKey: json['asset_key'] as String,
      questionCount: json['question_count'] as int? ?? 3,
      xpReward: json['xp_reward'] as int? ?? 0,
      firstScene: lines(content['first_scene']),
      scene: lines(content['scene']),
      right: line(content['right']),
      wrong: line(content['wrong']),
      success: line(content['success']),
    );
  }

  final String id;
  final String slug;

  /// taleron, haendlerschiff, fischerboot, angeberschiff, tala_vergisst
  final String type;
  final String title;
  final String assetKey;
  final int questionCount;
  final int xpReward;
  final List<DialogLine> firstScene;
  final List<DialogLine> scene;
  final DialogLine? right;
  final DialogLine? wrong;
  final DialogLine? success;
}

/// Eine Begegnung, die gerade auf der Karte wartet (next_encounter()).
class EncounterOffer {
  const EncounterOffer({
    required this.encounter,
    required this.questionIds,
    required this.firstMeeting,
    required this.dueCount,
  });

  factory EncounterOffer.fromJson(Map<String, dynamic> json) => EncounterOffer(
    encounter: Encounter.fromJson(json['encounter'] as Map<String, dynamic>),
    questionIds: [for (final id in json['question_ids'] as List) id as String],
    firstMeeting: json['first_meeting'] as bool? ?? false,
    dueCount: json['due_count'] as int? ?? 0,
  );

  final Encounter encounter;
  final List<String> questionIds;
  final bool firstMeeting;
  final int dueCount;

  /// Szene zu Beginn: beim ersten Mal die Vorstellung, danach die kurze Begrüßung.
  List<DialogLine> get openingScene =>
      firstMeeting && encounter.firstScene.isNotEmpty ? encounter.firstScene : encounter.scene;
}

/// Antwort des Servers nach einer Begegnung.
class EncounterResult {
  const EncounterResult({
    required this.correct,
    required this.total,
    required this.xpAwarded,
    this.rankUp,
    this.streakWeeks = 0,
  });

  factory EncounterResult.fromJson(Map<String, dynamic> json) => EncounterResult(
    correct: json['correct'] as int,
    total: json['total'] as int,
    xpAwarded: json['xp_awarded'] as int? ?? 0,
    rankUp: Rank.parse(json['rank_up']),
    streakWeeks: json['streak_weeks'] as int? ?? 0,
  );

  final int correct;
  final int total;
  final int xpAwarded;
  final Rank? rankUp;
  final int streakWeeks;
}
