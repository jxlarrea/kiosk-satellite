import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsManager settings;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    final bus = EventBus();
    final log = Logger();
    settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
  }

  test('unstored settings return their declared default', () async {
    await build({});
    expect(settings.get(defs.webMicrophone), isTrue); // default true
    expect(settings.get(defs.webCamera), isFalse); // default false
    expect(settings.get(defs.screensaverTimeoutSeconds), 300);
  });

  test('describe() reports defaults for unstored settings (not null)',
      () async {
    await build({});
    final described = settings.describe();
    final mic = described.firstWhere((s) => s['key'] == 'web.microphone');
    // Regression: nullable type inference in describe() used to make this
    // null, so the UI rendered every untouched toggle as off.
    expect(mic['value'], isTrue);
    final camera = described.firstWhere((s) => s['key'] == 'web.camera');
    expect(camera['value'], isFalse);
  });

  test('set persists and is read back', () async {
    await build({});
    await settings.set(defs.webCamera, true);
    expect(settings.get(defs.webCamera), isTrue);
    // Simulate a fresh app run against the same store.
    final bus = EventBus();
    final log = Logger();
    final reopened = SettingsManager(bus, CommandRegistry(log), log);
    await reopened.init();
    expect(reopened.get(defs.webCamera), isTrue);
  });

  test('secrets are masked in describe but report set/unset', () async {
    await build({'ks.remote.password': 'hunter2'});
    final described = settings.describe();
    final pw = described.firstWhere((s) => s['key'] == 'remote.password');
    expect(pw['value'], '__set__');
    expect(pw['default'], isNull);
  });
}
