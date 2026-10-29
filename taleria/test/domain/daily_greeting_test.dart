import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/budget_models.dart';
import 'package:taleria/domain/daily_greeting.dart';
import 'package:taleria/domain/progress_models.dart';

void main() {
  const noWind = PaceStatus(free: false, stationsPerWeek: 2, wind: 0);

  test('Am selben Tag derselbe Satz, an anderen Tagen wechselt er', () {
    const stats = ChildStats(xp: 100);
    final monday = dailyGreeting(day: DateTime(2026, 11, 2, 8), stats: stats);
    expect(dailyGreeting(day: DateTime(2026, 11, 2, 20), stats: stats).kind, monday.kind);
    final kinds = {for (var d = 0; d < 14; d++) dailyGreeting(day: DateTime(2026, 11, 2 + d), stats: stats).kind};
    expect(kinds, containsAll([GreetingKind.wind, GreetingKind.tip]));
  });

  test('Alles, was passt, kommt im Laufe der Tage dran', () {
    final stats = ChildStats(
      xp: 1300,
      nextRank: Rank.parse('matrose'),
      nextRankXp: 1500,
      streakWeeks: 3,
      reviewsDue: 2,
      pace: PaceStatus(free: false, stationsPerWeek: 2, wind: 0, nextRelease: DateTime(2026, 11, 5)),
    );
    final goals = [
      const SavingsGoal(id: 'a', title: 'Ball', targetCents: 1000, savedCents: 600),
      const SavingsGoal(id: 'b', title: 'Buch', targetCents: 800, savedCents: 0),
    ];
    final seen = <GreetingKind, DailyGreeting>{
      for (var d = 0; d < 30; d++)
        for (final g in [dailyGreeting(day: DateTime(2026, 11, 1 + d), stats: stats, goals: goals)]) g.kind: g,
    };
    expect(
      seen.keys,
      containsAll([
        GreetingKind.waitWind,
        GreetingKind.rankSoon,
        GreetingKind.goalSoon,
        GreetingKind.streak,
        GreetingKind.reviews,
        GreetingKind.tip,
      ]),
    );
    expect(seen.containsKey(GreetingKind.wind), isFalse, reason: 'kein Wind');
    expect(seen[GreetingKind.rankSoon]!.number, 200);
    expect(seen[GreetingKind.goalSoon]!.title, 'Ball');
    expect(seen[GreetingKind.goalSoon]!.number, 400);
    expect(seen[GreetingKind.waitWind]!.date, DateTime(2026, 11, 5));
  });

  test('Ein voller Wunschschatz geht vor, ohne Wind und Termin kein Wind-Satz', () {
    const stats = ChildStats(xp: 100, pace: noWind);
    final goals = [const SavingsGoal(id: 'a', title: 'Ball', targetCents: 1000, savedCents: 1000)];
    final kinds = {
      for (var d = 0; d < 10; d++) dailyGreeting(day: DateTime(2026, 11, 1 + d), stats: stats, goals: goals).kind,
    };
    expect(kinds, {GreetingKind.goalReady, GreetingKind.tip});
  });
}
