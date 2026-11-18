import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

/// One Voice Match session on Kiosk Satellite Ground Control: one voice
/// turn, or a whole realtime conversation.
///
/// Follow mode: the service gets everything the microphone hears, with the
/// wake word as the anchor for who the user is, and sends back only the
/// user's speech (onAudio) for the kiosk to forward in place of the
/// microphone, with `turn_start` and `turn_end` around each turn. TV
/// before, between and after the user's words never reaches the backend.
///
/// Live mode: the kiosk keeps sending its own audio to Home Assistant and
/// this copy goes to the service, which answers with events only:
/// `speaker` (who is talking, about a second in), `other_voice`,
/// `end_of_speech` (the speaker stopped, or someone else took over) and
/// `rejected` (only enrolled voices are answered and this is not one).
///
/// onLost says the service is gone before [end]: the kiosk goes back to
/// sending its own microphone.
///
/// It gets the audio Home Assistant gets, from the same point. Audio fed
/// before the socket is ready waits in a queue, so the start of the
/// command is never lost. Nothing here blocks the turn: a service that is
/// slow or gone just sends no events.
class VoiceMatchTurn {
  VoiceMatchTurn._(
    this._onEvent,
    this._log,
    this._onAudio,
    this._onLost,
    this._onReady,
  );

  /// The service's id for the session, once it answered the start.
  final void Function(String session)? _onReady;

  final void Function(Map<String, Object?> event) _onEvent;
  final void Function(Uint8List pcm)? _onAudio;
  final void Function()? _onLost;
  final void Function(String line)? _log;
  WebSocketChannel? _socket;
  StreamSubscription<Object?>? _sub;
  final _queue = <Uint8List>[];
  int _queued = 0;
  bool _ready = false;
  bool _ended = false;
  bool _lostSaid = false;

  /// The service answered the start: audio flows both ways.
  bool get ready => _ready;

  /// At most this much audio waits for the socket (10 s at 16 kHz PCM16).
  static const _maxQueued = 320000;

  /// Opens a session. Never throws: on any failure the turn just has no
  /// Voice Match events.
  static VoiceMatchTurn open({
    required String baseUrl,
    required String token,
    required String deviceId,
    required String deviceName,
    required String policy,
    List<String> people = const [],
    required void Function(Map<String, Object?> event) onEvent,
    void Function(String line)? log,
    bool follow = false,
    Uint8List? anchor,
    String? speaker,
    String? continues,
    void Function(String session)? onReady,
    void Function(Uint8List pcm)? onAudio,
    void Function()? onLost,
  }) {
    final turn = VoiceMatchTurn._(onEvent, log, onAudio, onLost, onReady);
    final base = Uri.parse(baseUrl);
    final uri = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/api/session',
    );
    unawaited(
      turn._connect(uri, {
        'type': 'start',
        'token': token,
        'device_id': deviceId,
        'device_name': deviceName,
        'mode': follow ? 'follow' : 'live',
        'policy': policy,
        if (policy == 'people') 'people': people,
        if (follow && anchor != null && anchor.isNotEmpty)
          'anchor': base64Encode(anchor),
        // A follow-up: the person an earlier turn of the conversation was,
        // and its session, so the conversation is saved as one.
        if (follow && speaker != null) 'speaker': speaker,
        if (follow && continues != null) 'continues': continues,
      }),
    );
    return turn;
  }

  Future<void> _connect(Uri uri, Map<String, Object?> start) async {
    try {
      final socket = WebSocketChannel.connect(uri);
      await socket.ready.timeout(const Duration(seconds: 3));
      if (_ended) {
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
      _log?.call('voice match session did not open: $err');
      _drop();
    }
  }

  void _onMessage(Object? data) {
    if (data is List<int>) {
      // Follow mode: the user's speech, to forward.
      if (!_ended) {
        _onAudio?.call(data is Uint8List ? data : Uint8List.fromList(data));
      }
      return;
    }
    if (data is! String) return;
    final Map<String, Object?> e;
    try {
      e = (jsonDecode(data) as Map).cast<String, Object?>();
    } on Object {
      return;
    }
    if (e['type'] == 'ready') {
      _ready = true;
      final session = e['session'];
      if (session is String) _onReady?.call(session);
      for (final pcm in _queue) {
        _socket?.sink.add(pcm);
      }
      _queue.clear();
      _queued = 0;
      return;
    }
    if (e['type'] == 'error') {
      _log?.call('voice match refused the session: ${e['code']}');
      _drop();
      return;
    }
    _onEvent(e);
  }

  /// One chunk of the turn's microphone audio, 16 kHz mono PCM16.
  void feed(Uint8List pcm) {
    if (_ended) return;
    if (_ready) {
      _socket?.sink.add(pcm);
      return;
    }
    if (_queued + pcm.length > _maxQueued) return;
    _queue.add(Uint8List.fromList(pcm));
    _queued += pcm.length;
  }

  /// The turn is over. The service keeps the session (its audio, scores
  /// and outcome) for the app's Sessions page.
  void end() {
    if (_ended) return;
    _ended = true;
    _queue.clear();
    final socket = _socket;
    if (socket == null) return;
    try {
      socket.sink.add(jsonEncode({'type': 'end'}));
    } on Object {
      // Already closed.
    }
    // Let the service answer with its stats, then let go.
    Timer(const Duration(seconds: 2), _drop);
  }

  void _drop() {
    // Gone before the turn was over: the kiosk takes its microphone back.
    if (!_ended && !_lostSaid) {
      _lostSaid = true;
      _onLost?.call();
    }
    _ready = false;
    unawaited(_sub?.cancel());
    _sub = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      unawaited(socket.sink.close().catchError((Object _) {}));
    }
  }
}
