import 'package:web/web.dart' as web;

/// Öffnet eine Datei neben der App (zum Beispiel ein Logbuch-PDF) in einem
/// neuen Tab. Nur für den Elternbereich. Gibt `true` zurück, wenn es geht.
bool openFileNextToApp(String path) {
  web.window.open(path, '_blank');
  return true;
}
