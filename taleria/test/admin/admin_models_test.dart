import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/admin/domain/admin_models.dart';

void main() {
  group('Rollen', () {
    test('Owner darf alles, Redaktion nur Inhalte, Support nur suchen', () {
      expect(
        [AdminRole.owner.seesOverview, AdminRole.owner.changesFamilies, AdminRole.owner.seesAuditLog],
        [true, true, true],
      );
      expect(
        [AdminRole.editor.seesContent, AdminRole.editor.seesSupport, AdminRole.editor.seesOverview],
        [true, false, false],
      );
      expect(
        [AdminRole.support.seesSupport, AdminRole.support.changesFamilies, AdminRole.support.seesContent],
        [true, false, false],
      );
    });

    test('whoami: unbekannte Rolle oder kein Admin', () {
      expect(AdminIdentity.fromJson(null), isNull);
      expect(AdminIdentity.fromJson({'role': 'boss', 'mfa': true}), isNull);
      final who = AdminIdentity.fromJson({'role': 'editor', 'mfa': false, 'email': 'a@b.de'})!;
      expect([who.role, who.mfa, who.email], [AdminRole.editor, false, 'a@b.de']);
    });
  });

  test('Schlüssel der Zwei-Faktor-App in Vierergruppen', () {
    expect(const TotpSetup(factorId: 'f', secret: 'ABCDEFGHIJ', uri: '').groupedSecret, 'ABCD EFGH IJ');
  });

  test('Inhalts-Statistik aus der Datenbank lesen', () {
    final stats = ContentStats.fromJson({
      'stage': 1,
      'children_onboarded': 4,
      'islands': [
        {
          'id': 'i',
          'slug': 'hafen',
          'title': 'Hafen',
          'sort_order': 1,
          'route_type': 'main',
          'status': 'review',
          'publish_at': null,
          'access': 'free',
          'questions': 60,
          'reached': 3,
          'completed': 1,
          'stations': [
            {
              'id': 's',
              'number': 2,
              'title': 'Ankerplatz',
              'type': 'review_stop',
              'status': 'draft',
              'is_required': true,
              'questions': 0,
              'done': 2,
            },
          ],
        },
      ],
      'hardest_questions': [
        {
          'id': 'q',
          'question': 'Frage',
          'island': 'Hafen',
          'station_number': 2,
          'station_type': 'quiz',
          'answered': 6,
          'wrong': 5,
          'wrong_rate': 0.83,
        },
      ],
      'easiest_questions': [],
    });
    final island = stats.islands.single;
    expect([island.status, island.premium, island.inFog], [ContentStatus.review, false, false]);
    expect(island.stations.single.isDive, isTrue);
    expect(stats.hardest.single.wrongPercent, 83);
  });

  test('Familie im Supportfall lesen', () {
    final family = FamilyInfo.fromJson({
      'parent_id': 'p',
      'email': 'a@b.de',
      'created_at': '2026-10-01T10:00:00Z',
      'consent_at': '2026-10-01T10:00:00Z',
      'consent_version': '2026-10',
      'marketing_consent': true,
      'children': 2,
      'last_active_at': null,
      'premium': true,
      'entitlements': [
        {'source': 'manual', 'valid_until': null},
      ],
    });
    expect(family.hasManualPremium, isTrue);
    expect(family.lastActiveAt, isNull);
    expect(family.entitlements.single.validUntil, isNull);
  });

  test('Test-Einstellungen erkennen', () {
    expect(
      EnvironmentSettings.fromRows([
        {'key': 'content_preview', 'value': true},
      ]).anyTestSetting,
      isTrue,
    );
    expect(
      EnvironmentSettings.fromRows([
        {'key': 'content_preview', 'value': false},
      ]).anyTestSetting,
      isFalse,
    );
  });

  test('Abo von Hand: Laufzeiten', () {
    final now = DateTime.utc(2026, 10, 10);
    expect(ManualPremiumDuration.unlimited.validUntil(now), isNull);
    expect(ManualPremiumDuration.oneYear.validUntil(now), DateTime.utc(2027, 10, 10));
  });

  group('Der Admin-Code bleibt aus der Store-App heraus', () {
    final importPattern = RegExp(r'''^import\s+'([^']+)';''', multiLine: true);

    // Alle Dateien, die von [entry] aus erreichbar sind (nur eigene Dateien unter lib/).
    Set<String> reachable(String entry) {
      final seen = <String>{};
      final todo = [File(entry).absolute.path];
      final lib = Directory('lib').absolute.path;
      while (todo.isNotEmpty) {
        final path = todo.removeLast();
        if (!seen.add(path)) continue;
        for (final m in importPattern.allMatches(File(path).readAsStringSync())) {
          final target = m.group(1)!;
          if (target.startsWith('dart:')) continue;
          if (target.startsWith('package:')) {
            if (!target.startsWith('package:taleria/')) continue;
            todo.add('$lib/${target.substring('package:taleria/'.length)}');
          } else {
            todo.add(File(path).parent.uri.resolve(target).toFilePath());
          }
        }
      }
      return seen;
    }

    test('lib/main.dart erreicht keine Datei unter lib/admin/', () {
      final files = reachable('lib/main.dart');
      expect(files.where((f) => f.contains('/lib/admin/')), isEmpty);
      expect(files.length, greaterThan(50), reason: 'Importe werden wirklich verfolgt');
    });

    test('Der Adminbereich braucht kein dart:io (läuft im Browser)', () {
      for (final path in reachable('lib/main_admin.dart')) {
        expect(File(path).readAsStringSync(), isNot(contains("import 'dart:io'")), reason: path);
      }
    });
  });
}
