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

  @override
  String get childHomeTreasureButton => 'Schatztruhe';

  @override
  String get childHomeTasksButton => 'Aufträge';

  @override
  String childHomeTasksOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offene Aufträge',
      one: '1 offener Auftrag',
      zero: 'Keine offenen Aufträge',
    );
    return '$_temp0';
  }

  @override
  String get treasureTitle => 'Deine Truhen';

  @override
  String get potSpendChild => 'Bordkasse';

  @override
  String get potSaveChild => 'Schatztruhe';

  @override
  String get potGiveChild => 'Glückstruhe';

  @override
  String get potSpendHint => 'Zum Ausgeben';

  @override
  String get potSaveHint => 'Zum Sparen für deine Wunschschätze';

  @override
  String get potGiveHint => 'Zum Verschenken und Spenden';

  @override
  String get treasureMove => 'Umbuchen';

  @override
  String get treasureSpend => 'Ausgabe eintragen';

  @override
  String get treasureGive => 'Geschenk eintragen';

  @override
  String treasureAllowance(String amount, String interval) {
    return 'Deine Heuer: $amount $interval';
  }

  @override
  String treasureAllowanceNext(String date) {
    return 'Nächste Heuer am $date';
  }

  @override
  String get treasureNoAllowance => 'Noch keine Heuer. Frag deine Eltern!';

  @override
  String get treasureVirtual =>
      'Alle Beträge sind virtuell. Die App zählt mit, das echte Geld bekommst du von deinen Eltern.';

  @override
  String get allowanceWeekly => 'pro Woche';

  @override
  String get allowanceMonthly => 'pro Monat';

  @override
  String get goalsHeading => 'Wunschschätze';

  @override
  String get goalsEmpty => 'Noch kein Wunschschatz. Lege einen an!';

  @override
  String get goalNew => 'Neuer Wunschschatz';

  @override
  String goalProgress(String saved, String target) {
    return '$saved von $target';
  }

  @override
  String get goalRedeem => 'Einlösen';

  @override
  String get goalReached => 'Erfüllt!';

  @override
  String goalRedeemTitle(String title) {
    return '$title einlösen?';
  }

  @override
  String goalRedeemBody(String amount) {
    return '$amount gehen aus der Schatztruhe. Viel Spaß mit deinem Wunsch!';
  }

  @override
  String get goalDelete => 'Löschen';

  @override
  String goalDeleteTitle(String title) {
    return '$title löschen?';
  }

  @override
  String get goalTitleLabel => 'Was wünschst du dir?';

  @override
  String get goalTargetLabel => 'Wie viel kostet es? (in Euro)';

  @override
  String get ledgerHeading => 'Kassenbuch';

  @override
  String get ledgerEmpty => 'Noch keine Buchungen.';

  @override
  String get ledgerAllowance => 'Heuer';

  @override
  String get ledgerTask => 'Auftrag';

  @override
  String get ledgerTransfer => 'Umgebucht';

  @override
  String get ledgerManual => 'Korrektur';

  @override
  String get ledgerGoal => 'Wunschschatz eingelöst';

  @override
  String get ledgerPurchase => 'Ausgabe';

  @override
  String get ledgerDonation => 'Geschenk';

  @override
  String get moveTitle => 'Umbuchen';

  @override
  String get moveFrom => 'Von';

  @override
  String get moveTo => 'Nach';

  @override
  String get amountLabel => 'Betrag in Euro';

  @override
  String get amountHint => 'zum Beispiel 2,50';

  @override
  String get amountInvalid => 'Bitte einen Betrag wie 2,50 eingeben.';

  @override
  String get amountZero => 'Der Betrag muss größer als 0 sein.';

  @override
  String amountTooLarge(String max) {
    return 'Höchstens $max.';
  }

  @override
  String get notEnoughMoney => 'So viel ist nicht in der Truhe.';

  @override
  String get noteLabel => 'Wofür? (freiwillig)';

  @override
  String get bookButton => 'Buchen';

  @override
  String get spendTitle => 'Ausgabe eintragen';

  @override
  String get giveTitle => 'Geschenk eintragen';

  @override
  String get tasksTitle => 'Aufträge';

  @override
  String get tasksOpenHeading => 'Offen';

  @override
  String get tasksWaitingHeading => 'Wartet auf deine Eltern';

  @override
  String get tasksDoneHeading => 'Erledigt';

  @override
  String get tasksEmpty => 'Gerade keine Aufträge. Deine Eltern können im Leuchtturm welche anlegen.';

  @override
  String get taskDoneButton => 'Erledigt!';

  @override
  String taskReward(String amount) {
    return '+$amount';
  }

  @override
  String get taskChore => 'Pflicht';

  @override
  String taskRejected(String note) {
    return 'Noch nicht ganz: $note';
  }

  @override
  String get taskRejectedNoNote => 'Deine Eltern möchten, dass du noch einmal nachschaust.';

  @override
  String get taskResubmit => 'Nochmal melden';

  @override
  String get taskSubmitted => 'Super! Jetzt müssen deine Eltern bestätigen.';

  @override
  String get budgetTitle => 'Taschengeld und Aufgaben';

  @override
  String pendingTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufgaben warten auf Bestätigung',
      one: '1 Aufgabe wartet auf Bestätigung',
      zero: 'Keine Aufgaben warten',
    );
    return '$_temp0';
  }

  @override
  String get parentPotSpend => 'Ausgeben';

  @override
  String get parentPotSave => 'Sparen';

  @override
  String get parentPotGive => 'Verschenken';

  @override
  String get allowanceHeading => 'Taschengeld';

  @override
  String get allowanceNone => 'Kein Taschengeld festgelegt.';

  @override
  String allowanceCurrent(String amount, String interval, String date) {
    return '$amount $interval, nächste Zahlung am $date';
  }

  @override
  String get allowanceSet => 'Taschengeld festlegen';

  @override
  String get allowanceStop => 'Taschengeld beenden';

  @override
  String get allowanceIntervalLabel => 'Rhythmus';

  @override
  String get allowanceWeeklyOption => 'wöchentlich';

  @override
  String get allowanceMonthlyOption => 'monatlich';

  @override
  String allowanceFirstPayout(String date) {
    return 'Erste Zahlung: $date';
  }

  @override
  String get allowanceHint => 'Das Taschengeld ist virtuell: Die App zählt mit, auszahlen tut ihr es selbst.';

  @override
  String get tasksParentHeading => 'Aufgaben';

  @override
  String get taskCreate => 'Aufgabe anlegen';

  @override
  String get taskTitleLabel => 'Aufgabe';

  @override
  String get taskRewardLabel => 'Belohnung in Euro';

  @override
  String get taskChoreLabel => 'Pflicht ohne Belohnung';

  @override
  String get taskTitleInvalid => 'Bitte 2 bis 60 Zeichen.';

  @override
  String get taskApprove => 'Bestätigen';

  @override
  String get taskReject => 'Ablehnen';

  @override
  String get taskRejectNoteLabel => 'Nachricht an dein Kind (freiwillig)';

  @override
  String get taskStatusOpen => 'Offen';

  @override
  String get taskStatusSubmitted => 'Gemeldet';

  @override
  String get taskStatusApproved => 'Bestätigt';

  @override
  String get taskStatusRejected => 'Abgelehnt';

  @override
  String get taskDelete => 'Aufgabe löschen';

  @override
  String get tasksParentEmpty => 'Noch keine Aufgaben.';

  @override
  String get balanceHeading => 'Kontostand';

  @override
  String get manualBooking => 'Korrektur buchen';

  @override
  String get manualHint => 'Positiv ist eine Gutschrift, mit Minus ein Abzug (zum Beispiel -2,50).';

  @override
  String get potLabel => 'Truhe';

  @override
  String rankName(String rank) {
    String _temp0 = intl.Intl.selectLogic(rank, {
      'schiffsjunge': 'Schiffsjunge',
      'matrose': 'Matrose',
      'bootsmann': 'Bootsmann',
      'steuermann': 'Steuermann',
      'kapitaen': 'Kapitän',
      'other': 'Neu an Bord',
    });
    return '$_temp0';
  }

  @override
  String statsXp(int xp) {
    final intl.NumberFormat xpNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String xpString = xpNumberFormat.format(xp);

    return '$xpString Seemeilen';
  }

  @override
  String statsNextRank(int xp, String rank) {
    final intl.NumberFormat xpNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String xpString = xpNumberFormat.format(xp);

    return 'Noch $xpString Seemeilen bis $rank';
  }

  @override
  String get statsNextRankCertificate => 'Finde die Goldene Schatzkarte, dann wirst du Kapitän.';

  @override
  String get statsTopRank => 'Du hast den höchsten Rang erreicht!';

  @override
  String get statsNoRank => 'Nach dem Intro wirst du Schiffsjunge.';

  @override
  String streakWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks Wochen Fahrtwind',
      one: '1 Woche Fahrtwind',
      zero: 'Noch kein Fahrtwind',
    );
    return '$_temp0';
  }

  @override
  String get streakPaused => 'Fahrtwind macht gerade Pause';

  @override
  String get streakHint => 'Jede Woche, in der du segelst, bringt Fahrtwind.';

  @override
  String badgesButton(int count) {
    return 'Meine Orden ($count)';
  }

  @override
  String get badgesTitle => 'Meine Orden';

  @override
  String get badgesEmpty => 'Noch keine Orden. Schließe deine erste Insel ab!';

  @override
  String badgeEarnedOn(String date) {
    return 'Verliehen am $date';
  }

  @override
  String get badgeNotYet => 'Noch nicht gefunden';

  @override
  String get windNeededShort => 'Das Schiff braucht Wind.';

  @override
  String windNeeded(String weekday) {
    return 'Das Schiff braucht Wind. Die nächste Station erreichst du am $weekday.';
  }

  @override
  String get windNeededSoon => 'Das Schiff braucht Wind. Bald geht es weiter.';

  @override
  String get windMeanwhile => 'Bis dahin kannst du fertige Stationen wiederholen oder Begegnungen auf See lösen.';

  @override
  String weekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Montag',
      '2': 'Dienstag',
      '3': 'Mittwoch',
      '4': 'Donnerstag',
      '5': 'Freitag',
      '6': 'Samstag',
      '7': 'Sonntag',
      'other': 'nächsten Tag',
    });
    return '$_temp0';
  }

  @override
  String get stationNoWind => 'Wartet auf Wind';

  @override
  String mapEncounterButton(String title) {
    return '$title taucht auf!';
  }

  @override
  String get mapEncounterNone => 'Gerade ist alles ruhig auf See. Schau später wieder vorbei.';

  @override
  String encounterProgress(int current, int total) {
    return 'Rätsel $current von $total';
  }

  @override
  String get encounterTryAgain => 'Nochmal versuchen';

  @override
  String get encounterNext => 'Nächstes Rätsel';

  @override
  String get encounterFinish => 'Fertig';

  @override
  String get encounterDoneTitle => 'Der Weg ist frei!';

  @override
  String encounterFirstTry(int correct, int total) {
    return 'Beim ersten Versuch richtig: $correct von $total';
  }

  @override
  String get encounterNoXpToday => 'Seemeilen für Begegnungen gibt es einmal am Tag. Für heute hast du sie schon.';

  @override
  String get encounterBack => 'Zurück zur Karte';

  @override
  String rankUpTitle(String rank) {
    return 'Neuer Rang: $rank!';
  }

  @override
  String get badgeTapToContinue => 'Weiter';

  @override
  String get paceHeading => 'Tempo und Serie';

  @override
  String get paceLabel => 'Neue Stationen pro Woche';

  @override
  String get paceFree => 'Frei';

  @override
  String get paceHint =>
      'Standard sind 2 neue Stationen pro Woche (Montag und Donnerstag). Wiederholen geht immer. In den Ferien passt „Frei“.';

  @override
  String get paceSaved => 'Tempo gespeichert.';

  @override
  String get streakPauseLabel => 'Serie pausieren';

  @override
  String get streakPauseHint => 'Zum Beispiel in den Ferien: Wochen ohne Lernen beenden die Serie dann nicht.';

  @override
  String parentLevel(int level, String rank) {
    return 'Level $level ($rank)';
  }

  @override
  String parentProgressXp(int xp) {
    final intl.NumberFormat xpNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String xpString = xpNumberFormat.format(xp);

    return 'Fortschritt: $xpString Seemeilen';
  }

  @override
  String parentBadges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Abzeichen',
      one: '1 Abzeichen',
      zero: 'Noch keine Abzeichen',
    );
    return '$_temp0';
  }

  @override
  String parentStreak(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Serie: $weeks Wochen',
      one: 'Serie: 1 Woche',
      zero: 'Keine laufende Serie',
    );
    return '$_temp0';
  }

  @override
  String get parentStreakPaused => 'Serie pausiert';

  @override
  String get stationDive => 'Ankerplatz';

  @override
  String get diveTitle => 'Perlentauchen';

  @override
  String get diveHint => 'Jede richtige Antwort ist eine Perle.';

  @override
  String get wreckTitle => 'Im Wrack';

  @override
  String get wreckDone => 'Wieder auftauchen';

  @override
  String get diveResultTitle => 'Wieder an Bord!';

  @override
  String divePearls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Perlen gefunden',
      one: '1 Perle gefunden',
      zero: 'Diesmal keine Perle, beim nächsten Mal klappt es',
    );
    return '$_temp0';
  }

  @override
  String diveFind(String title) {
    return 'Fund für deine Sammlung: $title';
  }

  @override
  String gameSortProgress(int current, int total) {
    return 'Karte $current von $total';
  }

  @override
  String get gameSortWrong => 'Passt nicht ganz. Versuch einen anderen Korb.';

  @override
  String get gameSortRight => 'Passt!';

  @override
  String get gameNextCard => 'Nächste Karte';

  @override
  String get gameOrderWrong => 'Noch nicht. Was kommt davor?';

  @override
  String gameOrderPlaced(int count, int total) {
    return '$count von $total an der richtigen Stelle';
  }

  @override
  String get gameDone => 'Geschafft!';

  @override
  String collectionButton(int count) {
    return 'Unterwasser-Sammlung ($count)';
  }

  @override
  String get collectionTitle => 'Unterwasser-Sammlung';

  @override
  String collectionPearls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Perlen',
      one: '1 Perle',
      zero: 'Noch keine Perlen',
    );
    return '$_temp0';
  }

  @override
  String get collectionEmpty => 'Noch keine Funde. An jedem Ankerplatz liegt etwas im Wrack.';

  @override
  String collectionFoundOn(String date) {
    return 'Gefunden am $date';
  }

  @override
  String get fogAheadTitle => 'Die nächste Insel liegt noch im Nebel.';

  @override
  String get fogAheadBody => 'Bis sie auftaucht, kannst du Kontrollfahrten machen, tauchen und Spiele wiederholen.';

  @override
  String get fogAheadButton => 'Kontrollfahrt starten';

  @override
  String get childDetailProgress => 'Fortschritt und Lernstand';

  @override
  String get childDetailKitchen => 'Kombüsen-Fragen';

  @override
  String get childDetailKitchenHint => 'Gesprächsideen und Aufträge fürs echte Leben';

  @override
  String progressTitle(String nickname) {
    return '$nickname: Fortschritt';
  }

  @override
  String parentCollection(int finds, int pearls) {
    String _temp0 = intl.Intl.pluralLogic(
      finds,
      locale: localeName,
      other: '$finds Fundstücke',
      one: '1 Fundstück',
      zero: 'Noch keine Fundstücke',
    );
    return '$_temp0 · Perlen: $pearls';
  }

  @override
  String lastActive(String date) {
    return 'Zuletzt aktiv am $date';
  }

  @override
  String get lastActiveNever => 'Noch nicht gespielt';

  @override
  String get islandsHeading => 'Inseln';

  @override
  String islandStatusCompleted(String date) {
    return 'Abgeschlossen am $date';
  }

  @override
  String islandStatusProgress(int done, int total) {
    return '$done von $total Stationen geschafft';
  }

  @override
  String get islandStatusLocked => 'Noch gesperrt';

  @override
  String get islandStatusFog => 'Inhalt folgt';

  @override
  String get learningHeading => 'Lernstand';

  @override
  String get learningHint =>
      'Der Lernstand kommt aus den Wiederholungen. „Sicher“ heißt: auch nach Tagen noch gewusst. „Wackelt noch“ heißt: zuletzt falsch beantwortet, das kommt in den nächsten Wiederholungen wieder dran.';

  @override
  String get topicSecure => 'Sicher';

  @override
  String get topicLearning => 'Wird geübt';

  @override
  String get topicShaky => 'Wackelt noch';

  @override
  String get topicNotStarted => 'Noch nicht dran';

  @override
  String topicAnswered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fragen beantwortet',
      one: '1 Frage beantwortet',
    );
    return '$_temp0';
  }

  @override
  String get kitchenTitle => 'Kombüsen-Fragen';

  @override
  String kitchenIntro(String nickname) {
    return 'Gesprächsideen für den Familientisch, passend zu dem, was $nickname gerade lernt.';
  }

  @override
  String kitchenNone(String nickname) {
    return 'Sobald $nickname die erste Insel betritt, gibt es hier Gesprächsideen.';
  }

  @override
  String get kitchenCurrent => 'Gerade dran';

  @override
  String get realLifeTaskHeading => 'Auftrag fürs echte Leben';

  @override
  String get realLifeTaskCreate => 'Als Aufgabe anlegen';

  @override
  String realLifeTaskCreated(String nickname) {
    return 'Aufgabe angelegt. Sie steht jetzt bei $nickname unter den Aufträgen.';
  }

  @override
  String get pendingOverviewTitle => 'Wartet auf deine Bestätigung';
}
