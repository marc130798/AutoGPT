import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/services/session_controller.dart';

import '../fakes.dart';

void main() {
  late FakeBackend backend;
  late FakeLocalSettings settings;
  late DateTime now;

  setUp(() {
    backend = FakeBackend();
    settings = FakeLocalSettings();
    now = DateTime(2026, 10, 9, 10);
  });

  /// Startet die App neu (neuer Controller, gleicher Server und gleiches Gerät).
  Future<SessionController> launch() async {
    final controller = SessionController(
      auth: FakeAuthRepository(backend),
      family: FakeFamilyRepository(backend),
      settings: settings,
      clock: () => now,
    );
    await controller.start();
    return controller;
  }

  test('Ohne Server: Vorschau', () async {
    final controller = SessionController(auth: null, family: null, settings: settings);
    await controller.start();
    expect(controller.state, isA<SessionOffline>());
  });

  test('Ohne Anmeldung: Willkommen', () async {
    expect((await launch()).state, isA<SessionSignedOut>());
  });

  group('Eltern', () {
    test('Registrierung: erst PIN festlegen, dann Leuchtturm offen', () async {
      final session = await launch();
      final hasSession = await session.registerParent(
        email: 'neu@test.invalid',
        password: 'sehrgeheim123',
        marketingConsent: false,
      );
      expect(hasSession, isTrue);
      var state = session.state as SessionParent;
      expect(state.parent.hasPin, isFalse);

      await session.setParentPin('2468');
      state = session.state as SessionParent;
      expect(state.parent.hasPin, isTrue);
      expect(state.unlocked, isTrue);
    });

    test('Registrierung mit E-Mail-Bestätigung: noch keine Sitzung', () async {
      backend.requireEmailConfirmation = true;
      final session = await launch();
      final hasSession = await session.registerParent(
        email: 'neu@test.invalid',
        password: 'sehrgeheim123',
        marketingConsent: true,
      );
      expect(hasSession, isFalse);
      expect(session.state, isA<SessionSignedOut>());
    });

    test('Zu einfache PIN wird gar nicht erst gesendet', () async {
      backend.addParent();
      backend.signInAs('eltern@test.invalid');
      final session = await launch();
      expect(() => session.setParentPin('1234'), throwsArgumentError);
    });

    test('App-Neustart: Leuchtturm ist gesperrt, nur richtige PIN öffnet', () async {
      backend.addParent(pin: '2468');
      backend.signInAs('eltern@test.invalid');
      final session = await launch();
      expect((session.state as SessionParent).unlocked, isFalse);

      final wrong = await session.unlockWithPin('1357');
      expect(wrong.status, PinCheckStatus.wrong);
      expect((session.state as SessionParent).unlocked, isFalse);

      final ok = await session.unlockWithPin('2468');
      expect(ok.status, PinCheckStatus.ok);
      expect((session.state as SessionParent).unlocked, isTrue);
    });

    test('Anmeldung mit Passwort öffnet den Leuchtturm ohne PIN', () async {
      backend.addParent(pin: '2468');
      final session = await launch();
      await session.signInParent(email: 'eltern@test.invalid', password: 'sehrgeheim123');
      expect((session.state as SessionParent).unlocked, isTrue);
    });

    test('Falsches Passwort', () async {
      backend.addParent();
      final session = await launch();
      expect(
        () => session.signInParent(email: 'eltern@test.invalid', password: 'falsch'),
        throwsA(isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.invalidCredentials)),
      );
    });

    test('Nach 5 Minuten im Hintergrund ist der Leuchtturm wieder gesperrt', () async {
      backend.addParent(pin: '2468');
      final session = await launch();
      await session.signInParent(email: 'eltern@test.invalid', password: 'sehrgeheim123');

      session.appPaused();
      now = now.add(const Duration(minutes: 1));
      session.appResumed();
      expect((session.state as SessionParent).unlocked, isTrue, reason: 'kurze Pause');

      session.appPaused();
      now = now.add(SessionController.relockAfter);
      session.appResumed();
      expect((session.state as SessionParent).unlocked, isFalse, reason: 'lange Pause');
    });

    test('Konto löschen: zurück zum Start', () async {
      backend.addParent(pin: '2468');
      final session = await launch();
      await session.signInParent(email: 'eltern@test.invalid', password: 'sehrgeheim123');
      await session.deleteAccount();
      expect(session.state, isA<SessionSignedOut>());
      expect(backend.parentsByUser, isEmpty);
    });

    test('Server nicht erreichbar: Fehlerbild mit Grund', () async {
      backend.addParent(pin: '2468');
      backend.signInAs('eltern@test.invalid');
      backend.failWith = FailureKind.network;
      final session = await launch();
      final state = session.state as SessionProblem;
      expect(state.kind, SessionProblemKind.loadFailed);
      expect(state.failure, FailureKind.network);

      backend.failWith = null;
      await session.retry();
      expect(session.state, isA<SessionParent>());
    });
  });

  group('Kind spielt auf dem Eltern-Gerät', () {
    test('Übergeben, Neustart, Leuchtturm nur mit PIN', () async {
      final parent = backend.addParent(pin: '2468');
      final mila = backend.addChild(parent);
      final session = await launch();
      await session.signInParent(email: 'eltern@test.invalid', password: 'sehrgeheim123');

      await session.handOverToChild(mila);
      final child = session.state as SessionChild;
      expect(child.child.nickname, 'Mila');
      expect(child.onParentDevice, isTrue);

      // Nach einem Neustart spielt Mila weiter, ohne PIN.
      final restarted = await launch();
      expect((restarted.state as SessionChild).child.id, mila.id);

      // Tipp auf den Leuchtturm: PIN-Abfrage, zurück geht ohne PIN.
      restarted.requestParentArea();
      final gate = restarted.state as SessionParent;
      expect(gate.unlocked, isFalse);
      expect(gate.returnChild?.id, mila.id);
      restarted.returnToChild();
      expect(restarted.state, isA<SessionChild>());

      // Mit PIN in den Leuchtturm. Danach startet die App wieder im Leuchtturm.
      restarted.requestParentArea();
      await restarted.unlockWithPin('2468');
      expect((restarted.state as SessionParent).unlocked, isTrue);
      final third = await launch();
      expect((third.state as SessionParent).unlocked, isFalse);
    });

    test('Gelöschtes Kind auf dem Eltern-Gerät: zurück zum Leuchtturm', () async {
      final parent = backend.addParent(pin: '2468');
      final mila = backend.addChild(parent);
      backend.signInAs('eltern@test.invalid');
      await settings.setActiveChildId(parent.userId, mila.id);
      backend.children.clear();
      final session = await launch();
      expect(session.state, isA<SessionParent>());
      expect(settings.values, isEmpty);
    });
  });

  group('Kinder-Gerät', () {
    test('Code einlösen: Kinderbereich nur für dieses Kind', () async {
      final parent = backend.addParent(pin: '2468');
      final mila = backend.addChild(parent);
      backend.addChild(parent, nickname: 'Ben');
      backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);

      final session = await launch();
      expect(await session.redeemChildCode('XXXX2345'), isFalse);
      expect(await session.redeemChildCode('abcd-2345'), isTrue);
      final state = session.state as SessionChild;
      expect(state.child.nickname, 'Mila');
      expect(state.onParentDevice, isFalse);

      // Nach Neustart weiter Mila.
      expect(((await launch()).state as SessionChild).child.id, mila.id);
    });

    test('Eltern melden das Gerät ab: zurück zum Start', () async {
      final parent = backend.addParent(pin: '2468');
      final mila = backend.addChild(parent);
      backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
      final session = await launch();
      await session.redeemChildCode('ABCD2345');
      final deviceId = backend.currentUser!.id;

      backend.signOutDevice(deviceId);
      await pumpEventQueue();
      expect(session.state, isA<SessionSignedOut>());
    });

    test('Kinder-Gerät ohne Profil: Code eingeben', () async {
      final session = await launch();
      await FakeAuthRepository(backend).signInChildDevice();
      await session.retry();
      expect(session.state, isA<SessionChildUnlinked>());
    });

    test('Auf dem Kinder-Gerät öffnet der Leuchtturm-Knopf nichts', () async {
      final parent = backend.addParent(pin: '2468');
      final mila = backend.addChild(parent);
      backend.codes['ABCD2345'] = (childId: mila.id, validUntil: DateTime(2026), used: false);
      final session = await launch();
      await session.redeemChildCode('ABCD2345');
      session.requestParentArea();
      expect(session.state, isA<SessionChild>());
    });
  });
}
