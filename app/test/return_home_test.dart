import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Return to the dashboard (issue #83): mutual exclusion with view
/// rotation, and the behind-the-cover return at screensaver start. The
/// idle timer itself shares the same _returnHome path exercised here. A
/// stub evalJs command stands in for the browser; navigation asserts on
/// the pushState code it receives.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late List<String> evalCalls;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.test:8123',
      'ks.ha.token': 'token',
      'ks.browser.start_url': 'http://ha.test:8123/lovelace/home',
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
        return const CommandResult.ok('navigated');
      },
    ));
    final ha = HomeAssistantManager(bus, commands, log, settings);
    await ha.init();
  }

  test('enabling rotation forces the return switch off', () async {
    await build({'ks.ha.return_home_enabled': true});
    await settings.set(defs.haRotationEnabled, true);
    await pumpEventQueue();
    expect(settings.get(defs.haReturnHomeEnabled), isFalse);
  });

  test('screensaver start navigates home behind the cover', () async {
    await build({'ks.ha.return_home_enabled': true});
    bus.publish(const ScreensaverStateChanged(active: true));
    await pumpEventQueue();
    expect(evalCalls, hasLength(1));
    expect(evalCalls.single, contains('lovelace/home'));
    expect(evalCalls.single, contains('pushState'));
  });

  test('rotation on means no return, even at screensaver start', () async {
    await build({
      'ks.ha.return_home_enabled': true,
      'ks.ha.rotation_enabled': true,
    });
    // Both flags stored true (a state the UI cannot produce): the runtime
    // gate alone must block the return.
    bus.publish(const ScreensaverStateChanged(active: true));
    await pumpEventQueue();
    expect(evalCalls, isEmpty);
  });

  test('the feature off means no navigation', () async {
    await build({});
    bus.publish(const ScreensaverStateChanged(active: true));
    await pumpEventQueue();
    expect(evalCalls, isEmpty);
  });

  test('a bare-origin start URL has no view to return to', () async {
    await build({
      'ks.ha.return_home_enabled': true,
      'ks.browser.start_url': 'http://ha.test:8123',
    });
    bus.publish(const ScreensaverStateChanged(active: true));
    await pumpEventQueue();
    expect(evalCalls, isEmpty);
  });
}
