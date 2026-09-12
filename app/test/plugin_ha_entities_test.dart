import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/home_assistant/plugin_entities.dart';

void main() {
  test('compressed updates merge attributes, timestamps and removals', () {
    const id = 'sensor.room';
    final initial = applyEntityUpdates(
      {},
      {
        'a': {
          id: {
            's': '20',
            'a': {'unit': 'C', 'old': true},
            'lc': 1000,
          },
        },
      },
      {id},
    );
    expect(initial[id]!['lastChanged'], '1970-01-01T00:16:40.000Z');
    final changed = applyEntityUpdates(
      initial,
      {
        'c': {
          id: {
            '+': {
              'a': {'unit': 'F'},
              'lu': 1001,
            },
            '-': {
              'a': ['old'],
            },
          },
        },
      },
      {id},
    );
    expect(changed[id]!['attributes'], {'unit': 'F'});
    expect(changed[id]!['state'], '20');
    expect(changed[id]!['lastChanged'], initial[id]!['lastChanged']);
    expect(changed[id]!['lastUpdated'], '1970-01-01T00:16:41.000Z');
    final state = applyEntityUpdates(
      changed,
      {
        'c': {
          id: {
            '+': {'s': 'unknown', 'lc': 1002},
          },
        },
      },
      {id},
    );
    expect(state[id]!['status'], 'unknown');
    expect(state[id]!['lastChanged'], state[id]!['lastUpdated']);
    final removed = applyEntityUpdates(
      state,
      {
        'r': [id],
      },
      {id},
    );
    expect(removed[id]!['status'], 'missing');
    expect(removed[id]!['state'], isNull);
    expect(removed[id]!['attributes'], isEmpty);
    expect(
      applyEntityUpdates(
        {},
        {
          'a': {
            'sensor.other': {'s': '1'},
          },
        },
        {id},
      ),
      isEmpty,
    );
  });

  test(
    'snapshots detach attributes, omit context and bound oversized entities',
    () {
      final attributes = {
        'nested': [1, 2],
      };
      final result = HaPluginEntities.snapshot('sensor.room', {
        'state': 'unavailable',
        'attributes': attributes,
        'context': {'user_id': 'private'},
      });
      attributes['nested']!.add(3);
      expect(result['attributes'], {
        'nested': [1, 2],
      });
      expect(result.containsKey('context'), false);
      expect(result['status'], 'unavailable');
      expect(
        HaPluginEntities.snapshot('sensor.room', {
          'state': 'ok',
          'attributes': {'large': 'x' * 40000},
        })['status'],
        'too_large',
      );
      for (final id in ['sensor.room', 'binary_sensor.door']) {
        expect(HaPluginEntities.validId(id), true);
      }
      for (final id in [
        'sensor.*',
        '../config',
        'sensor.room?token=x',
        'sensor.room/more',
        '',
      ]) {
        expect(HaPluginEntities.validId(id), false);
      }
    },
  );

  test(
    'read and subscription reconnect without leaking credentials or old states',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <WebSocket>[];
      final subscribed = <List<dynamic>>[];
      final events = <Map<String, Object?>>[];
      final owners = <String>[];
      final source = HaPluginEntities(
        baseUrl: () => 'http://127.0.0.1:${server.port}',
        token: () => 'test-only-token',
        emit: (owner, id, state) {
          owners.add(owner);
          events.add(state);
        },
      );
      server.listen((request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          sockets.add(socket);
          socket.add(jsonEncode({'type': 'auth_required'}));
          socket.listen((raw) {
            final frame = jsonDecode(raw as String) as Map;
            if (frame['type'] == 'auth') {
              expect(frame['access_token'], 'test-only-token');
              socket.add(jsonEncode({'type': 'auth_ok'}));
            } else if (frame['type'] == 'subscribe_entities') {
              subscribed.add(frame['entity_ids'] as List);
              socket.add(
                jsonEncode({'id': 1, 'type': 'result', 'success': true}),
              );
              socket.add(
                jsonEncode({
                  'id': 1,
                  'type': 'event',
                  'event': {
                    'a': {
                      'sensor.room': {
                        's': '21',
                        'a': {'unit': 'C'},
                        'lc': 1000,
                      },
                    },
                  },
                }),
              );
            }
          });
        } else {
          expect(
            request.headers.value('Authorization'),
            'Bearer test-only-token',
          );
          request.response.headers.contentType = ContentType.json;
          if (request.uri.path.endsWith('sensor.missing')) {
            request.response.statusCode = 404;
          } else {
            request.response.write(
              jsonEncode({
                'entity_id': 'sensor.room',
                'state': '20',
                'attributes': {'unit': 'C'},
                'last_changed': 'now',
              }),
            );
          }
          await request.response.close();
        }
      });
      Future<void> until(bool Function() condition) async {
        final end = DateTime.now().add(const Duration(seconds: 5));
        while (!condition() && DateTime.now().isBefore(end)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(condition(), true);
      }

      try {
        expect((await source.read('sensor.room'))['state'], '20');
        expect((await source.read('sensor.missing'))['status'], 'missing');
        source.watch('one', 'sensor.room');
        source.watch('one', 'sensor.missing');
        await until(() => events.any((e) => e['status'] == 'available'));
        expect(subscribed.single.toSet(), {'sensor.room', 'sensor.missing'});
        expect(
          events.any(
            (e) =>
                e['entityId'] == 'sensor.missing' && e['status'] == 'missing',
          ),
          true,
        );
        source.watch('two', 'sensor.room');
        expect(owners.last, 'two');
        expect(events.last['state'], '21');
        expect(sockets.length, 1);
        await sockets.first.close();
        await until(() => events.any((e) => e['status'] == 'disconnected'));
        await until(
          () => sockets.length == 2 && events.last['status'] != 'connecting',
        );
        expect(jsonEncode(events).contains('test-only-token'), false);
        source.unwatch('one');
        source.unwatch('two');
        final count = events.length;
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(events.length, count);
      } finally {
        source.dispose();
        for (final socket in sockets) {
          await socket.close();
        }
        await server.close(force: true);
      }
    },
  );

  test(
    'unconfigured subscriptions report status and stop after removal',
    () async {
      final states = <String>[];
      final source = HaPluginEntities(
        baseUrl: () => '',
        token: () => '',
        emit: (_, _, data) => states.add(data['status'] as String),
      );
      try {
        expect((await source.read('sensor.room'))['status'], 'not_configured');
        source.watch('one', 'sensor.room');
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(states, ['not_configured']);
        source.unwatch('one');
        source.restart();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(states.length, 1);
      } finally {
        source.dispose();
      }
    },
  );
}
