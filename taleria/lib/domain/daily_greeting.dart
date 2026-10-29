import 'budget_models.dart';
import 'progress_models.dart';

/// Worum es im Satz des Tages geht.
enum GreetingKind { wind, waitWind, rankSoon, goalReady, goalSoon, streak, reviews, tip }

/// Ein Satz von Talo oder Tala auf der Startseite, jeden Tag ein anderer
/// (Marcs Wunsch am 29.10.2026: die App soll lebendiger wirken). Ohne Druck:
/// keine Uhrzeit, kein Countdown, nur Hinweise und Tipps.
class DailyGreeting {
  const DailyGreeting(this.kind, {required this.speaker, this.number = 0, this.title, this.date, this.rank});

  final GreetingKind kind;

  /// `talo` oder `tala`.
  final String speaker;

  /// Seemeilen, Cent, Wochen oder Nummer des Tipps, je nach [kind].
  final int number;

  /// Name des Wunschschatzes.
  final String? title;

  /// Nächster Freigabetag.
  final DateTime? date;
  final Rank? rank;
}

/// Wie viele Tipps es gibt (Texte `greetingTip0` bis `greetingTip5`).
const greetingTipCount = 6;

/// Der Satz für [day]: Aus allem, was gerade passt, und einem Tipp wird
/// reihum einer gewählt. Am selben Tag bleibt es derselbe Satz.
DailyGreeting dailyGreeting({required DateTime day, required ChildStats stats, List<SavingsGoal> goals = const []}) {
  final dayNumber = DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  final open = goals.where((g) => !g.reached).toList();
  final ready = open.where((g) => g.canRedeem).toList();
  final saving = open.where((g) => !g.canRedeem && g.savedCents > 0).toList()
    ..sort((a, b) => a.missingCents.compareTo(b.missingCents));
  final toRank = stats.xpToNextRank;
  final tip = dayNumber % greetingTipCount;

  final options = <DailyGreeting>[
    if (stats.pace.hasWind)
      const DailyGreeting(GreetingKind.wind, speaker: 'talo')
    else if (stats.pace.nextRelease != null)
      DailyGreeting(GreetingKind.waitWind, speaker: 'talo', date: stats.pace.nextRelease),
    if (toRank != null && toRank > 0 && toRank <= 500 && stats.nextRank != null)
      DailyGreeting(GreetingKind.rankSoon, speaker: 'talo', number: toRank, rank: stats.nextRank),
    if (ready.isNotEmpty)
      DailyGreeting(GreetingKind.goalReady, speaker: 'tala', title: ready.first.title)
    else if (saving.isNotEmpty)
      DailyGreeting(
        GreetingKind.goalSoon,
        speaker: 'tala',
        title: saving.first.title,
        number: saving.first.missingCents,
      ),
    if (stats.streakWeeks >= 2) DailyGreeting(GreetingKind.streak, speaker: 'tala', number: stats.streakWeeks),
    if (stats.reviewsDue > 0) const DailyGreeting(GreetingKind.reviews, speaker: 'talo'),
    DailyGreeting(GreetingKind.tip, speaker: tip.isEven ? 'tala' : 'talo', number: tip),
  ];
  return options[dayNumber % options.length];
}
