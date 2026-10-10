import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/learning_status.dart';

void main() {
  test('Noch keine Antworten: noch nicht dran', () {
    expect(topicStatus(answered: 0, secure: 0, shaky: 0), TopicStatus.notStarted);
  });

  test('Ein Drittel zuletzt falsch: wackelt noch', () {
    expect(topicStatus(answered: 3, secure: 2, shaky: 1), TopicStatus.shaky);
    expect(topicStatus(answered: 4, secure: 3, shaky: 1), isNot(TopicStatus.shaky));
  });

  test('Zwei Drittel auch nach Tagen gewusst: sicher', () {
    expect(topicStatus(answered: 3, secure: 2, shaky: 0), TopicStatus.secure);
    expect(topicStatus(answered: 4, secure: 3, shaky: 1), TopicStatus.secure);
  });

  test('Sonst: wird geübt', () {
    expect(topicStatus(answered: 4, secure: 1, shaky: 0), TopicStatus.learning);
    expect(topicStatus(answered: 2, secure: 0, shaky: 0), TopicStatus.learning);
  });

  test('Zahlen aus der Datenbank', () {
    final topic = TopicLearning.fromJson({
      'island_id': 'i',
      'station_id': 's',
      'answered': 3,
      'secure': 0,
      'learning': 1,
      'shaky': 2,
    });
    expect(topic.status, TopicStatus.shaky);
  });
}
