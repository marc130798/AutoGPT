import 'package:web/web.dart' as web;

/// Öffnet eine Datei neben der App (zum Beispiel ein Logbuch-PDF) in einem
/// neuen Tab. Nur für den Elternbereich. Gibt `true` zurück, wenn es geht.
/// Die App bleibt im alten Tab offen; zurück geht es über „Fertig“ (iPhone)
/// oder durch Schließen des Tabs.
bool openFileNextToApp(String path) {
  web.window.open(path, '_blank');
  return true;
}

/// Lädt eine Datei neben der App herunter (Logbuch-PDF zum Speichern oder
/// Drucken). Auf dem iPhone öffnet Safari dafür die Vorschau mit „Teilen“.
bool downloadFileNextToApp(String path, String fileName) {
  final link = web.HTMLAnchorElement()
    ..href = path
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(link);
  link.click();
  link.remove();
  return true;
}
