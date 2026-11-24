import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Vision Match on Kiosk Satellite Ground Control: the camera's face and
/// hand looks, done on Ground Control instead of the models on the device.
///
/// One socket per camera session (`/api/vision`). The native analyzer
/// decides when a look is due and hands over the frame as a JPEG with its
/// rotation (see `GroundControlVision.kt`). [send] passes it on and the
/// answer comes back through [onResult]: the faces in it and the shown hand.
/// Every frame gets exactly one answer: a result, or a failure when
/// Ground Control dropped it, couldn't read it or the socket went.
///
/// [onReady] carries how many looks a second Ground Control keeps up with,
/// for the analyzer's pacing. [onLost] says the socket is gone: the owner
/// opens a new one after a pause.
class VisionMatchSocket {
  VisionMatchSocket._(this._onReady, this._onResult, this._onLost, this._log);

  final void Function(double? face, double? hands) _onReady;
  final void Function(Map<String, Object?> answer) _onResult;
  final void Function() _onLost;
  final void Function(String line)? _log;

  WebSocketChannel? _socket;
  StreamSubscription<Object?>? _sub;
  bool _ready = false;
  bool _closed = false;
  bool _lostSaid = false;

  /// Frames sent and not answered yet, so a socket that goes answers them
  /// as failed instead of leaving the analyzer waiting.
  final _waiting = <int>{};

  bool get ready => _ready && !_closed;

  static VisionMatchSocket open({
    required String baseUrl,
    required String token,
    String? ticket,
    required String deviceId,
    required String deviceName,
    required List<String> want,
    required void Function(double? face, double? hands) onReady,
    required void Function(Map<String, Object?> answer) onResult,
    required void Function() onLost,
    void Function(String line)? log,
  }) {
    final socket = VisionMatchSocket._(onReady, onResult, onLost, log);
    final base = Uri.parse(baseUrl);
    final uri = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/api/vision',
    );
    unawaited(
      socket._connect(uri, {
        'type': 'start',
        'token': token,
        'ticket': ?ticket,
        'device_id': deviceId,
        'device_name': deviceName,
        'want': want,
      }),
    );
    return socket;
  }

  Future<void> _connect(Uri uri, Map<String, Object?> start) async {
    try {
      final socket = WebSocketChannel.connect(uri);
      await socket.ready.timeout(const Duration(seconds: 3));
      if (_closed) {
        await socket.sink.close();
        return;
      }
      _socket = socket;
      socket.sink.add(jsonEncode(start));
      _sub = socket.stream.listen(
        _onMessage,
        onError: (Object _) => _drop(),
        onDone: _drop,
        cancelOnError: true,
      );
    } on Object catch (err) {
      _log?.call('vision socket did not open: $err');
      _drop();
    }
  }

  /// Send one frame. False when the socket isn't ready: the caller answers
  /// the analyzer itself.
  bool send({
    required int id,
    required int rotation,
    required List<String> want,
    required Uint8List jpeg,
  }) {
    final socket = _socket;
    if (!ready || socket == null) return false;
    _waiting.add(id);
    socket.sink.add(
      jsonEncode({
        'type': 'frame',
        'id': id,
        'rotation': rotation,
        'want': want,
      }),
    );
    socket.sink.add(jpeg);
    return true;
  }

  void _onMessage(Object? data) {
    if (data is! String) return;
    final Map<String, Object?> e;
    try {
      e = (jsonDecode(data) as Map).cast<String, Object?>();
    } on Object {
      return;
    }
    switch (e['type']) {
      case 'ready':
        _ready = true;
        final looks = e['max_looks'];
        _onReady(
          looks is Map ? (looks['face'] as num?)?.toDouble() : null,
          looks is Map ? (looks['hands'] as num?)?.toDouble() : null,
        );
      case 'result':
        final id = e['id'];
        if (id is int && _waiting.remove(id)) _onResult(e);
      case 'dropped':
        _fail(e['id']);
      case 'error':
        final id = e['id'];
        if (id == null) {
          // Refused before the first frame: not approved, or the models
          // can't run on this Ground Control.
          _log?.call('Ground Control refused vision: ${e['code']}');
          _drop();
          return;
        }
        _log?.call('Ground Control could not look at frame $id: ${e['code']}');
        _fail(id);
    }
  }

  void _fail(Object? id) {
    if (id is int && _waiting.remove(id)) {
      _onResult({'id': id, 'failed': true});
    }
  }

  void _drop() {
    _ready = false;
    for (final id in _waiting.toList()) {
      _fail(id);
    }
    if (_closed || _lostSaid) return;
    _lostSaid = true;
    unawaited(close());
    _onLost();
  }

  Future<void> close() async {
    _closed = true;
    _ready = false;
    await _sub?.cancel();
    _sub = null;
    final socket = _socket;
    _socket = null;
    await socket?.sink.close();
  }
}
