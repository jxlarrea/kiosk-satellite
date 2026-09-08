import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/sendspin/ma_remote_player.dart';
import 'package:kiosk_satellite/managers/sendspin/music_assistant_api.dart';
import 'package:kiosk_satellite/managers/sendspin/sendspin_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Api extends MusicAssistantApi {
  _Api() : super(baseUrl: 'ma.local', token: 'token');
  @override
  Future<MusicAssistantResult> call(
    String command, {
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 15),
  }) async => const MusicAssistantResult.success(null, {});
}

class _Remote extends MaRemotePlayer {
  _Remote({
    required super.playerId,
    required super.onSnapshot,
    required super.log,
  }) : super(baseUrl: 'ma.local', token: 'token');
  bool started = false;
  bool stopped = false;
  int level = 40;
  final writes = <int>[];
  Completer<bool>? gate;

  void emit({int? volume = 40, bool supported = true}) => onSnapshot({
    'title': 'Song',
    'playing': true,
    'volume': ?volume,
    'supportedCommands': [if (supported) 'volume'],
  });

  @override
  void start() {
    started = true;
    emit(volume: level);
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<bool> setVolume(int percent) async {
    expect(stopped, isFalse, reason: 'restore must precede stop');
    writes.add(percent);
    final pending = gate;
    gate = null;
    if (pending != null) await pending.future;
    level = percent;
    emit(volume: level);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('kiosk_satellite/sendspin');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late EventBus bus;
  late SendspinManager manager;
  late SettingsManager settings;
  final remotes = <_Remote>[];
  final native = <MethodCall>[];

  Future<void> boot(String source) async {
    SharedPreferences.setMockInitialValues({
      'ks.device.name': 'Tablet',
      'ks.sendspin.enabled': true,
      'ks.sendspin.client_id': 'tablet',
      'ks.sendspin.player_source': source,
      'ks.sendspin.player': source.isEmpty ? '' : '$source:p1',
      if (source.isNotEmpty) 'ks.sendspin.ma_url': 'ma.local',
      'ks.sendspin.ma_token': 'token',
      'ks.ha.url': 'http://ha.local',
      'ks.ha.token': 'token',
      'ks.sendspin.sonos_hosts': '{"p1":{"host":"speaker.local"}}',
      'ks.sendspin.lyrics': false,
    });
    remotes.clear();
    native.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      native.add(call);
      return null;
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    manager = SendspinManager(bus, commands, log, settings);
    manager.apiFactory = ({required baseUrl, required token}) => _Api();
    _Remote create(String id, void Function(Map<String, Object?>?) onSnapshot) {
      final remote = _Remote(playerId: id, onSnapshot: onSnapshot, log: log);
      remotes.add(remote);
      return remote;
    }

    manager.remoteFactory =
        ({
          required baseUrl,
          required token,
          required playerId,
          required onSnapshot,
          required log,
          String label = 'remote player',
        }) => create(playerId, onSnapshot);
    manager.haRemoteFactory =
        ({
          required baseUrl,
          required token,
          required entityId,
          required onSnapshot,
          required log,
        }) => create(entityId, onSnapshot);
    manager.sonosRemoteFactory =
        ({
          required host,
          required uuid,
          required onSnapshot,
          required log,
          bool groupVolume = true,
          bool showInputs = false,
        }) => create(uuid, onSnapshot);
    await manager.init();
    await pumpEventQueue();
  }

  Future<void> voice(bool active, [String reason = 'voice']) async {
    bus.publish(VoiceInteractionChanged(active: active, reason: reason));
    await pumpEventQueue();
  }

  tearDown(() async {
    await manager.dispose();
    await bus.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  for (final source in ['ma', 'ha', 'sonos']) {
    test(
      '$source ducks once across overlapping interactions and restores',
      () async {
        await boot(source);
        final remote = remotes.single;
        await voice(true, 'media');
        expect(remote.writes, isEmpty);
        await voice(true);
        await voice(true, 'announcement');
        await voice(true);
        expect(remote.writes, [4]);
        expect(manager.nowPlaying.value?['volume'], 40);
        await voice(false);
        expect(remote.writes, [4]);
        await voice(false, 'announcement');
        expect(remote.writes, [4, 40]);
      },
    );
  }

  test(
    'local audio uses native gain and leaves the normal volume unchanged',
    () async {
      await boot('');
      final volume = settings.get(defs.mediaVolume);
      await voice(true);
      expect(native.lastWhere((c) => c.method == 'duck').arguments, {
        'factor': .1,
      });
      await settings.set(defs.sendspinDuckPercent, 20);
      await pumpEventQueue();
      expect(native.lastWhere((c) => c.method == 'duck').arguments, {
        'factor': .2,
      });
      await voice(false);
      expect(native.lastWhere((c) => c.method == 'duck').arguments, {
        'factor': 1.0,
      });
      expect(settings.get(defs.mediaVolume), volume);
    },
  );

  test(
    'live factor and slider changes preserve the new normal volume',
    () async {
      await boot('ma');
      final remote = remotes.single;
      await voice(true);
      await settings.set(defs.sendspinDuckPercent, 20);
      await pumpEventQueue();
      expect(remote.writes, [4, 8]);
      expect(await manager.setVolume(60), isTrue);
      expect(remote.writes, [4, 8, 12]);
      expect(manager.nowPlaying.value?['volume'], 60);
      await voice(false);
      expect(remote.writes, [4, 8, 12, 60]);
    },
  );

  test(
    'a source replacement waits for restoration and ignores old snapshots',
    () async {
      await boot('ma');
      final old = remotes.single;
      final gate = Completer<bool>();
      old.gate = gate;
      await voice(true);
      expect(old.writes, [4]);
      await settings.set(defs.sendspinPlayer, 'ma:p2');
      await pumpEventQueue();
      final next = remotes.last;
      expect(next, isNot(same(old)));
      expect(next.started, isFalse);
      old.emit(volume: 1);
      expect(manager.nowPlaying.value, isNull);
      gate.complete(true);
      await pumpEventQueue();
      expect(old.writes, [4, 40]);
      expect(old.stopped, isTrue);
      expect(next.started, isTrue);
      expect(next.writes, [4]);
      await voice(false);
      expect(next.writes, [4, 40]);
    },
  );

  test(
    'missing or unsupported volume is skipped until usable state arrives',
    () async {
      await boot('ha');
      final remote = remotes.single;
      remote.emit(volume: null);
      await voice(true);
      expect(remote.writes, isEmpty);
      remote.emit(supported: false);
      await pumpEventQueue();
      expect(remote.writes, isEmpty);
      remote.emit(volume: 80);
      await pumpEventQueue();
      expect(remote.writes, [8]);
      await voice(false);
      expect(remote.writes, [8, 80]);
    },
  );

  test('the main-page slider follows Player for every source', () async {
    await boot('sonos');
    expect(settings.visible(defs.sendspinDuckPercent), isTrue);
    expect(defs.sendspinDuckPercent.subpage, isNull);
    expect(defs.sendspinDuckPercent.section, isNull);
    final index = defs.allSettings.indexOf(defs.sendspinPlayer);
    expect(defs.allSettings[index + 1], same(defs.sendspinDuckPercent));
    expect(settings.get(defs.sendspinDuckPercent), 10);
  });
}
