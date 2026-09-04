import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/person/person_sensor_manager.dart';
import 'package:kiosk_satellite/managers/proximity/proximity_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The schedule's per-entry proximity and person overrides (issue #437),
/// the motion override's shape: the screensaver announces the active
/// entry's policy, the proximity and person sensor managers gate their
/// sensors off it over the switches, and the screensaver's own dismiss
/// path reads the same override. Registry commands the screensaver calls
/// (setBrightness, keepScreenAwake, ...) are absent here and fail soft.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/proximity_sensor'),
          (call) async => switch (call.method) {
            'support' => {'supported': true, 'name': 'STK3310 Proximity'},
            _ => null,
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('kiosk_satellite/proximity_sensor_stream'),
          MockStreamHandler.inline(
            onListen: (arguments, events) {},
            onCancel: (arguments) {},
          ),
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/background'),
          (call) async => switch (call.method) {
            'personSensorSupport' => {'supported': true},
            'readLogsState' => {'granted': true, 'effective': true},
            _ => null,
          },
        );
  });

  late EventBus bus;
  late CommandRegistry commands;
  late ScreensaverManager saver;
  late ProximityManager proximity;
  late PersonSensorManager person;
  late StreamController<String> lines;

  Future<void> build(Map<String, Object> initial) async {
    defs.deviceHiddenKeys.clear();
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();
    proximity = ProximityManager(bus, commands, log, settings);
    addTearDown(proximity.dispose);
    await proximity.init();
    lines = StreamController<String>.broadcast();
    person = PersonSensorManager(
      bus,
      commands,
      log,
      settings,
      lineSource: () => lines.stream,
    );
    await person.init();
    // The tail attaches after an async grant check.
    await pumpEventQueue();
  }

  test('a proximity:false entry gates the sensor off over the switch and '
      'clears on stop', () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"black","proximity":false}]',
      'ks.screensaver.dismiss_on_proximity': true,
    });
    expect(proximity.enabled, isTrue);
    await saver.start();
    await pumpEventQueue();
    expect(proximity.enabled, isFalse);
    final enabled = await commands.execute('getProximityEnabled', const {});
    expect(enabled.data, isFalse);

    // The screensaver's own dismiss path reads the override too: an
    // approach under this entry leaves the screensaver up.
    bus.publish(const ProximityDetected());
    await pumpEventQueue();
    expect(saver.isActive, isTrue);

    await saver.stop();
    await pumpEventQueue();
    expect(proximity.enabled, isTrue);
  });

  test('a proximity:true entry enables the sensor over a switched-off '
      'setting and dismisses on an approach', () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"clock","proximity":true}]',
      'ks.screensaver.dismiss_on_proximity': false,
    });
    await saver.start();
    await pumpEventQueue();
    expect(proximity.enabled, isTrue);
    bus.publish(const ProximityDetected());
    await pumpEventQueue();
    expect(saver.isActive, isFalse);
  });

  test('a person:false entry detaches the tail over the switch and clears '
      'on stop', () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"black","person":false}]',
      'ks.screensaver.dismiss_on_person': true,
    });
    expect(person.wanted, isTrue);
    expect(person.running, isTrue);
    await saver.start();
    await pumpEventQueue();
    expect(person.wanted, isFalse);
    expect(person.running, isFalse);

    bus.publish(const PersonDetected());
    await pumpEventQueue();
    expect(saver.isActive, isTrue);

    await saver.stop();
    await pumpEventQueue();
    expect(person.wanted, isTrue);
    expect(person.running, isTrue);
  });

  test('a person:true entry attaches the tail over a switched-off setting '
      'and dismisses on someone arriving', () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"clock","person":true}]',
      'ks.screensaver.dismiss_on_person': false,
    });
    expect(person.running, isFalse);
    await saver.start();
    await pumpEventQueue();
    expect(person.wanted, isTrue);
    expect(person.running, isTrue);
    bus.publish(const PersonDetected());
    await pumpEventQueue();
    expect(saver.isActive, isFalse);
  });

  test('entries without the fields follow the switches', () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule': '[{"at":"00:00","mode":"black"}]',
      'ks.screensaver.dismiss_on_proximity': false,
      'ks.screensaver.dismiss_on_person': false,
    });
    await saver.start();
    await pumpEventQueue();
    expect(proximity.enabled, isFalse);
    expect(person.wanted, isFalse);
    bus.publish(const ProximityDetected());
    bus.publish(const PersonDetected());
    await pumpEventQueue();
    expect(saver.isActive, isTrue);
  });
}
