import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/core/permissions.dart';
import 'package:kiosk_satellite/managers/audio/noise_level_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 80 ms of a square wave at [amplitude] (full scale 32768), whose RMS is
/// the amplitude itself.
Uint8List chunk(int amplitude) {
  final samples = Int16List(1280);
  for (var i = 0; i < samples.length; i++) {
    samples[i] = i.isEven ? amplitude : -amplitude;
  }
  return Uint8List.view(samples.buffer);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late NoiseLevelManager noise;
  SettingsManager? settings;
  late StreamController<Uint8List> mic;
  var micOpen = false;
  var micAsked = 0;
  var micGrant = PermissionOutcome.granted;
  late StreamController<Uint8List> tap;
  late List<NoiseLevelChanged> events;
  late DateTime now;
  var played = false;
  var wake = <String, Object?>{'active': true, 'listening': true};

  /// [adaptive] null builds the manager with no settings, as it measured
  /// before adaptive volume. Otherwise it is the adaptive volume switch.
  Future<void> build({bool? adaptive}) async {
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = null;
    if (adaptive != null) {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsManager(bus, commands, log);
      await settings!.init();
      await settings!.set(defs.adaptiveVolume, adaptive);
    }
    micOpen = false;
    micAsked = 0;
    mic = StreamController<Uint8List>.broadcast(
      onListen: () => micOpen = true,
      onCancel: () => micOpen = false,
    );
    commands.register(
      Command(
        name: 'getWakeWordState',
        description: 'stub',
        handler: (_) async => CommandResult.ok(wake),
      ),
    );
    tap = StreamController<Uint8List>.broadcast(sync: true);
    events = [];
    bus.on<NoiseLevelChanged>().listen(events.add);
    now = DateTime.utc(2026, 10, 8, 12);
    noise = NoiseLevelManager(
      bus,
      commands,
      log,
      settings: settings,
      tap: () => tap.stream,
      micStream: () => mic.stream,
      micPermission: () async {
        micAsked++;
        return micGrant;
      },
      playedWithin: (_) async => played,
      now: () => now,
    );
    await noise.init();
    await pumpEventQueue();
  }

  /// One full window at [amplitude], then the chunk that closes it.
  Future<void> feed(int amplitude) async {
    for (var i = 0; i <= 5000 ~/ 80 + 1; i++) {
      tap.add(chunk(amplitude));
      now = now.add(const Duration(milliseconds: 80));
    }
    await pumpEventQueue();
  }

  Future<Map> level() async =>
      (await commands.execute('getNoiseLevel', const {})).data as Map;

  setUp(() {
    micGrant = PermissionOutcome.granted;
    played = false;
    wake = {'active': true, 'listening': true};
  });

  tearDown(() async {
    await noise.dispose();
    await settings?.dispose();
    await mic.close();
    await tap.close();
    await bus.dispose();
  });

  test('reports a 5 second window as whole dBFS', () async {
    await build();
    expect(tap.hasListener, true);
    // Listening, but nothing measured yet.
    expect((await level())['dbfs'], null);
    // 328 / 32768 is -40 dBFS.
    await feed(328);
    final reading = await level();
    expect(reading['available'], true);
    expect(reading['dbfs'], -40);
    expect(reading['held'], false);
    expect(reading['updated'], isA<String>());
    expect(events.last.dbfs, -40);
    expect(events.last.held, false);
  });

  test('moves smaller than 2 dB are not news', () async {
    await build();
    await feed(328);
    final count = events.length;
    // About -39 dBFS.
    await feed(368);
    expect((await level())['dbfs'], -39);
    expect(events, hasLength(count));
    // About -30 dBFS.
    await feed(1036);
    expect(events, hasLength(count + 1));
    expect(events.last.dbfs, -30);
  });

  test('holds the last value through a voice turn', () async {
    await build();
    await feed(328);
    bus.publish(const WakeWordStateChanged(active: false, listening: false));
    await pumpEventQueue();
    expect(events.last.held, true);
    expect(events.last.dbfs, -40);
    // Speech during the turn is never measured.
    await feed(10000);
    expect((await level())['dbfs'], -40);
    bus.publish(const WakeWordStateChanged(active: true, listening: true));
    await pumpEventQueue();
    await feed(1036);
    expect(await level(), containsPair('held', false));
    expect((await level())['dbfs'], -30);
  });

  test('holds through announcements, timers and media', () async {
    await build();
    await feed(328);
    bus.publish(
      const VoiceInteractionChanged(active: true, reason: 'announcement'),
    );
    await pumpEventQueue();
    await feed(10000);
    expect((await level())['held'], true);
    expect((await level())['dbfs'], -40);
    bus.publish(
      const VoiceInteractionChanged(active: false, reason: 'announcement'),
    );
    await pumpEventQueue();
    // Held until a clean window replaces the value.
    expect((await level())['held'], true);
    await feed(1036);
    expect((await level())['held'], false);
    expect((await level())['dbfs'], -30);
  });

  test('throws away a window the kiosk played sound into', () async {
    await build();
    await feed(328);
    played = true;
    await feed(10000);
    expect((await level())['dbfs'], -40);
    expect((await level())['held'], true);
    expect(events.last.held, true);
    played = false;
    await feed(328);
    expect((await level())['held'], false);
  });

  test('announces every clean window before rounding (issue #1450)', () async {
    await build();
    final windows = <double>[];
    bus.on<NoiseWindowMeasured>().listen((e) => windows.add(e.dbfs));
    await feed(328);
    // About -39 dBFS: under the sensor's 2 dB step, still a window.
    await feed(368);
    expect(windows, hasLength(2));
    expect(windows[0], closeTo(-39.99, 0.01));
    expect(windows[1], closeTo(-38.99, 0.01));
    // A window the kiosk played into is not one.
    played = true;
    await feed(10000);
    expect(windows, hasLength(2));
  });

  test(
    'holds while a player without an echo tap plays (issue #1450)',
    () async {
      await build();
      await feed(328);
      bus.publish(const UntappedPlaybackChanged(source: 'dlna', playing: true));
      await pumpEventQueue();
      expect(events.last.held, true);
      // The music is never measured as the room.
      await feed(10000);
      expect((await level())['dbfs'], -40);
      bus.publish(
        const UntappedPlaybackChanged(source: 'dlna', playing: false),
      );
      await pumpEventQueue();
      // The first window after it still carries its echo.
      await feed(10000);
      expect((await level())['held'], true);
      expect((await level())['dbfs'], -40);
      await feed(1036);
      expect((await level())['held'], false);
      expect((await level())['dbfs'], -30);
    },
  );

  group('adaptive volume (issue #1450)', () {
    test('holds the microphone open with wake word detection off', () async {
      wake = {'active': true, 'listening': false};
      await build(adaptive: true);
      expect(micOpen, true);
      expect(micAsked, 1);
      // Open, nothing measured yet.
      expect((await level())['available'], true);
      expect((await level())['dbfs'], null);
      await feed(328);
      expect((await level())['dbfs'], -40);
      expect((await level())['held'], false);
    });

    test('off, nothing opens the microphone', () async {
      wake = {'active': true, 'listening': false};
      await build(adaptive: false);
      expect(micOpen, false);
      expect(micAsked, 0);
      expect((await level())['available'], false);
    });

    test('the hold comes and goes with the switch', () async {
      wake = {'active': true, 'listening': false};
      await build(adaptive: false);
      await settings!.set(defs.adaptiveVolume, true);
      await pumpEventQueue();
      expect(micOpen, true);
      await feed(328);
      expect((await level())['dbfs'], -40);
      await settings!.set(defs.adaptiveVolume, false);
      await pumpEventQueue();
      expect(micOpen, false);
      expect((await level())['available'], false);
      expect((await level())['dbfs'], null);
    });

    test(
      'with wake word detection listening the hold changes nothing',
      () async {
        await build(adaptive: true);
        expect(micOpen, true);
        await feed(328);
        expect((await level())['dbfs'], -40);
        // A voice turn still holds the level.
        bus.publish(
          const WakeWordStateChanged(active: false, listening: false),
        );
        await pumpEventQueue();
        await feed(10000);
        expect((await level())['held'], true);
        expect((await level())['dbfs'], -40);
      },
    );

    test('a muted satellite keeps the microphone closed', () async {
      wake = {'active': true, 'listening': false, 'muted': true};
      await build(adaptive: true);
      expect(micOpen, false);
      expect(micAsked, 0);
      bus.publish(const WakeWordStateChanged(active: true, listening: false));
      await pumpEventQueue();
      expect(micOpen, true);
      bus.publish(
        const WakeWordStateChanged(active: true, listening: false, muted: true),
      );
      await pumpEventQueue();
      expect(micOpen, false);
    });

    test('without the permission nothing opens, and it asks once', () async {
      wake = {'active': true, 'listening': false};
      micGrant = PermissionOutcome.declined;
      await build(adaptive: true);
      expect(micOpen, false);
      expect(micAsked, 1);
      // Not again for the same switch.
      bus.publish(const WakeWordStateChanged(active: true, listening: false));
      await pumpEventQueue();
      expect(micAsked, 1);
      // Turned off and on, it asks again.
      micGrant = PermissionOutcome.granted;
      await settings!.set(defs.adaptiveVolume, false);
      await settings!.set(defs.adaptiveVolume, true);
      await pumpEventQueue();
      expect(micAsked, 2);
      expect(micOpen, true);
    });

    test('a capture that fails is given up and tried again later', () async {
      wake = {'active': true, 'listening': false};
      await build(adaptive: true);
      mic.addError(StateError('audio server died'));
      await pumpEventQueue();
      expect(micOpen, false);
      expect((await level())['available'], false);
    });
  });

  test('reports nothing before wake word detection listens', () async {
    wake = {'active': true, 'listening': false};
    await build();
    // The tap is passive: it never opens the microphone by itself.
    expect(tap.hasListener, true);
    expect(await level(), {
      'available': false,
      'dbfs': null,
      'held': false,
      'updated': null,
    });
    await feed(328);
    expect((await level())['dbfs'], null);
  });

  test('reports nothing once wake word detection stops', () async {
    await build();
    await feed(328);
    bus.publish(const WakeWordStateChanged(active: true, listening: false));
    await pumpEventQueue();
    expect(events.last.available, false);
    expect(events.last.dbfs, null);
    expect((await level())['available'], false);
  });
}
