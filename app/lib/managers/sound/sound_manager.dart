import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';

/// Page-delegated sound playback (Voice Satellite chimes; TTS later).
///
/// The page hands over a URL; this manager fetches it here - through the
/// app's HTTP stack, which already trusts the user's self-signed HA
/// certificate - and hands a local file to the native player, which honors
/// the speaker selection and needs no autoplay gesture. Completion comes
/// back as a `sound-ended` wire event the page can await.
///
/// Caching is per-URL and opt-in (`cache: true`): chimes are small static
/// files worth keeping warm so replays start instantly; TTS URLs are
/// one-shot and would only pile files up, so uncached downloads are deleted
/// when their sound ends.
class SoundManager extends Manager {
  SoundManager(super.bus, super.commands, super.log);

  static const _channel = MethodChannel('kiosk_satellite/sound');

  @override
  String get name => 'sound';

  /// url -> local file path, for cache:true fetches.
  final _cached = <String, String>{};

  /// id -> temp file path to delete when the sound ends (cache:false).
  final _ephemeral = <String, String>{};

  int _nextId = 0;

  @override
  Future<void> init() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'ended') {
        final args = (call.arguments as Map).cast<String, Object?>();
        final id = '${args['id']}';
        final error = args['error'] as String?;
        if (error != null) log.warn(name, 'sound $id failed: $error');
        final stale = _ephemeral.remove(id);
        if (stale != null) {
          try {
            await File(stale).delete();
          } catch (_) {}
        }
        bus.publish(SoundEnded(id: id, error: error));
      }
      return null;
    });

    commands
      ..register(Command(
        name: 'playSound',
        description:
            'Play a sound natively (honors the speaker selection, no '
            'autoplay gate). Fetches the URL app-side, resolves {id}; a '
            'sound-ended event follows when it finishes.',
        params: const {
          'url': 'absolute URL of the audio file',
          'volume': '0..1, relative to media volume (default 1)',
          'cache': 'keep the download for instant replays (default false)',
        },
        handler: (p) async {
          final url = p['url'] as String?;
          if (url == null || url.isEmpty) {
            return const CommandResult.fail('url required');
          }
          final cache = p['cache'] == true;
          final String path;
          try {
            path = await _fetch(url, cache: cache);
          } catch (e) {
            return CommandResult.fail('sound fetch failed: $e');
          }
          final id = 'snd${++_nextId}';
          if (!cache) _ephemeral[id] = path;
          final ok = await _channel.invokeMethod<bool>('play', {
            'id': id,
            'path': path,
            'volume': (p['volume'] as num?)?.toDouble() ?? 1.0,
          });
          if (ok != true) {
            _ephemeral.remove(id);
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
}
