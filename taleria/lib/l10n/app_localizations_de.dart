// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Taleria';

  @override
  String get homeWelcome => 'Willkommen an Bord!';

  @override
  String get homeSubtitle => 'Talo und Tala warten schon im Hafen auf dich.';

  @override
  String get homeShowIntro => 'Intro ansehen';

  @override
  String get homeShowAssets => 'Alle Platzhalter ansehen';

  @override
  String get videoComingSoon => 'Film folgt';

  @override
  String get continueButton => 'Weiter';

  @override
  String get assetGalleryTitle => 'Grafiken und Filme';

  @override
  String get assetGalleryHint => 'Grau umrandet = Platzhalter, die echte Datei fehlt noch.';

  @override
  String assetGalleryCount(int available, int total) {
    return '$available von $total Dateien vorhanden';
  }

  @override
  String get assetManifestError => 'Die Liste der Grafiken konnte nicht geladen werden.';

  @override
  String get environmentTest => 'Testumgebung';

  @override
  String get environmentLive => 'Live';

  @override
  String get backendNotConfigured => 'Ohne Server (keine Zugangsdaten eingetragen)';

  @override
  String get backendChecking => 'Verbindung wird geprüft …';

  @override
  String get backendReady => 'Server verbunden, Datenbank bereit';

  @override
  String get backendSchemaMissing => 'Server verbunden, aber die Tabellen fehlen noch';

  @override
  String get backendUnreachable => 'Server nicht erreichbar';
}
