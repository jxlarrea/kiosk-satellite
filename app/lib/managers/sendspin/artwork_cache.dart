import 'dart:typed_data';

/// Shares encoded covers and in-flight downloads between Now Playing surfaces.
/// Both byte and entry limits apply, including very small images.
class ArtworkCache {
  ArtworkCache({this.maxBytes = 8 << 20, this.maxEntries = 16});

  final int maxBytes;
  final int maxEntries;
  final _entries = <String, Uint8List>{};
  final _pending = <String, Future<Uint8List?>>{};
  int _bytes = 0;

  int get bytes => _bytes;
  int get length => _entries.length;

  Future<Uint8List?> load(
    String url,
    Future<Uint8List?> Function(String) fetch,
  ) {
    if (url.isEmpty) return Future.value(null);
    final cached = _entries.remove(url);
    if (cached != null) {
      _entries[url] = cached;
      return Future.value(cached);
    }
    return _pending.putIfAbsent(url, () async {
      try {
        final image = await Future<Uint8List?>.sync(() => fetch(url));
        if (image != null && image.isNotEmpty && image.length <= maxBytes) {
          _entries[url] = image;
          _bytes += image.length;
          while (_bytes > maxBytes || _entries.length > maxEntries) {
            _bytes -= _entries.remove(_entries.keys.first)!.length;
          }
        }
        return image;
      } finally {
        _pending.remove(url);
      }
    });
  }
}
