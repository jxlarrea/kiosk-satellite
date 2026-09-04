import 'dart:async';
import 'dart:typed_data';

/// Small images kept by URL for a list that scrolls, bounded by bytes
/// rather than count: a queue of a thousand tracks must not grow this
/// past a few megabytes however far it is flung. Least recently used
/// goes first. A fetch that came back empty is remembered too, as a
/// null, so the row is not asked again every time it scrolls into view.
class ThumbCache {
  ThumbCache({this.maxBytes = 3 << 20});

  final int maxBytes;
  final _entries = <String, Uint8List?>{};
  int _bytes = 0;

  int get bytes => _bytes;
  int get length => _entries.length;

  bool contains(String url) => _entries.containsKey(url);

  /// The bytes for [url], moved to the back of the line; null for a
  /// miss and for an empty fetch alike, [contains] telling them apart.
  Uint8List? get(String url) {
    if (!_entries.containsKey(url)) return null;
    final bytes = _entries.remove(url);
    _entries[url] = bytes;
    return bytes;
  }

  void put(String url, Uint8List? bytes) {
    if (_entries.containsKey(url)) _bytes -= _entries.remove(url)?.length ?? 0;
    // A single image past the whole budget is not kept: it would evict
    // everything for one row.
    if (bytes != null && bytes.length > maxBytes) return;
    _entries[url] = bytes;
    _bytes += bytes?.length ?? 0;
    while (_bytes > maxBytes && _entries.isNotEmpty) {
      final oldest = _entries.keys.first;
      _bytes -= _entries.remove(oldest)?.length ?? 0;
    }
  }

  void clear() {
    _entries.clear();
    _bytes = 0;
  }
}

/// Fetches for a scrolling list, a few at a time: a fling through a long
/// queue asks for a row's image the moment the row is built, and without
/// this every one of them opened a connection at once. Callers that no
/// longer need their answer withdraw before their turn comes.
class FetchLane {
  FetchLane({this.width = 4});

  /// How many fetches run at once.
  final int width;
  final _waiting = <_Fetch>[];
  var _running = 0;

  int get pending => _waiting.length;
  int get running => _running;

  /// Run [work] when a slot frees. The returned handle cancels the wait;
  /// a fetch already running finishes on its own.
  FetchTicket schedule(Future<void> Function() work) {
    final fetch = _Fetch(work);
    _waiting.add(fetch);
    _pump();
    return FetchTicket._(() => _waiting.remove(fetch));
  }

  void _pump() {
    while (_running < width && _waiting.isNotEmpty) {
      final next = _waiting.removeAt(0);
      _running++;
      unawaited(
        next.work().whenComplete(() {
          _running--;
          _pump();
        }),
      );
    }
  }
}

class _Fetch {
  _Fetch(this.work);
  final Future<void> Function() work;
}

/// A place in a [FetchLane]'s line.
class FetchTicket {
  FetchTicket._(this._withdraw);
  final bool Function() _withdraw;

  /// Leave the line; false when the fetch already started.
  bool cancel() => _withdraw();
}
