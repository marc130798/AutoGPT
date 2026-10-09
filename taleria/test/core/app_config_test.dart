import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('Ohne Zugangsdaten: Testumgebung ohne Server', () {
      final config = AppConfig.fromValues(environment: 'test', supabaseUrl: '', supabasePublishableKey: '');
      expect(config.environment, AppEnvironment.test);
      expect(config.isTest, isTrue);
      expect(config.hasBackend, isFalse);
    });

    test('Mit Zugangsdaten: Server ist eingerichtet', () {
      final config = AppConfig.fromValues(
        environment: 'test',
        supabaseUrl: ' https://abc.supabase.co ',
        supabasePublishableKey: 'sb_publishable_123',
      );
      expect(config.hasBackend, isTrue);
      expect(config.supabaseUrl, 'https://abc.supabase.co');
    });

    test('Live ohne Zugangsdaten wird abgelehnt', () {
      expect(
        () => AppConfig.fromValues(environment: 'live', supabaseUrl: '', supabasePublishableKey: ''),
        throwsArgumentError,
      );
    });

    test('Unbekannte Umgebung wird abgelehnt', () {
      expect(
        () => AppConfig.fromValues(environment: 'staging', supabaseUrl: '', supabasePublishableKey: ''),
        throwsArgumentError,
      );
    });

    test('Server-Adresse muss https sein (außer lokal)', () {
      expect(
        () => AppConfig.fromValues(
          environment: 'test',
          supabaseUrl: 'http://abc.supabase.co',
          supabasePublishableKey: 'x',
        ),
        throwsArgumentError,
      );
      final local = AppConfig.fromValues(
        environment: 'test',
        supabaseUrl: 'http://127.0.0.1:54321',
        supabasePublishableKey: 'x',
      );
      expect(local.hasBackend, isTrue);
    });
  });
}
