import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_manager.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_model.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_requests.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A calendar in memory: what the requests read, write and show.
class _Store implements CalendarStore {
  _Store(this.enabled);

  @override
  final List<CalendarSource> enabled;

  final events = <String, List<CalendarEvent>>{};
  final created = <(String, CalendarDraft)>[];
  final updated = <(String, CalendarEvent, CalendarDraft)>[];
  final deleted = <(String, CalendarEvent, String)>[];
  final shown = <({String view, DateTime date, CalendarHighlight? h})>[];

  /// Calendars that refuse writes, as a read-only one does.
  final readOnly = <String>{};

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

  @override
  Future<void> createEvent(String entity, CalendarDraft draft) async {
    if (readOnly.contains(entity)) throw StateError('ERR_NOT_SUPPORTED');
    created.add((entity, draft));
  }

  @override
  Future<void> updateEvent(
    String entity,
    CalendarEvent event,
    CalendarDraft draft, {
    String scope = 'this',
  }) async => updated.add((entity, event, draft));

  @override
  Future<void> deleteEvent(
    String entity,
    CalendarEvent event,
    String scope,
  ) async => deleted.add((entity, event, scope));

  @override
  Future<void> show({
    required String view,
    required DateTime date,
    CalendarHighlight? highlight,
  }) async => shown.add((view: view, date: date, h: highlight));
}

CalendarEvent _event(
  String summary,
  DateTime start,
  DateTime end,
  String calendar, {
  String? uid,
  String? recurrenceId,
  String? rrule,
  bool allDay = false,
}) => CalendarEvent(
  summary: summary,
  start: start,
  end: end,
  allDay: allDay,
  calendars: [calendar],
  uid: uid,
  recurrenceId: recurrenceId,
  rrule: rrule,
);

/// The calendar asked for through the Kiosk Satellite calendar script.
/// 2026-10-19 is a Monday.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Store store;
  late CalendarRequests requests;
  final now = DateTime(2026, 10, 19, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({'ks.device.name': 'Kitchen'});
    final log = Logger();
    final settings = SettingsManager(EventBus(), CommandRegistry(log), log);
    await settings.init();
    store = _Store(const [
      CalendarSource(
        entity: 'calendar.family',
        name: 'Family',
        color: '72,130,132',
      ),
      CalendarSource(
        entity: 'calendar.sam',
        name: 'Sam',
        color: '192,97,58',
        person: 'person.sam',
      ),
      CalendarSource(
        entity: 'calendar.leo_school',
        name: 'Leo',
        color: '168,122,31',
        person: 'person.leo',
      ),
    ]);
    requests = CalendarRequests(settings, store, clock: () => now);
  });

  group('add', () {
    test('a timed event is an hour long on the family calendar', () async {
      final r = await requests.handle({
        'action': 'add',
        'title': 'Dentist',
        'start': '2026-10-22 16:00',
      });
      expect(r['ok'], isTrue);
      expect(r['result'], 'added');
      final (entity, draft) = store.created.single;
      expect(entity, 'calendar.family');
      expect(draft.start, DateTime(2026, 10, 22, 16));
      expect(draft.end, DateTime(2026, 10, 22, 17));
      expect(draft.toHa()['dtstart'], startsWith('2026-10-22T16:00:00'));
      expect(
        (r['event']! as Map)['when'],
        'Thursday 2026-10-22 16:00 to 17:00',
      );
    });

    test('people pick their calendars, by name, entity or person', () async {
      final r = await requests.handle({
        'action': 'add',
        'title': 'Dinner',
        'start': '2026-10-23 19:00',
        'end': '20:30',
        'people': ["Sam's", 'leo'],
      });
      expect(r['ok'], isTrue);
      expect(
        [for (final (e, _) in store.created) e],
        ['calendar.sam', 'calendar.leo_school'],
      );
      expect(store.created.first.$2.end, DateTime(2026, 10, 23, 20, 30));
      expect((r['event']! as Map)['for'], ['Sam', 'Leo']);
    });

    test('a person left in the title picks the calendar', () async {
      await requests.handle({
        'action': 'add',
        'title': "Maya's haircut",
        'start': '2026-10-22 17:00',
      });
      await requests.handle({
        'action': 'add',
        'title': 'Piano for leo',
        'start': '2026-10-23 17:00',
      });
      expect(
        [for (final (e, d) in store.created) (e, d.summary)],
        [
          ('calendar.family', "Maya's haircut"),
          ('calendar.leo_school', 'Piano'),
        ],
      );
    });

    test('everyone is every calendar', () async {
      await requests.handle({
        'action': 'add',
        'title': 'Trip',
        'start': '2026-10-24',
        'people': ['everyone'],
      });
      expect(store.created, hasLength(3));
    });

    test('an all-day event ends the day after its last day', () async {
      await requests.handle({
        'action': 'add',
        'title': 'Camp',
        'start': '2026-10-24',
        'end': '2026-10-26',
      });
      final draft = store.created.single.$2;
      expect(draft.allDay, isTrue);
      expect(draft.end, DateTime(2026, 10, 27));
      expect(draft.toHa()['dtend'], '2026-10-27');
    });

    test('an unknown person lists the calendars', () async {
      final r = await requests.handle({
        'action': 'add',
        'title': 'Piano',
        'start': '2026-10-22 15:00',
        'people': ['Maya'],
      });
      expect(r['ok'], isFalse);
      expect(r['calendars'], ['Family', 'Sam', 'Leo']);
      expect(store.created, isEmpty);
    });

    test('a retry does not add it twice', () async {
      store.events['calendar.family'] = [
        _event(
          'Dentist',
          DateTime(2026, 10, 22, 16),
          DateTime(2026, 10, 22, 17),
          'calendar.family',
        ),
      ];
      final r = await requests.handle({
        'action': 'add',
        'title': 'dentist',
        'start': '2026-10-22 16:00',
      });
      expect(r['result'], 'already_there');
      expect(store.created, isEmpty);
    });

    test('a day before today is sent back to check', () async {
      final r = await requests.handle({
        'action': 'add',
        'title': 'Dentist',
        'start': '2025-07-25 16:00',
      });
      expect(r['ok'], isFalse);
      expect(r['error'], contains('Today is Monday 2026-10-19'));
      expect(store.created, isEmpty);
    });

    test('times sent in the change fields still add', () async {
      final r = await requests.handle({
        'action': 'add',
        'title': 'Dentist',
        'new_start': '2026-10-22 14:30',
      });
      expect(r['result'], 'added');
      expect(store.created.single.$2.start, DateTime(2026, 10, 22, 14, 30));
    });

    test('a calendar that refuses new events says so', () async {
      store.readOnly.add('calendar.family');
      final r = await requests.handle({
        'action': 'add',
        'title': 'Dentist',
        'start': '2026-10-22 16:00',
      });
      expect(r['ok'], isFalse);
      expect(r['error'], contains('cannot take new events'));
    });

    test('heard here, it opens the day with the event ringed', () async {
      await requests.handle({
        'action': 'add',
        'title': 'Dentist',
        'start': '2026-10-22 16:00',
        'voiceTurn': true,
        'show': true,
      });
      final s = store.shown.single;
      expect(s.view, 'day');
      expect(s.date, DateTime(2026, 10, 22));
      expect(s.h, (summary: 'Dentist', start: DateTime(2026, 10, 22, 16)));
    });

    test(
      'Show on the kiosk off, or another kiosk named, shows nothing',
      () async {
        await requests.handle({
          'action': 'add',
          'title': 'A',
          'start': '2026-10-22 16:00',
          'voiceTurn': true,
          'show': 'False',
        });
        await requests.handle({
          'action': 'add',
          'title': 'B',
          'start': '2026-10-22 17:00',
          'voiceTurn': false,
        });
        expect(store.shown, isEmpty);
      },
    );
  });

  group('find', () {
    setUp(() {
      store.events['calendar.sam'] = [
        _event(
          'Dentist appointment',
          DateTime(2026, 11, 3, 10),
          DateTime(2026, 11, 3, 11),
          'calendar.sam',
        ),
        _event(
          'Gym',
          DateTime(2026, 10, 19, 18),
          DateTime(2026, 10, 19, 19),
          'calendar.sam',
        ),
      ];
      store.events['calendar.leo_school'] = [
        _event(
          'Soccer practice',
          DateTime(2026, 10, 19, 16),
          DateTime(2026, 10, 19, 17),
          'calendar.leo_school',
        ),
        _event(
          'Field trip',
          DateTime(2026, 10, 20),
          DateTime(2026, 10, 21),
          'calendar.leo_school',
          allDay: true,
        ),
      ];
    });

    test('with no day and no title, today', () async {
      final r = await requests.handle({'action': 'find'});
      expect(r['result'], 'found');
      expect(
        [for (final e in r['events']! as List) (e as Map)['title']],
        ['Soccer practice', 'Gym'],
      );
    });

    test('a title looks ahead and keeps the best match', () async {
      final r = await requests.handle({
        'action': 'find',
        'title': 'the dentist',
        'voiceTurn': true,
      });
      final events = r['events']! as List;
      expect(events, hasLength(1));
      expect(
        (events.single as Map)['when'],
        'Tuesday 2026-11-03 10:00 to 11:00',
      );
      expect(store.shown.single.view, 'day');
      expect(store.shown.single.h?.summary, 'Dentist appointment');
    });

    test('a span of days, for one person, opens the week', () async {
      final r = await requests.handle({
        'action': 'find',
        'start': '2026-10-19',
        'end': '2026-10-25',
        'people': ['Leo'],
        'voiceTurn': true,
      });
      expect(
        [for (final e in r['events']! as List) (e as Map)['title']],
        ['Soccer practice', 'Field trip'],
      );
      expect(
        (r['events']! as List)[1],
        containsPair('when', 'Tuesday 2026-10-20, all day'),
      );
      expect(store.shown.single.view, 'week');
    });

    test('a span all before today carries a note', () async {
      final r = await requests.handle({
        'action': 'find',
        'start': '2025-05-19 00:00:00',
        'end': '2025-05-25 23:59:59',
      });
      expect(r['note'], contains('before today, Monday 2026-10-19'));
    });

    test('nothing found says so', () async {
      final r = await requests.handle({'action': 'find', 'title': 'piano'});
      expect(r['ok'], isTrue);
      expect(r['result'], 'nothing_found');
    });
  });

  group('change and cancel', () {
    test('a new day keeps the time and the length', () async {
      store.events['calendar.sam'] = [
        _event(
          'Dentist',
          DateTime(2026, 10, 22, 16),
          DateTime(2026, 10, 22, 16, 45),
          'calendar.sam',
          uid: 'u1',
        ),
      ];
      final r = await requests.handle({
        'action': 'change',
        'title': 'dentist',
        'new_start': '2026-10-23',
      });
      expect(r['result'], 'changed');
      final (entity, event, draft) = store.updated.single;
      expect(entity, 'calendar.sam');
      expect(event.uid, 'u1');
      expect(draft.start, DateTime(2026, 10, 23, 16));
      expect(draft.end, DateTime(2026, 10, 23, 16, 45));
    });

    test('a move to a day before today is sent back', () async {
      store.events['calendar.sam'] = [
        _event(
          'Dentist',
          DateTime(2026, 10, 22, 14, 30),
          DateTime(2026, 10, 22, 15, 30),
          'calendar.sam',
          uid: 'u1',
        ),
      ];
      final r = await requests.handle({
        'action': 'change',
        'title': 'dentist',
        'new_start': '2025-07-25 16:00',
      });
      expect(r['ok'], isFalse);
      expect(r['error'], contains('in the past'));
      expect(store.updated, isEmpty);
    });

    test('a cancel on a day before today is sent back', () async {
      final r = await requests.handle({
        'action': 'cancel',
        'title': 'chess',
        'start': '2025-03-26 00:00:00',
      });
      expect(r['ok'], isFalse);
      expect(r['error'], contains('Today is Monday 2026-10-19'));
    });

    test('a new time alone stays on the same day', () async {
      store.events['calendar.sam'] = [
        _event(
          'Dentist',
          DateTime(2026, 10, 22, 16),
          DateTime(2026, 10, 22, 17),
          'calendar.sam',
          uid: 'u1',
        ),
      ];
      await requests.handle({
        'action': 'change',
        'title': 'dentist',
        'new_start': '15:00',
      });
      expect(store.updated.single.$3.start, DateTime(2026, 10, 22, 15));
    });

    test('a shared event changes on every calendar it is on', () async {
      for (final (cal, uid) in [
        ('calendar.sam', 'a'),
        ('calendar.leo_school', 'b'),
      ]) {
        store.events[cal] = [
          _event(
            'Dinner',
            DateTime(2026, 10, 23, 19),
            DateTime(2026, 10, 23, 20),
            cal,
            uid: uid,
          ),
        ];
      }
      await requests.handle({
        'action': 'change',
        'title': 'dinner',
        'new_title': 'Pizza night',
      });
      expect(
        [for (final (e, ev, d) in store.updated) (e, ev.uid, d.summary)],
        [
          ('calendar.sam', 'a', 'Pizza night'),
          ('calendar.leo_school', 'b', 'Pizza night'),
        ],
      );
    });

    test('several matches ask which one', () async {
      store.events['calendar.sam'] = [
        _event(
          'Gym',
          DateTime(2026, 10, 20, 7),
          DateTime(2026, 10, 20, 8),
          'calendar.sam',
          uid: 'g1',
        ),
        _event(
          'Gym class',
          DateTime(2026, 10, 22, 7),
          DateTime(2026, 10, 22, 8),
          'calendar.sam',
          uid: 'g2',
        ),
      ];
      final r = await requests.handle({'action': 'cancel', 'title': 'gym'});
      expect(r['ok'], isFalse);
      expect(r['error'], contains('several events match'));
      expect(r['events'], hasLength(2));
      expect(store.deleted, isEmpty);
    });

    test(
      'a repeating event asks which day, unless it is all of them',
      () async {
        store.events['calendar.leo_school'] = [
          for (final day in [19, 26])
            _event(
              'Soccer practice',
              DateTime(2026, 10, day, 16),
              DateTime(2026, 10, day, 17),
              'calendar.leo_school',
              uid: 's',
              recurrenceId: '202610${day}T160000',
              rrule: 'FREQ=WEEKLY',
            ),
        ];
        final ask = await requests.handle({
          'action': 'cancel',
          'title': 'soccer',
        });
        expect(ask['error'], contains('it repeats'));
        final one = await requests.handle({
          'action': 'cancel',
          'title': 'soccer',
          'start': '2026-10-26',
        });
        expect(one['result'], 'canceled');
        expect(store.deleted.single.$2.recurrenceId, '20261026T160000');
        expect(store.deleted.single.$3, 'this');
        final all = await requests.handle({
          'action': 'cancel',
          'title': 'soccer',
          'scope': 'all',
        });
        expect(all['result'], 'canceled');
        expect(store.deleted.last.$3, 'all');
      },
    );

    test('an event without a uid cannot be changed from here', () async {
      store.events['calendar.family'] = [
        _event(
          'Holiday',
          DateTime(2026, 10, 22),
          DateTime(2026, 10, 23),
          'calendar.family',
          allDay: true,
        ),
      ];
      final r = await requests.handle({'action': 'cancel', 'title': 'holiday'});
      expect(r['ok'], isFalse);
      expect(r['error'], contains('cannot change or remove'));
    });
  });

  test('show opens the asked view on the asked day', () async {
    final r = await requests.handle({
      'action': 'show',
      'view': 'month',
      'start': '2026-11-01',
    });
    expect(r['result'], 'shown');
    expect(store.shown.single.view, 'month');
    expect(store.shown.single.date, DateTime(2026, 11, 1));
  });

  test('parseWhen reads days, times and bare times on a base day', () {
    expect(parseWhen('2026-10-22'), (
      at: DateTime(2026, 10, 22),
      hasTime: false,
    ));
    expect(parseWhen('2026-10-22 16:30')?.at, DateTime(2026, 10, 22, 16, 30));
    expect(
      parseWhen('4 pm', base: DateTime(2026, 10, 22))?.at,
      DateTime(2026, 10, 22, 16),
    );
    expect(parseWhen('soon'), isNull);
  });
}
