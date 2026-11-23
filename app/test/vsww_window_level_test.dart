import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/wake_word/vsww/window_level.dart';

const _window = 20800; // 1.3 s at 16 kHz
const _span = 8000; // 500 ms
const _hop = 160;

/// A window that is quiet apart from [burst] samples of a sine at
/// amplitude [amp] starting at [at], in time order.
Float32List _burst(double amp, int at, int burst, {double floor = 0}) {
  final w = Float32List(_window);
  for (var i = 0; i < _window; i++) {
    w[i] = floor * math.sin(i * 0.37);
  }
  for (var i = at; i < at + burst; i++) {
    w[i] = amp * math.sin(2 * math.pi * 440 * i / 16000);
  }
  return w;
}

double _rms(Float32List w) {
  var s = 0.0;
  for (final v in w) {
    s += v * v;
  }
  return math.sqrt(s / w.length);
}

/// [w] laid into a ring whose oldest sample is at [head].
Float32List _asRing(Float32List w, int head) {
  final ring = Float32List(w.length);
  for (var i = 0; i < w.length; i++) {
    ring[(head + i) % w.length] = w[i];
  }
  return ring;
}

void main() {
  test('a word in half the window reads at its own level', () {
    // A 600 ms word at -52 dBFS RMS: speech peaking around -40 dBFS on the
    // quiet microphone of #1568.
    const wordRms = 0.0025;
    final w = _burst(wordRms * math.sqrt2, 10000, 9600);
    final loudest = loudestRms(w, 0, _span, step: _hop);
    expect(loudest, closeTo(wordRms, 1e-5));
    // Below the veto over the whole window, at it over the word.
    expect(_rms(w), lessThan(0.002));
    expect(loudest, greaterThanOrEqualTo(0.002));
  });

  test('steady quiet speech reads the same either way', () {
    final amp = math.pow(10, -60 / 20).toDouble();
    final w = _burst(amp, 0, _window);
    expect(loudestRms(w, 0, _span, step: _hop), closeTo(_rms(w), 1e-5));
    expect(loudestRms(w, 0, _span, step: _hop), lessThan(0.002));
  });

  test('never reads below the whole window on even content', () {
    final w = _burst(0.01, 3000, 2000, floor: 0.0005);
    expect(loudestRms(w, 0, _span, step: _hop), greaterThan(_rms(w)));
  });

  test('the ring head does not change the result', () {
    final w = _burst(0.01, 15000, 4000);
    final straight = loudestRms(w, 0, _span, step: _hop);
    for (final head in [1, 160, 7777, 20799]) {
      expect(
        loudestRms(_asRing(w, head), head, _span, step: _hop),
        closeTo(straight, 1e-9),
      );
    }
  });

  test('a span that covers the window is the window RMS', () {
    final w = _burst(0.01, 0, 5000);
    expect(loudestRms(w, 0, _window, step: _hop), closeTo(_rms(w), 1e-9));
    expect(loudestRms(w, 0, 0, step: _hop), closeTo(_rms(w), 1e-9));
  });

  test('silence reads zero', () {
    expect(loudestRms(Float32List(_window), 0, _span, step: _hop), 0);
  });
}
