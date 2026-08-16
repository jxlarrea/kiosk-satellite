import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/home_assistant/kiosk_mode.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HA kiosk mode after the kiosk-mode resource was dropped.
///
/// The setting used to be a strategy choice (off/auto/plugin/css) because the
/// hiding could be handed to that resource. The app does the hiding itself
/// now, so it is a plain switch — and a device upgrading into this must not
/// come back with kiosk mode silently off because its stored value no longer
/// has the right type.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsManager> build(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final bus = EventBus();
    final log = Logger();
    final settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
    return settings;
  }

  test('a strategy that was hiding something migrates to on', () async {
    for (final mode in ['auto', 'plugin', 'css']) {
      final settings = await build({'ks.ha.kiosk_mode': mode});
      expect(settings.get(defs.haKioskMode), isTrue, reason: mode);
    }
  });

  test('the off strategy migrates to off', () async {
    final settings = await build({'ks.ha.kiosk_mode': 'off'});
    expect(settings.get(defs.haKioskMode), isFalse);
  });

  test('a device that never set it keeps the default', () async {
    final settings = await build({});
    expect(settings.get(defs.haKioskMode), isFalse);
  });

  test('an already-migrated device is left alone', () async {
    final settings = await build({'ks.ha.kiosk_mode': true});
    expect(settings.get(defs.haKioskMode), isTrue);
  });

  test('the strategy the drawer used to restore is dropped', () async {
    await build({'ks.ha.kiosk_mode': 'css', 'ks.ha.kiosk_mode_last': 'css'});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.get('ks.ha.kiosk_mode_last'), isNull);
  });

  test('the toggle survives a round trip through the switch', () async {
    final settings = await build({'ks.ha.kiosk_mode': 'plugin'});
    await settings.set(defs.haKioskMode, false);
    expect(settings.get(defs.haKioskMode), isFalse);
    await settings.set(defs.haKioskMode, true);
    expect(settings.get(defs.haKioskMode), isTrue);
  });

  group('the page script', () {
    test('carries the flags it is called with', () {
      expect(
        kioskModeApplyJs(apply: true, hideHeader: true, hideSidebar: false),
        contains('__ksKioskApply(true, true, false)'),
      );
    });

    test('does nothing on a page that never got the script', () {
      expect(kioskModeApplyJs(apply: true), startsWith('if (window.'));
    });

    test('hides by tag name, not by tree position', () {
      // The frontend's internals move between releases; tag names are the
      // stable part, and losing this is how kiosk mode silently stops
      // working on an HA upgrade.
      for (final tag in ['home-assistant-main', 'ha-drawer', 'hui-root']) {
        expect(kioskModeScript, contains("'$tag'"));
      }
    });

    test('covers both drawer and header generations', () {
      for (final selector in [
        '.mdc-drawer',
        '.sidebar-shell',
        'app-header',
        'ch-header',
      ]) {
        expect(kioskModeScript, contains(selector));
      }
    });

    test('keeps a hidden sidebar hidden', () {
      // The menu button and the edge swipe both open the drawer, so the
      // toggle event is swallowed and a drawer opened anyway is closed.
      expect(kioskModeScript, contains('hass-toggle-menu'));
      expect(kioskModeScript, contains("removeAttribute('open')"));
    });

    test('catches shadow roots as they are created', () {
      expect(kioskModeScript, contains('attachShadow'));
    });
  });
}
