import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../notifications/notification_sounds.dart';
import '../settings/settings_manager.dart';
import 'sound_capture.dart';

/// Page-delegated sound playback (Voice Satellite chimes and TTS).
///
/// The page hands over a URL; playback is native, so it honors the speaker
/// selection and needs no autoplay gesture. Lifecycle comes back as wire
/// events the page can await: `sound-started` when audio actually begins,
/// `sound-ended` exactly once when it finishes, fails, or is stopped.
///
/// Two transports, chosen by the caller:
///  - Download (`cache` optional): the file is fetched here - through the
///    app's HTTP stack, which already trusts the user's self-signed HA
///    certificate - and played from disk. `cache: true` keeps it (chimes,
///    small and static, worth instant replays); otherwise it is deleted
///    when the sound ends.
///  - Stream (`stream: true`): for TTS, which Home Assistant serves while
///    still synthesizing - waiting for the whole file would delay speech by
///    the synthesis tail. The native player instead pulls from a loopback
///    relay here, which pipes the remote response through as it arrives
///    (same certificate story as downloads).
class SoundManager extends Manager {
  SoundManager(super.bus, super.commands, super.log, {this.settings});

  final SettingsManager? settings;
  int _previewGeneration = 0;
  int _refreshGeneration = 0;
  StreamSubscription<SettingChanged>? _settingsSub;
  final _voiceDurations = <String, (int, int, double)>{};
  static const _voiceDefaults = <String, double>{
    'wake': 0.29,
    'done': 0.29,
    'error': 0.19,
    'alert': 0.63,
    'announce': 1.0,
  };

  static String? voiceChimeKind(String url) {
    final path = Uri.tryParse(url)?.path;
    final match = RegExp(
      r'^/voice_satellite/sounds/(wake|done|error|alert|announce)\.mp3$',
    ).firstMatch(path ?? '');
    return match?.group(1);
  }

  Future<double?> _voiceDuration(String source) async {
    final stat = await File(source).stat();
    final cached = _voiceDurations[source];
    if (cached != null &&
        cached.$1 == stat.size &&
        cached.$2 == stat.modified.microsecondsSinceEpoch) {
      return cached.$3;
    }
    try {
      final duration = await _channel.invokeMethod<num>('duration', {
        'source': source,
      });
      if (duration != null && duration.isFinite && duration > 0) {
        final seconds = duration.toDouble();
        _voiceDurations[source] = (
          stat.size,
          stat.modified.microsecondsSinceEpoch,
          seconds,
        );
        return seconds;
      }
    } catch (e) {
      log.warn(name, 'Cannot read chime duration: $e');
    }
    return null;
  }

  Future<(String, double)> _voiceChime(String kind) async {
    final def = voiceChimeSettings[kind]!;
    final custom = await NotificationSounds.resolve(settings?.get(def) ?? '');
    if (custom != null) {
      final duration = await _voiceDuration(custom);
      if (duration != null) return (custom, duration);
      log.warn(name, 'Unreadable $kind chime, using the bundled sound');
    }
    final asset = kind == 'alert' ? 'timer-alert' : 'voice-$kind';
    final source = await _bundled('assets/sounds/$asset.mp3');
    return (source, await _voiceDuration(source) ?? _voiceDefaults[kind]!);
  }

  Future<Map<String, double>> _refreshVoiceChimes() async {
    final generation = ++_refreshGeneration;
    final durations = <String, double>{};
    for (final kind in voiceChimeSettings.keys) {
      durations['$kind.mp3'] = (await _voiceChime(kind)).$2;
    }
    if (generation == _refreshGeneration) {
      bus.publish(VoiceChimesChanged(durations));
    }
    return durations;
  }

  static const _channel = MethodChannel('kiosk_satellite/sound');

  /// Play an audio file the app wrote itself (the wake word tester's
  /// playback, a diagnostics clip) at the speaker's own volume, outside the
  /// assistant fader. [SoundEnded] with [id] fires when it is over. False
  /// when the native player refused it.
  Future<bool> playFile(String id, String path) async =>
      await _channel.invokeMethod<bool>('play', {
        'id': id,
        'source': path,
        'volume': 1.0,
        'absolute': true,
      }) ==
      true;

  /// Stop a sound started by [playFile].
  Future<void> stopFile(String id) =>
      _channel.invokeMethod<void>('stop', {'id': id});

  /// The chime that announces a notification pushed from Home Assistant
  /// (see NotificationManager).
  static const _notificationChime = 'assets/sounds/notification.ogg';

  @override
  String get name => 'sound';

  /// url -> local file path, for cache:true fetches.
  final _cached = <String, String>{};

  /// asset key -> the copy of it on disk (see [_bundled]).
  final _assets = <String, String>{};

  /// id -> temp file path to delete when the sound ends (cache:false).
  final _ephemeral = <String, String>{};

  /// Loopback relay for stream plays: token -> upstream URL, id -> token.
  HttpServer? _relay;
  final _relayTargets = <String, _SoundRelayTarget>{};
  final _streamTokens = <String, String>{};
  bool _captureArmed = false;
  SoundCapture? _capture;
  String? _diagnosticReplayId;

  int _nextId = 0;

  @override
  Future<void> init() async {
    _channel.setMethodCallHandler((call) async {
      final args = (call.arguments as Map).cast<String, Object?>();
      final id = '${args['id']}';
      switch (call.method) {
        case 'diagnostic':
          log.debug(name, 'sound $id: ${args['message']}');
        case 'started':
          bus.publish(SoundStarted(id: id));
        case 'level':
          bus.publish(
            SoundLevel(id: id, level: (args['level'] as num?)?.toDouble() ?? 0),
          );
        case 'ended':
          final error = args['error'] as String?;
          if (_diagnosticReplayId == id) _diagnosticReplayId = null;
          if (_capture?.id == id) {
            _capture!
              ..playbackEnded = true
              ..playbackError = error;
          }
          if (error != null) log.warn(name, 'sound $id failed: $error');
          final stale = _ephemeral.remove(id);
          if (stale != null) {
            try {
              await File(stale).delete();
            } catch (_) {}
          }
          final token = _streamTokens.remove(id);
          if (token != null) _relayTargets.remove(token);
          bus.publish(SoundEnded(id: id, error: error));
      }
      return null;
    });

    _settingsSub = bus.on<SettingChanged>().listen((event) {
      if (voiceChimeSettings.values.any((def) => def.key == event.key)) {
        unawaited(
          _refreshVoiceChimes().catchError((Object error) {
            log.warn(name, 'Cannot refresh voice chimes: $error');
            return <String, double>{};
          }),
        );
      }
    });
    commands
      ..register(
        Command(
          name: 'getVoiceChimeDurations',
          description:
              'Read the durations of the Voice Satellite chimes on this kiosk.',
          handler: (_) async => CommandResult.ok(await _refreshVoiceChimes()),
        ),
      )
      ..register(
        Command(
          name: 'previewVoiceChime',
          description:
              'Preview a selected Voice Satellite chime on this kiosk.',
          params: const {'kind': 'wake, done, error, alert or announce'},
          handler: (p) async {
            final kind = p['kind'];
            if (kind is! String || !voiceChimeSettings.containsKey(kind)) {
              return const CommandResult.fail('Unknown chime');
            }
            final generation = ++_previewGeneration;
            final source = (await _voiceChime(kind)).$1;
            if (generation != _previewGeneration) {
              return const CommandResult.ok();
            }
            final ok = await _channel.invokeMethod<bool>('play', {
              'id': 'voice-preview',
              'source': source,
              'volume': 1.0,
            });
            return ok == true
                ? const CommandResult.ok()
                : const CommandResult.fail('Playback failed');
          },
        ),
      )
      ..register(
        Command(
          name: 'soundDiagnostics',
          description:
              'Capture the next streamed sound in memory for diagnosis, '
              'inspect it or replay its exact bytes through Android ExoPlayer',
          quiet: true,
          params: const {
            'action': 'arm, status (default), export, replay or clear',
            'decoder': 'default or software for replay (default: default)',
            'volume':
                '0..1 for replay, relative to assistant volume (default 1)',
          },
          handler: _soundDiagnostics,
        ),
      )
      ..register(
        Command(
          name: 'playSound',
          description:
              'Play a sound natively (honors the speaker selection, no '
              'autoplay gate). Resolves {id}; sound-started fires when audio '
              'begins and sound-ended exactly once when it finishes.',
          params: const {
            'url': 'absolute URL of the audio file',
            'volume': '0..1, relative to the assistant volume (default 1)',
            'cache': 'keep the download for instant replays (default false)',
            'stream':
                'play while downloading, for sources still being generated '
                '(TTS); cache is ignored (default false)',
          },
          handler: (p) async {
            final url = p['url'] as String?;
            if (url == null || url.isEmpty) {
              return const CommandResult.fail('url required');
            }
            final id = 'snd${++_nextId}';
            final String source;
            final chime = voiceChimeKind(url);
            if (chime != null) {
              source = (await _voiceChime(chime)).$1;
            } else if (p['stream'] == true) {
              try {
                source = await _relayUrlFor(id, url);
              } catch (e) {
                return CommandResult.fail('sound relay failed: $e');
              }
            } else {
              final cache = p['cache'] == true;
              try {
                source = await _fetch(url, cache: cache);
              } catch (e) {
                return CommandResult.fail('sound fetch failed: $e');
              }
              if (!cache) _ephemeral[id] = source;
            }
            final ok = await _channel.invokeMethod<bool>('play', {
              'id': id,
              'source': source,
              'volume': (p['volume'] as num?)?.toDouble() ?? 1.0,
            });
            if (ok != true) {
              _ephemeral.remove(id);
              final token = _streamTokens.remove(id);
              if (token != null) _relayTargets.remove(token);
              return const CommandResult.fail('native playback failed');
            }
            return CommandResult.ok({'id': id});
          },
        ),
      )
      ..register(
        Command(
          name: 'prefetchSound',
          description:
              'Warm the sound cache for a URL so the first playSound of it '
              'starts instantly',
          params: const {'url': 'absolute URL of the audio file'},
          handler: (p) async {
            final url = p['url'] as String?;
            if (url == null || url.isEmpty) {
              return const CommandResult.fail('url required');
            }
            try {
              final kind = voiceChimeKind(url);
              if (kind != null) {
                await _voiceChime(kind);
              } else {
                await _fetch(url, cache: true);
              }
              return const CommandResult.ok();
            } catch (e) {
              return CommandResult.fail('sound fetch failed: $e');
            }
          },
        ),
      )
      ..register(
        Command(
          name: 'playTimerChime',
          description: 'Play the selected Voice Satellite timer alert locally.',
          handler: (_) async {
            final id = 'timer${++_nextId}';
            final source = (await _voiceChime('alert')).$1;
            final ok = await _channel.invokeMethod<bool>('play', {
              'id': id,
              'source': source,
              'volume': 1.0,
            });
            return ok == true
                ? CommandResult.ok({'id': id})
                : const CommandResult.fail('native playback failed');
          },
        ),
      )
      ..register(
        Command(
          name: 'playChime',
          description:
              'Play the notification chime natively (honors the speaker '
              'selection). Its volume stands apart from the assistant and '
              'media faders: a notification is neither.',
          params: const {
            'source':
                'the path of a sound file on the device to play instead of '
                'the bundled chime; empty or missing falls through',
            'fallback': 'a second such path, tried when the first is missing',
            'volume': '0..1, absolute (default 1)',
          },
          handler: (p) async {
            final String source;
            try {
              source = await _chimeSource([p['source'], p['fallback']]);
            } catch (e) {
              return CommandResult.fail('chime unavailable: $e');
            }
            final ok = await _channel.invokeMethod<bool>('play', {
              'id': 'chime${++_nextId}',
              'source': source,
              'volume': (p['volume'] as num?)?.toDouble() ?? 1.0,
              'absolute': true,
            });
            return ok == true
                ? const CommandResult.ok()
                : const CommandResult.fail('native playback failed');
          },
        ),
      )
      ..register(
        Command(
          name: 'stopSound',
          description: 'Stop a playing sound by its playSound id',
          params: const {'id': 'id returned by playSound'},
          handler: (p) async {
            if (p['id'] == 'voice-preview') _previewGeneration++;
            await _channel.invokeMethod<void>('stop', {'id': '${p['id']}'});
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'setSoundVolume',
          description:
              'Change the volume of a playing sound (the page applies live '
              'volume changes mid-utterance, matching browser audio)',
          params: const {
            'id': 'id returned by playSound',
            'volume': '0..1, relative to media volume',
          },
          handler: (p) async {
            await _channel.invokeMethod<void>('setVolume', {
              'id': '${p['id']}',
              'volume': (p['volume'] as num?)?.toDouble() ?? 1.0,
            });
            return const CommandResult.ok();
          },
        ),
      );
  }

  Future<CommandResult> _soundDiagnostics(Map<String, Object?> p) async {
    final capture = _capture;
    switch (p['action'] ?? 'status') {
      case 'arm':
        capture?.discard('Replaced by a new capture');
        _capture = null;
        _captureArmed = true;
        log.info(
          name,
          'Capture armed for the next streamed sound (8 MiB limit)',
        );
        return const CommandResult.ok({'armed': true});
      case 'clear':
        _captureArmed = false;
        capture?.discard('Capture cleared');
        _capture = null;
        return const CommandResult.ok({'armed': false});
      case 'status':
        return CommandResult.ok({
          'armed': _captureArmed,
          'capture': capture?.status,
          'replayId': _diagnosticReplayId,
        });
      case 'export':
        if (capture == null || !capture.ready) {
          return const CommandResult.fail('No complete capture available');
        }
        return CommandResult.ok({
          ...capture.status,
          'base64': base64Encode(capture.audio),
        });
      case 'replay':
        if (_diagnosticReplayId != null) {
          return const CommandResult.fail(
            'A diagnostic replay is still active',
          );
        }
        if (capture == null || !capture.ready || !capture.playbackEnded) {
          return const CommandResult.fail(
            'Wait for a complete capture and the original playback to end',
          );
        }
        final decoder = p['decoder'] ?? 'default';
        if (decoder != 'default' && decoder != 'software') {
          return const CommandResult.fail(
            'decoder must be default or software',
          );
        }
        final id = 'snd${++_nextId}';
        final bytes = capture.audio;
        _diagnosticReplayId = id;
        File? file;
        try {
          final dir = await getTemporaryDirectory();
          file = File('${dir.path}/ks_sound_capture_$id');
          await file.writeAsBytes(bytes, flush: true);
          _ephemeral[id] = file.path;
          final ok = await _channel.invokeMethod<bool>('playDiagnostic', {
            'id': id,
            'source': file.path,
            'volume': (p['volume'] as num?)?.toDouble() ?? 1.0,
            // Local files normally use the short-clip path. Both comparison
            // runs must use the same ExoPlayer path as streamed TTS.
            'exoDecoder': decoder,
          });
          if (ok != true) throw StateError('Native replay refused');
        } catch (_) {
          if (_diagnosticReplayId == id) _diagnosticReplayId = null;
          _ephemeral.remove(id);
          if (file != null && await file.exists()) await file.delete();
          rethrow;
        }
        log.info(
          name,
          'Replaying capture ${capture.id} as $id decoder=$decoder',
        );
        return CommandResult.ok({'id': id, 'captureId': capture.id});
      default:
        return const CommandResult.fail('Unknown sound diagnostics action');
    }
  }

  /// The first of [candidates] that exists on disk, the bundled chime when
  /// none does. Files only, and local ones: the notification sounds live
  /// in a folder on the device (NotificationSounds), and the native clip
  /// cache keyed on path and mtime makes every play after the first
  /// instant. A miss is logged so a name that resolved a moment ago and
  /// vanished since still leaves a trace.
  Future<String> _chimeSource(List<Object?> candidates) async {
    for (final candidate in candidates) {
      final source = '${candidate ?? ''}'.trim();
      if (source.isEmpty) continue;
      if (File(source).existsSync()) return source;
      log.warn(name, 'chime file $source is missing, falling back');
    }
    return _bundled(_notificationChime);
  }

  /// Copies a bundled sound out of the APK once and returns its path. The
  /// native player opens files, not asset handles, and a short local file
  /// is exactly what its decoded-PCM path is for (no MediaPlayer stall).
  Future<String> _bundled(String asset) async {
    final hit = _assets[asset];
    if (hit != null && File(hit).existsSync()) return hit;
    final data = await rootBundle.load(asset);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ks_${asset.split('/').last}');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    _assets[asset] = file.path;
    return file.path;
  }

  Future<String> _fetch(String url, {required bool cache}) async {
    final hit = cache ? _cached[url] : null;
    if (hit != null && File(hit).existsSync()) return hit;
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/ks_sound_${url.hashCode.toRadixString(16)}'
      '${cache ? '' : '_${++_nextId}'}',
    );
    await file.writeAsBytes(response.bodyBytes, flush: true);
    if (cache) _cached[url] = file.path;
    return file.path;
  }

  /// Register [url] under a one-shot token and return the loopback address
  /// the native player streams it from.
  Future<String> _relayUrlFor(String id, String url) async {
    final relay = _relay ??= await _startRelay();
    final token = 'r${++_nextId}';
    SoundCapture? capture;
    if (_captureArmed) {
      _captureArmed = false;
      capture = _capture = SoundCapture(id);
    }
    _relayTargets[token] = _SoundRelayTarget(id, url, capture);
    _streamTokens[id] = token;
    return 'http://127.0.0.1:${relay.port}/s/$token';
  }

  Future<HttpServer> _startRelay() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(
      _handleRelay,
      onError: (Object e) {
        log.warn(name, 'sound relay error: $e');
      },
    );
    log.info(name, 'sound relay on 127.0.0.1:${server.port}');
    return server;
  }

  Future<void> _handleRelay(HttpRequest req) async {
    final segments = req.uri.pathSegments;
    final target = segments.length == 2 && segments[0] == 's'
        ? _relayTargets[segments[1]]
        : null;
    if (target == null) {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
      return;
    }
    final client = HttpClient();
    final elapsed = Stopwatch()..start();
    var bytes = 0;
    // ExoPlayer may retry a request. Keep one response per capture, never
    // append a second response to the first clip.
    final capture = target.captureClaimed ? null : target.capture;
    target.captureClaimed = true;
    log.debug(name, 'sound ${target.id}: HTTP request started');
    try {
      final out = await client.getUrl(Uri.parse(target.url));
      final upstream = await out.close();
      final res = req.response;
      res.statusCode = upstream.statusCode;
      final type = upstream.headers.contentType;
      if (type != null) res.headers.contentType = type;
      capture
        ?..statusCode = upstream.statusCode
        ..contentType = type?.toString();
      log.debug(
        name,
        'sound ${target.id}: HTTP headers '
        'status=${upstream.statusCode} length=${upstream.contentLength} '
        'type=$type elapsed=${elapsed.elapsedMilliseconds}ms',
      );
      // Chunked passthrough, no length: the upstream is typically still
      // being synthesized, and the player reads until the stream closes.
      await res.addStream(
        upstream.transform(
          StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (chunk, sink) {
              if (bytes == 0) {
                log.debug(
                  name,
                  'sound ${target.id}: HTTP first bytes '
                  'elapsed=${elapsed.elapsedMilliseconds}ms',
                );
              }
              bytes += chunk.length;
              capture?.add(chunk);
              sink.add(chunk);
            },
            handleDone: (sink) {
              // Only the upstream's end event proves EOF. A downstream
              // cancellation must not make a partial capture replayable.
              if (capture != null) capture.httpComplete = true;
              log.debug(
                name,
                'sound ${target.id}: HTTP upstream complete '
                'bytes=$bytes elapsed=${elapsed.elapsedMilliseconds}ms',
              );
              sink.close();
            },
          ),
        ),
      );
      await res.close();
      log.debug(name, 'sound ${target.id}: HTTP relay closed');
    } catch (e) {
      capture?.discard('HTTP transfer failed');
      log.warn(
        name,
        'sound ${target.id}: HTTP relay failed '
        'bytes=$bytes elapsed=${elapsed.elapsedMilliseconds}ms: $e',
      );
      try {
        req.response.statusCode = HttpStatus.badGateway;
      } catch (_) {}
      try {
        await req.response.close();
      } catch (_) {}
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> dispose() async {
    await _settingsSub?.cancel();
    _captureArmed = false;
    _capture?.discard('Sound manager disposed');
    _capture = null;
    await _relay?.close(force: true);
    _relay = null;
  }
}

class _SoundRelayTarget {
  _SoundRelayTarget(this.id, this.url, this.capture);

  final String id;
  final String url;
  final SoundCapture? capture;
  bool captureClaimed = false;
}
