import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/domain/progress_models.dart';

void main() {
  group('Statistik aus child_stats()', () {
    final json = {
      'xp': 850,
      'rank': 'schiffsjunge',
      'rank_min_xp': 1,
      'next_rank': 'matrose',
      'next_rank_xp': 1500,
      'next_rank_needs_certificate': false,
      'streak_weeks': 3,
      'streak_paused': false,
      'badge_count': 1,
      'reviews_due': 4,
      'pace': {'free': false, 'stations_per_week': 2, 'wind': 0, 'next_release': '2026-10-15'},
    };

    test('liest alle Werte', () {
      final stats = ChildStats.fromJson(json);
      expect(stats.rank, Rank.schiffsjunge);
      expect(stats.nextRank, Rank.matrose);
      expect(stats.xpToNextRank, 650);
      expect(stats.progressToNextRank, closeTo(849 / 1499, 0.0001));
      expect(stats.streakWeeks, 3);
      expect(stats.reviewsDue, 4);
      expect(stats.pace.hasWind, isFalse);
      expect(stats.pace.nextRelease, DateTime(2026, 10, 15));
      expect(stats.pace.nextRelease!.weekday, DateTime.thursday);
    });

    test('Kapitän nur mit Schatzkarte: kein Balken, keine Seemeilen-Grenze', () {
      final stats = ChildStats.fromJson({
        ...json,
        'rank': 'steuermann',
        'rank_min_xp': 8000,
        'next_rank': 'kapitaen',
        'next_rank_xp': null,
        'next_rank_needs_certificate': true,
      });
      expect(stats.nextRankNeedsCertificate, isTrue);
      expect(stats.progressToNextRank, isNull);
      expect(stats.xpToNextRank, isNull);
    });

    test('Freie Fahrt hat immer Wind', () {
      expect(
        ChildStats.fromJson({
          ...json,
          'pace': {'free': true, 'wind': null},
        }).pace.hasWind,
        isTrue,
      );
      expect(const PaceStatus(free: false, wind: 1).hasWind, isTrue);
    });

    test('Level für Eltern', () {
      expect(Rank.schiffsjunge.level, 1);
      expect(Rank.kapitaen.level, 5);
      expect(Rank.parse('unbekannt'), isNull);
    });
  });

  test('Ergebnis einer Station mit neuem Rang, Orden und Wind', () {
    final result = StationResult.fromJson({
      'correct': 10,
      'total': 10,
      'passed': true,
      'xp_awarded': 150,
      'island_completed': true,
      'rank_up': 'matrose',
      'badge': {'id': 'b', 'slug': 'hafen', 'title': 'Erster Landgang', 'asset_key': 'badge.hafen'},
      'wind_left': 0,
    });
    expect(result.rankUp, Rank.matrose);
    expect(result.badge?.title, 'Erster Landgang');
    expect(result.windLeft, 0);
  });

  test('Begegnung: beim ersten Mal die Vorstellung, danach die kurze Begrüßung', () {
    Map<String, dynamic> offer({required bool first}) => {
      'encounter': {
        'id': 'e',
        'slug': 'taleron',
        'type': 'taleron',
        'title': 'Meister Taleron',
        'asset_key': 'character.taleron',
        'question_count': 3,
        'xp_reward': 20,
        'content': {
          'first_scene': [
            {'speaker': 'tala', 'text': 'Da ist etwas!'},
            {'speaker': 'taleron', 'text': 'Hoho!'},
          ],
          'scene': [
            {'speaker': 'taleron', 'text': 'Da seid ihr ja wieder!'},
          ],
          'success': {'speaker': 'taleron', 'text': 'Gute Fahrt!'},
        },
      },
      'question_ids': ['a', 'b', 'c'],
      'first_meeting': first,
      'due_count': 5,
    };
    expect(EncounterOffer.fromJson(offer(first: true)).openingScene, hasLength(2));
    final later = EncounterOffer.fromJson(offer(first: false));
    expect(later.openingScene.single.text, 'Da seid ihr ja wieder!');
    expect(later.encounter.success?.text, 'Gute Fahrt!');
    expect(later.questionIds, ['a', 'b', 'c']);
  });
}
