import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plugins with the screensaver.mode capability hold a mode in place of
/// the schedule and the setting. The newest hold wins, each owner clears
/// only its own, and a change while the screensaver shows switches it
/// live. Registry commands the screensaver calls are absent here and fail
/// soft.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late Map<String, String> published;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    published = {'plugin:monitor:hw': 'Hardware (Monitor)'};
    settings.pluginScreensavers = () => published;
    saver = ScreensaverManager(bus, commands, log, settings);
  }

  test('a hold wins over the schedule and the setting, newest first', () async {
    await build({
      'ks.screensaver.mode': 'black',
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule': '[{"at":"00:00","mode":"clock"}]',
    });
    expect(saver.modeState, containsPair('mode', 'clock'));
    expect(saver.modeState, containsPair('saved', 'black'));
    expect(saver.modeState, containsPair('schedule', 'clock'));
    expect(saver.modeState, containsPair('override', null));
    expect(saver.modeState, containsPair('active', false));

    expect(saver.setModeOverride('a:1', 'nope'), isFalse);
    expect(saver.setModeOverride('a:1', 'plugin:other:gone'), isFalse);
    expect(saver.modeOverride.value, isNull);

    expect(saver.setModeOverride('a:1', 'plugin:monitor:hw'), isTrue);
    expect(saver.setModeOverride('b:1', 'weather_mood'), isTrue);
    expect(saver.modeState['mode'], 'weather_mood');
    expect(saver.modeState['override'], 'weather_mood');
    // Clearing the newest falls back to the one before, then to normal.
    saver.clearModeOverride('b:1');
    expect(saver.modeState['mode'], 'plugin:monitor:hw');
    saver.clearModeOverride('nobody');
    expect(saver.modeOverride.value, 'plugin:monitor:hw');
    // Setting again moves an owner to the front.
    saver.setModeOverride('b:1', 'celestial');
    saver.setModeOverride('a:1', 'plugin:monitor:hw');
    expect(saver.modeOverride.value, 'plugin:monitor:hw');
    saver.clearModeOverride('a:1');
    saver.clearModeOverride('b:1');
    expect(saver.modeState['mode'], 'clock');
    // Never saved.
    expect(settings.get(defs.screensaverMode), 'black');
  });

  test('the modes list the stock modes and published plugin ones', () async {
    await build({});
    final modes = saver.modeState['modes'] as List;
    expect(modes.first, {'id': 'dim', 'label': 'Dim'});
    expect(modes, anyElement(equals({'id': 'clock', 'label': 'Clock'})));
    expect(modes.last, {
      'id': 'plugin:monitor:hw',
      'label': 'Hardware (Monitor)',
    });
    // A saved plugin mode that is no longer published is not offered.
    await settings.set(defs.screensaverMode, 'plugin:other:gone');
    expect(
      (saver.modeState['modes'] as List).map((m) => (m as Map)['id']),
      isNot(contains('plugin:other:gone')),
    );
  });

  test('a change while showing switches the screensaver live', () async {
    await build({'ks.screensaver.mode': 'clock'});
    await saver.start();
    await pumpEventQueue();
    expect(saver.activeView.value, 'clock');
    expect(saver.modeState['active'], isTrue);
    saver.setModeOverride('a:1', 'plugin:monitor:hw');
    await pumpEventQueue();
    expect(saver.activeView.value, 'plugin:monitor:hw');
    // The renderer going away keeps the mode: it shows black, as a
    // selected plugin screensaver whose plugin stopped does.
    published = {};
    await pumpEventQueue();
    expect(saver.activeView.value, 'plugin:monitor:hw');
    saver.clearModeOverride('a:1');
    await pumpEventQueue();
    expect(saver.activeView.value, 'clock');
    await saver.stop();
  });

  test('a plugin tint stays on the plugin screensaver it was set on', () async {
    // Issue #1299: a plugin that never clears its tint must not color any
    // other screensaver, not even its own other one.
    await build({'ks.screensaver.mode': 'clock'});
    published = {
      'plugin:monitor:hw': 'Hardware (Monitor)',
      'plugin:monitor:cpu': 'CPU (Monitor)',
    };
    expect(saver.setPluginTint('monitor', 0xFF822222), isFalse);
    await saver.start();
    await pumpEventQueue();
    expect(saver.setPluginTint('monitor', 0xFF822222), isFalse);

    saver.setModeOverride('a:1', 'plugin:monitor:hw');
    await pumpEventQueue();
    expect(saver.setPluginTint('other', 0xFF112233), isFalse);
    expect(saver.setPluginTint('monitor', 0xFF822222), isTrue);
    expect(saver.pluginTint.value, (
      mode: 'plugin:monitor:hw',
      color: 0xFF822222,
    ));
    // Another plugin cannot clear it.
    saver.clearPluginTint('other');
    expect(saver.pluginTint.value, isNotNull);

    // The plugin's other screensaver starts untinted.
    saver.setModeOverride('a:1', 'plugin:monitor:cpu');
    await pumpEventQueue();
    expect(saver.activeView.value, 'plugin:monitor:cpu');
    expect(saver.pluginTint.value, isNull);

    // So does the Clock, and coming back does not bring the tint back.
    expect(saver.setPluginTint('monitor', 0xFF822222), isTrue);
    saver.clearModeOverride('a:1');
    await pumpEventQueue();
    expect(saver.activeView.value, 'clock');
    expect(saver.pluginTint.value, isNull);
    saver.setModeOverride('a:1', 'plugin:monitor:cpu');
    await pumpEventQueue();
    expect(saver.pluginTint.value, isNull);

    // The session ending drops it too.
    expect(saver.setPluginTint('monitor', 0xFF822222), isTrue);
    await saver.stop();
    expect(saver.pluginTint.value, isNull);
    saver.clearModeOverride('a:1');
  });

  test('the countdown names the held mode', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.timeout_seconds': 30,
      'ks.screensaver.mode': 'clock',
    });
    final modes = <String?>[];
    bus.on<ScreensaverCountdownChanged>().listen((e) => modes.add(e.mode));
    await saver.init();
    await pumpEventQueue();
    expect(modes.last, 'clock');
    saver.setModeOverride('a:1', 'celestial');
    await pumpEventQueue();
    expect(modes.last, 'celestial');
    saver.clearModeOverride('a:1');
    await pumpEventQueue();
    expect(modes.last, 'clock');
    await saver.dispose();
  });
}
