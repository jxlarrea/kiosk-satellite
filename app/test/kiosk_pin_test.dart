import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
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

    lockCalls = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(lockChannel,
        (call) async {
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
    binding.defaultBinaryMessenger.setMockMethodCallHandler(backgroundChannel,
        (call) async {
      if (call.method == 'launchApp') return launchWorks;
      return null;
    });

    kiosk = KioskManager(bus, commands, log, settings);
    kiosk.pushFlags = true;
    await kiosk.init();
    // init pushes its own apply; only calls made by the scenario count.
    lockCalls.clear();
  }

  tearDown(() async {
    await kiosk.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(lockChannel, null);
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(backgroundChannel, null);
  });

  group('launchApp under the pin', () {
    test('unpins before launching; the success path leaves re-pinning to '
        'the resume', () async {
      pinned = true;
      launchWorks = true;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      final result =
          await commands.execute('launchApp', {'package': 'com.example.app'});
      expect(result.ok, true);
      expect(lockCalls, contains('unpin'));
      expect(lockCalls, isNot(contains('apply')));
    });

    test('a failed launch re-arms the pin immediately (no pause means no '
        'resume re-pin)', () async {
      pinned = true;
      launchWorks = false;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      final result =
          await commands.execute('launchApp', {'package': 'com.example.gone'});
      expect(result.ok, false);
      expect(lockCalls, contains('unpin'));
      expect(lockCalls, contains('apply'));
      expect(lockCalls.indexOf('unpin'), lessThan(lockCalls.indexOf('apply')));
    });

    test('a failed launch that never held a pin does not re-apply',
        () async {
      pinned = false;
      launchWorks = false;
      await build({});
      final result =
          await commands.execute('launchApp', {'package': 'com.example.gone'});
      expect(result.ok, false);
      expect(lockCalls, isNot(contains('apply')));
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

    test('back-to-back resumes re-apply once (consent-dialog loop guard)',
        () async {
      pinned = false;
      launchWorks = true;
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      kiosk.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      kiosk.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(lockCalls.where((m) => m == 'apply').length, 1);
    });
  });
}
