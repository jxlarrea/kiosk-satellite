import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/ground_control/vision_match_client.dart';

/// Vision Match's socket against a stand-in Ground Control: every frame
/// sent gets exactly one answer, a result or a failure.
void main() {
  late HttpServer server;
  late StreamController<WebSocket> sockets;

  setUp(() async {
    sockets = StreamController<WebSocket>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path != '/api/vision') {
        request.response.statusCode = 404;
        await request.response.close();
        return;
      }
      sockets.add(await WebSocketTransformer.upgrade(request));
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await sockets.close();
  });

  ({
    VisionMatchSocket socket,
    Completer<(double?, double?)> ready,
    List<Map<String, Object?>> answers,
    Completer<void> lost,
  })
  open() {
    final ready = Completer<(double?, double?)>();
    final answers = <Map<String, Object?>>[];
    final lost = Completer<void>();
    final socket = VisionMatchSocket.open(
      baseUrl: 'http://127.0.0.1:${server.port}',
      token: 'tok',
      ticket: 'tkt',
      deviceId: 'kitchen',
      deviceName: 'Kitchen',
      want: const ['face', 'hands'],
      onReady: (face, hands) => ready.complete((face, hands)),
      onResult: answers.add,
      onLost: () => lost.complete(),
    );
    return (socket: socket, ready: ready, answers: answers, lost: lost);
  }

  test('a frame comes back with its faces and hand', () async {
    final c = open();
    final gc = await sockets.stream.first;
    final messages = StreamIterator(gc);
    expect(await messages.moveNext(), isTrue);
    final start = jsonDecode(messages.current as String) as Map;
    expect(start['type'], 'start');
    expect(start['ticket'], 'tkt');
    expect(start['want'], ['face', 'hands']);
    gc.add(
      jsonEncode({
        'type': 'ready',
        'model': 'light',
        'max_looks': {'face': 40.0, 'hands': 12.5},
      }),
    );
    expect(await c.ready.future, (40.0, 12.5));

    final jpeg = Uint8List.fromList([0xff, 0xd8, 1, 2, 3]);
    expect(
      c.socket.send(id: 7, rotation: 90, want: ['face'], jpeg: jpeg),
      isTrue,
    );
    expect(await messages.moveNext(), isTrue);
    final header = jsonDecode(messages.current as String) as Map;
    expect(header, {
      'type': 'frame',
      'id': 7,
      'rotation': 90,
      'want': ['face'],
    });
    expect(await messages.moveNext(), isTrue);
    expect(messages.current, jpeg);
    gc.add(
      jsonEncode({
        'type': 'result',
        'id': 7,
        'faces': [
          {
            'box': [0.4, 0.2, 0.1, 0.15],
            'frontal': true,
          },
        ],
      }),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.answers, hasLength(1));
    expect(c.answers.single['id'], 7);
    await c.socket.close();
  });

  test('frames carry their encoding time and the last round trip', () async {
    final c = open();
    final gc = await sockets.stream.first;
    final messages = StreamIterator(gc);
    expect(await messages.moveNext(), isTrue); // start
    gc.add(
      jsonEncode({
        'type': 'ready',
        'max_looks': {'face': 2, 'hands': 2},
      }),
    );
    await c.ready.future;
    final jpeg = Uint8List.fromList([0xff, 0xd8]);
    c.socket.send(
      id: 1,
      rotation: 0,
      want: ['face'],
      jpeg: jpeg,
      encodeMs: 8.5,
    );
    expect(await messages.moveNext(), isTrue);
    final first = jsonDecode(messages.current as String) as Map;
    expect(first['encode_ms'], 8.5);
    expect(first.containsKey('rtt_ms'), isFalse);
    expect(await messages.moveNext(), isTrue); // its JPEG
    gc.add(jsonEncode({'type': 'result', 'id': 1, 'faces': []}));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    c.socket.send(id: 2, rotation: 0, want: ['face'], jpeg: jpeg);
    expect(await messages.moveNext(), isTrue);
    final second = jsonDecode(messages.current as String) as Map;
    expect(second['rtt_ms'], isA<num>());
    expect(second.containsKey('encode_ms'), isFalse);
    expect(await messages.moveNext(), isTrue); // its JPEG

    c.socket.outcome('gesture', fingers: 3, action: 'Refresh the dashboard');
    expect(await messages.moveNext(), isTrue);
    expect(jsonDecode(messages.current as String), {
      'type': 'outcome',
      'what': 'gesture',
      'fingers': 3,
      'action': 'Refresh the dashboard',
    });
    await c.socket.close();
  });

  test('a dropped frame and a frame that could not be read fail', () async {
    final c = open();
    final gc = await sockets.stream.first;
    gc.add(
      jsonEncode({
        'type': 'ready',
        'max_looks': {'face': 2, 'hands': 2},
      }),
    );
    await c.ready.future;
    final jpeg = Uint8List.fromList([0xff, 0xd8]);
    c.socket.send(id: 1, rotation: 0, want: ['hands'], jpeg: jpeg);
    c.socket.send(id: 2, rotation: 0, want: ['hands'], jpeg: jpeg);
    gc.add(jsonEncode({'type': 'dropped', 'id': 1}));
    gc.add(jsonEncode({'type': 'error', 'id': 2, 'code': 'bad_frame'}));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.answers, [
      {'id': 1, 'failed': true},
      {'id': 2, 'failed': true},
    ]);
    await c.socket.close();
  });

  test('a socket that goes fails its waiting frames and says so', () async {
    final c = open();
    final gc = await sockets.stream.first;
    gc.add(
      jsonEncode({
        'type': 'ready',
        'max_looks': {'face': 2, 'hands': 2},
      }),
    );
    await c.ready.future;
    c.socket.send(id: 3, rotation: 0, want: ['face'], jpeg: Uint8List(2));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await gc.close();
    await c.lost.future.timeout(const Duration(seconds: 2));
    expect(c.answers, [
      {'id': 3, 'failed': true},
    ]);
    expect(c.socket.ready, isFalse);
    expect(
      c.socket.send(id: 4, rotation: 0, want: ['face'], jpeg: Uint8List(2)),
      isFalse,
    );
  });

  test('a refusal before the first frame closes the socket', () async {
    final c = open();
    final gc = await sockets.stream.first;
    gc.add(jsonEncode({'type': 'error', 'code': 'vision_unavailable'}));
    await c.lost.future.timeout(const Duration(seconds: 2));
    expect(c.ready.isCompleted, isFalse);
  });

  test('Face Recognition: the person at the kiosk and everyone in view, '
      'said once when either changes', () async {
    final seen = <String>[];
    final socket = VisionMatchSocket.open(
      baseUrl: 'http://127.0.0.1:${server.port}',
      token: 'tok',
      deviceId: 'kitchen',
      deviceName: 'Kitchen',
      want: const ['face'],
      onReady: (_, _) {},
      onResult: (_) {},
      onLost: () {},
      recognize: true,
      onPerson: (person, people) => seen.add(
        '${person?['id']}: ${people.map((p) => p['id']).join(', ')}',
      ),
    );
    final gc = await sockets.stream.first;
    final ana = {'id': 'ana', 'name': 'Ana', 'color': '#56814F', 'score': 0.7};
    final leo = {'id': 'leo', 'name': 'Leo', 'score': 0.5};
    gc
      ..add(
        jsonEncode({
          'type': 'person',
          'person': ana,
          'people': [ana],
        }),
      )
      ..add(
        jsonEncode({
          'type': 'person',
          'person': ana,
          'people': [ana],
        }),
      )
      ..add(
        jsonEncode({
          'type': 'person',
          'person': ana,
          'people': [ana, leo],
        }),
      )
      // An older Ground Control: the person at the kiosk alone.
      ..add(jsonEncode({'type': 'person', 'person': leo}))
      ..add(jsonEncode({'type': 'person', 'person': null, 'people': []}));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(seen, ['ana: ana', 'ana: ana, leo', 'leo: leo', 'null: ']);
    await socket.close();
  });
}
