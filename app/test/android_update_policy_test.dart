import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/update/android_update_policy_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Android's own system updates (issue #1292): the device owner hands the
/// restart prompt kiosk mode hides to a system update policy. The rows
/// only show where the policy can be set. Every change of the three
/// settings reaches Android.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  const background = MethodChannel('kiosk_satellite/background');

  late EventBus bus;
  late SettingsManager settings;
  late AndroidUpdatePolicyManager manager;
  late List<MethodCall> policyCalls;
  late bool owner;

  final keys = {
    defs.androidUpdatePolicy.key,
    defs.androidUpdateWindowStart.key,
    defs.androidUpdateWindowEnd.key,
  };

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  Future<void> build({
    required bool isOwner,
    String? rom,
    Map<String, Object> initial = const {},
  }) async {
    defs.deviceHiddenKeys.clear();
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    owner = isOwner;
    policyCalls = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(background, (
      call,
    ) async {
      switch (call.method) {
        case 'isDeviceOwner':
          return owner;
        case 'setSystemUpdatePolicy':
          policyCalls.add(call);
          return {'ok': true, 'applied': call.arguments['policy']};
      }
      return null;
    });
    manager = AndroidUpdatePolicyManager(
      bus,
      commands,
      log,
      settings,
      romUpdater: () async => rom,
    )..active = true;
    await manager.init();
  }

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(background, null);
    defs.deviceHiddenKeys.clear();
  });

  test('a device owner shows the rows and applies the stored policy', () async {
    await build(isOwner: true);
    expect(manager.supported, isTrue);
    expect(defs.deviceHiddenKeys.intersection(keys), isEmpty);
    expect(policyCalls, hasLength(1));
    expect(policyCalls.single.arguments, {
      'policy': 'ask',
      'start': 180,
      'end': 300,
    });
  });

  test('without the device owner the rows hide and nothing is set', () async {
    await build(isOwner: false);
    expect(manager.supported, isFalse);
    expect(defs.deviceHiddenKeys, containsAll(keys));
    expect(policyCalls, isEmpty);
  });

  test('the Echo images hide the rows even as device owner', () async {
    for (final rom in ['echo', 'biscuit']) {
      await build(isOwner: true, rom: rom);
      expect(manager.supported, isFalse, reason: rom);
      expect(defs.deviceHiddenKeys, containsAll(keys), reason: rom);
      expect(policyCalls, isEmpty, reason: rom);
    }
  });

  test('a change of policy or window reaches Android', () async {
    await build(isOwner: true);
    policyCalls.clear();
    await settings.set(defs.androidUpdatePolicy, 'windowed');
    await settle();
    await settings.set(defs.androidUpdateWindowStart, '23:30');
    await settle();
    await settings.set(defs.androidUpdateWindowEnd, '01:15');
    await settle();
    expect(policyCalls.map((c) => c.arguments).toList(), [
      {'policy': 'windowed', 'start': 180, 'end': 300},
      {'policy': 'windowed', 'start': 1410, 'end': 300},
      {'policy': 'windowed', 'start': 1410, 'end': 75},
    ]);
  });

  test('a stored policy applies at boot, as after an import', () async {
    await build(
      isOwner: true,
      initial: {'ks.${defs.androidUpdatePolicy.key}': 'automatic'},
    );
    expect(policyCalls.single.arguments['policy'], 'automatic');
  });

  test('becoming the device owner while running shows the rows', () async {
    await build(isOwner: false);
    expect(defs.deviceHiddenKeys, containsAll(keys));
    owner = true;
    bus.publish(const DeviceOwnerChanged());
    await settle();
    expect(defs.deviceHiddenKeys.intersection(keys), isEmpty);
    expect(policyCalls, hasLength(1));
  });

  test('times read as minutes after midnight, with a fallback', () {
    expect(AndroidUpdatePolicyManager.minutesOf('03:00', 0), 180);
    expect(AndroidUpdatePolicyManager.minutesOf('7:05', 0), 425);
    expect(AndroidUpdatePolicyManager.minutesOf('23:59', 0), 1439);
    expect(AndroidUpdatePolicyManager.minutesOf('24:00', 99), 99);
    expect(AndroidUpdatePolicyManager.minutesOf('noon', 99), 99);
  });
}
