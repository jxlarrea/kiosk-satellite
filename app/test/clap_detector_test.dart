import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/audio/mic_hub.dart';
import 'package:kiosk_satellite/managers/gestures/clap_detector.dart';

import 'clap_synth.dart';

/// Feed a signal in device-sized chunks (80 ms, 2560 bytes) plus a ragged
/// remainder, so chunk edges land mid-subframe like they do live.
void feed(ClapDetector detector, List<double> samples) {
  final bytes = pcmOf(samples);
  const chunk = 2560;
  for (var i = 0; i < bytes.length; i += chunk) {
    detector.addChunk(
      Uint8List.sublistView(bytes, i, min(i + chunk, bytes.length)),
    );
  }
}

void main() {
  group('ClapDetector', () {
    late List<int> fired;
    late ClapDetector detector;

    setUp(() {
      fired = [];
      detector = ClapDetector(onClaps: fired.add);
    });

    for (final count in [2, 3, 4]) {
      test('$count claps fire when $count is a target', () {
        detector.targets = {2, 3, 4};
        feed(detector, clapScene(count, Random(1)));
        expect(fired, [count]);
      });
    }

    test('a single clap never fires', () {
      detector.targets = {2, 3, 4};
      feed(detector, clapScene(1, Random(2)));
      expect(fired, isEmpty);
    });

    test('a count that is not a target stays silent', () {
      detector.targets = {3};
      feed(detector, clapScene(2, Random(3)));
      expect(fired, isEmpty);
    });

    test('the largest target fires without waiting for the gap', () {
      detector.targets = {2};
      final rng = Random(4);
      // No closing tail: the second clap itself must fire.
      feed(detector, [
        ...ambience(700, rng),
        ...clap(rng),
        ...ambience(300, rng),
        ...clap(rng),
        ...ambience(50, rng),
      ]);
      expect(fired, [2]);
    });

    test('a smaller target waits out the gap when a larger one exists', () {
      detector.targets = {2, 4};
      final rng = Random(5);
      final scene = clapScene(2, rng, tailMs: 0);
      feed(detector, scene);
      expect(fired, isEmpty, reason: 'two claps could still become four');
      feed(detector, ambience(900, rng));
      expect(fired, [2]);
    });

    test('sustained loudness is vetoed, not counted', () {
      detector.targets = {2};
      final rng = Random(6);
      feed(detector, [
        ...ambience(700, rng),
        ...sustained(800, rng),
        ...ambience(1500, rng),
      ]);
      expect(fired, isEmpty);
    });

    test('low-frequency thuds are not claps', () {
      detector.targets = {2};
      final rng = Random(7);
      feed(detector, [
        ...ambience(700, rng),
        ...thud(30),
        ...ambience(300, rng),
        ...thud(30),
        ...ambience(900, rng),
      ]);
      expect(fired, isEmpty);
    });

    test('loud claps with a live-room reverb tail still count', () {
      detector.targets = {2};
      final rng = Random(13);
      // Regression: the tail at 250 ms is far above any absolute floor but
      // 15+ dB below the clap's peak; only a peak-relative check passes it.
      feed(detector, [
        ...ambience(700, rng),
        ...reverbClap(rng),
        ...ambience(150, rng),
        ...reverbClap(rng),
        ...ambience(900, rng),
      ]);
      expect(fired, [2]);
    });

    test('claps quieter than the music under them do not fire', () {
      detector.targets = {2};
      final rng = Random(8);
      // The floor adapts up to the music level; a "clap" only 2x above it
      // is nowhere near the 13 dB jump a real clap makes.
      final music = sustained(3000, rng, amp: 0.2);
      final softClap = clap(rng, amp: 0.3);
      feed(detector, [
        ...music,
        ...softClap,
        ...sustained(300, rng, amp: 0.2),
        ...softClap,
        ...sustained(900, rng, amp: 0.2),
      ]);
      expect(fired, isEmpty);
    });

    test('reset drops a half-collected sequence', () {
      detector.targets = {2};
      final rng = Random(9);
      feed(detector, [...ambience(700, rng), ...clap(rng)]);
      detector.reset();
      feed(detector, [
        ...ambience(700, rng),
        ...clap(rng),
        ...ambience(900, rng),
      ]);
      expect(fired, isEmpty, reason: 'one clap before and after the reset');
    });

    test('empty targets cost nothing and fire nothing', () {
      detector.targets = const {};
      feed(detector, clapScene(3, Random(10)));
      expect(fired, isEmpty);
    });

    test('two sequences in a row both fire', () {
      detector.targets = {2};
      final rng = Random(11);
      feed(detector, clapScene(2, rng));
      feed(detector, [
        ...clap(rng),
        ...ambience(300, rng),
        ...clap(rng),
        ...ambience(900, rng),
      ]);
      expect(fired, [2, 2]);
    });
  });

  group('MicHub', () {
    test('opens on first listener, closes on last, bounces in place', () async {
      final hub = MicHub.instance;
      var opens = 0;
      final chunks = <Uint8List>[];
      hub.opener = () {
        opens++;
        return Stream<Uint8List>.periodic(
          const Duration(milliseconds: 5),
          (_) => Uint8List(4),
        );
      };
      expect(hub.capturing, isFalse);

      final a = hub.stream().listen(chunks.add);
      final b = hub.stream().listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(opens, 1, reason: 'two listeners share one capture');
      expect(hub.capturing, isTrue);
      expect(chunks, isNotEmpty);

      await hub.bounce();
      expect(opens, 2, reason: 'bounce reopens without dropping listeners');
      expect(hub.capturing, isTrue);

      await a.cancel();
      expect(hub.capturing, isTrue, reason: 'one listener remains');
      await b.cancel();
      expect(hub.capturing, isFalse, reason: 'last cancel closes capture');

      await hub.bounce();
      expect(opens, 2, reason: 'bounce with nothing open is a no-op');
    });
  });
}
