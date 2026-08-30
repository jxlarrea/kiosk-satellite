import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/proximity/proximity_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proximity Detection: Motion Detection's two legs on the device's
/// proximity sensor. The native bridge answers `support` (has one, its
/// name, or why not) and streams near/far transitions with the resting
/// state flagged; the manager watches the sensor only while a leg wants
/// it, keeps the switch off where there is no sensor, and the screensaver
/// wakes or holds off on the event.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const noSensor = {
    'supported': false,
    'hint': 'Not available on this device: it has no proximity sensor.',
  };
  const irSensor = {
    'supported': true,
    'name': 'STK3310 Proximity',
    'vendor': 'Sensortek',
  };

  var listens = 0;
  var cancels = 0;
  Map<String, Object?>? nativeAnswer;
  MockStreamHandlerEventSink? sink;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/proximity_sensor'),
          (call) async => switch (call.method) {
            'support' => nativeAnswer,
            _ => null,
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('kiosk_satellite/proximity_sensor_stream'),
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              listens++;
              sink = events;
            },
            onCancel: (arguments) {
              cancels++;
              sink = null;
            },
          ),
        );
  });

  late EventBus bus;
  late CommandRegistry commands;
  late Logger log;
  late SettingsManager settings;
  late ProximityManager proximity;

  Future<void> build(Map<String, Object> initial) async {
    listens = 0;
    cancels = 0;
    sink = null;
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    proximity = ProximityManager(
      bus,
      commands,
      log,
      settings,
      holdInterval: const Duration(milliseconds: 40),
    );
    addTearDown(proximity.dispose);
    await proximity.init();
  }

  Future<void> pump() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  void reading({required bool near, bool initial = false}) {
    sink!.success({'near': near, 'initial': initial});
  }

  test('no sensor: the switch is kept off and both surfaces get the '
      'reason', () async {
    nativeAnswer = noSensor;
    await build({'ks.screensaver.dismiss_on_proximity': true});
    await pump();
    expect(settings.get(defs.screensaverDismissOnProximity), isFalse);
    expect(proximity.proximityKnownUnsupported, isTrue);
    expect(proximity.proximityHint, noSensor['hint']);
    expect(proximity.sensorName, isNull);
    expect(
      log.recent
          .where((e) => e.level == LogLevel.warn && e.tag == 'proximity')
          .map((e) => e.message),
      contains(
        'Dismiss on proximity kept off: not available on this device: it '
        'has no proximity sensor.',
      ),
    );
    final res = await commands.execute('getProximitySupport', const {});
    expect(res.ok, isTrue);
    expect(res.data, noSensor);
    final on = await commands.execute('getProximityEnabled', const {});
    expect(on.data, isFalse);

    // A later write (the remote API, an import) is undone the same way,
    // and the screensaver never has the sensor watched.
    await settings.set(defs.screensaverDismissOnProximity, true);
    await pump();
    expect(settings.get(defs.screensaverDismissOnProximity), isFalse);
    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(listens, 0);
  });

  test('a sensor: its name is served, and the switch is left alone', () async {
    nativeAnswer = irSensor;
    await build({'ks.screensaver.dismiss_on_proximity': true});
    await pump();
    expect(settings.get(defs.screensaverDismissOnProximity), isTrue);
    expect(proximity.proximityKnownUnsupported, isFalse);
    expect(proximity.sensorName, 'STK3310 Proximity');
    expect(proximity.sensorVendor, 'Sensortek');
    final res = await commands.execute('getProximitySupport', const {});
    expect(res.data, irSensor);
    final on = await commands.execute('getProximityEnabled', const {});
    expect(on.data, isTrue);
  });

  test('no native answer counts as supported, never switching the feature '
      'off on a guess', () async {
    nativeAnswer = null;
    await build({'ks.screensaver.dismiss_on_proximity': true});
    await pump();
    expect(settings.get(defs.screensaverDismissOnProximity), isTrue);
    expect(proximity.proximityKnownUnsupported, isFalse);
    expect(proximity.enabled, isTrue);
  });

  test('dismiss leg: the sensor is watched only during the screensaver, '
      'the resting state is ignored and a near publishes', () async {
    nativeAnswer = irSensor;
    await build({'ks.screensaver.dismiss_on_proximity': true});
    await pump();
    expect(listens, 0, reason: 'nothing to dismiss yet');
    final events = <ProximityDetected>[];
    bus.on<ProximityDetected>().listen(events.add);

    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(listens, 1);

    // Something resting on the sensor as it registers is not an approach.
    reading(near: true, initial: true);
    await pump();
    expect(events, isEmpty);
    reading(near: false);
    await pump();
    expect(events, isEmpty);
    reading(near: true);
    await pump();
    expect(events.length, 1);

    // A held near repeats, so the postpone leg can keep holding.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(events.length, greaterThan(1));
    final held = events.length;
    reading(near: false);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(events.length, held, reason: 'far stops the repeat');

    bus.publish(const ScreensaverStateChanged(active: false));
    await pump();
    expect(cancels, 1);
  });

  test('postpone leg: watched between screensavers with the screen on, '
      'and only as an extension of Dismiss on proximity', () async {
    nativeAnswer = irSensor;
    await build({
      'ks.screensaver.dismiss_on_proximity': true,
      'ks.screensaver.postpone_on_proximity': true,
      'ks.screensaver.enabled': true,
    });
    await pump();
    expect(listens, 1, reason: 'the postpone leg starts at init');

    bus.publish(const ScreenStateChanged(on: false));
    await pump();
    expect(cancels, 1, reason: 'a dark panel has nothing to postpone');
    bus.publish(const ScreenStateChanged(on: true));
    await pump();
    expect(listens, 2);

    // The postpone switch never acts on its own.
    await settings.set(defs.screensaverDismissOnProximity, false);
    await pump();
    expect(cancels, 2);
    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(listens, 2, reason: 'the dismiss leg is off too');
  });

  group('the screensaver', () {
    late ScreensaverManager saver;

    Future<void> buildSaver(Map<String, Object> initial) async {
      nativeAnswer = irSensor;
      await build(initial);
      saver = ScreensaverManager(bus, commands, log, settings);
      await saver.init();
    }

    test('wakes on proximity under Dismiss on proximity', () async {
      await buildSaver({
        'ks.screensaver.enabled': true,
        'ks.screensaver.dismiss_on_proximity': true,
      });
      await saver.start();
      await pumpEventQueue();
      expect(saver.isActive, isTrue);
      bus.publish(const ProximityDetected());
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
    });

    test('something still close when the screensaver starts does not '
        'dismiss it (issue #369)', () async {
      await buildSaver({
        'ks.screensaver.enabled': true,
        'ks.screensaver.dismiss_on_proximity': true,
      });
      await saver.start();
      await pumpEventQueue();
      bus.publish(const ProximityDetected(held: true));
      await pumpEventQueue();
      expect(saver.isActive, isTrue);
      bus.publish(const ProximityDetected());
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
    });

    test('leaves the screensaver alone with the switch off', () async {
      await buildSaver({
        'ks.screensaver.enabled': true,
        'ks.screensaver.dismiss_on_proximity': false,
      });
      await saver.start();
      await pumpEventQueue();
      bus.publish(const ProximityDetected());
      await pumpEventQueue();
      expect(saver.isActive, isTrue);
    });

    test('leaves a screensaver running under Lockdown Mode alone', () async {
      await buildSaver({
        'ks.screensaver.enabled': true,
        'ks.screensaver.dismiss_on_proximity': true,
        'ks.lockdown.enabled': true,
        'ks.lockdown.allow_screensaver': true,
      });
      await saver.start();
      await pumpEventQueue();
      expect(saver.isActive, isTrue);
      bus.publish(const ProximityDetected());
      await pumpEventQueue();
      expect(saver.isActive, isTrue);
    });
  });
}
