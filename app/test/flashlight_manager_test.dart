import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/flashlight/flashlight_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('kiosk_satellite/flashlight');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<Object?> sets;
  late SettingsManager settings;
  late CommandRegistry commands;
  late EventBus bus;

  Future<FlashlightManager> start({
    required bool present,
    bool stored = false,
  }) async {
    SharedPreferences.setMockInitialValues({'ks.camera.flashlight': stored});
    defs.deviceHiddenKeys.remove(defs.cameraFlashlight.key);
    sets = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'describe') return {'present': present};
      if (call.method == 'set') sets.add((call.arguments as Map)['on']);
      return null;
    });
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    final manager = FlashlightManager(bus, commands, log, settings);
    await manager.init();
    return manager;
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    defs.deviceHiddenKeys.remove(defs.cameraFlashlight.key);
  });

  test('a device without a flash hides the group', () async {
    await start(present: false);
    expect(defs.deviceHiddenKeys, contains(defs.cameraFlashlight.key));
    final support = await commands.execute('getFlashlightSupport', const {});
    expect(support.data, {'supported': false});
    await settings.set(defs.cameraFlashlight, true);
    await pumpEventQueue();
    expect(sets, isEmpty);
  });

  test('the setting drives the light', () async {
    await start(present: true);
    expect(defs.deviceHiddenKeys, isNot(contains(defs.cameraFlashlight.key)));
    expect(sets, isEmpty, reason: 'off at boot leaves the light alone');
    await settings.set(defs.cameraFlashlight, true);
    await pumpEventQueue();
    await settings.set(defs.cameraFlashlight, false);
    await pumpEventQueue();
    expect(sets, [true, false]);
  });

  test('a light left on comes back at boot', () async {
    await start(present: true, stored: true);
    expect(sets, [true]);
  });

  test('a switch made outside the app lands in the setting', () async {
    await start(present: true);
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('changed', {'on': true}),
      ),
      (_) {},
    );
    await pumpEventQueue();
    expect(settings.get(defs.cameraFlashlight), true);
  });

  test('Fleet Management never syncs it', () {
    expect(defs.cameraFlashlight.perDevice, true);
  });
}
