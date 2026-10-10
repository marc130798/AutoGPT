import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/admin/admin_texts.dart';
import 'package:taleria/admin/domain/admin_models.dart';
import 'package:taleria/core/config/app_config.dart';

import 'fake_admin.dart';

void main() {
  group('Anmeldung', () {
    testWidgets('Erste Anmeldung: Passwort, Zwei-Faktor einrichten, dann die Übersicht', (tester) async {
      final auth = FakeAdminAuth();
      await pumpAdminApp(tester, auth: auth, repository: FakeAdminRepository(auth));

      expect(find.text(AdminTexts.loginTitle), findsOneWidget);
      await signIn(tester, password: 'falsch');
      expect(find.text('E-Mail oder Passwort stimmt nicht.'), findsOneWidget);

      await signIn(tester);
      expect(find.text(AdminTexts.mfaSetupTitle), findsOneWidget);
      expect(find.text('JBSW Y3DP EHPK 3PXP JBSW'), findsOneWidget, reason: 'Schlüssel in Vierergruppen');

      await enterCode(tester, '000000');
      expect(find.textContaining('Der Code stimmt nicht'), findsOneWidget);
      expect(auth.aal2, isFalse);

      await enterCode(tester, FakeAdminAuth.validCode);
      expect(auth.aal2, isTrue);
      expect(find.text(AdminTexts.families), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text(AdminTexts.premium(1, 2, 1)), findsOneWidget);
      expect(find.text('75 %'), findsOneWidget, reason: 'Rückkehr nach 1 Woche: 6 von 8');
      expect(find.text(AdminTexts.returned(6, 8, 14)), findsOneWidget);
      expect(find.text('Noch niemand ist 35 Tage dabei.'), findsOneWidget, reason: 'Rückkehr nach 4 Wochen');
      expect(find.text('chefin@test.invalid · Owner'), findsOneWidget);
    });

    testWidgets('Mit eingerichteter App nur noch den Code eingeben', (tester) async {
      final auth = FakeAdminAuth(enrolled: {'chefin@test.invalid'});
      await pumpAdminApp(tester, auth: auth, repository: FakeAdminRepository(auth));
      await signIn(tester);

      expect(find.text(AdminTexts.mfaVerifyTitle), findsOneWidget);
      expect(auth.setups, 0, reason: 'keine neue App einrichten');
      await enterCode(tester, FakeAdminAuth.validCode);
      expect(find.text(AdminTexts.families), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('admin-sign-out')));
      await tester.pumpAndSettle();
      expect(find.text(AdminTexts.loginTitle), findsOneWidget);
      expect(auth.hasSession, isFalse);
    });

    testWidgets('Eltern-Konten kommen nicht hinein und richten keine Zwei-Faktor-App ein', (tester) async {
      final auth = FakeAdminAuth(accounts: {'eltern@test.invalid': 'geheim123'});
      await pumpAdminApp(tester, auth: auth, repository: FakeAdminRepository(auth));
      await signIn(tester, email: 'eltern@test.invalid');

      expect(find.text(AdminTexts.notAdminTitle), findsOneWidget);
      expect(auth.hasSession, isFalse, reason: 'wieder abgemeldet');
      expect(auth.setups, 0);
      await tester.tap(find.text(AdminTexts.backToLogin));
      await tester.pumpAndSettle();
      expect(find.text(AdminTexts.loginTitle), findsOneWidget);
    });
  });

  group('Rollen', () {
    Future<void> loginAs(WidgetTester tester, AdminRole role, {AppEnvironment env = AppEnvironment.test}) async {
      final auth = FakeAdminAuth(enrolled: {'chefin@test.invalid'});
      final repository = FakeAdminRepository(auth, roles: {'chefin@test.invalid': role});
      await pumpAdminApp(tester, auth: auth, repository: repository, environment: env);
      await signIn(tester);
      await enterCode(tester, FakeAdminAuth.validCode);
    }

    testWidgets('Owner sieht alle fünf Bereiche', (tester) async {
      await loginAs(tester, AdminRole.owner);
      for (final name in ['overview', 'content', 'support', 'audit', 'errors']) {
        expect(find.byKey(ValueKey('nav-$name')), findsOneWidget, reason: name);
      }
    });

    testWidgets('Redaktion sieht nur Inhalte', (tester) async {
      await loginAs(tester, AdminRole.editor);
      expect(find.byKey(const ValueKey('nav-content')), findsOneWidget);
      for (final name in ['overview', 'support', 'audit', 'errors']) {
        expect(find.byKey(ValueKey('nav-$name')), findsNothing, reason: name);
      }
      expect(find.text('1. Hafen von Taleria'), findsOneWidget);
    });

    testWidgets('Support sieht nur den Support und ändert nichts', (tester) async {
      await loginAs(tester, AdminRole.support);
      expect(find.byKey(const ValueKey('nav-support')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-overview')), findsNothing);

      await tester.enterText(find.byKey(const ValueKey('support-email')), 'familie@test.invalid');
      await tester.enterText(find.byKey(const ValueKey('support-reason')), 'Anfrage per E-Mail');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('support-search')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('support-family')), findsOneWidget);
      expect(find.byKey(const ValueKey('support-grant')), findsNothing);
      expect(find.byKey(const ValueKey('support-delete')), findsNothing);
    });

    testWidgets('Testumgebung zeigt die Test-Einstellungen, ohne Alarm', (tester) async {
      final auth = FakeAdminAuth(enrolled: {'chefin@test.invalid'});
      final repository = FakeAdminRepository(auth)
        ..settings = const EnvironmentSettings(contentPreview: true, testPurchases: true);
      await pumpAdminApp(tester, auth: auth, repository: repository);
      await signIn(tester);
      await enterCode(tester, FakeAdminAuth.validCode);
      expect(find.text(AdminTexts.environmentTest), findsOneWidget);
      expect(find.byKey(const ValueKey('banner-test')), findsOneWidget);
      expect(find.byKey(const ValueKey('banner-live-warning')), findsNothing);
    });

    testWidgets('Live-Datenbank mit Test-Einstellungen schlägt Alarm', (tester) async {
      final auth = FakeAdminAuth(enrolled: {'chefin@test.invalid'});
      final repository = FakeAdminRepository(auth)..settings = const EnvironmentSettings(contentPreview: true);
      await pumpAdminApp(tester, auth: auth, repository: repository, environment: AppEnvironment.live);
      await signIn(tester);
      await enterCode(tester, FakeAdminAuth.validCode);
      expect(find.text(AdminTexts.environmentLive), findsOneWidget);
      expect(find.byKey(const ValueKey('banner-live-warning')), findsOneWidget);
    });
  });

  group('Inhalte', () {
    testWidgets('Status, Zugang und Rückgang von Station zu Station', (tester) async {
      final auth = FakeAdminAuth(enrolled: {'chefin@test.invalid'});
      await pumpAdminApp(tester, auth: auth, repository: FakeAdminRepository(auth));
      await signIn(tester);
      await enterCode(tester, FakeAdminAuth.validCode);
      await tester.tap(find.byKey(const ValueKey('nav-content')));
      await tester.pumpAndSettle();

      expect(find.text(AdminTexts.islandLine(60, 15, 9)), findsOneWidget);
      expect(find.text('Veröffentlicht'), findsOneWidget);
      expect(find.text(AdminTexts.fog), findsOneWidget, reason: 'Spar-Insel ohne Stationen');
      expect(find.text(AdminTexts.premiumIsland), findsOneWidget);

      await tester.tap(find.text('1. Hafen von Taleria'));
      await tester.pumpAndSettle();
      expect(find.text('geschafft von 15'), findsOneWidget);
      expect(find.text('begonnen von 14 · geschafft von 12 (−3)'), findsOneWidget);
      expect(find.text('Was ist Inflation?'), findsOneWidget);
      expect(find.text('Hafen von Taleria, Station 2 · 11 von 20 falsch (55 %)'), findsOneWidget);
      expect(find.text(AdminTexts.noQuestionStats), findsOneWidget, reason: 'keine leichten Fragen');
    });
  });

  group('Support', () {
    late FakeAdminAuth auth;
    late FakeAdminRepository repository;

    Future<void> openSupport(WidgetTester tester) async {
      auth = FakeAdminAuth(enrolled: {'chefin@test.invalid'});
      repository = FakeAdminRepository(auth);
      await pumpAdminApp(tester, auth: auth, repository: repository);
      await signIn(tester);
      await enterCode(tester, FakeAdminAuth.validCode);
      await tester.tap(find.byKey(const ValueKey('nav-support')));
      await tester.pumpAndSettle();
    }

    Future<void> search(WidgetTester tester, String email, String reason) async {
      await tester.enterText(find.byKey(const ValueKey('support-email')), email);
      await tester.enterText(find.byKey(const ValueKey('support-reason')), reason);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('support-search')));
      await tester.pumpAndSettle();
    }

    FilledButton searchButton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byKey(const ValueKey('support-search')));

    testWidgets('Suchen nur mit Grund, ohne Treffer und mit Treffer', (tester) async {
      await openSupport(tester);
      await tester.enterText(find.byKey(const ValueKey('support-email')), 'familie@test.invalid');
      await tester.enterText(find.byKey(const ValueKey('support-reason')), 'kurz');
      await tester.pump();
      expect(searchButton(tester).onPressed, isNull, reason: 'Grund zu kurz');

      await search(tester, 'niemand@test.invalid', 'Anfrage per E-Mail');
      expect(find.text(AdminTexts.notFound), findsOneWidget);

      await search(tester, 'Familie@test.invalid', 'Anfrage per E-Mail');
      expect(find.text('familie@test.invalid'), findsWidgets);
      expect(find.text(AdminTexts.familyChildren(2)), findsOneWidget);
      expect(find.text(AdminTexts.familyPremium(false)), findsOneWidget);
      expect(repository.audit.map((e) => e.action), ['family.view', 'family.search']);
      expect(repository.audit.first.reason, 'Anfrage per E-Mail');
    });

    testWidgets('Abo von Hand vergeben und wieder entfernen', (tester) async {
      await openSupport(tester);
      await search(tester, 'familie@test.invalid', 'Beta-Familie');

      await tester.tap(find.byKey(const ValueKey('support-grant')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('duration-unlimited')));
      await tester.pump();
      expect(find.text('Beta-Familie'), findsWidgets, reason: 'Grund der Suche ist vorbelegt');
      await tester.tap(find.byKey(const ValueKey('dialog-confirm')));
      await tester.pumpAndSettle();

      expect(find.text(AdminTexts.familyPremium(true)), findsOneWidget);
      expect(find.text('· von Hand, ohne Ablauf'), findsOneWidget);
      expect(repository.audit.map((e) => e.action), contains('premium.grant'));

      await tester.tap(find.byKey(const ValueKey('support-revoke')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('dialog-reason')), 'Beta beendet');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('dialog-confirm')));
      await tester.pumpAndSettle();
      expect(find.text(AdminTexts.familyPremium(false)), findsOneWidget);
      expect(repository.audit.first.action, 'family.view', reason: 'nach der Änderung neu geladen');
      expect(repository.audit[1].action, 'premium.revoke');
      expect(repository.audit[1].reason, 'Beta beendet');
    });

    testWidgets('Konto löschen nur mit eingetippter E-Mail', (tester) async {
      await openSupport(tester);
      await search(tester, 'familie@test.invalid', 'Löschwunsch per E-Mail');

      await tester.tap(find.byKey(const ValueKey('support-delete')));
      await tester.pumpAndSettle();
      FilledButton confirm() => tester.widget<FilledButton>(find.byKey(const ValueKey('dialog-confirm')));
      expect(confirm().onPressed, isNull);
      await tester.enterText(find.byKey(const ValueKey('dialog-confirm-email')), 'andere@test.invalid');
      await tester.pump();
      expect(confirm().onPressed, isNull);
      await tester.enterText(find.byKey(const ValueKey('dialog-confirm-email')), 'FAMILIE@test.invalid');
      await tester.pump();
      expect(confirm().onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('dialog-confirm')));
      await tester.pumpAndSettle();

      expect(find.text(AdminTexts.deleted), findsOneWidget);
      expect(repository.families, isEmpty);
      expect(repository.audit.first.action, 'family.delete');
      expect(repository.audit.first.reason, 'Löschwunsch per E-Mail');

      await tester.tap(find.byKey(const ValueKey('nav-audit')));
      await tester.pumpAndSettle();
      expect(find.textContaining(AdminTexts.auditAction('family.delete')), findsOneWidget);
      expect(find.textContaining('Löschwunsch per E-Mail'), findsWidgets);
    });
  });

  testWidgets('Fehlerprotokoll der App mit Stack zum Aufklappen', (tester) async {
    final auth = FakeAdminAuth(enrolled: {'chefin@test.invalid'});
    await pumpAdminApp(tester, auth: auth, repository: FakeAdminRepository(auth));
    await signIn(tester);
    await enterCode(tester, FakeAdminAuth.validCode);
    await tester.tap(find.byKey(const ValueKey('nav-errors')));
    await tester.pumpAndSettle();

    expect(find.text('Null check operator used on a null value'), findsOneWidget);
    expect(find.textContaining('ios · 3× an 2 Tagen'), findsOneWidget);
    await tester.tap(find.text('Null check operator used on a null value'));
    await tester.pumpAndSettle();
    expect(find.textContaining('#0 IslandMapScreen.build'), findsOneWidget);
  });
}
