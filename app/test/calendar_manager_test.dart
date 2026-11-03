import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_edits.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/voice/ha_socket.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home Assistant as the calendar sees it: a subscription per calendar
/// that answers with the events at once and again on every change, or an
/// older Home Assistant that only answers calendar.get_events.
class _FakeSocket extends HaSocket {
  _FakeSocket({this.live = true}) : super(baseUrl: () => '', token: () => '');

  final bool live;
  final subscriptions = <Map<String, Object?>>[];
  final listeners = <String, void Function(Map<String, Object?>)>{};
  final events = <String, List<Map<String, Object?>>>{};
  final requests = <Map<String, Object?>>[];

  /// Each calendar's supported_features, as its state carries them.
  final features = <String, int>{};
  int ended = 0;

  @override
  bool get connected => true;

  void push(String entity) =>
      listeners[entity]?.call({'events': events[entity] ?? const []});

  @override
  Future<Future<void> Function()> subscribe(
    Map<String, Object?> command,
    void Function(Map<String, Object?> event) onEvent, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (command['type'] == 'calendar/event/subscribe' && !live) {
      throw StateError('Unknown command.');
    }
    // The people's pictures and the calendars' features: the states
    // right after the result, as Home Assistant sends them.
    if (command['type'] == 'subscribe_entities') {
      final ids = (command['entity_ids'] as List).cast<String>();
      Future.microtask(
        () => onEvent({
          'a': {
            for (final id in ids)
              id: {
                'a': {'supported_features': ?features[id]},
              },
          },
        }),
      );
      return () async {};
    }
    subscriptions.add(command);
    final entity = '${command['entity_id']}';
    if (command['type'] == 'calendar/event/subscribe') {
      listeners[entity] = onEvent;
      // Home Assistant sends the window's events right after the result.
      Future.microtask(() => push(entity));
    }
    return () async {
      ended++;
      listeners.remove(entity);
    };
  }

  @override
  Future<Object?> request(
    Map<String, Object?> command, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    requests.add(command);
    final ids = ((command['target'] as Map)['entity_id'] as List)
        .cast<String>();
    return {
      'response': {
        for (final id in ids) id: {'events': events[id] ?? const []},
      },
    };
  }

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsManager settings;
  late CalendarManager calendar;
  late _FakeSocket socket;

  Future<void> build({bool live = true}) async {
    SharedPreferences.setMockInitialValues({
      'ks.calendar.calendars': jsonEncode([
        {'entity': 'calendar.leo', 'name': 'Leo', 'color': '168,122,31'},
        {'entity': 'calendar.sam', 'name': 'Sam', 'color': '192,97,58'},
        {
          'entity': 'calendar.work',
          'name': 'Work',
          'color': '76,111,165',
          'on': false,
        },
      ]),
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    for (final name in ['screenOn', 'bringToFront', 'stopScreensaver']) {
      commands.register(
        Command(
          name: name,
          description: 'stub',
          handler: (_) async => const CommandResult.ok(),
        ),
      );
    }
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    socket = _FakeSocket(live: live);
    calendar = CalendarManager(bus, commands, log, settings, socket: socket);
    await calendar.init();
  }

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  final soccer = {
    'summary': 'Soccer practice',
    'start': '2026-10-19T16:00:00-05:00',
    'end': '2026-10-19T17:30:00-05:00',
    'uid': 'shared-1',
  };

  test('nothing reaches Home Assistant until a screen watches', () async {
    await build();
    await settle();
    expect(socket.subscriptions, isEmpty);
    expect(calendar.snapshot.value.link, CalendarLink.idle);
  });

  test('each calendar\'s features come with the people\'s pictures', () async {
    await build();
    socket.features['calendar.leo'] = calendarCreates | calendarUpdates;
    socket.features['calendar.sam'] = 0;
    final holder = Object();
    calendar.watch(holder, DateTime(2026, 10, 18), DateTime(2026, 10, 25));
    await settle();
    expect(calendar.calendarAllows('calendar.leo', calendarCreates), isTrue);
    expect(calendar.calendarAllows('calendar.leo', calendarDeletes), isFalse);
    expect(calendar.calendarAllows('calendar.sam', calendarCreates), isFalse);
    // One not read yet is left to Home Assistant to refuse.
    expect(calendar.calendarAllows('calendar.maya', calendarCreates), isTrue);
    calendar.unwatch(holder);
  });

  test('each calendar that is on gets a subscription for the span', () async {
    await build();
    socket.events['calendar.leo'] = [soccer];
    socket.events['calendar.sam'] = [
      soccer,
      {
        'summary': 'Book club',
        'start': '2026-10-20T19:00:00-05:00',
        'end': '2026-10-20T20:30:00-05:00',
      },
    ];
    final holder = Object();
    calendar.watch(holder, DateTime(2026, 10, 18), DateTime(2026, 10, 25));
    await settle();
    expect(socket.subscriptions.map((s) => s['entity_id']), [
      'calendar.leo',
      'calendar.sam',
    ]);
    expect(socket.subscriptions.first['start'], endsWith('Z'));
    final s = calendar.snapshot.value;
    expect(s.link, CalendarLink.live);
    expect(s.events, hasLength(2));
    final shared = s.events.firstWhere((e) => e.summary == 'Soccer practice');
    expect(shared.calendars, ['calendar.leo', 'calendar.sam']);

    // A change in Home Assistant arrives on the subscription.
    socket.events['calendar.sam'] = [soccer];
    socket.push('calendar.sam');
    await settle();
    expect(calendar.snapshot.value.events, hasLength(1));

    // The last screen lets go: the subscriptions end.
    calendar.unwatch(holder);
    await settle();
    expect(socket.ended, 2);
    expect(calendar.snapshot.value.link, CalendarLink.idle);
  });

  test('a span inside the subscribed one needs no new subscription', () async {
    await build();
    calendar.watch(Object(), DateTime(2026, 10, 1), DateTime(2026, 11, 1));
    await settle();
    final count = socket.subscriptions.length;
    calendar.watch(Object(), DateTime(2026, 10, 19), DateTime(2026, 10, 20));
    await settle();
    expect(socket.subscriptions.length, count);
  });

  test('an older Home Assistant is asked with calendar.get_events', () async {
    await build(live: false);
    socket.events['calendar.leo'] = [soccer];
    calendar.watch(Object(), DateTime(2026, 10, 18), DateTime(2026, 10, 25));
    await settle();
    expect(calendar.snapshot.value.link, CalendarLink.polled);
    expect(socket.requests.single['service'], 'get_events');
    expect(calendar.snapshot.value.events.single.summary, 'Soccer practice');
    calendar.unwatch(calendar);
    await calendar.dispose();
  });

  test('hiding a calendar is kept per kiosk', () async {
    await build();
    await calendar.setHidden('calendar.sam', true);
    expect(calendar.hidden.value, {'calendar.sam'});
    expect(jsonDecode(settings.get(defs.calendarHidden)), ['calendar.sam']);
    expect(defs.calendarHidden.perDevice, isTrue);
    await calendar.setHidden('calendar.sam', false);
    expect(calendar.hidden.value, isEmpty);
  });

  test('openCalendar opens on the view and day asked for', () async {
    await build();
    final result = await calendar.commands.execute('openCalendar', {
      'view': 'month',
      'date': '2026-10-31',
    });
    expect(result.ok, isTrue);
    expect(calendar.visible.value, isTrue);
    expect(calendar.opening.view, 'month');
    expect(calendar.opening.date, DateTime(2026, 10, 31));
    await calendar.commands.execute('hideCalendar', const {});
    expect(calendar.visible.value, isFalse);
  });
}
