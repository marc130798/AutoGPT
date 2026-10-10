/// Lernstand pro Thema für die Eltern (CLAUDE.md Abschnitt 8: „was das Kind
/// sicher kann und wo es noch wackelt“). Die Zahlen kommen aus dem
/// Wiederholungsplan (learning_status() in der Datenbank).
library;

enum TopicStatus {
  /// Noch keine Frage zu diesem Thema beantwortet.
  notStarted,

  /// Richtig beantwortet, aber noch nicht über Tage wiederholt.
  learning,

  /// Auch nach Tagen noch gewusst.
  secure,

  /// Die letzte Antwort war bei einem Teil der Fragen falsch.
  shaky,
}

/// Zahlen eines Themas (einer Station) aus dem Wiederholungsplan.
class TopicLearning {
  const TopicLearning({
    required this.stationId,
    required this.islandId,
    required this.answered,
    required this.secure,
    required this.learning,
    required this.shaky,
  });

  factory TopicLearning.fromJson(Map<String, dynamic> json) => TopicLearning(
    stationId: json['station_id'] as String,
    islandId: json['island_id'] as String,
    answered: json['answered'] as int? ?? 0,
    secure: json['secure'] as int? ?? 0,
    learning: json['learning'] as int? ?? 0,
    shaky: json['shaky'] as int? ?? 0,
  );

  final String stationId;
  final String islandId;
  final int answered;
  final int secure;
  final int learning;
  final int shaky;

  TopicStatus get status => topicStatus(answered: answered, secure: secure, shaky: shaky);
}

/// Urteil pro Thema (Vorschlag, mit Marc abstimmen):
/// * wackelt noch: mindestens ein Drittel der Fragen zuletzt falsch
/// * sicher: mindestens zwei Drittel der Fragen auch nach Tagen gewusst
/// * sonst: wird geübt
TopicStatus topicStatus({required int answered, required int secure, required int shaky}) {
  if (answered <= 0) return TopicStatus.notStarted;
  if (shaky * 3 >= answered) return TopicStatus.shaky;
  if (secure * 3 >= answered * 2) return TopicStatus.secure;
  return TopicStatus.learning;
}
