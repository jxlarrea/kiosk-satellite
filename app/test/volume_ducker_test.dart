import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/sendspin/volume_ducker.dart';

void main() {
  test(
    'factor changes keep the original volume and restoration resets capture',
    () async {
      var current = 60;
      final writes = <int>[];
      final ducker = VolumeDucker(
        capture: () async => [
          DuckingVolume(current, (level) async {
            writes.add(level);
            current = level;
            return true;
          }),
        ],
        onError: (error) => fail('$error'),
      );
      await ducker.update(active: true, factor: .1);
      await ducker.update(active: true, factor: .1);
      await ducker.update(active: true, factor: .25);
      expect(ducker.volume, 60);
      await ducker.update(active: false, factor: .25);
      expect(writes, [6, 15, 60]);
      current = 80;
      await ducker.update(active: true, factor: .1);
      await ducker.close();
      expect(writes, [6, 15, 60, 8, 80]);
    },
  );

  test('ending a turn during a slow duck restores after the write', () async {
    final gate = Completer<bool>();
    final writes = <int>[];
    final ducker = VolumeDucker(
      capture: () async => [
        DuckingVolume(70, (level) {
          writes.add(level);
          return writes.length == 1 ? gate.future : Future.value(true);
        }),
      ],
      onError: (error) => fail('$error'),
    );
    final start = ducker.update(active: true, factor: .1);
    await pumpEventQueue();
    final end = ducker.update(active: false, factor: .1);
    expect(writes, [7]);
    gate.complete(true);
    await Future.wait([start, end]);
    expect(writes, [7, 70]);
    expect(ducker.volume, isNull);
  });

  test('ending while volume is being read makes no temporary write', () async {
    final gate = Completer<List<DuckingVolume>?>();
    final writes = <int>[];
    final ducker = VolumeDucker(
      capture: () => gate.future,
      onError: (error) => fail('$error'),
    );
    final start = ducker.update(active: true, factor: .1);
    await pumpEventQueue();
    final end = ducker.close();
    gate.complete([
      DuckingVolume(70, (level) async {
        writes.add(level);
        return true;
      }),
    ]);
    await Future.wait([start, end]);
    expect(writes, isEmpty);
  });

  test('close restores an in-flight write and rejects later updates', () async {
    final gate = Completer<bool>();
    final writes = <int>[];
    final ducker = VolumeDucker(
      capture: () async => [
        DuckingVolume(70, (level) {
          writes.add(level);
          return writes.length == 1 ? gate.future : Future.value(true);
        }),
      ],
      onError: (error) => fail('$error'),
    );
    final start = ducker.update(active: true, factor: .1);
    await pumpEventQueue();
    final close = ducker.close();
    gate.complete(true);
    await Future.wait([start, close]);
    await ducker.update(active: true, factor: .1);
    expect(writes, [7, 70]);
  });

  test('group ducking to zero restores exact room levels', () async {
    final levels = [7, 43];
    final ducker = VolumeDucker(
      capture: () async => [
        for (var i = 0; i < levels.length; i++)
          DuckingVolume(levels[i], (value) async {
            levels[i] = value;
            return true;
          }),
      ],
      onError: (error) => fail('$error'),
    );
    await ducker.update(active: true, factor: 0);
    expect(levels, [0, 0]);
    await ducker.close();
    expect(levels, [7, 43]);
  });

  test(
    'manual volume changes stay ducked and become the restored volume',
    () async {
      final writes = <int>[];
      Future<bool> write(int level) async {
        writes.add(level);
        return true;
      }

      final ducker = VolumeDucker(
        capture: () async => [DuckingVolume(60, write)],
        onError: (error) => fail('$error'),
      );
      await ducker.update(active: true, factor: .1);
      expect(await ducker.setVolume(80, write), isTrue);
      expect(writes, [6, 8]);
      expect(ducker.volume, 80);
      await ducker.close();
      expect(writes, [6, 8, 80]);
    },
  );

  test(
    'failed and partial writes retain the original levels for restoration',
    () async {
      final levels = [20, 70];
      var failSecond = true;
      final errors = <Object>[];
      final ducker = VolumeDucker(
        capture: () async => [
          for (var i = 0; i < levels.length; i++)
            DuckingVolume(levels[i], (value) async {
              if (i == 1 && failSecond) throw StateError('offline');
              levels[i] = value;
              return true;
            }),
        ],
        onError: errors.add,
      );
      await ducker.update(active: true, factor: .1);
      expect(levels, [2, 70]);
      expect(errors, hasLength(1));
      failSecond = false;
      await ducker.close();
      expect(levels, [20, 70]);
    },
  );
}
