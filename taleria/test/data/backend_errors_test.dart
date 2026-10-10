import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/data/backend_errors.dart';
import 'package:taleria/domain/family_models.dart';

void main() {
  tearDown(() => onUnexpectedBackendError = null);

  test('Unerwartete Daten vom Server: Fehlermeldung statt Absturz, und gemeldet', () async {
    final reported = <Object>[];
    onUnexpectedBackendError = (error, _) => reported.add(error);
    final Map<String, dynamic> row = {'sort_order': null};

    await expectLater(
      guardBackend(() async => row['sort_order'] as int),
      throwsA(isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.unknown)),
    );
    expect(reported.single, isA<TypeError>());
  });

  test('Fehler der App selbst bleiben, wie sie sind', () async {
    await expectLater(
      guardBackend<void>(() async => throw const AppFailure(FailureKind.noWind)),
      throwsA(isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.noWind)),
    );
  });
}
