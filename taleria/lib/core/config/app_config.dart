/// Einstellungen, die beim Bauen der App festgelegt werden.
///
/// Die Werte kommen aus einer JSON-Datei, die beim Start übergeben wird:
///
///     flutter run --dart-define-from-file=env/test.json
///
/// Die Dateien `env/test.json` und `env/live.json` enthalten Zugangsdaten
/// und stehen deshalb in `.gitignore`. Vorlagen: `env/*.example.json`.
library;

enum AppEnvironment {
  test,
  live;

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'test' => AppEnvironment.test,
      'live' => AppEnvironment.live,
      _ => throw ArgumentError.value(value, 'TALERIA_ENV', 'Erlaubt sind nur "test" und "live"'),
    };
  }
}

class AppConfig {
  const AppConfig({required this.environment, required this.supabaseUrl, required this.supabasePublishableKey});

  /// Liest die Werte, die mit `--dart-define-from-file` übergeben wurden.
  /// Ohne Datei startet die App in der Testumgebung ohne Server.
  factory AppConfig.fromEnvironment() {
    return AppConfig.fromValues(
      environment: const String.fromEnvironment('TALERIA_ENV', defaultValue: 'test'),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    );
  }

  factory AppConfig.fromValues({
    required String environment,
    required String supabaseUrl,
    required String supabasePublishableKey,
  }) {
    final config = AppConfig(
      environment: AppEnvironment.parse(environment),
      supabaseUrl: supabaseUrl.trim(),
      supabasePublishableKey: supabasePublishableKey.trim(),
    );
    final url = config.supabaseUrl;
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      final isLocal = uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '10.0.2.2');
      if (uri == null || !uri.hasAuthority || (uri.scheme != 'https' && !isLocal)) {
        throw ArgumentError.value(url, 'SUPABASE_URL', 'Muss eine https-Adresse sein');
      }
    }
    // Die Live-App muss immer mit einem Server laufen.
    if (config.environment == AppEnvironment.live && !config.hasBackend) {
      throw ArgumentError('Live-Umgebung braucht SUPABASE_URL und SUPABASE_PUBLISHABLE_KEY');
    }
    return config;
  }

  final AppEnvironment environment;
  final String supabaseUrl;

  /// Öffentlicher Schlüssel (publishable key, beginnt mit sb_publishable_).
  /// Er darf in die App,
  /// weil die Datenbank alle Rechte per Row Level Security prüft.
  /// Der geheime service_role-Schlüssel kommt NIE in die App.
  final String supabasePublishableKey;

  bool get isTest => environment == AppEnvironment.test;

  bool get hasBackend => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
