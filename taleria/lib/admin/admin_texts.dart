/// Texte des Adminbereichs.
///
/// Der Adminbereich ist nur für das Taleria-Team und nur auf Deutsch. Seine
/// Texte stehen deshalb hier und nicht in lib/l10n/app_de.arb, damit sie nicht
/// in die Kinder- und Eltern-App gelangen.
library;

import 'data/admin_failure.dart';
import 'domain/admin_models.dart';

abstract final class AdminTexts {
  static const appTitle = 'Taleria Admin';

  // Start ohne Server
  static const noBackendTitle = 'Kein Server eingetragen';
  static const noBackendBody =
      'Der Adminbereich braucht die Zugangsdaten der Datenbank. '
      'Start mit: flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env/test.json';

  // Anmeldung
  static const loginTitle = 'Anmeldung für das Taleria-Team';
  static const loginHint = 'Nur für Admin-Konten. Eltern melden sich in der App an.';
  static const email = 'E-Mail';
  static const password = 'Passwort';
  static const signIn = 'Anmelden';
  static const signOut = 'Abmelden';

  static const notAdminTitle = 'Kein Admin-Zugang';
  static const notAdminBody =
      'Dieses Konto ist kein Admin-Konto. Admin-Konten legt der Owner im SQL Editor von Supabase an '
      '(siehe README, „Adminbereich“).';
  static const backToLogin = 'Zurück zur Anmeldung';

  // Zwei-Faktor
  static const mfaSetupTitle = 'Zwei-Faktor-Anmeldung einrichten';
  static const mfaSetupBody =
      'Für den Adminbereich ist eine Zwei-Faktor-App Pflicht (zum Beispiel Google Authenticator, '
      'Microsoft Authenticator oder 1Password). Lege dort einen neuen Eintrag an und tippe diesen '
      'Schlüssel ein (Art: zeitbasiert):';
  static const mfaSecretLabel = 'Schlüssel';
  static const mfaLinkLabel = 'Oder diesen Link in der App öffnen:';
  static const mfaCopy = 'Kopieren';
  static const mfaCopied = 'Kopiert';
  static const mfaSetupCodeHint = 'Danach den 6-stelligen Code aus der App eingeben:';
  static const mfaVerifyTitle = 'Code aus der Zwei-Faktor-App';
  static const mfaVerifyBody = 'Bitte den aktuellen 6-stelligen Code aus deiner Zwei-Faktor-App eingeben.';
  static const mfaCode = 'Code';
  static const mfaConfirm = 'Bestätigen';

  // Kopf und Navigation
  static const overview = 'Übersicht';
  static const content = 'Inhalte';
  static const support = 'Support';
  static const auditLog = 'Protokoll';
  static const appErrors = 'Fehler';
  static const reload = 'Neu laden';
  static const environmentTest = 'TESTUMGEBUNG';
  static const environmentLive = 'LIVE';
  static const testSettingsInTest =
      'Testumgebung: Kinder sehen auch Entwürfe, Eltern können das Abo testweise einschalten.';
  static const testSettingsInLive =
      'Achtung: In dieser Live-Datenbank sind Test-Einstellungen aktiv (Inhalts-Vorschau oder Test-Abo). '
      'Bitte sofort in der Tabelle app_settings löschen. supabase/seed.sql gehört nie in die Live-Datenbank.';

  static String role(AdminRole role) => switch (role) {
    AdminRole.owner => 'Owner',
    AdminRole.editor => 'Redaktion',
    AdminRole.support => 'Support',
  };

  // Übersicht
  static const families = 'Familien';
  static const children = 'Kinder-Profile';
  static const activeChildren = 'Aktive Kinder';
  static const subscriptions = 'Abos';
  static const budget = 'Taschengeld und Aufgaben';
  static String newFamilies(int week, int month) => 'neu: $week in 7 Tagen, $month in 28 Tagen';
  static String onboarded(int count) => '$count mit abgeschlossenem Intro';
  static String active(int week, int month) => '$week in 7 Tagen, $month in 28 Tagen';
  static String premium(int store, int manual, int test) => 'Store: $store, von Hand: $manual, Test: $test';
  static String budgetUsage(int allowance, int tasks) =>
      'Taschengeld eingerichtet: $allowance\nAufgaben bestätigt (28 Tage): $tasks';
  static const returnWeek1 = 'Rückkehr nach 1 Woche';
  static const returnWeek4 = 'Rückkehr nach 4 Wochen';
  static String percentOrDash(int? percent) => percent == null ? '–' : '$percent %';
  static String returned(int returned, int cohort, int days) => cohort == 0
      ? 'Noch niemand ist $days Tage dabei.'
      : '$returned von $cohort Kindern, die seit mindestens $days Tagen dabei sind';
  static const appErrors7d = 'Fehler in der App';
  static String appErrorsDetail(int count) => count == 0 ? 'keine in 7 Tagen' : 'Meldungen in 7 Tagen';
  static const overviewNote =
      'Nur zusammengefasste Zahlen, keine Einzelprofile von Kindern. Aktiv heißt: Station, Begegnung '
      'oder Wiederholung. Rückkehr: Das Kind öffnet die App in Woche 2 (Tag 7 bis 13) oder Woche 5 '
      '(Tag 28 bis 34) nach seinem ersten Tag wieder. Gemessen wird seit Schritt 11, nur tageweise.';

  // Inhalte
  static String stage(int stage) => 'Stufe $stage';
  static String contentStatus(ContentStatus status) => switch (status) {
    ContentStatus.draft => 'Entwurf',
    ContentStatus.review => 'Prüfung',
    ContentStatus.published => 'Veröffentlicht',
  };
  static const fog = 'Nebel';
  static const free = 'Gratis';
  static const premiumIsland = 'Abo';
  static String islandLine(int questions, int reached, int completed) =>
      '$questions Fragen · erreicht von $reached · abgeschlossen von $completed';
  static String stationLabel(StationStats s) {
    final kind = s.isDive
        ? 'Ankerplatz'
        : s.isExam
        ? 'Prüfung'
        : 'Station';
    final number = s.number == null || s.isExam ? '' : ' ${s.number}';
    final bonus = s.isRequired ? '' : ' (Bonus)';
    return '$kind$number$bonus: ${s.title}';
  }

  static String stationLine(StationStats s) => '${contentStatus(s.status)} · ${s.questions} Fragen';
  static String stationDone(StationStats s, int? drop) {
    final done = drop == null || drop <= 0 ? 'geschafft von ${s.done}' : 'geschafft von ${s.done} (−$drop)';
    return s.started == 0 ? done : 'begonnen von ${s.started} · $done';
  }

  static String onboardedChildren(int count) => '$count Kinder haben das Intro abgeschlossen.';
  static const hardest = 'Schwierigste Fragen';
  static const easiest = 'Leichteste Fragen';
  static const noQuestionStats = 'Noch zu wenige Antworten (ab 5 Antworten pro Frage).';
  static String questionStats(QuestionStats q) {
    final where = q.stationType == 'exam'
        ? 'Prüfung'
        : q.stationType == 'review_stop'
        ? 'Ankerplatz'
        : 'Station ${q.stationNumber ?? '?'}';
    return '${q.island}, $where · ${q.wrong} von ${q.answered} falsch (${q.wrongPercent} %)';
  }

  static const contentNote =
      'Inhalte ändern: in den Inhaltsdateien (content/stufe1) mit „status“ entwurf, pruefung oder freigegeben. '
      'Daraus entstehen supabase/seed.sql (Testumgebung) und supabase/inhalte_live.sql (Live-Datenbank). '
      'Der Rückgang von Station zu Station zeigt, wo Kinder aufhören oder auf Wind warten. '
      '„Begonnen“ wird seit Schritt 11 gemessen; begonnen, aber nicht geschafft heißt: abgebrochen oder noch dabei.';

  // Support
  static const supportHint =
      'Jede Suche und jede Änderung braucht einen Grund und landet im Protokoll. '
      'Angezeigt wird nur, was der Support braucht: keine Spitznamen, keine Lerndaten.';
  static const reason = 'Grund (zum Beispiel „Anfrage per E-Mail vom 10.10.“)';
  static const reasonTooShort = 'Bitte einen Grund angeben (mindestens 5 Zeichen).';
  static const search = 'Suchen';
  static const notFound = 'Kein Eltern-Konto mit dieser E-Mail.';
  static const deleted = 'Das Konto wurde mit allen Daten gelöscht.';
  static String familyCreated(String date) => 'Angelegt am $date';
  static String familyConsent(String? version, String? date) =>
      'Einwilligung: ${version ?? '–'}${date == null ? '' : ' am $date'}';
  static String familyMarketing(bool on) => on ? 'Newsletter: ja' : 'Newsletter: nein';
  static String familyChildren(int count) => 'Kinder-Profile: $count';
  static String familyLastActive(String? date) => 'Zuletzt aktiv: ${date ?? 'noch nie'}';
  static String familyPremium(bool on) => on ? 'Abo: aktiv' : 'Abo: Basis (kostenlos)';
  static String entitlement(EntitlementInfo e, String? until) {
    final source = switch (e.source) {
      'revenuecat' => 'Store',
      'manual' => 'von Hand',
      'test' => 'Test',
      _ => e.source,
    };
    return '$source, ${until == null ? 'ohne Ablauf' : 'bis $until'}';
  }

  static const grantPremium = 'Abo von Hand vergeben';
  static const revokePremium = 'Abo von Hand entfernen';
  static const deleteFamily = 'Konto löschen';
  static const grantTitle = 'Abo von Hand vergeben';
  static const grantBody = 'Zum Beispiel für Beta-Familien. Käufe im Store bleiben davon unberührt.';
  static String duration(ManualPremiumDuration d) => switch (d) {
    ManualPremiumDuration.oneMonth => '1 Monat',
    ManualPremiumDuration.threeMonths => '3 Monate',
    ManualPremiumDuration.oneYear => '1 Jahr',
    ManualPremiumDuration.unlimited => 'Ohne Ablauf',
  };
  static const revokeTitle = 'Abo von Hand entfernen';
  static const revokeBody = 'Die Familie behält nur ein Abo aus dem Store, falls sie eins hat.';
  static const deleteTitle = 'Konto endgültig löschen?';
  static const deleteBody =
      'Gelöscht werden das Eltern-Konto, alle Kinder-Profile, Fortschritt, Taschengeld und Aufgaben. '
      'Die Kinder-Geräte werden abgemeldet. Das lässt sich nicht rückgängig machen. '
      'Zur Bestätigung die E-Mail-Adresse eintippen:';
  static const deleteConfirm = 'Endgültig löschen';
  static const cancel = 'Abbrechen';
  static const save = 'Speichern';

  // Protokoll
  static const auditEmpty = 'Noch keine Einträge.';
  static String auditAction(String action) => switch (action) {
    'family.view' => 'Familie angesehen',
    'family.search' => 'Suche ohne Treffer',
    'premium.grant' => 'Abo von Hand vergeben',
    'premium.revoke' => 'Abo von Hand entfernt',
    'family.delete' => 'Konto gelöscht',
    _ => action,
  };
  static String auditWho(AuditEntry e) =>
      '${e.adminEmail ?? 'unbekannt'}${e.adminRole == null ? '' : ' (${role(e.adminRole!)})'}';
  static String auditTarget(AuditEntry e) => e.targetId == null ? '' : ' · Konto ${e.targetId!.substring(0, 8)}';

  // Fehlerprotokoll der App
  static const appErrorsEmpty = 'Keine Fehler in den letzten 14 Tagen.';
  static const appErrorsNote =
      'Fehler, die die App selbst gemeldet hat: nur Fehlertext, gekürzter Stack und Plattform, '
      'ohne Nutzer und ohne Gerät. Gespeichert 90 Tage.';
  static String appErrorLine(AppErrorInfo e) =>
      '${e.platform} · ${e.total}× an ${e.days} ${e.days == 1 ? 'Tag' : 'Tagen'} · zuletzt ${dateTime(e.lastSeenAt)}';

  // Fehler
  static String failure(AdminFailure failure) => switch (failure.kind) {
    AdminFailureKind.invalidCredentials => 'E-Mail oder Passwort stimmt nicht.',
    AdminFailureKind.invalidCode => 'Der Code stimmt nicht. Bitte den aktuellen Code aus der App eingeben.',
    AdminFailureKind.notAllowed => 'Dafür fehlt die Berechtigung.',
    AdminFailureKind.rejected => failure.message,
    AdminFailureKind.notFound => 'Nicht gefunden. Vielleicht wurde das Konto schon gelöscht.',
    AdminFailureKind.network => 'Keine Verbindung zum Server. Bitte später noch einmal versuchen.',
    AdminFailureKind.unknown => 'Das hat nicht geklappt. (${failure.message})',
  };

  static String date(DateTime date) {
    final local = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year}';
  }

  static String dateTime(DateTime date) {
    final local = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${AdminTexts.date(local)}, ${two(local.hour)}:${two(local.minute)}';
  }
}
