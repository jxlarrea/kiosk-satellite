import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// The device as a synchronized Sendspin audio player.
///
/// The actual player — WebSocket protocol, clock sync, decoders, the
/// timing-critical AudioTrack pipeline — lives in Kotlin (SendspinBridge and
/// the sendspin/ package): audio scheduling at millisecond precision has no
/// business crossing a platform channel per chunk. This manager owns the
/// lifecycle (settings in, state out) and translates player activity into
/// the same app-wide events every other feature speaks:
///
///  - [VoiceInteractionChanged] (reason 'media') while audio plays, so the
///    screensaver and dashboard rotation stand down exactly as they do for
///    Voice Satellite media.
///  - Status/discovery commands for the settings surfaces.
class SendspinManager extends Manager {
  SendspinManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _channel = MethodChannel('kiosk_satellite/sendspin');

  @override
  String get name => 'sendspin';

  Timer? _restartDebounce;

  /// Serialises start/stop so a settings burst cannot interleave two
  /// client lifecycles.
  Future<void> _transition = Future.value();

  bool _running = false;
  bool _playing = false;
  Map<String, Object?> _status = const {};

  /// Live now-playing snapshot for the floating player overlay: the merged
  /// status plus 'playing' and 'receivedAt' (epoch ms of the last metadata
  /// update, for on-screen position extrapolation). Null when idle.
  final nowPlaying = ValueNotifier<Map<String, Object?>?>(null);

  void _publishNowPlaying() {
    final state = '${_status['playbackState'] ?? ''}';
    final active = _playing || (state == 'paused' && _status['title'] != null);
    nowPlaying.value = !active
        ? null
        : {..._status, 'playing': _playing};
  }

  @override
  Future<void> init() async {
    var clientId = _settings.get(defs.sendspinClientId);
    if (clientId.isEmpty) {
      final rng = Random.secure();
      clientId =
          List.generate(32, (_) => rng.nextInt(16).toRadixString(16)).join();
      await _settings.set(defs.sendspinClientId, clientId);
    }

    _channel.setMethodCallHandler((call) async {
      final args = call.arguments;
      final map = args is Map ? args.cast<String, Object?>() : const <String, Object?>{};
      switch (call.method) {
        case 'stateChanged':
          _status = {..._status, ...map};
          log.info(
              name,
              'state: connected=${map['connected']} '
              'server=${map['serverName']} synced=${map['synced']}');
        case 'metadataChanged':
          // Metadata arrives as deltas: a progress-only update carries no
          // title, and the server may send literal "null" strings. Absent
          // fields must not clobber what an earlier message established.
          _status = {
            ..._status,
            for (final e in map.entries)
              if (e.value != null && '${e.value}' != 'null' &&
                  '${e.value}'.isNotEmpty)
                e.key: e.value,
            'receivedAt': DateTime.now().millisecondsSinceEpoch,
          };
        case 'volumeChanged':
          _status = {..._status, ...map};
        case 'controllerChanged':
          _status = {..._status, ...map};
        case 'playingChanged':
          final playing = map['playing'] == true;
          if (playing != _playing) {
            _playing = playing;
            // The same signal Voice Satellite media playback raises: hold
            // the screensaver and rotation while music is audible here.
            // NOT raised in full-screen player mode: there the screensaver
            // must keep firing, because it IS the now-playing display.
            if (!_settings.get(defs.sendspinFullscreen)) {
              bus.publish(
                  VoiceInteractionChanged(active: playing, reason: 'media'));
            } else if (!playing) {
              bus.publish(const VoiceInteractionChanged(
                  active: false, reason: 'media'));
            }
          }
      }
      _publishNowPlaying();
      return null;
    });

    bus.on<SettingChanged>().listen((e) {
      // Only connection-shaping settings restart the client; the UI-only
      // ones (card visibility, size, position, fullscreen mode) must not
      // interrupt playback when toggled.
      const uiOnly = [
        'sendspin.show_player',
        'sendspin.player_size',
        'sendspin.player_pos',
        'sendspin.fullscreen',
      ];
      final relevant = e.key.startsWith('sendspin.') &&
              e.key != defs.sendspinClientId.key &&
              !uiOnly.contains(e.key) ||
          e.key == defs.deviceName.key;
      if (!relevant) return;
      _restartDebounce?.cancel();
      _restartDebounce = Timer(const Duration(seconds: 1), () {
        _transition = _transition.then((_) async {
          await _stop();
          if (_settings.get(defs.sendspinEnabled)) await _start();
        });
      });
    });

    commands.register(Command(
      name: 'sendspinStatus',
      description:
          'The Sendspin player status: connection, server, playback state, '
          'current track and volume.',
      handler: (_) async => CommandResult.ok({
        'enabled': _settings.get(defs.sendspinEnabled),
        'running': _running,
        'playing': _playing,
        ..._status,
      }),
    ));

    commands.register(Command(
      name: 'sendspinControl',
      description:
          'Send a transport command to the Sendspin group this player '
          'belongs to (play, pause, next, previous).',
      params: const {'command': 'play | pause | next | previous'},
      handler: (p) async {
        final ok = await control('${p['command'] ?? ''}');
        return ok
            ? const CommandResult.ok()
            : const CommandResult.fail('command not supported or not sent');
      },
    ));

    commands.register(Command(
      name: 'sendspinDiscover',
      description:
          'Scan the network for Sendspin servers (mDNS). Returns name, '
          'host, port and url per server found.',
      params: const {'timeoutMs': 'scan duration, default 3000'},
      handler: (p) async {
        try {
          final found = await _channel.invokeMethod<List<Object?>>(
              'discover', {
            'timeoutMs': (p['timeoutMs'] as num?)?.toInt() ?? 3000,
          });
          return CommandResult.ok(found ?? const []);
        } catch (e) {
          return CommandResult.fail('discovery failed: $e');
        }
      },
    ));

    if (_settings.get(defs.sendspinEnabled)) {
      _transition = _transition.then((_) => _start());
    }
  }

  @override
  Future<void> dispose() async {
    _restartDebounce?.cancel();
    await _stop();
  }

  /// Group transport control (the controller role). False when the server
  /// does not support the command or nothing is connected.
  Future<bool> control(String command) async {
    try {
      return await _channel.invokeMethod<bool>(
              'control', {'command': command}) ??
          false;
    } catch (e) {
      log.warn(name, 'control $command failed: $e');
      return false;
    }
  }

  Future<void> _start() async {
    // The player name is the same identity everything else shows: the
    // device name setting, or the hardware model via getDeviceInfo.
    var playerName = _settings.get(defs.deviceName).trim();
    if (playerName.isEmpty) {
      final info = await commands.execute('getDeviceInfo', const {});
      final data = info.data;
      if (info.ok && data is Map) playerName = '${data['name'] ?? 'Kiosk'}';
    }
    try {
      await _channel.invokeMethod('start', {
        'serverUrl': _settings.get(defs.sendspinServer).trim(),
        'playerName': playerName,
        'clientId': _settings.get(defs.sendspinClientId),
        'preferredCodec': _settings.get(defs.sendspinCodec),
      });
      _running = true;
      log.info(name, 'player started as "$playerName"');
    } catch (e) {
      log.warn(name, 'start failed: $e');
    }
  }

  Future<void> _stop() async {
    if (!_running) return;
    _running = false;
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      log.warn(name, 'stop failed: $e');
    }
    if (_playing) {
      _playing = false;
      bus.publish(const VoiceInteractionChanged(active: false, reason: 'media'));
    }
    _status = const {};
    nowPlaying.value = null;
  }
}
