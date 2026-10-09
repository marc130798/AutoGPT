import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/avatar.dart';

void main() {
  test('Avatar wird gespeichert und wieder gelesen', () {
    const avatar = AvatarConfig(
      skin: SkinTone.s5,
      hairStyle: HairStyle.braid,
      hairColor: HairColor.red,
      outfit: OutfitColor.green,
      hat: Hat.straw,
    );
    expect(AvatarConfig.fromJson(avatar.toJson()), avatar);
  });

  test('Kaputte oder alte Werte werden zum Standard, ohne Absturz', () {
    final avatar = AvatarConfig.fromJson({'skin': 'lila', 'hat': 42, 'hair': 'curly'});
    expect(avatar.skin, const AvatarConfig().skin);
    expect(avatar.hat, const AvatarConfig().hat);
    expect(avatar.hairStyle, HairStyle.curly);
    expect(AvatarConfig.fromJson(null), const AvatarConfig());
  });

  test('Gespeichertes Format ist klein (Datenbank erlaubt höchstens 1 KB)', () {
    expect(const AvatarConfig().toJson().toString().length, lessThan(200));
  });
}
