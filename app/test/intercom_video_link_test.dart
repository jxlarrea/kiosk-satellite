import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/intercom/intercom_video.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _Sink implements WebSocketSink {
  final items = <Object?>[];

  @override
  void add(Object? data) => items.add(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Channel implements WebSocketChannel {
  final incoming = StreamController<Object?>();
  final out = _Sink();

  @override
  Stream<Object?> get stream => incoming.stream;

  @override
  WebSocketSink get sink => out;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Uint8List frame({bool key = false}) =>
    Uint8List.fromList([if (key) 1 else 0, 0, 0, 0, 0, 0, 0, 0, 0, 9]);

void main() {
  late _Channel channel;
  late IntercomVideoLink link;
  late List<Uint8List> frames;
  late List<Map<String, Object?>> messages;

  setUp(() {
    channel = _Channel();
    frames = [];
    messages = [];
    link = IntercomVideoLink(
      channel,
      onFrame: frames.add,
      onMessage: messages.add,
      onClosed: (_) {},
    );
  });

  Future<void> ack(int n) async {
    channel.incoming.add(jsonEncode({'type': 'ack', 'n': n}));
    await Future<void>.delayed(Duration.zero);
  }

  Iterable<Object?> sentFrames() => channel.out.items.whereType<Uint8List>();

  test('sends until the far side falls behind, then drops', () {
    for (var i = 0; i < IntercomVideoLink.maxInFlight + 3; i++) {
      link.sendFrame(frame());
    }
    expect(sentFrames(), hasLength(IntercomVideoLink.maxInFlight));
    expect(link.dropped, 3);
  });

  test('after a drop only a key frame restarts the stream', () async {
    for (var i = 0; i < IntercomVideoLink.maxInFlight + 1; i++) {
      link.sendFrame(frame());
    }
    await ack(IntercomVideoLink.maxInFlight);
    link.sendFrame(frame());
    expect(sentFrames(), hasLength(IntercomVideoLink.maxInFlight));
    link.sendFrame(frame(key: true));
    expect(sentFrames(), hasLength(IntercomVideoLink.maxInFlight + 1));
    link.sendFrame(frame());
    expect(sentFrames(), hasLength(IntercomVideoLink.maxInFlight + 2));
  });

  test('a key frame waits its turn too while the link is behind', () {
    for (var i = 0; i < IntercomVideoLink.maxInFlight; i++) {
      link.sendFrame(frame());
    }
    link.sendFrame(frame(key: true));
    expect(sentFrames(), hasLength(IntercomVideoLink.maxInFlight));
  });

  test('an ack beyond what was sent changes nothing', () async {
    link.sendFrame(frame());
    await ack(50);
    for (var i = 0; i < IntercomVideoLink.maxInFlight + 2; i++) {
      link.sendFrame(frame());
    }
    expect(sentFrames(), hasLength(IntercomVideoLink.maxInFlight));
  });

  test('a received frame is acknowledged and handed on', () async {
    channel.incoming.add(frame());
    await Future<void>.delayed(Duration.zero);
    expect(frames, hasLength(1));
    final ack = channel.out.items.whereType<String>().single;
    expect(jsonDecode(ack), {'type': 'ack', 'n': 1});
  });

  test('other messages reach the manager', () async {
    channel.incoming.add(jsonEncode({'type': 'camera', 'on': true}));
    await Future<void>.delayed(Duration.zero);
    expect(messages, [
      {'type': 'camera', 'on': true},
    ]);
  });

  test('each quality has a size, a rate and a bitrate', () {
    for (final q in ['low', 'medium', 'high']) {
      final config = intercomVideoConfig(q);
      expect(config.keys, containsAll(['width', 'height', 'fps', 'bitrate']));
    }
    expect(
      intercomVideoConfig('high')['bitrate'] as int,
      greaterThan(intercomVideoConfig('low')['bitrate'] as int),
    );
  });
}
