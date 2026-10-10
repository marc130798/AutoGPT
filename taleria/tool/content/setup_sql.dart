/// Baut aus den Migrationen eine einzige SQL-Datei zum Einrichten eines neuen
/// Supabase-Projekts im SQL Editor (ohne Kommandozeile).
library;

import 'dart:io';

String buildSetupSql(Directory migrations) {
  final files = migrations.listSync().whereType<File>().where((f) => f.path.endsWith('.sql')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final b = StringBuffer()
    ..writeln('-- Taleria: Datenbank in einem NEUEN, LEEREN Supabase-Projekt einrichten.')
    ..writeln('-- Automatisch erzeugt aus supabase/migrations/ mit: dart run tool/build_setup_sql.dart')
    ..writeln('-- Nicht von Hand ändern. Nur einmal pro Projekt ausführen.')
    ..writeln('--')
    ..writeln('-- So geht es: Im Supabase-Dashboard den SQL Editor öffnen, den ganzen Inhalt')
    ..writeln('-- dieser Datei einfügen und auf „Run“ klicken. Läuft etwas schief, wird nichts')
    ..writeln('-- gespeichert (alles in einem Durchgang).')
    ..writeln()
    ..writeln('begin;')
    ..writeln();
  final versions = <(String, String)>[];
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final version = name.split('_').first;
    versions.add((version, name.substring(version.length + 1, name.length - 4)));
    b
      ..writeln('-- ===========================================================================')
      ..writeln('-- Migration $name')
      ..writeln('-- ===========================================================================')
      ..writeln()
      ..writeln(file.readAsStringSync().trimRight())
      ..writeln();
  }
  b
    ..writeln('-- ===========================================================================')
    ..writeln('-- Liste der Supabase CLI: diese Migrationen sind eingespielt')
    ..writeln('-- ===========================================================================')
    ..writeln()
    ..writeln('create schema if not exists supabase_migrations;')
    ..writeln('create table if not exists supabase_migrations.schema_migrations (version text not null primary key);')
    ..writeln('alter table supabase_migrations.schema_migrations add column if not exists statements text[];')
    ..writeln('alter table supabase_migrations.schema_migrations add column if not exists name text;')
    ..writeln('insert into supabase_migrations.schema_migrations (version, name) values');
  for (final (i, (version, name)) in versions.indexed) {
    b.writeln("  ('$version', '$name')${i == versions.length - 1 ? '' : ','}");
  }
  b
    ..writeln('on conflict (version) do nothing;')
    ..writeln()
    ..writeln('commit;');
  return b.toString();
}
