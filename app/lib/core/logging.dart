import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class LogEntry {
  LogEntry(this.time, this.level, this.tag, this.message);

  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  Map<String, Object?> toJson() => {
        'time': time.toIso8601String(),
        'level': level.name,
        'tag': tag,
        'message': message,
      };
}

/// Ring-buffer logger. The remote UI tails [stream] over its WebSocket and
/// fetches [recent] on connect.
class Logger {
  static const _capacity = 500;

  final _buffer = ListQueue<LogEntry>(_capacity);
  final _controller = StreamController<LogEntry>.broadcast();

  Stream<LogEntry> get stream => _controller.stream;
  List<LogEntry> get recent => _buffer.toList(growable: false);

  void debug(String tag, String message) => _add(LogLevel.debug, tag, message);
  void info(String tag, String message) => _add(LogLevel.info, tag, message);
  void warn(String tag, String message) => _add(LogLevel.warn, tag, message);
  void error(String tag, String message) => _add(LogLevel.error, tag, message);

  void _add(LogLevel level, String tag, String message) {
    final entry = LogEntry(DateTime.now(), level, tag, message);
    if (_buffer.length >= _capacity) _buffer.removeFirst();
    _buffer.addLast(entry);
    if (!_controller.isClosed) _controller.add(entry);
    if (kDebugMode) {
      debugPrint('[${level.name}] $tag: $message');
    }
  }

  Future<void> dispose() => _controller.close();
}
