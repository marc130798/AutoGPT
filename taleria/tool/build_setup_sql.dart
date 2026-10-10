// Fügt alle Migrationen zu einer Datei zusammen: supabase/datenbank_einrichten.sql
//
// Damit lässt sich ein NEUES, LEERES Supabase-Projekt ohne Kommandozeile
// einrichten: Datei im SQL Editor einfügen und ausführen. Die Datei trägt die
// Migrationen auch in die Liste der Supabase CLI ein, damit später
// `npx supabase db push` nur neue Migrationen nachholt.
//
// Aufruf im Ordner taleria/:
//   dart run tool/build_setup_sql.dart
import 'dart:io';

import 'content/setup_sql.dart';

void main() {
  File('supabase/datenbank_einrichten.sql').writeAsStringSync(buildSetupSql(Directory('supabase/migrations')));
  stdout.writeln('supabase/datenbank_einrichten.sql erzeugt.');
}
