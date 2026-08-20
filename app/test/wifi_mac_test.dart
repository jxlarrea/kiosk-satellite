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
  });
}
