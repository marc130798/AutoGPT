import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/content/setup_sql.dart';

void main() {
  test('supabase/datenbank_einrichten.sql ist aktuell (sonst: dart run tool/build_setup_sql.dart)', () {
    expect(
      File('supabase/datenbank_einrichten.sql').readAsStringSync(),
      buildSetupSql(Directory('supabase/migrations')),
    );
  });
}
