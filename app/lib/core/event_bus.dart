import 'dart:async';

import 'events.dart';

/// Typed publish/subscribe bus.
///
/// Managers never import each other; they publish [AppEvent] subclasses here
/// and subscribe to the ones they care about. Subscriptions are delivered
/// asynchronously (broadcast stream semantics).
class EventBus {
  final _controller = StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  /// Events of a specific type.
  Stream<T> on<T extends AppEvent>() => _controller.stream.whereType<T>();

  void publish(AppEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  Future<void> dispose() => _controller.close();
}

extension _WhereType<T> on Stream<T> {
  Stream<S> whereType<S>() =>
      where((e) => e is S).map((e) => e as S);
}
