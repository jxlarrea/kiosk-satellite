import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Dart side of the call video (`IntercomVideo.kt`). The picture itself never
/// lands here: this holds the two textures and passes compressed frames
/// between the native codecs and the call's video socket.
class IntercomVideo {
  static const _channel = MethodChannel('kiosk_satellite/intercom_video');

  /// Frames go through a background queue, for the reason the voice does:
  /// through the main thread a busy UI holds them back.
  static const _data = MethodChannel('kiosk_satellite/intercom_video_data');

  /// How the platform is reached. Tests swap it.
  Future<Object?> Function(String method, [Object? args]) invoker =
      (method, [args]) => (method == 'frame' ? _data : _channel)
          .invokeMethod<Object?>(method, args);

  /// An encoded frame of this kiosk's camera, ready for the socket.
  void Function(Uint8List frame)? onFrame;

  /// The other kiosk's picture started, at this size.
  void Function(int width, int height)? onFarSize;

  /// The picture moved to another texture.
  void Function(int texture)? onFarTexture;

  /// The first frame of it reached the screen.
  void Function()? onFarShown;

  /// This kiosk's own picture, at this size.
  void Function(int width, int height)? onSelfSize;

  /// The decoder needs a key frame from the other kiosk.
  void Function()? onRequestKey;

  /// The camera could not send.
  void Function(String message)? onCameraFailed;

  /// Starts taking calls from the native side.
  void listen() => _channel.setMethodCallHandler(handle);

  /// One call from the native side. Tests call it directly.
  Future<void> handle(MethodCall call) async {
    final args = call.arguments;
    final map = args is Map ? args : const {};
    switch (call.method) {
      case 'frame':
        if (args is Uint8List) onFrame?.call(args);
      case 'far':
        onFarSize?.call(map['width'] as int, map['height'] as int);
      case 'farTexture':
        onFarTexture?.call(map['id'] as int);
      case 'farShown':
        onFarShown?.call();
      case 'self':
        onSelfSize?.call(map['width'] as int, map['height'] as int);
      case 'requestKey':
        onRequestKey?.call();
      case 'cameraFailed':
        onCameraFailed?.call('${map['message'] ?? ''}');
    }
  }

  Future<int?> _texture(String method) async {
    try {
      return await invoker(method) as int?;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _quietly(String method, [Object? args]) async {
    try {
      await invoker(method, args);
    } on MissingPluginException {
      // No bridge in tests.
    } catch (_) {}
  }

  Future<int?> openFar() => _texture('openFar');
  Future<void> closeFar() => _quietly('closeFar');
  Future<int?> openSelf() => _texture('openSelf');
  Future<void> closeSelf() => _quietly('closeSelf');
  Future<void> setSending(bool on) => _quietly('sending', on);
  Future<void> keyFrame() => _quietly('keyFrame');

  /// One frame from the other kiosk. Fire and forget, like the voice.
  void push(Uint8List frame) => unawaited(_quietly('frame', frame));
}

/// The size, rate and bitrate of each Video quality.
Map<String, Object> intercomVideoConfig(String quality) => switch (quality) {
  'low' => {'width': 640, 'height': 480, 'fps': 15, 'bitrate': 500000},
  'high' => {'width': 1280, 'height': 720, 'fps': 30, 'bitrate': 2500000},
  _ => {'width': 640, 'height': 480, 'fps': 24, 'bitrate': 1000000},
};

/// Whether a frame from the native side is a key frame.
bool intercomFrameIsKey(Uint8List frame) =>
    frame.isNotEmpty && frame[0] & 1 != 0;

/// The video socket of a call, in both directions.
///
/// A WebSocket buffers whatever it is given, so on a slow link video would
/// fall further and further behind. The far side acknowledges each frame:
/// past [maxInFlight] unacknowledged frames this one drops, then waits for a
/// key frame so the decoder never sees a gap.
class IntercomVideoLink {
  IntercomVideoLink(
    this.channel, {
    required this.onFrame,
    required this.onMessage,
    required this.onClosed,
  }) {
    _sub = channel.stream.listen(
      _onData,
      onDone: () => onClosed(this),
      onError: (Object _) => onClosed(this),
    );
  }

  static const maxInFlight = 6;

  final WebSocketChannel channel;
  final void Function(Uint8List frame) onFrame;
  final void Function(Map<String, Object?> message) onMessage;
  final void Function(IntercomVideoLink link) onClosed;
  StreamSubscription<Object?>? _sub;

  int _sent = 0;
  int _acked = 0;
  int _received = 0;
  bool _waitingKey = false;

  /// Frames this side let go of, for the logs.
  int dropped = 0;

  /// Frames this side sent.
  int get sent => _sent;

  void _onData(Object? raw) {
    if (raw is String) {
      Map<String, Object?>? message;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) message = decoded.cast<String, Object?>();
      } catch (_) {}
      if (message == null) return;
      if (message['type'] == 'ack') {
        final n = message['n'];
        if (n is int && n > _acked && n <= _sent) _acked = n;
        return;
      }
      onMessage(message);
      return;
    }
    if (raw is List<int>) {
      final bytes = raw is Uint8List ? raw : Uint8List.fromList(raw);
      _received++;
      sendMessage({'type': 'ack', 'n': _received});
      onFrame(bytes);
    }
  }

  void sendMessage(Map<String, Object?> message) {
    try {
      channel.sink.add(jsonEncode(message));
    } catch (_) {}
  }

  /// Sends [frame] unless the link has fallen behind.
  void sendFrame(Uint8List frame) {
    final key = intercomFrameIsKey(frame);
    final behind = _sent - _acked >= maxInFlight;
    if (behind || (_waitingKey && !key)) {
      _waitingKey = true;
      dropped++;
      return;
    }
    _waitingKey = false;
    _sent++;
    try {
      channel.sink.add(frame);
    } catch (_) {}
  }

  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await channel.sink.close();
    } catch (_) {}
  }
}
