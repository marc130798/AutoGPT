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

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get saveButton => 'Speichern';

  @override
  String get retryButton => 'Noch einmal versuchen';

  @override
  String get signOutButton => 'Abmelden';

  @override
  String get noFinancialAdvice => 'Taleria ist ein Lernspiel und keine Finanzberatung. Alle Beträge sind virtuell.';

  @override
  String get failureNetwork => 'Keine Verbindung zum Server. Bitte prüfe das Internet und versuche es noch einmal.';

  @override
  String get failureInvalidCredentials => 'E-Mail oder Passwort stimmt nicht.';

  @override
  String get failureEmailNotConfirmed =>
      'Bitte bestätige zuerst deine E-Mail-Adresse. Den Link findest du in unserer E-Mail.';

  @override
  String get failureEmailTaken => 'Für diese E-Mail-Adresse gibt es schon ein Konto. Bitte melde dich an.';

  @override
  String get failureWeakPassword => 'Dieses Passwort ist zu leicht zu erraten. Bitte wähle ein anderes.';

  @override
  String get failureRateLimited => 'Zu viele Versuche. Bitte warte kurz und versuche es dann noch einmal.';

  @override
  String get failureNotAllowed => 'Das ist mit diesem Konto nicht erlaubt.';

  @override
  String get failureUnknown => 'Da ist etwas schiefgegangen. Bitte versuche es noch einmal.';

  @override
  String get welcomeTitle => 'Willkommen in Taleria';

  @override
  String get welcomeSubtitle => 'Lerne mit Talo und Tala, gut mit Geld umzugehen.';

  @override
  String get welcomeChildButton => 'Ich habe einen Code';

  @override
  String get welcomeParentButton => 'Für Eltern: anmelden oder registrieren';

  @override
  String get welcomeOfflineHint => 'Ohne Server gibt es noch keine Konten. Du kannst dir die Vorschau ansehen.';

  @override
  String get welcomeOfflinePreview => 'Vorschau ohne Konto';

  @override
  String get parentAuthTitle => 'Eltern-Konto';

  @override
  String get parentAuthRegisterTab => 'Registrieren';

  @override
  String get parentAuthLoginTab => 'Anmelden';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String passwordHint(int min) {
    return 'Mindestens $min Zeichen';
  }

  @override
  String get emailEmpty => 'Bitte gib deine E-Mail-Adresse ein.';

  @override
  String get emailInvalid => 'Diese E-Mail-Adresse sieht nicht richtig aus.';

  @override
  String passwordTooShort(int min) {
    return 'Das Passwort braucht mindestens $min Zeichen.';
  }

  @override
  String get consentLabel =>
      'Ich bin einverstanden, dass Taleria meine Daten und die Daten meines Kindes gemäß der Datenschutzerklärung verarbeitet. (Pflicht)';

  @override
  String get consentRequired => 'Ohne diese Einwilligung können wir kein Konto anlegen.';

  @override
  String get marketingLabel =>
      'Ich möchte etwa einmal im Monat per E-Mail erfahren, was es Neues in Taleria gibt. (freiwillig, jederzeit abbestellbar)';

  @override
  String get registerButton => 'Konto anlegen';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get checkEmailTitle => 'Fast geschafft!';

  @override
  String get checkEmailBody =>
      'Wir haben dir eine E-Mail geschickt. Bitte bestätige deine Adresse und melde dich dann hier an.';

  @override
  String get setPinTitle => 'Eltern-PIN festlegen';

  @override
  String get setPinBody =>
      'Mit dieser PIN öffnest du auf diesem Gerät den Leuchtturm, den Bereich für Eltern. Dein Kind sollte sie nicht kennen.';

  @override
  String get pinLabel => 'PIN (4 bis 6 Ziffern)';

  @override
  String get pinRepeatLabel => 'PIN wiederholen';

  @override
  String get pinFormat => 'Die PIN besteht aus 4 bis 6 Ziffern.';

  @override
  String get pinTooSimple => 'Diese PIN ist zu leicht zu erraten, zum Beispiel 1111 oder 1234.';

  @override
  String get pinMismatch => 'Die beiden PINs sind nicht gleich.';

  @override
  String get pinSaveButton => 'PIN speichern';

  @override
  String get pinGateBody => 'Bitte gib die Eltern-PIN ein.';

  @override
  String get pinGateUnlock => 'Öffnen';

  @override
  String get pinWrong => 'Die PIN stimmt nicht.';

  @override
  String pinLocked(String time) {
    return 'Zu viele Versuche. Du kannst es um $time Uhr wieder versuchen.';
  }

  @override
  String get pinForgot => 'PIN vergessen? Mit Passwort neu anmelden';

  @override
  String get pinBackToChild => 'Zurück an Bord';

  @override
  String get pinChanged => 'Die neue PIN ist gespeichert.';

  @override
  String get lighthouseTitle => 'Leuchtturm';

  @override
  String get lighthouseChildrenHeading => 'Kinder-Profile';

  @override
  String get lighthouseNoChildren => 'Noch kein Kinder-Profil. Lege jetzt eins an.';

  @override
  String get lighthouseAddChild => 'Kinder-Profil anlegen';

  @override
  String get lighthouseAccountHeading => 'Konto';

  @override
  String get lighthouseChangePin => 'Eltern-PIN ändern';

  @override
  String get lighthouseDeleteAccount => 'Konto löschen';

  @override
  String get lighthouseShowAssets => 'Grafik-Übersicht (nur Testumgebung)';

  @override
  String get deleteAccountTitle => 'Konto wirklich löschen?';

  @override
  String get deleteAccountBody =>
      'Dein Konto, alle Kinder-Profile und alle Daten werden endgültig gelöscht. Angemeldete Kinder-Geräte werden abgemeldet. Das lässt sich nicht rückgängig machen.';

  @override
  String get deleteConfirm => 'Endgültig löschen';

  @override
  String get levelBeginner => 'Einsteiger';

  @override
  String get levelAdvanced => 'Fortgeschritten';

  @override
  String childSubtitle(int year, String level) {
    return 'Jahrgang $year · $level';
  }

  @override
  String get childFormNewTitle => 'Neues Kinder-Profil';

  @override
  String get childFormEditTitle => 'Profil bearbeiten';

  @override
  String get nicknameLabel => 'Spitzname';

  @override
  String get nicknameHint => 'Ein Spitzname reicht, ein echter Name ist nicht nötig.';

  @override
  String get nicknameTooShort => 'Der Spitzname braucht mindestens 2 Zeichen.';

  @override
  String get nicknameTooLong => 'Der Spitzname darf höchstens 20 Zeichen haben.';

  @override
  String get nicknameInvalid => 'Bitte nur Buchstaben, Ziffern, Leerzeichen oder Bindestrich.';

  @override
  String get birthYearLabel => 'Geburtsjahr';

  @override
  String get birthYearHint => 'Empfohlen ab 10 Jahren. Du entscheidest, wann dein Kind startet.';

  @override
  String get levelLabel => 'Niveau';

  @override
  String get childDetailCodeHeading => 'Gerät deines Kindes anmelden';

  @override
  String get childDetailCodeBody =>
      'Erzeuge einen Code und gib ihn auf dem Gerät deines Kindes unter „Ich habe einen Code“ ein.';

  @override
  String get childDetailCreateCode => 'Anmeldecode erzeugen';

  @override
  String childDetailCodeValid(String time) {
    return 'Gültig bis $time Uhr und nur einmal nutzbar.';
  }

  @override
  String get childDetailPlayHereHeading => 'Auf diesem Gerät spielen';

  @override
  String get childDetailPlayHereBody =>
      'Dein Kind spielt auf diesem Gerät. Zurück in den Leuchtturm geht es nur mit deiner PIN.';

  @override
  String childDetailPlayHereButton(String nickname) {
    return 'Gerät an $nickname übergeben';
  }

  @override
  String childDetailDevices(int count) {
    return 'Angemeldete Geräte: $count';
  }

  @override
  String get childDetailSignOutDevices => 'Alle Geräte abmelden';

  @override
  String get childDetailSignedOut => 'Alle Geräte wurden abgemeldet.';

  @override
  String get childDetailEdit => 'Profil bearbeiten';

  @override
  String get childDetailDelete => 'Profil löschen';

  @override
  String deleteChildTitle(String nickname) {
    return '$nickname wirklich löschen?';
  }

  @override
  String get deleteChildBody =>
      'Das Profil und alle Fortschritte werden endgültig gelöscht. Angemeldete Geräte werden abgemeldet.';

  @override
  String get childCodeTitle => 'An Bord kommen';

  @override
  String get childCodeBody => 'Gib den Code ein, den deine Eltern im Leuchtturm für dich erzeugt haben.';

  @override
  String get childCodeLabel => 'Code';

  @override
  String get childCodeButton => 'An Bord gehen';

  @override
  String get childCodeIncomplete => 'Der Code hat 8 Zeichen.';

  @override
  String get childCodeInvalid =>
      'Dieser Code passt nicht. Vielleicht ist er schon benutzt oder abgelaufen. Frag deine Eltern nach einem neuen.';

  @override
  String childHomeWelcome(String nickname) {
    return 'Willkommen an Bord, $nickname!';
  }

  @override
  String get childHomeLighthouseHint =>
      'Der Leuchtturm ist der Bereich für deine Eltern. Er öffnet sich auf ihrem Gerät.';

  @override
  String get problemNoParentTitle => 'Kein Eltern-Konto';

  @override
  String get problemNoParentBody => 'Dieses Konto gehört zu keinem Eltern-Konto von Taleria.';

  @override
  String get passwordEmpty => 'Bitte gib dein Passwort ein.';

  @override
  String get birthYearMissing => 'Bitte wähle das Geburtsjahr.';

  @override
  String get speakerTalo => 'Talo';

  @override
  String get speakerTala => 'Tala';

  @override
  String get introStoryTalo1 => 'Ahoi! Ich bin Talo, der Kapitän. Ich habe einen Kompass und meistens einen Plan.';

  @override
  String get introStoryTala1 =>
      'Und ich bin Tala, die Zahlmeisterin! Ich passe auf unsere Schatztruhe auf. Meistens jedenfalls.';

  @override
  String get introStoryTalo2 =>
      'Heute Morgen ist eine Flaschenpost angetrieben. Darin war ein Stück einer alten Schatzkarte!';

  @override
  String get introStoryTala2 =>
      'Meister Taleron, der Hüter des Meeres, hat die Karte zerrissen und die Teile auf den Inseln versteckt. Nur eine kluge Crew findet den Schatz.';

  @override
  String get introStoryTalo3 => 'Unsere Bordkasse ist leer, und wir brauchen Verstärkung. Willst du in unsere Crew?';

  @override
  String get introJoinButton => 'Ja, ich bin dabei!';

  @override
  String get introNext => 'Weiter';

  @override
  String get avatarTitle => 'Wie siehst du aus?';

  @override
  String get avatarSkin => 'Hautfarbe';

  @override
  String get avatarHairStyle => 'Frisur';

  @override
  String get avatarHairColor => 'Haarfarbe';

  @override
  String get avatarOutfit => 'Jacke';

  @override
  String get avatarHat => 'Kopfbedeckung';

  @override
  String get avatarHairShort => 'Kurz';

  @override
  String get avatarHairLong => 'Lang';

  @override
  String get avatarHairCurly => 'Locken';

  @override
  String get avatarHairBraid => 'Zopf';

  @override
  String get avatarHairNone => 'Keine';

  @override
  String get avatarHatNone => 'Keine';

  @override
  String get avatarHatCaptain => 'Kapitänsmütze';

  @override
  String get avatarHatBandana => 'Kopftuch';

  @override
  String get avatarHatStraw => 'Strohhut';

  @override
  String avatarColorOption(String group, int number) {
    return '$group $number';
  }

  @override
  String get avatarDone => 'So sehe ich aus!';

  @override
  String get shipTitle => 'Taufe dein Schiff';

  @override
  String get shipBody => 'Jedes Schiff braucht einen Namen. Wie soll unseres heißen?';

  @override
  String get shipLabel => 'Name des Schiffs';

  @override
  String get shipSuggestions => 'Seestern|Goldmöwe|Wellenreiter|Sturmvogel';

  @override
  String get shipButton => 'Schiff taufen';

  @override
  String get shipNameTooShort => 'Der Name braucht mindestens 2 Zeichen.';

  @override
  String get shipNameTooLong => 'Der Name darf höchstens 30 Zeichen haben.';

  @override
  String get tourTitle => 'Rundgang an Bord';

  @override
  String get tourMapTitle => 'Die Karte';

  @override
  String get tourMapBody =>
      'Auf der Karte siehst du alle Inseln. Jede Insel hat ein Thema und versteckt ein Stück der Schatzkarte.';

  @override
  String get tourChestTitle => 'Die Schatztruhe';

  @override
  String get tourChestBody => 'In der Schatztruhe sammelst du deine Taler und deine Wunschschätze.';

  @override
  String get tourLogbookTitle => 'Das Logbuch';

  @override
  String get tourLogbookBody => 'Im Logbuch steht, was du schon geschafft hast: Seemeilen, Orden und dein Rang.';

  @override
  String get tourDone => 'Verstanden!';

  @override
  String get wishTitle => 'Dein erster Wunschschatz';

  @override
  String get wishBody =>
      'Wofür würdest du gern sparen? Ein Wunschschatz ist etwas, das du dir wünschst und wofür du Taler sammelst.';

  @override
  String get wishTitleLabel => 'Was wünschst du dir?';

  @override
  String get wishAmountLabel => 'Ungefähr wie viel kostet das? (in Euro)';

  @override
  String get wishAmountHint => 'Schätzen ist völlig in Ordnung.';

  @override
  String get wishSave => 'In die Schatztruhe legen';

  @override
  String get wishSkip => 'Weiß ich noch nicht';

  @override
  String get wishTitleTooShort => 'Schreib mindestens 2 Zeichen.';

  @override
  String get wishTitleTooLong => 'Höchstens 40 Zeichen, bitte.';

  @override
  String get wishAmountInvalid => 'Bitte eine ganze Zahl von 1 bis 10000.';

  @override
  String doneTitle(String nickname) {
    return 'Willkommen in der Crew, $nickname!';
  }

  @override
  String get doneRank => 'Dein Rang: Schiffsjunge';

  @override
  String doneXp(int xp) {
    return '+$xp Seemeilen';
  }

  @override
  String get doneWish => 'Dein Wunschschatz liegt in der Schatztruhe.';

  @override
  String get doneMapButton => 'Karte öffnen';

  @override
  String get mapOpenTitle => 'Die Karte ist offen!';

  @override
  String get mapOpenBody => 'Euer erstes Ziel: der Hafen von Taleria.';

  @override
  String get mapStartButton => 'Los geht\'s';

  @override
  String get mapTitle => 'Karte';

  @override
  String childHomeShip(String ship) {
    return 'Dein Schiff: $ship';
  }

  @override
  String get childHomeMapButton => 'Zur Karte';

  @override
  String get childHomeIntroAgain => 'Intro noch einmal ansehen';

  @override
  String lighthouseChildShip(String ship) {
    return 'Schiff: $ship';
  }

  @override
  String get lighthouseIntroPending => 'Intro noch nicht abgeschlossen';

  @override
  String get avatarSpecies => 'Figur';

  @override
  String get avatarSpeciesHuman => 'Mensch';

  @override
  String get avatarSpeciesCat => 'Katze';

  @override
  String get avatarSpeciesDog => 'Hund';

  @override
  String get avatarSpeciesBear => 'Bär';

  @override
  String get avatarSpeciesRabbit => 'Hase';

  @override
  String get avatarSpeciesMouse => 'Maus';

  @override
  String get avatarFur => 'Fellfarbe';

  @override
  String get mapIslandLocked => 'Diese Insel ist noch verschlossen. Schließ zuerst die Insel davor ab.';

  @override
  String get mapIslandFog => 'Diese Insel taucht bald auf.';

  @override
  String mapIslandFogTitle(String title) {
    return '$title?';
  }

  @override
  String get mapYouAreHere => 'Dein Schiff';

  @override
  String get islandStationsHeading => 'Stationen';

  @override
  String get islandArrivalAgain => 'Ankunft noch einmal ansehen';

  @override
  String get islandAllDone => 'Alle Stationen geschafft. Das Kartenstück gehört euch!';

  @override
  String stationNumber(int number) {
    return 'Station $number';
  }

  @override
  String get stationExam => 'Abschlussprüfung';

  @override
  String get stationLocked => 'Diese Station öffnet sich, wenn du die Station davor geschafft hast.';

  @override
  String get stationIntroDone => 'Hier hat deine Reise begonnen.';

  @override
  String get stationDone => 'Geschafft';

  @override
  String get stationBonus => 'Flaschenpost';

  @override
  String get warmUpTitle => 'Weißt du noch?';

  @override
  String get warmUpHint => 'Zwei kurze Fragen zur letzten Station. Fehler sind kein Problem.';

  @override
  String get quizCheckTitle => 'Kurzer Check';

  @override
  String quizProgress(int current, int total) {
    return 'Frage $current von $total';
  }

  @override
  String get quizCorrect => 'Richtig!';

  @override
  String get quizWrong => 'Nicht ganz.';

  @override
  String get quizNext => 'Nächste Frage';

  @override
  String get quizFinish => 'Fertig';

  @override
  String gamePlaceholderTitle(String title) {
    return 'Spiel: $title';
  }

  @override
  String get gamePlaceholderBody => 'Dieses Spiel wird gerade gebaut. Bald kannst du es hier spielen.';

  @override
  String get resultTitle => 'Station geschafft!';

  @override
  String resultCorrect(int correct, int total) {
    return '$correct von $total richtig';
  }

  @override
  String get resultBack => 'Zurück zur Insel';

  @override
  String get examPassedTitle => 'Prüfung bestanden!';

  @override
  String get examFailedTitle => 'Noch nicht ganz';

  @override
  String examFailedBody(int pass) {
    return 'Du brauchst $pass richtige Antworten. Versuch es noch einmal, ohne Strafe. Du bekommst neue Fragen.';
  }

  @override
  String get examRetry => 'Noch einmal versuchen';

  @override
  String get islandCompletedTitle => 'Kartenstück gefunden!';

  @override
  String islandCompletedBadge(String badge) {
    return 'Neuer Orden: $badge';
  }

  @override
  String get islandCompletedNext => 'Die nächste Insel ist jetzt offen.';

  @override
  String get islandCompletedButton => 'Zur Karte';
}
