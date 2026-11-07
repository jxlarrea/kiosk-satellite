import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/alarms/alarm_manager.dart';
import 'package:kiosk_satellite/managers/alarms/alarm_model.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A ring from start to Stop, Snooze or Silence after, driven by a clock
/// the test moves: what rings, what it holds on the way (the screen, the
/// screensaver, the stop word, the brightness) and what survives a
/// restart. The native side is absent here, so only Dart's own timing and
/// the commands it reaches for are checked. 2026-10-02 is a Friday.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late AlarmManager alarms;
  late List<(String, Map<String, Object?>)> calls;
  late List<VoiceInteractionChanged> holds;
  late List<HaEventRequested> haEvents;
  late DateTime now;
  late CommandRegistry registry;
  var takeoverOk = true;

  Future<void> build(
    List<Map<String, Object?>> list, {
    Map<String, Object> extra = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      'ks.alarms.list': jsonEncode(list),
      ...extra,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    registry = commands;
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    calls = [];
    holds = [];
    haEvents = [];
    bus.on<VoiceInteractionChanged>().listen(holds.add);
    bus.on<HaEventRequested>().listen(haEvents.add);
    for (final name in [
      'bringToFront',
      'screenOn',
      'stopScreensaver',
      'alarmBrightness',
      'setStopWordArmed',
      'alarmTakeover',
      'holdScreensaver',
    ]) {
      commands.register(
        Command(
          name: name,
          description: 'stub',
          handler: (p) async {
            calls.add((name, p));
            if (name == 'alarmTakeover' && p['phase'] != null && !takeoverOk) {
              return const CommandResult.fail('refused');
            }
            return const CommandResult.ok();
          },
        ),
      );
    }
    alarms = AlarmManager(bus, commands, log, settings, clock: () => now);
    await alarms.init();
    await pumpEventQueue();
  }

  tearDown(() async {
    await alarms.dispose();
  });

  Map<String, Object?> daily(
    String time, {
    String id = 'a',
    bool sunrise = false,
    String label = '',
  }) => {
    'id': id,
    'time': time,
    'days': [0, 1, 2, 3, 4, 5, 6],
    'label': label,
    'sunrise': sunrise,
    'on': true,
  };

  Iterable<String> named(String name) =>
      calls.where((c) => c.$1 == name).map((c) => jsonEncode(c.$2));

  test('openAlarms with alarm next asks the list for the next alarm', () async {
    now = DateTime(2026, 10, 2, 6, 0);
    await build([daily('09:00', id: 'late'), daily('07:00', id: 'early')]);
    expect((await registry.execute('openAlarms', const {})).ok, isTrue);
    expect(alarms.focus.value, isNull);
    expect(alarms.visible.value, isTrue);
    alarms.visible.value = false;
    expect(
      (await registry.execute('openAlarms', {'alarm': 'next'})).ok,
      isTrue,
    );
    expect(alarms.focus.value, 'early');
    expect(alarms.visible.value, isTrue);
    expect(
      (await registry.execute('openAlarms', {'alarm': 'late'})).ok,
      isFalse,
    );
  });

  test('openAlarms with alarm next and none set opens the list', () async {
    now = DateTime(2026, 10, 2, 6, 0);
    await build([]);
    await registry.execute('openAlarms', {'alarm': 'next'});
    expect(alarms.focus.value, isNull);
    expect(alarms.visible.value, isTrue);
  });

  test('a due alarm rings, comes forward and arms the stop word', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build([daily('07:00', label: 'Wake up')]);
    final s = alarms.status.value;
    expect(s.phase, AlarmPhase.ringing);
    expect(s.ids, ['a']);
    expect(s.labels, ['Wake up']);
    expect(s.takeover, isNull);
    expect(s.ownView, isTrue);
    expect(named('bringToFront'), isNotEmpty);
    expect(
      named('setStopWordArmed'),
      contains('{"armed":true,"holder":"alarm"}'),
    );
    expect(holds.single.active, isTrue);
    expect(holds.single.reason, 'alarm');
    expect(holds.single.source, InteractionSource.command);
  });

  test('an alarm is not due before its minute or long after it', () async {
    now = DateTime(2026, 10, 2, 6, 59, 30);
    await build([daily('07:00')]);
    expect(alarms.status.value.phase, AlarmPhase.idle);
    expect(alarms.status.value.next?.at, DateTime(2026, 10, 2, 7));
    // Asleep through the whole Silence after window: skipped, not late.
    now = DateTime(2026, 10, 2, 7, 11);
    await alarms.check();
    expect(alarms.status.value.phase, AlarmPhase.idle);
  });

  test(
    'snooze holds it off for the snooze length, then it rings again',
    () async {
      now = DateTime(2026, 10, 2, 7, 0, 5);
      await build([daily('07:00')]);
      expect(await alarms.snooze(), isTrue);
      var s = alarms.status.value;
      expect(s.phase, AlarmPhase.snoozed);
      expect(s.snoozedUntil, DateTime(2026, 10, 2, 7, 10, 5));
      expect(s.next?.at, DateTime(2026, 10, 2, 7, 10, 5));
      expect(holds.last.active, isFalse);
      now = DateTime(2026, 10, 2, 7, 10, 6);
      await alarms.check();
      s = alarms.status.value;
      expect(s.phase, AlarmPhase.ringing);
      expect(s.ids, ['a']);
    },
  );

  test('stop ends it and the same ring never comes back', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build([daily('07:00')]);
    expect(await alarms.stop(), isTrue);
    expect(alarms.status.value.phase, AlarmPhase.idle);
    expect(named('setStopWordArmed').last, '{"armed":false,"holder":"alarm"}');
    now = DateTime(2026, 10, 2, 7, 1);
    await alarms.check();
    expect(alarms.status.value.phase, AlarmPhase.idle);
    expect(alarms.status.value.next?.at, DateTime(2026, 10, 3, 7));
  });

  test('silence after ends a ring nobody stops, as stopped', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build([daily('07:00')]);
    now = DateTime(2026, 10, 2, 7, 10, 6);
    await alarms.check();
    expect(alarms.status.value.phase, AlarmPhase.idle);
  });

  test('a one time alarm turns itself off once it rings', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build([
      {'id': 'o', 'time': '07:00', 'date': '2026-10-02', 'on': true},
    ]);
    expect(alarms.status.value.phase, AlarmPhase.ringing);
    final stored = decodeAlarms(settings.get(defs.alarmsList)).single;
    expect(stored.on, isFalse);
    expect(stored.date, isNull);
  });

  test('saving a one time alarm dates it to its next ring', () async {
    now = DateTime(2026, 10, 2, 9);
    await build(const []);
    final saved = await alarms.save(const Alarm(id: 'n', hour: 8, minute: 0));
    expect(saved.date, '2026-10-03');
    expect(alarms.status.value.next?.at, DateTime(2026, 10, 3, 8));
  });

  test('Clock with Let alarms take over rings on the screensaver', () async {
    takeoverOk = true;
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build(
      [daily('07:00')],
      extra: {'ks.screensaver.enabled': true, 'ks.screensaver.mode': 'clock'},
    );
    final s = alarms.status.value;
    expect(s.phase, AlarmPhase.ringing);
    expect(s.takeover, 'clock');
    expect(s.ownView, isFalse);
    expect(named('alarmTakeover'), contains('{"phase":"ringing"}'));
    expect(holds.last.source, InteractionSource.native);
    await alarms.stop();
    expect(named('alarmTakeover').last, '{"phase":null}');
  });

  test('a refused takeover falls back to the alarm own view', () async {
    takeoverOk = false;
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build(
      [daily('07:00')],
      extra: {
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'weather_mood',
      },
    );
    expect(alarms.status.value.takeover, isNull);
    expect(alarms.status.value.ownView, isTrue);
    expect(holds.last.source, InteractionSource.command);
    takeoverOk = true;
  });

  test('the takeover switch off keeps the own view', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build(
      [daily('07:00')],
      extra: {
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'clock',
        'ks.screensaver.clock_alarm_takeover': false,
      },
    );
    expect(alarms.status.value.takeover, isNull);
    expect(named('alarmTakeover'), isEmpty);
  });

  test('a sunrise alarm brightens ahead and rings at full', () async {
    now = DateTime(2026, 10, 2, 6, 45);
    await build([daily('07:00', sunrise: true)]);
    var s = alarms.status.value;
    expect(s.phase, AlarmPhase.sunrise);
    expect(s.sunriseStart, DateTime(2026, 10, 2, 6, 30));
    final level = calls.lastWhere((c) => c.$1 == 'alarmBrightness').$2['level'];
    expect(level, closeTo(0.02 + 0.98 * 0.5, 0.01));
    now = DateTime(2026, 10, 2, 7, 0, 1);
    await alarms.check();
    s = alarms.status.value;
    expect(s.phase, AlarmPhase.ringing);
    expect(calls.lastWhere((c) => c.$1 == 'alarmBrightness').$2['level'], 1);
    await alarms.stop();
    expect(
      calls.lastWhere((c) => c.$1 == 'alarmBrightness').$2['level'],
      isNull,
    );
  });

  test('stopping a sunrise skips its ring', () async {
    now = DateTime(2026, 10, 2, 6, 45);
    await build([daily('07:00', sunrise: true)]);
    await alarms.stop();
    // The skipped ring no longer counts as the next one.
    expect(alarms.status.value.next?.at, DateTime(2026, 10, 3, 7));
    now = DateTime(2026, 10, 2, 7, 0, 1);
    await alarms.check();
    expect(alarms.status.value.phase, AlarmPhase.idle);
  });

  test('stopping the sunrise of a one time alarm turns it off', () async {
    now = DateTime(2026, 10, 2, 6, 45);
    await build([
      {'id': 'o', 'time': '07:00', 'date': '2026-10-02', 'sunrise': true},
    ]);
    expect(alarms.status.value.phase, AlarmPhase.sunrise);
    await alarms.stop();
    expect(decodeAlarms(settings.get(defs.alarmsList)).single.on, isFalse);
    expect(alarms.status.value.next, isNull);
  });

  test('a snooze survives a restart', () async {
    now = DateTime(2026, 10, 2, 7, 5);
    await build(
      [daily('07:00')],
      extra: {
        'ks.alarms.runtime': jsonEncode({
          'handled': {'a': DateTime(2026, 10, 2, 7).millisecondsSinceEpoch},
          'snooze': {
            'ids': ['a'],
            'at': DateTime(2026, 10, 2, 7).millisecondsSinceEpoch,
            'until': DateTime(2026, 10, 2, 7, 10).millisecondsSinceEpoch,
          },
        }),
      },
    );
    final s = alarms.status.value;
    expect(s.phase, AlarmPhase.snoozed);
    expect(s.snoozedUntil, DateTime(2026, 10, 2, 7, 10));
  });

  test(
    'the open list holds the screensaver and lets go when it closes',
    () async {
      now = DateTime(2026, 10, 2, 9);
      await build(const []);
      alarms.visible.value = true;
      alarms.visible.value = false;
      await pumpEventQueue();
      expect(named('holdScreensaver'), [
        '{"holder":"alarms","held":true}',
        '{"holder":"alarms","held":false}',
      ]);
    },
  );

  test('a second alarm at the same time on the same days is refused', () async {
    now = DateTime(2026, 10, 2, 9);
    await build([
      {'id': 'o', 'time': '07:00', 'on': false},
      {
        'id': 'w',
        'time': '06:30',
        'days': [1, 2, 3, 4, 5],
      },
    ]);
    // Another one time alarm at 7:00, even with the first one off.
    expect(
      () => alarms.save(const Alarm(id: 'n1', hour: 7, minute: 0)),
      throwsA(
        isA<DuplicateAlarm>().having((e) => e.existing.id, 'existing', 'o'),
      ),
    );
    // Same days, in any order, are the same repeat.
    expect(
      () => alarms.save(
        const Alarm(id: 'n2', hour: 6, minute: 30, days: [5, 4, 3, 2, 1]),
      ),
      throwsA(isA<DuplicateAlarm>()),
    );
    // Other days or another minute are a different alarm.
    await alarms.save(const Alarm(id: 'n3', hour: 6, minute: 30, days: [6]));
    await alarms.save(const Alarm(id: 'n4', hour: 7, minute: 1));
    // Saving an alarm over itself is no duplicate.
    await alarms.save(
      const Alarm(id: 'w', hour: 6, minute: 30, days: [1, 2, 3, 4, 5]),
    );
    expect(alarms.alarms.value, hasLength(4));
  });

  test('the save command answers duplicate for the remote to word', () async {
    now = DateTime(2026, 10, 2, 9);
    await build([
      {'id': 'o', 'time': '07:00'},
    ]);
    final r = await registry.execute('alarmSave', {
      'alarm': {'time': '07:00', 'on': true},
    });
    expect(r.ok, isFalse);
    expect(r.error, 'duplicate');
    expect(alarms.alarms.value, hasLength(1));
  });

  test('turning an existing alarm on is never refused', () async {
    now = DateTime(2026, 10, 2, 9);
    await build([
      {'id': 'a', 'time': '07:00'},
      {'id': 'b', 'time': '07:00', 'on': false},
    ]);
    expect(await alarms.setEnabled('b', true), isTrue);
  });

  test('deleting a ringing alarm stops it', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build([daily('07:00')]);
    expect(await alarms.delete('a'), isTrue);
    expect(alarms.status.value.phase, AlarmPhase.idle);
    expect(alarms.alarms.value, isEmpty);
  });

  group('Home Assistant events', () {
    List<String> fired() => [
      for (final e in haEvents) '${e.data['event_type']} ${e.data['alarm_id']}',
    ];

    test('a ring, a snooze and a stop each fire one', () async {
      now = DateTime(2026, 10, 2, 7, 0, 5);
      await build([daily('07:00', label: 'Wake up')]);
      expect(haEvents.single.name, 'kiosk_satellite_alarm');
      expect(haEvents.single.data, {
        'event_type': 'ringing',
        'alarm_id': 'a',
        'label': 'Wake up',
        'time': '07:00',
        'days': ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
        'enabled': true,
      });
      await alarms.snooze();
      await pumpEventQueue();
      expect(
        haEvents.last.data['snoozed_until'],
        DateTime(2026, 10, 2, 7, 10, 5).toUtc().toIso8601String(),
      );
      now = DateTime(2026, 10, 2, 7, 10, 6);
      await alarms.check();
      await alarms.stop();
      await pumpEventQueue();
      expect(fired(), ['ringing a', 'snoozed a', 'ringing a', 'stopped a']);
    });

    test('a ring nobody stops fires silenced', () async {
      now = DateTime(2026, 10, 2, 7, 0, 5);
      await build([daily('07:00')]);
      now = DateTime(2026, 10, 2, 7, 10, 6);
      await alarms.check();
      await pumpEventQueue();
      expect(fired(), ['ringing a', 'silenced a']);
    });

    test('a sunrise fires before its ring', () async {
      now = DateTime(2026, 10, 2, 6, 45);
      await build([daily('07:00', sunrise: true)]);
      now = DateTime(2026, 10, 2, 7, 0, 1);
      await alarms.check();
      await pumpEventQueue();
      expect(fired(), ['sunrise a', 'ringing a']);
    });

    test('changes to the list fire created, updated and deleted', () async {
      now = DateTime(2026, 10, 2, 6);
      await build([daily('07:00')]);
      expect(haEvents, isEmpty);
      await alarms.save(
        const Alarm(id: 'b', hour: 8, minute: 30, days: [1, 2, 3, 4, 5]),
      );
      await alarms.setEnabled('a', false);
      await alarms.delete('b');
      await pumpEventQueue();
      expect(fired(), ['created b', 'updated a', 'deleted b']);
      expect(haEvents[1].data['enabled'], isFalse);
      expect(haEvents[2].data['days'], ['mon', 'tue', 'wed', 'thu', 'fri']);
    });

    test('deleting a ringing alarm still names it when it stops', () async {
      now = DateTime(2026, 10, 2, 7, 0, 5);
      await build([daily('07:00', label: 'Wake up')]);
      await alarms.delete('a');
      await pumpEventQueue();
      expect(fired(), ['ringing a', 'deleted a', 'stopped a']);
      expect(haEvents.last.data['label'], 'Wake up');
    });
  });

  group('ease in', () {
    const channel = MethodChannel('kiosk_satellite/alarms');
    late List<Map<Object?, Object?>> rings;

    setUp(() {
      rings = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method != 'ring') return null;
            rings.add(call.arguments as Map<Object?, Object?>);
            return true;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Future<int> easeOf(
      Map<String, Object?> alarm, {
      Map<String, Object> extra = const {},
    }) async {
      now = DateTime(2026, 10, 2, 7, 0, 5);
      await build([alarm], extra: extra);
      return rings.single['easeMs']! as int;
    }

    test('rings at once by default', () async {
      expect(await easeOf(daily('07:00')), 0);
    });

    test('follows the default switch over its seconds', () async {
      expect(
        await easeOf(
          daily('07:00'),
          extra: {'ks.alarms.ease_in': true, 'ks.alarms.ease_in_seconds': 45},
        ),
        45000,
      );
    });

    test("an alarm's own choice wins either way", () async {
      expect(
        await easeOf(
          {...daily('07:00'), 'ease': false},
          extra: {'ks.alarms.ease_in': true},
        ),
        0,
      );
      await alarms.dispose();
      rings.clear();
      expect(await easeOf({...daily('07:00'), 'ease': true}), 30000);
    });
  });

  group('phrase', () {
    test('the default phrase names the time and the label', () async {
      now = DateTime(2026, 10, 2, 9);
      await build([daily('07:00', label: 'Gym')]);
      final alarm = alarms.alarms.value.single;
      expect(
        alarms.phraseFor(alarm, DateTime(2026, 10, 2, 7)),
        "It's 7:00 AM. Gym",
      );
    });

    test('fills the hour, the minute and the date', () async {
      await build([
        {
          ...daily('07:00'),
          'phrase':
              '{hour} {minute} {dayofmonth} {month} {year}, {date}, {day}',
        },
      ]);
      expect(
        alarms.phraseFor(
          alarms.alarms.value.single,
          DateTime(2026, 10, 2, 19, 5),
        ),
        '7 5 2 October 2026, October 2, 2026, Friday',
      );
    });

    test('{hour} reads 12 at midnight on an AM/PM clock', () async {
      await build([
        {...daily('00:00'), 'phrase': '{hour}'},
      ]);
      expect(
        alarms.phraseFor(alarms.alarms.value.single, DateTime(2026, 10, 2)),
        '12',
      );
    });

    test('asks Home Assistant for the name only when it is used', () async {
      await build([
        {...daily('07:00'), 'phrase': 'Good morning {name}!'},
      ]);
      var asked = 0;
      final named = AlarmManager(
        bus,
        registry,
        Logger(),
        settings,
        clock: () => now,
        userName: () async {
          asked++;
          return 'Sam';
        },
      );
      final alarm = alarms.alarms.value.single;
      expect(
        await named.spokenPhrase(alarm, DateTime(2026, 10, 2, 7)),
        'Good morning Sam!',
      );
      expect(asked, 1);
      await named.spokenPhrase(
        alarm.copyWith(phrase: "It's {time}"),
        DateTime(2026, 10, 2, 7),
      );
      expect(asked, 1);
    });

    test('a failed name lookup says the phrase without it', () async {
      await build([
        {...daily('07:00'), 'phrase': 'Good morning {name}!'},
      ]);
      final named = AlarmManager(
        bus,
        registry,
        Logger(),
        settings,
        clock: () => now,
        userName: () async => throw StateError('offline'),
      );
      expect(
        await named.spokenPhrase(
          alarms.alarms.value.single,
          DateTime(2026, 10, 2, 7),
        ),
        'Good morning!',
      );
    });

    test("an alarm's own phrase wins over the default", () async {
      now = DateTime(2026, 10, 2, 9);
      await build([
        {...daily('07:00', label: 'Gym'), 'phrase': 'Happy {day}, {label}'},
      ]);
      expect(
        alarms.phraseFor(alarms.alarms.value.single, DateTime(2026, 10, 2, 7)),
        'Happy Friday, Gym',
      );
    });

    test('{time} and {hour} follow the alarms 24-hour clock', () async {
      final evening = DateTime(2026, 10, 2, 19, 5);
      await build(
        [
          {...daily('19:05'), 'phrase': '{time} {hour}'},
        ],
        extra: {'ks.alarms.clock_24h': true},
      );
      expect(alarms.phraseFor(alarms.alarms.value.single, evening), '19:05 19');
      await settings.set(defs.alarmsClock24h, false);
      expect(
        alarms.phraseFor(alarms.alarms.value.single, evening),
        '7:05 PM 7',
      );
    });

    test('an AM/PM clock says AM/PM in a 24-hour language', () async {
      await initializeDateFormatting();
      await build(
        [
          {...daily('19:05'), 'phrase': '{time}'},
        ],
        extra: {'ks.alarms.clock_24h': false},
      );
      // With plain spaces, which every text to speech engine reads.
      expect(
        Intl.withLocale(
          'es',
          () => alarms.phraseFor(
            alarms.alarms.value.single,
            DateTime(2026, 10, 2, 19, 5),
          ),
        ),
        '7:05 p. m.',
      );
    });

    test('no label leaves no stray stop', () async {
      now = DateTime(2026, 10, 2, 9);
      await build([daily('07:00')]);
      expect(
        alarms.phraseFor(alarms.alarms.value.single, DateTime(2026, 10, 2, 7)),
        "It's 7:00 AM.",
      );
    });
  });
}
