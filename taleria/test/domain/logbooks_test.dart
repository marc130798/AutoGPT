import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/logbooks.dart';
import 'package:taleria/domain/shipyard.dart';

/// Jedes Logbuch hat sein PDF (für die Web-Version), ein Vorschaubild und einen Schatzcode.
void main() {
  test('Logbücher passen zu den Schatzcodes und den Dateien', () {
    expect(logbooks.map((b) => b.island).toSet(), logbookCodes.values.toSet());
    for (final book in logbooks) {
      expect(File('logbuch/web/logbuch_${book.island}.pdf').existsSync(), isTrue, reason: book.path);
      expect(File('assets/images/logbook.${book.island}.jpg').existsSync(), isTrue, reason: book.island);
    }
  });
}
