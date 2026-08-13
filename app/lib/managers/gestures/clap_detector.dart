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
  ClapDetector({required this.onClaps, this.onDiscard});

  /// Fired with the clap count when a completed sequence matches [targets].
  final void Function(int count) onClaps;

  /// Diagnostic: a collected sequence was thrown away and why ("sustained
  /// sound after N claps", "closed with N claps, no match"). The one clue a
  /// field report of missed claps has, so the manager logs it at debug.
  final void Function(String reason)? onDiscard;

  /// Clap counts that fire (2..4, from the configured mappings). The count
  /// equal to the largest target fires the moment it lands; smaller targets
  /// wait out [_maxGapFrames] in case another clap is coming. Empty
  /// short-circuits [addChunk] entirely.
  Set<int> targets = const {};

  /// Strict mode (the gestures.clap_strictness setting): louder onsets, a
  /// longer quiet lead-in and tighter rhythm/loudness consistency. For homes
  /// where ordinary clatter (a child's toys was the field report) is
  /// impulsive enough to pass the standard checks.
  bool strict = false;

  // All tunables in 10 ms subframes of 160 samples.
  static const int _subframeSamples = 160;
  static const int _warmupFrames = 50; // let the noise floor settle first
  static const double _riseRatio = 3; // energy jump over the previous subframe
  static const double _minEnergy = 5e-5; // absolute onset floor (quiet mics ok)
  static const double _minHfRatio = 0.08; // diff-energy share = broadband
  static const int _refractoryFrames = 15; // 150 ms between claps
  static const int _decayCheckFrames = 25; // decay window: 250 ms past onset
  static const int _decayLateFrames = 10; // judged on its last 100 ms
  static const double _decayDropRatio = 32; // a clap is 15 dB down by then
  static const int _maxGapFrames = 70; // 700 ms between claps in a sequence
  static const int _vetoCooldownFrames = 100; // quiet-down after a false start
  static const double _leadLoudRatio = 10; // what counts as noise beforehand

  // Deliberateness: claps meant as a command come out of quiet, on a beat,
  // at one loudness. Random clatter shares the impulse shape but rarely all
  // three of those, which is what separates the two without a model.
  double get _onsetRatio => strict ? 40 : 20; // over the floor: 16 / 13 dB
  int get _quietLeadFrames => strict ? 50 : 30; // quiet before the first clap
  double get _rhythmMaxRatio => strict ? 1.5 : 1.8; // longest gap / shortest
  double get _levelMaxRatio => strict ? 6 : 12; // loudest clap / quietest

  int _frame = 0;
  double _floor = 1e-4;
  double _prevEnergy = 0;
  int _suppressedUntil = 0;

  /// Frame indices of the claps in the sequence being collected, and each
  /// one's onset energy for the loudness-consistency check.
  final List<int> _onsets = [];
  final List<double> _levels = [];

  /// The last frame that was loud relative to the floor: the quiet-lead-in
  /// check needs to know whether the room was calm before a first clap.
  int _lastLoudFrame = 0;

  /// Pending decay check for the newest clap. The judgment is RELATIVE to
  /// the clap's own peak, never near-absolute: a loud clap in a live room
  /// leaves reverb well above any fixed level at 250 ms (which is how loud
  /// close claps used to veto themselves, deterministically, while soft
  /// ones worked), but that reverb is 20+ dB below the clap's peak, where
  /// music or an alarm is still sitting at full level. Majority-of-window
  /// rather than one sampled frame, so a stray blip cannot decide it.
  int _decayCheckAt = -1;
  double _onsetEnergy = 0;
  double _onsetFloor = 0;
  int _lateLoud = 0;
  int _lateTotal = 0;

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
    _levels.clear();
    _lastLoudFrame = 0;
    _decayCheckAt = -1;
    _onsetEnergy = 0;
    _lateLoud = 0;
    _lateTotal = 0;
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

    // The decay check for the newest clap: a real clap has fallen far below
    // its own peak a quarter second after it hit. Something still near that
    // level is music, an alarm, a truck — cancel the sequence and stand down
    // briefly so a sustained sound cannot keep restarting it.
    if (_decayCheckAt > 0) {
      if (_frame > _decayCheckAt - _decayLateFrames) {
        _lateTotal++;
        // Near the clap's peak, above pre-clap ambience, and not mere noise:
        // all three, so neither a quiet room nor a noisy one skews the count.
        final loudBar = [
          _onsetEnergy / _decayDropRatio,
          _onsetFloor * 4,
          _minEnergy,
        ].reduce((a, b) => a > b ? a : b);
        if (energy > loudBar) _lateLoud++;
      } else if (energy > _onsetEnergy) {
        // The burst can peak a frame or two past the onset frame.
        _onsetEnergy = energy;
      }
      if (_frame == _decayCheckAt) {
        final veto = _lateLoud * 2 > _lateTotal;
        _decayCheckAt = -1;
        if (veto) {
          final count = _onsets.length;
          _onsets.clear();
          _levels.clear();
          _suppressedUntil = _frame + _vetoCooldownFrames;
          onDiscard?.call('sustained sound after $count clap(s)');
        }
      }
    }

    // Quiet lead-in: a first clap that is a command comes out of calm, not
    // out of ongoing clatter. Only the sequence's first clap needs it —
    // later ones follow other claps by design.
    final leadOk = _onsets.isNotEmpty ||
        _frame - _lastLoudFrame >= _quietLeadFrames;
    final canDetect = _frame > _warmupFrames &&
        _frame >= _suppressedUntil &&
        (_onsets.isEmpty || _frame - _onsets.last >= _refractoryFrames);
    if (canDetect &&
        leadOk &&
        energy > _minEnergy &&
        energy > _floor * _onsetRatio &&
        energy > _prevEnergy * _riseRatio &&
        hf > energy * _minHfRatio) {
      _onsets.add(_frame);
      _levels.add(energy);
      _decayCheckAt = _frame + _decayCheckFrames;
      _onsetEnergy = energy;
      _onsetFloor = _floor;
      _lateLoud = 0;
      _lateTotal = 0;
      // Nothing larger is configured, so there is nothing to wait for.
      var maxTarget = 0;
      for (final t in targets) {
        if (t > maxTarget) maxTarget = t;
      }
      if (_onsets.length >= maxTarget) _closeSequence();
    }

    // For the lead-in check, using the floor before this frame joins it.
    if (energy > _minEnergy && energy > _floor * _leadLoudRatio) {
      _lastLoudFrame = _frame;
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
    final onsets = List<int>.of(_onsets);
    final levels = List<double>.of(_levels);
    _onsets.clear();
    _levels.clear();
    _decayCheckAt = -1;
    // The tail of the last clap must not seed the next sequence.
    _suppressedUntil = _frame + _refractoryFrames;
    if (count < 2 || !targets.contains(count)) {
      onDiscard?.call('closed with $count clap(s), no match');
      return;
    }
    // Rhythm: deliberate claps land on a beat. Random bangs that happen to
    // reach the right count rarely keep their gaps within a factor of each
    // other. Two claps make one gap, so this starts at three.
    if (count >= 3) {
      var shortest = 1 << 30, longest = 0;
      for (var i = 1; i < onsets.length; i++) {
        final gap = onsets[i] - onsets[i - 1];
        if (gap < shortest) shortest = gap;
        if (gap > longest) longest = gap;
      }
      if (longest > shortest * _rhythmMaxRatio) {
        onDiscard?.call('$count claps with an uneven rhythm');
        return;
      }
    }
    // Loudness: one pair of hands claps at one level. A sequence mixing a
    // bang with a tap is clatter, not a command.
    var quietest = double.infinity, loudest = 0.0;
    for (final level in levels) {
      if (level < quietest) quietest = level;
      if (level > loudest) loudest = level;
    }
    if (loudest > quietest * _levelMaxRatio) {
      onDiscard?.call('$count claps with uneven loudness');
      return;
    }
    onClaps(count);
  }
}
