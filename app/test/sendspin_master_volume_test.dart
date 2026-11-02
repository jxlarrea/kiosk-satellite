import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/sendspin/sendspin_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The local Sendspin player's volume as the device's master volume
/// (issue #1267): the native side gets the switch at start and live, the
/// slider and mute move the master, and a reported master level never
/// lands in the media fader. With the switch off nothing changes.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('kiosk_satellite/sendspin');
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late SettingsManager settings;
  late SendspinManager manager;
  late List<MethodCall> calls;
  late List<int> masterWrites;

  Future<void> boot({bool master = false}) async {
    SharedPreferences.setMockInitialValues({
      'ks.sendspin.enabled': true,
      'ks.sendspin.client_id': 'tablet',
      'ks.sendspin.lyrics': false,
      'ks.sendspin.master_volume': master,
      'ks.audio.media_volume': 30,
    });
    calls = [];
    masterWrites = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    commands.register(
      Command(
        name: 'setVolume',
        description: 'test double for the master volume',
        handler: (p) async {
          masterWrites.add((p['percent'] as num).toInt());
          return const CommandResult.ok();
        },
      ),
    );
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    manager = SendspinManager(bus, commands, log, settings);
    await manager.init();
    addTearDown(manager.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  Future<void> native(String method, Map<String, Object?> args) async {
    await messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall(method, args)),
      (_) {},
    );
    await pumpEventQueue();
  }

  Map<Object?, Object?> startArgs() =>
      calls.firstWhere((c) => c.method == 'start').arguments as Map;

  test('the switch is off by default on the Sendspin Player page', () {
    expect(defs.sendspinMasterVolume.defaultValue, isFalse);
    expect(defs.sendspinMasterVolume.subpage, 'Sendspin Player');
    expect(defs.sendspinMasterVolume.dependsOn, defs.sendspinEnabled.key);
  });

  group('off', () {
    test('the slider and mute move the media fader', () async {
      await boot();
      expect(startArgs()['masterVolume'], isFalse);
      expect(manager.volumeLevel, 30);
      await manager.setVolume(40);
      expect(settings.get(defs.mediaVolume), 40);
      await manager.toggleMute();
      expect(manager.muted, isTrue);
      expect(settings.get(defs.mediaVolume), 0);
      await manager.toggleMute();
      expect(settings.get(defs.mediaVolume), 40);
      expect(masterWrites, isEmpty);
    });

    test('a server volume lands in the media fader', () async {
      await boot();
      await native('volumeChanged', {'volume': 55, 'muted': false});
      expect(settings.get(defs.mediaVolume), 55);
      expect(manager.volumeLevel, 55);
    });
  });

  group('on', () {
    test('the native side gets the switch at start', () async {
      await boot(master: true);
      expect(startArgs()['masterVolume'], isTrue);
    });

    test('the slider shows and sets the master', () async {
      await boot(master: true);
      await native('volumeChanged', {
        'volume': 80,
        'muted': false,
        'master': true,
      });
      expect(manager.volumeLevel, 80);
      // The master level is the device's and stays out of the setting.
      expect(settings.get(defs.mediaVolume), 30);
      expect(manager.nowPlaying.value?.containsKey('master'), isNot(true));
      await manager.setVolume(60);
      expect(masterWrites, [60]);
      expect(settings.get(defs.mediaVolume), 30);
    });

    test('mute takes the master to zero and back', () async {
      await boot(master: true);
      await native('volumeChanged', {
        'volume': 80,
        'muted': false,
        'master': true,
      });
      await manager.toggleMute();
      expect(manager.muted, isTrue);
      expect(masterWrites, [0]);
      await native('volumeChanged', {
        'volume': 0,
        'muted': false,
        'master': true,
      });
      await manager.toggleMute();
      expect(manager.muted, isFalse);
      expect(masterWrites, [0, 80]);
      expect(settings.get(defs.mediaVolume), 30);
    });
  });

  test('flipping the switch applies live without a restart', () async {
    await boot();
    calls.clear();
    await settings.set(defs.sendspinMasterVolume, true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(calls.map((c) => c.method), ['setMasterVolume']);
    expect((calls.single.arguments as Map)['enabled'], isTrue);
    calls.clear();
    await settings.set(defs.sendspinMasterVolume, false);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(calls.map((c) => c.method), ['setMasterVolume']);
    expect((calls.single.arguments as Map)['enabled'], isFalse);
  });

  test('a master report arriving after the switch goes off stays out of '
      'the media fader', () async {
    await boot();
    await native('volumeChanged', {
      'volume': 90,
      'muted': false,
      'master': true,
    });
    expect(settings.get(defs.mediaVolume), 30);
  });
}
