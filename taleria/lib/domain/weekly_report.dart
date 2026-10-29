import 'budget_models.dart';
import 'content_models.dart';
import 'learning_status.dart';
import 'progress_models.dart';

/// Was ein Kind in den letzten 7 Tagen geschafft hat, für den Wochenbericht im
/// Leuchtturm. Eltern sollen sehen, dass ihr Kind lernt (Marc, 29.10.2026).
class WeeklyReport {
  const WeeklyReport({
    required this.from,
    required this.to,
    this.stations = const [],
    this.dives = 0,
    this.islands = const [],
    this.badges = const [],
    this.finds = 0,
    this.tasksApproved = 0,
    this.rewardCents = 0,
    this.shakyTopics = const [],
    this.prompt,
    this.streakWeeks = 0,
    this.lastActiveAt,
  });

  final DateTime from;
  final DateTime to;

  /// Titel der geschafften Stationen und Stopps auf See (ohne Intro und Tauchgänge).
  final List<String> stations;
  final int dives;
  final List<String> islands;
  final List<String> badges;
  final int finds;
  final int tasksApproved;
  final int rewardCents;

  /// Themen, die gerade wackeln (höchstens drei).
  final List<String> shakyTopics;

  /// Gesprächsidee zur Insel, auf der das Kind gerade ist.
  final String? prompt;
  final int streakWeeks;
  final DateTime? lastActiveAt;

  /// Diese Woche ist nichts passiert.
  bool get quiet => stations.isEmpty && dives == 0 && islands.isEmpty && tasksApproved == 0;
}

/// Rechnet den Bericht für die 7 Tage bis [now].
WeeklyReport buildWeeklyReport({
  required DateTime now,
  required Map<String, DateTime> stationDoneAt,
  required Map<String, StationInfo> stations,
  required Map<String, DateTime> islandCompletedAt,
  required Map<String, String> islandTitles,
  List<BadgeInfo> badges = const [],
  List<CollectibleInfo> collection = const [],
  List<FamilyTask> tasks = const [],
  List<TopicLearning> learning = const [],
  String? prompt,
  ChildStats? stats,
}) {
  final from = now.subtract(const Duration(days: 7));
  bool inWeek(DateTime? t) => t != null && t.isAfter(from) && !t.isAfter(now);

  final done = [
    for (final e in stationDoneAt.entries)
      if (inWeek(e.value) && stations[e.key] != null) (station: stations[e.key]!, at: e.value),
  ]..sort((a, b) => a.at.compareTo(b.at));

  return WeeklyReport(
    from: from,
    to: now,
    stations: [
      for (final d in done)
        if (!d.station.isDive && !d.station.content.isOnboarding) d.station.content.title,
    ],
    dives: done.where((d) => d.station.isDive).length,
    islands: [
      for (final e in islandCompletedAt.entries)
        if (inWeek(e.value) && islandTitles[e.key] != null) islandTitles[e.key]!,
    ],
    badges: [
      for (final b in badges)
        if (inWeek(b.earnedAt)) b.title,
    ],
    finds: collection.where((c) => inWeek(c.foundAt)).length,
    tasksApproved: tasks.where((t) => t.status == TaskStatus.approved && inWeek(t.reviewedAt)).length,
    rewardCents: tasks
        .where((t) => t.status == TaskStatus.approved && inWeek(t.reviewedAt))
        .fold(0, (sum, t) => sum + t.rewardCents),
    shakyTopics: [
      for (final t in learning)
        if (t.status == TopicStatus.shaky && stations[t.stationId] != null) stations[t.stationId]!.content.title,
    ].take(3).toList(),
    prompt: prompt,
    streakWeeks: stats?.streakWeeks ?? 0,
    lastActiveAt: stats?.lastActiveAt,
  );
}
