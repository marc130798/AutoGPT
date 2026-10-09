import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/family_models.dart';
import 'package:taleria/services/lighthouse_controller.dart';

import '../fakes.dart';

void main() {
  late FakeBackend backend;
  late ParentAccount parent;
  late LighthouseController controller;

  setUp(() async {
    backend = FakeBackend();
    parent = backend.addParent(pin: '2468');
    backend.signInAs('eltern@test.invalid');
    controller = LighthouseController(family: FakeFamilyRepository(backend), parent: parent);
    await controller.load();
  });

  test('Kinder-Profil anlegen, ändern, löschen', () async {
    expect(controller.children, isEmpty);

    final mila = await controller.createChild(nickname: '  Mila ', birthYear: 2015, level: LevelSetting.beginner);
    expect(mila.nickname, 'Mila');
    expect(controller.children, hasLength(1));

    await controller.updateChild(
      ChildProfile(id: mila.id, nickname: 'Mila M', birthYear: 2014, level: LevelSetting.advanced),
    );
    expect(controller.childById(mila.id)?.nickname, 'Mila M');
    expect(controller.childById(mila.id)?.level, LevelSetting.advanced);

    await controller.deleteChild(mila.id);
    expect(controller.children, isEmpty);
  });

  test('Ungültiger Spitzname wird nicht gesendet', () {
    expect(
      () => controller.createChild(nickname: 'X', birthYear: 2015, level: LevelSetting.beginner),
      throwsArgumentError,
    );
  });

  test('Profil löschen meldet seine Geräte ab', () async {
    final mila = await controller.createChild(nickname: 'Mila', birthYear: 2015, level: LevelSetting.beginner);
    backend.devices['device-x'] = mila.id;
    expect(await controller.countDevices(mila.id), 1);
    await controller.deleteChild(mila.id);
    expect(backend.devices, isEmpty);
  });

  test('Ladefehler wird gemerkt, nicht geworfen', () async {
    backend.failWith = FailureKind.network;
    await controller.load();
    expect(controller.loadFailure, FailureKind.network);
    expect(controller.loading, isFalse);
  });
}
