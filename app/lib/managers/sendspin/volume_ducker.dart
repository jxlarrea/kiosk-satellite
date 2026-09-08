import 'dart:async';

/// A volume captured before a voice turn. A Sonos group keeps one per
/// room so even ducking to zero preserves each room's original level.
class DuckingVolume {
  DuckingVolume(this.level, this.write);

  final int level;
  final Future<bool> Function(int percent) write;
}

/// Serializes temporary volume writes and restoration for one player.
/// Each queued operation reads the latest desired state. A voice turn
/// ending during a slow write therefore restores after that write ends.
class VolumeDucker {
  VolumeDucker({required this.capture, required this.onError});

  final Future<List<DuckingVolume>?> Function() capture;
  final void Function(Object error) onError;
  Future<void> _pending = Future.value();
  List<DuckingVolume>? _volumes;
  double? _applied = 1;
  double _factor = 1;
  bool _active = false;
  bool _closed = false;

  Future<void> update({required bool active, required double factor}) {
    if (_closed) return _pending;
    _active = active;
    _factor = factor.clamp(0, 1);
    return _enqueue();
  }

  /// The normal volume shown by the slider while temporary writes are
  /// echoed by the remote player. A group uses its rooms' average.
  int? get volume {
    final volumes = _volumes;
    if (volumes == null) return null;
    return (volumes.fold<int>(0, (sum, v) => sum + v.level) / volumes.length)
        .round();
  }

  /// A slider change during a voice turn changes the level restored at
  /// its end. The temporary output stays attenuated throughout the turn.
  Future<bool> setVolume(int percent, Future<bool> Function(int) write) {
    if (_closed) return Future.value(false);
    final operation = _pending
        .then((_) async {
          final volumes = _volumes;
          if (volumes == null) return write(percent);
          final previous = volume!;
          _volumes = [
            for (final item in volumes)
              DuckingVolume(
                (previous == 0 ? percent : item.level * percent / previous)
                    .round()
                    .clamp(0, 100),
                item.write,
              ),
          ];
          _applied = null;
          await _sync();
          return _applied != null;
        })
        .catchError((Object error) {
          onError(error);
          return false;
        });
    _pending = operation.then((_) {});
    return operation;
  }

  /// Stop accepting updates and put the old player back before its
  /// connection is closed, even if a duck request is still in flight.
  Future<void> close() {
    _closed = true;
    _active = false;
    return _enqueue();
  }

  Future<void> _enqueue() {
    return _pending = _pending.then((_) => _sync()).catchError((Object error) {
      onError(error);
    });
  }

  Future<void> _sync() async {
    if (_volumes == null) {
      if (!_active) return;
      final volumes = await capture();
      if (!_active || volumes == null || volumes.isEmpty) return;
      _volumes = volumes;
      _applied = 1;
    }
    final factor = _active ? _factor : 1.0;
    if (_applied != factor) {
      // A failed request may have reached the player. Keep the original
      // levels until restoration succeeds rather than capturing them again.
      _applied = null;
      final results = await Future.wait([
        for (final volume in _volumes!)
          volume.write((volume.level * factor).round().clamp(0, 100)),
      ]);
      if (results.any((ok) => !ok)) {
        onError(StateError('player refused a temporary volume change'));
        return;
      }
      _applied = factor;
    }
    if (!_active && factor == 1) _volumes = null;
  }
}
