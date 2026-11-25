import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_face_focus.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_model.dart';

/// Settings > Calendar > Focus on who is at the kiosk: which calendars
/// the people Face Recognition names at the kiosk put forward, and for how
/// long.
void main() {
  const calendars = [
    CalendarSource(entity: 'calendar.family', name: 'Family', color: '1,1,1'),
    CalendarSource(
      entity: 'calendar.maya',
      name: 'School',
      color: '1,1,1',
      person: 'person.maya',
    ),
    CalendarSource(entity: 'calendar.leo', name: 'Leo', color: '1,1,1'),
    CalendarSource(entity: 'calendar.sam', name: 'Sam', color: '1,1,1'),
  ];
  const things = {
    'm1': {'person': 'person.maya'},
    's1': {'calendar': 'calendar.sam'},
  };

  const names = {'m1': 'Maya', 'l1': 'Leo', 's1': 'Sam'};

  late bool on;
  late CalendarFaceFocus focus;

  setUp(() {
    on = true;
    focus = CalendarFaceFocus(
      calendars: () => calendars,
      thingsOf: (id) => things[id] ?? const {},
      on: () => on,
    );
  });

  tearDown(() => focus.dispose());

  FaceInViewChanged inView(
    String? id,
    String name, [
    List<String> also = const [],
  ]) => FaceInViewChanged(
    id: id,
    name: name,
    people: [
      if (id != null) (id: id, name: name),
      for (final o in also) (id: o, name: names[o]!),
    ],
  );

  test('finds each calendar as voice finds "my calendar"', () {
    // Maya by her Home Assistant person, Leo by name, Sam by the calendar
    // Ground Control keeps for him.
    focus.inView(inView('m1', 'Maya', ['l1', 's1']));
    expect(focus.value.value.entities, [
      'calendar.maya',
      'calendar.leo',
      'calendar.sam',
    ]);
    expect(focus.value.value.lead, 'calendar.maya');
    expect(focus.value.value.leadName, 'Maya');
  });

  test('someone counts until they have been away for a minute', () {
    fakeAsync((async) {
      focus.inView(inView('m1', 'Maya'));
      focus.inView(const FaceInViewChanged());
      async.elapse(const Duration(seconds: 59));
      expect(focus.value.value.lead, 'calendar.maya');
      // Back before the minute is up: the clock starts over.
      focus.inView(inView('m1', 'Maya'));
      focus.inView(const FaceInViewChanged());
      async.elapse(const Duration(seconds: 59));
      expect(focus.value.value.isEmpty, isFalse);
      async.elapse(const Duration(seconds: 2));
      expect(focus.value.value, CalendarFocus.none);
    });
  });

  test('the person at the kiosk stays the lead until someone else is', () {
    focus.inView(inView('m1', 'Maya', ['l1']));
    // Maya looks away. Leo is still in view but not at the kiosk.
    focus.inView(inView(null, '', ['l1']));
    expect(focus.value.value.lead, 'calendar.maya');
    focus.inView(inView('l1', 'Leo', ['m1']));
    expect(focus.value.value.lead, 'calendar.leo');
    expect(focus.value.value.entities, ['calendar.leo', 'calendar.maya']);
  });

  test('nothing is put forward while the setting is off', () {
    on = false;
    focus.inView(inView('m1', 'Maya'));
    expect(focus.value.value, CalendarFocus.none);
    on = true;
    focus.refresh();
    expect(focus.value.value.lead, 'calendar.maya');
  });

  test('a person without a calendar is not the lead of anything', () {
    focus.inView(inView('x1', 'Guest', ['l1']));
    expect(focus.value.value.lead, isNull);
    expect(focus.value.value.leadName, '');
    expect(focus.value.value.entities, ['calendar.leo']);
  });
}
