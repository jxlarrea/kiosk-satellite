import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/voice/voice_match_client.dart';

/// The first message each session sends, from a local service.
Future<(HttpServer, Stream<Map<String, Object?>>)> _service() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final starts = StreamController<Map<String, Object?>>();
  server.listen((req) async {
    final ws = await WebSocketTransformer.upgrade(req);
    ws.listen((m) {
      if (m is! String) return;
      final msg = jsonDecode(m) as Map<String, Object?>;
      if (msg['type'] != 'start') return;
      starts.add(msg);
      ws.add(jsonEncode({'type': 'ready', 'session': 's1'}));
    });
  });
  return (server, starts.stream);
}

void main() {
  test('a follow-up says who the conversation already recognized', () async {
    final (server, starts) = await _service();
    final got = StreamIterator(starts);
    final sessions = <String>[];
    VoiceMatchTurn open({String? speaker, String? continues}) =>
        VoiceMatchTurn.open(
          baseUrl: 'http://127.0.0.1:${server.port}',
          token: 't',
          deviceId: 'k1',
          deviceName: 'Kitchen',
          policy: 'people',
          people: const ['xavier'],
          onEvent: (_) {},
          follow: true,
          speaker: speaker,
          continues: continues,
          onReady: sessions.add,
        );

    final first = open();
    expect(await got.moveNext(), isTrue);
    expect(got.current.containsKey('speaker'), isFalse);
    first.end();

    final followup = open(speaker: 'xavier', continues: 's1');
    expect(await got.moveNext(), isTrue);
    expect(got.current['speaker'], 'xavier');
    expect(got.current['continues'], 's1');
    expect(got.current['mode'], 'follow');
    followup.end();
    // The session id from the service's answer, for the next follow-up.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(sessions, ['s1', 's1']);
    await server.close(force: true);
  });

  test('a follow session says whether this kiosk wants Isolation', () async {
    final (server, starts) = await _service();
    final got = StreamIterator(starts);
    VoiceMatchTurn open({required bool follow, bool? isolation}) =>
        isolation == null
        ? VoiceMatchTurn.open(
            baseUrl: 'http://127.0.0.1:${server.port}',
            token: 't',
            deviceId: 'k1',
            deviceName: 'Kitchen',
            policy: 'anyone',
            onEvent: (_) {},
            follow: follow,
          )
        : VoiceMatchTurn.open(
            baseUrl: 'http://127.0.0.1:${server.port}',
            token: 't',
            deviceId: 'k1',
            deviceName: 'Kitchen',
            policy: 'anyone',
            isolation: isolation,
            onEvent: (_) {},
            follow: follow,
          );

    for (final (follow, isolation, expected) in [
      (true, false, false),
      (true, null, true), // on unless the kiosk turned it off
    ]) {
      final turn = open(follow: follow, isolation: isolation);
      expect(await got.moveNext(), isTrue);
      expect(got.current['isolation'], expected);
      turn.end();
    }
    // A live session has no Trimming, so nothing to isolate.
    final live = open(follow: false, isolation: true);
    expect(await got.moveNext(), isTrue);
    expect(got.current.containsKey('isolation'), isFalse);
    live.end();
    await server.close(force: true);
  });
}
