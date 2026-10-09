import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/avatar.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/services/intro_controller.dart';

import '../fakes.dart';

void main() {
  late FakeBackend backend;
  late ChildProfile mila;
  late IntroController intro;

  setUp(() {
    backend = FakeBackend();
    final parent = backend.addParent(pin: '2468');
    mila = backend.addChild(parent, onboardingCompleted: false);
    backend.signInAs('eltern@test.invalid');
    intro = IntroController(repository: FakeChildRepository(backend), child: mila);
  });

  Future<void> goToWish() async {
    intro.filmFinished();
    intro.joinCrew();
    intro.updateAvatar(const AvatarConfig(hat: Hat.bandana));
    await intro.saveAvatar();
    await intro.christenShip(' Seestern ');
    intro.tourFinished();
  }

  test('Abschnitte kommen in fester Reihenfolge', () async {
    expect(intro.step, IntroStep.film);
    intro.joinCrew(); // geht noch nicht, erst der Film
    expect(intro.step, IntroStep.film);
    await goToWish();
    expect(intro.step, IntroStep.wish);
    expect(backend.childById(mila.id).avatar?.hat, Hat.bandana);
    expect(backend.childById(mila.id).shipName, 'Seestern');
  });

  test('Ungültiger Schiffsname wird nicht gesendet', () async {
    intro.filmFinished();
    intro.joinCrew();
    await intro.saveAvatar();
    expect(() => intro.christenShip('!'), throwsArgumentError);
    expect(intro.step, IntroStep.ship);
  });

  test('Wunschschatz: ganze Euro werden zu Cent', () async {
    await goToWish();
    await intro.saveWish(title: 'Fußball', euros: 25);
    expect(backend.savingsGoals.single.targetCents, 2500);
    expect(intro.step, IntroStep.done);
    expect(intro.earnedXp, 50);
    expect(intro.wishCreated, isTrue);
  });

  test('Wunschschatz außerhalb von 1 bis 10000 Euro wird abgelehnt', () async {
    await goToWish();
    expect(() => intro.saveWish(title: 'Pferd', euros: 20000), throwsArgumentError);
    expect(() => intro.saveWish(title: 'Pferd', euros: 0), throwsArgumentError);
    expect(intro.step, IntroStep.wish);
  });

  test('Seemeilen gibt es nur einmal', () async {
    await goToWish();
    await intro.skipWish();
    expect(intro.earnedXp, 50);

    final again = IntroController(repository: FakeChildRepository(backend), child: mila);
    again.filmFinished();
    again.joinCrew();
    await again.saveAvatar();
    await again.christenShip('Seestern');
    again.tourFinished();
    await again.skipWish();
    expect(again.earnedXp, 0);
  });

  test('Fehler beim Speichern: Abschnitt bleibt offen, nichts geht verloren', () async {
    intro.filmFinished();
    intro.joinCrew();
    backend.failWith = FailureKind.network;
    await expectLater(intro.saveAvatar(), throwsA(isA<AppFailure>()));
    expect(intro.step, IntroStep.avatar);
    expect(intro.busy, isFalse);

    backend.failWith = null;
    await intro.saveAvatar();
    expect(intro.step, IntroStep.ship);
  });

  test('Fremdes Kind: Server lehnt ab', () async {
    backend.addParent(email: 'fremd@test.invalid');
    backend.signInAs('fremd@test.invalid');
    intro.filmFinished();
    intro.joinCrew();
    await expectLater(intro.saveAvatar(), throwsA(isA<AppFailure>()));
  });
}
