import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/error_log_repository.dart';

/// Meldet unerwartete Fehler der App an das eigene Fehlerprotokoll (Beta, Schritt 11).
///
/// Datenschutz: Gemeldet werden nur Fehlertext, gekürzter Stack und die Plattform
/// (ios, android). Kein Nutzer, kein Gerät, kein Drittanbieter. Jeder Fehler höchstens
/// einmal pro App-Start, höchstens [maxReports] Meldungen. Ein Fehler beim Melden
/// stört nie.
class AppErrorReporter {
  AppErrorReporter(this._log, {required this.platform, this.maxReports = 20});

  final ErrorLogRepository _log;
  final String platform;
  final int maxReports;
  final _sent = <String>{};

  /// Höchstens so viele Zeilen des Stacks.
  static const stackLines = 25;

  /// ios, android, web oder other (wie in der Datenbank).
  static String platformName({bool isWeb = kIsWeb, TargetPlatform? target}) {
    if (isWeb) return 'web';
    return switch (target ?? defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'other',
    };
  }

  static String describe(Object error) {
    final text = '${error.runtimeType}: $error';
    return text.length <= 500 ? text : text.substring(0, 500);
  }

  static String? shortStack(StackTrace? stack) {
    if (stack == null) return null;
    final lines = stack.toString().split('\n').where((l) => l.trim().isNotEmpty).take(stackLines).toList();
    return lines.isEmpty ? null : lines.join('\n');
  }

  Future<void> report(Object error, StackTrace? stack) async {
    if (!_log.canReport) return;
    final message = describe(error);
    final trace = shortStack(stack);
    final key = '$message|${trace?.split('\n').first}';
    if (_sent.length >= maxReports || !_sent.add(key)) return;
    try {
      await _log.reportError(platform: platform, error: message, stack: trace);
    } catch (_) {
      // Melden ist zweitrangig; die App läuft weiter.
    }
  }
}

/// Fängt Fehler aus Flutter und aus asynchronem Code ab und meldet sie.
/// Das bisherige Verhalten (Ausgabe in der Konsole) bleibt.
void installErrorReporting(AppErrorReporter reporter) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    previous?.call(details);
    unawaited(reporter.report(details.exception, details.stack));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(reporter.report(error, stack));
    return false;
  };
}
