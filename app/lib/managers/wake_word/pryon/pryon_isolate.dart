import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../wake_msg.dart';

/// The Echo images' wake word service (pryond).
///
/// A leaf like wake_msg.dart: the compute isolate depends on it.
const pryonSocketPath = '/dev/socket/pryond';

/// Entry point of the compute isolate for Amazon's engine.
///
/// There is no model to run here: the service runs it. The isolate keeps the
/// socket and its traffic off the platform isolate like the other engines'
/// inference, and turns the service's detections into the usual messages.
void pryonIsolateEntry(SendPort mainPort) {
  final worker = _PryonWorker(mainPort);
  final port = ReceivePort();
  mainPort.send(port.sendPort);
  port.listen((msg) {
    if (msg is Uint8List) {
      worker.onAudio(msg);
    } else if (msg is Map) {
      switch (msg['type']) {
        case WakeMsg.init:
          unawaited(worker.init(msg));
        case WakeMsg.resume:
          worker.resumeDetection(msg['absSample'] as int?);
        case WakeMsg.armStop:
          worker.armStop(msg['active'] == true);
        case WakeMsg.setTelemetry:
          worker.setTelemetry(
            msg['enabled'] == true,
            tester: msg['tester'] == true,
          );
        case WakeMsg.setNearMisses:
          worker.nearMisses = msg['enabled'] == true;
        case WakeMsg.stop:
          worker.stop();
          port.close();
      }
    }
  });
}

class _Word {
  _Word(
    this.id,
    this.wakeWord,
    this.offset,
    this.accept, {
    this.isStop = false,
  });

  final String id;
  final String wakeWord;

  /// Added to the service's threshold (WakeWordModelRef.thresholdOffset).
  final double offset;

  /// The last threshold the service accepted this word at. A near miss
  /// comes with the lower threshold near misses start from, so this is what
  /// a near miss is held against.
  double? accept;

  final bool isStop;
}

class _PryonWorker {
  _PryonWorker(this._main);
  final SendPort _main;

  Socket? _socket;
  Completer<String?>? _started;

  /// By "MODEL/KEYWORD", as the service names them.
  final _words = <String, _Word>{};
  bool _stopped = false;

  /// A wake word fired and we await re-arming. The stop word stays live.
  bool _detected = false;
  bool _stopArmed = false;
  bool _telemetry = false;

  /// The wake word tester is watching: detections show in the telemetry
  /// and fire nothing.
  bool _tester = false;
  bool nearMisses = false;

  /// Mic-timeline samples, shared with the main isolate.
  int _absSamples = 0;

  /// Samples the service has had from us. Its detections count in these.
  int _sent = 0;

  /// [_absSamples] minus [_sent], fixed at the last gap in the audio.
  int _offset = 0;

  void _log(String level, String message) =>
      _main.send({'type': WakeMsg.log, 'level': level, 'message': message});

  Future<void> init(Map msg) async {
    try {
      final models = <String>{};
      for (final m in msg['models'] as List) {
        final e = m as Map;
        final key = '${e['model']}/${e['keyword']}';
        _words[key] = _Word(
          '${e['id']}',
          '${e['wakeWord']}',
          (e['thresholdOffset'] as num?)?.toDouble() ?? 0,
          (e['acceptThreshold'] as num?)?.toDouble(),
          isStop: e['stop'] == true,
        );
        models.add('${e['model']}');
      }
      nearMisses = msg['nearMisses'] == true;

      final socket = await _connect(
        msg['socketPath'] as String? ?? pryonSocketPath,
      );
      _socket = socket;
      _started = Completer<String?>();
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_onLine, onDone: _onClosed, onError: (_) => _onClosed());
      _frame('S', utf8.encode(models.join(',')));
      final error = await _started!.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => 'the service did not start listening',
      );
      if (error != null) throw StateError(error);
      _log('info', 'listening with ${models.join(', ')}');
      _main.send({'type': WakeMsg.ready});
    } catch (e) {
      _main.send({'type': WakeMsg.error, 'message': '$e'});
    }
  }

  /// The service's socket, waiting out a restart: init brings a service
  /// that died back after a few seconds, and the manager restarts a
  /// crashed engine sooner than that.
  Future<Socket> _connect(String path) async {
    final address = InternetAddress(path, type: InternetAddressType.unix);
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (true) {
      try {
        return await Socket.connect(
          address,
          0,
          timeout: const Duration(seconds: 3),
        );
      } on SocketException {
        if (DateTime.now().isAfter(deadline)) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }

  void _frame(String type, List<int> payload) {
    final header = ByteData(5)
      ..setUint8(0, type.codeUnitAt(0))
      ..setUint32(1, payload.length, Endian.little);
    _socket?.add(header.buffer.asUint8List());
    if (payload.isNotEmpty) _socket?.add(payload);
  }

  void _onClosed() {
    if (_stopped) return;
    if (_started?.isCompleted == false) {
      _started!.complete('the service closed the connection');
      return;
    }
    // Uncaught, so the main isolate sees the detector die and the manager
    // brings a new one up, as for a crashed model.
    throw StateError('the wake word service closed the connection');
  }

  void _onLine(String line) {
    final Object? event;
    try {
      event = jsonDecode(line);
    } catch (_) {
      return;
    }
    if (event is! Map) return;
    switch (event['event']) {
      case 'started':
        if (_started?.isCompleted == false) _started!.complete(null);
      case 'error':
        final message = '${event['message']}';
        if (_started?.isCompleted == false) {
          _started!.complete(message);
        } else {
          _log('warn', 'service: $message');
        }
      case 'detection':
        _onDetection(event);
    }
  }

  void _onDetection(Map event) {
    final w = _words['${event['model']}/${event['keyword']}'];
    if (w == null || _stopped) return;
    final score = (event['score'] as num?)?.toDouble() ?? -1;
    final reported = (event['threshold'] as num?)?.toDouble() ?? -1;
    final accepted = event['accepted'] == true;
    if (accepted) w.accept = reported;
    final threshold = (w.accept ?? reported) + w.offset;
    final fired = score >= threshold && (accepted || w.offset < 0);
    final end = (event['end'] as num?)?.toInt() ?? _sent;
    final t = (end + _offset) ~/ 16;

    if (_telemetry) {
      _main.send({
        'type': WakeMsg.telemetry,
        'id': w.id,
        'wakeWord': w.wakeWord,
        't': t,
        'score': score,
        'threshold': threshold,
        'fired': fired,
      });
    }
    if (_tester) return;

    if (w.isStop) {
      if (!_stopArmed) return;
      if (!fired) {
        if (nearMisses) {
          _main.send({
            'type': WakeMsg.nearMiss,
            'id': w.id,
            'wakeWord': w.wakeWord,
            'stop': true,
            'score': score,
            'threshold': threshold,
          });
        }
        return;
      }
      _log('info', 'stop word detected (${score.toStringAsFixed(3)})');
      _main.send({
        'type': WakeMsg.detection,
        'id': w.id,
        'wakeWord': w.wakeWord,
        'stop': true,
        'score': score,
        'threshold': threshold,
      });
      return;
    }
    if (_detected) return;
    if (!fired) {
      if (nearMisses) {
        _main.send({
          'type': WakeMsg.nearMiss,
          'id': w.id,
          'wakeWord': w.wakeWord,
          'score': score,
          'threshold': threshold,
        });
      }
      return;
    }
    _log(
      'info',
      'detected "${w.id}" (${score.toStringAsFixed(3)} against '
          '${threshold.toStringAsFixed(3)})',
    );
    _detected = true;
    _main.send({
      'type': WakeMsg.detection,
      'id': w.id,
      'wakeWord': w.wakeWord,
      // The service says where the word ended, so the stream starts right
      // after it.
      'wakeEndSample': end + _offset,
      'score': score,
      'threshold': threshold,
    });
  }

  void onAudio(Uint8List bytes) {
    if (_stopped || _socket == null) return;
    final samples = bytes.length ~/ 2;
    _absSamples += samples;
    _frame('A', bytes);
    _sent += samples;
  }

  void resumeDetection(int? absSample) {
    if (_stopped) return;
    _detected = false;
    if (absSample != null) _absSamples = absSample;
    // The audio of the turn never reached the service, so tell it there is
    // a gap and count its samples on from here.
    _frame('E', const []);
    _offset = _absSamples - _sent;
    _log('info', 're-armed');
  }

  void armStop(bool active) {
    if (_stopped || _stopArmed == active) return;
    _stopArmed = active;
    _log('info', active ? 'stop word armed' : 'stop word disarmed');
  }

  void setTelemetry(bool enabled, {bool tester = false}) {
    _telemetry = enabled;
    _tester = enabled && tester;
  }

  void stop() {
    if (_stopped) return;
    _stopped = true;
    _socket?.destroy();
    _socket = null;
    _main.send({'type': WakeMsg.stopped});
  }
}
