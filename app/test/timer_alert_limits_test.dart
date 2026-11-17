import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/voice_timers/voice_timer_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #1480: Silence after stops the ring of a finished timer and keeps
/// the alert, Dismiss after dismisses it as a tap does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late List<String> sounds;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    sounds = [];
    commands
      ..register(
        Command(
          name: 'voiceChime',
          description: '',
          handler: (_) async {
            sounds.add('play');
            return CommandResult.ok({'id': 'sound${sounds.length}'});
          },
        ),
      )
      ..register(
        Command(
          name: 'voiceStopSpeech',
          description: '',
          handler: (p) async {
            sounds.add('stop:${p['id']}');
            return const CommandResult.ok();
          },
        ),
      );
  });

  /// Runs [body] with a manager whose clock and timers follow fake time.
  /// Everything that schedules a timer is set up inside the fake zone.
  void run(
    void Function(
      FakeAsync async,
      VoiceTimerManager timers,
      List<VoiceTimerAction> actions,
      List<bool> quiet,
    )
    body,
  ) {
    fakeAsync((async) {
      final start = DateTime(2026, 11, 17, 12).millisecondsSinceEpoch;
      final timers = VoiceTimerManager(
        bus,
        commands,
        Logger(),
        settings: settings,
        clock: () => DateTime.fromMillisecondsSinceEpoch(
          start + async.elapsed.inMilliseconds,
        ),
      );
      final actions = <VoiceTimerAction>[];
      final quiet = <bool>[];
      final subs = [
        bus.on<VoiceTimerAction>().listen(actions.add),
        bus.on<TimerRingQuiet>().listen((e) => quiet.add(e.quiet)),
      ];
      timers.init();
      async.flushMicrotasks();
      body(async, timers, actions, quiet);
      for (final s in subs) {
        s.cancel();
      }
      timers.dispose();
      async.flushMicrotasks();
    });
  }

  void alert(FakeAsync async, List<String> ids) {
    commands.execute('setVoiceTimerAlert', {
      'entityId': 'assist_satellite.kitchen',
      'timers': [
        for (final id in ids)
          {
            'id': id,
            'name': '',
            'totalSeconds': 0,
            'startedAt': 0,
            'isActive': false,
          },
      ],
    });
    async.flushMicrotasks();
  }

  void set(FakeAsync async, defs.SettingDef<String> def, String value) {
    settings.set(def, value);
    async.flushMicrotasks();
  }

  /// Lets the ring go on for [seconds], each chime ending before the next.
  void ring(FakeAsync async, int seconds) {
    for (var i = 0; i < seconds; i++) {
      bus.publish(SoundEnded(id: 'sound${sounds.length}'));
      async.elapse(const Duration(seconds: 1));
    }
  }

  int plays() => sounds.where((s) => s == 'play').length;

  test('Never rings until the alert is dismissed', () {
    run((async, timers, actions, quiet) {
      alert(async, ['done']);
      ring(async, 1800);
      expect(timers.quiet, isFalse);
      expect(plays(), greaterThan(500));
      expect(actions, isEmpty);
      expect(timers.alerts.value, hasLength(1));
      timers.dismissLocal();
      async.flushMicrotasks();
    });
  });

  test('Silence after stops the sound and keeps the alert', () {
    run((async, timers, actions, quiet) {
      set(async, defs.timersSilenceAfter, '30');
      alert(async, ['done']);
      // The chime of the 27th second is still playing at 30: it stops.
      ring(async, 27);
      expect(timers.quiet, isFalse);
      async.elapse(const Duration(seconds: 4));
      expect(timers.quiet, isTrue);
      expect(quiet, [true]);
      expect(sounds.last, startsWith('stop:'));
      final silenced = plays();
      ring(async, 60);
      expect(plays(), silenced);
      expect(timers.alerts.value, hasLength(1));
      expect(actions, isEmpty);

      // Another timer finishing rings again, for its own 30 seconds.
      alert(async, ['done', 'more']);
      expect(timers.quiet, isFalse);
      expect(plays(), silenced + 1);
      ring(async, 29);
      expect(timers.quiet, isFalse);
      ring(async, 2);
      expect(timers.quiet, isTrue);
      expect(quiet, [true, false, true]);

      timers.control('done', 'dismiss');
      async.flushMicrotasks();
      expect(actions.single.action, 'dismiss');
      expect(timers.alerts.value, isEmpty);
      expect(timers.quiet, isFalse);
      expect(quiet, [true, false, true, false]);
      final rang = plays();
      async.elapse(const Duration(seconds: 30));
      expect(plays(), rang);
    });
  });

  test('Silence after set during the ring counts from the finish', () {
    run((async, timers, actions, quiet) {
      alert(async, ['done']);
      ring(async, 40);
      expect(timers.quiet, isFalse);
      // Already past: quiet at once.
      set(async, defs.timersSilenceAfter, '30');
      expect(timers.quiet, isTrue);
      // Longer than the ring has gone: rings again until then.
      set(async, defs.timersSilenceAfter, '60');
      expect(timers.quiet, isFalse);
      expect(sounds.last, 'play');
      ring(async, 19);
      expect(timers.quiet, isFalse);
      ring(async, 2);
      expect(timers.quiet, isTrue);
      set(async, defs.timersSilenceAfter, '0');
      expect(timers.quiet, isFalse);
      timers.dismissLocal();
      async.flushMicrotasks();
    });
  });

  test('a muted alert stays muted under Silence after', () {
    run((async, timers, actions, quiet) {
      set(async, defs.timersSilenceAfter, '30');
      commands.execute('setVoiceTimerAlert', {
        'entityId': 'assist_satellite.kitchen',
        'muted': true,
        'timers': [
          {'id': 'done', 'name': '', 'totalSeconds': 0, 'startedAt': 0},
        ],
      });
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 60));
      expect(plays(), 0);
      expect(timers.quiet, isTrue);
      timers.dismissLocal();
      async.flushMicrotasks();
    });
  });

  test('Dismiss after dismisses as a tap does', () {
    run((async, timers, actions, quiet) {
      set(async, defs.timersDismissAfter, '60');
      alert(async, ['done']);
      ring(async, 59);
      expect(actions, isEmpty);
      expect(timers.alerts.value, hasLength(1));
      ring(async, 2);
      expect(actions.single.action, 'dismiss');
      expect(actions.single.id, 'done');
      expect(timers.alerts.value, isEmpty);
      final rang = plays();
      async.elapse(const Duration(seconds: 30));
      expect(plays(), rang);
    });
  });

  test('Dismiss after counts from the last timer that finished', () {
    run((async, timers, actions, quiet) {
      set(async, defs.timersDismissAfter, '60');
      alert(async, ['done']);
      ring(async, 40);
      alert(async, ['done', 'more']);
      ring(async, 59);
      expect(actions, isEmpty);
      ring(async, 2);
      expect(actions.single.action, 'dismiss');
      expect(timers.alerts.value, isEmpty);
    });
  });

  test('both together: quiet first, then dismissed', () {
    run((async, timers, actions, quiet) {
      set(async, defs.timersSilenceAfter, '60');
      set(async, defs.timersDismissAfter, '600');
      alert(async, ['done']);
      ring(async, 61);
      expect(timers.quiet, isTrue);
      expect(actions, isEmpty);
      async.elapse(const Duration(seconds: 540));
      expect(actions.single.action, 'dismiss');
      expect(timers.alerts.value, isEmpty);
      expect(timers.quiet, isFalse);
    });
  });

  test('Dismiss after leaves a shared timer to its own kiosk', () {
    run((async, timers, actions, quiet) {
      set(async, defs.timersDismissAfter, '30');
      set(async, defs.timersSilenceAfter, '30');
      timers.setShared(
        'kitchen',
        name: 'Kitchen',
        timers: const [],
        alerts: [
          VoiceTimer.parse({
            'id': 'done',
            'name': '',
            'totalSeconds': 0,
            'startedAt': 0,
          })!,
        ],
      );
      async.flushMicrotasks();
      ring(async, 120);
      expect(actions, isEmpty);
      expect(timers.alerts.value, hasLength(1));
      // Silence after covers the shared ring on this kiosk.
      expect(timers.quiet, isTrue);
      timers.setShared(
        'kitchen',
        name: 'Kitchen',
        timers: const [],
        alerts: const [],
      );
      async.flushMicrotasks();
      expect(timers.quiet, isFalse);
    });
  });
}
