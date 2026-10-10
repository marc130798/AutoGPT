// Erzeugt aus den Inhaltsdateien in content/stufe1/ und content/begegnungen.json:
//   * supabase/seed.sql          Testumgebung (mit Inhalts-Vorschau und Test-Abo)
//   * supabase/inhalte_live.sql  geprüfter Import für die Live-Datenbank
//
// Aufruf im Ordner taleria/:
//   dart run tool/build_seed.dart
//
// Bricht mit einer Liste der Probleme ab, wenn eine Inhaltsdatei gegen die
// Regeln verstößt (zum Beispiel zu kleiner Fragenpool).
import 'dart:convert';
import 'dart:io';

import 'content/content_model.dart';

void main() {
  final islands = loadIslands(Directory('content/stufe1'));
  final manifest = jsonDecode(File('assets/asset_manifest.json').readAsStringSync()) as Map<String, dynamic>;
  final keys = (manifest['assets'] as Map<String, dynamic>).keys.toSet();

  final encounters = parseEncounters('begegnungen.json', File('content/begegnungen.json').readAsStringSync());
  final problems = [
    ...validateIslands(islands, knownAssetKeys: keys),
    ...validateEncounters(encounters, islands: islands, knownAssetKeys: keys),
  ];
  if (problems.isNotEmpty) {
    stderr.writeln('Die Inhalte haben ${problems.length} Problem(e):');
    for (final p in problems) {
      stderr.writeln('  - $p');
    }
    exitCode = 1;
    return;
  }

  File('supabase/seed.sql').writeAsStringSync(buildSeedSql(islands, encounters: encounters));
  File('supabase/inhalte_live.sql')
      .writeAsStringSync(buildSeedSql(islands, encounters: encounters, target: SeedTarget.live));
  final questions = islands.expand((i) => i.stations).expand((s) => s.questions).length;
  final stops = islands.expand((i) => i.seaStops).toList();
  final released = islands.where((i) => i.status == 'freigegeben').map((i) => i.title);
  stdout
    ..writeln(
      'supabase/seed.sql und supabase/inhalte_live.sql erzeugt: '
      '${islands.length} Inseln, $questions Fragen, ${stops.length} Stopps auf See '
      '(${stops.expand((s) => s.questions).length} Fragen), ${encounters.length} Begegnung(en).',
    )
    ..writeln('Freigegeben: ${released.isEmpty ? 'noch nichts' : released.join(', ')}');
}
