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
/// A stub evalJs stands in for the browser; assertions read the settheme
/// payload it receives. The test binding reports a light platform, so
/// "system" resolves light here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late List<String> evalCalls;

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
    commands.register(Command(
      name: 'evalJs',
      description: 'stub',
      handler: (p) async {
        evalCalls.add('${p['code']}');
        return const CommandResult.ok('');
      },
    ));
    final ha = HomeAssistantManager(bus, commands, log, settings);
    await ha.init();
  }

  test('the mirror follows the App theme setting', () async {
    await build({
      'ks.ha.theme_match_app': true,
      'ks.ui.theme': 'dark',
    });
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await pumpEventQueue();
    expect(evalCalls.last, contains('dark: true'));

    await settings.setFromJson(defs.uiTheme.key, 'light');
    await pumpEventQueue();
    expect(evalCalls.last, contains('dark: false'));
  });

  test('system resolves through the platform brightness', () async {
    await build({
      'ks.ha.theme_match_app': true,
      'ks.ui.theme': 'system',
    });
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await pumpEventQueue();
    // The test platform reports light.
    expect(evalCalls.last, contains('dark: false'));
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
    expect(evalCalls.last, contains('dark: true'));
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
    expect(evalCalls.last, contains('dark: true'));
    expect(settings.get(defs.uiTheme), 'dark');
  });

  test('everything off touches nothing', () async {
    await build({'ks.ui.theme': 'dark'});
    bus.publish(const PageChanged(url: 'http://ha.test:8123/lovelace/0'));
    await pumpEventQueue();
    expect(evalCalls, isEmpty);
  });
}
