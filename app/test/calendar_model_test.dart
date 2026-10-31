import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_manager.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_model.dart';

CalendarEvent _event(
  String calendar,
  String summary,
  DateTime start,
  DateTime end, {
  bool allDay = false,
  String? uid,
}) => CalendarEvent(
  summary: summary,
  start: start,
  end: end,
  allDay: allDay,
  calendars: [calendar],
  uid: uid,
);

void main() {
  group('calendars', () {
    test('decode keeps calendar entities once, in order', () {
      final list = decodeCalendars(
        '[{"entity":"calendar.sam","name":"Sam","color":"192,97,58"},'
        '{"entity":"light.x","name":"No"},'
        '{"entity":"calendar.sam","name":"Again"},'
        '{"entity":"calendar.leo","name":"Leo","color":"bad","on":false}]',
      );
      expect(list.map((c) => c.entity), ['calendar.sam', 'calendar.leo']);
      expect(list.first.name, 'Sam');
      // A color that is not "r,g,b" falls back to the first palette color.
      expect(list.last.color, calendarPalette.first.rgb);
      expect(list.last.on, isFalse);
      expect(decodeCalendars('not json'), isEmpty);
    });

    test('round trips through JSON', () {
      const source = CalendarSource(
        entity: 'calendar.maya',
        name: 'Maya',
        color: '138,90,156',
        person: 'person.maya',
      );
      expect(decodeCalendars(encodeCalendars([source])), [source]);
      expect(source.initial, 'M');
    });

    test('a new calendar takes the first unused palette color', () {
      final taken = [
        CalendarSource(
          entity: 'calendar.a',
          name: 'A',
          color: calendarPalette[0].rgb,
        ),
        CalendarSource(
          entity: 'calendar.b',
          name: 'B',
          color: calendarPalette[2].rgb,
        ),
      ];
      expect(nextCalendarColor(taken), calendarPalette[1].rgb);
    });
  });

  group('parseHaEvent', () {
    test('reads a timed event in device time', () {
      final e = parseHaEvent({
        'summary': 'Soccer practice',
        'start': '2026-10-19T16:00:00-05:00',
        'end': '2026-10-19T17:30:00-05:00',
        'location': 'Riverside Park',
        'uid': 'abc',
        'rrule': 'FREQ=WEEKLY;BYDAY=MO,TH',
      }, 'calendar.leo')!;
      expect(e.allDay, isFalse);
      expect(e.start, DateTime.parse('2026-10-19T21:00:00Z').toLocal());
      expect(e.end.difference(e.start), const Duration(minutes: 90));
      expect(e.location, 'Riverside Park');
      expect(e.calendars, ['calendar.leo']);
      expect(rruleFrequency(e.rrule), 'WEEKLY');
    });

    test('reads an all-day event as local dates with an exclusive end', () {
      final e = parseHaEvent({
        'summary': 'Denver trip',
        'start': '2026-10-22',
        'end': '2026-10-24',
      }, 'calendar.sam')!;
      expect(e.allDay, isTrue);
      expect(e.start, DateTime(2026, 10, 22));
      expect(e.end, DateTime(2026, 10, 24));
      expect(e.multiDay, isTrue);
      expect(e.occursOn(DateTime(2026, 10, 22)), isTrue);
      expect(e.occursOn(DateTime(2026, 10, 23)), isTrue);
      expect(e.occursOn(DateTime(2026, 10, 24)), isFalse);
    });

    test('reads the dateTime and date maps the REST API sends', () {
      final e = parseHaEvent({
        'summary': 'Holiday',
        'start': {'date': '2026-10-31'},
        'end': {'date': '2026-11-01'},
      }, 'calendar.h')!;
      expect(e.allDay, isTrue);
      expect(e.multiDay, isFalse);
    });

    test('refuses an event without a start', () {
      expect(parseHaEvent({'summary': 'x'}, 'calendar.a'), isNull);
    });
  });

  group('mergeEvents', () {
    final start = DateTime(2026, 10, 19, 16);
    final end = DateTime(2026, 10, 19, 17, 30);

    test('one event on two calendars comes out once with both, by uid', () {
      final merged = mergeEvents(
        {
          'calendar.sam': [
            _event('calendar.sam', 'Soccer', start, end, uid: 'u1'),
          ],
          'calendar.leo': [
            _event('calendar.leo', 'Soccer practice', start, end, uid: 'u1'),
          ],
        },
        ['calendar.leo', 'calendar.sam'],
      );
      expect(merged, hasLength(1));
      // In the order Settings lists the calendars.
      expect(merged.single.calendars, ['calendar.leo', 'calendar.sam']);
    });

    test('without a uid, the same title, start and end match', () {
      final merged = mergeEvents(
        {
          'calendar.a': [_event('calendar.a', 'Date night', start, end)],
          'calendar.b': [_event('calendar.b', 'date night', start, end)],
          'calendar.c': [
            _event(
              'calendar.c',
              'Date night',
              start,
              end.add(const Duration(minutes: 1)),
            ),
          ],
        },
        ['calendar.a', 'calendar.b', 'calendar.c'],
      );
      expect(merged, hasLength(2));
      expect(merged.where((e) => e.calendars.length == 2).single.calendars, [
        'calendar.a',
        'calendar.b',
      ]);
    });

    test('all-day events sort first, then by start', () {
      final merged = mergeEvents(
        {
          'calendar.a': [
            _event(
              'calendar.a',
              'Late',
              DateTime(2026, 10, 19, 18),
              DateTime(2026, 10, 19, 19),
            ),
            _event(
              'calendar.a',
              'Early',
              DateTime(2026, 10, 19, 8),
              DateTime(2026, 10, 19, 9),
            ),
            _event(
              'calendar.a',
              'Pickup',
              DateTime(2026, 10, 19),
              DateTime(2026, 10, 20),
              allDay: true,
            ),
          ],
        },
        ['calendar.a'],
      );
      expect(merged.map((e) => e.summary), ['Pickup', 'Early', 'Late']);
    });
  });

  test(
    'a hidden calendar leaves its band, and the event only with the last',
    () {
      final shared = CalendarEvent(
        summary: 'Soccer',
        start: DateTime(2026, 10, 19, 16),
        end: DateTime(2026, 10, 19, 17),
        allDay: false,
        calendars: const ['calendar.leo', 'calendar.sam'],
      );
      expect(visibleEvents([shared], {'calendar.sam'}).single.calendars, [
        'calendar.leo',
      ]);
      expect(
        visibleEvents([shared], {'calendar.sam', 'calendar.leo'}),
        isEmpty,
      );
      expect(visibleEvents([shared], const {}).single, same(shared));
    },
  );

  test('overlapping events share the width, the rest keep it whole', () {
    DateTime at(int h, [int m = 0]) => DateTime(2026, 10, 19, h, m);
    final choir = _event('calendar.m', 'Choir', at(15, 30), at(16, 30));
    final soccer = _event('calendar.l', 'Soccer', at(16), at(17, 30));
    final pickup = _event('calendar.a', 'Pickup', at(15), at(15, 30));
    final taco = _event('calendar.f', 'Taco night', at(18, 30), at(19, 30));
    final placed = {
      for (final p in layoutColumns([taco, soccer, choir, pickup]))
        p.event.summary: (p.column, p.columns),
    };
    expect(placed['Pickup'], (0, 1));
    expect(placed['Choir'], (0, 2));
    expect(placed['Soccer'], (1, 2));
    expect(placed['Taco night'], (0, 1));
  });

  group('dates', () {
    test('the week starts on the given day', () {
      // Monday, October 19 2026.
      final monday = DateTime(2026, 10, 19, 15);
      expect(weekStart(monday, 0), DateTime(2026, 10, 18));
      expect(weekStart(monday, 1), DateTime(2026, 10, 19));
      expect(weekStart(monday, 6), DateTime(2026, 10, 17));
    });

    test('the month grid covers whole weeks', () {
      final october = DateTime(2026, 10, 5);
      expect(monthGridStart(october, 0), DateTime(2026, 9, 27));
      expect(monthGridWeeks(october, 0), 5);
      expect(monthGridWeeks(DateTime(2026, 8), 0), 6);
      expect(monthGridWeeks(DateTime(2026, 2), 0), 4);
    });

    test('addDays steps by the calendar', () {
      expect(addDays(DateTime(2026, 10, 31), 1), DateTime(2026, 11, 1));
      expect(daysBetween(DateTime(2026, 3, 1), DateTime(2026, 4, 1)), 31);
    });
  });

  test('up next lists the timed events today that have not ended', () {
    DateTime at(int h) => DateTime(2026, 10, 19, h);
    final events = [
      _event('calendar.a', 'Over', at(8), at(9)),
      _event('calendar.a', 'Going', at(10), at(12)),
      _event('calendar.a', 'Later', at(15), at(16)),
      _event(
        'calendar.a',
        'All day',
        DateTime(2026, 10, 19),
        DateTime(2026, 10, 20),
        allDay: true,
      ),
      _event(
        'calendar.a',
        'Tomorrow',
        DateTime(2026, 10, 20, 9),
        DateTime(2026, 10, 20, 10),
      ),
    ];
    expect(upNext(events, at(11)).map((e) => e.summary), ['Going', 'Later']);
    expect(
      upNext(
        [...events]..sort(compareEvents),
        at(11),
        allDay: true,
      ).map((e) => e.summary),
      ['All day', 'Going', 'Later'],
    );
  });

  test('up next looks ahead over the days asked for', () {
    DateTime on(int day, int h) => DateTime(2026, 10, day, h);
    final events = [
      _event('calendar.a', 'Today', on(19, 15), on(19, 16)),
      // Started yesterday and runs into tomorrow: listed once, today.
      _event('calendar.a', 'Trip', on(18, 9), on(20, 18)),
      _event(
        'calendar.a',
        'Holiday',
        DateTime(2026, 10, 20),
        DateTime(2026, 10, 21),
        allDay: true,
      ),
      _event('calendar.a', 'Tomorrow', on(20, 9), on(20, 10)),
      _event('calendar.a', 'Saturday', on(24, 9), on(24, 10)),
      _event('calendar.a', 'Next week', on(26, 9), on(26, 10)),
    ]..sort(compareEvents);
    List<String> titles(int days) => upNext(
      events,
      on(19, 11),
      allDay: true,
      days: days,
    ).map((e) => e.summary).toList();
    expect(titles(1), ['Trip', 'Today']);
    expect(titles(2), ['Trip', 'Today', 'Holiday', 'Tomorrow']);
    expect(titles(7), ['Trip', 'Today', 'Holiday', 'Tomorrow', 'Saturday']);
  });

  test('the forecast is keyed by local date', () {
    final forecast = parseForecast([
      {
        'datetime': '2026-10-19T17:00:00+00:00',
        'condition': 'sunny',
        'temperature': 68.4,
        'templow': 54,
      },
      {'datetime': 'nope'},
    ]);
    final day = dateOnly(DateTime.parse('2026-10-19T17:00:00Z').toLocal());
    expect(forecast[day]!.condition, 'sunny');
    expect(forecast[day]!.high, 68.4);
    expect(forecast[day]!.low, 54);
    expect(forecast, hasLength(1));
  });
}
