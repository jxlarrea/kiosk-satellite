import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_manager.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Weather widget's high and low come from the daily forecast, asked
/// for over the entity subscription's own socket (issue #1262). Home
/// Assistant rejects an id lower than one it already saw, so the forecast
/// must not push the translation lookups or the pings below it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GlanceSubscription.heartbeat = const Duration(milliseconds: 50);
    GlanceSubscription.pongTimeout = const Duration(milliseconds: 200);
  });
  tearDown(() {
    GlanceSubscription.heartbeat = const Duration(seconds: 30);
    GlanceSubscription.pongTimeout = const Duration(seconds: 10);
  });

  test('delivers the daily forecast with ids that only go up', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final ids = <int>[];
    final rejected = <String>[];
    var pongs = 0;
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.add(jsonEncode({'type': 'auth_required'}));
      socket.listen((raw) {
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        final type = '${msg['type']}';
        if (type == 'auth') {
          socket.add(jsonEncode({'type': 'auth_ok'}));
          return;
        }
        final id = msg['id'] as int;
        if (ids.isNotEmpty && id <= ids.last) rejected.add('$type $id');
        ids.add(id);
        Map<String, Object?> result(Object? value) => {
          'id': id,
          'type': 'result',
          'success': true,
          'result': value,
        };
        switch (type) {
          case 'subscribe_entities':
            socket.add(jsonEncode(result(null)));
            socket.add(
              jsonEncode({
                'id': id,
                'type': 'event',
                'event': {
                  'a': {
                    'weather.home': {
                      's': 'rainy',
                      'a': {'temperature': 28},
                    },
                  },
                },
              }),
            );
          case 'weather/subscribe_forecast':
            expect(msg['entity_id'], 'weather.home');
            expect(msg['forecast_type'], 'daily');
            socket.add(jsonEncode(result(null)));
            socket.add(
              jsonEncode({
                'id': id,
                'type': 'event',
                'event': {
                  'type': 'daily',
                  'forecast': [
                    {
                      'datetime': DateTime.now().toUtc().toIso8601String(),
                      'condition': 'pouring',
                      'temperature': 31.6,
                      'templow': 24.4,
                    },
                  ],
                },
              }),
            );
          case 'frontend/get_user_data':
            socket.add(jsonEncode(result({'value': 'fr'})));
          case 'frontend/get_translations':
            socket.add(jsonEncode(result({'resources': {}})));
          case 'ping':
            pongs++;
            socket.add(jsonEncode({'id': id, 'type': 'pong'}));
        }
      });
    });
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://127.0.0.1:${server.port}',
      'ks.ha.token': 'token',
    });
    final bus = EventBus();
    final log = Logger();
    final settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
    final ha = HomeAssistantManager(bus, CommandRegistry(log), log, settings);

    final states = <String>[];
    final forecast = Completer<Object?>();
    final live = await ha.subscribeEntities(
      ['weather.home'],
      (id, state) => states.add('${state['state']}'),
      translationDomain: 'weather',
      onTranslations: (_) {},
      forecastEntity: 'weather.home',
      onForecast: forecast.complete,
    );
    addTearDown(() => live?.close());
    final daily = parseForecast(
      await forecast.future.timeout(const Duration(seconds: 2)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(states, ['rainy']);
    expect(daily.values.single.high, 31.6);
    expect(daily.values.single.low, 24.4);
    expect(rejected, isEmpty);
    expect(pongs, greaterThan(1));
    expect(live!.isClosed, false);
  });
}
