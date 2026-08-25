import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
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
      commands.register(
        Command(
          name: name,
          description: 'stub',
          handler: (_) async {
            executed.add(name);
            return const CommandResult.ok();
          },
        ),
      );
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
      final result = await launcher.commands.execute(
        'showAppLauncher',
        const {},
      );
      expect(result.ok, isFalse);
      expect(result.error, contains('disabled'));
      expect(launcher.visible.value, isFalse);
      expect(executed, isEmpty);
    });

    test('refuses with an empty whitelist', () async {
      await build({'ks.launcher.enabled': true});
      final result = await launcher.commands.execute(
        'showAppLauncher',
        const {},
      );
      expect(result.ok, isFalse);
      expect(launcher.visible.value, isFalse);
      expect(executed, isEmpty);
    });

    test('wakes, fronts, stops the screensaver, then shows', () async {
      await build({'ks.launcher.enabled': true, 'ks.launcher.apps': twoApps});
      final result = await launcher.commands.execute(
        'showAppLauncher',
        const {},
      );
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

  group('auto-return (issue #317)', () {
    const channel = MethodChannel('kiosk_satellite/background');
    late List<Map<String, Object?>> watchCalls;

    setUp(() {
      watchCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'watchTouches') {
              watchCalls.add((call.arguments as Map).cast<String, Object?>());
              return true;
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Future<void> armed() => build({
      'ks.launcher.enabled': true,
      'ks.launcher.apps': twoApps,
      'ks.launcher.auto_return': true,
      'ks.launcher.auto_return_seconds': 30,
    });

    test('returns after the idle time, watching touches meanwhile', () async {
      await armed();
      fakeAsync((async) {
        bus.publish(const AppLaunched(package: 'com.a'));
        async.flushMicrotasks();
        launcher.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.flushMicrotasks();
        expect(watchCalls, [
          {'on': true},
        ]);
        expect(launcher.watchingTouches, isTrue);
        async.elapse(const Duration(seconds: 29));
        expect(executed, isEmpty);
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(executed, ['bringToFront']);
        // The watch comes down with the clock.
        expect(watchCalls.last, {'on': false});
        expect(launcher.watchingTouches, isFalse);
      });
    });

    test('a touch in the other app starts the clock over', () async {
      await armed();
      fakeAsync((async) {
        bus.publish(const AppLaunched(package: 'com.a'));
        async.flushMicrotasks();
        launcher.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 25));
        launcher.touchSeen();
        async.elapse(const Duration(seconds: 25));
        // 50s in, but only 25s since the last touch: still away.
        expect(executed, isEmpty);
        launcher.touchSeen();
        async.elapse(const Duration(seconds: 29));
        expect(executed, isEmpty);
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(executed, ['bringToFront']);
      });
    });

    test('coming back on its own disarms the clock and the watch', () async {
      await armed();
      fakeAsync((async) {
        bus.publish(const AppLaunched(package: 'com.a'));
        async.flushMicrotasks();
        launcher.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        launcher.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.flushMicrotasks();
        expect(watchCalls.last, {'on': false});
        async.elapse(const Duration(seconds: 60));
        expect(executed, isEmpty);
        // A touch report after disarm is noise, not a re-arm.
        launcher.touchSeen();
        async.elapse(const Duration(seconds: 60));
        expect(executed, isEmpty);
      });
    });

    test('a pause with no launch behind it arms nothing', () async {
      await armed();
      fakeAsync((async) {
        launcher.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.flushMicrotasks();
        expect(watchCalls, isEmpty);
        async.elapse(const Duration(seconds: 60));
        expect(executed, isEmpty);
      });
    });

    test('runs the plain clock when the watch cannot go up', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => false);
      await armed();
      fakeAsync((async) {
        bus.publish(const AppLaunched(package: 'com.a'));
        async.flushMicrotasks();
        launcher.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.flushMicrotasks();
        expect(launcher.watchingTouches, isFalse);
        async.elapse(const Duration(seconds: 31));
        async.flushMicrotasks();
        expect(executed, ['bringToFront']);
      });
    });
  });

  group('foregroundApp', () {
    final binding = TestWidgetsFlutterBinding.instance;
    const channel = MethodChannel('kiosk_satellite/background');

    void mockNative(Map<Object?, Object?>? answer) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'foregroundApp' ? answer : null,
      );
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
    }

    test('relays the native answer when usage access names one', () async {
      await build({});
      mockNative(const {'package': 'com.wall', 'label': 'WallPanel'});
      final result = await launcher.commands.execute('foregroundApp', const {});
      expect(result.ok, isTrue);
      expect((result.data as Map)['package'], 'com.wall');
      expect((result.data as Map)['label'], 'WallPanel');
    });

    test(
      'vouches for this app while resumed when native knows nothing',
      () async {
        await build({});
        mockNative(null);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        final result = await launcher.commands.execute(
          'foregroundApp',
          const {},
        );
        expect((result.data as Map)['package'], 'me.jxl.kiosk_satellite');
        expect((result.data as Map)['label'], 'Kiosk Satellite');
      },
    );

    test(
      'answers an honest null while another app is up without the grant',
      () async {
        await build({});
        mockNative(null);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        // Leave the binding as other tests expect it.
        addTearDown(
          () =>
              binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
        );
        final result = await launcher.commands.execute(
          'foregroundApp',
          const {},
        );
        expect(result.ok, isTrue);
        expect((result.data as Map)['package'], isNull);
      },
    );
  });
}
