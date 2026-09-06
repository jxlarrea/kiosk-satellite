import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/esp_entities.dart';
import 'package:kiosk_satellite/managers/kiosk/kiosk_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen pinning vs the app launcher (issue #250): Android refuses to
/// switch away from a pinned task, so launchApp must unpin first, and the
/// pin must come back on its own when the kiosk returns to the foreground.
/// The resume re-pin also answers a manual unpin, which used to defeat
/// Disable home button until the setting was toggled.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  const lockChannel = MethodChannel('kiosk_satellite/kiosk_lock');
  const backgroundChannel = MethodChannel('kiosk_satellite/background');

  late EventBus bus;
  late CommandRegistry commands;
  late KioskManager kiosk;
  late EspEntitySurface surface;
  late List<MethodCall> backgroundCalls;

  /// Every outgoing call on the lock channel, in order.
  late List<String> lockCalls;

  /// What the mock native side reports: whether the task is pinned right
  /// now, and whether the launch intent resolves.
  late bool pinned;
  late bool launchWorks;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    surface = EspEntitySurface(bus, commands, log, settings);

    lockCalls = [];
    backgroundCalls = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(lockChannel, (
      call,
    ) async {
      lockCalls.add(call.method);
      switch (call.method) {
        case 'unpin':
          final was = pinned;
          pinned = false;
          return was;
        case 'isPinned':
          return pinned;
        case 'hasOverlayPermission':
          return true;
        default:
          return null;
      }
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(backgroundChannel, (
      call,
    ) async {
      backgroundCalls.add(call);
      if (call.method == 'launchApp' ||
          call.method == 'openUri' ||
          call.method == 'openSystemSettings') {
        return launchWorks;
      }
      return null;
    });

    kiosk = KioskManager(bus, commands, log, settings);
    kiosk.pushFlags = true;
    await kiosk.init();
    // init pushes its own apply; only calls made by the scenario count.
    lockCalls.clear();
  }

  tearDown(() async {
    surface.detach();
    await kiosk.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(lockChannel, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      backgroundChannel,
      null,
    );
  });

  group('launchApp under the pin', () {
    test('unpins before launching; the success path leaves re-pinning to '
        'the resume', () async {
      pinned = true;
      launchWorks = true;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      final result = await commands.execute('launchApp', {
        'package': 'com.example.app',
      });
      expect(result.ok, true);
      expect(lockCalls, contains('unpin'));
      expect(lockCalls, isNot(contains('apply')));
    });

    test('a failed launch re-arms the pin immediately (no pause means no '
        'resume re-pin)', () async {
      pinned = true;
      launchWorks = false;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      final result = await commands.execute('launchApp', {
        'package': 'com.example.gone',
      });
      expect(result.ok, false);
      expect(lockCalls, contains('unpin'));
      expect(lockCalls, contains('apply'));
      expect(lockCalls.indexOf('unpin'), lessThan(lockCalls.indexOf('apply')));
    });

    test('a failed launch that never held a pin does not re-apply', () async {
      pinned = false;
      launchWorks = false;
      await build({});
      final result = await commands.execute('launchApp', {
        'package': 'com.example.gone',
      });
      expect(result.ok, false);
      expect(lockCalls, isNot(contains('apply')));
    });

    test('Android Settings and a deep link take the same road (issue #417): '
        'unpin first, and the launch is published as sanctioned', () async {
      pinned = true;
      launchWorks = true;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      final launched = <String>[];
      bus.on<AppLaunched>().listen((e) => launched.add(e.package));

      expect((await commands.execute('openSystemSettings', const {})).ok, true);
      expect(lockCalls, contains('unpin'));
      expect(lockCalls, isNot(contains('apply')));
      lockCalls.clear();
      pinned = true;

      expect((await commands.execute('openUri', {'uri': 'geo:0,0'})).ok, true);
      expect(lockCalls, contains('unpin'));
      await pumpEventQueue();
      expect(launched, ['com.android.settings', 'geo:0,0']);
    });

    test('Android Settings that does not come up re-arms the pin', () async {
      pinned = true;
      launchWorks = false;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      final result = await commands.execute('openSystemSettings', const {});
      expect(result.ok, false);
      expect(lockCalls.indexOf('unpin'), lessThan(lockCalls.indexOf('apply')));
    });
  });

  group('ESPHome launch_app', () {
    test('launches the requested package through the kiosk command', () async {
      pinned = true;
      launchWorks = true;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      final action = surface.buildServices().singleWhere(
        (service) => service['name'] == 'launch_app',
      );
      expect(action['supportsResponse'], true);
      expect(action['args'], [
        {'name': 'package_name', 'type': 'string'},
      ]);
      final launched = <String>[];
      final sub = bus.on<AppLaunched>().listen((e) => launched.add(e.package));
      addTearDown(sub.cancel);

      expect(
        await surface.handleService('launch_app', {
          'package_name': ' com.android.deskclock ',
        }),
        isEmpty,
      );
      final call = backgroundCalls.singleWhere((c) => c.method == 'launchApp');
      expect(call.arguments, {'package': 'com.android.deskclock'});
      expect(lockCalls, contains('unpin'));
      expect(lockCalls, isNot(contains('apply')));
      await pumpEventQueue();
      expect(launched, ['com.android.deskclock']);
    });

    test('reports a failed launch and restores the pin', () async {
      pinned = true;
      launchWorks = false;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});

      await expectLater(
        surface.handleService('launch_app', {
          'package_name': 'com.example.gone',
        }),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('com.example.gone is not installed'),
          ),
        ),
      );
      expect(lockCalls.indexOf('unpin'), lessThan(lockCalls.indexOf('apply')));
    });

    test('rejects missing or blank packages without unpinning', () async {
      pinned = true;
      launchWorks = true;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});

      for (final args in <Map<String, Object?>>[
        {},
        {'package_name': ''},
        {'package_name': '   '},
      ]) {
        await expectLater(
          surface.handleService('launch_app', args),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'package required',
            ),
          ),
        );
      }
      expect(lockCalls, isNot(contains('unpin')));
      expect(backgroundCalls.where((c) => c.method == 'launchApp'), isEmpty);
    });
  });

  group('re-pin on resume', () {
    test('a resume with Disable home wanted re-applies the flags', () async {
      pinned = false;
      launchWorks = true;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      kiosk.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(lockCalls, contains('apply'));
    });

    test('a resume without the setting leaves the pin alone', () async {
      pinned = false;
      launchWorks = true;
      await build({'ks.kiosk.enabled': true});
      kiosk.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(lockCalls, isNot(contains('apply')));
    });

    test('an open menu stands the re-pin down', () async {
      pinned = false;
      launchWorks = true;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      kiosk.menuBusy = true;
      kiosk.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(lockCalls, isNot(contains('apply')));
    });

    test(
      'back-to-back resumes re-apply once (consent-dialog loop guard)',
      () async {
        pinned = false;
        launchWorks = true;
        await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
        kiosk.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await pumpEventQueue();
        kiosk.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await pumpEventQueue();
        expect(lockCalls.where((m) => m == 'apply').length, 1);
      },
    );
  });
}
