import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Where Face Recognition's guided capture stands.
enum FaceEnrollPhase { starting, capturing, saved, failed }

/// The guided capture's steps, as Ground Control names them.
const faceEnrollSteps = ['look', 'side_a', 'side_b', 'far'];

/// What the guided capture screen shows: the step, how far it is, what to
/// fix and the latest camera frame.
@immutable
class FaceEnrollState {
  const FaceEnrollState({
    required this.phase,
    required this.name,
    this.color,
    this.step = 'look',
    this.stepIndex = 0,
    this.steps = 4,
    this.have = 0,
    this.need = 1,
    this.hint = 'ok',
    this.frame,
    this.rotation = 0,
    this.mirror = false,
    this.crops = 0,
    this.complete = false,
    this.error,
  });

  final FaceEnrollPhase phase;
  final String name;
  final String? color;
  final String step;
  final int stepIndex;
  final int steps;
  final int have;
  final int need;

  /// Ground Control's hint for the last frame: `ok`, `no_face`,
  /// `several_faces`, `closer`, `farther`, `look_at_screen`, `turn_more`,
  /// `turn_less`, `other_side`, `too_dark` or `other_face`.
  final String hint;
  final Uint8List? frame;
  final int rotation;
  final bool mirror;

  /// Face pictures saved, once [phase] is saved.
  final int crops;

  /// Every step was done before it was saved.
  final bool complete;

  /// Why nothing was saved: `too_short`, `unavailable`, `refused` or
  /// another code from Ground Control.
  final String? error;

  bool get active =>
      phase == FaceEnrollPhase.starting || phase == FaceEnrollPhase.capturing;

  /// How far through the whole capture, 0 to 1.
  double get progress =>
      ((stepIndex + (need > 0 ? have / need : 0)) / steps).clamp(0.0, 1.0);

  FaceEnrollState copyWith({
    FaceEnrollPhase? phase,
    String? step,
    int? stepIndex,
    int? steps,
    int? have,
    int? need,
    String? hint,
    Uint8List? frame,
    int? rotation,
    bool? mirror,
    int? crops,
    bool? complete,
    String? error,
  }) => FaceEnrollState(
    phase: phase ?? this.phase,
    name: name,
    color: color,
    step: step ?? this.step,
    stepIndex: stepIndex ?? this.stepIndex,
    steps: steps ?? this.steps,
    have: have ?? this.have,
    need: need ?? this.need,
    hint: hint ?? this.hint,
    frame: frame ?? this.frame,
    rotation: rotation ?? this.rotation,
    mirror: mirror ?? this.mirror,
    crops: crops ?? this.crops,
    complete: complete ?? this.complete,
    error: error ?? this.error,
  );
}

/// One guided capture on Ground Control (`/api/face_enroll`): frames in,
/// progress out, then the saved face. Every frame sent gets one answer,
/// [onAnswered] with its id, so the camera can send the next.
class FaceEnrollSocket {
  FaceEnrollSocket._(this._onEvent, this._onAnswered, this._log);

  final void Function(Map<String, Object?> event) _onEvent;
  final void Function(int id) _onAnswered;
  final void Function(String line)? _log;

  WebSocketChannel? _socket;
  StreamSubscription<Object?>? _sub;
  bool _ready = false;
  bool _closed = false;
  bool _ended = false;
  final _waiting = <int>{};

  bool get ready => _ready && !_closed;

  static FaceEnrollSocket open({
    required String baseUrl,
    required String token,
    String? ticket,
    required String deviceId,
    required String deviceName,
    String? personId,
    String? name,
    required void Function(Map<String, Object?> event) onEvent,
    required void Function(int id) onAnswered,
    void Function(String line)? log,
  }) {
    final socket = FaceEnrollSocket._(onEvent, onAnswered, log);
    final base = Uri.parse(baseUrl);
    final uri = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/api/face_enroll',
    );
    unawaited(
      socket._connect(uri, {
        'type': 'start',
        'token': token,
        'ticket': ?ticket,
        'device_id': deviceId,
        'device_name': deviceName,
        'person_id': ?personId,
        'name': ?name,
      }),
    );
    return socket;
  }

  Future<void> _connect(Uri uri, Map<String, Object?> start) async {
    try {
      final socket = WebSocketChannel.connect(uri);
      await socket.ready.timeout(const Duration(seconds: 5));
      if (_closed) {
        await socket.sink.close();
        return;
      }
      _socket = socket;
      socket.sink.add(jsonEncode(start));
      _sub = socket.stream.listen(
        _onMessage,
        onError: (Object _) => _gone(),
        onDone: _gone,
        cancelOnError: true,
      );
    } on Object catch (err) {
      _log?.call('face enrollment socket did not open: $err');
      _gone();
    }
  }

  /// Send one frame. False when the socket isn't ready.
  bool send({required int id, required int rotation, required Uint8List jpeg}) {
    final socket = _socket;
    if (!ready || socket == null) return false;
    _waiting.add(id);
    socket.sink.add(
      jsonEncode({'type': 'frame', 'id': id, 'rotation': rotation}),
    );
    socket.sink.add(jpeg);
    return true;
  }

  /// Stop early: Ground Control keeps what it has when the first step was done.
  void end() {
    final socket = _socket;
    if (socket == null || _closed) return;
    socket.sink.add(jsonEncode({'type': 'end'}));
  }

  void _onMessage(Object? data) {
    if (data is! String) return;
    final Map<String, Object?> e;
    try {
      e = (jsonDecode(data) as Map).cast<String, Object?>();
    } on Object {
      return;
    }
    final id = e['id'];
    if (id is int && _waiting.remove(id)) _onAnswered(id);
    switch (e['type']) {
      case 'ready':
        _ready = true;
      case 'saved':
        _ended = true;
      case 'error':
        if (id == null) _ended = true;
    }
    _onEvent(e);
  }

  void _gone() {
    _ready = false;
    for (final id in _waiting.toList()) {
      _onAnswered(id);
    }
    _waiting.clear();
    if (!_ended && !_closed) {
      _ended = true;
      _onEvent({'type': 'error', 'code': 'lost'});
    }
    unawaited(close());
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
