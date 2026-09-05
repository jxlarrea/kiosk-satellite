import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/wake_word/chunk_telemetry.dart';

void main() {
  test('reports full chunk time while preserving per-model inference time', () async {
    final port = ReceivePort();
    final messages = <Map>[];
    final sub = port.listen((m) => messages.add(m as Map));
    final telemetry = ChunkTelemetry(port.sendPort);
    try {
      telemetry.begin(true);
      telemetry.add({'id': 'a', 'latencyUs': 1});
      telemetry.add({'id': 'b', 'latencyUs': 2});
      await Future<void>.delayed(Duration.zero);
      expect(messages, isEmpty);
      telemetry.end();
      await Future<void>.delayed(Duration.zero);
      expect(messages.map((m) => m['latencyUs']), [1, 2]);
      expect(messages[0]['chunkLatencyUs'], isA<int>());
      expect(messages[0]['chunkLatencyUs'], messages[1]['chunkLatencyUs']);
      telemetry.begin(false);
      telemetry.end();
      telemetry.begin(true);
      telemetry.end();
      await Future<void>.delayed(Duration.zero);
      expect(messages.length, 2, reason: 'empty chunks never replay old scores');
    } finally {
      await sub.cancel();
      port.close();
    }
  });
}
