import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/data/error_log_repository.dart';
import 'package:taleria/services/error_reporting.dart';

class FakeErrorLog implements ErrorLogRepository {
  bool signedIn = true;
  bool fail = false;
  final reports = <({String platform, String error, String? stack})>[];

  @override
  bool get canReport => signedIn;

  @override
  Future<void> reportError({required String platform, required String error, String? stack}) async {
    if (fail) throw Exception('offline');
    reports.add((platform: platform, error: error, stack: stack));
  }
}

void main() {
  late FakeErrorLog log;
  late AppErrorReporter reporter;

  setUp(() {
    log = FakeErrorLog();
    reporter = AppErrorReporter(log, platform: 'ios', maxReports: 3);
  });

  test('Meldet Fehlertext, gekürzten Stack und Plattform', () async {
    final stack = StackTrace.fromString(List.generate(40, (i) => '#$i zeile $i').join('\n'));
    await reporter.report(StateError('kaputt'), stack);
    final report = log.reports.single;
    expect(report.platform, 'ios');
    expect(report.error, 'StateError: Bad state: kaputt');
    expect(report.stack!.split('\n'), hasLength(AppErrorReporter.stackLines));
  });

  test('Derselbe Fehler nur einmal, höchstens maxReports Meldungen', () async {
    for (var i = 0; i < 3; i++) {
      await reporter.report(StateError('gleich'), null);
    }
    expect(log.reports, hasLength(1));
    for (var i = 0; i < 5; i++) {
      await reporter.report(StateError('anders $i'), null);
    }
    expect(log.reports, hasLength(3));
  });

  test('Ohne Anmeldung nichts, und ein Fehler beim Melden stört nicht', () async {
    log.signedIn = false;
    await reporter.report(StateError('a'), null);
    expect(log.reports, isEmpty);
    log
      ..signedIn = true
      ..fail = true;
    await expectLater(reporter.report(StateError('b'), null), completes);
  });

  test('Lange Fehlertexte werden gekürzt', () {
    expect(AppErrorReporter.describe(Exception('x' * 900)).length, 500);
  });

  test('Plattform wie in der Datenbank', () {
    expect(AppErrorReporter.platformName(isWeb: false, target: TargetPlatform.iOS), 'ios');
    expect(AppErrorReporter.platformName(isWeb: false, target: TargetPlatform.android), 'android');
    expect(AppErrorReporter.platformName(isWeb: false, target: TargetPlatform.macOS), 'other');
    expect(AppErrorReporter.platformName(isWeb: true), 'web');
  });
}
