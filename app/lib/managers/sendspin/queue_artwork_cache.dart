import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../ui/thumb_cache.dart';

/// Queue covers stored as small images in the app's disposable cache.
/// Filenames contain only a hash of the URL. Disk work is serialized so
/// reads, eviction and clearing cannot race one another.
class QueueArtworkCache {
  QueueArtworkCache({
    this.maxBytes = 100 << 20,
    this.maxEntries = 4096,
    Future<Directory?> Function()? directory,
    Future<Uint8List?> Function(Uint8List)? prepare,
  }) : _directoryProvider = directory ?? _defaultDirectory,
       _prepare = prepare ?? thumbnail;

  final int maxBytes;
  final int maxEntries;
  final memory = ThumbCache();
  final Future<Directory?> Function() _directoryProvider;
  final Future<Uint8List?> Function(Uint8List) _prepare;
  final _entries = <String, int>{};
  Directory? _directory;
  bool _ready = false;
  int _bytes = 0;
  int _generation = 0;
  Future<void> _disk = Future.value();

  static Future<Directory> _defaultDirectory() async =>
      Directory('${(await getTemporaryDirectory()).path}/queue-artwork-v1');

  Future<T> _serial<T>(Future<T> Function() work) {
    final result = _disk.then((_) => work());
    _disk = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  String _key(String url) => sha256.convert(utf8.encode(url)).toString();
  File _file(String key) => File('${_directory!.path}/$key.png');

  Future<void> _init() async {
    if (_ready) return;
    final dir = await _directoryProvider();
    if (dir == null) {
      _ready = true;
      return;
    }
    await dir.create(recursive: true);
    final found = <(String, FileStat)>[];
    await for (final file in dir.list(followLinks: false)) {
      if (file is! File) continue;
      final name = file.uri.pathSegments.last;
      if (name.endsWith('.part')) {
        await file.delete();
        continue;
      }
      if (!RegExp(r'^[a-f0-9]{64}\.png$').hasMatch(name)) continue;
      final stat = await file.stat();
      if (stat.size == 0 || stat.size > maxBytes) {
        await file.delete();
      } else {
        found.add((name.substring(0, 64), stat));
      }
    }
    found.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    _directory = dir;
    _entries.clear();
    _bytes = 0;
    for (final (key, stat) in found) {
      _entries[key] = stat.size;
      _bytes += stat.size;
    }
    await _evict();
    _ready = true;
  }

  Future<void> _evict() async {
    while (_bytes > maxBytes || _entries.length > maxEntries) {
      final key = _entries.keys.first;
      final file = _file(key);
      if (await file.exists()) await file.delete();
      _bytes -= _entries.remove(key)!;
    }
  }

  /// Network and image preparation stay outside the disk lock. Clearing
  /// invalidates this load even while it waits for either of them.
  Future<Uint8List?> load(
    String url,
    Future<Uint8List?> Function() fetch, {
    bool Function()? cancelled,
  }) async {
    if (url.isEmpty) return null;
    final generation = _generation;
    bool valid() => generation == _generation && !(cancelled?.call() ?? false);
    final cached = memory.get(url);
    if (cached != null) return cached;
    final key = _key(url);
    Uint8List? bytes;
    try {
      bytes = await _serial(() async {
        await _init();
        if (!valid() || !_entries.containsKey(key)) return null;
        final file = _file(key);
        try {
          final data = await file.readAsBytes();
          // A truncated file is a miss. Writes are atomic, but Android
          // can reclaim cache files independently of this process.
          if (data.length != _entries[key] || !isPng(data)) {
            if (await file.exists()) await file.delete();
            _bytes -= _entries.remove(key)!;
            return null;
          }
          final size = _entries.remove(key)!;
          _entries[key] = size;
          await file.setLastModified(DateTime.now());
          return data;
        } on FileSystemException {
          _bytes -= _entries.remove(key) ?? 0;
          return null;
        }
      });
    } catch (_) {
      // A full or unavailable cache must not prevent artwork from loading.
    }
    if (!valid()) return null;
    if (bytes == null) {
      final original = await fetch();
      if (!valid() || original == null || original.isEmpty) return null;
      bytes = await _prepare(original);
      if (!valid() || bytes == null) return null;
      final data = bytes;
      try {
        await _serial(() async {
          await _init();
          if (!valid() || _directory == null || data.length > maxBytes) return;
          await _directory!.create(recursive: true);
          final temporary = File('${_file(key).path}.part');
          await temporary.writeAsBytes(data, flush: true);
          if (!valid()) {
            await temporary.delete();
            return;
          }
          await temporary.rename(_file(key).path);
          _bytes -= _entries.remove(key) ?? 0;
          _entries[key] = data.length;
          _bytes += data.length;
          await _evict();
        });
      } catch (_) {}
    }
    if (!valid()) return null;
    memory.put(url, bytes);
    return bytes;
  }

  Future<Map<String, Object?>> stats() => _serial(() async {
    await _init();
    // Count actual files so space reclaimed by the OS is reflected too.
    if (_directory != null) {
      for (final key in _entries.keys.toList()) {
        final stat = await _file(key).stat();
        if (stat.type != FileSystemEntityType.file) {
          _bytes -= _entries.remove(key)!;
        }
      }
    }
    return {'bytes': _bytes, 'items': _entries.length, 'maxBytes': maxBytes};
  });

  Future<void> clear() {
    _generation++;
    memory.clear();
    return _serial(() async {
      await _init();
      final directory = _directory;
      if (directory != null && await directory.exists()) {
        await directory.delete(recursive: true);
      }
      _entries.clear();
      _bytes = 0;
    });
  }

  static bool isPng(Uint8List bytes) =>
      bytes.length >= 8 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71 &&
      bytes[4] == 13 &&
      bytes[5] == 10 &&
      bytes[6] == 26 &&
      bytes[7] == 10;

  /// Decode only a thumbnail-sized frame with the platform codec. The
  /// image keeps its aspect ratio and alpha without a full-size bitmap.
  static Future<Uint8List?> thumbnail(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        final scale = math.min(
          1.0,
          256 / math.max(descriptor.width, descriptor.height),
        );
        final codec = await descriptor.instantiateCodec(
          targetWidth: math.max(1, (descriptor.width * scale).round()),
          targetHeight: math.max(1, (descriptor.height * scale).round()),
        );
        try {
          final frame = await codec.getNextFrame();
          try {
            final data = await frame.image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            return data?.buffer.asUint8List(
              data.offsetInBytes,
              data.lengthInBytes,
            );
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
      }
    } catch (_) {
      return null;
    } finally {
      buffer.dispose();
    }
  }
}
