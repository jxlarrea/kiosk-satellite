import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/kiosk/kiosk_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lockdown Mode (discussion #143): one remote-only toggle that makes the
/// screen untouchable without touching the persisted kiosk settings. The
/// shield itself is UI; what is testable headless is the derivations: the
/// exit gesture tap count, the screensaver's refusal to run under
/// lockdown, and the setting's registration.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('exit gesture derivation', () {
    test('kiosk gesture keeps its own count', () {
      expect(KioskManager.exitGestureTaps('taps5', lockdown: false), 5);
      expect(KioskManager.exitGestureTaps('taps7', lockdown: false), 7);
      expect(KioskManager.exitGestureTaps('taps5hold', lockdown: false), 5);
      expect(KioskManager.exitGestureTaps('taps7hold', lockdown: false), 7);
    });

    test('lockdown is the kiosk gesture plus two taps', () {
      expect(KioskManager.exitGestureTaps('taps5', lockdown: true), 7);
      expect(KioskManager.exitGestureTaps('taps7', lockdown: true), 9);
      expect(KioskManager.exitGestureTaps('taps5hold', lockdown: true), 7);
      expect(KioskManager.exitGestureTaps('taps7hold', lockdown: true), 9);
    });

    test('a disabled kiosk gesture stays disabled under lockdown', () {
      expect(KioskManager.exitGestureTaps('none', lockdown: false), 0);
      expect(KioskManager.exitGestureTaps('none', lockdown: true), 0);
    });
  });

  group('setting registration', () {
    test('lockdown.enabled is declared, off by default, own category', () {
      expect(defs.allSettings, contains(defs.lockdownEnabled));
      expect(defs.lockdownEnabled.defaultValue, false);
      expect(defs.lockdownEnabled.category, 'Lockdown');
      expect(defs.lockdownEnabled.hidden, false);
    });
  });

  group('screensaver under lockdown', () {
    late EventBus bus;
    late SettingsManager settings;
    late ScreensaverManager saver;

    Future<void> build(Map<String, Object> initial) async {
      SharedPreferences.setMockInitialValues(initial);
      bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      saver = ScreensaverManager(bus, commands, log, settings);
      await saver.init();
    }

    test('start() refuses while lockdown holds', () async {
      await build({'ks.lockdown.enabled': true});
      await saver.start();
      expect(saver.isActive, false);
    });

    test('an active screensaver stops when lockdown flips on, and the '
        'screensaver runs again after it lifts', () async {
      await build({});
      await saver.start();
      expect(saver.isActive, true);
      await settings.set(defs.lockdownEnabled, true);
      await pumpEventQueue();
      expect(saver.isActive, false);
      // Still refused while the mode holds.
      await saver.start();
      expect(saver.isActive, false);
      await settings.set(defs.lockdownEnabled, false);
      await pumpEventQueue();
      await saver.start();
      expect(saver.isActive, true);
    });
  });
}
