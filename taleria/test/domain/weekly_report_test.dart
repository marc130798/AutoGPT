import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/budget_models.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/domain/weekly_report.dart';

void main() {
  StationInfo station(String id, {StationType type = StationType.quiz}) => StationInfo(
    id: id,
    islandId: 'insel',
    sortOrder: 10,
    type: type,
    isRequired: true,
    xpReward: 100,
    content: StationContent(title: 'Station $id'),
  );

  test('Wochenbericht zählt nur die letzten 7 Tage', () {
    final now = DateTime(2026, 10, 29, 12);
    final report = buildWeeklyReport(
      now: now,
      stationDoneAt: {'a': DateTime(2026, 10, 28), 'b': DateTime(2026, 10, 20), 'tauch': DateTime(2026, 10, 27)},
      stations: {
        'a': station('a'),
        'b': station('b'),
        'tauch': station('tauch', type: StationType.reviewStop),
      },
      islandCompletedAt: {'insel': DateTime(2026, 10, 28)},
      islandTitles: {'insel': 'Hafen'},
      tasks: [
        FamilyTask(
          id: 't1',
          title: 'Zimmer',
          rewardCents: 250,
          isChore: false,
          status: TaskStatus.approved,
          reviewedAt: DateTime(2026, 10, 25),
        ),
        FamilyTask(
          id: 't2',
          title: 'Alt',
          rewardCents: 500,
          isChore: false,
          status: TaskStatus.approved,
          reviewedAt: DateTime(2026, 10, 1),
        ),
      ],
    );
    expect(report.stations, ['Station a']);
    expect(report.dives, 1);
    expect(report.islands, ['Hafen']);
    expect(report.tasksApproved, 1);
    expect(report.rewardCents, 250);
    expect(report.quiet, isFalse);
  });

  test('Ohne Fahrt in der Woche ist der Bericht ruhig', () {
    final report = buildWeeklyReport(
      now: DateTime(2026, 10, 29),
      stationDoneAt: {'a': DateTime(2026, 10, 1)},
      stations: {'a': station('a')},
      islandCompletedAt: const {},
      islandTitles: const {},
    );
    expect(report.quiet, isTrue);
  });
}
