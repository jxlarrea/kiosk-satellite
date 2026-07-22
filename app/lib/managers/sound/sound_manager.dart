import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';

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
  SoundManager(super.bus, super.commands, super.log);

  static const _channel = MethodChannel('kiosk_satellite/sound');

  @override
  String get name => 'sound';

  /// url -> local file path, for cache:true fetches.
  final _cached = <String, String>{};

  /// id -> temp file path to delete when the sound ends (cache:false).
  final _ephemeral = <String, String>{};

  /// Loopback relay for stream plays: token -> upstream URL, id -> token.
  HttpServer? _relay;
  final _relayTargets = <String, String>{};
  final _streamTokens = <String, String>{};

  int _nextId = 0;

  @override
  Future<void> init() async {
    _channel.setMethodCallHandler((call) async {
      final args = (call.arguments as Map).cast<String, Object?>();
      final id = '${args['id']}';
      switch (call.method) {
        case 'started':
          bus.publish(SoundStarted(id: id));
        case 'level':
          bus.publish(SoundLevel(
            id: id,
            level: (args['level'] as num?)?.toDouble() ?? 0,
          ));
        case 'ended':
          final error = args['error'] as String?;
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

    commands
      ..register(Command(
        name: 'playSound',
        description:
            'Play a sound natively (honors the speaker selection, no '
            'autoplay gate). Resolves {id}; sound-started fires when audio '
            'begins and sound-ended exactly once when it finishes.',
        params: const {
          'url': 'absolute URL of the audio file',
          'volume': '0..1, relative to media volume (default 1)',
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
          if (p['stream'] == true) {
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
      ))
      ..register(Command(
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
            await _fetch(url, cache: true);
            return const CommandResult.ok();
          } catch (e) {
            return CommandResult.fail('sound fetch failed: $e');
          }
        },
      ))
      ..register(Command(
        name: 'stopSound',
        description: 'Stop a playing sound by its playSound id',
        params: const {'id': 'id returned by playSound'},
        handler: (p) async {
          await _channel.invokeMethod<void>('stop', {'id': '${p['id']}'});
          return const CommandResult.ok();
        },
      ));
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
    _relayTargets[token] = url;
    _streamTokens[id] = token;
    return 'http://127.0.0.1:${relay.port}/s/$token';
  }

  Future<HttpServer> _startRelay() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(_handleRelay, onError: (Object e) {
      log.warn(name, 'sound relay error: $e');
    });
    log.info(name, 'sound relay on 127.0.0.1:${server.port}');
    return server;
  }

  Future<void> _handleRelay(HttpRequest req) async {
    final segments = req.uri.pathSegments;
    final target =
        segments.length == 2 && segments[0] == 's' ? _relayTargets[segments[1]] : null;
    if (target == null) {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
      return;
    }
    final client = HttpClient();
    try {
      final out = await client.getUrl(Uri.parse(target));
      final upstream = await out.close();
      final res = req.response;
      res.statusCode = upstream.statusCode;
      final type = upstream.headers.contentType;
      if (type != null) res.headers.contentType = type;
      // Chunked passthrough, no length: the upstream is typically still
      // being synthesized, and the player reads until the stream closes.
      await res.addStream(upstream);
      await res.close();
    } catch (e) {
      log.warn(name, 'sound relay failed for $target: $e');
      try {
        req.response.statusCode = HttpStatus.badGateway;
        await req.response.close();
      } catch (_) {}
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> dispose() async {
    await _relay?.close(force: true);
    _relay = null;
  }
}
