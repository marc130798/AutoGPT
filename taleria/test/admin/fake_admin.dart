import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/admin/admin_app.dart';
import 'package:taleria/admin/admin_scope.dart';
import 'package:taleria/admin/data/admin_auth.dart';
import 'package:taleria/admin/data/admin_failure.dart';
import 'package:taleria/admin/data/admin_repository.dart';
import 'package:taleria/admin/domain/admin_models.dart';
import 'package:taleria/admin/services/admin_session.dart';
import 'package:taleria/core/config/app_config.dart';

/// Nachbau der Supabase-Anmeldung mit Zwei-Faktor. Der richtige Code ist immer 123456.
class FakeAdminAuth implements AdminAuth {
  FakeAdminAuth({this.accounts = const {'chefin@test.invalid': 'geheim123'}, this.enrolled = const {}});

  final Map<String, String> accounts;

  /// Konten, die schon eine Zwei-Faktor-App haben.
  final Set<String> enrolled;
  final _enrolled = <String>{};

  static const validCode = '123456';

  String? email;
  bool aal2 = false;
  int setups = 0;

  bool _isEnrolled(String email) => enrolled.contains(email) || _enrolled.contains(email);

  @override
  bool get hasSession => email != null;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (accounts[email.trim()] != password) throw const AdminFailure(AdminFailureKind.invalidCredentials);
    this.email = email.trim();
    aal2 = false;
  }

  @override
  Future<void> signOut() async {
    email = null;
    aal2 = false;
  }

  @override
  Future<MfaStatus> mfaStatus() async {
    if (aal2) return MfaStatus.done;
    return _isEnrolled(email!) ? MfaStatus.verify : MfaStatus.enroll;
  }

  @override
  Future<TotpSetup> startTotpSetup() async {
    setups++;
    return const TotpSetup(
      factorId: 'faktor-1',
      secret: 'JBSWY3DPEHPK3PXPJBSW',
      uri: 'otpauth://totp/Taleria:chefin@test.invalid?secret=JBSWY3DPEHPK3PXPJBSW&issuer=Taleria',
    );
  }

  @override
  Future<void> confirmTotpSetup(TotpSetup setup, String code) async {
    if (code != validCode) throw const AdminFailure(AdminFailureKind.invalidCode);
    _enrolled.add(email!);
    aal2 = true;
  }

  @override
  Future<void> verifyTotp(String code) async {
    if (code != validCode) throw const AdminFailure(AdminFailureKind.invalidCode);
    aal2 = true;
  }
}

/// Nachbau der Admin-Funktionen der Datenbank, mit denselben Rollen-Regeln.
class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository(this.auth, {this.roles = const {'chefin@test.invalid': AdminRole.owner}});

  final FakeAdminAuth auth;
  final Map<String, AdminRole> roles;

  EnvironmentSettings settings = const EnvironmentSettings();
  final audit = <AuditEntry>[];
  final families = <String, FamilyInfo>{
    'familie@test.invalid': FamilyInfo(
      parentId: 'p0000000-0000-0000-0000-000000000001',
      email: 'familie@test.invalid',
      createdAt: DateTime.utc(2026, 10, 1),
      consentAt: DateTime.utc(2026, 10, 1),
      consentVersion: '2026-10',
      children: 2,
      lastActiveAt: DateTime.utc(2026, 10, 9),
      premium: false,
    ),
  };

  AdminRole _require(Set<AdminRole> allowed) {
    final role = roles[auth.email];
    if (role == null || !auth.aal2 || !allowed.contains(role)) {
      throw const AdminFailure(AdminFailureKind.notAllowed, 'Nur für Admins mit Zwei-Faktor-Anmeldung');
    }
    return role;
  }

  void _log(String action, String? target, String reason) {
    if (reason.trim().length < 5) {
      throw const AdminFailure(AdminFailureKind.rejected, 'Bitte einen Grund angeben (mindestens 5 Zeichen)');
    }
    audit.insert(
      0,
      AuditEntry(
        createdAt: DateTime.utc(2026, 10, 10, 12),
        adminEmail: auth.email,
        adminRole: roles[auth.email],
        action: action,
        targetType: 'parent',
        targetId: target,
        reason: reason.trim(),
      ),
    );
  }

  @override
  Future<AdminIdentity?> whoami() async {
    final role = roles[auth.email];
    if (auth.email == null || role == null) return null;
    return AdminIdentity(role: role, mfa: auth.aal2, email: auth.email);
  }

  @override
  Future<AdminOverview> overview() async {
    _require({AdminRole.owner});
    return const AdminOverview(
      families: 12,
      familiesNew7d: 3,
      familiesNew28d: 9,
      children: 17,
      childrenOnboarded: 15,
      childrenActive7d: 8,
      childrenActive28d: 14,
      premiumFamilies: 4,
      premiumStore: 1,
      premiumManual: 2,
      premiumTest: 1,
      childrenWithAllowance: 6,
      tasksApproved28d: 21,
    );
  }

  @override
  Future<ContentStats> contentStats(int stage) async {
    _require({AdminRole.owner, AdminRole.editor});
    return ContentStats(
      stage: stage,
      childrenOnboarded: 15,
      islands: [
        IslandStats(
          id: 'i1',
          slug: 'hafen',
          title: 'Hafen von Taleria',
          sortOrder: 1,
          routeType: 'main',
          status: ContentStatus.published,
          premium: false,
          questions: 60,
          reached: 15,
          completed: 9,
          stations: const [
            StationStats(
              id: 's1',
              number: 1,
              title: 'Willkommen an Bord',
              type: 'practice',
              status: ContentStatus.published,
              isRequired: true,
              questions: 0,
              done: 15,
            ),
            StationStats(
              id: 's2',
              number: 2,
              title: 'Was ist Geld?',
              type: 'quiz',
              status: ContentStatus.published,
              isRequired: true,
              questions: 10,
              done: 12,
            ),
          ],
        ),
        const IslandStats(
          id: 'i4',
          slug: 'spar-insel',
          title: 'Spar-Insel',
          sortOrder: 4,
          routeType: 'main',
          status: ContentStatus.draft,
          premium: true,
          questions: 0,
          reached: 0,
          completed: 0,
          stations: [],
        ),
      ],
      hardest: const [
        QuestionStats(
          id: 'q1',
          question: 'Was ist Inflation?',
          island: 'Hafen von Taleria',
          stationNumber: 2,
          stationType: 'quiz',
          answered: 20,
          wrong: 11,
        ),
      ],
      easiest: const [],
    );
  }

  @override
  Future<EnvironmentSettings> environmentSettings() async => settings;

  @override
  Future<FamilyInfo?> findFamily({required String email, required String reason}) async {
    _require({AdminRole.owner, AdminRole.support});
    final family = families[email.trim().toLowerCase()];
    _log(family == null ? 'family.search' : 'family.view', family?.parentId, reason);
    return family;
  }

  @override
  Future<bool> setPremium({
    required String parentId,
    required bool active,
    required String reason,
    DateTime? validUntil,
  }) async {
    _require({AdminRole.owner});
    final entry = families.entries.firstWhere((e) => e.value.parentId == parentId);
    _log(active ? 'premium.grant' : 'premium.revoke', parentId, reason);
    final old = entry.value;
    families[entry.key] = FamilyInfo(
      parentId: old.parentId,
      email: old.email,
      createdAt: old.createdAt,
      consentAt: old.consentAt,
      consentVersion: old.consentVersion,
      children: old.children,
      lastActiveAt: old.lastActiveAt,
      premium: active,
      entitlements: active ? [EntitlementInfo(source: 'manual', validUntil: validUntil)] : const [],
    );
    return active;
  }

  @override
  Future<void> deleteFamily({required String parentId, required String reason}) async {
    _require({AdminRole.owner});
    _log('family.delete', parentId, reason);
    families.removeWhere((_, f) => f.parentId == parentId);
  }

  @override
  Future<List<AuditEntry>> auditLog({int limit = 100}) async {
    _require({AdminRole.owner});
    return audit.take(limit).toList();
  }
}

/// Baut den Adminbereich für Widget-Tests.
Future<AdminSession> pumpAdminApp(
  WidgetTester tester, {
  required FakeAdminAuth auth,
  required FakeAdminRepository repository,
  AppEnvironment environment = AppEnvironment.test,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final session = AdminSession(auth: auth, repository: repository);
  await session.start();
  await tester.pumpWidget(
    AdminApp(
      services: AdminServices(
        config: AppConfig(
          environment: environment,
          supabaseUrl: 'https://test.supabase.co',
          supabasePublishableKey: 'sb_publishable_test',
        ),
        session: session,
        repository: repository,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return session;
}

Future<void> signIn(WidgetTester tester, {String email = 'chefin@test.invalid', String password = 'geheim123'}) async {
  await tester.enterText(find.byKey(const ValueKey('admin-email')), email);
  await tester.enterText(find.byKey(const ValueKey('admin-password')), password);
  await tester.tap(find.byKey(const ValueKey('admin-sign-in')));
  await tester.pumpAndSettle();
}

Future<void> enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byKey(const ValueKey('mfa-code')), code);
  await tester.ensureVisible(find.byKey(const ValueKey('mfa-confirm')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('mfa-confirm')));
  await tester.pumpAndSettle();
}
