import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'lrclib.dart';
import 'lyrics.dart';
import 'music_assistant_api.dart';

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

  /// True while any non-media interaction (voice, announcement, timer) is
  /// in progress: the floating player hides and playback ducks.
  final voiceActive = ValueNotifier<bool>(false);
  final _voiceReasons = <String>{};

  Timer? _idleGrace;

  /// The 'playing' flag as published to the UI. Lags reality through the
  /// grace window: at the instant playback stops, a pause and a track
  /// change are indistinguishable (both are a stream/end), so the UI keeps
  /// its playing look until the gap proves persistent.
  bool _uiPlaying = false;

  /// Whether any audio has played this session. Music Assistant reports a
  /// merely-stopped queue with its last track's metadata, which is
  /// indistinguishable from a pause; requiring a prior playing state keeps
  /// the boot sequence from conjuring a paused card out of stale metadata.
  bool _sawPlayback = false;

  /// The current track's synced lyrics, empty when there are none, the
  /// feature is off, or the lookup has not finished. The full-screen player
  /// follows it; nothing else does.
  final lyrics = ValueNotifier<List<LyricLine>>(const []);

  /// The track the lyrics in [lyrics] belong to, so a reply that arrives
  /// after the song has already changed can be discarded.
  String _lyricsKey = '';

  /// Ask Music Assistant for the playing track's lyrics.
  ///
  /// One lookup per track, not per metadata update: Sendspin sends progress
  /// constantly and only the title/artist pair matters here. A track with no
  /// lyrics is remembered as such by its key, so it is not asked for again
  /// every few seconds for the length of the song.
  Future<void> _refreshLyrics() async {
    if (!_settings.get(defs.sendspinLyrics)) {
      if (lyrics.value.isNotEmpty) lyrics.value = const [];
      _lyricsKey = '';
      return;
    }
    final title = '${_status['title'] ?? ''}';
    final artist = '${_status['artist'] ?? ''}';
    final key = '$artist|$title';
    if (key == _lyricsKey) return;
    _lyricsKey = key;
    lyrics.value = const [];
    if (title.isEmpty) return;
    final api = MusicAssistantApi(
      baseUrl: _settings.get(defs.sendspinMaUrl),
      token: _settings.get(defs.sendspinMaToken),
    );
    var lrc = await api.fetchLyrics(
      title: title,
      artist: artist,
      album: '${_status['album'] ?? ''}',
    );
    // The song may have moved on while Music Assistant was looking.
    if (_lyricsKey != key) return;
    var source = 'Music Assistant';
    if (lrc == null || lrc.trim().isEmpty) {
      // Music Assistant's providers found nothing — often strict matching
      // losing to a lyrics database's sloppy credits (issue #90). Ask
      // LRCLIB's own, looser search directly before giving up; the user's
      // local .lrc files stayed authoritative above.
      final durationMs = (_status['durationMs'] as num?)?.toInt() ?? 0;
      lrc = await LrclibApi().fetchSyncedLyrics(
        title: title,
        artist: artist,
        durationSeconds: durationMs > 0 ? (durationMs / 1000).round() : null,
      );
      if (_lyricsKey != key) return;
      source = 'LRCLIB';
    }
    final parsed = parseLrc(lrc);
    log.info(
      name,
      parsed.isEmpty
          ? 'no synced lyrics for $artist - $title'
          : 'lyrics for $artist - $title (${parsed.length} lines, $source)',
    );
    lyrics.value = parsed;
  }

  void _setNowPlaying(Map<String, Object?>? value) {
    final wasShowing = nowPlaying.value?['playing'] == true;
    nowPlaying.value = value;
    final showing = value?['playing'] == true;
    if (wasShowing != showing) {
      // The screensaver's motion policy tracks the full-screen display,
      // which only shows while actually playing.
      bus.publish(SendspinNowPlayingChanged(active: showing));
    }
  }

  void _publishNowPlaying() {
    final connected = _status['connected'] == true;
    final hasTrack = _status['title'] != null;
    if (_playing) {
      _idleGrace?.cancel();
      _idleGrace = null;
      _uiPlaying = true;
      _sawPlayback = true;
      _setNowPlaying({..._status, 'playing': true});
      return;
    }
    if (nowPlaying.value == null) {
      // Nothing shown yet: a track paused MID-SESSION still gets a card,
      // so playback paused elsewhere is resumable here. Requires having
      // actually played first — see _sawPlayback.
      if (connected && hasTrack && _sawPlayback) {
        _uiPlaying = false;
        _setNowPlaying({..._status, 'playing': false});
      }
      return;
    }
    // Something is on screen and playback just is not running: hold the
    // current look through a grace period. Track changes rebuild the
    // stream (a moment of "not playing" between stream/end and the next
    // stream/start); without the hold every song change flashed the
    // dashboard through the now-playing screensaver and the card.
    _setNowPlaying({..._status, 'playing': _uiPlaying});
    _idleGrace ??= Timer(const Duration(milliseconds: 2500), () {
      _idleGrace = null;
      if (_playing) return;
      _uiPlaying = false;
      final conn = _status['connected'] == true;
      final track = _status['title'] != null;
      if (conn && track) {
        // A real pause: the card stays, paused, ready to resume.
        _setNowPlaying({..._status, 'playing': false});
      } else {
        _setNowPlaying(null);
      }
    });
  }

  @override
  Future<void> init() async {
    var clientId = _settings.get(defs.sendspinClientId);
    if (clientId.isEmpty) {
      final rng = Random.secure();
      clientId = List.generate(
        32,
        (_) => rng.nextInt(16).toRadixString(16),
      ).join();
      await _settings.set(defs.sendspinClientId, clientId);
    }

    _channel.setMethodCallHandler((call) async {
      final args = call.arguments;
      final map = args is Map
          ? args.cast<String, Object?>()
          : const <String, Object?>{};
      switch (call.method) {
        case 'stateChanged':
          _status = {..._status, ...map};
          log.info(
            name,
            'state: connected=${map['connected']} '
            'server=${map['serverName']} synced=${map['synced']}',
          );
        case 'metadataChanged':
          // Metadata arrives as deltas: a progress-only update carries no
          // title, and the server may send literal "null" strings. Absent
          // fields must not clobber what an earlier message established.
          _status = {
            ..._status,
            for (final e in map.entries)
              if (e.value != null &&
                  '${e.value}' != 'null' &&
                  '${e.value}'.isNotEmpty)
                e.key: e.value,
            'receivedAt': DateTime.now().millisecondsSinceEpoch,
          };
        case 'volumeChanged':
          _status = {..._status, ...map};
          // A server-commanded media volume applied natively; persist it
          // into the media fader setting so the slider, the MQTT entity
          // and the next app start all agree. Equality-guarded: the echo
          // of our own setting push must not ping-pong.
          final vol = (map['volume'] as num?)?.toInt();
          if (vol != null && vol != _settings.get(defs.mediaVolume).toInt()) {
            unawaited(_settings.set(defs.mediaVolume, vol));
          }
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
                VoiceInteractionChanged(active: playing, reason: 'media'),
              );
            } else if (!playing) {
              bus.publish(
                const VoiceInteractionChanged(active: false, reason: 'media'),
              );
            }
          }
      }
      _publishNowPlaying();
      unawaited(_refreshLyrics());
      return null;
    });

    // Voice interactions (anything but media, which is playback itself,
    // ours included): hide the floating player and duck the audio so the
    // microphone hears the person, not the song.
    bus.on<VoiceInteractionChanged>().listen((e) {
      if (e.reason == 'media') return;
      if (e.active) {
        _voiceReasons.add(e.reason);
      } else {
        _voiceReasons.remove(e.reason);
      }
      final active = _voiceReasons.isNotEmpty;
      if (active == voiceActive.value) return;
      voiceActive.value = active;
      final factor = active
          ? _settings.get(defs.sendspinDuckPercent) / 100.0
          : 1.0;
      _channel.invokeMethod('duck', {'factor': factor}).catchError((_) {});
    });

    bus.on<SettingChanged>().listen((e) {
      // Only connection-shaping settings restart the client; the UI-only
      // ones (card visibility, size, position, fullscreen mode) must not
      // interrupt playback when toggled.
      // The sync offset applies live inside the running player: a slider
      // being tuned by ear must not restart the music it is tuned against.
      if (e.key == defs.sendspinSyncOffset.key) {
        unawaited(_channel.invokeMethod('setSyncOffset', {
          'ms': _settings.get(defs.sendspinSyncOffset).toInt(),
        }).catchError((_) {}));
        return;
      }
      const uiOnly = [
        'sendspin.show_player',
        'sendspin.player_size',
        'sendspin.player_pos',
        'sendspin.fullscreen',
        'sendspin.fullscreen_motion',
        'sendspin.duck_percent',
        'sendspin.paused_hide_minutes',
        'sendspin.dismiss_keeps_playing',
        // The lyric system lives on the Dart side and reads both of these
        // live (the fetch checks the toggle per track, the view reads the
        // offset every tick). An offset being tuned by ear must not restart
        // the music it is tuned against.
        'sendspin.lyrics',
        'sendspin.lyrics_offset',
      ];
      final relevant =
          e.key.startsWith('sendspin.') &&
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

    commands.register(
      Command(
        name: 'sendspinStatus',
        description:
            'The Sendspin player status: connection, server, playback state, '
            'current track and volume.',
        handler: (_) async {
          // The cached snapshot lags fields only re-sent on events (sync
          // state); the bridge computes them live.
          var live = const <String, Object?>{};
          try {
            live = ((await _channel.invokeMethod<Map>('getStatus')) ??
                    const {})
                .cast<String, Object?>();
          } catch (_) {}
          return CommandResult.ok({
            'enabled': _settings.get(defs.sendspinEnabled),
            'running': _running,
            'playing': _playing,
            ..._status,
            ...live,
          });
        },
      ),
    );

    commands.register(
      Command(
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
      ),
    );

    commands.register(
      Command(
        name: 'sendspinDiscover',
        description:
            'Scan the network for Sendspin servers (mDNS). Returns name, '
            'host, port and url per server found.',
        params: const {'timeoutMs': 'scan duration, default 3000'},
        handler: (p) async {
          try {
            final found = await _channel.invokeMethod<List<Object?>>(
              'discover',
              {'timeoutMs': (p['timeoutMs'] as num?)?.toInt() ?? 3000},
            );
            return CommandResult.ok(found ?? const []);
          } catch (e) {
            return CommandResult.fail('discovery failed: $e');
          }
        },
      ),
    );

    commands.register(
      Command(
        name: 'maValidate',
        description:
            "Check the Music Assistant address and token by opening its API "
            'and authenticating. Reports the server version on success.',
        handler: (_) async {
          final api = MusicAssistantApi(
            baseUrl: _settings.get(defs.sendspinMaUrl),
            token: _settings.get(defs.sendspinMaToken),
          );
          // 'auth' alone: it is the whole question being asked, and it needs
          // no scope, so a read-only token validates as happily as an admin
          // one.
          final result = await api.call('auth');
          if (!result.ok) {
            log.warn(name, 'Music Assistant validation failed: ${result.error}');
            return CommandResult.fail(result.error!);
          }
          final info = result.serverInfo;
          return CommandResult.ok({
            'version': info['server_version'],
            'schemaVersion': info['schema_version'],
            'name': info['name'],
          });
        },
      ),
    );

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
      return await _channel.invokeMethod<bool>('control', {
            'command': command,
          }) ??
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
        'syncOffsetMs': _settings.get(defs.sendspinSyncOffset).toInt(),
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
      bus.publish(
        const VoiceInteractionChanged(active: false, reason: 'media'),
      );
    }
    _status = const {};
    _idleGrace?.cancel();
    _idleGrace = null;
    _uiPlaying = false;
    _setNowPlaying(null);
  }
}
