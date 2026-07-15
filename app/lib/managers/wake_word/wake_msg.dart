/// Tags exchanged with a wake-word compute isolate.
///
/// One vocabulary for all three engines: they run different models but the
/// conversation is the same shape, and three copies of these constants only
/// ever drifted in the direction of a typo.
///
/// Deliberately a leaf with no imports: the compute isolates depend on this,
/// and they must not pull in the mic's platform channel — a channel is bound to
/// the platform isolate and unusable from theirs.
library;

class WakeMsg {
  // isolate -> main
  static const ready = 'ready';
  static const detection = 'detection';
  static const error = 'error';
  static const log = 'log';
  static const stopped = 'stopped';

  // main -> isolate (control; audio arrives as a bare Uint8List)
  static const init = 'init';
  static const stop = 'stop';
  static const resume = 'resume';
  static const armStop = 'armStop';
}
