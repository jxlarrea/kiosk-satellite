import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../audio/mic_hub.dart';

/// Holds shared capture only while a viewer requests microphone audio.
/// PCM goes directly from MicRecorder to the native encoder worker.
class RtspAudio {
  static const _channel = MethodChannel('kiosk_satellite/camera/rtsp');
  final MicHub _hub = MicHub.instance;
  StreamSubscription<Uint8List>? _subscription;
  Future<void> _pending = Future.value();
  bool _wanted = false;
  bool _disposed = false;
  String? error;

  RtspAudio() {
    _hub.browserCapturing.addListener(_sync);
  }

  bool get suspended => _wanted && _hub.browserCapturing.value;

  void demand(bool wanted) {
    _wanted = wanted;
    _sync();
  }

  void _sync() {
    _pending = _pending
        .then((_) async {
          final wanted = _wanted && !_disposed && !_hub.browserCapturing.value;
          if (!wanted) {
            final sub = _subscription;
            _subscription = null;
            await sub?.cancel();
            await _channel.invokeMethod<void>('audioCapture', false);
            return;
          }
          if (_subscription != null) return;
          if (!await Permission.microphone.isGranted) {
            error = 'Microphone permission is required for RTSP audio.';
            return;
          }
          if (!_wanted || _disposed || _hub.browserCapturing.value) return;
          error = null;
          await _channel.invokeMethod<void>('audioCapture', true);
          _subscription = _hub.stream().listen(
            (_) {},
            onError: (Object e) {
              error = 'RTSP microphone capture failed: $e';
              demand(false);
            },
          );
        })
        .catchError((Object e) {
          error = 'RTSP audio unavailable: $e';
        });
  }

  Future<void> dispose() async {
    _disposed = true;
    _hub.browserCapturing.removeListener(_sync);
    _sync();
    await _pending;
  }
}
