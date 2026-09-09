import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/audio/mic_hub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final hub = MicHub.instance;
  final opener = hub.opener;

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
    'RTSP shares capture and browser ownership releases every native reader',
    () async {
      var opens = 0;
      var closes = 0;
      final captures = <StreamController<Uint8List>>[];
      hub.opener = () {
        opens++;
        final stream = StreamController<Uint8List>(
          onCancel: () {
            closes++;
          },
        );
        captures.add(stream);
        return stream.stream;
      };
      final wakeFrames = <Uint8List>[];
      final rtspFrames = <Uint8List>[];
      final wake = hub.stream().listen(wakeFrames.add);
      final rtsp = hub.stream().listen(rtspFrames.add);
      await settle();
      expect(opens, 1);
      captures.last.add(Uint8List.fromList([1, 2]));
      await settle();
      expect(wakeFrames.single, rtspFrames.single);
      await wake.cancel();
      await settle();
      expect(closes, 0);
      await hub.setBrowserCapturing(true);
      expect(closes, 1);
      expect(hub.capturing, false);
      await hub.bounce();
      expect(opens, 1);
      await hub.setBrowserCapturing(false);
      expect(opens, 2);
      await rtsp.cancel();
      await settle();
      expect(closes, 2);
      hub.opener = opener;
      for (final stream in captures) {
        await stream.close();
      }
    },
  );

  test(
    'a subscriber joining during cancellation waits before reopening',
    () async {
      final closed = Completer<void>();
      var opens = 0;
      hub.opener = () {
        opens++;
        return StreamController<Uint8List>(
          onCancel: () => closed.future,
        ).stream;
      };
      final first = hub.stream().listen((_) {});
      await settle();
      await first.cancel();
      await settle();
      final second = hub.stream().listen((_) {});
      await settle();
      expect(opens, 1);
      closed.complete();
      await settle();
      expect(opens, 2);
      await second.cancel();
      await settle();
      hub.opener = opener;
    },
  );
}
