import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/serial_shared.dart';

void main() {
  test('a burst of callers costs one run in flight and one waiting', () async {
    final shared = SerialShared<int>();
    final gates = <Completer<void>>[];
    var runs = 0;
    var live = 0;
    var most = 0;
    Future<int> task() async {
      final run = ++runs;
      live++;
      if (live > most) most = live;
      final gate = Completer<void>();
      gates.add(gate);
      await gate.future;
      live--;
      return run;
    }

    final first = shared.run('a', task);
    await pumpEventQueue();
    expect(runs, 1);
    // Asked while the first run is in flight: all of these share the next
    // run, which starts after they asked.
    final burst = [for (var i = 0; i < 200; i++) shared.run('a', task)];
    await pumpEventQueue();
    expect(runs, 1);
    gates[0].complete();
    expect(await first, 1);
    await pumpEventQueue();
    expect(runs, 2);
    gates[1].complete();
    expect(await Future.wait(burst), everyElement(2));
    expect(most, 1);
  });

  test('different keys take turns and a failed run frees the next', () async {
    final shared = SerialShared<String>();
    final order = <String>[];
    final gate = Completer<void>();
    final a = shared.run('a', () async {
      order.add('a');
      await gate.future;
      throw StateError('a failed');
    });
    final b = shared.run('b', () async {
      order.add('b');
      return 'b';
    });
    await pumpEventQueue();
    expect(order, ['a']);
    gate.complete();
    await expectLater(a, throwsStateError);
    expect(await b, 'b');
    expect(order, ['a', 'b']);
    expect(await shared.run('a', () async => 'again'), 'again');
  });
}
