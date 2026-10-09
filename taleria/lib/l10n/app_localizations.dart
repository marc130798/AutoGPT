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

  /// Abbrechen-Knopf in Dialogen
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// OK-Knopf in Hinweisen
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// Speichern-Knopf
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get saveButton;

  /// Knopf, um einen fehlgeschlagenen Vorgang zu wiederholen
  ///
  /// In de, this message translates to:
  /// **'Noch einmal versuchen'**
  String get retryButton;

  /// Knopf zum Abmelden
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get signOutButton;

  /// Pflicht-Hinweis (CLAUDE.md Abschnitt 9)
  ///
  /// In de, this message translates to:
  /// **'Taleria ist ein Lernspiel und keine Finanzberatung. Alle Beträge sind virtuell.'**
  String get noFinancialAdvice;

  /// Fehler: kein Netz
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung zum Server. Bitte prüfe das Internet und versuche es noch einmal.'**
  String get failureNetwork;

  /// Fehler: falsche Anmeldedaten
  ///
  /// In de, this message translates to:
  /// **'E-Mail oder Passwort stimmt nicht.'**
  String get failureInvalidCredentials;

  /// Fehler: E-Mail noch nicht bestätigt
  ///
  /// In de, this message translates to:
  /// **'Bitte bestätige zuerst deine E-Mail-Adresse. Den Link findest du in unserer E-Mail.'**
  String get failureEmailNotConfirmed;

  /// Fehler: E-Mail schon registriert
  ///
  /// In de, this message translates to:
  /// **'Für diese E-Mail-Adresse gibt es schon ein Konto. Bitte melde dich an.'**
  String get failureEmailTaken;

  /// Fehler: Passwort vom Server abgelehnt
  ///
  /// In de, this message translates to:
  /// **'Dieses Passwort ist zu leicht zu erraten. Bitte wähle ein anderes.'**
  String get failureWeakPassword;

  /// Fehler: zu viele Anfragen
  ///
  /// In de, this message translates to:
  /// **'Zu viele Versuche. Bitte warte kurz und versuche es dann noch einmal.'**
  String get failureRateLimited;

  /// Fehler: keine Berechtigung
  ///
  /// In de, this message translates to:
  /// **'Das ist mit diesem Konto nicht erlaubt.'**
  String get failureNotAllowed;

  /// Fehler: unbekannt
  ///
  /// In de, this message translates to:
  /// **'Da ist etwas schiefgegangen. Bitte versuche es noch einmal.'**
  String get failureUnknown;

  /// Überschrift auf dem Startbildschirm ohne Anmeldung
  ///
  /// In de, this message translates to:
  /// **'Willkommen in Taleria'**
  String get welcomeTitle;

  /// Unterzeile auf dem Startbildschirm ohne Anmeldung
  ///
  /// In de, this message translates to:
  /// **'Lerne mit Talo und Tala, gut mit Geld umzugehen.'**
  String get welcomeSubtitle;

  /// Knopf für Kinder: Anmeldecode eingeben
  ///
  /// In de, this message translates to:
  /// **'Ich habe einen Code'**
  String get welcomeChildButton;

  /// Knopf für Eltern
  ///
  /// In de, this message translates to:
  /// **'Für Eltern: anmelden oder registrieren'**
  String get welcomeParentButton;

  /// Hinweis, wenn keine Server-Zugangsdaten eingetragen sind
  ///
  /// In de, this message translates to:
  /// **'Ohne Server gibt es noch keine Konten. Du kannst dir die Vorschau ansehen.'**
  String get welcomeOfflineHint;

  /// Knopf zur Vorschau, wenn kein Server eingerichtet ist
  ///
  /// In de, this message translates to:
  /// **'Vorschau ohne Konto'**
  String get welcomeOfflinePreview;

  /// Titel des Bildschirms für Eltern-Anmeldung und -Registrierung
  ///
  /// In de, this message translates to:
  /// **'Eltern-Konto'**
  String get parentAuthTitle;

  /// Reiter: neues Eltern-Konto
  ///
  /// In de, this message translates to:
  /// **'Registrieren'**
  String get parentAuthRegisterTab;

  /// Reiter: bestehendes Eltern-Konto
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get parentAuthLoginTab;

  /// Feld für die E-Mail-Adresse
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get emailLabel;

  /// Feld für das Passwort
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get passwordLabel;

  /// Hinweis unter dem Passwortfeld
  ///
  /// In de, this message translates to:
  /// **'Mindestens {min} Zeichen'**
  String passwordHint(int min);

  /// Fehler: E-Mail leer
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deine E-Mail-Adresse ein.'**
  String get emailEmpty;

  /// Fehler: E-Mail ungültig
  ///
  /// In de, this message translates to:
  /// **'Diese E-Mail-Adresse sieht nicht richtig aus.'**
  String get emailInvalid;

  /// Fehler: Passwort zu kurz
  ///
  /// In de, this message translates to:
  /// **'Das Passwort braucht mindestens {min} Zeichen.'**
  String passwordTooShort(int min);

  /// Pflicht-Einwilligung bei der Registrierung. ENTWURF, rechtlich prüfen. Bei Änderung consentVersion hochzählen.
  ///
  /// In de, this message translates to:
  /// **'Ich bin einverstanden, dass Taleria meine Daten und die Daten meines Kindes gemäß der Datenschutzerklärung verarbeitet. (Pflicht)'**
  String get consentLabel;

  /// Fehler: Einwilligung fehlt
  ///
  /// In de, this message translates to:
  /// **'Ohne diese Einwilligung können wir kein Konto anlegen.'**
  String get consentRequired;

  /// Freiwillige Newsletter-Einwilligung, nie vorausgewählt (MARKETING.md)
  ///
  /// In de, this message translates to:
  /// **'Ich möchte etwa einmal im Monat per E-Mail erfahren, was es Neues in Taleria gibt. (freiwillig, jederzeit abbestellbar)'**
  String get marketingLabel;

  /// Knopf: registrieren
  ///
  /// In de, this message translates to:
  /// **'Konto anlegen'**
  String get registerButton;

  /// Knopf: anmelden
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get loginButton;

  /// Überschrift nach der Registrierung, wenn die E-Mail bestätigt werden muss
  ///
  /// In de, this message translates to:
  /// **'Fast geschafft!'**
  String get checkEmailTitle;

  /// Text nach der Registrierung, wenn die E-Mail bestätigt werden muss
  ///
  /// In de, this message translates to:
  /// **'Wir haben dir eine E-Mail geschickt. Bitte bestätige deine Adresse und melde dich dann hier an.'**
  String get checkEmailBody;

  /// Titel: PIN festlegen
  ///
  /// In de, this message translates to:
  /// **'Eltern-PIN festlegen'**
  String get setPinTitle;

  /// Erklärung beim Festlegen der PIN
  ///
  /// In de, this message translates to:
  /// **'Mit dieser PIN öffnest du auf diesem Gerät den Leuchtturm, den Bereich für Eltern. Dein Kind sollte sie nicht kennen.'**
  String get setPinBody;

  /// Feld für die PIN
  ///
  /// In de, this message translates to:
  /// **'PIN (4 bis 6 Ziffern)'**
  String get pinLabel;

  /// Feld zum Wiederholen der PIN
  ///
  /// In de, this message translates to:
  /// **'PIN wiederholen'**
  String get pinRepeatLabel;

  /// Fehler: PIN-Format
  ///
  /// In de, this message translates to:
  /// **'Die PIN besteht aus 4 bis 6 Ziffern.'**
  String get pinFormat;

  /// Fehler: PIN zu einfach
  ///
  /// In de, this message translates to:
  /// **'Diese PIN ist zu leicht zu erraten, zum Beispiel 1111 oder 1234.'**
  String get pinTooSimple;

  /// Fehler: PINs stimmen nicht überein
  ///
  /// In de, this message translates to:
  /// **'Die beiden PINs sind nicht gleich.'**
  String get pinMismatch;

  /// Knopf: PIN speichern
  ///
  /// In de, this message translates to:
  /// **'PIN speichern'**
  String get pinSaveButton;

  /// Text der PIN-Abfrage vor dem Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'Bitte gib die Eltern-PIN ein.'**
  String get pinGateBody;

  /// Knopf: Leuchtturm mit PIN öffnen
  ///
  /// In de, this message translates to:
  /// **'Öffnen'**
  String get pinGateUnlock;

  /// Fehler: falsche PIN
  ///
  /// In de, this message translates to:
  /// **'Die PIN stimmt nicht.'**
  String get pinWrong;

  /// Fehler: PIN gesperrt
  ///
  /// In de, this message translates to:
  /// **'Zu viele Versuche. Du kannst es um {time} Uhr wieder versuchen.'**
  String pinLocked(String time);

  /// Knopf: PIN vergessen
  ///
  /// In de, this message translates to:
  /// **'PIN vergessen? Mit Passwort neu anmelden'**
  String get pinForgot;

  /// Knopf auf der PIN-Abfrage, zurück zum Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'Zurück an Bord'**
  String get pinBackToChild;

  /// Bestätigung nach PIN-Änderung
  ///
  /// In de, this message translates to:
  /// **'Die neue PIN ist gespeichert.'**
  String get pinChanged;

  /// Name des Elternbereichs
  ///
  /// In de, this message translates to:
  /// **'Leuchtturm'**
  String get lighthouseTitle;

  /// Überschrift der Kinderliste im Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'Kinder-Profile'**
  String get lighthouseChildrenHeading;

  /// Hinweis, wenn es noch keine Kinder-Profile gibt
  ///
  /// In de, this message translates to:
  /// **'Noch kein Kinder-Profil. Lege jetzt eins an.'**
  String get lighthouseNoChildren;

  /// Knopf: neues Kinder-Profil
  ///
  /// In de, this message translates to:
  /// **'Kinder-Profil anlegen'**
  String get lighthouseAddChild;

  /// Überschrift Konto-Einstellungen im Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get lighthouseAccountHeading;

  /// Knopf: PIN ändern
  ///
  /// In de, this message translates to:
  /// **'Eltern-PIN ändern'**
  String get lighthouseChangePin;

  /// Knopf: Konto löschen
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get lighthouseDeleteAccount;

  /// Knopf zur Grafik-Übersicht im Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'Grafik-Übersicht (nur Testumgebung)'**
  String get lighthouseShowAssets;

  /// Titel des Löschen-Dialogs für das Konto
  ///
  /// In de, this message translates to:
  /// **'Konto wirklich löschen?'**
  String get deleteAccountTitle;

  /// Text des Löschen-Dialogs für das Konto
  ///
  /// In de, this message translates to:
  /// **'Dein Konto, alle Kinder-Profile und alle Daten werden endgültig gelöscht. Angemeldete Kinder-Geräte werden abgemeldet. Das lässt sich nicht rückgängig machen.'**
  String get deleteAccountBody;

  /// Knopf: endgültig löschen
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get deleteConfirm;

  /// Niveau Einsteiger
  ///
  /// In de, this message translates to:
  /// **'Einsteiger'**
  String get levelBeginner;

  /// Niveau Fortgeschritten
  ///
  /// In de, this message translates to:
  /// **'Fortgeschritten'**
  String get levelAdvanced;

  /// Zeile unter dem Spitznamen in der Kinderliste
  ///
  /// In de, this message translates to:
  /// **'Jahrgang {year} · {level}'**
  String childSubtitle(int year, String level);

  /// Titel: Kinder-Profil anlegen
  ///
  /// In de, this message translates to:
  /// **'Neues Kinder-Profil'**
  String get childFormNewTitle;

  /// Titel: Kinder-Profil bearbeiten
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get childFormEditTitle;

  /// Feld Spitzname
  ///
  /// In de, this message translates to:
  /// **'Spitzname'**
  String get nicknameLabel;

  /// Hinweis zum Spitznamen (Datensparsamkeit)
  ///
  /// In de, this message translates to:
  /// **'Ein Spitzname reicht, ein echter Name ist nicht nötig.'**
  String get nicknameHint;

  /// Fehler: Spitzname zu kurz
  ///
  /// In de, this message translates to:
  /// **'Der Spitzname braucht mindestens 2 Zeichen.'**
  String get nicknameTooShort;

  /// Fehler: Spitzname zu lang
  ///
  /// In de, this message translates to:
  /// **'Der Spitzname darf höchstens 20 Zeichen haben.'**
  String get nicknameTooLong;

  /// Fehler: Spitzname mit ungültigen Zeichen
  ///
  /// In de, this message translates to:
  /// **'Bitte nur Buchstaben, Ziffern, Leerzeichen oder Bindestrich.'**
  String get nicknameInvalid;

  /// Feld Geburtsjahr
  ///
  /// In de, this message translates to:
  /// **'Geburtsjahr'**
  String get birthYearLabel;

  /// Hinweis zum Alter
  ///
  /// In de, this message translates to:
  /// **'Empfohlen ab 10 Jahren. Du entscheidest, wann dein Kind startet.'**
  String get birthYearHint;

  /// Feld Niveau
  ///
  /// In de, this message translates to:
  /// **'Niveau'**
  String get levelLabel;

  /// Überschrift: Code für Kinder-Gerät
  ///
  /// In de, this message translates to:
  /// **'Gerät deines Kindes anmelden'**
  String get childDetailCodeHeading;

  /// Erklärung zum Anmeldecode
  ///
  /// In de, this message translates to:
  /// **'Erzeuge einen Code und gib ihn auf dem Gerät deines Kindes unter „Ich habe einen Code“ ein.'**
  String get childDetailCodeBody;

  /// Knopf: Code erzeugen
  ///
  /// In de, this message translates to:
  /// **'Anmeldecode erzeugen'**
  String get childDetailCreateCode;

  /// Gültigkeit des Codes
  ///
  /// In de, this message translates to:
  /// **'Gültig bis {time} Uhr und nur einmal nutzbar.'**
  String childDetailCodeValid(String time);

  /// Überschrift: Kind spielt auf dem Eltern-Gerät
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Gerät spielen'**
  String get childDetailPlayHereHeading;

  /// Erklärung: Kind spielt auf dem Eltern-Gerät
  ///
  /// In de, this message translates to:
  /// **'Dein Kind spielt auf diesem Gerät. Zurück in den Leuchtturm geht es nur mit deiner PIN.'**
  String get childDetailPlayHereBody;

  /// Knopf: Kinderbereich auf dem Eltern-Gerät öffnen
  ///
  /// In de, this message translates to:
  /// **'Gerät an {nickname} übergeben'**
  String childDetailPlayHereButton(String nickname);

  /// Anzahl der Kinder-Geräte
  ///
  /// In de, this message translates to:
  /// **'Angemeldete Geräte: {count}'**
  String childDetailDevices(int count);

  /// Knopf: Kinder-Geräte abmelden
  ///
  /// In de, this message translates to:
  /// **'Alle Geräte abmelden'**
  String get childDetailSignOutDevices;

  /// Bestätigung: Geräte abgemeldet
  ///
  /// In de, this message translates to:
  /// **'Alle Geräte wurden abgemeldet.'**
  String get childDetailSignedOut;

  /// Knopf: Profil bearbeiten
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get childDetailEdit;

  /// Knopf: Profil löschen
  ///
  /// In de, this message translates to:
  /// **'Profil löschen'**
  String get childDetailDelete;

  /// Titel des Löschen-Dialogs für ein Kinder-Profil
  ///
  /// In de, this message translates to:
  /// **'{nickname} wirklich löschen?'**
  String deleteChildTitle(String nickname);

  /// Text des Löschen-Dialogs für ein Kinder-Profil
  ///
  /// In de, this message translates to:
  /// **'Das Profil und alle Fortschritte werden endgültig gelöscht. Angemeldete Geräte werden abgemeldet.'**
  String get deleteChildBody;

  /// Titel: Code eingeben (Kinderbereich)
  ///
  /// In de, this message translates to:
  /// **'An Bord kommen'**
  String get childCodeTitle;

  /// Erklärung: Code eingeben (Kinderbereich)
  ///
  /// In de, this message translates to:
  /// **'Gib den Code ein, den deine Eltern im Leuchtturm für dich erzeugt haben.'**
  String get childCodeBody;

  /// Feld: Anmeldecode
  ///
  /// In de, this message translates to:
  /// **'Code'**
  String get childCodeLabel;

  /// Knopf: Code einlösen
  ///
  /// In de, this message translates to:
  /// **'An Bord gehen'**
  String get childCodeButton;

  /// Fehler: Code unvollständig
  ///
  /// In de, this message translates to:
  /// **'Der Code hat 8 Zeichen.'**
  String get childCodeIncomplete;

  /// Fehler: Code falsch oder abgelaufen
  ///
  /// In de, this message translates to:
  /// **'Dieser Code passt nicht. Vielleicht ist er schon benutzt oder abgelaufen. Frag deine Eltern nach einem neuen.'**
  String get childCodeInvalid;

  /// Begrüßung im Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'Willkommen an Bord, {nickname}!'**
  String childHomeWelcome(String nickname);

  /// Hinweis auf dem Kinder-Gerät beim Tipp auf den Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'Der Leuchtturm ist der Bereich für deine Eltern. Er öffnet sich auf ihrem Gerät.'**
  String get childHomeLighthouseHint;

  /// Titel: angemeldetes Konto ist kein Eltern-Konto
  ///
  /// In de, this message translates to:
  /// **'Kein Eltern-Konto'**
  String get problemNoParentTitle;

  /// Text: angemeldetes Konto ist kein Eltern-Konto
  ///
  /// In de, this message translates to:
  /// **'Dieses Konto gehört zu keinem Eltern-Konto von Taleria.'**
  String get problemNoParentBody;

  /// Fehler: Passwort leer bei der Anmeldung
  ///
  /// In de, this message translates to:
  /// **'Bitte gib dein Passwort ein.'**
  String get passwordEmpty;

  /// Fehler: kein Geburtsjahr gewählt
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle das Geburtsjahr.'**
  String get birthYearMissing;

  /// Name von Talo über seiner Sprechblase
  ///
  /// In de, this message translates to:
  /// **'Talo'**
  String get speakerTalo;

  /// Name von Tala über ihrer Sprechblase
  ///
  /// In de, this message translates to:
  /// **'Tala'**
  String get speakerTala;

  /// Intro, Szene 1: Talo stellt sich vor (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Ahoi! Ich bin Talo, der Kapitän. Ich habe einen Kompass und meistens einen Plan.'**
  String get introStoryTalo1;

  /// Intro, Szene 2: Tala stellt sich vor (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Und ich bin Tala, die Zahlmeisterin! Ich passe auf unsere Schatztruhe auf. Meistens jedenfalls.'**
  String get introStoryTala1;

  /// Intro, Szene 3: Flaschenpost (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Heute Morgen ist eine Flaschenpost angetrieben. Darin war ein Stück einer alten Schatzkarte!'**
  String get introStoryTalo2;

  /// Intro, Szene 4: Meister Taleron (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Meister Taleron, der Hüter des Meeres, hat die Karte zerrissen und die Teile auf den Inseln versteckt. Nur eine kluge Crew findet den Schatz.'**
  String get introStoryTala2;

  /// Intro, Szene 5: Einladung in die Crew (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Unsere Bordkasse ist leer, und wir brauchen Verstärkung. Willst du in unsere Crew?'**
  String get introStoryTalo3;

  /// Knopf: der Crew beitreten
  ///
  /// In de, this message translates to:
  /// **'Ja, ich bin dabei!'**
  String get introJoinButton;

  /// Knopf: nächste Szene im Intro
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get introNext;

  /// Überschrift Avatar-Baukasten
  ///
  /// In de, this message translates to:
  /// **'Wie siehst du aus?'**
  String get avatarTitle;

  /// Abschnitt im Avatar-Baukasten
  ///
  /// In de, this message translates to:
  /// **'Hautfarbe'**
  String get avatarSkin;

  /// Abschnitt im Avatar-Baukasten
  ///
  /// In de, this message translates to:
  /// **'Frisur'**
  String get avatarHairStyle;

  /// Abschnitt im Avatar-Baukasten
  ///
  /// In de, this message translates to:
  /// **'Haarfarbe'**
  String get avatarHairColor;

  /// Abschnitt im Avatar-Baukasten
  ///
  /// In de, this message translates to:
  /// **'Jacke'**
  String get avatarOutfit;

  /// Abschnitt im Avatar-Baukasten
  ///
  /// In de, this message translates to:
  /// **'Kopfbedeckung'**
  String get avatarHat;

  /// Frisur kurz
  ///
  /// In de, this message translates to:
  /// **'Kurz'**
  String get avatarHairShort;

  /// Frisur lang
  ///
  /// In de, this message translates to:
  /// **'Lang'**
  String get avatarHairLong;

  /// Frisur Locken
  ///
  /// In de, this message translates to:
  /// **'Locken'**
  String get avatarHairCurly;

  /// Frisur Zopf
  ///
  /// In de, this message translates to:
  /// **'Zopf'**
  String get avatarHairBraid;

  /// Keine Haare
  ///
  /// In de, this message translates to:
  /// **'Keine'**
  String get avatarHairNone;

  /// Keine Kopfbedeckung
  ///
  /// In de, this message translates to:
  /// **'Keine'**
  String get avatarHatNone;

  /// Kopfbedeckung Kapitänsmütze
  ///
  /// In de, this message translates to:
  /// **'Kapitänsmütze'**
  String get avatarHatCaptain;

  /// Kopfbedeckung Kopftuch
  ///
  /// In de, this message translates to:
  /// **'Kopftuch'**
  String get avatarHatBandana;

  /// Kopfbedeckung Strohhut
  ///
  /// In de, this message translates to:
  /// **'Strohhut'**
  String get avatarHatStraw;

  /// Vorlesetext für eine Farbauswahl, z. B. „Hautfarbe 3“
  ///
  /// In de, this message translates to:
  /// **'{group} {number}'**
  String avatarColorOption(String group, int number);

  /// Knopf: Avatar speichern
  ///
  /// In de, this message translates to:
  /// **'So sehe ich aus!'**
  String get avatarDone;

  /// Überschrift Schiffstaufe
  ///
  /// In de, this message translates to:
  /// **'Taufe dein Schiff'**
  String get shipTitle;

  /// Tala bei der Schiffstaufe (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Jedes Schiff braucht einen Namen. Wie soll unseres heißen?'**
  String get shipBody;

  /// Feld Schiffsname
  ///
  /// In de, this message translates to:
  /// **'Name des Schiffs'**
  String get shipLabel;

  /// Namensvorschläge für das Schiff, getrennt durch |
  ///
  /// In de, this message translates to:
  /// **'Seestern|Goldmöwe|Wellenreiter|Sturmvogel'**
  String get shipSuggestions;

  /// Knopf: Schiff taufen
  ///
  /// In de, this message translates to:
  /// **'Schiff taufen'**
  String get shipButton;

  /// Fehler: Schiffsname zu kurz
  ///
  /// In de, this message translates to:
  /// **'Der Name braucht mindestens 2 Zeichen.'**
  String get shipNameTooShort;

  /// Fehler: Schiffsname zu lang
  ///
  /// In de, this message translates to:
  /// **'Der Name darf höchstens 30 Zeichen haben.'**
  String get shipNameTooLong;

  /// Überschrift Rundgang
  ///
  /// In de, this message translates to:
  /// **'Rundgang an Bord'**
  String get tourTitle;

  /// Rundgang: Karte
  ///
  /// In de, this message translates to:
  /// **'Die Karte'**
  String get tourMapTitle;

  /// Talo erklärt die Karte (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Auf der Karte siehst du alle Inseln. Jede Insel hat ein Thema und versteckt ein Stück der Schatzkarte.'**
  String get tourMapBody;

  /// Rundgang: Schatztruhe
  ///
  /// In de, this message translates to:
  /// **'Die Schatztruhe'**
  String get tourChestTitle;

  /// Tala erklärt die Schatztruhe (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'In der Schatztruhe sammelst du deine Taler und deine Wunschschätze.'**
  String get tourChestBody;

  /// Rundgang: Logbuch
  ///
  /// In de, this message translates to:
  /// **'Das Logbuch'**
  String get tourLogbookTitle;

  /// Talo erklärt das Logbuch (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Im Logbuch steht, was du schon geschafft hast: Seemeilen, Orden und dein Rang.'**
  String get tourLogbookBody;

  /// Knopf: Rundgang beenden
  ///
  /// In de, this message translates to:
  /// **'Verstanden!'**
  String get tourDone;

  /// Überschrift erster Wunschschatz
  ///
  /// In de, this message translates to:
  /// **'Dein erster Wunschschatz'**
  String get wishTitle;

  /// Tala erklärt den Wunschschatz (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Wofür würdest du gern sparen? Ein Wunschschatz ist etwas, das du dir wünschst und wofür du Taler sammelst.'**
  String get wishBody;

  /// Feld: Titel des Wunschschatzes
  ///
  /// In de, this message translates to:
  /// **'Was wünschst du dir?'**
  String get wishTitleLabel;

  /// Feld: Betrag des Wunschschatzes
  ///
  /// In de, this message translates to:
  /// **'Ungefähr wie viel kostet das? (in Euro)'**
  String get wishAmountLabel;

  /// Hinweis zum Betrag
  ///
  /// In de, this message translates to:
  /// **'Schätzen ist völlig in Ordnung.'**
  String get wishAmountHint;

  /// Knopf: Wunschschatz speichern
  ///
  /// In de, this message translates to:
  /// **'In die Schatztruhe legen'**
  String get wishSave;

  /// Knopf: Wunschschatz überspringen
  ///
  /// In de, this message translates to:
  /// **'Weiß ich noch nicht'**
  String get wishSkip;

  /// Fehler: Titel zu kurz
  ///
  /// In de, this message translates to:
  /// **'Schreib mindestens 2 Zeichen.'**
  String get wishTitleTooShort;

  /// Fehler: Titel zu lang
  ///
  /// In de, this message translates to:
  /// **'Höchstens 40 Zeichen, bitte.'**
  String get wishTitleTooLong;

  /// Fehler: Betrag ungültig
  ///
  /// In de, this message translates to:
  /// **'Bitte eine ganze Zahl von 1 bis 10000.'**
  String get wishAmountInvalid;

  /// Abschluss des Intros
  ///
  /// In de, this message translates to:
  /// **'Willkommen in der Crew, {nickname}!'**
  String doneTitle(String nickname);

  /// Erster Rang nach dem Intro (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Dein Rang: Schiffsjunge'**
  String get doneRank;

  /// Gutgeschriebene Seemeilen
  ///
  /// In de, this message translates to:
  /// **'+{xp} Seemeilen'**
  String doneXp(int xp);

  /// Hinweis nach angelegtem Wunschschatz
  ///
  /// In de, this message translates to:
  /// **'Dein Wunschschatz liegt in der Schatztruhe.'**
  String get doneWish;

  /// Knopf: Karte öffnen
  ///
  /// In de, this message translates to:
  /// **'Karte öffnen'**
  String get doneMapButton;

  /// Überschrift, wenn sich die Karte aufrollt
  ///
  /// In de, this message translates to:
  /// **'Die Karte ist offen!'**
  String get mapOpenTitle;

  /// Text unter der Karte nach dem Intro (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Euer erstes Ziel: der Hafen von Taleria.'**
  String get mapOpenBody;

  /// Knopf: Intro beenden
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get mapStartButton;

  /// Titel der Karte
  ///
  /// In de, this message translates to:
  /// **'Karte'**
  String get mapTitle;

  /// Schiffsname im Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'Dein Schiff: {ship}'**
  String childHomeShip(String ship);

  /// Knopf: Karte öffnen (Kinderbereich)
  ///
  /// In de, this message translates to:
  /// **'Zur Karte'**
  String get childHomeMapButton;

  /// Knopf: Intro-Film erneut ansehen
  ///
  /// In de, this message translates to:
  /// **'Intro noch einmal ansehen'**
  String get childHomeIntroAgain;

  /// Schiffsname im Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'Schiff: {ship}'**
  String lighthouseChildShip(String ship);

  /// Hinweis im Leuchtturm, wenn das Kind das Intro noch nicht beendet hat
  ///
  /// In de, this message translates to:
  /// **'Intro noch nicht abgeschlossen'**
  String get lighthouseIntroPending;

  /// Abschnitt im Avatar-Baukasten: Mensch oder Tier
  ///
  /// In de, this message translates to:
  /// **'Figur'**
  String get avatarSpecies;

  /// Avatar: Mensch
  ///
  /// In de, this message translates to:
  /// **'Mensch'**
  String get avatarSpeciesHuman;

  /// Avatar: Katze
  ///
  /// In de, this message translates to:
  /// **'Katze'**
  String get avatarSpeciesCat;

  /// Avatar: Hund
  ///
  /// In de, this message translates to:
  /// **'Hund'**
  String get avatarSpeciesDog;

  /// Avatar: Bär
  ///
  /// In de, this message translates to:
  /// **'Bär'**
  String get avatarSpeciesBear;

  /// Avatar: Hase
  ///
  /// In de, this message translates to:
  /// **'Hase'**
  String get avatarSpeciesRabbit;

  /// Avatar: Maus
  ///
  /// In de, this message translates to:
  /// **'Maus'**
  String get avatarSpeciesMouse;

  /// Abschnitt im Avatar-Baukasten für Tiere
  ///
  /// In de, this message translates to:
  /// **'Fellfarbe'**
  String get avatarFur;

  /// Hinweis beim Tipp auf eine gesperrte Insel
  ///
  /// In de, this message translates to:
  /// **'Diese Insel ist noch verschlossen. Schließ zuerst die Insel davor ab.'**
  String get mapIslandLocked;

  /// Hinweis beim Tipp auf eine Insel im Nebel (Glossar: Nebel)
  ///
  /// In de, this message translates to:
  /// **'Diese Insel taucht bald auf.'**
  String get mapIslandFog;

  /// Name einer Insel im Nebel, mit Fragezeichen
  ///
  /// In de, this message translates to:
  /// **'{title}?'**
  String mapIslandFogTitle(String title);

  /// Vorlesetext für das Schiff auf der Karte
  ///
  /// In de, this message translates to:
  /// **'Dein Schiff'**
  String get mapYouAreHere;

  /// Überschrift der Stationsliste einer Insel
  ///
  /// In de, this message translates to:
  /// **'Stationen'**
  String get islandStationsHeading;

  /// Knopf: Ankunftsszene der Insel erneut zeigen
  ///
  /// In de, this message translates to:
  /// **'Ankunft noch einmal ansehen'**
  String get islandArrivalAgain;

  /// Hinweis, wenn eine Insel abgeschlossen ist
  ///
  /// In de, this message translates to:
  /// **'Alle Stationen geschafft. Das Kartenstück gehört euch!'**
  String get islandAllDone;

  /// Nummer einer Station
  ///
  /// In de, this message translates to:
  /// **'Station {number}'**
  String stationNumber(int number);

  /// Name der Prüfungsstation
  ///
  /// In de, this message translates to:
  /// **'Abschlussprüfung'**
  String get stationExam;

  /// Hinweis beim Tipp auf eine gesperrte Station
  ///
  /// In de, this message translates to:
  /// **'Diese Station öffnet sich, wenn du die Station davor geschafft hast.'**
  String get stationLocked;

  /// Hinweis beim Tipp auf die erledigte Intro-Station
  ///
  /// In de, this message translates to:
  /// **'Hier hat deine Reise begonnen.'**
  String get stationIntroDone;

  /// Kennzeichen einer erledigten Station
  ///
  /// In de, this message translates to:
  /// **'Geschafft'**
  String get stationDone;

  /// Kennzeichen einer Bonus-Station (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Flaschenpost'**
  String get stationBonus;

  /// Überschrift der Aufwärmfragen (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Weißt du noch?'**
  String get warmUpTitle;

  /// Erklärung der Aufwärmfragen
  ///
  /// In de, this message translates to:
  /// **'Zwei kurze Fragen zur letzten Station. Fehler sind kein Problem.'**
  String get warmUpHint;

  /// Überschrift des Stations-Checks
  ///
  /// In de, this message translates to:
  /// **'Kurzer Check'**
  String get quizCheckTitle;

  /// Fortschritt im Quiz
  ///
  /// In de, this message translates to:
  /// **'Frage {current} von {total}'**
  String quizProgress(int current, int total);

  /// Rückmeldung bei richtiger Antwort
  ///
  /// In de, this message translates to:
  /// **'Richtig!'**
  String get quizCorrect;

  /// Rückmeldung bei falscher Antwort
  ///
  /// In de, this message translates to:
  /// **'Nicht ganz.'**
  String get quizWrong;

  /// Knopf: nächste Frage
  ///
  /// In de, this message translates to:
  /// **'Nächste Frage'**
  String get quizNext;

  /// Knopf: Quiz abschließen
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get quizFinish;

  /// Überschrift des Spiel-Platzhalters
  ///
  /// In de, this message translates to:
  /// **'Spiel: {title}'**
  String gamePlaceholderTitle(String title);

  /// Text des Spiel-Platzhalters (bis Schritt 7)
  ///
  /// In de, this message translates to:
  /// **'Dieses Spiel wird gerade gebaut. Bald kannst du es hier spielen.'**
  String get gamePlaceholderBody;

  /// Überschrift nach einer Station
  ///
  /// In de, this message translates to:
  /// **'Station geschafft!'**
  String get resultTitle;

  /// Ergebnis eines Quiz
  ///
  /// In de, this message translates to:
  /// **'{correct} von {total} richtig'**
  String resultCorrect(int correct, int total);

  /// Knopf: zurück zur Insel
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Insel'**
  String get resultBack;

  /// Überschrift nach bestandener Prüfung
  ///
  /// In de, this message translates to:
  /// **'Prüfung bestanden!'**
  String get examPassedTitle;

  /// Überschrift nach nicht bestandener Prüfung
  ///
  /// In de, this message translates to:
  /// **'Noch nicht ganz'**
  String get examFailedTitle;

  /// Erklärung nach nicht bestandener Prüfung
  ///
  /// In de, this message translates to:
  /// **'Du brauchst {pass} richtige Antworten. Versuch es noch einmal, ohne Strafe. Du bekommst neue Fragen.'**
  String examFailedBody(int pass);

  /// Knopf: Prüfung wiederholen
  ///
  /// In de, this message translates to:
  /// **'Noch einmal versuchen'**
  String get examRetry;

  /// Überschrift nach Abschluss einer Insel
  ///
  /// In de, this message translates to:
  /// **'Kartenstück gefunden!'**
  String get islandCompletedTitle;

  /// Orden für die Insel
  ///
  /// In de, this message translates to:
  /// **'Neuer Orden: {badge}'**
  String islandCompletedBadge(String badge);

  /// Hinweis nach Abschluss einer Insel
  ///
  /// In de, this message translates to:
  /// **'Die nächste Insel ist jetzt offen.'**
  String get islandCompletedNext;

  /// Knopf nach Abschluss einer Insel
  ///
  /// In de, this message translates to:
  /// **'Zur Karte'**
  String get islandCompletedButton;
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
