import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/assets/asset_keys.dart';
import 'package:taleria/domain/content_models.dart';
import 'package:taleria/features/station/station_stage.dart';

void main() {
  const lines = [
    DialogLine(speaker: 'talo', text: 'Ahoi!'),
    DialogLine(speaker: 'olga', text: 'Willkommen.'),
    DialogLine(speaker: 'tala', text: 'Danke!'),
    DialogLine(speaker: 'bruno', text: 'Äpfel!'),
    DialogLine(speaker: 'olga', text: 'Tauscht doch.'),
  ];

  List<String> keys(FigureStage stage) => [for (final f in stage.figures) f.character];

  test('Erste Zeile: nur wer spricht steht da und winkt', () {
    final stage = dialogStage(lines, 1);
    expect(keys(stage), ['character.talo']);
    expect(stage.figures.single.pose, CharacterPose.wave);
    expect(stage.figures.single.active, isTrue);
  });

  test('Wer gesprochen hat, bleibt stehen; vorn ist, wer gerade spricht', () {
    final stage = dialogStage(lines, 3);
    expect(keys(stage), ['character.talo', 'character.olga', 'character.tala']);
    expect([for (final f in stage.figures) f.active], [false, false, true]);
    expect(stage.figures.every((f) => f.pose == null), isTrue, reason: 'Gewunken wird nur zur Begrüßung');
  });

  test('Höchstens drei Figuren: die, die zuletzt sprachen', () {
    final stage = dialogStage(lines, 5);
    expect(keys(stage), ['character.olga', 'character.tala', 'character.bruno']);
    expect(stage.figures.firstWhere((f) => f.active).character, 'character.olga');
  });

  test('Frage: Talo denkt nach, nach richtiger Antwort freuen sich beide', () {
    final open = quizStage(answered: false, correct: false);
    expect(keys(open), [AssetKeys.talo, AssetKeys.tala]);
    expect(open.figures.first.pose, CharacterPose.think);
    expect(open.figures.last.active, isFalse);

    final right = quizStage(answered: true, correct: true);
    expect(right.figures.every((f) => f.pose == CharacterPose.happy && f.active), isTrue);

    final wrong = quizStage(answered: true, correct: false);
    expect(wrong.figures.first.pose, CharacterPose.think);
  });
}
