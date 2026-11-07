import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_arbitration.dart';

/// Every kiosk on one wire: what one sends, the others receive.
class _Wire {
  final _ends = <_End>[];
}

class _End implements ArbitrationTransport {
  _End(this.wire, this.address);
  final _Wire wire;
  final String address;
  void Function(Uint8List, String)? _onPacket;

  /// Drop everything this end sends, as a lossy access point would.
  bool mute = false;

  /// Drop only what this end broadcasts, as an access point holding
  /// broadcasts for sleeping clients can.
  bool dropBroadcast = false;

  @override
  Future<bool> open(
    void Function(Uint8List data, String from) onPacket, {
    void Function()? onReopen,
  }) async {
    _onPacket = onPacket;
    wire._ends.add(this);
    return true;
  }

  @override
  void send(Uint8List data) {
    if (mute || dropBroadcast) return;
    for (final e in [...wire._ends]) {
      e._onPacket?.call(data, address);
    }
  }

  @override
  void sendTo(Uint8List data, String to) {
    if (mute) return;
    for (final e in [...wire._ends]) {
      if (e.address == to) e._onPacket?.call(data, address);
    }
  }

  @override
  Future<void> close() async => wire._ends.remove(this);
}

/// [seconds] of 16 kHz PCM16: quiet noise, then a tone at [speech] RMS
/// over the last 0.8 seconds.
Uint8List _clip({double noise = 0.002, double speech = 0.1}) {
  const rate = 16000;
  final total = 3 * rate;
  final start = total - (0.8 * rate).round();
  final r = math.Random(1);
  final out = Int16List(total);
  for (var i = 0; i < total; i++) {
    var v = (r.nextDouble() * 2 - 1) * noise * 1.732;
    if (i >= start) {
      v += speech * 1.414 * math.sin(2 * math.pi * 300 * i / rate);
    }
    out[i] = (v.clamp(-1.0, 1.0) * 32767).round();
  }
  return out.buffer.asUint8List();
}

void main() {
  group('wakeEnergy', () {
    test('a louder wake word scores higher over the same room', () {
      final near = wakeEnergy(_clip(speech: 0.2))!;
      final far = wakeEnergy(_clip(speech: 0.05))!;
      expect(near, greaterThan(far + 10));
    });

    test('gain does not change the score', () {
      final quiet = wakeEnergy(_clip(noise: 0.002, speech: 0.05))!;
      final loud = wakeEnergy(_clip(noise: 0.008, speech: 0.2))!;
      expect((quiet - loud).abs(), lessThan(1));
    });

    test('a silenced floor cannot claim an endless margin', () {
      final clean = wakeEnergy(_clip(noise: 0, speech: 0.1))!;
      expect(clean, lessThan(80));
    });

    test('measured levels score the same as the audio they came from', () {
      final pcm = _clip(noise: 0.003, speech: 0.08);
      final samples = ByteData.sublistView(pcm);
      final levels = <double>[];
      for (var f = 0; f < pcm.length ~/ 640; f++) {
        var sum = 0.0;
        for (var i = 0; i < 320; i++) {
          final v = samples.getInt16((f * 320 + i) * 2, Endian.little) / 32768;
          sum += v * v;
        }
        levels.add(10 * math.log(sum / 320) / math.ln10);
      }
      expect(wakeEnergyOfLevels(levels), closeTo(wakeEnergy(pcm)!, 0.01));
      expect(wakeEnergyOfLevels(levels.take(5).toList()), isNull);
    });

    test('too little audio has no score', () {
      expect(wakeEnergy(Uint8List(1000)), isNull);
    });
  });

  group('WakeArbiter', () {
    late _Wire wire;
    late Logger log;

    setUp(() {
      wire = _Wire();
      log = Logger();
    });

    Future<WakeArbiter> kiosk(String address, {String? id}) async {
      final a = WakeArbiter(log, transport: _End(wire, address), id: id);
      await a.start();
      return a;
    }

    const window = Duration(milliseconds: 60);

    test('the louder kiosk answers and the other stands down', () async {
      final near = await kiosk('10.0.0.1');
      final far = await kiosk('10.0.0.2');
      final results = await Future.wait([
        near.contend(phrase: 'Okay Nabu', energy: 30, window: window),
        far.contend(phrase: 'okay nabu ', energy: 18, window: window),
      ]);
      expect(results[0].won, isTrue);
      expect(results[0].rivals, 1);
      expect(results[1].won, isFalse);
      expect(results[1].winner, '10.0.0.1');
      expect(results[1].winnerEnergy, 30);
    });

    test('a slower kiosk still competes within the window', () async {
      final fast = await kiosk('10.0.0.1');
      final slow = await kiosk('10.0.0.2');
      final first = fast.contend(
        phrase: 'hey jarvis',
        energy: 12,
        window: window,
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final second = slow.contend(
        phrase: 'hey jarvis',
        energy: 25,
        window: window,
      );
      expect((await first).won, isFalse);
      expect((await second).won, isTrue);
    });

    test('a claim from outside the window does not count', () async {
      final a = await kiosk('10.0.0.1');
      final b = await kiosk('10.0.0.2');
      await a.contend(phrase: 'hey jarvis', energy: 40, window: window);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final late = await b.contend(
        phrase: 'hey jarvis',
        energy: 10,
        window: window,
      );
      expect(late.won, isTrue);
      expect(late.rivals, 0);
    });

    test('different wake words do not compete', () async {
      final a = await kiosk('10.0.0.1');
      final b = await kiosk('10.0.0.2');
      final results = await Future.wait([
        a.contend(phrase: 'okay nabu', energy: 30, window: window),
        b.contend(phrase: 'hey jarvis', energy: 10, window: window),
      ]);
      expect(results.every((r) => r.won), isTrue);
    });

    test('an exact tie goes to the lower id on both sides', () async {
      final a = await kiosk('10.0.0.1', id: 'aaaa');
      final b = await kiosk('10.0.0.2', id: 'bbbb');
      final results = await Future.wait([
        b.contend(phrase: 'okay nabu', energy: 20.04, window: window),
        a.contend(phrase: 'okay nabu', energy: 19.96, window: window),
      ]);
      expect(results[0].won, isFalse);
      expect(results[1].won, isTrue);
    });

    test('a lost claim leaves both answering', () async {
      final a = await kiosk('10.0.0.1');
      final b = await kiosk('10.0.0.2');
      final end = wire._ends.last..mute = true;
      expect(end.address, '10.0.0.2');
      final results = await Future.wait([
        a.contend(phrase: 'okay nabu', energy: 10, window: window),
        b.contend(phrase: 'okay nabu', energy: 30, window: window),
      ]);
      expect(results[0].won, isTrue);
      expect(results[1].won, isTrue);
    });

    test('three kiosks agree on one winner', () async {
      final kiosks = [
        await kiosk('10.0.0.1'),
        await kiosk('10.0.0.2'),
        await kiosk('10.0.0.3'),
      ];
      final results = await Future.wait([
        for (final (i, k) in kiosks.indexed)
          k.contend(
            phrase: 'okay nabu',
            energy: [14.0, 27.5, 21.0][i],
            window: window,
          ),
      ]);
      expect([for (final r in results) r.won], [false, true, false]);
      expect(results[0].winner, '10.0.0.2');
      expect(results[2].winner, '10.0.0.2');
    });

    test(
      'a louder claim after the window makes the winner stand down',
      () async {
        final early = await kiosk('10.0.0.1');
        final late = await kiosk('10.0.0.2');
        final first = early.contend(
          phrase: 'ok nova',
          energy: 30,
          window: window,
        );
        await Future<void>.delayed(const Duration(milliseconds: 90));
        final second = late.contend(
          phrase: 'ok nova',
          energy: 45,
          window: window,
        );
        final won = await first;
        expect(won.won, isTrue);
        expect((await second).won, isTrue);
        final louder = await early.overtaken(won, window);
        expect(louder?.from, '10.0.0.2');
        expect(louder?.energy, 45);
      },
    );

    test('a quieter or much later claim leaves the winner answering', () async {
      final early = await kiosk('10.0.0.1');
      final late = await kiosk('10.0.0.2');
      final first = early.contend(
        phrase: 'ok nova',
        energy: 30,
        window: window,
      );
      await Future<void>.delayed(const Duration(milliseconds: 90));
      unawaited(late.contend(phrase: 'ok nova', energy: 20, window: window));
      expect(await early.overtaken(await first, window), isNull);

      final again = early.contend(
        phrase: 'ok nova',
        energy: 30,
        window: window,
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
      unawaited(late.contend(phrase: 'ok nova', energy: 50, window: window));
      expect(await early.overtaken(await again, window), isNull);
    });

    test('kiosks learn each other from their hellos', () async {
      final a = await kiosk('10.0.0.1');
      final b = await kiosk('10.0.0.2');
      expect(a.peers, ['10.0.0.2']);
      expect(b.peers, ['10.0.0.1']);
    });

    test('a claim still arrives when broadcasts are lost', () async {
      final near = await kiosk('10.0.0.1');
      final far = await kiosk('10.0.0.2');
      for (final e in wire._ends) {
        e.dropBroadcast = true;
      }
      final results = await Future.wait([
        near.contend(phrase: 'ok nova', energy: 40, window: window),
        far.contend(phrase: 'ok nova', energy: 20, window: window),
      ]);
      expect(results[0].won, isTrue);
      expect(results[1].won, isFalse);
      expect(results[1].winner, '10.0.0.1');
    });

    test('a stopped arbiter answers without waiting', () async {
      final a = await kiosk('10.0.0.1');
      await a.stop();
      final watch = Stopwatch()..start();
      final r = await a.contend(
        phrase: 'okay nabu',
        energy: 1,
        window: const Duration(seconds: 5),
      );
      expect(r.won, isTrue);
      expect(watch.elapsedMilliseconds, lessThan(1000));
    });

    test('junk on the port is ignored', () async {
      final a = await kiosk('10.0.0.1');
      final other = _End(wire, '10.0.0.9');
      await other.open((_, _) {});
      final pending = a.contend(phrase: 'okay nabu', energy: 5, window: window);
      other.send(Uint8List.fromList([1, 2, 3]));
      other.send(Uint8List.fromList('{"ks":"wake","v":1}'.codeUnits));
      final r = await pending;
      expect(r.won, isTrue);
      expect(r.rivals, 0);
    });
  });

  group('UdpArbitrationTransport', () {
    Future<int> freePort() async {
      final probe = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final port = probe.port;
      probe.close();
      return port;
    }

    test('opens its port again after a failed send', () async {
      // A send fails without throwing: the socket reports the error on its
      // stream and closes, as with no network while Wi-Fi joins at boot.
      // An oversized datagram fails the same way on any machine.
      final port = await freePort();
      final transport = UdpArbitrationTransport(
        port: port,
        reopenAfter: const Duration(milliseconds: 50),
      );
      final received = <String>[];
      final reopened = Completer<void>();
      await transport.open(
        (data, from) => received.add(String.fromCharCodes(data)),
        onReopen: reopened.complete,
      );
      addTearDown(transport.close);

      transport.sendTo(Uint8List(70000), '127.0.0.1');
      await reopened.future.timeout(const Duration(seconds: 5));

      // Listening and sending again on the same port.
      transport.sendTo(Uint8List.fromList('hello'.codeUnits), '127.0.0.1');
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (received.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(received, ['hello']);
    });

    test('stays closed once closed', () async {
      final port = await freePort();
      var reopens = 0;
      final transport = UdpArbitrationTransport(
        port: port,
        reopenAfter: const Duration(milliseconds: 50),
      );
      await transport.open((_, _) {}, onReopen: () => reopens++);
      transport.sendTo(Uint8List(70000), '127.0.0.1');
      await transport.close();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(reopens, 0);
      // The port is free again.
      final other = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      other.close();
    });
  });
}
