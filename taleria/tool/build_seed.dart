// Erzeugt supabase/seed.sql aus den Inhaltsdateien in content/stufe1/.
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

  final problems = validateIslands(islands, knownAssetKeys: keys);
  if (problems.isNotEmpty) {
    stderr.writeln('Die Inhalte haben ${problems.length} Problem(e):');
    for (final p in problems) {
      stderr.writeln('  - $p');
    }
    exitCode = 1;
    return;
  }

  File('supabase/seed.sql').writeAsStringSync(buildSeedSql(islands));
  final questions = islands.expand((i) => i.stations).expand((s) => s.questions).length;
  stdout.writeln('supabase/seed.sql erzeugt: ${islands.length} Inseln, $questions Fragen.');
}
