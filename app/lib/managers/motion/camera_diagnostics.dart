import 'package:flutter/services.dart';

import '../../core/logging.dart';

/// Camera lifecycle records share the regular App Logs and remote API.
class CameraDiagnostics {
  CameraDiagnostics(this._log);

  static const channel = MethodChannel('kiosk_satellite/camera/diagnostics');
  final Logger _log;
  final _seen = <String>{};
  bool _disposed = false;

  Future<void> start() async {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'record') _record(call.arguments);
    });
    try {
      final history = await channel.invokeListMethod<Object?>('start');
      for (final entry in history ?? const []) {
        _record(entry);
      }
    } on MissingPluginException {
      // No native camera bridge on this platform.
    } on PlatformException catch (e) {
      _log.warn('camera', 'Could not read camera diagnostics: ${e.message}');
    }
  }

  void _record(Object? value) {
    if (_disposed || value is! Map) return;
    final id = value['id'];
    final message = value['message'];
    if (id is! String || message is! String || !_seen.add(id)) return;
    while (_seen.length > 64) {
      _seen.remove(_seen.first);
    }
    final time = value['time'];
    final text = time is String ? '[$time] $message' : message;
    if (value['level'] == 'warn') {
      _log.warn('camera', text);
    } else {
      _log.info('camera', text);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    channel.setMethodCallHandler(null);
    try {
      await channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // No native camera bridge on this platform.
    } on PlatformException {
      // The engine may already be detaching.
    }
  }
}
