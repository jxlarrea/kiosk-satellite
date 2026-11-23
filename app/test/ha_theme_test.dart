import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The dashboard theme mirror (issue #92) and the time schedule around it.
/// Assertions read [HomeAssistantManager.dashboardDark], which the dashboard
/// WebView applies on this device only. A stub evalJs records anything sent
/// to the page: nothing may reach the user's profile through `settheme`
/// (issue #1101). The test binding reports a light platform, so "system"
/// resolves light here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late List<String> evalCalls;
  late HomeAssistantManager ha;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.test:8123',
      'ks.ha.token': 'token',
      ...initial,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    evalCalls = [];
    commands.register(
      Command(
        name: 'evalJs',
        description: 'stub',
        handler: (p) async {
          evalCalls.add('${p['code']}');
          return const CommandResult.ok('');
        },
      ),
    );
    ha = HomeAssistantManager(bus, commands, log, settings);
    await ha.init();
  }

  test('the mirror follows the App theme setting', () async {
    await build({'ks.ha.theme_match_app': true, 'ks.ui.theme': 'dark'});
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await pumpEventQueue();
    expect(ha.dashboardDark.value, isTrue);

    await settings.setFromJson(defs.uiTheme.key, 'light');
    await pumpEventQueue();
    expect(ha.dashboardDark.value, isFalse);
  });

  test('system resolves through the platform brightness', () async {
    await build({'ks.ha.theme_match_app': true, 'ks.ui.theme': 'system'});
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await pumpEventQueue();
    // The test platform reports light.
    expect(ha.dashboardDark.value, isFalse);
  });

  test('with the mirror on, the schedule drives the app theme and the '
      'mirror carries it to the dashboard', () async {
    await build({
      'ks.ha.theme_match_app': true,
      'ks.ha.theme_auto': true,
      // Dark from midnight to 23:59: dark now, whenever now is (bar one
      // minute a day).
      'ks.ha.theme_dark_at': '00:00',
      'ks.ha.theme_light_at': '23:59',
      'ks.ui.theme': 'light',
    });
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await pumpEventQueue();
    expect(settings.get(defs.uiTheme), 'dark');
    expect(ha.dashboardDark.value, isTrue);
  });

  test('without the mirror the legacy behavior stands', () async {
    await build({
      'ks.ha.theme_auto': true,
      'ks.ha.theme_dark_at': '00:00',
      'ks.ha.theme_light_at': '23:59',
      'ks.ha.theme_auto_app': true,
      'ks.ui.theme': 'light',
    });
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await pumpEventQueue();
    expect(ha.dashboardDark.value, isTrue);
    expect(settings.get(defs.uiTheme), 'dark');
  });

  test('a theme pinned from Home Assistant outranks the schedule', () async {
    await build({
      'ks.ha.theme': 'light',
      'ks.ha.theme_auto': true,
      'ks.ha.theme_dark_at': '00:00',
      'ks.ha.theme_light_at': '23:59',
      'ks.ui.theme': 'light',
    });
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await pumpEventQueue();
    expect(ha.dashboardDark.value, isFalse);

    // The select moving applies at once, no minute tick needed.
    await settings.setFromJson(defs.haTheme.key, 'dark');
    await pumpEventQueue();
    expect(ha.dashboardDark.value, isTrue);

    // Auto hands control back to the schedule, which says dark too.
    await settings.setFromJson(defs.haTheme.key, 'auto');
    await pumpEventQueue();
    expect(ha.dashboardDark.value, isTrue);
  });

  test('the pin reaches the app theme through the mirror', () async {
    await build({
      'ks.ha.theme': 'dark',
      'ks.ha.theme_match_app': true,
      'ks.ui.theme': 'light',
    });
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await pumpEventQueue();
    expect(settings.get(defs.uiTheme), 'dark');
    expect(ha.dashboardDark.value, isTrue);

    // Back to Auto: the mirror follows the app theme, which stays dark.
    await settings.setFromJson(defs.haTheme.key, 'auto');
    await settings.setFromJson(defs.uiTheme.key, 'light');
    await pumpEventQueue();
    expect(ha.dashboardDark.value, isFalse);
  });

  test('the pin without the mirror leaves the app theme alone', () async {
    await build({'ks.ha.theme': 'dark', 'ks.ui.theme': 'light'});
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await pumpEventQueue();
    expect(ha.dashboardDark.value, isTrue);
    expect(settings.get(defs.uiTheme), 'light');
  });

  test('everything off leaves the theme to Home Assistant', () async {
    await build({'ks.ui.theme': 'dark'});
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await pumpEventQueue();
    expect(ha.dashboardDark.value, isNull);
    expect(evalCalls, isEmpty);
  });

  test('the theme never reaches the user profile', () async {
    await build({
      'ks.ha.theme': 'dark',
      'ks.ha.theme_match_app': true,
      'ks.ha.theme_auto': true,
    });
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await settings.setFromJson(defs.haTheme.key, 'light');
    await settings.setFromJson(defs.haTheme.key, 'auto');
    await pumpEventQueue();
    expect(evalCalls.where((c) => c.contains('settheme')), isEmpty);
  });

  test('the theme is settled before the first page load', () async {
    await build({'ks.ha.theme': 'dark'});
    await pumpEventQueue();
    expect(ha.dashboardDark.value, isTrue);
  });
}
