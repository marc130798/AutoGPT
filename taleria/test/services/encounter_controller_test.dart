import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/progress_models.dart';
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

  group('Meister Talerons Prüfung', () {
    EncounterOffer trialOffer() {
      final base = content.encounters.first;
      final ids = [for (final q in content.allQuestions.take(4)) q.id];
      return EncounterOffer(
        encounter: Encounter(
          id: 'trial-a',
          slug: 'taleron-siegel-a',
          type: 'taleron_trial',
          title: 'Meister Talerons Prüfung',
          assetKey: base.assetKey,
          questionCount: ids.length,
          xpReward: 150,
          scene: base.scene,
          success: base.success,
        ),
        questionIds: ids,
        firstMeeting: false,
        dueCount: 0,
        trial: const TrialInfo(
          pass: 3,
          badge: BadgeRef(slug: 'taleron-siegel-a', title: 'Taleron-Siegel A', assetKey: 'badge.taleron.a'),
        ),
      );
    }

    Future<EncounterController> trial({required int wrongFirst}) async {
      final offer = trialOffer();
      progress.trialOffer = offer;
      final c = EncounterController(
        content: content,
        progress: progress,
        childId: 'kind',
        offer: offer,
        random: Random(5),
      );
      await c.start();
      c.introDone();
      final run = c.run!;
      for (var i = 0; i < run.total; i++) {
        if (i < wrongFirst) {
          c.answer((run.current.correctDisplayIndex + 1) % 3);
          c.retry();
        }
        c.answer(run.current.correctDisplayIndex);
        await c.next();
      }
      return c;
    }

    test('genug richtig: Siegel und Seemeilen, die Prüfung verschwindet', () async {
      final c = await trial(wrongFirst: 1);
      expect(c.step, EncounterStep.result);
      expect(c.result!.passed, isTrue);
      expect(c.result!.badge!.slug, 'taleron-siegel-a');
      expect(c.result!.xpAwarded, 150);
      expect(progress.trialRuns, 1);
      expect(await progress.taleronTrial('kind'), isNull);
    });

    test('zu wenig richtig: kein Siegel, Taleron wartet weiter', () async {
      final c = await trial(wrongFirst: 2);
      expect(c.result!.passed, isFalse);
      expect(c.result!.badge, isNull);
      expect(c.result!.xpAwarded, 0);
      expect(await progress.taleronTrial('kind'), isNotNull);
    });
  });
}
