/// Daten des Adminbereichs (CLAUDE.md Abschnitt 10). Ohne Aussehen, ohne Supabase.
/// Alle Rechte prüft die Datenbank; die Rollen hier steuern nur, was die Seite zeigt.
library;

/// Rollen im Adminbereich: owner (alles), editor (nur Inhalte), support (Konten einsehen).
enum AdminRole {
  owner('owner'),
  editor('editor'),
  support('support');

  const AdminRole(this.code);

  final String code;

  static AdminRole? parse(Object? code) {
    for (final role in values) {
      if (role.code == code) return role;
    }
    return null;
  }

  /// Zahlen zu Familien, Kindern und Abos.
  bool get seesOverview => this == owner;

  /// Inhalte und ihre Statistik.
  bool get seesContent => this == owner || this == editor;

  /// Familien suchen.
  bool get seesSupport => this == owner || this == support;

  /// Abo von Hand vergeben oder entfernen, Konto löschen.
  bool get changesFamilies => this == owner;

  bool get seesAuditLog => this == owner;
}

/// Wer ist angemeldet (admin_whoami())?
class AdminIdentity {
  const AdminIdentity({required this.role, required this.mfa, this.email});

  /// `null`, wenn die Rolle unbekannt ist.
  static AdminIdentity? fromJson(Map<String, dynamic>? json) {
    final role = AdminRole.parse(json?['role']);
    if (json == null || role == null) return null;
    return AdminIdentity(role: role, mfa: json['mfa'] as bool? ?? false, email: json['email'] as String?);
  }

  final AdminRole role;

  /// Zwei-Faktor-Anmeldung erfolgt? Erst dann gelten die Admin-Rechte.
  final bool mfa;
  final String? email;
}

/// Neue Zwei-Faktor-App einrichten: Schlüssel zum Abtippen und Link für die App.
class TotpSetup {
  const TotpSetup({required this.factorId, required this.secret, required this.uri});

  final String factorId;
  final String secret;
  final String uri;

  /// Schlüssel in Vierergruppen, damit er sich leichter abtippen lässt.
  String get groupedSecret {
    final clean = secret.replaceAll(' ', '');
    final groups = <String>[];
    for (var i = 0; i < clean.length; i += 4) {
      groups.add(clean.substring(i, i + 4 > clean.length ? clean.length : i + 4));
    }
    return groups.join(' ');
  }
}

/// Stand der Zwei-Faktor-Anmeldung nach dem Passwort.
enum MfaStatus {
  /// Noch keine Zwei-Faktor-App eingerichtet.
  enroll,

  /// App eingerichtet, Code fehlt noch.
  verify,

  /// Mit Zwei-Faktor angemeldet.
  done,
}

int _int(Object? value) => (value as num?)?.toInt() ?? 0;
DateTime? _date(Object? value) => value == null ? null : DateTime.parse(value as String);

/// Zahlen für die Übersicht (admin_overview(), nur owner).
class AdminOverview {
  const AdminOverview({
    required this.families,
    required this.familiesNew7d,
    required this.familiesNew28d,
    required this.children,
    required this.childrenOnboarded,
    required this.childrenActive7d,
    required this.childrenActive28d,
    required this.premiumFamilies,
    required this.premiumStore,
    required this.premiumManual,
    required this.premiumTest,
    required this.childrenWithAllowance,
    required this.tasksApproved28d,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) => AdminOverview(
    families: _int(json['families']),
    familiesNew7d: _int(json['families_new_7d']),
    familiesNew28d: _int(json['families_new_28d']),
    children: _int(json['children']),
    childrenOnboarded: _int(json['children_onboarded']),
    childrenActive7d: _int(json['children_active_7d']),
    childrenActive28d: _int(json['children_active_28d']),
    premiumFamilies: _int(json['premium_families']),
    premiumStore: _int(json['premium_revenuecat']),
    premiumManual: _int(json['premium_manual']),
    premiumTest: _int(json['premium_test']),
    childrenWithAllowance: _int(json['children_with_allowance']),
    tasksApproved28d: _int(json['tasks_approved_28d']),
  );

  final int families;
  final int familiesNew7d;
  final int familiesNew28d;
  final int children;
  final int childrenOnboarded;
  final int childrenActive7d;
  final int childrenActive28d;

  /// Familien mit gültigem Abo, egal woher.
  final int premiumFamilies;

  /// Gekauft im App Store oder bei Google Play (RevenueCat).
  final int premiumStore;

  /// Vom Team vergeben (zum Beispiel Beta-Familien).
  final int premiumManual;

  /// Test-Abo (nur Testumgebung).
  final int premiumTest;
  final int childrenWithAllowance;
  final int tasksApproved28d;
}

/// Status eines Inhalts (draft, review, published).
enum ContentStatus {
  draft,
  review,
  published;

  static ContentStatus parse(Object? value) =>
      values.firstWhere((s) => s.name == value, orElse: () => ContentStatus.draft);
}

class StationStats {
  const StationStats({
    required this.id,
    required this.number,
    required this.title,
    required this.type,
    required this.status,
    required this.isRequired,
    required this.questions,
    required this.done,
  });

  factory StationStats.fromJson(Map<String, dynamic> json) => StationStats(
    id: json['id'] as String,
    number: (json['number'] as num?)?.toInt(),
    title: json['title'] as String? ?? '',
    type: json['type'] as String? ?? '',
    status: ContentStatus.parse(json['status']),
    isRequired: json['is_required'] as bool? ?? true,
    questions: _int(json['questions']),
    done: _int(json['done']),
  );

  final String id;
  final int? number;
  final String title;
  final String type;
  final ContentStatus status;
  final bool isRequired;
  final int questions;

  /// So viele Kinder haben die Station geschafft.
  final int done;

  bool get isDive => type == 'review_stop';
  bool get isExam => type == 'exam';
}

class IslandStats {
  const IslandStats({
    required this.id,
    required this.slug,
    required this.title,
    required this.sortOrder,
    required this.routeType,
    required this.status,
    required this.premium,
    required this.questions,
    required this.reached,
    required this.completed,
    required this.stations,
    this.publishAt,
  });

  factory IslandStats.fromJson(Map<String, dynamic> json) => IslandStats(
    id: json['id'] as String,
    slug: json['slug'] as String,
    title: json['title'] as String? ?? '',
    sortOrder: _int(json['sort_order']),
    routeType: json['route_type'] as String? ?? 'main',
    status: ContentStatus.parse(json['status']),
    publishAt: _date(json['publish_at']),
    premium: json['access'] == 'premium',
    questions: _int(json['questions']),
    reached: _int(json['reached']),
    completed: _int(json['completed']),
    stations: [
      for (final s in (json['stations'] as List?) ?? const []) StationStats.fromJson(s as Map<String, dynamic>),
    ],
  );

  final String id;
  final String slug;
  final String title;
  final int sortOrder;
  final String routeType;
  final ContentStatus status;
  final DateTime? publishAt;
  final bool premium;
  final int questions;

  /// So viele Kinder haben mindestens eine Station der Insel geschafft.
  final int reached;
  final int completed;
  final List<StationStats> stations;

  /// Noch keine Stationen: liegt im Nebel.
  bool get inFog => stations.isEmpty;
}

class QuestionStats {
  const QuestionStats({
    required this.id,
    required this.question,
    required this.island,
    required this.answered,
    required this.wrong,
    this.stationNumber,
    this.stationType,
  });

  factory QuestionStats.fromJson(Map<String, dynamic> json) => QuestionStats(
    id: json['id'] as String,
    question: json['question'] as String? ?? '',
    island: json['island'] as String? ?? '',
    stationNumber: (json['station_number'] as num?)?.toInt(),
    stationType: json['station_type'] as String?,
    answered: _int(json['answered']),
    wrong: _int(json['wrong']),
  );

  final String id;
  final String question;
  final String island;
  final int? stationNumber;
  final String? stationType;
  final int answered;
  final int wrong;

  /// Anteil falscher Antworten in Prozent (gerundet).
  int get wrongPercent => answered == 0 ? 0 : (wrong * 100 / answered).round();
}

/// Inhalte und ihre Statistik (admin_content_stats(), owner und editor).
class ContentStats {
  const ContentStats({
    required this.stage,
    required this.childrenOnboarded,
    required this.islands,
    required this.hardest,
    required this.easiest,
  });

  factory ContentStats.fromJson(Map<String, dynamic> json) {
    List<QuestionStats> questions(Object? raw) => [
      for (final q in (raw as List?) ?? const []) QuestionStats.fromJson(q as Map<String, dynamic>),
    ];
    return ContentStats(
      stage: _int(json['stage']),
      childrenOnboarded: _int(json['children_onboarded']),
      islands: [
        for (final i in (json['islands'] as List?) ?? const []) IslandStats.fromJson(i as Map<String, dynamic>),
      ],
      hardest: questions(json['hardest_questions']),
      easiest: questions(json['easiest_questions']),
    );
  }

  final int stage;
  final int childrenOnboarded;
  final List<IslandStats> islands;
  final List<QuestionStats> hardest;
  final List<QuestionStats> easiest;
}

class EntitlementInfo {
  const EntitlementInfo({required this.source, this.validUntil});

  factory EntitlementInfo.fromJson(Map<String, dynamic> json) =>
      EntitlementInfo(source: json['source'] as String? ?? '', validUntil: _date(json['valid_until']));

  /// revenuecat, manual oder test
  final String source;

  /// `null` = ohne Ablauf.
  final DateTime? validUntil;

  bool get isManual => source == 'manual';
}

/// Eltern-Konto im Supportfall (admin_find_family()). Keine Spitznamen, keine Lerndaten.
class FamilyInfo {
  const FamilyInfo({
    required this.parentId,
    required this.email,
    required this.createdAt,
    required this.children,
    required this.premium,
    this.consentAt,
    this.consentVersion,
    this.marketingConsent = false,
    this.lastActiveAt,
    this.entitlements = const [],
  });

  factory FamilyInfo.fromJson(Map<String, dynamic> json) => FamilyInfo(
    parentId: json['parent_id'] as String,
    email: json['email'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String),
    consentAt: _date(json['consent_at']),
    consentVersion: json['consent_version'] as String?,
    marketingConsent: json['marketing_consent'] as bool? ?? false,
    children: _int(json['children']),
    lastActiveAt: _date(json['last_active_at']),
    premium: json['premium'] as bool? ?? false,
    entitlements: [
      for (final e in (json['entitlements'] as List?) ?? const []) EntitlementInfo.fromJson(e as Map<String, dynamic>),
    ],
  );

  final String parentId;
  final String email;
  final DateTime createdAt;
  final DateTime? consentAt;
  final String? consentVersion;
  final bool marketingConsent;
  final int children;
  final DateTime? lastActiveAt;
  final bool premium;
  final List<EntitlementInfo> entitlements;

  bool get hasManualPremium => entitlements.any((e) => e.isManual);
}

/// Ein Eintrag im Audit-Log.
class AuditEntry {
  const AuditEntry({
    required this.createdAt,
    required this.action,
    required this.targetType,
    required this.reason,
    this.adminEmail,
    this.adminRole,
    this.targetId,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
    createdAt: DateTime.parse(json['created_at'] as String),
    adminEmail: json['admin_email'] as String?,
    adminRole: AdminRole.parse(json['admin_role']),
    action: json['action'] as String? ?? '',
    targetType: json['target_type'] as String? ?? '',
    targetId: json['target_id'] as String?,
    reason: json['reason'] as String? ?? '',
  );

  final DateTime createdAt;
  final String? adminEmail;
  final AdminRole? adminRole;

  /// family.view, family.search, premium.grant, premium.revoke, family.delete
  final String action;
  final String targetType;
  final String? targetId;
  final String reason;
}

/// Einstellungen der Datenbank, die nur in die Testumgebung gehören.
class EnvironmentSettings {
  const EnvironmentSettings({this.contentPreview = false, this.testPurchases = false});

  factory EnvironmentSettings.fromRows(List<Map<String, dynamic>> rows) {
    bool on(String key) => rows.any((r) => r['key'] == key && r['value'] == true);
    return EnvironmentSettings(contentPreview: on('content_preview'), testPurchases: on('test_purchases'));
  }

  /// Kinder sehen auch Entwürfe.
  final bool contentPreview;

  /// Eltern können das Abo testweise einschalten.
  final bool testPurchases;

  bool get anyTestSetting => contentPreview || testPurchases;
}

/// Wie lange ein Abo von Hand gilt.
enum ManualPremiumDuration {
  oneMonth(30),
  threeMonths(91),
  oneYear(365),
  unlimited(null);

  const ManualPremiumDuration(this.days);

  final int? days;

  /// Ablaufdatum ab [now], `null` = ohne Ablauf.
  DateTime? validUntil(DateTime now) => days == null ? null : now.add(Duration(days: days!));
}
