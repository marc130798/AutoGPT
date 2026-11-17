/// Die Logbücher zum Ausdrucken (Ordner `logbuch/`): je Insel ein Heft mit
/// Aufgaben fürs echte Leben und einem Schatzcode für die Werft
/// (`logbookCodes` in shipyard.dart). In der Web-Version liegen die PDFs unter
/// `logbuch/logbuch_<insel>.pdf` neben der App (tool/build_test_web.sh).
class Logbook {
  const Logbook({required this.island, required this.title});

  /// Insel, zum Beispiel `hafen`.
  final String island;

  /// Name der Insel, so wie er auf dem Heft steht.
  final String title;

  /// Pfad der PDF-Datei neben der App.
  String get path => 'logbuch/logbuch_$island.pdf';
}

/// In der Reihenfolge der Reise.
const logbooks = [
  Logbook(island: 'hafen', title: 'Hafen von Taleria'),
  Logbook(island: 'tauschinsel', title: 'Tauschinsel'),
  Logbook(island: 'wunschinsel', title: 'Wunschinsel'),
  Logbook(island: 'spar-insel', title: 'Spar-Insel'),
  Logbook(island: 'taschengeld-bucht', title: 'Taschengeld-Bucht'),
];
