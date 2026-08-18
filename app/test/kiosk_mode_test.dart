import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/vs_suppress_script.dart';
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

  group('external pages', () {
    // The dashboard's own WebView loads one thing. These views load whatever
    // address they are given, so kiosk mode is fenced twice: the caller only
    // asks for it on this Home Assistant's pages, and the script is then held
    // to that origin for the life of the view.
    test('a Home Assistant page gets the script, held to its origin', () {
      final sources = externalKioskModeSources(
        origin: 'https://ha.example.com',
        apply: true,
        hideHeader: true,
        hideSidebar: true,
      );
      expect(sources, isNotEmpty);
      expect(
        sources.first,
        'window.__ksKioskOrigins = ["https://ha.example.com"];',
      );
      expect(sources, contains(kioskModeScript));
      expect(sources.last, contains('__ksKioskApply(true, true, true)'));
    });

    test('kiosk mode off injects the script inert, not nothing', () {
      // These views are built once and kept, so a script that only appeared
      // while the setting was on would leave the page unable to hear about
      // the setting being turned on later.
      final sources = externalKioskModeSources(
        origin: 'https://ha.example.com',
        apply: false,
        hideHeader: true,
        hideSidebar: true,
      );
      expect(sources, contains(kioskModeScript));
      expect(sources.last, contains('__ksKioskApply(false,'));
    });

    test('a page that navigates on to another site is left alone', () {
      // The origin list is what the script checks before it styles anything,
      // so a tapped link that leaves Home Assistant keeps its own chrome.
      expect(kioskModeScript, contains('__ksKioskOrigins'));
      expect(kioskModeScript, contains('indexOf(location.origin)'));
    });

    test('an origin with a quote in it cannot break out of the script', () {
      final sources = externalKioskModeSources(
        origin: 'https://evil"+alert(1)+"',
        apply: true,
        hideHeader: true,
        hideSidebar: true,
      );
      expect(sources.first, isNot(contains('"+alert(1)+"')));
    });
  });

  group('Voice Satellite on external pages', () {
    test('claims the engine flag before Voice Satellite can boot', () {
      // The engine guards its own bootstrap on this flag, so holding it is
      // what keeps a screensaver or link page from opening a second
      // microphone and registering as the same satellite twice.
      expect(vsSuppressScript, contains('__vsEngine'));
    });

    test('never takes a flag the page already set', () {
      expect(vsSuppressScript, contains('if (!window.__vsEngine)'));
    });
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

    test('declares a zero kiosk header height for panel cards', () {
      // Cards that fill a panel view size themselves with
      // calc(100vh - var(--kiosk-header-height, var(--header-height))), the
      // contract the kiosk-mode resource established. Without the
      // declaration a panel card ends a header short of the screen (#232).
      expect(kioskModeScript, contains('--kiosk-header-height:0px'));
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
