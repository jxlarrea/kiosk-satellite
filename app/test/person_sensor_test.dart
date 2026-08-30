import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/person/person_sensor_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Portal presence source (discussion #353): Meta's own people
/// detector logs a heartbeat every 30 seconds while someone is in view,
/// and the manager tails it in place of the camera face leg. The log line
/// source is injected, so a test can push lines through it and watch what
/// comes out on the bus, and the clock is injected so the beat ages are
/// deterministic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// What the native bridge answers: the Portal probe and the grant.
  var supported = true;
  String? hint;
  var granted = true;
  var effective = true;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/background'),
          (call) async => switch (call.method) {
            'personSensorSupport' => {'supported': supported, 'hint': ?hint},
            'readLogsState' => {'granted': granted, 'effective': effective},
            _ => null,
          },
        );
  });

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late PersonSensorManager sensor;
  late StreamController<String> lines;
  var attaches = 0;
  late DateTime clock;

  /// A beat line the way the Portal Go writes it, stamped [at].
  String beat(
    DateTime at, {
    String text =
        'PresenceManager: onNotifyPresence presence updated [APPLICATION]',
  }) =>
      '${(at.millisecondsSinceEpoch / 1000).toStringAsFixed(3)}  2658  3721 I $text';

  Future<void> build(
    Map<String, Object> initial, {
    bool broadcastLines = false,
  }) async {
    defs.deviceHiddenKeys.clear();
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    attaches = 0;
    clock = DateTime(2026, 8, 29, 20, 0, 0);
    lines = StreamController<String>.broadcast();
    sensor = PersonSensorManager(
      bus,
      commands,
      log,
      settings,
      lineSource: () {
        attaches++;
        return lines.stream;
      },
      now: () => clock,
    );
    await sensor.init();
  }

  Future<void> pump() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  const on = {'ks.screensaver.dismiss_on_person': true};

  setUp(() {
    supported = true;
    hint = null;
    granted = true;
    effective = true;
  });

  tearDown(() async {
    await sensor.dispose();
    await lines.close();
    defs.deviceHiddenKeys.clear();
  });

  test('idle until Dismiss on person is on', () async {
    await build({});
    await pump();
    expect(sensor.wanted, isFalse);
    expect(sensor.running, isFalse);
    expect(attaches, 0);

    await settings.set(defs.screensaverDismissOnPerson, true);
    await pump();
    expect(sensor.running, isTrue);
    expect(attaches, 1);

    await settings.set(defs.screensaverDismissOnPerson, false);
    await pump();
    expect(sensor.running, isFalse);
  });

  test(
    'a fresh beat is a person sighting, and presence holds for 50 s',
    () async {
      await build(on);
      await pump();
      final faces = <PersonDetected>[];
      final states = <bool>[];
      bus.on<PersonDetected>().listen(faces.add);
      bus.on<PersonSensorChanged>().listen((e) => states.add(e.present));

      lines.add(beat(clock));
      await pump();
      expect(faces, hasLength(1));
      expect(sensor.present, isTrue);
      expect(states, [true]);
      expect(sensor.lastLine, contains('onNotifyPresence'));

      // The next beat 30 s on keeps it, and is a sighting of its own (the
      // postpone leg resets its clock on each).
      clock = clock.add(const Duration(seconds: 30));
      lines.add(
        beat(
          clock,
          text: 'aloha.CameraServiceController: Notify people presence',
        ),
      );
      await pump();
      expect(faces, hasLength(2));
      expect(states, [true]);
    },
  );

  test('presence clears once the newest beat is older than 50 s', () {
    fakeAsync((async) {
      build(on);
      async.flushMicrotasks();
      final states = <bool>[];
      bus.on<PersonSensorChanged>().listen((e) => states.add(e.present));
      lines.add(beat(clock));
      async.flushMicrotasks();
      expect(sensor.present, isTrue);

      // 40 s on, still within the window at the periodic check.
      clock = clock.add(const Duration(seconds: 40));
      async.elapse(const Duration(seconds: 10));
      expect(sensor.present, isTrue);

      // 60 s on, the room reads empty.
      clock = clock.add(const Duration(seconds: 20));
      async.elapse(const Duration(seconds: 10));
      expect(sensor.present, isFalse);
      expect(states, [true, false]);
    });
  });

  test('the backlog logcat dumps on attach does not count', () async {
    await build(on);
    await pump();
    final faces = <PersonDetected>[];
    bus.on<PersonDetected>().listen(faces.add);

    // Stamped a minute ago: the buffer's history, not someone here now.
    lines.add(beat(clock.subtract(const Duration(seconds: 60))));
    // Stamped in the future: a clock stepped back.
    lines.add(beat(clock.add(const Duration(seconds: 30))));
    await pump();
    expect(faces, isEmpty);
    expect(sensor.present, isFalse);
  });

  test('explicit negatives clear, lifecycle chatter is ignored', () async {
    await build(on);
    await pump();
    final faces = <PersonDetected>[];
    bus.on<PersonDetected>().listen(faces.add);

    lines.add(beat(clock));
    await pump();
    expect(sensor.present, isTrue);

    // Engine chatter under the same tags: neither a beat nor a clear.
    lines.add(beat(clock, text: 'PresenceManager: registerPresenceListener'));
    lines.add(
      beat(clock, text: 'PresenceManager: request presence engine start'),
    );
    await pump();
    expect(faces, hasLength(1));
    expect(sensor.present, isTrue);

    // An explicit negative clears at once, without waiting 50 s.
    lines.add(beat(clock, text: 'PresenceManager: pausing presence'));
    await pump();
    expect(sensor.present, isFalse);
    expect(faces, hasLength(1));

    // Lines without the word are not looked at.
    lines.add(beat(clock, text: 'PresenceManager: onCameraUnavailable [0]'));
    await pump();
    expect(sensor.present, isFalse);
  });

  test('the framing director tracking a person counts as a beat, its '
      'reframe moves do not', () async {
    await build(on);
    await pump();
    final faces = <PersonDetected>[];
    bus.on<PersonDetected>().listen(faces.add);

    lines.add(
      beat(
        clock,
        text: 'aloha.TrackAndHoldAiDirector: Forcing hold reframe movement',
      ),
    );
    await pump();
    expect(faces, isEmpty);
    expect(sensor.present, isFalse);

    lines.add(
      beat(
        clock,
        text:
            'aloha.TrackAndHoldAiDirectorDefaultNudgeMovement: '
            'boundaryViolatedPct 0.097218 greater than 0',
      ),
    );
    await pump();
    expect(faces, hasLength(1));
    expect(sensor.present, isTrue);
  });

  test('while someone is in view a sighting goes out every hold tick, so '
      'Postpone on person holds the idle clock', () {
    fakeAsync((async) {
      build(on);
      async.flushMicrotasks();
      final faces = <PersonDetected>[];
      bus.on<PersonDetected>().listen(faces.add);
      lines.add(beat(clock));
      async.flushMicrotasks();
      expect(faces, hasLength(1));

      // Ten seconds on, still within the beat window: five hold ticks.
      clock = clock.add(const Duration(seconds: 10));
      async.elapse(const Duration(seconds: 10));
      expect(faces, hasLength(6));

      // Nobody for a minute: the ticks stop with the presence.
      clock = clock.add(const Duration(seconds: 60));
      async.elapse(const Duration(seconds: 10));
      expect(sensor.present, isFalse);
      final settled = faces.length;
      async.elapse(const Duration(seconds: 10));
      expect(faces, hasLength(settled));
    });
  });

  test('a missing grant leaves the tail off with the reason', () async {
    granted = false;
    effective = false;
    await build(on);
    await pump();
    expect(sensor.running, isFalse);
    expect(sensor.error, 'Log access not granted.');
    expect(attaches, 0);

    // Granted from adb but not in effect until the process restarts.
    granted = true;
    sensor.sync();
    await pump();
    expect(sensor.running, isFalse);
    expect(sensor.error, contains('restarts'));

    // In effect (a restart in real life): the row's sync attaches it.
    effective = true;
    sensor.sync();
    await pump();
    expect(sensor.running, isTrue);
    expect(sensor.error, isNull);
  });

  test('the tail re-attaches with backoff when it ends', () {
    fakeAsync((async) {
      build(on);
      async.flushMicrotasks();
      expect(attaches, 1);

      // The source ends (logd restarted): back in 5 s.
      final first = lines;
      lines = StreamController<String>.broadcast();
      first.close();
      async.flushMicrotasks();
      expect(sensor.running, isFalse);
      async.elapse(const Duration(seconds: 5));
      expect(attaches, 2);
      expect(sensor.running, isTrue);

      // Ends again at once: the delay doubles.
      final second = lines;
      lines = StreamController<String>.broadcast();
      second.close();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 5));
      expect(attaches, 2);
      async.elapse(const Duration(seconds: 5));
      expect(attaches, 3);
    });
  });

  test('not a Portal: the page is hidden and the switches kept off', () async {
    supported = false;
    hint = 'Only on Meta Portal devices.';
    await build({...on, 'ks.screensaver.postpone_on_person': true});
    await pump();
    expect(sensor.knownUnsupported, isTrue);
    expect(
      defs.deviceHiddenKeys,
      containsAll([
        defs.screensaverDismissOnPerson.key,
        defs.screensaverPostponeOnPerson.key,
      ]),
    );
    expect(settings.get(defs.screensaverDismissOnPerson), isFalse);
    expect(settings.get(defs.screensaverPostponeOnPerson), isFalse);
    expect(sensor.running, isFalse);
    expect(attaches, 0);

    // Written from the remote API or an import: written back to false.
    await settings.set(defs.screensaverDismissOnPerson, true);
    await pump();
    expect(settings.get(defs.screensaverDismissOnPerson), isFalse);
  });

  test('status carries what the rows show', () async {
    await build(on);
    await pump();
    lines.add(beat(clock));
    await pump();
    final r = await commands.execute('getPersonSensor', const {});
    expect(r.ok, isTrue);
    final status = r.data as Map<String, Object?>;
    expect(status['enabled'], isTrue);
    expect(status['running'], isTrue);
    expect(status['present'], isTrue);
    expect(status['lastBeat'], clock.millisecondsSinceEpoch);
    expect((status['logAccess'] as Map)['effective'], isTrue);
    final support = await commands.execute('getPersonSensorSupport', const {});
    expect((support.data as Map)['supported'], isTrue);
  });
}
