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

  /// Fehler: Code zum Zurücksetzen falsch oder abgelaufen
  ///
  /// In de, this message translates to:
  /// **'Der Code stimmt nicht oder ist abgelaufen. Fordere einfach einen neuen an.'**
  String get failureCodeInvalid;

  /// Fehler: neues Passwort gleich dem alten
  ///
  /// In de, this message translates to:
  /// **'Das neue Passwort muss anders sein als das alte.'**
  String get failureSamePassword;

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

  /// Knopf unter der Anmeldung
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen?'**
  String get forgotPasswordLink;

  /// Titel: Passwort zurücksetzen
  ///
  /// In de, this message translates to:
  /// **'Neues Passwort'**
  String get resetTitle;

  /// Erklärung: Passwort zurücksetzen, Schritt 1
  ///
  /// In de, this message translates to:
  /// **'Gib die E-Mail-Adresse deines Kontos ein. Wir schicken dir einen Code, mit dem du ein neues Passwort festlegst.'**
  String get resetIntro;

  /// Knopf: Code per E-Mail anfordern
  ///
  /// In de, this message translates to:
  /// **'Code schicken'**
  String get resetSendCode;

  /// Hinweis nach dem Anfordern
  ///
  /// In de, this message translates to:
  /// **'Wenn es zu {email} ein Konto gibt, ist jetzt ein Code unterwegs. Schau auch im Spam-Ordner nach.'**
  String resetCodeSent(String email);

  /// Feld für den Code
  ///
  /// In de, this message translates to:
  /// **'Code aus der E-Mail'**
  String get resetCodeLabel;

  /// Fehler: Code hat falsches Format
  ///
  /// In de, this message translates to:
  /// **'Der Code besteht aus 6 Ziffern.'**
  String get resetCodeInvalidFormat;

  /// Feld für das neue Passwort
  ///
  /// In de, this message translates to:
  /// **'Neues Passwort'**
  String get resetNewPasswordLabel;

  /// Knopf: neues Passwort speichern
  ///
  /// In de, this message translates to:
  /// **'Neues Passwort speichern'**
  String get resetSave;

  /// Knopf: neuen Code anfordern
  ///
  /// In de, this message translates to:
  /// **'Code nochmal schicken'**
  String get resetSendAgain;

  /// Hinweis: neuer Code angefordert
  ///
  /// In de, this message translates to:
  /// **'Ein neuer Code ist unterwegs.'**
  String get resetSentAgain;

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
  /// **'Empfohlen ab 8 Jahren. Du entscheidest, wann dein Kind startet.'**
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
  /// **'Auf der Karte liegen alle Inseln. Tipp auf eine Insel und spiel ihre Stationen. Auf jeder Insel wartet ein Stück der Schatzkarte.'**
  String get tourMapBody;

  /// Rundgang: Schatztruhe
  ///
  /// In de, this message translates to:
  /// **'Die Schatztruhe'**
  String get tourChestTitle;

  /// Tala erklärt die Schatztruhe (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Hier liegt dein Geld in drei Truhen: zum Ausgeben, zum Sparen und zum Verschenken. Hier sparst du auch für deine Wunschschätze.'**
  String get tourChestBody;

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

  /// Intro-Abschluss: erster Rang in der gewählten Form
  ///
  /// In de, this message translates to:
  /// **'Dein Rang: {rank}'**
  String doneRank(String rank);

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

  /// Hinweis: Insel offen, aber die Stopps auf See davor fehlen noch
  ///
  /// In de, this message translates to:
  /// **'Auf dem Weg zu dieser Insel liegen noch Stopps auf See. Tipp auf den leuchtenden Stopp!'**
  String get mapSeaStopsFirst;

  /// Hinweis: Stopp auf See noch gesperrt
  ///
  /// In de, this message translates to:
  /// **'Diesen Stopp erreichst du, wenn du die Insel und den Stopp davor geschafft hast.'**
  String get mapSeaStopLocked;

  /// Ergebnis nach einem Stopp auf See
  ///
  /// In de, this message translates to:
  /// **'Stopp geschafft!'**
  String get seaStopDone;

  /// Knopf nach einem Stopp auf See: zurück zur Karte
  ///
  /// In de, this message translates to:
  /// **'Weiter segeln'**
  String get seaStopBack;

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

  /// Insel von innen: Überschrift über den kurzen Lernpunkten für Kinder
  ///
  /// In de, this message translates to:
  /// **'Das lernst du hier'**
  String get islandLearnHeading;

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

  /// Talo auf der Insel: welche Station als Nächstes dran ist
  ///
  /// In de, this message translates to:
  /// **'Weiter geht\'s mit „{title}“. Tipp auf die leuchtende Stelle am Weg!'**
  String islandNextHint(String title);

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

  /// Überschrift: Ausblick auf die nächste Insel nach dem Insel-Abschluss
  ///
  /// In de, this message translates to:
  /// **'Was kommt als Nächstes?'**
  String get islandTeaserTitle;

  /// Knopf nach Abschluss einer Insel
  ///
  /// In de, this message translates to:
  /// **'Zur Karte'**
  String get islandCompletedButton;

  /// Knopf im Kinderbereich: Truhen und Wunschschätze (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Schatztruhe'**
  String get childHomeTreasureButton;

  /// Knopf im Kinderbereich: Aufträge (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Aufträge'**
  String get childHomeTasksButton;

  /// Anzahl offener Aufträge im Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine offenen Aufträge} =1{1 offener Auftrag} other{{count} offene Aufträge}}'**
  String childHomeTasksOpen(int count);

  /// Titel der Truhen-Übersicht im Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'Deine Truhen'**
  String get treasureTitle;

  /// Truhe zum Ausgeben (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Bordkasse'**
  String get potSpendChild;

  /// Truhe zum Sparen (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Schatztruhe'**
  String get potSaveChild;

  /// Truhe zum Verschenken (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Glückstruhe'**
  String get potGiveChild;

  /// Erklärung der Bordkasse
  ///
  /// In de, this message translates to:
  /// **'Zum Ausgeben. Davon kaufst du dir kleine Dinge, zum Beispiel ein Eis.'**
  String get potSpendHint;

  /// Erklärung der Schatztruhe
  ///
  /// In de, this message translates to:
  /// **'Zum Sparen. Hier sammelst du für deine Wunschschätze, also für Dinge, die mehr kosten.'**
  String get potSaveHint;

  /// Erklärung der Glückstruhe
  ///
  /// In de, this message translates to:
  /// **'Zum Verschenken. Damit machst du anderen eine Freude, zum Beispiel mit einem Geschenk.'**
  String get potGiveHint;

  /// Knopf: Geld zwischen Truhen verschieben
  ///
  /// In de, this message translates to:
  /// **'Geld in eine andere Truhe legen'**
  String get treasureMove;

  /// Knopf auf einer Truhe: Übersicht öffnen
  ///
  /// In de, this message translates to:
  /// **'Was ist drin?'**
  String get potDetailsButton;

  /// Überschrift der Übersicht einer Truhe
  ///
  /// In de, this message translates to:
  /// **'So setzt sich das zusammen'**
  String get potDetailsHeading;

  /// Übersicht einer Truhe: Geld, das hineinkam
  ///
  /// In de, this message translates to:
  /// **'Dazugekommen'**
  String get potDetailsIn;

  /// Übersicht einer Truhe: Geld, das herausging
  ///
  /// In de, this message translates to:
  /// **'Weggegangen'**
  String get potDetailsOut;

  /// Übersicht einer Truhe: ältere Buchungen, die nicht einzeln geladen sind
  ///
  /// In de, this message translates to:
  /// **'Frühere Buchungen'**
  String get potDetailsOlder;

  /// Übersicht einer Truhe: Summe (alle Truhen-Namen sind weiblich)
  ///
  /// In de, this message translates to:
  /// **'Jetzt in der {pot}'**
  String potDetailsTotal(String pot);

  /// Übersicht einer leeren Truhe
  ///
  /// In de, this message translates to:
  /// **'Hier ist noch nichts passiert. Sobald Geld dazukommt oder weggeht, steht es hier.'**
  String get potDetailsEmpty;

  /// Übersicht einer Truhe: Liste der einzelnen Buchungen
  ///
  /// In de, this message translates to:
  /// **'Alle Buchungen'**
  String get potDetailsList;

  /// Übersicht einer Truhe: wie oft
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Mal} other{{count} Mal}}'**
  String potDetailsCount(int count);

  /// Übersicht einer Truhe: Art der Buchung
  ///
  /// In de, this message translates to:
  /// **'Taschengeld'**
  String get potSumAllowance;

  /// Übersicht einer Truhe: Art der Buchung
  ///
  /// In de, this message translates to:
  /// **'Belohnungen für Aufträge'**
  String get potSumTask;

  /// Übersicht einer Truhe: umgebucht, hinein
  ///
  /// In de, this message translates to:
  /// **'Aus anderen Truhen hergelegt'**
  String get potSumTransferIn;

  /// Übersicht einer Truhe: umgebucht, hinaus
  ///
  /// In de, this message translates to:
  /// **'In andere Truhen gelegt'**
  String get potSumTransferOut;

  /// Übersicht einer Truhe: Art der Buchung
  ///
  /// In de, this message translates to:
  /// **'Korrekturen von deinen Eltern'**
  String get potSumManual;

  /// Übersicht einer Truhe: Art der Buchung
  ///
  /// In de, this message translates to:
  /// **'Wunschschätze eingelöst'**
  String get potSumGoal;

  /// Übersicht einer Truhe: Art der Buchung
  ///
  /// In de, this message translates to:
  /// **'Gekauft'**
  String get potSumPurchase;

  /// Übersicht einer Truhe: Art der Buchung
  ///
  /// In de, this message translates to:
  /// **'Verschenkt'**
  String get potSumDonation;

  /// Knopf: Ausgabe aus der Bordkasse
  ///
  /// In de, this message translates to:
  /// **'Ich habe etwas gekauft'**
  String get treasureSpend;

  /// Knopf: Geschenk aus der Glückstruhe
  ///
  /// In de, this message translates to:
  /// **'Ich habe etwas verschenkt'**
  String get treasureGive;

  /// Taschengeld im Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'Dein Taschengeld: {amount} {interval}'**
  String treasureAllowance(String amount, String interval);

  /// Datum des nächsten Taschengelds
  ///
  /// In de, this message translates to:
  /// **'Das nächste Taschengeld kommt am {date}.'**
  String treasureAllowanceNext(String date);

  /// Hinweis ohne Taschengeld
  ///
  /// In de, this message translates to:
  /// **'Du bekommst hier noch kein Taschengeld. Frag deine Eltern, ob sie es eintragen.'**
  String get treasureNoAllowance;

  /// Hinweis: Geld ist virtuell
  ///
  /// In de, this message translates to:
  /// **'Alle Beträge sind virtuell. Die App zählt mit, das echte Geld bekommst du von deinen Eltern.'**
  String get treasureVirtual;

  /// Rhythmus des Taschengelds: wöchentlich
  ///
  /// In de, this message translates to:
  /// **'pro Woche'**
  String get allowanceWeekly;

  /// Rhythmus des Taschengelds: monatlich
  ///
  /// In de, this message translates to:
  /// **'pro Monat'**
  String get allowanceMonthly;

  /// Überschrift Wunschschätze (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Wunschschätze'**
  String get goalsHeading;

  /// Hinweis ohne Wunschschätze
  ///
  /// In de, this message translates to:
  /// **'Du hast noch keinen Wunschschatz. Was wünschst du dir?'**
  String get goalsEmpty;

  /// Knopf: Wunschschatz anlegen
  ///
  /// In de, this message translates to:
  /// **'Neuer Wunschschatz'**
  String get goalNew;

  /// Fortschritt eines Wunschschatzes
  ///
  /// In de, this message translates to:
  /// **'{saved} von {target}'**
  String goalProgress(String saved, String target);

  /// Knopf: Wunschschatz einlösen
  ///
  /// In de, this message translates to:
  /// **'Einlösen'**
  String get goalRedeem;

  /// Kennzeichen eines eingelösten Wunschschatzes
  ///
  /// In de, this message translates to:
  /// **'Erfüllt!'**
  String get goalReached;

  /// Rückfrage beim Einlösen
  ///
  /// In de, this message translates to:
  /// **'{title} einlösen?'**
  String goalRedeemTitle(String title);

  /// Text beim Einlösen
  ///
  /// In de, this message translates to:
  /// **'{amount} gehen aus der Schatztruhe. Viel Spaß mit deinem Wunsch!'**
  String goalRedeemBody(String amount);

  /// Knopf: Wunschschatz löschen
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get goalDelete;

  /// Rückfrage beim Löschen eines Wunschschatzes
  ///
  /// In de, this message translates to:
  /// **'{title} löschen?'**
  String goalDeleteTitle(String title);

  /// Feld: Titel eines Wunschschatzes
  ///
  /// In de, this message translates to:
  /// **'Was wünschst du dir?'**
  String get goalTitleLabel;

  /// Feld: Betrag eines Wunschschatzes
  ///
  /// In de, this message translates to:
  /// **'Wie viel kostet es? (in Euro)'**
  String get goalTargetLabel;

  /// Überschrift der Buchungen
  ///
  /// In de, this message translates to:
  /// **'Kassenbuch'**
  String get ledgerHeading;

  /// Hinweis ohne Buchungen
  ///
  /// In de, this message translates to:
  /// **'Hier ist noch nichts passiert.'**
  String get ledgerEmpty;

  /// Buchungsart im Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'Taschengeld'**
  String get ledgerAllowance;

  /// Buchungsart im Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'Auftrag'**
  String get ledgerTask;

  /// Buchungsart im Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'Umgepackt'**
  String get ledgerTransfer;

  /// Buchungsart
  ///
  /// In de, this message translates to:
  /// **'Korrektur'**
  String get ledgerManual;

  /// Buchungsart im Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'Wunschschatz eingelöst'**
  String get ledgerGoal;

  /// Buchungsart
  ///
  /// In de, this message translates to:
  /// **'Gekauft'**
  String get ledgerPurchase;

  /// Buchungsart
  ///
  /// In de, this message translates to:
  /// **'Verschenkt'**
  String get ledgerDonation;

  /// Titel des Umbuchen-Dialogs
  ///
  /// In de, this message translates to:
  /// **'Geld in eine andere Truhe legen'**
  String get moveTitle;

  /// Feld: Truhe, aus der umgebucht wird
  ///
  /// In de, this message translates to:
  /// **'Von'**
  String get moveFrom;

  /// Feld: Truhe, in die umgebucht wird
  ///
  /// In de, this message translates to:
  /// **'Nach'**
  String get moveTo;

  /// Feld: Betrag
  ///
  /// In de, this message translates to:
  /// **'Betrag in Euro'**
  String get amountLabel;

  /// Hinweis zum Betrag
  ///
  /// In de, this message translates to:
  /// **'zum Beispiel 2,50'**
  String get amountHint;

  /// Fehler: Betrag ungültig
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Betrag wie 2,50 eingeben.'**
  String get amountInvalid;

  /// Fehler: Betrag 0
  ///
  /// In de, this message translates to:
  /// **'Der Betrag muss größer als 0 sein.'**
  String get amountZero;

  /// Fehler: Betrag zu groß
  ///
  /// In de, this message translates to:
  /// **'Höchstens {max}.'**
  String amountTooLarge(String max);

  /// Fehler: nicht genug Guthaben
  ///
  /// In de, this message translates to:
  /// **'So viel ist nicht in der Truhe.'**
  String get notEnoughMoney;

  /// Feld: Notiz zu einer Buchung
  ///
  /// In de, this message translates to:
  /// **'Wofür? (freiwillig)'**
  String get noteLabel;

  /// Knopf: Buchung ausführen
  ///
  /// In de, this message translates to:
  /// **'Buchen'**
  String get bookButton;

  /// Titel: Ausgabe aus der Bordkasse
  ///
  /// In de, this message translates to:
  /// **'Was hast du gekauft?'**
  String get spendTitle;

  /// Titel: Geschenk aus der Glückstruhe
  ///
  /// In de, this message translates to:
  /// **'Was hast du verschenkt?'**
  String get giveTitle;

  /// Titel der Aufträge im Kinderbereich (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Aufträge'**
  String get tasksTitle;

  /// Überschrift offener Aufträge
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get tasksOpenHeading;

  /// Überschrift gemeldeter Aufträge im Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'Wartet auf deine Eltern'**
  String get tasksWaitingHeading;

  /// Überschrift erledigter Aufträge
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get tasksDoneHeading;

  /// Hinweis ohne Aufträge
  ///
  /// In de, this message translates to:
  /// **'Gerade keine Aufträge. Deine Eltern können im Leuchtturm welche anlegen.'**
  String get tasksEmpty;

  /// Knopf: Auftrag als erledigt melden
  ///
  /// In de, this message translates to:
  /// **'Erledigt!'**
  String get taskDoneButton;

  /// Belohnung eines Auftrags
  ///
  /// In de, this message translates to:
  /// **'+{amount}'**
  String taskReward(String amount);

  /// Kennzeichen einer Pflicht ohne Belohnung
  ///
  /// In de, this message translates to:
  /// **'Pflicht'**
  String get taskChore;

  /// Ablehnung mit Nachricht der Eltern
  ///
  /// In de, this message translates to:
  /// **'Noch nicht ganz: {note}'**
  String taskRejected(String note);

  /// Ablehnung ohne Nachricht
  ///
  /// In de, this message translates to:
  /// **'Deine Eltern möchten, dass du noch einmal nachschaust.'**
  String get taskRejectedNoNote;

  /// Knopf: abgelehnten Auftrag erneut melden
  ///
  /// In de, this message translates to:
  /// **'Nochmal melden'**
  String get taskResubmit;

  /// Rückmeldung nach dem Melden
  ///
  /// In de, this message translates to:
  /// **'Super! Jetzt müssen deine Eltern bestätigen.'**
  String get taskSubmitted;

  /// Kinderbereich: wann der Auftrag gemeldet wurde
  ///
  /// In de, this message translates to:
  /// **'Gemeldet am {date}'**
  String taskSubmittedOn(String date);

  /// Kinderbereich: wann der Auftrag erledigt wurde
  ///
  /// In de, this message translates to:
  /// **'Erledigt am {date}'**
  String taskDoneOn(String date);

  /// Kinderbereich: gemeldet und an einem anderen Tag bestätigt
  ///
  /// In de, this message translates to:
  /// **'Erledigt am {done}, bestätigt am {confirmed}'**
  String taskDoneConfirmedOn(String done, String confirmed);

  /// Kinderbereich: wohin die Belohnung gebucht wurde
  ///
  /// In de, this message translates to:
  /// **'Die {amount} kamen in deine Bordkasse.'**
  String taskRewardBooked(String amount);

  /// Leuchtturm: Aufgabe offen seit
  ///
  /// In de, this message translates to:
  /// **'Offen seit {date}'**
  String taskParentOpenSince(String date);

  /// Leuchtturm: Aufgabe gemeldet am
  ///
  /// In de, this message translates to:
  /// **'Gemeldet am {date}'**
  String taskParentSubmittedOn(String date);

  /// Leuchtturm: Aufgabe bestätigt am
  ///
  /// In de, this message translates to:
  /// **'Bestätigt am {date}'**
  String taskParentApprovedOn(String date);

  /// Leuchtturm: Aufgabe abgelehnt am
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt am {date}'**
  String taskParentRejectedOn(String date);

  /// Leuchtturm: wohin die Belohnung gebucht wurde
  ///
  /// In de, this message translates to:
  /// **'{amount} auf „{pot}“ gebucht'**
  String taskParentBooked(String amount, String pot);

  /// Titel des Budget-Bereichs im Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'Taschengeld und Aufgaben'**
  String get budgetTitle;

  /// Anzahl gemeldeter Aufgaben im Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Aufgaben warten} =1{1 Aufgabe wartet auf Bestätigung} other{{count} Aufgaben warten auf Bestätigung}}'**
  String pendingTasks(int count);

  /// Truhe im Elternbereich (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Ausgeben'**
  String get parentPotSpend;

  /// Truhe im Elternbereich (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Sparen'**
  String get parentPotSave;

  /// Truhe im Elternbereich (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Verschenken'**
  String get parentPotGive;

  /// Schatztruhe: Überschrift über dem Taschengeld (Kinderwort, früher „Heuer“)
  ///
  /// In de, this message translates to:
  /// **'Taschengeld'**
  String get allowanceHeading;

  /// Hinweis ohne Taschengeld
  ///
  /// In de, this message translates to:
  /// **'Kein Taschengeld festgelegt.'**
  String get allowanceNone;

  /// Aktuelles Taschengeld
  ///
  /// In de, this message translates to:
  /// **'{amount} {interval}, nächste Zahlung am {date}'**
  String allowanceCurrent(String amount, String interval, String date);

  /// Knopf: Taschengeld festlegen
  ///
  /// In de, this message translates to:
  /// **'Taschengeld festlegen'**
  String get allowanceSet;

  /// Knopf: Taschengeld beenden
  ///
  /// In de, this message translates to:
  /// **'Taschengeld beenden'**
  String get allowanceStop;

  /// Feld: Rhythmus des Taschengelds
  ///
  /// In de, this message translates to:
  /// **'Rhythmus'**
  String get allowanceIntervalLabel;

  /// Option Rhythmus
  ///
  /// In de, this message translates to:
  /// **'wöchentlich'**
  String get allowanceWeeklyOption;

  /// Option Rhythmus
  ///
  /// In de, this message translates to:
  /// **'monatlich'**
  String get allowanceMonthlyOption;

  /// Datum der ersten Zahlung
  ///
  /// In de, this message translates to:
  /// **'Erste Zahlung: {date}'**
  String allowanceFirstPayout(String date);

  /// Hinweis: Taschengeld ist virtuell
  ///
  /// In de, this message translates to:
  /// **'Das Taschengeld ist virtuell: Die App zählt mit, auszahlen tut ihr es selbst.'**
  String get allowanceHint;

  /// Überschrift Aufgaben im Leuchtturm (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Aufgaben'**
  String get tasksParentHeading;

  /// Knopf: Aufgabe anlegen
  ///
  /// In de, this message translates to:
  /// **'Aufgabe anlegen'**
  String get taskCreate;

  /// Feld: Titel der Aufgabe
  ///
  /// In de, this message translates to:
  /// **'Aufgabe'**
  String get taskTitleLabel;

  /// Feld: Belohnung
  ///
  /// In de, this message translates to:
  /// **'Belohnung in Euro'**
  String get taskRewardLabel;

  /// Option: Aufgabe ohne Geld
  ///
  /// In de, this message translates to:
  /// **'Pflicht ohne Belohnung'**
  String get taskChoreLabel;

  /// Fehler: Titel der Aufgabe
  ///
  /// In de, this message translates to:
  /// **'Bitte 2 bis 60 Zeichen.'**
  String get taskTitleInvalid;

  /// Knopf: Aufgabe bestätigen
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get taskApprove;

  /// Knopf: Aufgabe ablehnen
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get taskReject;

  /// Feld: Nachricht beim Ablehnen
  ///
  /// In de, this message translates to:
  /// **'Nachricht an dein Kind (freiwillig)'**
  String get taskRejectNoteLabel;

  /// Status einer Aufgabe
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get taskStatusOpen;

  /// Status einer Aufgabe
  ///
  /// In de, this message translates to:
  /// **'Gemeldet'**
  String get taskStatusSubmitted;

  /// Status einer Aufgabe
  ///
  /// In de, this message translates to:
  /// **'Bestätigt'**
  String get taskStatusApproved;

  /// Status einer Aufgabe
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get taskStatusRejected;

  /// Knopf: Aufgabe löschen
  ///
  /// In de, this message translates to:
  /// **'Aufgabe löschen'**
  String get taskDelete;

  /// Hinweis ohne Aufgaben im Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'Noch keine Aufgaben.'**
  String get tasksParentEmpty;

  /// Überschrift Kontostand im Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'Kontostand'**
  String get balanceHeading;

  /// Knopf: Korrektur buchen
  ///
  /// In de, this message translates to:
  /// **'Korrektur buchen'**
  String get manualBooking;

  /// Hinweis zur Korrektur
  ///
  /// In de, this message translates to:
  /// **'Positiv ist eine Gutschrift, mit Minus ein Abzug (zum Beispiel -2,50).'**
  String get manualHint;

  /// Feld: Truhe auswählen (Elternbereich)
  ///
  /// In de, this message translates to:
  /// **'Truhe'**
  String get potLabel;

  /// Name eines Rangs (Glossar). Parameter ist der Code aus der Datenbank.
  ///
  /// In de, this message translates to:
  /// **'{rank, select, schiffsjunge{Schiffsjunge} matrose{Matrose} bootsmann{Bootsmann} steuermann{Steuermann} kapitaen{Kapitän} other{Neu an Bord}}'**
  String rankName(String rank);

  /// Titel der Seite mit allen Rängen (Zeitstrahl)
  ///
  /// In de, this message translates to:
  /// **'Deine Ränge'**
  String get ranksTitle;

  /// Knopf auf der Rang-Karte der Startseite
  ///
  /// In de, this message translates to:
  /// **'Alle Ränge ansehen'**
  String get ranksOpen;

  /// Talo erklärt den Zeitstrahl der Ränge (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Mit jeder Seemeile segelst du ein Stück weiter. Ganz oben wartet {captain}. Dafür brauchst du die Goldene Schatzkarte.'**
  String ranksIntro(String captain);

  /// Grenze eines Rangs
  ///
  /// In de, this message translates to:
  /// **'ab {xp} Seemeilen'**
  String ranksFrom(int xp);

  /// Grenze des ersten Rangs (ab der ersten Seemeile)
  ///
  /// In de, this message translates to:
  /// **'gleich zu Beginn'**
  String get ranksFromStart;

  /// Grenze des höchsten Rangs
  ///
  /// In de, this message translates to:
  /// **'mit der Goldenen Schatzkarte'**
  String get ranksFromCertificate;

  /// Rang ist erreicht
  ///
  /// In de, this message translates to:
  /// **'Geschafft'**
  String get ranksReached;

  /// Aktueller Rang im Zeitstrahl
  ///
  /// In de, this message translates to:
  /// **'Hier bist du'**
  String get ranksHere;

  /// Überschrift: woher Seemeilen kommen
  ///
  /// In de, this message translates to:
  /// **'So sammelst du Seemeilen'**
  String get ranksHowTitle;

  /// Woher Seemeilen kommen
  ///
  /// In de, this message translates to:
  /// **'Für jede Station, die du schaffst'**
  String get ranksHowStation;

  /// Woher Seemeilen kommen
  ///
  /// In de, this message translates to:
  /// **'Für jeden Tauchgang am Ankerplatz'**
  String get ranksHowDive;

  /// Woher Seemeilen kommen
  ///
  /// In de, this message translates to:
  /// **'Für Begegnungen auf See, einmal am Tag'**
  String get ranksHowEncounter;

  /// Seemeilen des Kindes
  ///
  /// In de, this message translates to:
  /// **'{xp} Seemeilen'**
  String statsXp(int xp);

  /// Fortschritt zum nächsten Rang
  ///
  /// In de, this message translates to:
  /// **'Noch {xp} Seemeilen bis {rank}'**
  String statsNextRank(int xp, String rank);

  /// Hinweis: Kapitän oder Kapitänin nur mit der Goldenen Schatzkarte
  ///
  /// In de, this message translates to:
  /// **'Finde die Goldene Schatzkarte, dann wirst du {rank}.'**
  String statsNextRankCertificate(String rank);

  /// Hinweis beim Rang Kapitän
  ///
  /// In de, this message translates to:
  /// **'Du hast den höchsten Rang erreicht!'**
  String get statsTopRank;

  /// Hinweis vor dem ersten Rang
  ///
  /// In de, this message translates to:
  /// **'Nach dem Intro bekommst du deinen ersten Rang.'**
  String get statsNoRank;

  /// Fahrtwind (Serie) in Wochen, Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'{weeks, plural, =0{Noch kein Fahrtwind} =1{1 Woche Fahrtwind} other{{weeks} Wochen Fahrtwind}}'**
  String streakWeeks(int weeks);

  /// Fahrtwind ist von den Eltern pausiert
  ///
  /// In de, this message translates to:
  /// **'Fahrtwind macht gerade Pause'**
  String get streakPaused;

  /// Erklärung Fahrtwind im Kinderbereich
  ///
  /// In de, this message translates to:
  /// **'Spiel jede Woche mindestens eine Station. Jede Woche hintereinander macht deinen Fahrtwind stärker.'**
  String get streakHint;

  /// Knopf zur Orden-Sammlung mit Anzahl
  ///
  /// In de, this message translates to:
  /// **'Meine Orden ({count})'**
  String badgesButton(int count);

  /// Überschrift der Orden-Sammlung
  ///
  /// In de, this message translates to:
  /// **'Meine Orden'**
  String get badgesTitle;

  /// Hinweis ohne Orden
  ///
  /// In de, this message translates to:
  /// **'Noch keine Orden. Schließe deine erste Insel ab!'**
  String get badgesEmpty;

  /// Datum eines verdienten Ordens
  ///
  /// In de, this message translates to:
  /// **'Verliehen am {date}'**
  String badgeEarnedOn(String date);

  /// Orden, den das Kind noch nicht hat
  ///
  /// In de, this message translates to:
  /// **'Noch nicht gefunden'**
  String get badgeNotYet;

  /// Kurzer Hinweis: keine neue Station gerade (Tempo)
  ///
  /// In de, this message translates to:
  /// **'Das Schiff braucht Wind.'**
  String get windNeededShort;

  /// Tempo als Geschichte, nie als Countdown (CLAUDE.md Abschnitt 8)
  ///
  /// In de, this message translates to:
  /// **'Das Schiff braucht Wind. Die nächste Station erreichst du am {weekday}.'**
  String windNeeded(String weekday);

  /// Tempo, wenn kein Datum bekannt ist
  ///
  /// In de, this message translates to:
  /// **'Das Schiff braucht Wind. Bald geht es weiter.'**
  String get windNeededSoon;

  /// Was das Kind ohne Wind tun kann
  ///
  /// In de, this message translates to:
  /// **'Bis dahin kannst du fertige Stationen wiederholen oder Begegnungen auf See lösen.'**
  String get windMeanwhile;

  /// Name eines Wochentags (1 = Montag)
  ///
  /// In de, this message translates to:
  /// **'{day, select, 1{Montag} 2{Dienstag} 3{Mittwoch} 4{Donnerstag} 5{Freitag} 6{Samstag} 7{Sonntag} other{nächsten Tag}}'**
  String weekday(String day);

  /// Station: neue Station, das Schiff braucht erst Wind
  ///
  /// In de, this message translates to:
  /// **'Wartet auf Wind'**
  String get stationNoWind;

  /// Knopf auf der Karte: Begegnung auf See wartet
  ///
  /// In de, this message translates to:
  /// **'{title} taucht auf!'**
  String mapEncounterButton(String title);

  /// Keine Begegnung verfügbar
  ///
  /// In de, this message translates to:
  /// **'Gerade ist alles ruhig auf See. Schau später wieder vorbei.'**
  String get mapEncounterNone;

  /// Knopf: dieselbe Frage noch einmal
  ///
  /// In de, this message translates to:
  /// **'Nochmal versuchen'**
  String get encounterTryAgain;

  /// Knopf: weiter zum nächsten Rätsel
  ///
  /// In de, this message translates to:
  /// **'Nächstes Rätsel'**
  String get encounterNext;

  /// Knopf nach dem letzten Rätsel
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get encounterFinish;

  /// Überschrift nach einer Begegnung
  ///
  /// In de, this message translates to:
  /// **'Der Weg ist frei!'**
  String get encounterDoneTitle;

  /// Ergebnis einer Begegnung
  ///
  /// In de, this message translates to:
  /// **'Beim ersten Versuch richtig: {correct} von {total}'**
  String encounterFirstTry(int correct, int total);

  /// Hinweis ohne Seemeilen
  ///
  /// In de, this message translates to:
  /// **'Seemeilen für Begegnungen gibt es einmal am Tag. Für heute hast du sie schon.'**
  String get encounterNoXpToday;

  /// Knopf nach einer Begegnung
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Karte'**
  String get encounterBack;

  /// Feier beim neuen Rang
  ///
  /// In de, this message translates to:
  /// **'Neuer Rang: {rank}!'**
  String rankUpTitle(String rank);

  /// Knopf nach der Feier für Orden oder Rang
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get badgeTapToContinue;

  /// Überschrift im Leuchtturm (Elternwörter)
  ///
  /// In de, this message translates to:
  /// **'Tempo und Serie'**
  String get paceHeading;

  /// Auswahl des Tempos
  ///
  /// In de, this message translates to:
  /// **'Neue Stationen pro Woche'**
  String get paceLabel;

  /// Tempo: freie Fahrt (kurz)
  ///
  /// In de, this message translates to:
  /// **'Frei'**
  String get paceFree;

  /// Erklärung Tempo für Eltern
  ///
  /// In de, this message translates to:
  /// **'Standard sind 2 neue Stationen pro Woche (Montag und Donnerstag). Wiederholen geht immer. In den Ferien passt „Frei“.'**
  String get paceHint;

  /// Bestätigung nach dem Ändern des Tempos
  ///
  /// In de, this message translates to:
  /// **'Tempo gespeichert.'**
  String get paceSaved;

  /// Schalter: Fahrtwind (Serie) pausieren
  ///
  /// In de, this message translates to:
  /// **'Serie pausieren'**
  String get streakPauseLabel;

  /// Erklärung Pause der Serie
  ///
  /// In de, this message translates to:
  /// **'Zum Beispiel in den Ferien: Wochen ohne Lernen beenden die Serie dann nicht.'**
  String get streakPauseHint;

  /// Rang für Eltern als Level (Glossar)
  ///
  /// In de, this message translates to:
  /// **'Level {level} ({rank})'**
  String parentLevel(int level, String rank);

  /// Seemeilen für Eltern
  ///
  /// In de, this message translates to:
  /// **'Fortschritt: {xp} Seemeilen'**
  String parentProgressXp(int xp);

  /// Orden für Eltern (Abzeichen)
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Noch keine Abzeichen} =1{1 Abzeichen} other{{count} Abzeichen}}'**
  String parentBadges(int count);

  /// Fahrtwind für Eltern (Serie)
  ///
  /// In de, this message translates to:
  /// **'{weeks, plural, =0{Keine laufende Serie} =1{Serie: 1 Woche} other{Serie: {weeks} Wochen}}'**
  String parentStreak(int weeks);

  /// Hinweis: Serie ist pausiert
  ///
  /// In de, this message translates to:
  /// **'Serie pausiert'**
  String get parentStreakPaused;

  /// Bezeichnung eines Ankerplatzes (Tauchgang) in der Stationsliste
  ///
  /// In de, this message translates to:
  /// **'Ankerplatz'**
  String get stationDive;

  /// Überschrift der Wiederholungsfragen im Tauchgang
  ///
  /// In de, this message translates to:
  /// **'Perlentauchen'**
  String get diveTitle;

  /// Erklärung Perlentauchen
  ///
  /// In de, this message translates to:
  /// **'Jede richtige Antwort ist eine Perle.'**
  String get diveHint;

  /// Überschrift der Wrack-Aufgabe
  ///
  /// In de, this message translates to:
  /// **'Im Wrack'**
  String get wreckTitle;

  /// Knopf nach der gelösten Wrack-Aufgabe
  ///
  /// In de, this message translates to:
  /// **'Wieder auftauchen'**
  String get wreckDone;

  /// Überschrift nach dem Tauchgang
  ///
  /// In de, this message translates to:
  /// **'Wieder an Bord!'**
  String get diveResultTitle;

  /// Perlen aus dem Tauchgang
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Diesmal keine Perle, beim nächsten Mal klappt es} =1{1 Perle gefunden} other{{count} Perlen gefunden}}'**
  String divePearls(int count);

  /// Neuer Fund aus dem Wrack
  ///
  /// In de, this message translates to:
  /// **'Fund für deine Sammlung: {title}'**
  String diveFind(String title);

  /// Fortschritt im Sortier-Spiel
  ///
  /// In de, this message translates to:
  /// **'Karte {current} von {total}'**
  String gameSortProgress(int current, int total);

  /// Falscher Korb im Sortier-Spiel
  ///
  /// In de, this message translates to:
  /// **'Passt nicht ganz. Versuch einen anderen Korb.'**
  String get gameSortWrong;

  /// Richtiger Korb im Sortier-Spiel
  ///
  /// In de, this message translates to:
  /// **'Passt!'**
  String get gameSortRight;

  /// Knopf: nächste Karte im Sortier-Spiel
  ///
  /// In de, this message translates to:
  /// **'Nächste Karte'**
  String get gameNextCard;

  /// Falsches Ding im Reihenfolge-Spiel
  ///
  /// In de, this message translates to:
  /// **'Noch nicht. Was kommt davor?'**
  String get gameOrderWrong;

  /// Fortschritt im Reihenfolge-Spiel
  ///
  /// In de, this message translates to:
  /// **'{count} von {total} an der richtigen Stelle'**
  String gameOrderPlaced(int count, int total);

  /// Mini-Spiel gelöst
  ///
  /// In de, this message translates to:
  /// **'Geschafft!'**
  String get gameDone;

  /// Kachel auf der Startseite des Kindes zur Orden-Sammlung
  ///
  /// In de, this message translates to:
  /// **'Orden'**
  String get childHomeBadgesTile;

  /// Kachel auf der Startseite des Kindes zur Unterwasser-Sammlung
  ///
  /// In de, this message translates to:
  /// **'Sammlung'**
  String get childHomeCollectionTile;

  /// Hinweis unter der Sammlung: Funde, die das Kind noch nicht angeschaut hat
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 neuer Fund} other{{count} neue Funde}}'**
  String childHomeNewFinds(int count);

  /// Knopf zur Unterwasser-Sammlung mit Zahl der Funde
  ///
  /// In de, this message translates to:
  /// **'Unterwasser-Sammlung ({count})'**
  String collectionButton(int count);

  /// Überschrift der Unterwasser-Sammlung
  ///
  /// In de, this message translates to:
  /// **'Unterwasser-Sammlung'**
  String get collectionTitle;

  /// Perlen in der Sammlung
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Noch keine Perlen} =1{1 Perle} other{{count} Perlen}}'**
  String collectionPearls(int count);

  /// Hinweis ohne Funde
  ///
  /// In de, this message translates to:
  /// **'Noch keine Funde. An jedem Ankerplatz liegt etwas im Wrack.'**
  String get collectionEmpty;

  /// Datum eines Fundes
  ///
  /// In de, this message translates to:
  /// **'Gefunden am {date}'**
  String collectionFoundOn(String date);

  /// Hinweis auf der Karte, wenn alle offenen Inseln geschafft sind
  ///
  /// In de, this message translates to:
  /// **'Die nächste Insel liegt noch im Nebel.'**
  String get fogAheadTitle;

  /// Was das Kind tun kann, solange Nebel voraus liegt
  ///
  /// In de, this message translates to:
  /// **'Bis sie auftaucht, kannst du Kontrollfahrten machen, tauchen und Spiele wiederholen.'**
  String get fogAheadBody;

  /// Knopf: Begegnung zum Üben
  ///
  /// In de, this message translates to:
  /// **'Kontrollfahrt starten'**
  String get fogAheadButton;

  /// Leuchtturm: Eintrag zur Fortschritts-Seite eines Kindes
  ///
  /// In de, this message translates to:
  /// **'Fortschritt und Lernstand'**
  String get childDetailProgress;

  /// Leuchtturm: Eintrag zu den Gesprächsideen
  ///
  /// In de, this message translates to:
  /// **'Kombüsen-Fragen'**
  String get childDetailKitchen;

  /// Untertitel des Eintrags Kombüsen-Fragen
  ///
  /// In de, this message translates to:
  /// **'Gesprächsideen und Aufträge fürs echte Leben'**
  String get childDetailKitchenHint;

  /// Eintrag im Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'Wochenbericht'**
  String get childDetailWeekly;

  /// Untertitel des Wochenberichts
  ///
  /// In de, this message translates to:
  /// **'Was {name} in den letzten 7 Tagen geschafft hat'**
  String childDetailWeeklyHint(String name);

  /// Titel des Wochenberichts
  ///
  /// In de, this message translates to:
  /// **'Woche von {name}'**
  String weeklyTitle(String name);

  /// Zeitraum des Wochenberichts
  ///
  /// In de, this message translates to:
  /// **'Vom {from} bis {to}'**
  String weeklyRange(String from, String to);

  /// Wochenbericht ohne Aktivität
  ///
  /// In de, this message translates to:
  /// **'Diese Woche war ruhig'**
  String get weeklyQuietTitle;

  /// Wochenbericht ohne Aktivität, freundlicher Hinweis ohne Druck
  ///
  /// In de, this message translates to:
  /// **'{name} war in den letzten 7 Tagen nicht auf See. Vielleicht passt am Wochenende eine Station zusammen? Schon 10 Minuten reichen.'**
  String weeklyQuietBody(String name);

  /// Wochenbericht: Überschrift
  ///
  /// In de, this message translates to:
  /// **'Geschafft'**
  String get weeklyDoneTitle;

  /// Wochenbericht
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Station geschafft:} other{{count} Stationen geschafft:}}'**
  String weeklyStations(int count);

  /// Wochenbericht
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Wiederholungs-Station (Tauchgang)} other{{count} Wiederholungs-Stationen (Tauchgänge)}}'**
  String weeklyDives(int count);

  /// Wochenbericht
  ///
  /// In de, this message translates to:
  /// **'Insel „{title}“ abgeschlossen'**
  String weeklyIsland(String title);

  /// Wochenbericht
  ///
  /// In de, this message translates to:
  /// **'Neues Abzeichen: {title}'**
  String weeklyBadge(String title);

  /// Wochenbericht
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 neuer Fund in der Sammlung} other{{count} neue Funde in der Sammlung}}'**
  String weeklyFinds(int count);

  /// Wochenbericht
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Aufgabe bestätigt, {amount} virtuell gebucht} other{{count} Aufgaben bestätigt, {amount} virtuell gebucht}}'**
  String weeklyTasks(int count, String amount);

  /// Wochenbericht: wackelnde Themen
  ///
  /// In de, this message translates to:
  /// **'Noch üben'**
  String get weeklyShakyTitle;

  /// Wochenbericht
  ///
  /// In de, this message translates to:
  /// **'Diese Themen wackeln noch. Taleria fragt sie von selbst wieder ab. Ein kurzes Gespräch hilft zusätzlich:'**
  String get weeklyShakyBody;

  /// Wochenbericht: Kombüsen-Frage
  ///
  /// In de, this message translates to:
  /// **'Gesprächsidee für diese Woche'**
  String get weeklyPromptTitle;

  /// Wochenbericht: Serie und zuletzt aktiv
  ///
  /// In de, this message translates to:
  /// **'Serie'**
  String get weeklyStreakTitle;

  /// Überschrift der Fortschritts-Seite
  ///
  /// In de, this message translates to:
  /// **'{nickname}: Fortschritt'**
  String progressTitle(String nickname);

  /// Sammlung des Kindes für Eltern
  ///
  /// In de, this message translates to:
  /// **'{finds, plural, =0{Noch keine Fundstücke} =1{1 Fundstück} other{{finds} Fundstücke}} · Perlen: {pearls}'**
  String parentCollection(int finds, int pearls);

  /// Letzter Tag mit Station oder Wiederholung
  ///
  /// In de, this message translates to:
  /// **'Zuletzt aktiv am {date}'**
  String lastActive(String date);

  /// Kind hat noch nichts gespielt
  ///
  /// In de, this message translates to:
  /// **'Noch nicht gespielt'**
  String get lastActiveNever;

  /// Überschrift der Inselliste im Leuchtturm
  ///
  /// In de, this message translates to:
  /// **'Inseln'**
  String get islandsHeading;

  /// Insel abgeschlossen
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen am {date}'**
  String islandStatusCompleted(String date);

  /// Fortschritt auf einer Insel (mit Wiederholungs-Stationen)
  ///
  /// In de, this message translates to:
  /// **'{done} von {total} Stationen geschafft'**
  String islandStatusProgress(int done, int total);

  /// Insel noch nicht erreicht
  ///
  /// In de, this message translates to:
  /// **'Noch gesperrt'**
  String get islandStatusLocked;

  /// Insel im Nebel (Elternwort laut Glossar)
  ///
  /// In de, this message translates to:
  /// **'Inhalt folgt'**
  String get islandStatusFog;

  /// Überschrift Lernstand
  ///
  /// In de, this message translates to:
  /// **'Lernstand'**
  String get learningHeading;

  /// Erklärung des Lernstands für Eltern
  ///
  /// In de, this message translates to:
  /// **'Der Lernstand kommt aus den Wiederholungen. „Sicher“ heißt: auch nach Tagen noch gewusst. „Wackelt noch“ heißt: zuletzt falsch beantwortet, das kommt in den nächsten Wiederholungen wieder dran.'**
  String get learningHint;

  /// Lernstand eines Themas: sicher
  ///
  /// In de, this message translates to:
  /// **'Sicher'**
  String get topicSecure;

  /// Lernstand eines Themas: richtig, aber noch nicht wiederholt
  ///
  /// In de, this message translates to:
  /// **'Wird geübt'**
  String get topicLearning;

  /// Lernstand eines Themas: zuletzt teils falsch
  ///
  /// In de, this message translates to:
  /// **'Wackelt noch'**
  String get topicShaky;

  /// Lernstand eines Themas: noch keine Fragen
  ///
  /// In de, this message translates to:
  /// **'Noch nicht dran'**
  String get topicNotStarted;

  /// Anzahl beantworteter Fragen eines Themas
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Frage beantwortet} other{{count} Fragen beantwortet}}'**
  String topicAnswered(int count);

  /// Überschrift der Gesprächsideen
  ///
  /// In de, this message translates to:
  /// **'Kombüsen-Fragen'**
  String get kitchenTitle;

  /// Einleitung Kombüsen-Fragen
  ///
  /// In de, this message translates to:
  /// **'Gesprächsideen für den Familientisch, passend zu dem, was {nickname} gerade lernt.'**
  String kitchenIntro(String nickname);

  /// Noch keine Insel erreicht
  ///
  /// In de, this message translates to:
  /// **'Sobald {nickname} die erste Insel betritt, gibt es hier Gesprächsideen.'**
  String kitchenNone(String nickname);

  /// Markierung der aktuellen Insel
  ///
  /// In de, this message translates to:
  /// **'Gerade dran'**
  String get kitchenCurrent;

  /// Überschrift des Auftrags einer Insel
  ///
  /// In de, this message translates to:
  /// **'Auftrag fürs echte Leben'**
  String get realLifeTaskHeading;

  /// Knopf: Auftrag fürs echte Leben als Aufgabe anlegen
  ///
  /// In de, this message translates to:
  /// **'Als Aufgabe anlegen'**
  String get realLifeTaskCreate;

  /// Bestätigung nach dem Anlegen
  ///
  /// In de, this message translates to:
  /// **'Aufgabe angelegt. Sie steht jetzt bei {nickname} unter den Aufträgen.'**
  String realLifeTaskCreated(String nickname);

  /// Leuchtturm: Überschrift offene Aufgaben aller Kinder
  ///
  /// In de, this message translates to:
  /// **'Wartet auf deine Bestätigung'**
  String get pendingOverviewTitle;

  /// Fehler: nur mit Abo (Elternbereich)
  ///
  /// In de, this message translates to:
  /// **'Dafür braucht es das Abo.'**
  String get failurePremiumRequired;

  /// Kinderbereich: Insel gehört zum Abo. Keine Preise, kein Kauf-Knopf (Abschnitt 6).
  ///
  /// In de, this message translates to:
  /// **'Diese Insel ist noch verschlossen. Deine Eltern können sie im Leuchtturm freischalten.'**
  String get mapIslandPremium;

  /// Karte: es geht erst mit dem Abo weiter
  ///
  /// In de, this message translates to:
  /// **'Die nächste Insel ist noch verschlossen.'**
  String get premiumAheadTitle;

  /// Karte: was das Kind ohne Abo tun kann
  ///
  /// In de, this message translates to:
  /// **'Deine Eltern können sie im Leuchtturm freischalten. Bis dahin kannst du Kontrollfahrten machen, tauchen und Spiele wiederholen.'**
  String get premiumAheadBody;

  /// Leuchtturm: Insel gehört zum Abo
  ///
  /// In de, this message translates to:
  /// **'Mit dem Abo'**
  String get islandStatusPremium;

  /// Leuchtturm: Eintrag zur Abo-Seite
  ///
  /// In de, this message translates to:
  /// **'Abo'**
  String get lighthouseSubscription;

  /// Überschrift der Abo-Seite
  ///
  /// In de, this message translates to:
  /// **'Abo'**
  String get subscriptionTitle;

  /// Abo-Stand: kein Abo
  ///
  /// In de, this message translates to:
  /// **'Basis (kostenlos)'**
  String get subscriptionFree;

  /// Abo-Stand: Abo aktiv
  ///
  /// In de, this message translates to:
  /// **'Abo ist aktiv'**
  String get subscriptionPremium;

  /// Abo-Stand mit Ablaufdatum
  ///
  /// In de, this message translates to:
  /// **'Abo ist aktiv bis {date}'**
  String subscriptionPremiumUntil(String date);

  /// Hinweis: Abo stammt vom Testschalter
  ///
  /// In de, this message translates to:
  /// **'Test-Abo (nur in der Testumgebung)'**
  String get subscriptionTestNote;

  /// Überschrift: was gratis ist
  ///
  /// In de, this message translates to:
  /// **'Kostenlos dabei'**
  String get subscriptionFreeHeading;

  /// Gratis: Inseln
  ///
  /// In de, this message translates to:
  /// **'Hafen und Tauschinsel'**
  String get subscriptionFreeIslands;

  /// Gratis: Kinder-Profile
  ///
  /// In de, this message translates to:
  /// **'Ein Kinder-Profil'**
  String get subscriptionFreeChild;

  /// Gratis: Budget-Teil
  ///
  /// In de, this message translates to:
  /// **'Aufgaben, Taschengeld und Schatztruhe'**
  String get subscriptionFreeBudget;

  /// Überschrift: was das Abo dazu bringt
  ///
  /// In de, this message translates to:
  /// **'Mit dem Abo'**
  String get subscriptionPremiumHeading;

  /// Abo: Inseln
  ///
  /// In de, this message translates to:
  /// **'Alle Inseln bis zur Schatzinsel. Neue Inseln kommen automatisch dazu.'**
  String get subscriptionPremiumIslands;

  /// Abo: Kinder-Profile
  ///
  /// In de, this message translates to:
  /// **'Mehrere Kinder-Profile'**
  String get subscriptionPremiumChildren;

  /// Hinweis: Abo hängt am Eltern-Konto
  ///
  /// In de, this message translates to:
  /// **'Das Abo gilt für alle Kinder dieses Kontos.'**
  String get subscriptionAccountNote;

  /// Knopf: Abo kaufen (noch nicht verfügbar)
  ///
  /// In de, this message translates to:
  /// **'Abo abschließen'**
  String get subscriptionBuy;

  /// Hinweis: Kauf ist noch nicht eingebaut
  ///
  /// In de, this message translates to:
  /// **'Das Abo lässt sich bald direkt hier abschließen. Dafür fehlen noch die Einstellungen in den App-Stores.'**
  String get subscriptionBuySoon;

  /// Schalter: Test-Abo (nur Testumgebung)
  ///
  /// In de, this message translates to:
  /// **'Abo testweise aktiv'**
  String get subscriptionTestSwitch;

  /// Erklärung des Test-Schalters
  ///
  /// In de, this message translates to:
  /// **'Nur in der Testumgebung: So lässt sich ausprobieren, was mit und ohne Abo frei ist.'**
  String get subscriptionTestHint;

  /// Dialog: Kinder-Profil-Grenze ohne Abo
  ///
  /// In de, this message translates to:
  /// **'Weitere Kinder-Profile'**
  String get childLimitTitle;

  /// Dialog: Erklärung der Grenze
  ///
  /// In de, this message translates to:
  /// **'In der kostenlosen Version gibt es ein Kinder-Profil. Mit dem Abo kannst du weitere anlegen.'**
  String get childLimitBody;

  /// Dialog: Knopf zur Abo-Seite
  ///
  /// In de, this message translates to:
  /// **'Zum Abo'**
  String get childLimitButton;

  /// Kinderbereich, Schatztruhe: Überschrift des Bereichs Wunschflaschen
  ///
  /// In de, this message translates to:
  /// **'Wunschflaschen'**
  String get wishBottlesHeading;

  /// Kinderbereich, Schatztruhe: kurze Erklärung der Warte-Regel (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Steck einen Wunsch in eine Flasche. Wenn sie wieder angespült wird, schaust du, ob du ihn noch willst.'**
  String get wishBottlesIntro;

  /// Kinderbereich, Schatztruhe: keine offenen Wunschflaschen
  ///
  /// In de, this message translates to:
  /// **'Gerade treibt keine Flasche auf dem Meer.'**
  String get wishBottlesEmpty;

  /// Knopf und Dialogtitel: neuen Wunsch in eine Flasche stecken
  ///
  /// In de, this message translates to:
  /// **'Neue Wunschflasche'**
  String get wishBottleNew;

  /// Eingabefeld: Name des Wunsches
  ///
  /// In de, this message translates to:
  /// **'Was wünschst du dir?'**
  String get wishBottleTitleLabel;

  /// Eingabefeld: ungefährer Preis des Wunsches in Euro, darf leer bleiben
  ///
  /// In de, this message translates to:
  /// **'Was kostet es ungefähr? (freiwillig)'**
  String get wishBottlePriceLabel;

  /// Auswahl: kleiner Wunsch (eine Nacht warten)
  ///
  /// In de, this message translates to:
  /// **'Kleiner Wunsch'**
  String get wishBottleSmall;

  /// Auswahl: großer Wunsch (eine Woche warten)
  ///
  /// In de, this message translates to:
  /// **'Großer Wunsch'**
  String get wishBottleBig;

  /// Erklärung unter der Auswahl: kleiner Wunsch
  ///
  /// In de, this message translates to:
  /// **'Du schläfst eine Nacht drüber.'**
  String get wishBottleSmallHint;

  /// Erklärung unter der Auswahl: großer Wunsch
  ///
  /// In de, this message translates to:
  /// **'Du schläfst eine Woche drüber.'**
  String get wishBottleBigHint;

  /// Fehler: Name des Wunsches zu kurz
  ///
  /// In de, this message translates to:
  /// **'Bitte mindestens 2 Zeichen.'**
  String get wishBottleTitleTooShort;

  /// Knopf: Wunsch in die Flasche stecken und aufs Meer schicken
  ///
  /// In de, this message translates to:
  /// **'In die Flasche stecken'**
  String get wishBottleThrow;

  /// Knopf im Spiel Wunschflasche: ohne eigenen Wunsch weiter
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get wishBottleSkip;

  /// Spiel Wunschflasche: Bestätigung, kleiner Wunsch (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Deine Flasche treibt jetzt übers Meer. Morgen wird sie angespült. Dann fragt sie dich, ob du „{title}“ noch willst.'**
  String wishBottleThrownSmall(String title);

  /// Spiel Wunschflasche: Bestätigung, großer Wunsch (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Deine Flasche treibt jetzt übers Meer. In einer Woche wird sie angespült. Dann fragt sie dich, ob du „{title}“ noch willst.'**
  String wishBottleThrownBig(String title);

  /// Schatztruhe: Flasche, deren Wartezeit noch läuft
  ///
  /// In de, this message translates to:
  /// **'Treibt noch bis {date}'**
  String wishBottleDrifting(String date);

  /// Schatztruhe: angespülte Flasche, das Kind entscheidet
  ///
  /// In de, this message translates to:
  /// **'Willst du „{title}“ noch?'**
  String wishBottleDueQuestion(String title);

  /// Knopf: aus dem Wunsch wird ein Wunschschatz (Sparziel)
  ///
  /// In de, this message translates to:
  /// **'Ja, Wunschschatz daraus machen'**
  String get wishBottleKeep;

  /// Knopf: den Wunsch nicht mehr verfolgen
  ///
  /// In de, this message translates to:
  /// **'Loslassen'**
  String get wishBottleDrop;

  /// Dialogtitel: Preis für den neuen Wunschschatz eingeben, wenn die Flasche keinen hat
  ///
  /// In de, this message translates to:
  /// **'Wie viel kostet „{title}“?'**
  String wishBottleKeepPrice(String title);

  /// Hinweis nach dem Umwandeln in einen Wunschschatz
  ///
  /// In de, this message translates to:
  /// **'Neuer Wunschschatz: {title}'**
  String wishBottleKept(String title);

  /// Hinweis nach dem Loslassen eines Wunsches (ENTWURF)
  ///
  /// In de, this message translates to:
  /// **'Losgelassen. Gut, dass du gewartet hast!'**
  String get wishBottleDropped;

  /// Startseite des Kindes: Hinweis auf angespülte Wunschflaschen, ohne Push-Nachricht
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Eine Wunschflasche ist angespült! Schau in der Schatztruhe nach.} other{{count} Wunschflaschen sind angespült! Schau in der Schatztruhe nach.}}'**
  String childHomeWishDue(int count);

  /// Spiel Entscheidungen: Fortschritt
  ///
  /// In de, this message translates to:
  /// **'Situation {current} von {total}'**
  String gameChoiceProgress(int current, int total);

  /// Spiele Münzen legen und Rechnen: Fortschritt
  ///
  /// In de, this message translates to:
  /// **'Aufgabe {current} von {total}'**
  String gameTaskProgress(int current, int total);

  /// Spiel Entscheidungen: weiter zur nächsten Runde
  ///
  /// In de, this message translates to:
  /// **'Nächste Situation'**
  String get gameNextSituation;

  /// Spiele Münzen legen und Rechnen: weiter zur nächsten Aufgabe
  ///
  /// In de, this message translates to:
  /// **'Nächste Aufgabe'**
  String get gameNextTask;

  /// Spiel Münzen legen: Summe der gelegten Münzen und Zielbetrag
  ///
  /// In de, this message translates to:
  /// **'Gelegt: {sum} von {target}'**
  String gameCoinsPlaced(String sum, String target);

  /// Spiel Münzen legen: Ablage ist leer
  ///
  /// In de, this message translates to:
  /// **'Noch nichts gelegt. Tippe unten auf Münzen und Scheine.'**
  String get gameCoinsNothing;

  /// Spiel Münzen legen: Summe zu hoch
  ///
  /// In de, this message translates to:
  /// **'Zu viel! Tippe oben auf eine Münze, um sie wegzunehmen.'**
  String get gameCoinsTooMuch;

  /// Spiel Münzen legen: Betrag stimmt
  ///
  /// In de, this message translates to:
  /// **'Genau richtig!'**
  String get gameCoinsExact;

  /// Spiel Münzen legen: richtig, aber es ginge mit weniger Münzen
  ///
  /// In de, this message translates to:
  /// **'Geschafft! Mit {count} Münzen und Scheinen ginge es auch.'**
  String gameCoinsFewer(int count);

  /// Spiel Münzen legen: alle gelegten Münzen entfernen
  ///
  /// In de, this message translates to:
  /// **'Alles zurücklegen'**
  String get gameCoinsClear;

  /// Aufschrift auf einer gezeichneten Cent-Münze
  ///
  /// In de, this message translates to:
  /// **'CENT'**
  String get drawingCent;

  /// Aufschrift auf gezeichneten Euro-Münzen und -Scheinen
  ///
  /// In de, this message translates to:
  /// **'EURO'**
  String get drawingEuro;

  /// Betrag in Talern in einer gezeichneten Rechnung (Tauschinsel)
  ///
  /// In de, this message translates to:
  /// **'{value} Taler'**
  String drawingTaler(int value);

  /// Schild über den billigen Netzen in der Zeichnung „12 Netze im Jahr“
  ///
  /// In de, this message translates to:
  /// **'billig: hält 1 Monat'**
  String get drawingCheapNet;

  /// Schild über dem guten Netz in der Zeichnung „12 Netze im Jahr“
  ///
  /// In de, this message translates to:
  /// **'gut: hält 1 Jahr'**
  String get drawingGoodNet;

  /// Zeichnung Spar-Insel: Wochentage, mit Leerzeichen getrennt
  ///
  /// In de, this message translates to:
  /// **'Mo Di Mi Do Fr Sa So'**
  String get drawingWeekdays;

  /// Zeichnung Sparplan
  ///
  /// In de, this message translates to:
  /// **'{value} Taler pro Woche'**
  String drawingPerWeek(int value);

  /// Zeichnung Sparplan
  ///
  /// In de, this message translates to:
  /// **'Woche {n}'**
  String drawingWeek(int n);

  /// Zeichnung Sparplan
  ///
  /// In de, this message translates to:
  /// **'Ziel: {value} Taler'**
  String drawingGoal(int value);

  /// Beschriftung einer Münze unter 1 Euro
  ///
  /// In de, this message translates to:
  /// **'{value} ct'**
  String coinCents(int value);

  /// Beschriftung einer Münze oder eines Scheins ab 1 Euro
  ///
  /// In de, this message translates to:
  /// **'{value} €'**
  String coinEuros(int value);

  /// Preis in Talern (Spielwährung in Taleria)
  ///
  /// In de, this message translates to:
  /// **'{count} Taler'**
  String gameTaler(int count);

  /// Spiel Auswählen (genau): Summe und Zielbetrag
  ///
  /// In de, this message translates to:
  /// **'Zusammen: {sum} von {target} Talern'**
  String gamePickExactSum(int sum, int target);

  /// Spiel Auswählen (Budget): Summe und Budget
  ///
  /// In de, this message translates to:
  /// **'Zusammen: {sum} Taler, du hast {target} Taler'**
  String gamePickBudgetSum(int sum, int target);

  /// Knopf in Spielen: Lösung prüfen
  ///
  /// In de, this message translates to:
  /// **'Prüfen'**
  String get gameCheck;

  /// Spiel Auswählen: Budget überschritten
  ///
  /// In de, this message translates to:
  /// **'Das ist zu teuer. Lass etwas weg.'**
  String get gamePickTooMuch;

  /// Spiel Auswählen: Zielbetrag noch nicht erreicht
  ///
  /// In de, this message translates to:
  /// **'Da fehlt noch etwas.'**
  String get gamePickTooLittle;

  /// Spiel Auswählen: geschafft
  ///
  /// In de, this message translates to:
  /// **'Passt!'**
  String get gamePickSolved;

  /// Spiel Rechnen: Eingabefeld
  ///
  /// In de, this message translates to:
  /// **'Deine Antwort'**
  String get gameNumberLabel;

  /// Spiel Rechnen: falsche Zahl
  ///
  /// In de, this message translates to:
  /// **'Noch nicht ganz.'**
  String get gameNumberWrong;

  /// Spiel Rechnen: Tipp nach einer falschen Antwort
  ///
  /// In de, this message translates to:
  /// **'Tipp: {tip}'**
  String gameNumberTip(String tip);

  /// Spiel Rechnen: Lösung anzeigen nach einem falschen Versuch
  ///
  /// In de, this message translates to:
  /// **'Lösung zeigen'**
  String get gameNumberShowSolution;

  /// Spiel Rechnen: richtige Zahl
  ///
  /// In de, this message translates to:
  /// **'Richtig!'**
  String get gameNumberRight;

  /// Spiel Rechnen: angezeigte Lösung
  ///
  /// In de, this message translates to:
  /// **'Lösung: {value}'**
  String gameNumberSolution(String value);

  /// Tauchgang: Überschrift der Spielart Schatztruhe knacken
  ///
  /// In de, this message translates to:
  /// **'Schatztruhe knacken'**
  String get diveChestTitle;

  /// Tauchgang Schatztruhe knacken: Erklärung
  ///
  /// In de, this message translates to:
  /// **'Jede Antwort verrät eine Ziffer des Codes. Jede richtige Antwort ist eine Perle.'**
  String get diveChestHint;

  /// Tauchgang Schatztruhe knacken: alle Ziffern gefunden
  ///
  /// In de, this message translates to:
  /// **'Die Truhe springt auf!'**
  String get diveChestOpen;

  /// Tauchgang: Überschrift der Spielart Fischschwarm
  ///
  /// In de, this message translates to:
  /// **'Fischschwarm'**
  String get diveFishTitle;

  /// Tauchgang Fischschwarm: Erklärung
  ///
  /// In de, this message translates to:
  /// **'Jeder Fisch trägt eine Antwort. Tippe den richtigen an. Jede richtige Antwort ist eine Perle.'**
  String get diveFishHint;

  /// Startseite des Kindes: Beschriftung unter dem Lautsprecher-Knopf, wenn der Ton an ist
  ///
  /// In de, this message translates to:
  /// **'Ton an'**
  String get soundOnLabel;

  /// Startseite des Kindes: Beschriftung unter dem Lautsprecher-Knopf, wenn der Ton aus ist
  ///
  /// In de, this message translates to:
  /// **'Ton aus'**
  String get soundOffLabel;

  /// Hinweis und Vorlesetext für den Lautsprecher-Knopf, wenn der Ton an ist
  ///
  /// In de, this message translates to:
  /// **'Ton ausschalten'**
  String get soundTurnOff;

  /// Hinweis und Vorlesetext für den Lautsprecher-Knopf, wenn der Ton aus ist
  ///
  /// In de, this message translates to:
  /// **'Ton einschalten'**
  String get soundTurnOn;

  /// Leuchtturm: Schalter für die Musik auf Startseite und Karte
  ///
  /// In de, this message translates to:
  /// **'Musik im Hauptmenü'**
  String get lighthouseMusic;

  /// Leuchtturm: Erklärung unter dem Musik-Schalter
  ///
  /// In de, this message translates to:
  /// **'Meeresrauschen auf Startseite und Karte, gilt für dieses Gerät. Die Töne bei richtigen Antworten schaltet das Kind mit dem Lautsprecher-Knopf.'**
  String get lighthouseMusicHint;

  /// Leuchtturm: Schalter für kurzes Vibrieren, wenn das Kind eine Station schafft
  ///
  /// In de, this message translates to:
  /// **'Vibrieren bei Erfolgen'**
  String get lighthouseVibration;

  /// Leuchtturm: Erklärung unter dem Schalter fürs Vibrieren
  ///
  /// In de, this message translates to:
  /// **'Kurz vibrieren, wenn eine Station geschafft ist. Gilt nur für dieses Gerät, im Browser auf dem iPhone geht es nicht.'**
  String get lighthouseVibrationHint;

  /// Schatztruhe: Tala erklärt oben in der Sprechblase die drei Truhen
  ///
  /// In de, this message translates to:
  /// **'Ich bin Tala, die Zahlmeisterin. Dein Geld liegt in drei Truhen. Jede Truhe hat eine eigene Aufgabe.'**
  String get treasureTalaIntro;

  /// Schatztruhe: Erklärung, was ein Wunschschatz ist
  ///
  /// In de, this message translates to:
  /// **'Ein Wunschschatz ist etwas, das du dir wünschst und wofür du sparst, zum Beispiel ein Ball für 15 €. Der Balken zeigt, wie viel davon schon in deiner Schatztruhe liegt.'**
  String get goalsIntro;

  /// Schatztruhe: Erklärung, was das Kassenbuch ist
  ///
  /// In de, this message translates to:
  /// **'Hier steht alles, was mit deinem Geld passiert ist: was dazugekommen ist und was du ausgegeben hast. So weißt du immer, wohin dein Geld gegangen ist.'**
  String get ledgerIntro;

  /// Aufträge: Talo erklärt oben, was Aufträge sind
  ///
  /// In de, this message translates to:
  /// **'Aufträge sind Aufgaben von deinen Eltern, zum Beispiel: Zimmer aufräumen. Bist du fertig, tippst du auf „Erledigt!“.'**
  String get tasksIntroTalo;

  /// Aufträge: Tala erklärt Bestätigung, Belohnung und Pflicht
  ///
  /// In de, this message translates to:
  /// **'Dann schauen deine Eltern nach. Steht eine Belohnung dabei, kommt sie in deine Bordkasse. Bei „Pflicht“ gibt es kein Geld, das gehört einfach dazu.'**
  String get tasksIntroTala;

  /// Orden: Talo erklärt oben, wie man Orden bekommt
  ///
  /// In de, this message translates to:
  /// **'Für jede Insel, die du schaffst, bekommst du einen Orden. Hier hängen alle deine Orden. Die blassen findest du noch auf deiner Reise.'**
  String get badgesIntro;

  /// Sammlung: Tala erklärt oben, was man beim Tauchen findet
  ///
  /// In de, this message translates to:
  /// **'Beim Tauchen an den Ankerplätzen sammelst du Perlen und findest alte Schätze in den Wracks. Hier liegt alles, was du schon gefunden hast.'**
  String get collectionIntro;

  /// Startseite: Knopf oben, öffnet den Rundgang mit allen Bereichen
  ///
  /// In de, this message translates to:
  /// **'Was ist wo?'**
  String get tourButton;

  /// Rundgang: Beschriftung vor der Stelle auf der Startseite
  ///
  /// In de, this message translates to:
  /// **'Wo?'**
  String get tourWhere;

  /// Rundgang: Knopf zur vorigen Station
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get tourBack;

  /// Rundgang: wo die Karte zu finden ist
  ///
  /// In de, this message translates to:
  /// **'Auf der Startseite die große blaue Kachel „Zur Karte“'**
  String get tourMapWhere;

  /// Rundgang: Titel der Station Rang
  ///
  /// In de, this message translates to:
  /// **'Rang, Seemeilen und Fahrtwind'**
  String get tourRankTitle;

  /// Rundgang: wo Rang und Seemeilen stehen
  ///
  /// In de, this message translates to:
  /// **'Auf der Startseite direkt unter der Begrüßung'**
  String get tourRankWhere;

  /// Rundgang: Talo erklärt Rang, Seemeilen und Fahrtwind
  ///
  /// In de, this message translates to:
  /// **'Für jede Station bekommst du Seemeilen. Mit vielen Seemeilen steigst du auf, Rang für Rang bis ganz nach oben. Spielst du jede Woche, bekommst du Fahrtwind.'**
  String get tourRankBody;

  /// Rundgang: wo die Schatztruhe ist
  ///
  /// In de, this message translates to:
  /// **'Auf der Startseite unter der Karte, links'**
  String get tourChestWhere;

  /// Rundgang: Titel der Station Aufträge
  ///
  /// In de, this message translates to:
  /// **'Aufträge'**
  String get tourTasksTitle;

  /// Rundgang: wo die Aufträge sind
  ///
  /// In de, this message translates to:
  /// **'Auf der Startseite unter der Karte, rechts'**
  String get tourTasksWhere;

  /// Rundgang: Tala erklärt die Aufträge
  ///
  /// In de, this message translates to:
  /// **'Hier stehen Aufgaben von deinen Eltern. Bist du fertig, tippst du auf „Erledigt!“. Die rote Zahl zeigt, wie viele noch offen sind.'**
  String get tourTasksBody;

  /// Rundgang: Titel der Station Orden
  ///
  /// In de, this message translates to:
  /// **'Orden'**
  String get tourBadgesTitle;

  /// Rundgang: wo die Orden sind
  ///
  /// In de, this message translates to:
  /// **'Auf der Startseite ganz unten, links'**
  String get tourBadgesWhere;

  /// Rundgang: Talo erklärt die Orden
  ///
  /// In de, this message translates to:
  /// **'Für jede Insel, die du schaffst, bekommst du einen Orden. Hier hängen alle deine Orden.'**
  String get tourBadgesBody;

  /// Rundgang: Titel der Station Sammlung
  ///
  /// In de, this message translates to:
  /// **'Sammlung'**
  String get tourCollectionTitle;

  /// Rundgang: wo die Sammlung ist
  ///
  /// In de, this message translates to:
  /// **'Auf der Startseite ganz unten, rechts'**
  String get tourCollectionWhere;

  /// Rundgang: Tala erklärt die Unterwasser-Sammlung
  ///
  /// In de, this message translates to:
  /// **'Beim Tauchen an den Ankerplätzen findest du Perlen und alte Schätze aus Wracks. Hier liegt alles, was du gefunden hast.'**
  String get tourCollectionBody;

  /// Rundgang: Titel der letzten Station
  ///
  /// In de, this message translates to:
  /// **'Leuchtturm und Ton'**
  String get tourLighthouseTitle;

  /// Rundgang: wo Leuchtturm, Ton und Rundgang sind
  ///
  /// In de, this message translates to:
  /// **'Auf der Startseite ganz oben'**
  String get tourLighthouseWhere;

  /// Rundgang: Talo erklärt Leuchtturm, Ton und den Rundgang-Knopf
  ///
  /// In de, this message translates to:
  /// **'Der Leuchtturm oben rechts gehört deinen Eltern. Oben links schaltest du den Ton an oder aus. Und mit „Was ist wo?“ kannst du diesen Rundgang immer wieder anschauen.'**
  String get tourLighthouseBody;

  /// Rang-Namen in der Form, die Mädchen meist wählen (Glossar)
  ///
  /// In de, this message translates to:
  /// **'{rank, select, schiffsjunge{Schiffsmädchen} matrose{Matrosin} bootsmann{Bootsfrau} steuermann{Steuerfrau} kapitaen{Kapitänin} other{Neu an Bord}}'**
  String rankNameMaedchen(String rank);

  /// Rang-Namen, solange das Kind die Form noch nicht gewählt hat: beide Formen
  ///
  /// In de, this message translates to:
  /// **'{rank, select, schiffsjunge{Schiffsjunge/Schiffsmädchen} matrose{Matrose/Matrosin} bootsmann{Bootsmann/Bootsfrau} steuermann{Steuermann/Steuerfrau} kapitaen{Kapitän/Kapitänin} other{Neu an Bord}}'**
  String rankNameOpen(String rank);

  /// Einführung und Startseite: Überschrift der Wahl Schiffsjunge oder Schiffsmädchen
  ///
  /// In de, this message translates to:
  /// **'Dein Rang'**
  String get rankFormTitle;

  /// Tala fragt, ob die Ränge Schiffsjunge … oder Schiffsmädchen … heißen sollen
  ///
  /// In de, this message translates to:
  /// **'Jetzt gehörst du zur Crew! Neue Crew-Mitglieder bekommen ihren ersten Rang. Wie soll deiner heißen?'**
  String get rankFormQuestion;

  /// Unter der Wahl Schiffsjunge: die weiteren Ränge
  ///
  /// In de, this message translates to:
  /// **'Danach: Matrose, Bootsmann, Steuermann, Kapitän'**
  String get rankFormLadderJunge;

  /// Unter der Wahl Schiffsmädchen: die weiteren Ränge
  ///
  /// In de, this message translates to:
  /// **'Danach: Matrosin, Bootsfrau, Steuerfrau, Kapitänin'**
  String get rankFormLadderMaedchen;

  /// Hinweis unter der Wahl der Rang-Namen
  ///
  /// In de, this message translates to:
  /// **'Du kannst es später ändern: Deine Eltern können das im Leuchtturm umstellen.'**
  String get rankFormHint;

  /// Leuchtturm, Kinderseite: Einstellung, wie die Ränge heißen
  ///
  /// In de, this message translates to:
  /// **'Rang-Namen'**
  String get lighthouseRankForm;

  /// Leuchtturm: Erklärung unter der Einstellung Rang-Namen
  ///
  /// In de, this message translates to:
  /// **'Dein Kind hat das in der Einführung gewählt. Hier kannst du es ändern.'**
  String get lighthouseRankFormHint;

  /// Startbild vor einem echten Mini-Spiel: große Überschrift
  ///
  /// In de, this message translates to:
  /// **'Mini-Spiel!'**
  String get realGameBadge;

  /// Startbild: Knopf, der das Mini-Spiel startet
  ///
  /// In de, this message translates to:
  /// **'Spielen'**
  String get realGamePlay;

  /// Kleines Schild über Tipp-Aufgaben (Sortieren, Reihenfolge usw.), damit „Spiel“ nur für echte Spiele steht
  ///
  /// In de, this message translates to:
  /// **'Übung'**
  String get practiceLabel;

  /// Ende eines echten Mini-Spiels: Überschrift
  ///
  /// In de, this message translates to:
  /// **'Geschafft!'**
  String get realGameWellDone;

  /// Vorlesetext für die Sterne am Ende eines Mini-Spiels
  ///
  /// In de, this message translates to:
  /// **'{count} von 3 Sternen'**
  String realGameStars(int count);

  /// Knopf am Ende des letzten Zugs: zum Ergebnis des Mini-Spiels
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get realGameToResult;

  /// Ende eines Mini-Spiels auf der Seite „Spiele“: von vorn spielen
  ///
  /// In de, this message translates to:
  /// **'Nochmal spielen'**
  String get realGameAgain;

  /// Hinweis beim Nochmal-Spielen über die Startseite
  ///
  /// In de, this message translates to:
  /// **'Nur zum Spaß: Hier gibt es keine Seemeilen.'**
  String get realGameReplayNote;

  /// Kasse: welcher Kunde gerade dran ist
  ///
  /// In de, this message translates to:
  /// **'Kunde {current} von {total}'**
  String tillCustomer(int current, int total);

  /// Kasse: Preis und bezahlter Betrag, unter der Bestellung des Kunden
  ///
  /// In de, this message translates to:
  /// **'Das macht {price}. Ich gebe dir {paid}.'**
  String tillPays(String price, String paid);

  /// Kasse: Überschrift der Preise am Stand
  ///
  /// In de, this message translates to:
  /// **'Preistafel'**
  String get tillPriceBoard;

  /// Kasse: Summe des gelegten Wechselgelds
  ///
  /// In de, this message translates to:
  /// **'Wechselgeld: {sum}'**
  String tillTray(String sum);

  /// Kasse: noch kein Wechselgeld gelegt
  ///
  /// In de, this message translates to:
  /// **'Tippe unten auf Münzen und Scheine.'**
  String get tillTrayEmpty;

  /// Kasse: Wechselgeld dem Kunden geben
  ///
  /// In de, this message translates to:
  /// **'Herausgeben'**
  String get tillGive;

  /// Kasse: Wechselgeld richtig
  ///
  /// In de, this message translates to:
  /// **'Stimmt genau, danke!'**
  String get tillRight;

  /// Kasse: zu viel Wechselgeld
  ///
  /// In de, this message translates to:
  /// **'Das sind {difference} zu viel.'**
  String tillTooMuch(String difference);

  /// Kasse: zu wenig Wechselgeld
  ///
  /// In de, this message translates to:
  /// **'Da fehlen noch {difference}.'**
  String tillTooLittle(String difference);

  /// Kasse: weiter zum nächsten Kunden
  ///
  /// In de, this message translates to:
  /// **'Nächster Kunde'**
  String get tillNextCustomer;

  /// Markt-Einkauf: übriges Geld
  ///
  /// In de, this message translates to:
  /// **'Im Geldbeutel: {amount}'**
  String marketMoneyLeft(String amount);

  /// Markt-Einkauf: Überschrift der Liste
  ///
  /// In de, this message translates to:
  /// **'Einkaufsliste'**
  String get marketList;

  /// Markt-Einkauf: Zeile der Einkaufsliste
  ///
  /// In de, this message translates to:
  /// **'{count} × {item}'**
  String marketNeed(int count, String item);

  /// Markt-Einkauf: Rechnung für ein gekauftes Ding
  ///
  /// In de, this message translates to:
  /// **'{count} × {price} = {total}'**
  String marketBoughtLine(int count, String price, String total);

  /// Markt-Einkauf: Preis eines Angebots
  ///
  /// In de, this message translates to:
  /// **'{price} pro Stück'**
  String marketPerPiece(String price);

  /// Markt-Einkauf: Knopf an einem Angebot
  ///
  /// In de, this message translates to:
  /// **'Kaufen'**
  String get marketBuy;

  /// Markt-Einkauf: Vorlesetext zum Zurücklegen eines gekauften Dings
  ///
  /// In de, this message translates to:
  /// **'{item} zurücklegen'**
  String marketPutBack(String item);

  /// Markt-Einkauf: Hinweis unter der Liste
  ///
  /// In de, this message translates to:
  /// **'Tippe auf etwas Gekauftes, um es zurückzulegen.'**
  String get marketPutBackHint;

  /// Markt-Einkauf: Kind will etwas kaufen, das nicht gebraucht wird
  ///
  /// In de, this message translates to:
  /// **'Das steht nicht auf Talas Liste.'**
  String get marketNotOnList;

  /// Markt-Einkauf: Ding schon im Korb
  ///
  /// In de, this message translates to:
  /// **'{item} hast du schon gekauft.'**
  String marketAlreadyHave(String item);

  /// Markt-Einkauf: zu wenig Geld für dieses Angebot
  ///
  /// In de, this message translates to:
  /// **'Dafür reicht das Geld nicht. Vergleiche die Preise an den anderen Ständen!'**
  String get marketNotEnough;

  /// Markt-Einkauf: es geht sich nicht mehr aus
  ///
  /// In de, this message translates to:
  /// **'Das Geld reicht nicht mehr für alles. Lege etwas zurück und such günstigere Stände.'**
  String get marketStuck;

  /// Markt-Einkauf: geschafft mit den besten Preisen
  ///
  /// In de, this message translates to:
  /// **'Alles gekauft, und überall den günstigsten Stand gefunden! Übrig: {left}'**
  String marketBest(String left);

  /// Markt-Einkauf: geschafft, aber nicht überall am günstigsten
  ///
  /// In de, this message translates to:
  /// **'Alles gekauft! Übrig: {left}. Mit Vergleichen hättest du noch {more} sparen können.'**
  String marketCouldSave(String left, String more);

  /// Eisstand: welcher Tag
  ///
  /// In de, this message translates to:
  /// **'Tag {current} von {total}'**
  String iceDay(int current, int total);

  /// Eisstand: Wetter
  ///
  /// In de, this message translates to:
  /// **'Sonne'**
  String get iceWeatherSun;

  /// Eisstand: Wetter
  ///
  /// In de, this message translates to:
  /// **'Bewölkt'**
  String get iceWeatherClouds;

  /// Eisstand: Wetter
  ///
  /// In de, this message translates to:
  /// **'Regen'**
  String get iceWeatherRain;

  /// Eisstand: so viele Kugeln gibt es heute
  ///
  /// In de, this message translates to:
  /// **'Vorrat: {count} Kugeln'**
  String iceStock(int count);

  /// Eisstand: Überschrift über der Preiswahl
  ///
  /// In de, this message translates to:
  /// **'Preis für eine Kugel'**
  String get icePriceLabel;

  /// Eisstand: gewählter Preis
  ///
  /// In de, this message translates to:
  /// **'{value} Taler'**
  String icePrice(int value);

  /// Eisstand: Vorlesetext für den Minus-Knopf
  ///
  /// In de, this message translates to:
  /// **'Billiger'**
  String get icePriceDown;

  /// Eisstand: Vorlesetext für den Plus-Knopf
  ///
  /// In de, this message translates to:
  /// **'Teurer'**
  String get icePriceUp;

  /// Eisstand: Tag mit dem gewählten Preis spielen
  ///
  /// In de, this message translates to:
  /// **'Stand öffnen'**
  String get iceOpen;

  /// Eisstand: denselben Tag mit anderem Preis
  ///
  /// In de, this message translates to:
  /// **'Anderen Preis probieren'**
  String get iceTryAgain;

  /// Eisstand: weiter zum nächsten Tag
  ///
  /// In de, this message translates to:
  /// **'Nächster Tag'**
  String get iceNextDay;

  /// Eisstand: so viele wollten zu diesem Preis Eis
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Niemand wollte Eis.} =1{1 Tier wollte Eis.} other{{count} Tiere wollten Eis.}}'**
  String iceCustomers(int count);

  /// Eisstand: Ergebnis des Tages
  ///
  /// In de, this message translates to:
  /// **'Verkauft: {sold} Kugeln. Eingenommen: {earned} Taler.'**
  String iceSold(int sold, int earned);

  /// Eisstand: so viele bekamen kein Eis mehr
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tier ging leer aus.} other{{count} Tiere gingen leer aus.}}'**
  String iceMissed(int count);

  /// Eisstand: übrig gebliebenes Eis
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Kugel ist geschmolzen.} other{{count} Kugeln sind geschmolzen.}}'**
  String iceMelted(int count);

  /// Eisstand: höchste mögliche Einnahme getroffen
  ///
  /// In de, this message translates to:
  /// **'Bester Preis für diesen Tag!'**
  String get iceBest;

  /// Eisstand: Preis zu niedrig, Eis ausverkauft
  ///
  /// In de, this message translates to:
  /// **'Das Eis war schnell weg. Viele hätten auch mehr bezahlt.'**
  String get iceTooCheapSoldOut;

  /// Eisstand: Preis zu niedrig, aber nicht ausverkauft
  ///
  /// In de, this message translates to:
  /// **'Mit einem etwas höheren Preis hättest du mehr eingenommen.'**
  String get iceTooCheap;

  /// Eisstand: Preis zu hoch
  ///
  /// In de, this message translates to:
  /// **'Der Preis war vielen zu hoch. Probier es billiger!'**
  String get iceTooDear;

  /// Tauschkette: was Tala gerade hat
  ///
  /// In de, this message translates to:
  /// **'Tala hat: {item}'**
  String tradeHolding(String item);

  /// Tauschkette: was Tala am Ende haben will
  ///
  /// In de, this message translates to:
  /// **'Ziel: {item}'**
  String tradeGoal(String item);

  /// Tauschkette: was ein Händler hergibt
  ///
  /// In de, this message translates to:
  /// **'hat: {item}'**
  String tradeHas(String item);

  /// Tauschkette: was ein Händler dafür will
  ///
  /// In de, this message translates to:
  /// **'will: {item}'**
  String tradeWants(String item);

  /// Tauschkette: Händler lehnt ab
  ///
  /// In de, this message translates to:
  /// **'{name}: „Ich tausche nur gegen {item}.“'**
  String tradeRefused(String name, String item);

  /// Tauschkette: Schild an einem Händler, mit dem schon getauscht wurde
  ///
  /// In de, this message translates to:
  /// **'Getauscht!'**
  String get tradeTraded;

  /// Tauschkette: bisherige Tausche, zum Beispiel „Eimer → Fisch“
  ///
  /// In de, this message translates to:
  /// **'Bisher: {chain}'**
  String tradeChain(String chain);

  /// Tauschkette: wieder mit dem Start-Ding beginnen
  ///
  /// In de, this message translates to:
  /// **'Von vorn anfangen'**
  String get tradeReset;

  /// Tauschkette: Sackgasse, wenn es keine eigene Zeile in den Inhalten gibt
  ///
  /// In de, this message translates to:
  /// **'Hier will niemand mehr {item}.'**
  String tradeStuck(String item);

  /// Startseite Kind: Kachel mit allen Mini-Spielen zum Nochmal-Spielen
  ///
  /// In de, this message translates to:
  /// **'Spiele'**
  String get childHomeGamesTile;

  /// Vorlesetext der Kachel „Spiele“
  ///
  /// In de, this message translates to:
  /// **'Mini-Spiele, {count} freigespielt'**
  String gamesButton(int count);

  /// Seite „Spiele“: Titel
  ///
  /// In de, this message translates to:
  /// **'Mini-Spiele'**
  String get gamesTitle;

  /// Seite „Spiele“: Erklärung oben
  ///
  /// In de, this message translates to:
  /// **'Hier kannst du alle Mini-Spiele nochmal spielen, die du auf deiner Reise geschafft hast. Nur zum Spaß, ohne Seemeilen.'**
  String get gamesIntro;

  /// Seite „Spiele“: Spiel, das noch nicht freigespielt ist
  ///
  /// In de, this message translates to:
  /// **'Noch nicht geschafft: {island}, Station {number}'**
  String gamesLocked(String island, int number);

  /// Seite „Spiele“: wo das Spiel herkommt
  ///
  /// In de, this message translates to:
  /// **'{island}, Station {number}'**
  String gamesWhere(String island, int number);

  /// Seite „Spiele“: noch keine Spiele sichtbar
  ///
  /// In de, this message translates to:
  /// **'Auf den Inseln warten Stationen mit dem Spiel-Zeichen. Wenn du eine geschafft hast, kannst du das Spiel hier nochmal spielen.'**
  String get gamesEmpty;

  /// Vorlesetext an einer Station auf der Insel, die ein echtes Mini-Spiel hat
  ///
  /// In de, this message translates to:
  /// **'mit Mini-Spiel'**
  String get islandStationGame;

  /// Ergebnis einer Station mit Mini-Spiel: Überschrift der Bonus-Karte
  ///
  /// In de, this message translates to:
  /// **'Bonus: Mini-Spiel'**
  String get bonusGameTitle;

  /// Ergebnis einer Station: Erklärung zum Bonus-Spiel
  ///
  /// In de, this message translates to:
  /// **'„{title}“ ist jetzt freigespielt. Kein Muss: Spiel es jetzt oder später unter „Spiele“ auf der Startseite.'**
  String bonusGameBody(String title);

  /// Ergebnis einer Station: Bonus-Spiel sofort spielen
  ///
  /// In de, this message translates to:
  /// **'Jetzt spielen'**
  String get bonusGamePlay;

  /// Leuchtturm, Kinder-Profil: was Einsteiger und Fortgeschritten bedeuten
  ///
  /// In de, this message translates to:
  /// **'Einsteiger rechnen nur mit ganzen Zahlen (3 €, 80 Cent). Fortgeschrittene rechnen auch mit Komma (3,50 €). Unsere Empfehlung: ab 10 Jahren Fortgeschritten. Du kannst es jederzeit ändern.'**
  String get levelHint;

  /// Rucksack packen: welcher Ausflug gerade dran ist
  ///
  /// In de, this message translates to:
  /// **'Ausflug {number} von {total}'**
  String backpackTrip(int number, int total);

  /// Rucksack packen: übrige Taler für diesen Ausflug
  ///
  /// In de, this message translates to:
  /// **'Noch {left} von {budget} Talern'**
  String backpackLeft(int left, int budget);

  /// Rucksack packen: Überschrift über den eingepackten Dingen
  ///
  /// In de, this message translates to:
  /// **'Talas Rucksack'**
  String get backpackBag;

  /// Rucksack packen: noch nichts eingepackt
  ///
  /// In de, this message translates to:
  /// **'Der Rucksack ist noch leer.'**
  String get backpackEmpty;

  /// Rucksack packen: Hinweis unter den eingepackten Dingen
  ///
  /// In de, this message translates to:
  /// **'Antippen nimmt etwas wieder heraus.'**
  String get backpackUnpackHint;

  /// Rucksack packen: Überschrift über allen Dingen zum Einpacken
  ///
  /// In de, this message translates to:
  /// **'Im Packhaus'**
  String get backpackShelf;

  /// Rucksack packen: Vorlesetext für ein eingepacktes Ding
  ///
  /// In de, this message translates to:
  /// **'{item} wieder herausnehmen'**
  String backpackUnpack(String item);

  /// Rucksack packen: Ding ist teurer als die übrigen Taler
  ///
  /// In de, this message translates to:
  /// **'Dafür reichen die Taler nicht mehr. Nimm etwas anderes heraus.'**
  String get backpackNotEnough;

  /// Rucksack packen: Knopf, mit dem Tala aufbricht
  ///
  /// In de, this message translates to:
  /// **'Losgehen'**
  String get backpackGo;

  /// Rucksack packen: Tala kommt zurück, weil etwas Wichtiges fehlt
  ///
  /// In de, this message translates to:
  /// **'Oh nein, ich musste umkehren! Mir hat etwas gefehlt.'**
  String get backpackBack;

  /// Rucksack packen: alles Nötige war eingepackt
  ///
  /// In de, this message translates to:
  /// **'Alles dabei! Tala hat einen tollen Ausflug.'**
  String get backpackGone;

  /// Rucksack packen: eingepackt, aber auf diesem Ausflug nicht nötig
  ///
  /// In de, this message translates to:
  /// **'Heute nicht gebraucht: {items}.'**
  String backpackExtras(String items);

  /// Rucksack packen: übrige Taler werden gespart
  ///
  /// In de, this message translates to:
  /// **'{left} Taler übrig. Die legt Tala in ihre Schatztruhe.'**
  String backpackSaved(int left);

  /// Rucksack packen: Summe der gesparten Taler nach dem letzten Ausflug
  ///
  /// In de, this message translates to:
  /// **'Auf allen Ausflügen gespart: {saved} Taler.'**
  String backpackSavedTotal(int saved);

  /// Rucksack packen: Knopf zum nächsten Ausflug
  ///
  /// In de, this message translates to:
  /// **'Nächster Ausflug'**
  String get backpackNextTrip;

  /// Schätzfrage vor der Erklärung: Überschrift
  ///
  /// In de, this message translates to:
  /// **'Schätz mal!'**
  String get estimateBadge;

  /// Schätzfrage: Hinweis unter der Frage
  ///
  /// In de, this message translates to:
  /// **'Schätz einfach! Es gibt kein Richtig oder Falsch. Die Lösung kommt gleich in der Geschichte.'**
  String get estimateHint;

  /// Schätzfrage: Knopf zum Abgeben der Schätzung
  ///
  /// In de, this message translates to:
  /// **'Das ist mein Tipp'**
  String get estimateSubmit;

  /// Auflösung am Ende der Erklärung: was das Kind geschätzt hat
  ///
  /// In de, this message translates to:
  /// **'Dein Tipp: {guess}'**
  String estimateYourGuess(String guess);

  /// Auflösung: Die Schätzung war genau richtig
  ///
  /// In de, this message translates to:
  /// **'Genau getroffen!'**
  String get estimateExact;

  /// Auflösung der Schätzfrage: Überschrift
  ///
  /// In de, this message translates to:
  /// **'Auflösung'**
  String get estimateRevealTitle;

  /// Schätzfrage mit Zahlenrad: Hinweis
  ///
  /// In de, this message translates to:
  /// **'Dreh am Zahlenrad.'**
  String get estimateWheelHint;

  /// Antipp-Moment in der Bildergeschichte: Überschrift
  ///
  /// In de, this message translates to:
  /// **'Mach mit!'**
  String get tapBadge;

  /// Antipp-Moment „ziehen“: Ziel, auf das das Kind das Ding zieht
  ///
  /// In de, this message translates to:
  /// **'Hierher'**
  String get tapDropHere;

  /// Antipp-Moment „umdrehen“: Hinweis auf der Vorderseite der Karte
  ///
  /// In de, this message translates to:
  /// **'Antippen zum Umdrehen'**
  String get tapFlipHint;

  /// Antipp-Moment „wischen“: Hinweis unter dem Ding
  ///
  /// In de, this message translates to:
  /// **'Wisch zur Seite'**
  String get tapSwipeHint;

  /// Antipp-Moment geschafft, wenn es keinen eigenen Satz danach gibt
  ///
  /// In de, this message translates to:
  /// **'Super gemacht!'**
  String get tapDone;

  /// Antipp-Moment „tippen“ mit mehreren Tipps: wie oft noch
  ///
  /// In de, this message translates to:
  /// **'Noch {count}-mal'**
  String tapCountLeft(int count);

  /// Knopf „?“ auf Menü-Seiten: klappt die Erklärung von Talo oder Tala auf
  ///
  /// In de, this message translates to:
  /// **'Erklärung zeigen'**
  String get pageIntroShow;

  /// Knopf auf Menü-Seiten: klappt die Erklärung wieder zu
  ///
  /// In de, this message translates to:
  /// **'Erklärung zuklappen'**
  String get pageIntroHide;

  /// Auflösung der Schätzfrage: Überschrift über dem Tipp des Kindes (links)
  ///
  /// In de, this message translates to:
  /// **'Dein Tipp'**
  String get estimateGuessLabel;

  /// Auflösung der Schätzfrage: Überschrift über der richtigen Zahl (rechts, grün)
  ///
  /// In de, this message translates to:
  /// **'Lösung'**
  String get estimateAnswerLabel;

  /// Auflösung: Der Tipp liegt nahe an der Lösung (höchstens ein Siebtel der Skala daneben)
  ///
  /// In de, this message translates to:
  /// **'Ganz nah dran!'**
  String get estimateClose;

  /// Tier einer Inselfigur mit eigenem Namen (FIGUREN.md), damit Kinder Name und Tier zusammenbringen. Leer für Figuren ohne eigenen Namen.
  ///
  /// In de, this message translates to:
  /// **'{figure, select, bruno{der Bär} greta{die Ziege} otti{der Otter} olga{die Schildkröte} elsa{die Elster} moritz{das Murmeltier} emma{das Eichhörnchen} gustav{die Grille} other{}}'**
  String figureAnimal(String figure);

  /// Name einer Inselfigur mit Tier, zum Beispiel „Bruno, der Bär“
  ///
  /// In de, this message translates to:
  /// **'{name}, {animal}'**
  String figureWithAnimal(String name, String animal);

  /// Titel der Werft (Avatar-Teile und Flaggen mit Seemeilen freischalten)
  ///
  /// In de, this message translates to:
  /// **'Werft'**
  String get shipyardTitle;

  /// Tala erklärt die Werft
  ///
  /// In de, this message translates to:
  /// **'Willkommen in der Werft! Hier kann man nichts kaufen. Mit deinen Seemeilen wird nach und nach Neues frei: Jacken, Hüte, Halstücher und Flaggen für dein Schiff. Tipp an, was dir gefällt.'**
  String get shipyardIntro;

  /// Nächstes Teil der Werft
  ///
  /// In de, this message translates to:
  /// **'Noch {xp} Seemeilen bis: {item}'**
  String shipyardNext(int xp, String item);

  /// Alle Werft-Teile sind frei
  ///
  /// In de, this message translates to:
  /// **'Du hast alles in der Werft frei. Stark!'**
  String get shipyardAllUnlocked;

  /// Hinweis beim Antippen eines gesperrten Teils; xp ist z. B. „ab 1.000 Seemeilen“
  ///
  /// In de, this message translates to:
  /// **'Das wird {xp} frei. Segel einfach weiter!'**
  String shipyardLocked(String xp);

  /// Vorlese-Text für ein gesperrtes Teil
  ///
  /// In de, this message translates to:
  /// **'{item}, noch gesperrt'**
  String shipyardLockedLabel(String item);

  /// Bereiche der Werft
  ///
  /// In de, this message translates to:
  /// **'{slot, select, outfit{Jacke} hat{Kopfbedeckung} scarf{Halstuch} flag{Flagge} other{Teile}}'**
  String lookSlot(String slot);

  /// Name eines Teils in der Werft
  ///
  /// In de, this message translates to:
  /// **'{id, select, outfit_navy{Blaue Jacke} outfit_red{Rote Jacke} outfit_green{Grüne Jacke} outfit_yellow{Gelbe Jacke} outfit_purple{Lila Jacke} outfit_orange{Orange Jacke} outfit_teal{Türkise Jacke} outfit_gold{Goldene Jacke} hat_none{Ohne} hat_captain{Kapitänsmütze} hat_bandana{Kopftuch} hat_straw{Strohhut} hat_tricorn{Dreispitz} hat_goldCaptain{Goldmütze} scarf_none{Ohne} scarf_red{Rotes Halstuch} scarf_gold{Goldenes Halstuch} flag_taleria{Taleria-Flagge} flag_stripes{Streifen-Flagge} flag_wave{Wellen-Flagge} flag_star{Sternen-Flagge} flag_sun{Sonnen-Flagge} other{Teil}}'**
  String lookName(String id);

  /// Kachel auf der Startseite zur Werft
  ///
  /// In de, this message translates to:
  /// **'Werft'**
  String get childHomeShipyardTile;

  /// Hinweis unter der Werft-Kachel
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 neues Teil frei} other{{count} neue Teile frei}}'**
  String childHomeShipyardNew(int count);
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
