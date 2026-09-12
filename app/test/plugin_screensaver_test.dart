import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/plugin_screensaver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const mode = 'plugin:hello-world:dvd';
  late SettingsManager settings;
  late ScreensaverManager saver;
  late EventBus bus;
  late Logger log;
  late List<double> brightness;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'ks.screensaver.enabled': true});
    bus = EventBus();
    log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    brightness = [];
    commands.register(
      Command(
        name: 'getBrightness',
        description: 'test',
        handler: (_) async => const CommandResult.ok(.8),
      ),
    );
    commands.register(
      Command(
        name: 'setBrightness',
        description: 'test',
        handler: (p) async {
          brightness.add((p['level'] as num).toDouble());
          return const CommandResult.ok();
        },
      ),
    );
    saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();
  });
  tearDown(() async {
    await saver.dispose();
    await settings.dispose();
    await bus.dispose();
    log.dispose();
  });
  test(
    'both settings clients get live names and retain an unavailable selection',
    () async {
      settings.pluginScreensavers = () => {mode: 'DVD Logo (Hello World)'};
      expect(await settings.setFromJson(screensaverMode.key, mode), true);
      final schema = settings.describe().firstWhere(
        (s) => s['key'] == screensaverMode.key,
      );
      expect(schema['options'], contains(mode));
      expect((schema['optionLabels'] as Map)[mode], 'DVD Logo (Hello World)');
      settings.pluginScreensavers = () => {};
      expect(settings.optionsFor(screensaverMode), contains(mode));
      expect(
        settings.optionLabel(screensaverMode, mode),
        'Unavailable plugin screensaver',
      );
      expect(
        await settings.setFromJson(screensaverMode.key, 'plugin:../bad:dvd'),
        false,
      );
      expect(await settings.setFromJson(screensaverMode.key, 'clock'), true);
    },
  );
  test(
    'scheduled plugin uses stock overrides and restores brightness on stop',
    () async {
      await settings.set(screensaverScheduleEnabled, true);
      await settings.set(
        screensaverSchedule,
        jsonEncode([
          {
            'at': '00:00',
            'mode': mode,
            'brightness': .25,
            'widgets': false,
            'glance': false,
            'now_playing': false,
            'motion': false,
          },
        ]),
      );
      await pumpEventQueue();
      await saver.start();
      expect(saver.activeView.value, mode);
      expect(brightness, [.25]);
      expect(saver.scheduleWidgets.value, false);
      expect(saver.scheduleGlance.value, false);
      expect(saver.scheduleNowPlaying.value, false);
      await saver.stop();
      expect(saver.activeView.value, isNull);
      expect(brightness.last, .8);
    },
  );
  test('render document isolates plugin markup and denies host access', () {
    final document = pluginScreensaverDocument(
      '<script>window.demo = "test";</script>',
    );
    expect(document, contains('sandbox="allow-scripts"'));
    expect(document, isNot(contains('allow-same-origin')));
    expect(document, contains('&lt;script&gt;'));
    expect(document, contains("connect-src 'none'"));
    expect(document, contains("form-action 'none'"));
  });
}
