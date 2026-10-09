import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Jeder Text in app_de.arb hat eine Beschreibung', () {
    final arb = jsonDecode(File('lib/l10n/app_de.arb').readAsStringSync()) as Map<String, dynamic>;
    final keys = arb.keys.where((k) => !k.startsWith('@'));
    for (final key in keys) {
      expect(arb['@$key'], isA<Map<String, dynamic>>(), reason: '$key braucht "@$key"');
      expect((arb['@$key'] as Map)['description'], isNotEmpty, reason: '$key braucht eine Beschreibung');
    }
  });
}
