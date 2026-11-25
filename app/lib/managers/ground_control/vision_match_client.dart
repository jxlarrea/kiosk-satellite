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
///
/// For the vision sessions on Ground Control, each frame carries how long
/// it took to encode and the round trip of the frame before it, and
/// [outcome] says what the kiosk did with a result.
///
/// With [recognize], Ground Control also says who is looking at the kiosk
/// (Face Recognition), through [onPerson]: the person at the kiosk (id,
/// name, color and score) when it names someone, null when nobody known is
/// in view, and everyone it names in view, the person at the kiosk first.
class VisionMatchSocket {
  VisionMatchSocket._(
    this._onReady,
    this._onResult,
    this._onLost,
    this._log,
    this._onPerson,
  );

  final void Function(double? face, double? hands) _onReady;
  final void Function(
    Map<String, Object?>? person,
    List<Map<String, Object?>> people,
  )?
  _onPerson;
  final void Function(Map<String, Object?> answer) _onResult;
  final void Function() _onLost;
  final void Function(String line)? _log;

  WebSocketChannel? _socket;
  StreamSubscription<Object?>? _sub;
  bool _ready = false;
  bool _closed = false;
  bool _lostSaid = false;

  /// Frames sent and not answered yet, so a socket that goes answers them
  /// as failed instead of leaving the analyzer waiting, with when each was
  /// sent for its round trip.
  final _waiting = <int, Stopwatch>{};

  /// The last answered frame's round trip, sent with the next frame.
  double? _roundTripMs;

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
    bool recognize = false,
    void Function(
      Map<String, Object?>? person,
      List<Map<String, Object?>> people,
    )?
    onPerson,
  }) {
    final socket = VisionMatchSocket._(
      onReady,
      onResult,
      onLost,
      log,
      onPerson,
    );
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
        if (recognize) 'recognize': true,
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
    double? encodeMs,
  }) {
    final socket = _socket;
    if (!ready || socket == null) return false;
    _waiting[id] = Stopwatch()..start();
    final roundTrip = _roundTripMs;
    _roundTripMs = null;
    socket.sink.add(
      jsonEncode({
        'type': 'frame',
        'id': id,
        'rotation': rotation,
        'want': want,
        'encode_ms': ?encodeMs,
        'rtt_ms': ?roundTrip,
      }),
    );
    socket.sink.add(jpeg);
    return true;
  }

  /// What the kiosk did with Ground Control's results, for its vision
  /// session: `screensaver_dismissed`, `screensaver_postponed`, `gesture`
  /// with the finger count and the action it ran, `pin_skipped` with the
  /// mode (kiosk or lockdown) and the person, and `lockdown_off` with the
  /// person or `lockdown_on`, in [extra].
  void outcome(
    String what, {
    int? fingers,
    String? action,
    Map<String, Object?> extra = const {},
  }) {
    final socket = _socket;
    if (!ready || socket == null) return;
    socket.sink.add(
      jsonEncode({
        ...extra,
        'type': 'outcome',
        'what': what,
        'fingers': ?fingers,
        'action': ?action,
      }),
    );
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
        final sent = id is int ? _waiting.remove(id) : null;
        if (sent != null) {
          _roundTripMs = (sent.elapsedMicroseconds / 100).round() / 10;
          _onResult(e);
        }
        if (e.containsKey('person')) _person(e['person'], e['people']);
      case 'person':
        _person(e['person'], e['people']);
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

  /// Who is in view, said once when it changes.
  Object? _lastPerson = const Object();

  void _person(Object? raw, Object? rawPeople) {
    final person = raw is Map && raw['id'] is String
        ? raw.cast<String, Object?>()
        : null;
    // Ground Control before several faces: only the person at the kiosk.
    final people = rawPeople is List
        ? [
            for (final p in rawPeople)
              if (p is Map && p['id'] is String) p.cast<String, Object?>(),
          ]
        : [?person];
    if (person != null && people.every((p) => p['id'] != person['id'])) {
      people.insert(0, person);
    }
    final key = '${person?['id']}|${people.map((p) => p['id']).join(',')}';
    if (key == _lastPerson) return;
    _lastPerson = key;
    _onPerson?.call(person, people);
  }

  void _fail(Object? id) {
    if (id is int && _waiting.remove(id) != null) {
      _onResult({'id': id, 'failed': true});
    }
  }

  void _drop() {
    _ready = false;
    for (final id in _waiting.keys.toList()) {
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
