import 'dart:async';

/// Runs keyed work one piece at a time and lets its callers share a run.
///
/// Callers that ask for the same key while it waits for its turn all get
/// the one run that starts after they asked, so no answer is older than its
/// request. A caller that arrives once that run has started waits for the
/// next one. However many callers pile up, one run is in flight and one per
/// key is waiting.
class SerialShared<T> {
  Future<void> _tail = Future<void>.value();
  final _waiting = <Object, Future<T>>{};

  Future<T> run(Object key, Future<T> Function() task) {
    final waiting = _waiting[key];
    if (waiting != null) return waiting;
    final done = Completer<T>();
    _waiting[key] = done.future;
    _tail = _tail.then((_) async {
      _waiting.remove(key);
      try {
        done.complete(await task());
      } catch (e, s) {
        done.completeError(e, s);
      }
    });
    return done.future;
  }
}
