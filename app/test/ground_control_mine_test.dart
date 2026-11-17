import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/ground_control/mine.dart';

/// What "my" means: the person Voice Match placed and what Ground Control
/// keeps for them, in the four answers the personal commands act on.
void main() {
  const people = <Map<String, Object?>>[
    {
      'id': 'ana',
      'name': 'Ana',
      'things': {'todo_list': 'todo.ana', 'playlist': 'Ana mix'},
    },
    {'id': 'leo', 'name': 'Leo', 'things': <String, String>{}},
  ];
  Speaking? who(String id) => switch (id) {
    'ana' || 'leo' => Speaking(
      id: id,
      name: id == 'ana' ? 'Ana' : 'Leo',
      by: 'voice',
      things: thingsOf(id, people),
    ),
    _ => null,
  };

  test('own: the speaker has one', () {
    expect(resolveMine('todo_list', who('ana'), people), {
      'ok': true,
      'thing': 'todo_list',
      'status': 'own',
      'speaking': 'Ana',
      'by': 'voice',
      'entity': 'todo.ana',
    });
    expect(resolveMine('playlist', who('ana'), people)['query'], 'Ana mix');
  });

  test('not_theirs: the speaker is known but has none', () {
    final r = resolveMine('todo_list', who('leo'), people);
    expect(r['status'], 'not_theirs');
    expect(r.containsKey('entity'), isFalse);
  });

  test('no_speaker: someone has one, nobody was placed', () {
    expect(resolveMine('todo_list', null, people)['status'], 'no_speaker');
  });

  test('none: nobody in the home has one', () {
    expect(resolveMine('calendar', who('ana'), people)['status'], 'none');
    expect(resolveMine('calendar', null, people)['status'], 'none');
    expect(resolveMine('todo_list', null, const [])['status'], 'none');
  });

  test('an unknown thing is refused', () {
    expect(resolveMine('car', who('ana'), people)['ok'], isFalse);
  });

  test('a voice request carries the speaker and reads it back', () {
    final back = Speaking.from(who('ana')!.toJson())!;
    expect(back.name, 'Ana');
    expect(back.things['todo_list'], 'todo.ana');
    expect(Speaking.from(null), isNull);
    expect(Speaking.from({'name': ''}), isNull);
  });

  test('words for the person speaking', () {
    for (final w in ['me', 'Me', 'my', 'mine', 'my playlist', 'myself']) {
      expect(meansSpeaker(w), isTrue, reason: w);
    }
    for (final w in ['Ana', 'everyone', 'family', '']) {
      expect(meansSpeaker(w), isFalse, reason: w);
    }
  });
}
