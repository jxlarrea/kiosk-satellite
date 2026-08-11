import 'dart:typed_data';

/// Detects clap sequences (2 to 4 sharp broadband transients) in the 16 kHz
/// mono PCM16 microphone stream.
///
/// Deliberately not a model: a clap is an impulse — a jump of an order of
/// magnitude over the ambient level inside 10 ms, broadband enough to carry
/// high-frequency energy, gone again within a quarter second. Those three
/// facts are checked directly on subframe energies, which costs arithmetic
/// only (no FFT, no inference) and is measurement noise next to the wake-word
/// pipeline sharing the same stream.
///
/// Thresholds are relative to a running noise floor, never absolute: capture
/// levels vary by 30 dB across devices (the Echo Show 5 taught us that), and
/// a floor-relative jump is the thing a clap is. The floor tracks upward
/// slowly, so sustained loudness (music, speech) raises the bar rather than
/// firing through it, and the decay check throws out anything loud that
/// fails to die away — a clap that never ends is not a clap.
///
/// Time is counted in samples fed, not wall-clock: the mic delivers
/// continuously while open, and a deterministic clock is what makes this
/// testable with synthetic PCM.
class ClapDetector {
  ClapDetector({required this.onClaps});

  /// Fired with the clap count when a completed sequence matches [targets].
  final void Function(int count) onClaps;

  /// Clap counts that fire (2..4, from the configured mappings). The count
  /// equal to the largest target fires the moment it lands; smaller targets
  /// wait out [_maxGapFrames] in case another clap is coming. Empty
  /// short-circuits [addChunk] entirely.
  Set<int> targets = const {};

  // All tunables in 10 ms subframes of 160 samples.
  static const int _subframeSamples = 160;
  static const int _warmupFrames = 50; // let the noise floor settle first
  static const double _onsetRatio = 20; // energy jump over the floor (13 dB)
  static const double _riseRatio = 3; // and over the previous subframe
  static const double _minEnergy = 5e-5; // absolute onset floor (quiet mics ok)
  static const double _minHfRatio = 0.08; // diff-energy share = broadband
  static const int _refractoryFrames = 15; // 150 ms between claps
  static const int _decayCheckFrames = 25; // a clap has died away by here
  static const double _decayRatio = 8; // still this loud = not a clap
  static const int _maxGapFrames = 70; // 700 ms between claps in a sequence
  static const int _vetoCooldownFrames = 100; // quiet-down after a false start

  int _frame = 0;
  double _floor = 1e-4;
  double _prevEnergy = 0;
  int _suppressedUntil = 0;

  /// Frame indices of the claps in the sequence being collected.
  final List<int> _onsets = [];

  /// Pending decay check: the frame to look at and the floor at onset time.
  int _decayCheckAt = -1;
  double _decayFloor = 0;

  /// Partial subframe carried between chunks, plus the last sample of the
  /// previous subframe so the first difference is continuous across edges.
  final Int16List _carry = Int16List(_subframeSamples);
  int _carried = 0;
  double _lastSample = 0;

  /// Drop all state, including the noise floor: used when detection was
  /// suppressed (a voice turn ran, the mic reopened) and the acoustic world
  /// may have changed under us. Detection resumes after the warmup.
  void reset() {
    _frame = 0;
    _floor = 1e-4;
    _prevEnergy = 0;
    _suppressedUntil = 0;
    _onsets.clear();
    _decayCheckAt = -1;
    _carried = 0;
    _lastSample = 0;
  }

  /// Feed one chunk of little-endian PCM16 mono bytes.
  void addChunk(Uint8List bytes) {
    if (targets.isEmpty) return;
    final data = ByteData.sublistView(bytes);
    final samples = bytes.length ~/ 2;
    for (var i = 0; i < samples; i++) {
      _carry[_carried++] = data.getInt16(i * 2, Endian.little);
      if (_carried == _subframeSamples) {
        _subframe();
        _carried = 0;
      }
    }
  }

  void _subframe() {
    // Energy and first-difference energy, on full-scale-normalized samples.
    // The difference is a crude high-pass: broadband transients keep a large
    // share of their energy in it, low-frequency hum and vowels almost none.
    var sumSq = 0.0;
    var sumDiffSq = 0.0;
    var prev = _lastSample;
    for (var i = 0; i < _subframeSamples; i++) {
      final x = _carry[i] / 32768.0;
      sumSq += x * x;
      final d = x - prev;
      sumDiffSq += d * d;
      prev = x;
    }
    _lastSample = prev;
    final energy = sumSq / _subframeSamples;
    final hf = sumDiffSq / _subframeSamples;
    _frame++;

    // A sequence nobody added to for too long is complete: fire it if the
    // count is one of the configured ones, forget it either way.
    if (_onsets.isNotEmpty && _frame - _onsets.last > _maxGapFrames) {
      _closeSequence();
    }

    // The decay check for the newest clap: a real clap is back near the
    // floor a quarter second after it hit. Something still loud is music,
    // an alarm, a truck — cancel the sequence and stand down briefly so a
    // sustained sound cannot keep restarting it.
    if (_frame == _decayCheckAt) {
      _decayCheckAt = -1;
      if (energy > _minEnergy && energy > _decayFloor * _decayRatio) {
        _onsets.clear();
        _suppressedUntil = _frame + _vetoCooldownFrames;
      }
    }

    final canDetect = _frame > _warmupFrames &&
        _frame >= _suppressedUntil &&
        (_onsets.isEmpty || _frame - _onsets.last >= _refractoryFrames);
    if (canDetect &&
        energy > _minEnergy &&
        energy > _floor * _onsetRatio &&
        energy > _prevEnergy * _riseRatio &&
        hf > energy * _minHfRatio) {
      _onsets.add(_frame);
      _decayCheckAt = _frame + _decayCheckFrames;
      _decayFloor = _floor;
      // Nothing larger is configured, so there is nothing to wait for.
      var maxTarget = 0;
      for (final t in targets) {
        if (t > maxTarget) maxTarget = t;
      }
      if (_onsets.length >= maxTarget) _closeSequence();
    }

    // Asymmetric noise-floor EMA: falls fast, rises slowly (a ~500 ms time
    // constant), so a clap barely moves it but steady loudness becomes the
    // new normal that claps must then punch through.
    _floor += (energy < _floor ? 0.3 : 0.02) * (energy - _floor);
    if (_floor < 1e-7) _floor = 1e-7;
    _prevEnergy = energy;
  }

  void _closeSequence() {
    final count = _onsets.length;
    _onsets.clear();
    _decayCheckAt = -1;
    // The tail of the last clap must not seed the next sequence.
    _suppressedUntil = _frame + _refractoryFrames;
    if (count >= 2 && targets.contains(count)) onClaps(count);
  }
}
