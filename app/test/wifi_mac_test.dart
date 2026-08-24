import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/device/wifi_mac.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsManager> settingsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final bus = EventBus();
    final log = Logger();
    final settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
    return settings;
  }

  test('setting off means no identity, stored or not', () async {
    final settings = await settingsWith({
      'ks.internal.esphome_adopted_mac': '80:30:49:CD:D6:5F',
    });
    expect(await adoptedWifiMac(settings), isNull);
  });

  test('a stored adoption is returned without asking the platform', () async {
    final settings = await settingsWith({
      'ks.esphome.real_mac': true,
      'ks.internal.esphome_adopted_mac': '80:30:49:CD:D6:5F',
    });
    // No device_details channel exists in tests; a platform read would
    // come back null and fail this expectation.
    expect(await adoptedWifiMac(settings), '80:30:49:CD:D6:5F');
  });

  test('an unreadable address adopts nothing and stores nothing', () async {
    final settings = await settingsWith({'ks.esphome.real_mac': true});
    expect(await adoptedWifiMac(settings), isNull);
    expect(settings.internal('esphome_adopted_mac'), isEmpty);
    expect((await wifiMacIdentity(settings)).source, WifiMacSource.none);
  });

  // The hand-typed address (issue #300): the fallback once the platform
  // has come back empty, never adopted, never ahead of a hardware read.
  test('a typed address stands in when the platform reveals nothing',
      () async {
    final settings = await settingsWith({
      'ks.esphome.real_mac': true,
      'ks.esphome.mac_override': '80:30:49:CD:D6:5F',
    });
    final identity = await wifiMacIdentity(settings);
    expect(identity.mac, '80:30:49:CD:D6:5F');
    expect(identity.source, WifiMacSource.manual);
    expect(await adoptedWifiMac(settings), '80:30:49:CD:D6:5F');
    // Read live, not adopted: editing the field is how a typo gets fixed.
    expect(settings.internal('esphome_adopted_mac'), isEmpty);
  });

  test('a typed address is ignored while the setting is off', () async {
    final settings = await settingsWith({
      'ks.esphome.mac_override': '80:30:49:CD:D6:5F',
    });
    expect(await adoptedWifiMac(settings), isNull);
  });

  test('a stored hardware adoption beats a typed address', () async {
    final settings = await settingsWith({
      'ks.esphome.real_mac': true,
      'ks.internal.esphome_adopted_mac': '1C:4D:66:4C:7E:A1',
      'ks.esphome.mac_override': '80:30:49:CD:D6:5F',
    });
    final identity = await wifiMacIdentity(settings);
    expect(identity.mac, '1C:4D:66:4C:7E:A1');
    expect(identity.source, WifiMacSource.hardware);
  });

  test('a typed address that is not a usable one is ignored', () async {
    // Written past the validator (an old export, a hand-edited prefs
    // file): the identity must not trust it.
    final settings = await settingsWith({
      'ks.esphome.real_mac': true,
      'ks.esphome.mac_override': '01:00:5E:00:00:01',
    });
    expect(await adoptedWifiMac(settings), isNull);
    expect((await wifiMacIdentity(settings)).source, WifiMacSource.none);
  });
}
