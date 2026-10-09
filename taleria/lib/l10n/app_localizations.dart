import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de')];

  /// Name der App
  ///
  /// In de, this message translates to:
  /// **'Taleria'**
  String get appTitle;

  /// Begrüßung auf dem Startbildschirm
  ///
  /// In de, this message translates to:
  /// **'Willkommen an Bord!'**
  String get homeWelcome;

  /// Unterzeile auf dem Startbildschirm
  ///
  /// In de, this message translates to:
  /// **'Talo und Tala warten schon im Hafen auf dich.'**
  String get homeSubtitle;

  /// Knopf, der den Intro-Film öffnet
  ///
  /// In de, this message translates to:
  /// **'Intro ansehen'**
  String get homeShowIntro;

  /// Knopf zur Übersicht aller Grafiken (nur Testumgebung)
  ///
  /// In de, this message translates to:
  /// **'Alle Platzhalter ansehen'**
  String get homeShowAssets;

  /// Text auf dem Standbild, solange ein Film fehlt
  ///
  /// In de, this message translates to:
  /// **'Film folgt'**
  String get videoComingSoon;

  /// Allgemeiner Weiter-Knopf
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get continueButton;

  /// Titel der Übersicht aller Grafiken
  ///
  /// In de, this message translates to:
  /// **'Grafiken und Filme'**
  String get assetGalleryTitle;

  /// Erklärung oben in der Grafik-Übersicht
  ///
  /// In de, this message translates to:
  /// **'Grau umrandet = Platzhalter, die echte Datei fehlt noch.'**
  String get assetGalleryHint;

  /// Zählt, wie viele echte Dateien es schon gibt
  ///
  /// In de, this message translates to:
  /// **'{available} von {total} Dateien vorhanden'**
  String assetGalleryCount(int available, int total);

  /// Fehlermeldung, wenn das Asset-Manifest kaputt ist
  ///
  /// In de, this message translates to:
  /// **'Die Liste der Grafiken konnte nicht geladen werden.'**
  String get assetManifestError;

  /// Hinweis-Schild: App läuft gegen die Test-Datenbank
  ///
  /// In de, this message translates to:
  /// **'Testumgebung'**
  String get environmentTest;

  /// Hinweis-Schild: App läuft gegen die Live-Datenbank
  ///
  /// In de, this message translates to:
  /// **'Live'**
  String get environmentLive;

  /// Status: App läuft ohne Supabase
  ///
  /// In de, this message translates to:
  /// **'Ohne Server (keine Zugangsdaten eingetragen)'**
  String get backendNotConfigured;

  /// Status: Verbindung zu Supabase wird geprüft
  ///
  /// In de, this message translates to:
  /// **'Verbindung wird geprüft …'**
  String get backendChecking;

  /// Status: Supabase erreichbar und Tabellen vorhanden
  ///
  /// In de, this message translates to:
  /// **'Server verbunden, Datenbank bereit'**
  String get backendReady;

  /// Status: Supabase erreichbar, Migrationen nicht eingespielt
  ///
  /// In de, this message translates to:
  /// **'Server verbunden, aber die Tabellen fehlen noch'**
  String get backendSchemaMissing;

  /// Status: Supabase antwortet nicht
  ///
  /// In de, this message translates to:
  /// **'Server nicht erreichbar'**
  String get backendUnreachable;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
