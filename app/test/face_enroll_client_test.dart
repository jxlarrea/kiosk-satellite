import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/ground_control/face_enroll.dart';

/// Face Recognition's guided capture against a stand-in Ground Control:
/// every frame sent is answered once, and the saved face ends it.
void main() {
  late HttpServer server;
  late StreamController<WebSocket> sockets;

  setUp(() async {
    sockets = StreamController<WebSocket>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path != '/api/face_enroll') {
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

  test('frames get progress, then the face is saved', () async {
    final events = <Map<String, Object?>>[];
    final answered = <int>[];
    final socket = FaceEnrollSocket.open(
      baseUrl: 'http://127.0.0.1:${server.port}',
      token: 'tok',
      ticket: 'tkt',
      deviceId: 'kitchen',
      deviceName: 'Kitchen',
      name: 'Mia',
      onEvent: events.add,
      onAnswered: answered.add,
    );
    final gc = await sockets.stream.first;
    final messages = StreamIterator(gc);
    expect(await messages.moveNext(), isTrue);
    final start = jsonDecode(messages.current as String) as Map;
    expect(start['name'], 'Mia');
    expect(start.containsKey('person_id'), isFalse);
    gc.add(jsonEncode({'type': 'ready', 'person_id': 'p1', 'name': 'Mia'}));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(socket.ready, isTrue);

    expect(
      socket.send(id: 4, rotation: 90, jpeg: Uint8List.fromList([0xff, 0xd8])),
      isTrue,
    );
    expect(await messages.moveNext(), isTrue);
    expect(jsonDecode(messages.current as String), {
      'type': 'frame',
      'id': 4,
      'rotation': 90,
    });
    expect(await messages.moveNext(), isTrue); // the JPEG
    gc.add(
      jsonEncode({
        'type': 'progress',
        'id': 4,
        'step': 'look',
        'have': 1,
        'need': 4,
        'hint': 'ok',
      }),
    );
    gc.add(jsonEncode({'type': 'saved', 'crops': 13, 'complete': true}));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(answered, [4]);
    expect(events.map((e) => e['type']), ['ready', 'progress', 'saved']);
    await gc.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // A socket that closes after the save says nothing more.
    expect(events.last['type'], 'saved');
  });

  test('a socket that goes before the save says so', () async {
    final events = <Map<String, Object?>>[];
    FaceEnrollSocket.open(
      baseUrl: 'http://127.0.0.1:${server.port}',
      token: 'tok',
      deviceId: 'kitchen',
      deviceName: 'Kitchen',
      personId: 'p1',
      onEvent: events.add,
      onAnswered: (_) {},
    );
    final gc = await sockets.stream.first;
    await gc.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(events.single, {'type': 'error', 'code': 'lost'});
  });
}
