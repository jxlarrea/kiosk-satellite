import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_host_api.dart';

void main() {
  late EventBus bus;
  late Logger log;
  late CommandRegistry commands;
  late PluginHostApi api;
  late List<String> executed;
  late List<Map<String, Object?>> sent;
  const session = {'id': 'example', 'session': 'one'};

  void register(
    String name,
    Future<CommandResult> Function(Map<String, Object?>) handler,
  ) {
    commands.register(
      Command(
        name: name,
        description: 'test',
        handler: (p) {
          executed.add(name);
          return handler(p);
        },
      ),
    );
  }

  Future<Map<String, Object?>> read(
    String command, {
    Map<String, Object?> params = const {},
    String token = 'one',
  }) => api.execute({
    'id': 'example',
    'session': token,
    'command': command,
    'arguments': params,
  });
  void subscribe(String name, {bool subscribed = true}) =>
      api.subscription({...session, 'event': name, 'subscribed': subscribed});

  setUp(() {
    bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    executed = [];
    sent = [];
    api = PluginHostApi(commands, bus, (event) async {
      sent.add(event);
    });
    api.open({
      ...session,
      'capabilities': ['host.read'],
    });
  });
  tearDown(() async {
    await api.dispose();
    await bus.dispose();
  });

  test(
    'catalog is explicit and destructive or arbitrary commands never reach KS',
    () async {
      for (final name in [
        'stopScreensaver',
        'setBrightness',
        'evalJs',
        'getLocalStorage',
        'getSystemPermissions',
        'runPluginCommand',
        'getSettings',
        'exitApp',
      ]) {
        register(name, (_) async => const CommandResult.ok());
        expect((await read(name))['ok'], false, reason: name);
      }
      final result = await read('getHostApi');
      expect(result['ok'], true);
      expect((result['data'] as Map)['commands'], PluginHostApi.commandNames);
      expect((result['data'] as Map)['events'], PluginHostApi.eventNames);
      expect(executed, isEmpty);
    },
  );

  test(
    'transient controls require their own capability and never expose internal results',
    () async {
      api.open({
        ...session,
        'capabilities': ['host.control'],
      });
      final catalog = (await read('getHostApi'))['data'] as Map;
      expect(catalog['apiVersion'], 1);
      expect(catalog['commands'], [
        'getHostApi',
        ...PluginHostApi.controlNames,
      ]);
      expect(catalog['events'], isEmpty);
      register('isScreenOn', (_) async => const CommandResult.ok(true));
      expect((await read('isScreenOn'))['ok'], false);
      subscribe('screen.state');
      bus.publish(const ScreenStateChanged(on: true, source: 'app'));
      await Future<void>.delayed(const Duration(milliseconds: 130));
      expect(sent, isEmpty);
      final arguments = <String, Map<String, Object?>>{
        'showCameraView': {'viewId': 'front-door', 'toggle': true},
        'focusCamera': {'cameraId': 'front'},
        'sendspinControl': {'command': 'pause'},
        'showOverlayPage': {'url': 'https://example.com'},
        'showLinkPage': {'url': 'http://example.com'},
        'loadUrl': {'url': 'https://example.com'},
        'loadDashboard': {'dashboard': 'lovelace'},
        'haNavigate': {'path': 'lovelace/home'},
      };
      for (final name in PluginHostApi.controlNames) {
        register(name, (p) async {
          expect(
            p,
            name == 'screenOff' ? {'prompt': false} : arguments[name] ?? {},
          );
          return const CommandResult.ok({'secret': 'hidden'});
        });
        final result = await read(name, params: arguments[name] ?? {});
        expect(result['ok'], true, reason: name);
        expect(result.toString(), isNot(contains('secret')));
      }
      expect(executed, PluginHostApi.controlNames);
      api.close(session);
      expect((await read('stopScreensaver'))['ok'], false);
    },
  );

  test(
    'control arguments reject writes, permission prompts and executable URLs',
    () async {
      api.open({
        ...session,
        'capabilities': ['host.read', 'host.control'],
      });
      for (final name in [
        'setSettings',
        'setBrightness',
        'setVolume',
        'cameraDeleteView',
        'evalJs',
        'haCallService',
        'exitApp',
        'keepScreenAwake',
        'pauseScreensaver',
      ]) {
        register(name, (_) async => const CommandResult.ok());
        expect((await read(name))['ok'], false, reason: name);
      }
      final invalid = <String, List<Map<String, Object?>>>{
        'screenOff': [
          {'prompt': true},
        ],
        'stopScreensaver': [
          {'permanent': true},
        ],
        'showCameraView': [
          {},
          {'viewId': 'front', 'toggle': 'true'},
        ],
        'sendspinControl': [
          {'command': 'delete'},
          {'command': 'volume'},
        ],
        'haNavigate': [
          {'path': '../config'},
          {'path': 'https://evil.test'},
        ],
        'showLinkPage': [
          {'url': 'javascript:alert(1)'},
          {'url': 'intent://settings'},
          {'url': 'https://user:password@example.com'},
          {'url': 'x' * 2049},
        ],
      };
      for (final entry in invalid.entries) {
        register(entry.key, (_) async => const CommandResult.ok());
        for (final params in entry.value) {
          expect(
            (await read(entry.key, params: params))['ok'],
            false,
            reason: '${entry.key} $params',
          );
        }
      }
      expect(executed, isEmpty);
    },
  );

  test(
    'reads validate arguments and strip unapproved response fields',
    () async {
      register(
        'getDeviceInfo',
        (_) async => const CommandResult.ok({
          'name': 'Panel',
          'model': 'Test',
          'ip': 'private',
          'token': 'secret',
        }),
      );
      register('getBrightness', (p) async {
        expect(p, {'panel': true});
        return const CommandResult.ok(0.4);
      });
      expect(
        (await read('getDeviceInfo', params: {'includeSecrets': true}))['ok'],
        false,
      );
      final data = (await read('getDeviceInfo'))['data'] as Map;
      expect(data['name'], 'Panel');
      expect(data.containsKey('ip'), false);
      expect(data.containsKey('token'), false);
      expect(
        (await read('getBrightness', params: {'panel': true}))['data'],
        0.4,
      );
      expect(
        (await read('getBrightness', params: {'panel': 'true'}))['ok'],
        false,
      );
      expect(
        (await read(
          'getBrightness',
          params: {'panel': true, 'ceiling': true},
        ))['ok'],
        false,
      );
      expect(executed, ['getDeviceInfo', 'getBrightness']);
    },
  );

  test(
    'missing capability, stale sessions and stopped reads are rejected',
    () async {
      final completion = Completer<CommandResult>();
      register('isScreenOn', (_) => completion.future);
      api.close(session);
      api.open({
        ...session,
        'capabilities': ['overlay'],
      });
      expect((await read('isScreenOn'))['ok'], false);
      expect(executed, isEmpty);
      api.open({
        ...session,
        'capabilities': ['host.read'],
      });
      final pending = read('isScreenOn');
      api.close(session);
      api.open({
        'id': 'example',
        'session': 'two',
        'capabilities': ['host.read'],
      });
      api.close(session);
      completion.complete(const CommandResult.ok(true));
      expect((await pending)['ok'], false);
      expect((await read('getHostApi'))['ok'], false);
      expect((await read('getHostApi', token: 'two'))['ok'], true);
    },
  );

  test(
    'dashboard reads require host.read and expose only sanitized URL fields',
    () async {
      register(
        'getDashboardState',
        (_) async => const CommandResult.ok({
          'homeAssistantUrl':
              'https://name:password@ha.test?access_token=secret',
          'startUrl': 'https://ha.test/dashboard/main?kiosk=true#secret',
          'currentUrl': 'http://127.0.0.1:18123/dashboard/kitchen?token=secret',
          'currentPath': 'do-not-trust-this-field',
          'accessToken': 'secret',
        }),
      );
      final result = await read('getDashboardState');
      expect(result['ok'], true);
      expect(result['data'], {
        'homeAssistantUrl': 'https://ha.test',
        'startUrl': 'https://ha.test/dashboard/main',
        'currentUrl': 'http://127.0.0.1:18123/dashboard/kitchen',
        'currentPath': '/dashboard/kitchen',
      });
      expect(
        (await read(
          'getDashboardState',
          params: {'url': 'https://other.test'},
        ))['ok'],
        false,
      );
      api.open({
        ...session,
        'capabilities': ['host.control'],
      });
      executed.clear();
      expect((await read('getDashboardState'))['ok'], false);
      expect(executed, isEmpty);
    },
  );

  test(
    'browser notifications follow routes and URL settings without exposing their values',
    () async {
      subscribe('browser.state');
      bus.publish(const UrlChanged(url: 'https://ha.test/room?secret=one'));
      bus.publish(const PageChanged(url: 'https://ha.test/room#secret'));
      bus.publish(
        const SettingChanged(
          key: 'browser.start_url',
          value: 'https://user:secret@ha.test',
        ),
      );
      bus.publish(
        const SettingChanged(key: 'ha.url', value: 'https://other.test'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(sent, hasLength(1));
      expect(sent.single['event'], 'browser.state');
      expect((sent.single['payload'] as Map).keys, ['time']);
      sent.clear();
      bus.publish(const SettingChanged(key: 'ha.token', value: 'secret'));
      await Future<void>.delayed(const Duration(milliseconds: 130));
      expect(sent, isEmpty);
      bus.publish(const UrlChanged(url: 'https://ha.test/next'));
      await Future<void>.delayed(Duration.zero);
      api.close(session);
      await Future<void>.delayed(const Duration(milliseconds: 130));
      expect(sent, isEmpty);
    },
  );

  test('errors do not expose internal response details', () async {
    register(
      'haStatus',
      (_) async => const CommandResult.fail('Authorization: secret'),
    );
    final result = await read('haStatus');
    expect(result['ok'], false);
    expect(result.toString(), isNot(contains('secret')));
  });

  test('unexpected objects and oversized results are refused', () async {
    register(
      'isScreenOn',
      (_) async => const CommandResult.ok({'secret': 'value'}),
    );
    register(
      'getDeviceInfo',
      (_) async => CommandResult.ok({'name': 'x' * 40000}),
    );
    expect((await read('isScreenOn'))['ok'], false);
    expect((await read('getDeviceInfo'))['ok'], false);
  });

  test('events are opt-in, projected, coalesced and revoked on stop', () async {
    subscribe('screensaver.state');
    subscribe('device.light');
    bus.publish(const ScreensaverStateChanged(active: true));
    bus.publish(const LightLevelChanged(lux: 1));
    bus.publish(const LightLevelChanged(lux: 9));
    bus.publish(const SettingChanged(key: 'secret', value: 'token'));
    bus.publish(const MotionDetected());
    await Future<void>.delayed(const Duration(milliseconds: 180));
    expect(sent, hasLength(2));
    final light = sent.firstWhere((e) => e['event'] == 'device.light');
    expect((light['payload'] as Map)['lux'], 9);
    expect((light['payload'] as Map)['time'], isA<String>());
    expect(
      sent.every((e) => e['id'] == 'example' && e['session'] == 'one'),
      true,
    );
    sent.clear();
    subscribe('device.light', subscribed: false);
    bus.publish(const LightLevelChanged(lux: 20));
    bus.publish(const ScreensaverStateChanged(active: false));
    await Future<void>.delayed(Duration.zero);
    api.close(session);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(sent, isEmpty);
  });

  test('native and Flutter event contracts match', () {
    final source = File(
      'android/app/src/main/kotlin/me/jxl/kiosk_satellite/plugins/PluginHostPolicy.kt',
    ).readAsStringSync();
    final names = RegExp(
      r'"([a-z]+\.[a-z]+)"',
    ).allMatches(source).map((m) => m[1]).toSet();
    expect(names, PluginHostApi.eventNames.toSet());
  });
}
