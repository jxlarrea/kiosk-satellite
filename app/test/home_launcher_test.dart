import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/kiosk/kiosk_manager.dart';
import 'package:kiosk_satellite/managers/launcher/home_launcher_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The home-launcher role (issue #219): the manager is the single funnel
/// for home.enabled, so the device UI, the remote admin and a settings
/// import all drive the same acquire/release path; release must work
/// headless (the remote rescue); a tripped crash fuse flips the stored
/// setting to match what the device is actually doing.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  const lockChannel = MethodChannel('kiosk_satellite/kiosk_lock');
  const backgroundChannel = MethodChannel('kiosk_satellite/background');

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late HomeLauncherManager home;

  /// Every outgoing call, in order, with its arguments.
  late List<MethodCall> backgroundCalls;
  late List<MethodCall> lockCalls;

  /// The scripted native status the mock returns.
  late Map<String, Object?> nativeStatus;

  /// Whether the lock channel has a native handler (an Activity attached);
  /// without one the acquire path must stage instead of throwing.
  late bool activityUp;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  Future<void> build(Map<String, Object> initial) async {
    // Global and mutated by init on unsupported devices; each scenario
    // starts from a clean slate.
    defs.deviceHiddenKeys.clear();
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();

    backgroundCalls = [];
    lockCalls = [];
    activityUp = true;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(backgroundChannel, (
      call,
    ) async {
      backgroundCalls.add(call);
      switch (call.method) {
        case 'homeRoleStatus':
          return Map<String, Object?>.from(nativeStatus);
        case 'homeRoleAcquireSilent':
          return true;
        default:
          return true;
      }
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(lockChannel, (
      call,
    ) async {
      if (!activityUp) {
        throw MissingPluginException('no activity');
      }
      lockCalls.add(call);
      return true;
    });

    home = HomeLauncherManager(bus, commands, log, settings);
    home.active = true;
    await home.init();
    backgroundCalls.clear();
    lockCalls.clear();
  }

  tearDown(() async {
    await home.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(lockChannel, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      backgroundChannel,
      null,
    );
  });

  Map<String, Object?> status({
    bool supported = true,
    bool deviceOwner = false,
    bool held = false,
    bool aliasEnabled = false,
    bool fuseTripped = false,
    String fuseReason = '',
    String? defaultHome = 'com.oem.launcher',
  }) => {
    'supported': supported,
    'reason': supported ? '' : 'unavailable',
    'held': held,
    'defaultHome': defaultHome,
    'aliasEnabled': aliasEnabled,
    'deviceOwner': deviceOwner,
    'fuseTripped': fuseTripped,
    'fuseReason': fuseReason,
    'roleDenials': 0,
    'sdk': 34,
  };

  List<String> methods(List<MethodCall> calls) => [
    for (final c in calls) c.method,
  ];

  group('enable', () {
    test('device owner: fuse cleared, previous launcher stored, silent '
        'acquire, kiosk brought to the front', () async {
      nativeStatus = status(deviceOwner: true);
      await build({});
      // A silent enable is a remote one; the flip must end with the kiosk
      // on screen, not just the resolution changed (an Echo Show has no
      // home button to summon it with).
      var broughtToFront = 0;
      commands.register(
        Command(
          name: 'bringToFront',
          description: '',
          handler: (_) async {
            broughtToFront++;
            return const CommandResult.ok();
          },
        ),
      );
      await settings.set(defs.homeLauncherEnabled, true);
      await settle();
      expect(broughtToFront, 1);
      final seen = methods(backgroundCalls);
      expect(seen, contains('homeFuseClear'));
      expect(seen, contains('homeRoleAcquireSilent'));
      expect(
        seen.indexOf('homeFuseClear'),
        lessThan(seen.indexOf('homeRoleAcquireSilent')),
      );
      expect(settings.internal('home.previous_launcher'), 'com.oem.launcher');
      expect(methods(lockCalls), isNot(contains('homeRoleRequest')));
    });

    test('non-owner with the kiosk on screen: the role request fires on '
        'the activity channel', () async {
      nativeStatus = status();
      await build({});
      await settings.set(defs.homeLauncherEnabled, true);
      await settle();
      expect(methods(lockCalls), contains('homeRoleRequest'));
      expect(
        methods(backgroundCalls),
        isNot(contains('homeRoleAcquireSilent')),
      );
    });

    test(
      'non-owner with no activity: stays staged instead of throwing',
      () async {
        nativeStatus = status();
        await build({});
        activityUp = false;
        await settings.set(defs.homeLauncherEnabled, true);
        await settle();
        expect(lockCalls, isEmpty);
        expect(settings.get(defs.homeLauncherEnabled), isTrue);
      },
    );

    test('unsupported device: the rows are hidden and a raw enable is '
        'reverted, nothing engaged', () async {
      nativeStatus = status(supported: false);
      await build({});
      expect(
        defs.deviceHiddenKeys,
        containsAll([defs.homeLauncherEnabled.key, defs.homeKeepPinning.key]),
      );
      await settings.set(defs.homeLauncherEnabled, true);
      await settle();
      expect(settings.get(defs.homeLauncherEnabled), isFalse);
      expect(methods(backgroundCalls), isNot(contains('homeFuseClear')));
      expect(lockCalls, isEmpty);
    });

    test('unsupported device with a stored true (imported config): '
        'flipped off at boot', () async {
      nativeStatus = status(supported: false);
      await build({'ks.home.enabled': true});
      expect(settings.get(defs.homeLauncherEnabled), isFalse);
    });

    test('supported device leaves the rows visible', () async {
      nativeStatus = status();
      await build({});
      expect(
        defs.deviceHiddenKeys.contains(defs.homeLauncherEnabled.key),
        isFalse,
      );
    });

    test(
      'setFromJson funnels identically (the remote and import path)',
      () async {
        nativeStatus = status(deviceOwner: true);
        await build({});
        await settings.setFromJson(defs.homeLauncherEnabled.key, true);
        await settle();
        expect(methods(backgroundCalls), contains('homeRoleAcquireSilent'));
      },
    );
  });

  group('disable and rescue', () {
    test('toggle off releases with the remembered previous launcher', () async {
      nativeStatus = status(held: true, aliasEnabled: true);
      await build({'ks.home.enabled': true});
      await settings.setInternal('home.previous_launcher', 'com.oem.launcher');
      await settings.set(defs.homeLauncherEnabled, false);
      await settle();
      final release = backgroundCalls.firstWhere(
        (c) => c.method == 'homeRoleRelease',
      );
      expect(release.arguments, {'previous': 'com.oem.launcher'});
    });

    test(
      'releaseHomeRole works headless with the setting already off',
      () async {
        nativeStatus = status();
        await build({});
        activityUp = false;
        final res = await commands.execute('releaseHomeRole', const {});
        expect(res.ok, isTrue);
        expect(methods(backgroundCalls), contains('homeRoleRelease'));
      },
    );

    test('releaseHomeRole with the setting on goes through it, so every '
        'surface tells the truth', () async {
      nativeStatus = status(held: true, aliasEnabled: true);
      await build({'ks.home.enabled': true});
      final res = await commands.execute('releaseHomeRole', const {});
      await settle();
      expect(res.ok, isTrue);
      expect(settings.get(defs.homeLauncherEnabled), isFalse);
      expect(methods(backgroundCalls), contains('homeRoleRelease'));
    });
  });

  group('roleHeld cache (the PopScope veto)', () {
    test('seeded from the boot status read', () async {
      nativeStatus = status(held: true, aliasEnabled: true);
      await build({'ks.home.enabled': true});
      expect(home.roleHeld.value, isTrue);
    });

    test('follows HomeRoleChanged and drops on release', () async {
      nativeStatus = status();
      await build({});
      expect(home.roleHeld.value, isFalse);
      bus.publish(const HomeRoleChanged(held: true));
      await settle();
      expect(home.roleHeld.value, isTrue);
      await commands.execute('releaseHomeRole', const {});
      await settle();
      expect(home.roleHeld.value, isFalse);
    });
  });

  group('crash fuse', () {
    test('a tripped fuse at boot flips the setting off and keeps the '
        'reason', () async {
      nativeStatus = status(
        fuseTripped: true,
        fuseReason: 'home launcher disabled automatically: 3 starts',
      );
      await build({'ks.home.enabled': true});
      await settle();
      expect(settings.get(defs.homeLauncherEnabled), isFalse);
      expect(settings.internal('home.fuse_reason'), contains('3 starts'));
    });

    test('a deliberate re-enable clears the stored reason', () async {
      nativeStatus = status(deviceOwner: true);
      await build({});
      await settings.setInternal('home.fuse_reason', 'old trip');
      await settings.set(defs.homeLauncherEnabled, true);
      await settle();
      expect(settings.internal('home.fuse_reason'), isEmpty);
    });
  });

  group('kiosk bundle', () {
    test('homeRolePin rides the apply bundle from home.keep_pinning', () async {
      nativeStatus = status();
      await build({
        'ks.kiosk.enabled': true,
        'ks.kiosk.disable_home': true,
        'ks.home.enabled': true,
        'ks.home.keep_pinning': true,
      });
      final log = Logger();
      final kiosk = KioskManager(bus, CommandRegistry(log), log, settings);
      kiosk.pushFlags = true;
      Map<Object?, Object?>? bundle;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(lockChannel, (
        call,
      ) async {
        if (call.method == 'apply') {
          bundle = call.arguments as Map<Object?, Object?>;
        }
        return null;
      });
      await kiosk.init();
      // init's own apply is gated off-platform; the resume re-pin is the
      // test's way in, same as kiosk_pin_test.
      kiosk.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(bundle, isNotNull);
      expect(bundle!['homeRolePin'], isTrue);
      await kiosk.dispose();
    });
  });
}
