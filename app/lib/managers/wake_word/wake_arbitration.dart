import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/logging.dart';

/// How much recent audio [wakeEnergy] reads: the wake word plus the quiet
/// before it, which is where the noise floor comes from.
const wakeEnergyWindow = Duration(seconds: 3);

/// How loud the wake word reached this kiosk, in dB over its own noise floor.
///
/// The loudest 200 ms of the last 1.5 seconds (the wake word, whichever
/// engine fired and however late) against the quietest fifth of the whole
/// window. Measuring against the floor rather than full scale takes the
/// microphone gain out of it: a kiosk with a hot mic hears the room louder
/// too. The floor is clamped so audio a noise suppressor has silenced
/// cannot claim an endless margin. Null when there is too little audio.
double? wakeEnergy(Uint8List pcm) {
  const frame = 320; // 20 ms at 16 kHz
  final samples = ByteData.sublistView(pcm);
  final count = pcm.length ~/ 2 ~/ frame;
  final levels = List<double>.filled(count, 0);
  for (var f = 0; f < count; f++) {
    var sum = 0.0;
    for (var i = 0; i < frame; i++) {
      final s = samples.getInt16((f * frame + i) * 2, Endian.little) / 32768;
      sum += s * s;
    }
    final rms = math.sqrt(sum / frame);
    levels[f] = rms > 0 ? 20 * math.log(rms) / math.ln10 : -120;
  }
  return wakeEnergyOfLevels(levels);
}

/// [wakeEnergy] over levels already measured: dBFS per 20 ms, oldest
/// first. The microphone's own levels come from before the noise
/// suppressor (MicLevels on Android), so the setting cannot tilt the
/// result.
double? wakeEnergyOfLevels(List<double> levels) {
  final count = levels.length;
  if (count < 10) return null;
  final recent = levels.sublist(math.max(0, count - 75))
    ..sort((a, b) => b.compareTo(a));
  final loud = recent.take(10).toList();
  final speech = loud.reduce((a, b) => a + b) / loud.length;
  final sorted = [...levels]..sort();
  final floor = math.max(sorted[(sorted.length * 0.2).floor()], -75.0);
  return speech - floor;
}

/// What the arbitration decided for one wake.
class ArbitrationResult {
  const ArbitrationResult({
    required this.won,
    required this.rivals,
    this.winner,
    this.winnerEnergy,
    this.heard = const [],
    this.phrase = '',
    this.energy = 0,
    this.claimedAt = 0,
  });

  final bool won;

  /// How many other kiosks claimed the same wake word in the window.
  final int rivals;

  /// The address of the kiosk that beat this one, when it lost.
  final String? winner;
  final double? winnerEnergy;

  /// Each rival claim for the log, with when it arrived against this
  /// kiosk's own: how far apart the kiosks detect is what sets the window.
  final List<String> heard;

  /// This kiosk's own claim, for [WakeArbiter.overtaken].
  final String phrase;
  final double energy;
  final int claimedAt;
}

/// A louder claim that arrived after this kiosk had decided.
class LateClaim {
  const LateClaim(this.from, this.energy);
  final String from;
  final double energy;
}

/// Carries claims between kiosks. UDP on the real network; tests hand in
/// a loopback.
abstract class ArbitrationTransport {
  /// Start receiving. False when the port cannot be opened. [onReopen]
  /// runs when the transport had to open its port again, after the network
  /// closed it.
  Future<bool> open(
    void Function(Uint8List data, String from) onPacket, {
    void Function()? onReopen,
  });

  /// To every kiosk on the subnet.
  void send(Uint8List data);

  /// To one kiosk, by address.
  void sendTo(Uint8List data, String address);
  Future<void> close();
}

/// One datagram to the whole subnet per claim, on a port of its own: no
/// roster, no pairing and nothing else on the kiosk has to be turned on.
/// Kiosks it has heard from also get the claim addressed to them, which
/// Wi-Fi acknowledges and retries where a broadcast gets neither.
class UdpArbitrationTransport implements ArbitrationTransport {
  UdpArbitrationTransport({
    this.port = WakeArbiter.port,
    this.reopenAfter = const Duration(seconds: 5),
  });

  final int port;
  final Duration reopenAfter;
  RawDatagramSocket? _socket;
  void Function(Uint8List data, String from)? _onPacket;
  void Function()? _onReopen;
  Timer? _reopen;
  bool _open = false;
  static final _broadcast = InternetAddress('255.255.255.255');

  @override
  Future<bool> open(
    void Function(Uint8List data, String from) onPacket, {
    void Function()? onReopen,
  }) async {
    _onPacket = onPacket;
    _onReopen = onReopen;
    await _bind();
    _open = true;
    return true;
  }

  Future<void> _bind() async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
    );
    socket.broadcastEnabled = true;
    socket.listen(
      (event) {
        if (event != RawSocketEvent.read) return;
        final d = socket.receive();
        if (d != null) _onPacket?.call(d.data, d.address.address);
      },
      // A send that fails, such as with no network while Wi-Fi joins at
      // boot, does not throw: the socket reports it here and closes.
      onError: (Object _) {},
      onDone: () => _closed(socket),
    );
    _socket = socket;
  }

  /// The socket closed under us: open the port again.
  void _closed(RawDatagramSocket socket) {
    if (!_open || _socket != socket) return;
    _socket = null;
    _scheduleReopen();
  }

  /// Tries every [reopenAfter] until the port opens or [close] is called.
  void _scheduleReopen() {
    _reopen?.cancel();
    _reopen = Timer(reopenAfter, () async {
      if (!_open || _socket != null) return;
      try {
        await _bind();
      } catch (_) {
        if (_open) _scheduleReopen();
        return;
      }
      if (!_open) {
        _socket?.close();
        _socket = null;
        return;
      }
      _onReopen?.call();
    });
  }

  @override
  void send(Uint8List data) => _send(data, _broadcast);

  @override
  void sendTo(Uint8List data, String address) {
    final to = InternetAddress.tryParse(address);
    if (to != null) _send(data, to);
  }

  /// A datagram sent while the socket is closed or that fails is lost,
  /// which arbitration expects.
  void _send(Uint8List data, InternetAddress to) {
    try {
      _socket?.send(data, to, port);
    } on SocketException {
      // Dropped.
    }
  }

  @override
  Future<void> close() async {
    _open = false;
    _reopen?.cancel();
    _reopen = null;
    _socket?.close();
    _socket = null;
  }
}

class _Claim {
  _Claim(this.id, this.phrase, this.energy, this.from, this.at);
  final String id;
  final String phrase;
  final double energy;
  final String from;
  final int at;
}

/// Settles which kiosk answers a wake word several of them heard.
///
/// Every kiosk that detects the wake word broadcasts a claim (the phrase and
/// [wakeEnergy]) and holds the wake for the window. Claims for the same
/// phrase that arrive within the window either side of its own detection
/// compete: the highest energy wins and the lower id breaks an exact tie.
/// Both kiosks see both claims, so both reach the same answer without a
/// second round. A claim that never arrives leaves both answering, which is
/// how it worked before.
class WakeArbiter {
  WakeArbiter(this._log, {ArbitrationTransport? transport, String? id})
    : _transport = transport ?? UdpArbitrationTransport(),
      id = id ?? _randomId();

  static const port = 2330;
  static const _tag = 'wake_arbitration';

  /// Claims are older than any window after this.
  static const _keepMs = 2000;

  /// How often a kiosk says it is here, so the others can address their
  /// claims to it before it has claimed anything itself.
  static const _helloEvery = Duration(minutes: 5);

  /// A kiosk not heard from in this long is no longer addressed.
  static const _peerForMs = 30 * 60 * 1000;

  final Logger _log;
  final ArbitrationTransport _transport;

  /// Random per run: only needs to be the same on both sides of a tie.
  final String id;

  final _clock = Stopwatch()..start();
  final _heard = <String, _Claim>{};
  final _random = math.Random();
  bool _running = false;
  Timer? _hello;

  /// The kiosks heard from, by address, with when.
  final _peers = <String, int>{};

  /// The addresses claims are sent to directly, for the log and tests.
  Iterable<String> get peers => _peers.keys;

  bool get running => _running;

  static String _randomId() {
    final r = math.Random.secure();
    return List.generate(
      8,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<void> start() async {
    if (_running) return;
    try {
      _running = await _transport.open(
        _onPacket,
        onReopen: () {
          _log.info(_tag, 'listening on UDP $port again after a failed send');
          _sayHello();
        },
      );
      _log.info(_tag, 'listening on UDP $port');
    } catch (e) {
      _log.warn(_tag, 'cannot listen on UDP $port: $e');
    }
    if (!_running) return;
    _hello = Timer.periodic(_helloEvery, (_) => _sayHello());
    _sayHello();
  }

  Uint8List _helloPacket() => Uint8List.fromList(
    utf8.encode(jsonEncode({'ks': 'wake', 'v': 1, 'hello': true, 'id': id})),
  );

  void _sayHello() {
    if (_running) _transport.send(_helloPacket());
  }

  void _learn(String address) {
    final now = _clock.elapsedMilliseconds;
    if (!_peers.containsKey(address)) _log.info(_tag, 'heard from $address');
    _peers[address] = now;
    _peers.removeWhere((_, seen) => now - seen > _peerForMs);
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _hello?.cancel();
    _hello = null;
    _heard.clear();
    _peers.clear();
    await _transport.close();
    _log.info(_tag, 'stopped');
  }

  static String _normalize(String phrase) =>
      phrase.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Rounded so both sides compare the very numbers that went on the wire.
  static double _round(double energy) => (energy * 10).round() / 10;

  void _prune() {
    final now = _clock.elapsedMilliseconds;
    _heard.removeWhere((_, c) => now - c.at > _keepMs);
  }

  void _onPacket(Uint8List data, String from) {
    if (!_running) return;
    Object? msg;
    try {
      msg = jsonDecode(utf8.decode(data));
    } catch (_) {
      return;
    }
    if (msg is! Map ||
        msg['ks'] != 'wake' ||
        msg['v'] != 1 ||
        msg['id'] is! String ||
        msg['id'] == id) {
      return;
    }
    if (msg['hello'] == true) {
      // A kiosk heard for the first time gets a hello back, addressed, so
      // both sides know each other from the start.
      final known = _peers.containsKey(from);
      _learn(from);
      if (!known) _transport.sendTo(_helloPacket(), from);
      return;
    }
    if (msg['p'] is! String || msg['e'] is! num || msg['n'] is! int) {
      return;
    }
    final claimId = msg['id'] as String;
    final phrase = msg['p'] as String;
    final energy = (msg['e'] as num).toDouble();
    if (claimId.length > 64 || !energy.isFinite) return;
    _learn(from);
    _prune();
    // Each claim goes out more than once; the first copy sets the time.
    _heard.putIfAbsent(
      '$claimId:${msg['n']}',
      () => _Claim(
        claimId,
        _normalize(phrase),
        _round(energy),
        from,
        _clock.elapsedMilliseconds,
      ),
    );
  }

  /// Claim this wake and wait out [window]. Won when no other kiosk heard
  /// the same phrase louder.
  Future<ArbitrationResult> contend({
    required String phrase,
    required double energy,
    required Duration window,
  }) async {
    if (!_running) return const ArbitrationResult(won: true, rivals: 0);
    final mine = _normalize(phrase);
    final level = _round(energy);
    final packet = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'ks': 'wake',
          'v': 1,
          'id': id,
          'n': _random.nextInt(1 << 30),
          'p': mine,
          'e': level,
        }),
      ),
    );
    final at = _clock.elapsedMilliseconds;
    // Broadcast is never acknowledged, so the claim goes out three times.
    // Wi-Fi acknowledges and retries an addressed one, and an access point
    // hands it to a sleeping kiosk sooner than a broadcast, so every kiosk
    // heard from gets one too.
    void sendAll() {
      if (!_running) return;
      _transport.send(packet);
      for (final peer in _peers.keys) {
        _transport.sendTo(packet, peer);
      }
    }

    sendAll();
    for (final delay in const [15, 30]) {
      Timer(Duration(milliseconds: delay), sendAll);
    }
    await Future<void>.delayed(window);
    final span = window.inMilliseconds;
    final rivals = [
      for (final c in _heard.values)
        if (c.phrase == mine && (c.at - at).abs() <= span) c,
    ];
    _prune();
    _Claim? best;
    for (final c in rivals) {
      if (best == null ||
          c.energy > best.energy ||
          (c.energy == best.energy && c.id.compareTo(best.id) < 0)) {
        best = c;
      }
    }
    final won =
        best == null ||
        level > best.energy ||
        (level == best.energy && id.compareTo(best.id) < 0);
    return ArbitrationResult(
      won: won,
      rivals: rivals.length,
      winner: won ? null : best.from,
      winnerEnergy: won ? null : best.energy,
      phrase: mine,
      energy: level,
      claimedAt: at,
      heard: [
        for (final c in rivals)
          '${c.from} ${c.energy} dB at '
              '${c.at >= at ? '+' : ''}${c.at - at} ms',
      ],
    );
  }

  /// After a win: waits out one more window and returns a louder claim for
  /// the same wake that arrived after this kiosk's window closed, or null.
  /// A kiosk that detected the wake word later sends its claim later, and
  /// the trip over Wi-Fi comes on top. That kiosk heard this one's claim
  /// inside its own window and answers, so this one has to stand down.
  Future<LateClaim?> overtaken(
    ArbitrationResult result,
    Duration window,
  ) async {
    if (!_running || !result.won) return null;
    final span = window.inMilliseconds;
    final wait = result.claimedAt + 2 * span - _clock.elapsedMilliseconds;
    if (wait > 0) await Future<void>.delayed(Duration(milliseconds: wait));
    _Claim? louder;
    for (final c in _heard.values) {
      final after = c.at - result.claimedAt;
      if (c.phrase != result.phrase || after <= span || after > 2 * span) {
        continue;
      }
      final beats =
          c.energy > result.energy ||
          (c.energy == result.energy && c.id.compareTo(id) < 0);
      if (beats && (louder == null || c.energy > louder.energy)) louder = c;
    }
    return louder == null ? null : LateClaim(louder.from, louder.energy);
  }
}
