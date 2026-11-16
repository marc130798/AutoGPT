/// Außerhalb des Browsers liegen die Logbücher nicht neben der App. Dann sagt
/// der Leuchtturm, dass sie in der Web-Version zu finden sind.
bool openFileNextToApp(String path) => false;

/// Außerhalb des Browsers gibt es keinen Download neben der App.
bool downloadFileNextToApp(String path, String fileName) => false;
