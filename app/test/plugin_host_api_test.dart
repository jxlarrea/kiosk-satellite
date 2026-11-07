import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/home_assistant/plugin_ha_socket.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_host_api.dart';
import 'package:kiosk_satellite/managers/sendspin/plugin_ma_socket.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/voice/assist_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        'setVolume': {'percent': '40', 'channel': 'assistant'},
        'setWakeWordMuted': {'muted': true},
        'showOverlayPage': {'url': 'https://example.com'},
        'showLinkPage': {'url': 'http://example.com'},
        'loadUrl': {'url': 'https://example.com'},
        'openCalendar': {'view': 'week', 'date': '2026-10-22'},
        'loadDashboard': {'dashboard': 'lovelace'},
        'haNavigate': {'path': 'lovelace/home'},
        'launchApp': {'package': 'com.example.music'},
        'openKioskLink': {'url': 'ks://alarms'},
        'openAlarms': {'alarm': 'next'},
      };
      String target(String name) => switch (name) {
        'launchApp' => 'pluginLaunchApp',
        'openKioskLink' => 'pluginOpenKioskLink',
        _ => name,
      };
      for (final name in PluginHostApi.controlNames) {
        register(target(name), (p) async {
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
      expect(executed, PluginHostApi.controlNames.map(target));
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
        'setVolume': [
          {},
          {'percent': 40},
          {'percent': '101'},
          {'percent': '-1'},
          {'percent': 'loud'},
          {'percent': '40', 'channel': 'alarm'},
          {'percent': '40', 'channel': 'master', 'extra': true},
        ],
        'getVolume': [
          {'channel': 'alarm'},
          {'channel': true},
        ],
        'setWakeWordMuted': [
          {},
          {'muted': 'true'},
          {'muted': true, 'extra': true},
        ],
        'openCalendar': [
          {'view': 'year'},
          {'view': true},
          {'date': 'tomorrow'},
          {'date': '2026-10-22T09:00'},
          {'view': 'day', 'highlight': 'x'},
        ],
        'haNavigate': [
          {'path': '../config'},
          {'path': 'https://evil.test'},
        ],
        'launchApp': [
          {},
          {'package': ''},
          {'package': 'music'},
          {'package': 'com.example/.Main'},
          {'package': 'com.example', 'activity': 'Main'},
        ],
        'openAlarms': [
          {'alarm': 'first'},
          {'alarm': true},
          {'alarm': 'next', 'view': 'list'},
        ],
        'openKioskLink': [
          {},
          {'url': ''},
          {'url': 'ks://nothing'},
          {'url': 'ks://alarms?x=1'},
          {'url': 'https://example.com'},
          {'url': 'app://com.example.music'},
          {'url': 'ks://alarms', 'extra': true},
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
          'model': 'Panel Maker Test',
          'device': 'rk3576_u',
          'board': 'rk3576',
          'manufacturer': 'Panel Maker',
          'abis': ['arm64-v8a', 'armeabi-v7a', 'armeabi'],
          'sdkInt': 34,
          'ramFree': 2147483648,
          'ramTotal': 4294967296,
          'storageFree': 17179869184,
          'storageTotal': 34359738368,
          'ip': '192.0.2.5',
          'ipv6': ['2001:db8::5', 'fe80::5'],
          'battery': 82,
          'brightness': 0.35,
          'screenOn': false,
          'screenWidth': 1920,
          'screenHeight': 1080,
          'screenDensity': 1.5,
          'fingerprint': 'private',
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
      expect(data['model'], 'Panel Maker Test');
      expect(data['device'], 'rk3576_u');
      expect(data['board'], 'rk3576');
      expect(data['manufacturer'], 'Panel Maker');
      expect(data['abis'], ['arm64-v8a', 'armeabi-v7a', 'armeabi']);
      expect(data['sdkInt'], 34);
      expect(data['ramFree'], 2147483648);
      expect(data['ramTotal'], 4294967296);
      expect(data['storageFree'], 17179869184);
      expect(data['storageTotal'], 34359738368);
      expect(data['ip'], '192.0.2.5');
      expect(data['ipv6'], ['2001:db8::5', 'fe80::5']);
      expect(data['battery'], 82);
      expect(data['brightness'], 0.35);
      expect(data['screenOn'], false);
      expect(data['screenWidth'], 1920);
      expect(data['screenHeight'], 1080);
      expect(data['screenDensity'], 1.5);
      expect(data.containsKey('fingerprint'), false);
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

  test('getStats carries the CPU clock and battery temperature', () async {
    register(
      'getStats',
      (_) async => const CommandResult.ok({
        'battery': 64,
        'charging': false,
        'cpu': 18.5,
        'cpuClock': 1324.8,
        'temp': 44.0,
        'batteryTemp': 31.8,
        'memFree': 1073741824,
        'memTotal': 4294967296,
        'thermalZones': ['cpu-0'],
      }),
    );
    final data = (await read('getStats'))['data'] as Map;
    expect(data['batteryTemp'], 31.8);
    expect(data['cpuClock'], 1324.8);
    expect(data['temp'], 44.0);
    expect(data.containsKey('thermalZones'), false);
  });

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

  test('camera views and dashboards are listed without internals', () async {
    register(
      'cameraGetConfig',
      (_) async => const CommandResult.ok({
        'servers': [
          {'id': 's', 'url': 'http://user:pw@go2rtc:1984'},
        ],
        'cameras': [
          {'id': 'c1', 'url': 'rtsp://secret'},
        ],
        'views': [
          {
            'id': 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
            'name': 'Front door',
            'cameraIds': ['c1', 'c2'],
            'grid': 4,
          },
          {'id': 'default', 'name': 'Default', 'cameraIds': []},
        ],
      }),
    );
    final views = await read('getCameraViews');
    expect(views['data'], [
      {
        'id': 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
        'name': 'Front door',
        'cameraCount': 2,
      },
      {'id': 'default', 'name': 'Default', 'cameraCount': 0},
    ]);
    expect(views.toString(), isNot(contains('rtsp')));
    expect((await read('getCameraViews', params: {'all': true}))['ok'], false);

    var configured = true;
    register(
      'haListDashboards',
      (_) async => !configured
          ? const CommandResult.fail('Home Assistant not configured')
          : const CommandResult.ok([
              {
                'url_path': 'lovelace',
                'title': 'Overview',
                'icon': 'mdi:home',
                'require_admin': false,
              },
              {'url_path': 'dashboard-cams', 'title': 'Cameras'},
              {
                'url_path': 'energy',
                'title': 'Energy',
                'icon': 'mdi:lightning-bolt',
                'builtIn': true,
              },
              {'url_path': '', 'title': 'Broken'},
            ]),
    );
    register('haListDashboardViews', (p) async {
      if (p['url_path'] == 'dashboard-cams') {
        return const CommandResult.fail('could not read the dashboard');
      }
      if (p['url_path'] == 'energy') return const CommandResult.ok([]);
      return const CommandResult.ok([
        {'route': 'home', 'title': 'Home', 'icon': 'mdi:sofa', 'cards': 12},
        {'route': 'garage', 'subview': true},
        {'route': ''},
      ]);
    });
    final dashboards = await read('getDashboards');
    expect(dashboards['data'], [
      {
        'urlPath': 'lovelace',
        'title': 'Overview',
        'icon': 'mdi:home',
        'custom': false,
        'builtIn': false,
        'views': [
          {
            'path': 'lovelace/home',
            'title': 'Home',
            'icon': 'mdi:sofa',
            'subview': false,
          },
          {
            'path': 'lovelace/garage',
            'title': 'garage',
            'icon': null,
            'subview': true,
          },
        ],
      },
      // A dashboard whose views cannot be read still lists, without views.
      {
        'urlPath': 'dashboard-cams',
        'title': 'Cameras',
        'icon': null,
        'custom': false,
        'builtIn': false,
        'views': [],
      },
      // One of Home Assistant's own pages, opened by its bare path.
      {
        'urlPath': 'energy',
        'title': 'Energy',
        'icon': 'mdi:lightning-bolt',
        'custom': false,
        'builtIn': true,
        'views': [],
      },
    ]);
    configured = false;
    expect((await read('getDashboards'))['ok'], false);
  });

  test('launcher apps list and open only through the launcher', () async {
    api.open({
      ...session,
      'capabilities': ['host.read', 'host.control'],
    });
    register(
      'pluginLauncherApps',
      (_) async => const CommandResult.ok([
        {'package': 'com.example.music', 'label': 'Music', 'icon': 'x'},
      ]),
    );
    expect((await read('getLauncherApps'))['data'], [
      {'package': 'com.example.music', 'label': 'Music'},
    ]);
    register('installedApps', (_) async => const CommandResult.ok([]));
    expect((await read('installedApps'))['ok'], false);
    register('launchApp', (_) async => const CommandResult.ok());
    register(
      'pluginLaunchApp',
      (p) async => p['package'] == 'com.example.music'
          ? const CommandResult.ok()
          : const CommandResult.fail('the app is not one the launcher offers'),
    );
    final opened = await read(
      'launchApp',
      params: {'package': 'com.example.music'},
    );
    expect(opened, {'ok': true});
    final refused = await read(
      'launchApp',
      params: {'package': 'com.example.other'},
    );
    expect(refused['ok'], false);
    expect(executed, isNot(contains('launchApp')));
  });

  test('haNavigate takes queries and reports arriving on the view', () async {
    api.open({
      ...session,
      'capabilities': ['host.control'],
    });
    var outcome = 'navigated';
    final paths = <Object?>[];
    register('haNavigate', (p) async {
      paths.add(p['path']);
      return CommandResult.ok(outcome);
    });
    Future<Object?> go(String path) async =>
        (await read('haNavigate', params: {'path': path}))['data'];
    expect(await go('lovelace/0'), true);
    outcome = 'already';
    expect(await go('/cameras/0?camera=garage'), true);
    outcome = 'off-origin';
    expect(await go('local/dashboard.html#kitchen'), false);
    outcome = 'failed';
    expect(await go('lovelace/0/'), false);
    expect(paths, [
      'lovelace/0',
      '/cameras/0?camera=garage',
      'local/dashboard.html#kitchen',
      'lovelace/0/',
    ]);
    for (final bad in [
      '../config',
      'lovelace/../config',
      'lovelace/./x',
      'https://evil.test',
      'lovelace/0?x=a b',
      '?only=query',
    ]) {
      expect(
        (await read('haNavigate', params: {'path': bad}))['ok'],
        false,
        reason: bad,
      );
    }
    expect(paths, hasLength(4));
  });

  test('volume reads and writes pass the channel through', () async {
    api.open({
      ...session,
      'capabilities': ['host.read', 'host.control'],
    });
    final seen = <Map<String, Object?>>[];
    register('getVolume', (p) async {
      seen.add(p);
      return const CommandResult.ok(35);
    });
    register('setVolume', (p) async {
      seen.add(p);
      return const CommandResult.ok();
    });
    expect((await read('getVolume'))['data'], 35);
    expect(
      (await read('getVolume', params: {'channel': 'intercom'}))['data'],
      35,
    );
    expect(
      (await read('setVolume', params: {'percent': ' 12.5 '}))['ok'],
      true,
    );
    expect(seen, [
      {},
      {'channel': 'intercom'},
      {'percent': ' 12.5 '},
    ]);
    final projected = PluginHostApi.project(
      const SettingChanged(key: 'audio.assistant_volume', value: 40),
    );
    expect(projected?.$1, 'device.volume');
    expect(projected?.$2, isEmpty);
    expect(
      PluginHostApi.project(
        const SettingChanged(key: 'audio.duck_volume', value: 40),
      ),
      isNull,
    );
  });

  test('setWakeWordMuted answers the muted state it set', () async {
    api.open({
      ...session,
      'capabilities': ['host.read', 'host.control'],
    });
    final seen = <Map<String, Object?>>[];
    register('setWakeWordMuted', (p) async {
      seen.add(p);
      return CommandResult.ok(p['muted']);
    });
    expect(
      await read('setWakeWordMuted', params: {'muted': true}),
      containsPair('data', true),
    );
    expect(
      await read('setWakeWordMuted', params: {'muted': false}),
      containsPair('data', false),
    );
    expect(seen, [
      {'muted': true},
      {'muted': false},
    ]);
    register(
      'getWakeWordState',
      (_) async => const CommandResult.ok({
        'enabled': true,
        'listening': false,
        'muted': true,
        'releaseReason': 'muted',
      }),
    );
    final state = (await read('getWakeWordState'))['data'] as Map;
    expect(state['muted'], true);
    expect(state.containsKey('releaseReason'), false);
  });

  test('errors do not expose internal response details', () async {
    register(
      'haStatus',
      (_) async => const CommandResult.fail('Authorization: secret'),
    );
    final result = await read('haStatus');
    expect(result['ok'], false);
    expect(result.toString(), isNot(contains('secret')));
  });

  test('device reads allow only string lists for ABIs and IPv6', () async {
    final values = <String, Object?>{};
    register('getDeviceInfo', (_) async => CommandResult.ok(values));
    for (final field in ['abis', 'ipv6']) {
      for (final valid in [
        null,
        <String>[],
        ['value'],
      ]) {
        values[field] = valid;
        final result = await read('getDeviceInfo');
        expect(result['ok'], true);
        expect((result['data'] as Map)[field], valid);
      }
      for (final invalid in [
        'value',
        ['value', 32],
        [
          ['value'],
        ],
        {'key': 'value'},
        ['x' * 40000],
      ]) {
        values[field] = invalid;
        expect((await read('getDeviceInfo'))['ok'], false, reason: field);
      }
      values[field] = <String>[];
    }
    values['board'] = ['rk3576'];
    expect((await read('getDeviceInfo'))['ok'], false);
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

  test('the noise level needs its own capability', () async {
    register(
      'getNoiseLevel',
      (_) async => const CommandResult.ok({
        'available': true,
        'dbfs': -42,
        'held': false,
        'updated': '2026-10-08T12:00:00.000Z',
        'secret': 'hidden',
      }),
    );
    final plain = (await read('getHostApi'))['data'] as Map;
    expect(plain['commands'], isNot(contains('getNoiseLevel')));
    expect(plain['events'], isNot(contains('audio.noise')));
    expect((await read('getNoiseLevel'))['ok'], false);
    subscribe('audio.noise');
    bus.publish(
      const NoiseLevelChanged(available: true, dbfs: -42, held: false),
    );
    await Future<void>.delayed(const Duration(milliseconds: 130));
    expect(sent, isEmpty);
    expect(executed, isEmpty);

    api.open({
      ...session,
      'capabilities': ['host.read', 'noise'],
    });
    final catalog = (await read('getHostApi'))['data'] as Map;
    expect(catalog['capabilities'], ['host.read', 'noise']);
    expect(catalog['commands'], contains('getNoiseLevel'));
    expect(catalog['events'], contains('audio.noise'));
    final result = await read('getNoiseLevel');
    expect(result['data'], {
      'available': true,
      'dbfs': -42,
      'held': false,
      'updated': '2026-10-08T12:00:00.000Z',
    });
    subscribe('audio.noise');
    bus.publish(
      const NoiseLevelChanged(available: true, dbfs: -42, held: true),
    );
    await Future<void>.delayed(const Duration(milliseconds: 130));
    final event = sent.single;
    expect(event['event'], 'audio.noise');
    expect(event['payload'], containsPair('dbfs', -42));
    expect(event['payload'], containsPair('held', true));
    expect(event['payload'], containsPair('available', true));

    // Without host.read the capability opens nothing.
    api.open({
      ...session,
      'capabilities': ['host.control', 'noise'],
    });
    expect((await read('getNoiseLevel'))['ok'], false);
  });

  group('screensaver mode', () {
    late PluginHostApi modesApi;
    late Map<String, String> holds;
    const modes = [
      {'id': 'clock', 'label': 'Clock'},
      {'id': 'plugin:example:monitor', 'label': 'Monitor (Example)'},
    ];

    Future<Map<String, Object?>> run(
      String command, {
      Map<String, Object?> params = const {},
      String id = 'example',
    }) => modesApi.execute({
      'id': id,
      'session': 'one',
      'command': command,
      'arguments': params,
    });

    setUp(() {
      holds = {};
      modesApi = PluginHostApi(
        commands,
        bus,
        (event) async {},
        screensaverModes: PluginScreensaverModes(
          read: () => {
            'mode': holds.values.lastOrNull ?? 'clock',
            'saved': 'clock',
            'schedule': null,
            'override': holds.values.lastOrNull,
            'active': false,
            'modes': modes,
          },
          hold: (owner, mode) {
            if (!modes.any((m) => m['id'] == mode)) return false;
            holds.remove(owner);
            holds[owner] = mode;
            return true;
          },
          release: holds.remove,
        ),
      );
    });
    tearDown(() => modesApi.dispose());

    test('needs its own capability, with or without host access', () async {
      modesApi.open({
        ...session,
        'capabilities': ['host.read', 'host.control'],
      });
      final plain = (await run('getHostApi'))['data'] as Map;
      expect(plain['commands'], isNot(contains('getScreensaverMode')));
      expect((await run('getScreensaverMode'))['ok'], false);
      expect(
        (await run('setScreensaverMode', params: {'mode': 'clock'}))['ok'],
        false,
      );
      expect(holds, isEmpty);

      // The capability alone opens a session, and only these commands.
      modesApi.open({
        ...session,
        'capabilities': ['screensaver.mode'],
      });
      final catalog = (await run('getHostApi'))['data'] as Map;
      expect(catalog['capabilities'], ['screensaver.mode']);
      expect(catalog['commands'], [
        'getHostApi',
        ...PluginHostApi.screensaverModeCommandNames,
      ]);
      expect(catalog['events'], isEmpty);
      expect((await run('isScreensaverActive'))['ok'], false);
      final state = await run('getScreensaverMode');
      expect(state['ok'], true);
      expect((state['data'] as Map)['modes'], modes);
      expect(executed, isEmpty);
    });

    test('holds a mode per session and lets go when it closes', () async {
      modesApi.open({
        ...session,
        'capabilities': ['screensaver.mode'],
      });
      modesApi.open({
        'id': 'other',
        'session': 'one',
        'capabilities': ['screensaver.mode'],
      });
      for (final params in [
        <String, Object?>{},
        {'mode': ''},
        {'mode': true},
        {'mode': 'clock', 'extra': 'x'},
      ]) {
        expect((await run('setScreensaverMode', params: params))['ok'], false);
      }
      expect(
        (await run('clearScreensaverMode', params: {'x': 'y'}))['ok'],
        false,
      );
      final unknown = await run('setScreensaverMode', params: {'mode': 'nope'});
      expect(unknown['ok'], false);
      expect(unknown['error'], 'Unknown screensaver mode');
      expect(holds, isEmpty);

      final set = await run(
        'setScreensaverMode',
        params: {'mode': 'plugin:example:monitor'},
      );
      expect(set['ok'], true);
      expect(set.containsKey('data'), false);
      await run('setScreensaverMode', params: {'mode': 'clock'}, id: 'other');
      expect(holds, {
        'example:one': 'plugin:example:monitor',
        'other:one': 'clock',
      });
      expect(
        ((await run('getScreensaverMode'))['data'] as Map)['override'],
        'clock',
      );

      // Clearing touches only the caller's own hold.
      expect((await run('clearScreensaverMode', id: 'other'))['ok'], true);
      expect(holds, {'example:one': 'plugin:example:monitor'});
      modesApi.close(session);
      expect(holds, isEmpty);
    });
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

  test(
    'voice state reads and events carry the turn state, never its words',
    () async {
      register(
        'voiceStatus',
        (_) async => const CommandResult.ok({
          'enabled': true,
          'state': 'responding',
          'command': 'turn on the lights',
          'answer': 'Turned on the lights',
          'satelliteEntity': 'assist_satellite.kitchen',
        }),
      );
      final result = await read('getVoiceState');
      expect(result['ok'], true);
      expect(result['data'], {
        'enabled': true,
        'state': 'responding',
        'skinSelected': false,
        'overlay': 'hidden',
      });
      expect(executed, ['voiceStatus']);
      subscribe('voice.state');
      bus.publish(const VoiceSatelliteStateChanged('listening'));
      bus.publish(const VoiceSatelliteStateChanged('processing'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(sent, hasLength(1));
      expect(sent.single['event'], 'voice.state');
      expect((sent.single['payload'] as Map)['state'], 'processing');
    },
  );

  test(
    'intercom reads and events carry what the sensors show, once per change',
    () async {
      register(
        'intercomSensors',
        (_) async => const CommandResult.ok({
          'enabled': true,
          'state': 'ringing',
          'kiosk': 'Kitchen',
          'dnd': false,
          'kiosks': [],
        }),
      );
      final result = await read('getIntercomState');
      expect(result['ok'], true);
      expect(result['data'], {
        'enabled': true,
        'state': 'ringing',
        'kiosk': 'Kitchen',
        'dnd': false,
      });
      expect(executed, ['intercomSensors']);
      subscribe('intercom.state');
      Map<String, Object?> status(String state, {bool talking = false}) => {
        'state': state,
        'dnd': false,
        'call': {
          'peer': {'name': 'Kitchen', 'address': '10.0.0.2'},
          'talking': talking,
        },
        'kiosks': [
          {'name': 'Kitchen', 'address': '10.0.0.2'},
        ],
      };
      bus.publish(IntercomStateChanged(status('in_call')));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(sent, hasLength(1));
      expect(sent.single['event'], 'intercom.state');
      final payload = Map.of(sent.single['payload'] as Map)..remove('time');
      expect(payload, {'state': 'in_call', 'kiosk': 'Kitchen', 'dnd': false});
      sent.clear();
      bus.publish(IntercomStateChanged(status('in_call', talking: true)));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(sent, isEmpty);
      bus.publish(const IntercomStateChanged({'state': 'idle', 'dnd': true}));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect((sent.single['payload'] as Map)['kiosk'], '');
      expect((sent.single['payload'] as Map)['dnd'], true);
    },
  );

  test(
    'HA reads validate IDs and project only the SDK entity fields',
    () async {
      register('haPluginReadEntity', (params) async {
        expect(params, {'entityId': 'sensor.room'});
        return const CommandResult.ok({
          'entityId': 'sensor.room',
          'status': 'available',
          'state': '20',
          'attributes': {'unit': 'C'},
          'secret': 'hidden',
        });
      });
      for (final id in ['sensor.*', '../config', 'sensor.room?x=y']) {
        expect(
          (await read('getHaEntityState', params: {'entityId': id}))['ok'],
          false,
        );
      }
      final result = await read(
        'getHaEntityState',
        params: {'entityId': 'sensor.room'},
      );
      expect(result['ok'], true);
      expect((result['data'] as Map)['attributes'], {'unit': 'C'});
      expect((result['data'] as Map).containsKey('secret'), false);
    },
  );

  test(
    'entity subscriptions route by session, coalesce per entity and revoke',
    () async {
      final watches = <Map<String, Object?>>[];
      final releases = <Map<String, Object?>>[];
      register('haPluginWatchEntity', (p) async {
        watches.add(p);
        return const CommandResult.ok();
      });
      register('haPluginUnwatchEntity', (p) async {
        releases.add(p);
        return const CommandResult.ok();
      });
      subscribe('ha.entity.sensor.room');
      subscribe('ha.entity.sensor.other');
      expect(watches, hasLength(2));
      expect(watches.first['owner'], 'example:one');
      bus.publish(
        const PluginHaStateChanged('wrong:one', 'sensor.room', {
          'state': 'private',
        }),
      );
      bus.publish(
        const PluginHaStateChanged('example:one', 'sensor.room', {
          'state': '20',
          'attributes': {'unit': 'C'},
        }),
      );
      bus.publish(
        const PluginHaStateChanged('example:one', 'sensor.other', {
          'state': 'on',
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(sent, hasLength(2));
      expect(sent.any((event) => event.toString().contains('private')), false);
      sent.clear();
      subscribe('ha.entity.sensor.room', subscribed: false);
      bus.publish(
        const PluginHaStateChanged('example:one', 'sensor.room', {
          'state': '21',
        }),
      );
      api.close(session);
      api.open({
        ...session,
        'session': 'two',
        'capabilities': ['host.read'],
      });
      bus.publish(
        const PluginHaStateChanged('example:one', 'sensor.other', {
          'state': 'stale',
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(sent, isEmpty);
      expect(
        releases.any(
          (p) => p['owner'] == 'example:one' && !p.containsKey('entityId'),
        ),
        true,
      );
    },
  );

  group('Screensaver appearance (issue #1250)', () {
    late SettingsManager settings;
    late ValueNotifier<String?> view;
    late ValueNotifier<bool> night;
    late bool shared;
    late bool nowPlaying;

    setUp(() async {
      await api.dispose();
      SharedPreferences.setMockInitialValues({});
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      view = ValueNotifier(null);
      night = ValueNotifier(false);
      nowPlaying = false;
      shared = false;
      api = PluginHostApi(
        commands,
        bus,
        (event) async => sent.add(event),
        screensaver: PluginScreensaverFeed(
          view: view,
          night: night,
          nowPlaying: () => nowPlaying,
          nowPlayingShared: () => shared,
          settings: settings,
        ),
      );
      api.open({
        ...session,
        'capabilities': ['host.read'],
      });
    });

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 150));

    const day = {
      'view': 'clock',
      'night': false,
      'nowPlaying': false,
      'nowPlayingShared': false,
      'textColor': null,
      'backgroundColor': null,
      'cardColor': null,
      'widgetsHidden': false,
    };

    test('reads the Night mode the clock wears', () async {
      final catalog = (await read('getHostApi'))['data'] as Map;
      expect(catalog['commands'], contains('getScreensaverAppearance'));
      expect(catalog['events'], contains('screensaver.appearance'));
      expect((await read('getScreensaverAppearance'))['data'], {
        ...day,
        'view': null,
      });

      // Night mode is the clock's: another view never wears it.
      night.value = true;
      view.value = 'photos';
      expect(
        ((await read('getScreensaverAppearance'))['data'] as Map)['night'],
        false,
      );

      view.value = 'clock';
      await settings.set(defs.screensaverClockNightColor, '10,20,30');
      await settings.set(defs.screensaverClockNightHideWidgets, true);
      expect((await read('getScreensaverAppearance'))['data'], {
        'view': 'clock',
        'night': true,
        'nowPlaying': false,
        'nowPlayingShared': false,
        'textColor': 0xFF0A141E,
        'backgroundColor': 0xFF000000,
        'cardColor': null,
        'widgetsHidden': true,
      });

      await settings.set(defs.screensaverClockStyle, 'flip');
      expect(
        ((await read('getScreensaverAppearance'))['data'] as Map)['cardColor'],
        0xFF141414,
      );

      // Now Playing hides the face.
      nowPlaying = true;
      expect(
        ((await read('getScreensaverAppearance'))['data'] as Map)['night'],
        false,
      );

      // Beside a shared player the face stays in sight, Night mode and all.
      shared = true;
      final beside = (await read('getScreensaverAppearance'))['data'] as Map;
      expect(beside['nowPlayingShared'], true);
      expect(beside['night'], true);
      expect(beside['textColor'], 0xFF0A141E);
    });

    test('tells subscribers when the look changes, once', () async {
      subscribe('screensaver.appearance');
      view.value = 'clock';
      await settle();
      expect(sent.single['event'], 'screensaver.appearance');
      expect(sent.single['payload'], containsPair('night', false));
      sent.clear();

      night.value = true;
      await settle();
      expect(sent.single['payload'], containsPair('night', true));
      expect(sent.single['payload'], containsPair('textColor', 0xFF822222));
      sent.clear();

      await settings.set(defs.screensaverClockNightBgColor, '1,2,3');
      await settle();
      expect(
        sent.single['payload'],
        containsPair('backgroundColor', 0xFF010203),
      );
      sent.clear();

      // A change that leaves the look as it was is not news.
      await settings.set(defs.screensaverClockNightCardColor, '9,9,9');
      await settle();
      expect(sent, isEmpty);

      nowPlaying = true;
      bus.publish(const FullscreenViewChanged(view: 'nowPlaying', shown: true));
      await settle();
      expect(sent.single['payload'], {
        ...day,
        'nowPlaying': true,
        'time': (sent.single['payload'] as Map)['time'],
      });
      sent.clear();

      nowPlaying = false;
      view.value = null;
      await settle();
      expect(sent.single['payload'], containsPair('view', null));
    });
  });

  group('screensaver tint', () {
    late List<String> tints;
    late bool showing;

    setUp(() async {
      await api.dispose();
      tints = [];
      showing = true;
      final settings = SettingsManager(bus, commands, log);
      api = PluginHostApi(
        commands,
        bus,
        (event) async => sent.add(event),
        screensaver: PluginScreensaverFeed(
          view: ValueNotifier(null),
          night: ValueNotifier(false),
          nowPlaying: () => false,
          nowPlayingShared: () => false,
          settings: settings,
          setTint: (id, color) {
            if (!showing) return false;
            tints.add('$id ${color.toRadixString(16)}');
            return true;
          },
          clearTint: (id) => tints.add('$id clear'),
        ),
      );
    });

    Future<Map<String, Object?>> tint(Map<String, Object?> params) =>
        read('setScreensaverTint', params: params);

    test('needs the screensaver capability', () async {
      api.open({
        ...session,
        'capabilities': ['host.read'],
      });
      final catalog = (await read('getHostApi'))['data'] as Map;
      expect(catalog['commands'], isNot(contains('setScreensaverTint')));
      expect((await tint({'color': '#822222'}))['ok'], false);
      expect(tints, isEmpty);
    });

    test('tints the plugin\'s own screensaver and clears with it', () async {
      // A renderer needs no host capability for it, and gets nothing else.
      api.open({
        ...session,
        'capabilities': ['screensaver'],
      });
      final catalog = (await read('getHostApi'))['data'] as Map;
      expect(catalog['commands'], [
        'getHostApi',
        'setScreensaverTint',
        'clearScreensaverTint',
      ]);
      expect(catalog['events'], isEmpty);
      expect((await read('getScreensaverAppearance'))['ok'], false);
      for (final bad in ['822222', '#82222', '#82222g', '#FF822222', '']) {
        expect((await tint({'color': bad}))['ok'], false, reason: bad);
      }
      expect((await tint({'color': '#822222', 'extra': true}))['ok'], false);
      expect(tints, isEmpty);

      expect((await tint({'color': '#8a2Be2'}))['ok'], true);
      expect(tints, ['example ff8a2be2']);

      showing = false;
      final refused = await tint({'color': '#822222'});
      expect(refused['ok'], false);
      expect(refused['error'], contains('on screen'));

      expect((await read('clearScreensaverTint'))['ok'], true);
      expect(tints.last, 'example clear');

      // A session that ends takes its tint with it.
      tints.clear();
      api.close(session);
      expect(tints, ['example clear']);
    });
  });

  group('Home Assistant access', () {
    late _FakeHa ha;
    late PluginHostApi haApi;
    const haSession = {'id': 'ha-plugin', 'session': 'two'};

    setUp(() {
      ha = _FakeHa();
      haApi = PluginHostApi(commands, bus, (event) async {
        sent.add(event);
      }, ha: ha);
      haApi.open({
        ...haSession,
        'capabilities': ['ha'],
      });
      haApi.open({
        ...session,
        'capabilities': ['host.read'],
      });
    });

    tearDown(() => haApi.dispose());

    test('needs the ha capability', () async {
      final refused = await haApi.haCall({
        ...session,
        'message': {'type': 'call_service'},
      });
      expect(refused['ok'], false);
      expect((refused['data'] as Map)['code'], 'not_allowed');
      expect(ha.calls, isEmpty);
      final ok = await haApi.haCall({
        ...haSession,
        'message': {'type': 'call_service', 'domain': 'light'},
      });
      expect(ok, {
        'ok': true,
        'data': {'done': true},
      });
      expect(ha.calls.single.$1, 'ha-plugin:two');
      expect(ha.calls.single.$2, {'type': 'call_service', 'domain': 'light'});
    });

    test("errors keep Home Assistant's code and message", () async {
      ha.answer = {
        'ok': false,
        'error': {'code': 'service_not_found', 'message': 'Not found'},
      };
      expect(
        await haApi.haCall({
          ...haSession,
          'message': {'type': 'call_service'},
        }),
        {
          'ok': false,
          'error': 'service_not_found: Not found',
          'data': {'code': 'service_not_found', 'message': 'Not found'},
        },
      );
    });

    test('subscription events arrive in order, none merged', () async {
      expect(
        (await haApi.haSubscribe({
          ...haSession,
          'key': 'door',
          'message': {'type': 'subscribe_trigger'},
        }))['ok'],
        true,
      );
      for (var i = 0; i < 3; i++) {
        ha.emit!('ha-plugin:two', 'door', {
          'type': 'event',
          'event': {'n': i},
        });
      }
      // Another session's owner hears nothing here.
      ha.emit!('example:one', 'door', {'type': 'event'});
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(sent.map((e) => e['event']), [
        'ha.subscription.door',
        'ha.subscription.door',
        'ha.subscription.door',
      ]);
      expect(sent.map((e) => ((e['payload'] as Map)['event'] as Map)['n']), [
        0,
        1,
        2,
      ]);
      expect(sent.every((e) => e['session'] == 'two'), true);
    });

    test('a slow plugin hears how many events it missed', () async {
      for (var i = 0; i < 70; i++) {
        ha.emit!('ha-plugin:two', 'busy', {'type': 'event', 'event': i});
      }
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(sent, hasLength(65));
      expect(sent.last['payload'], containsPair('type', 'overflow'));
      expect(sent.last['payload'], containsPair('dropped', 6));
    });

    test('unsubscribing drops queued events and the end of a session '
        'releases everything', () async {
      ha.emit!('ha-plugin:two', 'door', {'type': 'event'});
      haApi.haUnsubscribe({...haSession, 'key': 'door'});
      expect(ha.unsubscribed, [('ha-plugin:two', 'door')]);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(sent, isEmpty);
      haApi.close(haSession);
      expect(ha.released, ['ha-plugin:two']);
    });

    test('getHostApi lists the capability', () async {
      haApi.open({
        ...haSession,
        'capabilities': ['ha', 'host.read'],
      });
      final api = await haApi.execute({
        ...haSession,
        'command': 'getHostApi',
        'arguments': const {},
      });
      final data = api['data'] as Map;
      expect(data['capabilities'], ['host.read', 'ha']);
      expect(data['haSubscriptions'], {
        'eventPrefix': 'ha.subscription.',
        'maxSubscriptions': 16,
      });
    });
  });

  group('Music Assistant access', () {
    late _FakeMa ma;
    late PluginHostApi maApi;
    const maSession = {'id': 'ma-plugin', 'session': 'three'};

    setUp(() {
      ma = _FakeMa();
      maApi = PluginHostApi(commands, bus, (event) async {
        sent.add(event);
      }, ma: ma);
      maApi.open({
        ...maSession,
        'capabilities': ['ma'],
      });
      maApi.open({
        ...session,
        'capabilities': ['host.read', 'ha'],
      });
    });

    tearDown(() => maApi.dispose());

    test('needs the ma capability', () async {
      final refused = await maApi.maCall({
        ...session,
        'command': 'players/all',
        'args': const {},
      });
      expect(refused['ok'], false);
      expect((refused['data'] as Map)['code'], 'not_allowed');
      expect(ma.calls, isEmpty);
      final ok = await maApi.maCall({
        ...maSession,
        'command': 'players/all',
        'args': {'limit': 5},
      });
      expect(ok, {
        'ok': true,
        'data': [
          {'player_id': 'p1'},
        ],
      });
      expect(ma.calls.single.$1, 'ma-plugin:three');
      expect(ma.calls.single.$2, 'players/all');
      expect(ma.calls.single.$3, {'limit': 5});
      final malformed = await maApi.maCall({
        ...maSession,
        'command': 'players/all',
        'args': 'x',
      });
      expect((malformed['data'] as Map)['code'], 'invalid_message');
    });

    test("errors keep Music Assistant's code and message", () async {
      ma.answer = {
        'ok': false,
        'error': {'code': '22', 'message': 'Insufficient permissions'},
      };
      expect(
        await maApi.maCall({
          ...maSession,
          'command': 'music/library/remove_item',
          'args': const {},
        }),
        {
          'ok': false,
          'error': '22: Insufficient permissions',
          'data': {'code': '22', 'message': 'Insufficient permissions'},
        },
      );
    });

    test('events arrive in order under their key', () async {
      expect(
        (await maApi.maSubscribe({
          ...maSession,
          'key': 'queue',
          'filter': {
            'events': ['queue_updated'],
          },
        }))['ok'],
        true,
      );
      expect(ma.subscribed.single.$3, {
        'events': ['queue_updated'],
      });
      for (var i = 0; i < 3; i++) {
        ma.emit!('ma-plugin:three', 'queue', {
          'type': 'event',
          'event': 'queue_updated',
          'data': {'n': i},
        });
      }
      ma.emit!('example:one', 'queue', {'type': 'event'});
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(sent.map((e) => e['event']), [
        'ma.subscription.queue',
        'ma.subscription.queue',
        'ma.subscription.queue',
      ]);
      expect(sent.map((e) => ((e['payload'] as Map)['data'] as Map)['n']), [
        0,
        1,
        2,
      ]);
      expect(sent.every((e) => e['session'] == 'three'), true);
    });

    test('unsubscribing drops queued events and the end of a session '
        'releases everything', () async {
      ma.emit!('ma-plugin:three', 'queue', {'type': 'event'});
      maApi.maUnsubscribe({...maSession, 'key': 'queue'});
      expect(ma.unsubscribed, [('ma-plugin:three', 'queue')]);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(sent, isEmpty);
      maApi.close(maSession);
      expect(ma.released, ['ma-plugin:three']);
    });

    test('getHostApi lists the capability', () async {
      final api = await maApi.execute({
        ...maSession,
        'command': 'getHostApi',
        'arguments': const {},
      });
      final data = api['data'] as Map;
      expect(data['capabilities'], ['ma']);
      expect(data['maSubscriptions'], {
        'eventPrefix': 'ma.subscription.',
        'maxSubscriptions': 16,
      });
      expect(data['haSubscriptions'], isNull);
    });
  });

  group('Sendspin player (issue #1053)', () {
    const player = {
      'enabled': true,
      'running': true,
      'connected': true,
      'playing': true,
      'clientId': 'f00d',
      'playerName': 'Kitchen Tablet',
      'serverName': 'Music Assistant',
      'maConfigured': true,
      'maPlayerId': 'f00d',
      'maServerId': 'abc123',
      'maServerName': 'Home',
      'maServerVersion': '2.10.2',
    };

    test('getSendspinPlayer reads the identity and nothing else', () async {
      register('sendspinPlayer', (_) async {
        return const CommandResult.ok({...player, 'token': 'secret'});
      });
      final result = await read('getSendspinPlayer');
      expect(result['ok'], true);
      expect(result['data'], player);
      expect(executed, ['sendspinPlayer']);
    });

    test('sendspin.player follows the identity', () async {
      subscribe('sendspin.player');
      bus.publish(SendspinPlayerChanged({...player, 'connected': false}));
      bus.publish(const SendspinPlayerChanged(player));
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(sent.single['event'], 'sendspin.player');
      expect(sent.single['payload'], {
        ...player,
        'time': (sent.single['payload'] as Map)['time'],
      });
    });
  });

  group('Voice skins (issue #1027)', () {
    late SettingsManager settings;
    late ValueNotifier<AssistView> view;
    late ValueNotifier<double> level;

    const answering = AssistView(
      phase: AssistPhase.speaking,
      command: 'turn on the lights',
      answer: 'Turned on the lights',
      tools: ['Turn on'],
    );

    setUp(() async {
      await api.dispose();
      SharedPreferences.setMockInitialValues({});
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      view = ValueNotifier(AssistView.hidden);
      level = ValueNotifier(0);
      api = PluginHostApi(
        commands,
        bus,
        (event) async => sent.add(event),
        voice: PluginVoiceFeed(view: view, level: level, settings: settings),
      );
      api.open({
        ...session,
        'capabilities': ['host.read'],
      });
    });

    Future<void> settle([int ms = 150]) =>
        Future<void>.delayed(Duration(milliseconds: ms));

    test('the conversation text needs its own capability', () async {
      final plain = (await read('getHostApi'))['data'] as Map;
      expect(plain['commands'], isNot(contains('getVoiceText')));
      expect(plain['events'], isNot(contains('voice.text')));
      expect((await read('getVoiceText'))['ok'], false);
      subscribe('voice.text');
      view.value = answering;
      await settle();
      expect(sent, isEmpty);

      api.open({
        ...session,
        'capabilities': ['host.read', 'voice.text'],
      });
      final catalog = (await read('getHostApi'))['data'] as Map;
      expect(catalog['capabilities'], ['host.read', 'voice.text']);
      expect(catalog['commands'], contains('getVoiceText'));
      expect(catalog['events'], contains('voice.text'));
      expect((await read('getVoiceText'))['data'], {
        'command': 'turn on the lights',
        'answer': 'Turned on the lights',
        'tools': ['Turn on'],
        'streaming': false,
        'announcement': false,
      });

      // Without host.read the capability opens nothing.
      api.open({
        ...session,
        'capabilities': ['host.control', 'voice.text'],
      });
      expect((await read('getVoiceText'))['ok'], false);
    });

    test('the text follows the Conversation settings', () async {
      api.open({
        ...session,
        'capabilities': ['host.read', 'voice.text'],
      });
      subscribe('voice.text');
      view.value = answering;
      await settle();
      expect(sent.single['event'], 'voice.text');
      expect(
        sent.single['payload'],
        containsPair('answer', 'Turned on the lights'),
      );
      sent.clear();

      await settings.set(defs.voiceShowCommand, false);
      await settings.set(defs.voiceShowTools, false);
      await settle();
      final payload = sent.single['payload'] as Map;
      expect(payload['command'], '');
      expect(payload['tools'], isEmpty);
      expect(payload['answer'], 'Turned on the lights');
      sent.clear();

      await settings.set(defs.voiceShowAnswer, false);
      expect((await read('getVoiceText'))['data'], {
        'command': '',
        'answer': '',
        'tools': <String>[],
        'streaming': false,
        'announcement': false,
      });

      // Nothing new to say: no event.
      view.value = answering.copyWith(command: 'something else');
      await settle();
      expect(sent.where((e) => e['event'] == 'voice.text'), hasLength(1));
      expect((sent.last['payload'] as Map)['answer'], '');
      sent.clear();
      view.value = answering.copyWith(command: 'another thing');
      await settle();
      expect(sent, isEmpty);
    });

    test('the voice level follows the bar and goes out quickly', () async {
      subscribe('voice.level');
      view.value = const AssistView(phase: AssistPhase.listening);
      level.value = 0.4;
      await settle(70);
      expect(sent.single['event'], 'voice.level');
      expect((sent.single['payload'] as Map)['level'], 0.4);
      sent.clear();

      // Thinking, the bar rests, and so does the level.
      view.value = const AssistView(phase: AssistPhase.thinking);
      level.value = 0.8;
      await settle(70);
      expect((sent.single['payload'] as Map)['level'], 0);
      sent.clear();

      view.value = const AssistView(phase: AssistPhase.speaking);
      level.value = 2;
      await settle(70);
      expect((sent.last['payload'] as Map)['level'], 1);
      sent.clear();

      view.value = AssistView.hidden;
      await settle(70);
      expect((sent.single['payload'] as Map)['level'], 0);
    });

    test('a plugin hears whether its skin is picked', () async {
      register(
        'voiceStatus',
        (_) async => const CommandResult.ok({'enabled': true, 'state': 'idle'}),
      );
      expect((await read('getVoiceState'))['data'], {
        'enabled': true,
        'state': 'idle',
        'skinSelected': false,
        'overlay': 'hidden',
      });
      subscribe('voice.skin');
      await settings.set(defs.voiceSkin, 'plugin:example');
      await settle();
      expect(sent.single['event'], 'voice.skin');
      expect((sent.single['payload'] as Map)['selected'], true);
      expect(
        ((await read('getVoiceState'))['data'] as Map)['skinSelected'],
        true,
      );
      sent.clear();
      await settings.set(defs.voiceSkin, 'plugin:another');
      await settle();
      expect((sent.single['payload'] as Map)['selected'], false);
    });

    test('a skin picked for Assistant 2 draws only its turns', () async {
      register(
        'voiceStatus',
        (_) async => const CommandResult.ok({'enabled': true, 'state': 'idle'}),
      );
      subscribe('voice.skin');
      subscribe('voice.overlay');
      await settings.set(defs.voiceSkin2, 'plugin:example');
      await settle();
      // Nothing shows: picked for either assistant reads as selected.
      expect((sent.single['payload'] as Map)['selected'], true);
      sent.clear();

      view.value = const AssistView(phase: AssistPhase.listening);
      await settle();
      expect(sent.map((e) => e['event']), ['voice.skin', 'voice.overlay']);
      expect((sent.first['payload'] as Map)['selected'], false);
      expect(
        ((await read('getVoiceState'))['data'] as Map)['skinSelected'],
        false,
      );
      view.value = AssistView.hidden;
      await settle();
      sent.clear();

      // Assistant 2's turn: selected before the overlay shows.
      view.value = const AssistView(phase: AssistPhase.listening, assistant: 2);
      await settle();
      expect(sent.map((e) => e['event']), ['voice.overlay']);
      expect(
        ((await read('getVoiceState'))['data'] as Map)['skinSelected'],
        true,
      );
    });

    test('a skin follows the Appearance settings', () async {
      expect((await read('getVoiceAppearance'))['data'], {
        'theme': 'auto',
        'background': null,
        'textScale': 1.0,
        'reactive': true,
      });
      subscribe('voice.appearance');
      await settings.set(defs.voiceBackgroundOpacity, 40);
      await settings.set(defs.voiceTextScale, 150);
      await settings.set(defs.voiceTheme, 'dark');
      await settle();
      expect(sent.single['event'], 'voice.appearance');
      expect(sent.single['payload'], containsPair('background', 0.4));
      expect(sent.single['payload'], containsPair('textScale', 1.5));
      expect(sent.single['payload'], containsPair('theme', 'dark'));
      sent.clear();

      // With the reactive bar off, the level holds at 0.
      subscribe('voice.level');
      view.value = const AssistView(phase: AssistPhase.listening);
      level.value = 0.6;
      await settle(70);
      expect((sent.last['payload'] as Map)['level'], 0.6);
      sent.clear();
      await settings.set(defs.voiceReactiveBar, false);
      await settle();
      expect(
        sent.firstWhere((e) => e['event'] == 'voice.appearance')['payload'],
        containsPair('reactive', false),
      );
      expect(
        (sent.firstWhere((e) => e['event'] == 'voice.level')['payload']
            as Map)['level'],
        0,
      );
      sent.clear();
      level.value = 0.9;
      await settle(70);
      expect(sent, isEmpty);
    });

    test('a plugin hears when the overlay shows, idle or not', () async {
      register(
        'voiceStatus',
        (_) async => const CommandResult.ok({'enabled': true, 'state': 'idle'}),
      );
      subscribe('voice.overlay');
      // A preview: nothing listens or speaks, and the overlay shows.
      view.value = answering.copyWith(lingering: true);
      await settle();
      expect(sent.single['event'], 'voice.overlay');
      expect((sent.single['payload'] as Map)['overlay'], 'full');
      expect(((await read('getVoiceState'))['data'] as Map)['overlay'], 'full');
      sent.clear();
      view.value = answering.copyWith(docked: true);
      await settle();
      expect((sent.single['payload'] as Map)['overlay'], 'docked');
      sent.clear();
      view.value = AssistView.hidden;
      await settle();
      expect((sent.single['payload'] as Map)['overlay'], 'hidden');
    });
  });

  test('native and Flutter event contracts match', () {
    final source = File(
      'android/app/src/main/kotlin/me/jxl/kiosk_satellite/plugins/PluginHostPolicy.kt',
    ).readAsStringSync();
    final names = RegExp(
      r'"([a-z]+\.[a-z]+)"',
    ).allMatches(source).map((m) => m[1]).toSet();
    expect(names, {
      ...PluginHostApi.eventNames,
      ...PluginHostApi.noiseEventNames,
      ...PluginHostApi.voiceTextEventNames,
    });
  });
}

class _FakeHa extends HaPluginSocket {
  _FakeHa() : super(baseUrl: () => '', token: () => '', log: Logger());

  final calls = <(String, Map<String, Object?>)>[];
  final unsubscribed = <(String, String)>[];
  final released = <String>[];
  Map<String, Object?> answer = {
    'ok': true,
    'result': {'done': true},
  };

  @override
  Future<Map<String, Object?>> call(
    String owner,
    Map<String, Object?> message,
  ) async {
    calls.add((owner, message));
    return answer;
  }

  @override
  Future<Map<String, Object?>> subscribe(
    String owner,
    String key,
    Map<String, Object?> message,
  ) async => {'ok': true};

  @override
  void unsubscribe(String owner, String key) => unsubscribed.add((owner, key));

  @override
  void release(String owner) => released.add(owner);
}

class _FakeMa extends MaPluginSocket {
  _FakeMa() : super(baseUrl: () => '', token: () => '', log: Logger());

  final calls = <(String, String, Map<String, Object?>)>[];
  final subscribed = <(String, String, Map<String, Object?>)>[];
  final unsubscribed = <(String, String)>[];
  final released = <String>[];
  Map<String, Object?> answer = {
    'ok': true,
    'result': [
      {'player_id': 'p1'},
    ],
  };

  @override
  Future<Map<String, Object?>> call(
    String owner,
    String command,
    Map<String, Object?> args,
  ) async {
    calls.add((owner, command, args));
    return answer;
  }

  @override
  Future<Map<String, Object?>> subscribe(
    String owner,
    String key,
    Map<String, Object?> filter,
  ) async {
    subscribed.add((owner, key, filter));
    return {'ok': true};
  }

  @override
  void unsubscribe(String owner, String key) => unsubscribed.add((owner, key));

  @override
  void release(String owner) => released.add(owner);
}
