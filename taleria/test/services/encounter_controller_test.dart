import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/services/encounter_controller.dart';

import '../fake_content.dart';

void main() {
  late FakeContent content;
  late FakeProgress progress;

  setUp(() {
    content = FakeContent();
    progress = FakeProgress(content)..makeDue('hafen', 2);
  });

  Future<EncounterController> started() async {
    final offer = await progress.nextEncounter('kind');
    final c = EncounterController(
      content: content,
      progress: progress,
      childId: 'kind',
      offer: offer!,
      random: Random(3),
    );
    await c.start();
    return c;
  }

  test('Ohne fällige Wiederholungen keine Begegnung', () async {
    expect(await FakeProgress(content).nextEncounter('kind'), isNull);
  });

  test('Erste Begegnung beginnt mit der Vorstellung von Meister Taleron', () async {
    final c = await started();
    expect(c.encounter.title, 'Meister Taleron');
    expect(c.step, EncounterStep.intro);
    expect(c.offer.openingScene.length, greaterThan(1));
    c.introDone();
    expect(c.step, EncounterStep.question);
    expect(c.run!.total, 3);
  });

  test('Falsch: erklären, nochmal versuchen; gezählt wird die erste Antwort', () async {
    final c = await started();
    c.introDone();
    final run = c.run!;

    // Rätsel 1: erst falsch, dann richtig.
    final wrong = (run.current.correctDisplayIndex + 1) % 3;
    c.answer(wrong);
    expect(run.answeredCorrectly, isFalse);
    await c.next();
    expect(run.index, 0, reason: 'Weiter erst, wenn die Antwort stimmt');
    c.retry();
    expect(run.chosen, isNull);
    expect(run.attempt, 2);
    c.answer(run.current.correctDisplayIndex);
    await c.next();
    expect(run.index, 1);

    // Rätsel 2 und 3: sofort richtig.
    for (var i = 0; i < 2; i++) {
      c.answer(run.current.correctDisplayIndex);
      await c.next();
    }
    expect(c.step, EncounterStep.result);
    expect(c.result!.correct, 2, reason: 'nur die erste Antwort zählt für den Plan');
    expect(c.result!.total, 3);
    expect(c.result!.xpAwarded, 20);
    expect(progress.due, isEmpty);
  });

  test('Seemeilen für Begegnungen nur einmal am Tag', () async {
    progress.reviewXpToday = true;
    final c = await started();
    c.introDone();
    for (var i = 0; i < 3; i++) {
      c.answer(c.run!.current.correctDisplayIndex);
      await c.next();
    }
    expect(c.result!.xpAwarded, 0);
  });
}
