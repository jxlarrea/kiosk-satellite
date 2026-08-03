import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/launcher/app_launcher_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app launcher (issue #114): whitelist decoding, the overlay's
/// show/hide commands and their choreography, and the ways the overlay
/// closes on its own (an app opening over it, the screensaver starting).
/// The auto-return timer rides real lifecycle pauses and is exercised on
/// hardware; here the stubbed commands prove what the paths call.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late AppLauncherManager launcher;
  late List<String> executed;

  const twoApps =
      '[{"package":"com.a","label":"Alpha"},{"package":"com.b","label":"Beta"}]';

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    executed = [];
    for (final name in ['screenOn', 'bringToFront', 'stopScreensaver']) {
      commands.register(Command(
        name: name,
        description: 'stub',
        handler: (_) async {
          executed.add(name);
          return const CommandResult.ok();
        },
      ));
    }
    launcher = AppLauncherManager(bus, commands, log, settings);
    await launcher.init();
  }

  group('decodeLauncherApps', () {
    test('decodes packages and labels', () {
      final apps = decodeLauncherApps(twoApps);
      expect(apps, hasLength(2));
      expect(apps.first.package, 'com.a');
      expect(apps.first.label, 'Alpha');
    });

    test('falls back to the package when the label is missing', () {
      final apps = decodeLauncherApps('[{"package":"com.a"}]');
      expect(apps.single.label, 'com.a');
    });

    test('drops entries without a package', () {
      final apps = decodeLauncherApps('[{"label":"x"}, {"package":"com.a"}]');
      expect(apps.single.package, 'com.a');
    });

    test('tolerates garbage', () {
      expect(decodeLauncherApps('not json'), isEmpty);
      expect(decodeLauncherApps('{"package":"com.a"}'), isEmpty);
      expect(decodeLauncherApps(''), isEmpty);
    });
  });

  group('showAppLauncher', () {
    test('refuses while the launcher is disabled, whitelist or not', () async {
      await build({'ks.launcher.apps': twoApps});
      final result =
          await launcher.commands.execute('showAppLauncher', const {});
      expect(result.ok, isFalse);
      expect(result.error, contains('disabled'));
      expect(launcher.visible.value, isFalse);
      expect(executed, isEmpty);
    });

    test('refuses with an empty whitelist', () async {
      await build({'ks.launcher.enabled': true});
      final result =
          await launcher.commands.execute('showAppLauncher', const {});
      expect(result.ok, isFalse);
      expect(launcher.visible.value, isFalse);
      expect(executed, isEmpty);
    });

    test('wakes, fronts, stops the screensaver, then shows', () async {
      await build({'ks.launcher.enabled': true, 'ks.launcher.apps': twoApps});
      final result =
          await launcher.commands.execute('showAppLauncher', const {});
      expect(result.ok, isTrue);
      expect(launcher.visible.value, isTrue);
      expect(executed, ['screenOn', 'bringToFront', 'stopScreensaver']);
    });

    test('hideAppLauncher closes it', () async {
      await build({'ks.launcher.enabled': true, 'ks.launcher.apps': twoApps});
      await launcher.commands.execute('showAppLauncher', const {});
      await launcher.commands.execute('hideAppLauncher', const {});
      expect(launcher.visible.value, isFalse);
    });

    test('turning the launcher off closes an open overlay', () async {
      await build({'ks.launcher.enabled': true, 'ks.launcher.apps': twoApps});
      await launcher.commands.execute('showAppLauncher', const {});
      await settings.setFromJson('launcher.enabled', false);
      await pumpEventQueue();
      expect(launcher.visible.value, isFalse);
    });
  });

  group('the overlay closes on its own', () {
    test('when another app opens over it', () async {
      await build({'ks.launcher.enabled': true, 'ks.launcher.apps': twoApps});
      await launcher.commands.execute('showAppLauncher', const {});
      bus.publish(const AppLaunched(package: 'com.a'));
      await pumpEventQueue();
      expect(launcher.visible.value, isFalse);
    });

    test('when the screensaver starts', () async {
      await build({'ks.launcher.enabled': true, 'ks.launcher.apps': twoApps});
      await launcher.commands.execute('showAppLauncher', const {});
      bus.publish(const ScreensaverStateChanged(active: true));
      await pumpEventQueue();
      expect(launcher.visible.value, isFalse);
    });
  });

  test('the whitelist reads live from settings', () async {
    await build({});
    expect(launcher.apps, isEmpty);
    await settings.setFromJson('launcher.apps', twoApps);
    expect(launcher.apps, hasLength(2));
  });
}
