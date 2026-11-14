import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/voice_timers/shared_timers_manager.dart';
import 'package:kiosk_satellite/managers/voice_timers/voice_timer_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One kiosk of the pair: its own bus, commands and clock. The two share
/// the mocked preferences, so a setting is set for both.
class _Kiosk {
  _Kiosk(this.id, this.name, this.skew);

  final String id;
  final String name;

  /// How far this kiosk's clock is from the test's.
  final Duration skew;
  final bus = EventBus();
  final log = Logger();
  late final commands = CommandRegistry(log).as('test');
  late final SettingsManager settings;
  late final VoiceTimerManager timers;
  late final SharedTimersManager shared;
  late DateTime Function() real;
  final chimes = <DateTime>[];
  final actions = <VoiceTimerAction>[];
  late final List<_Kiosk> network;

  DateTime now() => real().add(skew);

  Future<void> start(http.Client client) async {
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    timers = VoiceTimerManager(
      bus,
      commands,
      log,
      settings: settings,
      clock: now,
    );
    await timers.init();
    commands
      ..register(
        Command(
          name: 'fleet',
          description: '',
          handler: (_) async => CommandResult.ok({
            'enabled': true,
            'devices': [
              for (final k in network)
                {
                  'id': k.id,
                  'name': k.name,
                  'address': k.id,
                  'port': 2324,
                  'self': k == this,
                },
            ],
          }),
        ),
      )
      ..register(
        Command(
          name: 'voiceTimers',
          description: '',
          handler: (_) async => const CommandResult.ok({'timers': <Object>[]}),
        ),
      )
      ..register(
        Command(
          name: 'voiceChime',
          description: '',
          handler: (_) async {
            chimes.add(real());
            return CommandResult.ok({'id': 'chime${chimes.length}'});
          },
        ),
      );
    for (final quiet in ['voiceStopSpeech', 'voiceSpeakerDone', 'screenOn']) {
      commands.register(
        Command(
          name: quiet,
          description: '',
          handler: (_) async => const CommandResult.ok(),
        ),
      );
    }
    bus.on<VoiceTimerAction>().listen((action) {
      actions.add(action);
      // Native Voice Satellite drops its ringing timers on a dismissal.
      if (action.action == 'dismiss' && action.entityId == 'native') {
        unawaited(setTimers(const []));
      }
    });
    shared = SharedTimersManager(
      bus,
      commands,
      log,
      settings,
      timers,
      clientFactory: () => client,
      clock: now,
    );
    await shared.init();
  }

  /// What native Voice Satellite does when its timers change.
  Future<void> setTimers(List<Map<String, Object?>> list) async {
    await commands.execute('setVoiceTimers', {
      'entityId': 'native',
      'timers': [
        for (final t in list)
          if (t['finished'] != true)
            {
              'id': t['timer_id'],
              'name': t['name'],
              'totalSeconds': t['seconds_left'],
              'startedAt': now().millisecondsSinceEpoch,
              'isActive': t['is_active'],
              'duration': t['duration_seconds'],
            },
      ],
    });
    final ringing = [
      for (final t in list)
        if (t['finished'] == true)
          {
            'id': t['timer_id'],
            'name': t['name'],
            'totalSeconds': 0,
            'startedAt': 0,
          },
    ];
    await commands.execute('setVoiceTimerAlert', {
      'entityId': 'native',
      'timers': ringing,
    });
    bus.publish(VoiceTimersChanged(list));
  }

  Map<String, Object?> running(String id, String name, int seconds) => {
    'timer_id': id,
    'name': name,
    'total_seconds': seconds,
    'duration_seconds': seconds,
    'seconds_left': seconds,
    'is_active': true,
    'ends_at': now().add(Duration(seconds: seconds)).toUtc().toIso8601String(),
    'finished': false,
  };

  Map<String, Object?> finished(String id, String name) => {
    'timer_id': id,
    'name': name,
    'total_seconds': 60,
    'seconds_left': 0,
    'is_active': false,
    'ends_at': null,
    'finished': true,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Kiosk kitchen;
  late _Kiosk bedroom;
  late List<String> posts;
  late WidgetTester current;

  /// The kitchen shares with the bedroom, whose clock runs five seconds
  /// ahead. A request takes 20 ms each way.
  Future<void> pair(WidgetTester tester) async {
    current = tester;
    SharedPreferences.setMockInitialValues({
      'ks.${defs.voiceTimersShare.key}': true,
      'ks.${defs.voiceTimersShareWith.key}': SharedTimerTarget.encode(
        const [SharedTimerTarget('bedroom', 'Bedroom')],
      ),
    });
    kitchen = _Kiosk('kitchen', 'Kitchen', Duration.zero);
    bedroom = _Kiosk('bedroom', 'Bedroom', const Duration(seconds: 5));
    final all = [kitchen, bedroom];
    posts = [];
    final client = MockClient((request) async {
      final target = all.firstWhere((k) => k.id == request.url.host);
      posts.add('${request.url.host}${request.url.path}');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final received = target.now().millisecondsSinceEpoch;
      final r = await target.commands.execute(
        request.url.path.endsWith('/action')
            ? 'sharedTimersAction'
            : 'sharedTimersReceive',
        {
          ...(jsonDecode(request.body) as Map).cast<String, Object?>(),
          'address': 'kitchen',
          'received': received,
        },
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (!r.ok) return http.Response(jsonEncode({'error': r.error}), 400);
      final data = (r.data as Map).cast<String, Object?>();
      return http.Response(jsonEncode(data), data['code'] as int);
    });
    for (final k in all) {
      k
        ..network = all
        ..real = tester.binding.clock.now;
      await k.start(client);
    }
  }

  /// Before the test ends: the framework counts timers left running.
  Future<void> stop() async {
    await current.runAsync(() async {
      for (final k in [kitchen, bedroom]) {
        await k.shared.dispose();
        await k.timers.dispose();
        await k.settings.dispose();
        await k.bus.dispose();
      }
    });
  }

  Future<void> settle(WidgetTester tester, [int ms = 400]) async {
    for (var i = 0; i < ms ~/ 10; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  testWidgets(
    'a timer ends at the same instant on a kiosk whose clock differs',
    (tester) async {
      await pair(tester);
      await kitchen.setTimers([kitchen.running('t1', 'Pasta', 600)]);
      final started = tester.binding.clock.now();
      await settle(tester);
      final shown = bedroom.timers.timers.value;
      expect(shown, hasLength(1));
      expect(shown.single.name, 'Pasta');
      expect(shown.single.origin, 'Kitchen');
      expect(shown.single.shared, isTrue);
      expect(shown.single.duration, 600);
      // On the bedroom's clock, five seconds ahead, the end is the same
      // moment the kitchen counts to.
      final ends = shown.single.startedAt + shown.single.totalSeconds * 1000;
      final real = ends - bedroom.skew.inMilliseconds;
      expect(
        (real -
                started
                    .add(const Duration(seconds: 600))
                    .millisecondsSinceEpoch)
            .abs(),
        lessThanOrEqualTo(2),
      );
      expect(
        shown.single.remaining(bedroom.now()),
        kitchen.timers.timers.value.single.remaining(kitchen.now()),
      );
      await stop();
    },
  );

  testWidgets('both kiosks sound the first chime together', (tester) async {
    await pair(tester);
    await kitchen.setTimers([kitchen.running('t1', 'Pasta', 60)]);
    await settle(tester);
    await kitchen.setTimers([kitchen.finished('t1', 'Pasta')]);
    final finished = tester.binding.clock.now();
    await settle(tester, 1000);
    expect(kitchen.chimes, hasLength(1));
    expect(bedroom.chimes, hasLength(1));
    expect(
      kitchen.chimes.single
          .difference(bedroom.chimes.single)
          .inMilliseconds
          .abs(),
      lessThanOrEqualTo(10),
    );
    // The owner held its own chime back to give the other kiosk time.
    expect(
      kitchen.chimes.single.difference(finished),
      greaterThanOrEqualTo(const Duration(milliseconds: 390)),
    );
    expect(bedroom.timers.alerts.value.single.origin, 'Kitchen');
    await stop();
  });

  testWidgets('a pause on the other kiosk reaches the owner', (tester) async {
    await pair(tester);
    await kitchen.setTimers([kitchen.running('t1', 'Pasta', 600)]);
    await settle(tester);
    bedroom.timers.control(bedroom.timers.timers.value.single.id, 'pause');
    await settle(tester);
    expect(posts.last, 'kitchen/api/timers/shared/action');
    final action = kitchen.actions.last;
    expect(action.entityId, 'native');
    expect(action.id, 't1');
    expect(action.action, 'pause');
    await stop();
  });

  testWidgets('a dismissal on the other kiosk stops the ring on both', (
    tester,
  ) async {
    await pair(tester);
    await kitchen.setTimers([kitchen.finished('t1', 'Pasta')]);
    await settle(tester, 1000);
    expect(bedroom.timers.alerts.value, hasLength(1));
    bedroom.timers.control(bedroom.timers.alerts.value.single.id, 'dismiss');
    await settle(tester);
    expect(bedroom.timers.alerts.value, isEmpty);
    expect(kitchen.timers.alerts.value, isEmpty);
    expect(kitchen.actions.last.action, 'dismiss');
    final before = bedroom.chimes.length;
    await settle(tester, 4000);
    expect(bedroom.chimes.length, before);
    await stop();
  });

  testWidgets('the stop word ends a shared ring from the kiosk it rings on', (
    tester,
  ) async {
    await pair(tester);
    final ringing = <bool>[];
    bedroom.bus.on<SharedTimerAlertChanged>().listen(
      (e) => ringing.add(e.ringing),
    );
    await kitchen.setTimers([kitchen.finished('t1', 'Pasta')]);
    await settle(tester, 1000);
    expect(ringing, [true]);
    bedroom.bus.publish(const SharedTimerDismissRequested());
    await settle(tester);
    expect(ringing, [true, false]);
    expect(kitchen.timers.alerts.value, isEmpty);
    await stop();
  });

  testWidgets('a kiosk taken off the list loses the timers', (tester) async {
    await pair(tester);
    await kitchen.setTimers([kitchen.running('t1', 'Pasta', 600)]);
    await settle(tester);
    expect(bedroom.timers.timers.value, hasLength(1));
    await kitchen.settings.set(defs.voiceTimersShareWith, '[]');
    await settle(tester);
    expect(bedroom.timers.timers.value, isEmpty);
    await stop();
  });

  testWidgets('a timer that ends on the owner goes from the other kiosk', (
    tester,
  ) async {
    await pair(tester);
    await kitchen.setTimers([kitchen.running('t1', 'Pasta', 600)]);
    await settle(tester);
    await kitchen.setTimers(const []);
    await settle(tester);
    expect(bedroom.timers.timers.value, isEmpty);
    await stop();
  });

  testWidgets('Show shared timers off refuses them', (tester) async {
    await pair(tester);
    await bedroom.settings.set(defs.voiceTimersReceive, false);
    await kitchen.setTimers([kitchen.running('t1', 'Pasta', 600)]);
    await settle(tester);
    expect(bedroom.timers.timers.value, isEmpty);
    expect(
      ((kitchen.shared.describe()['targets']! as List).single as Map)['status'],
      'off',
    );
    await stop();
  });

  testWidgets('timers from a kiosk that went quiet are dropped', (
    tester,
  ) async {
    await pair(tester);
    await kitchen.setTimers([kitchen.running('t1', 'Pasta', 6000)]);
    await settle(tester);
    expect(bedroom.timers.timers.value, hasLength(1));
    unawaited(kitchen.shared.dispose());
    await tester.pump(
      SharedTimersManager.staleAfter + const Duration(seconds: 25),
    );
    expect(bedroom.timers.timers.value, isEmpty);
    await stop();
  });

  testWidgets('an action from a kiosk not on the list is refused', (
    tester,
  ) async {
    await pair(tester);
    await kitchen.setTimers([kitchen.running('t1', 'Pasta', 600)]);
    await settle(tester);
    kitchen.actions.clear();
    final r = await kitchen.commands.execute('sharedTimersAction', {
      'from': 'garage',
      'id': 't1',
      'action': 'cancel',
    });
    expect((r.data as Map)['code'], 403);
    expect(kitchen.actions, isEmpty);
    await stop();
  });

  test('the pick list survives junk', () {
    expect(SharedTimerTarget.parse('nope'), isEmpty);
    expect(SharedTimerTarget.parse('{"id":"a"}'), isEmpty);
    final list = SharedTimerTarget.parse(
      '[{"id":"a","name":"A"},{"id":"a"},{"id":""},7,{"id":"b"}]',
    );
    expect(list.map((t) => t.id), ['a', 'b']);
    expect(list.first.name, 'A');
  });
}
