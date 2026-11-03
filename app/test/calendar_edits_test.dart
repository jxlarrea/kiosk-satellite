import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_edits.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_manager.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_model.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_requests.dart';

/// A calendar in memory, each calendar's events as Home Assistant's REST
/// read returns them, and every write in order.
class _Store implements CalendarStore {
  @override
  final enabled = const [
    CalendarSource(entity: 'calendar.leo', name: 'Leo', color: '1,2,3'),
    CalendarSource(entity: 'calendar.sam', name: 'Sam', color: '1,2,3'),
    CalendarSource(entity: 'calendar.maya', name: 'Maya', color: '1,2,3'),
  ];

  final events = <String, List<CalendarEvent>>{};
  final writes = <String>[];
  final drafts = <CalendarDraft>[];

  /// What each write throws, by calendar.
  final refuse = <String, Object>{};

  @override
  Future<Map<String, List<CalendarEvent>>> readEvents(
    DateTime from,
    DateTime to,
  ) async => {
    for (final c in enabled)
      c.entity: [
        for (final e in events[c.entity] ?? const <CalendarEvent>[])
          if (e.start.isBefore(to) && e.end.isAfter(from)) e,
      ],
  };

  void _check(String entity) {
    if (refuse[entity] case final error?) throw error;
  }

  @override
  Future<void> createEvent(String entity, CalendarDraft draft) async {
    _check(entity);
    writes.add('create $entity');
    drafts.add(draft);
  }

  @override
  Future<void> updateEvent(
    String entity,
    CalendarEvent event,
    CalendarDraft draft, {
    String scope = 'this',
  }) async {
    _check(entity);
    writes.add('update $entity ${event.uid} $scope');
    drafts.add(draft);
  }

  @override
  Future<void> deleteEvent(
    String entity,
    CalendarEvent event,
    String scope,
  ) async {
    _check(entity);
    writes.add('delete $entity ${event.uid} $scope');
  }

  @override
  Future<void> show({
    required String view,
    required DateTime date,
    CalendarHighlight? highlight,
  }) async {}
}

final _start = DateTime(2026, 10, 19, 16);
final _end = DateTime(2026, 10, 19, 17, 30);

CalendarEvent _copy(
  String calendar,
  String? uid, {
  String? recurrenceId,
  String? rrule,
}) => CalendarEvent(
  summary: 'Soccer practice',
  start: _start,
  end: _end,
  allDay: false,
  calendars: [calendar],
  uid: uid,
  recurrenceId: recurrenceId,
  rrule: rrule,
);

/// The event as the screen draws it: one event on both calendars, from a
/// poll that left out the ids.
final _shared = CalendarEvent(
  summary: 'Soccer practice',
  start: _start,
  end: _end,
  allDay: false,
  calendars: const ['calendar.leo', 'calendar.sam'],
);

CalendarDraft _draft({String? rrule}) => CalendarDraft(
  summary: 'Soccer practice',
  start: _start,
  end: _end.add(const Duration(minutes: 30)),
  allDay: false,
  rrule: rrule,
);

void main() {
  late _Store store;
  late CalendarEdits edits;

  setUp(() {
    store = _Store();
    edits = CalendarEdits(store);
  });

  test('a new event goes on every calendar picked', () async {
    await edits.add(['calendar.leo', 'calendar.sam'], _draft());
    expect(store.writes, ['create calendar.leo', 'create calendar.sam']);
  });

  test('a change goes to each copy, read fresh for its uid', () async {
    store.events['calendar.leo'] = [_copy('calendar.leo', 'a')];
    store.events['calendar.sam'] = [_copy('calendar.sam', 'b')];
    await edits.change(
      _shared,
      _draft(),
      calendars: ['calendar.leo', 'calendar.sam'],
    );
    expect(store.writes, [
      'update calendar.leo a this',
      'update calendar.sam b this',
    ]);
  });

  test('a calendar added gets a copy and one taken out loses its', () async {
    store.events['calendar.leo'] = [_copy('calendar.leo', 'a')];
    store.events['calendar.sam'] = [_copy('calendar.sam', 'b')];
    await edits.change(
      _shared,
      _draft(),
      calendars: ['calendar.leo', 'calendar.maya'],
    );
    expect(store.writes, [
      'update calendar.leo a this',
      'create calendar.maya',
      'delete calendar.sam b this',
    ]);
  });

  test('one day of a series changes without the series rule', () async {
    const rule = 'FREQ=WEEKLY;BYDAY=MO,TH';
    final one = _copy('calendar.leo', 'a', recurrenceId: '20261019T160000');
    store.events['calendar.leo'] = [one];
    final shown = CalendarEvent(
      summary: one.summary,
      start: one.start,
      end: one.end,
      allDay: false,
      calendars: const ['calendar.leo'],
      uid: 'a',
      recurrenceId: one.recurrenceId,
      rrule: rule,
    );
    await edits.change(shown, _draft(rrule: rule), calendars: ['calendar.leo']);
    expect(store.writes, ['update calendar.leo a this']);
    expect(store.drafts.single.rrule, isNull);
    expect(store.drafts.single.toHa().containsKey('rrule'), isFalse);

    store.writes.clear();
    store.drafts.clear();
    await edits.change(
      shown,
      _draft(rrule: rule),
      calendars: ['calendar.leo'],
      scope: 'following',
    );
    expect(store.writes, ['update calendar.leo a following']);
    expect(store.drafts.single.toHa()['rrule'], rule);
  });

  test('a delete takes every copy with its scope', () async {
    store.events['calendar.leo'] = [_copy('calendar.leo', 'a')];
    store.events['calendar.sam'] = [_copy('calendar.sam', 'b')];
    await edits.remove(_shared, 'following');
    expect(store.writes, [
      'delete calendar.leo a following',
      'delete calendar.sam b following',
    ]);
  });

  test('a copy without a uid is a calendar that takes no changes', () async {
    store.events['calendar.leo'] = [_copy('calendar.leo', null)];
    store.events['calendar.sam'] = [_copy('calendar.sam', 'b')];
    await expectLater(
      edits.remove(_shared, 'this'),
      throwsA(
        isA<CalendarEditError>()
            .having((e) => e.calendar, 'calendar', 'calendar.leo')
            .having((e) => e.failure, 'failure', CalendarEditFailure.readOnly),
      ),
    );
    expect(store.writes, isEmpty);
  });

  test('an event changed elsewhere meanwhile is gone', () async {
    store.events['calendar.leo'] = [_copy('calendar.leo', 'a')];
    await expectLater(
      edits.remove(_shared, 'this'),
      throwsA(
        isA<CalendarEditError>()
            .having((e) => e.calendar, 'calendar', 'calendar.sam')
            .having((e) => e.failure, 'failure', CalendarEditFailure.gone),
      ),
    );
  });

  test('Home Assistant refusals say why', () async {
    store.refuse['calendar.leo'] = StateError('Not supported (not_supported)');
    store.refuse['calendar.sam'] = StateError('Unauthorized');
    store.refuse['calendar.maya'] = StateError('Timed out');
    Future<CalendarEditFailure> failure(String calendar) async {
      try {
        await edits.add([calendar], _draft());
      } on CalendarEditError catch (e) {
        return e.failure;
      }
      fail('no error');
    }

    expect(await failure('calendar.leo'), CalendarEditFailure.readOnly);
    expect(await failure('calendar.sam'), CalendarEditFailure.notAllowed);
    expect(await failure('calendar.maya'), CalendarEditFailure.refused);
  });

  group('repeat', () {
    final monday = DateTime(2026, 10, 19, 16);

    test('presets read back from the rules they write', () {
      for (final preset in [
        'none',
        'daily',
        'weekdays',
        'weekly',
        'monthly',
        'yearly',
      ]) {
        expect(
          calendarRepeatPreset(calendarRepeatRule(preset, null), monday),
          preset,
          reason: preset,
        );
      }
    });

    test('rules from other calendar apps match their preset', () {
      expect(
        calendarRepeatPreset('RRULE:FREQ=WEEKLY;BYDAY=MO', monday),
        'weekly',
      );
      expect(
        calendarRepeatPreset(
          'FREQ=WEEKLY;WKST=SU;BYDAY=FR,TH,WE,TU,MO',
          monday,
        ),
        'weekdays',
      );
      expect(
        calendarRepeatPreset('FREQ=MONTHLY;BYMONTHDAY=19', monday),
        'monthly',
      );
      expect(calendarRepeatPreset('FREQ=DAILY;INTERVAL=1', monday), 'daily');
    });

    test('rules the presets cannot say stay custom and keep the rule', () {
      for (final rule in [
        'FREQ=WEEKLY;BYDAY=MO,TH',
        'FREQ=WEEKLY;INTERVAL=2',
        'FREQ=WEEKLY;BYDAY=TU',
        'FREQ=MONTHLY;BYDAY=3MO',
        'FREQ=DAILY;COUNT=5',
      ]) {
        expect(calendarRepeatPreset(rule, monday), 'custom', reason: rule);
      }
      expect(
        calendarRepeatRule('custom', 'FREQ=WEEKLY;BYDAY=MO,TH'),
        'FREQ=WEEKLY;BYDAY=MO,TH',
      );
      expect(calendarRepeatRule('none', 'FREQ=DAILY'), isNull);
    });
  });
}
