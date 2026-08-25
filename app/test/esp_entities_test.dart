import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/esp_entities.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late EspEntitySurface surface;
  late List<(String, Object?)> pushed;
  late List<List<int>> images;
  late List<(String, Map<String, Object?>)> executed;
  var cameraPresent = true;
  var cameraFacings = <String>['front', 'back'];
  var bluetooth = <String, Object?>{};
  var vsState = <String, Object?>{};
  var ips = <String, Object?>{};

  setUp(() async {
    cameraPresent = true;
    cameraFacings = ['front', 'back'];
    vsState = {
      'config': {'auto_start': true},
      'satellite': 'assist_satellite.office_tablet',
      'engine': {'running': true, 'canStart': true},
    };
    ips = {
      'ipv4': {
        'wlan0': ['192.168.1.5'],
      },
      'ipv6': {
        'wlan0': ['fe80::1'],
      },
    };
    bluetooth = {
      'connected': 2,
      'devices': ['Kitchen Speaker', 'Keyboard'],
      'enabled': true,
    };
    SharedPreferences.setMockInitialValues({
      'ks.camera.enabled': true,
      'ks.launcher.enabled': true,
      'ks.btproxy.enabled': true,
      'ks.btproxy.connections': true,
      'ks.motion.sensor': true,
      'ks.screensaver.brightness_level': 0.4,
    });
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    surface = EspEntitySurface(bus, commands, log, settings);
    pushed = [];
    images = [];
    executed = [];

    void stub(String name, Object? result) => commands.register(
      Command(
        name: name,
        description: name,
        handler: (p) async {
          executed.add((name, Map<String, Object?>.from(p)));
          return CommandResult.ok(result);
        },
      ),
    );
    stub('getLightLevel', {'present': true, 'lux': 42.0});
    commands.register(
      Command(
        name: 'hasDeviceCamera',
        description: 'stub',
        handler: (_) async => CommandResult.ok(cameraPresent),
      ),
    );
    commands.register(
      Command(
        name: 'getCameraFacings',
        description: 'stub',
        handler: (_) async => CommandResult.ok(cameraFacings),
      ),
    );
    stub('getStats', {
      'battery': 73,
      'charging': true,
      'cpu': 12.4,
      'temp': 41,
    });
    stub('cameraGetConfig', {
      'views': [
        {
          'id': 'v1',
          'name': 'Front door',
          'cameraIds': ['c1'],
        },
        {'id': 'v2', 'name': 'Empty view', 'cameraIds': []},
      ],
    });
    stub('haListDashboards', [
      {'url_path': 'lovelace'},
    ]);
    stub('haListDashboardViews', [
      {'route': 'home'},
      {'route': 'cameras'},
    ]);
    stub('getDeviceDetails', {
      'ram': {'free': 512 * 1024 * 1024, 'total': 4096 * 1024 * 1024},
      'androidBuild': 'TP1A.220624.014',
    });
    stub('getUptime', {'app': 4200, 'network': 100});
    commands.register(
      Command(
        name: 'getIpAddresses',
        description: 'stub',
        handler: (_) async => CommandResult.ok(ips),
      ),
    );
    stub('foregroundApp', {'package': 'me.jxl.kiosk_satellite'});
    commands.register(
      Command(
        name: 'getBluetoothConnections',
        description: 'stub',
        handler: (_) async => CommandResult.ok(bluetooth),
      ),
    );
    commands.register(
      Command(
        name: 'vsEngineState',
        description: 'stub',
        handler: (_) async {
          executed.add(('vsEngineState', const {}));
          return vsState.isEmpty
              ? const CommandResult.fail('no hook')
              : CommandResult.ok(vsState);
        },
      ),
    );
    stub('btProxyNearby', {'count': 13});
    stub('btProxyStatus', {
      'connections': ['AA:BB:CC:DD:EE:FF'],
      'connectionSlots': 3,
    });
    stub('isScreenOn', true);
    stub('getBrightness', 0.4);
    stub('getVolume', 55);
    stub('getUpdateStatus', {
      'currentVersion': '2026.8.52',
      'availableVersion': '2026.8.53',
      'availableNotes': 'Notes',
      'releaseUrl': 'https://example/r',
    });
    stub('getNextAlarm', {'at': '2026-08-19T07:00:00+00:00'});
    stub('getDeviceInfo', {
      'model': 'samsung SM-X700',
      'osVersion': 'Android 13',
      'ip': '192.168.1.5',
    });
    stub('evalJs', '"https://ha.local/lovelace/home"');
    stub('screenshot', base64Encode([1, 2, 3]));
    for (final name in [
      'screenOn',
      'screenOff',
      'setBrightness',
      'setVolume',
      'startScreensaver',
      'stopScreensaver',
      'postponeScreensaver',
      'reload',
      'loadStartUrl',
      'clearWebCache',
      'restartApp',
      'bringToFront',
      'showAppLauncher',
      'showMusicAssistant',
      'hideCameraView',
      'showCameraView',
      'haNavigate',
      'installUpdate',
      'takeCameraSnapshot',
      'vsEngine',
      'vsSetBrowserSettings',
    ]) {
      stub(name, null);
    }
  });

  tearDown(() => surface.detach());

  Future<void> attach() async {
    surface.attach(
      (objectId, value) async => pushed.add((objectId, value)),
      (jpeg) async => images.add(jpeg),
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  test('the catalog mirrors the MQTT entity set', () async {
    final catalog = await surface.build();
    final ids = [for (final d in catalog) '${d['objectId']}'];
    expect(
      ids,
      containsAll([
        'screen',
        'screensaver_active',
        'volume',
        'postpone_screensaver',
        'reload',
        'load_start_url',
        'clear_cache',
        'restart',
        'bring_to_front',
        'open_launcher',
        'camera_view',
        'close_camera_view',
        'active_camera_view',
        'dashboard_view',
        'update',
        'device_camera',
        'take_snapshot',
        'last_snapshot',
        'take_screenshot',
        'last_screenshot',
        'illuminance',
        'motion',
        'next_alarm',
        'last_interaction',
        'screensaver_brightness_level',
        'assistant_volume',
        'media_volume',
        'clock_background',
        'kiosk',
        'lockdown',
        'ha_kiosk',
        'keep_screen_on',
        'remote',
        'screensaver_brightness',
        'screensaver',
        'hold_mode',
        'camera_enabled',
        'screensaver_motion',
        'screensaver_face',
        'screensaver_mode',
        'screensaver_clock_style',
        'battery',
        'charging',
        'cpu',
        'cpu_temp',
        'ram_free',
        'ram_total',
        'url',
        'foreground_app',
        'btproxy_nearby',
        'device_info',
        'ipv4_address',
        'ipv6_address',
        'app_uptime',
        'network_uptime',
        'admin_url',
      ]),
    );
    // The MQTT catalog's attributes have nowhere to live in the ESPHome
    // protocol, so the Device and IP detail is its own entity here.
    for (final id in [
      'android_version',
      'android_build',
      'ipv4_interfaces',
      'ipv6_interfaces',
    ]) {
      expect(ids, contains(id), reason: id);
      final def = catalog.firstWhere((d) => d['objectId'] == id);
      expect(def['category'], 2, reason: id);
      expect(def['type'], 'text_sensor', reason: id);
    }
    expect(ids, contains('connectivity'));
    expect(ids, contains('bt_max_connections'));
    expect(ids, contains('bt_devices_connected'));
    expect(ids, contains('last_seen'));
    final byId = {for (final d in catalog) d['objectId']: d};
    // Only views with cameras become options; 'Closed' leads. The
    // per-view show buttons ride along, exactly like MQTT.
    expect(byId['camera_view']!['options'], ['Closed', 'Front door']);
    expect(byId['camera_view_v1']!['name'], 'Show Front door');
    expect(byId.containsKey('camera_view_v2'), isFalse);
    expect(byId['dashboard_view']!['options'], [
      'lovelace/home',
      'lovelace/cameras',
    ]);
    // With a camera present and enabled it takes the one camera slot.
    expect(byId['device_camera']!['type'], 'camera');
    expect(byId.containsKey('screenshot'), isFalse);
    expect(byId['screensaver_mode']!['options'], isNotEmpty);
  });

  test('connected Bluetooth devices ride the proxy switch', () async {
    // Off with the proxy, whatever the platform would answer.
    await settings.set(defs.btproxyEnabled, false);
    var ids = [for (final d in await surface.build()) '${d['objectId']}'];
    expect(ids, isNot(contains('bt_devices_connected')));

    // Back on, and the sensor comes with the rest of the proxy set.
    await settings.set(defs.btproxyEnabled, true);
    ids = [for (final d in await surface.build()) '${d['objectId']}'];
    expect(ids, contains('bt_devices_connected'));
  });

  test('a device Android will not answer for gets no sensor', () async {
    // No adapter, or no Nearby devices grant: an entity that could only
    // ever read unknown is not published at all.
    bluetooth = {};
    final ids = [for (final d in await surface.build()) '${d['objectId']}'];
    expect(ids, isNot(contains('bt_devices_connected')));
    expect(ids, contains('btproxy_nearby'));
  });

  test('a link coming up pushes without waiting for the poll', () async {
    await surface.build();
    await attach();
    pushed.clear();
    bluetooth = {
      'connected': 3,
      'devices': ['Kitchen Speaker', 'Keyboard', 'Yale Lock'],
      'enabled': true,
    };
    bus.publish(const BluetoothLinksChanged());
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final byId = {for (final (id, value) in pushed) id: value};
    expect(byId['bt_devices_connected'], 3);
    // The budget rides the same read.
    expect(byId['bt_max_connections'], 3);
  });

  test('a camera-less device gets the screenshot camera instead', () async {
    cameraPresent = false;
    final catalog = await surface.build();
    final ids = [for (final d in catalog) '${d['objectId']}'];
    expect(ids, contains('screenshot'));
    expect(ids, isNot(contains('device_camera')));
    expect(ids, isNot(contains('take_snapshot')));
    expect(ids, isNot(contains('motion'))); // rides the camera
  });

  test('the camera facing select needs both facings', () async {
    var ids = [for (final d in await surface.build()) '${d['objectId']}'];
    expect(ids, contains('camera_device'));

    // Single-camera hardware (Echo Show 5): no choice, no dropdown.
    cameraFacings = ['front'];
    ids = [for (final d in await surface.build()) '${d['objectId']}'];
    expect(ids, isNot(contains('camera_device')));

    // An empty answer means the probe could not look, not one camera:
    // stay optimistic like hasDeviceCamera.
    cameraFacings = [];
    ids = [for (final d in await surface.build()) '${d['objectId']}'];
    expect(ids, contains('camera_device'));

    // But no camera at all beats any facing answer.
    cameraPresent = false;
    ids = [for (final d in await surface.build()) '${d['objectId']}'];
    expect(ids, isNot(contains('camera_device')));
  });

  test('the camera facing select speaks in labels, stores the value', () async {
    final catalog = await surface.build();
    final select = catalog.firstWhere((d) => d['objectId'] == 'camera_device');
    expect(select['options'], ['Front', 'Back']);

    await surface.handleCommand('camera_device', 'Back');
    expect(settings.get(defs.cameraDevice), 'back');
    // The raw stored vocabulary is accepted too.
    await surface.handleCommand('camera_device', 'front');
    expect(settings.get(defs.cameraDevice), 'front');
  });

  test('the Music Assistant button follows the server address', () async {
    // No address configured: no button.
    var ids = [for (final d in await surface.build()) '${d['objectId']}'];
    expect(ids, isNot(contains('show_music_assistant')));

    await settings.set(defs.sendspinMaUrl, '192.168.1.10:8095');
    ids = [for (final d in await surface.build()) '${d['objectId']}'];
    expect(ids, contains('show_music_assistant'));

    executed.clear();
    await surface.handleCommand('show_music_assistant', null);
    expect(executed.map((e) => e.$1).toList(), ['showMusicAssistant']);
  });

  test('IPv6 leads with the routable address, without its scope id', () async {
    ips = {
      'ipv4': {
        'wlan0': ['192.168.1.50'],
        'eth0': ['10.0.3.2'],
      },
      'ipv6': {
        'wlan0': ['fe80::1234%wlan0', '2001:db8::50'],
      },
    };
    await surface.build();
    await attach();
    final byId = {for (final (id, value) in pushed) id: value};
    expect(byId['ipv4_address'], '192.168.1.50');
    expect(byId['ipv4_interfaces'], 'wlan0: 192.168.1.50; eth0: 10.0.3.2');
    expect(byId['ipv6_address'], '2001:db8::50');
    expect(byId['ipv6_interfaces'], 'wlan0: fe80::1234, 2001:db8::50');
  });

  test('attach pushes an initial snapshot from the live sources', () async {
    await surface.build();
    await attach();
    final byId = {for (final (id, value) in pushed) id: value};
    expect(byId['battery'], 73);
    expect(byId['charging'], true);
    expect(byId['cpu'], 12);
    expect(byId['cpu_temp'], 41);
    expect(byId['ram_free'], 512);
    expect(byId['ram_total'], 4096);
    expect(byId['ipv4_address'], '192.168.1.5');
    expect(byId['ipv6_address'], 'fe80::1');
    // Uptimes are timestamp anchors like their MQTT twins: the moment the
    // app started, rendered by HA as "n hours ago".
    final appAnchor = DateTime.parse('${byId['app_uptime']}');
    final drift = DateTime.now().toUtc().difference(appAnchor).inSeconds - 4200;
    expect(drift.abs(), lessThan(30));
    expect(DateTime.parse('${byId['last_seen']}'), isA<DateTime>());
    expect(byId['foreground_app'], 'me.jxl.kiosk_satellite');
    expect(byId['btproxy_nearby'], 13);
    // The budget, not the usage: the connected-devices sensor is the
    // number that moves.
    expect(byId['bt_max_connections'], 3);
    expect(byId['bt_devices_connected'], 2);
    expect(byId['volume'], 55);
    expect(byId['screen'], {'on': true, 'brightness': 0.4});
    expect((byId['update'] as Map)['latest'], '2026.8.53');
    expect(byId['next_alarm'], '2026-08-19T07:00:00+00:00');
    expect(byId['admin_url'], 'disabled'); // remote.enabled defaults false
    expect(byId['device_info'], 'samsung SM-X700');
    expect(byId['android_version'], 'Android 13');
    expect(byId['android_build'], 'TP1A.220624.014');
    expect(byId['ipv4_interfaces'], 'wlan0: 192.168.1.5');
    expect(byId['ipv6_interfaces'], 'wlan0: fe80::1');
    expect(byId['kiosk'], false);
    expect(byId['camera_enabled'], true);
    expect(byId['screensaver_brightness_level'], 40);
    expect(byId['illuminance'], 42);
    // The selects report first values instead of sitting on "unknown".
    expect(byId['camera_view'], 'Closed');
    expect(byId['active_camera_view'], 'none');
    expect(byId['url'], 'https://ha.local/lovelace/home');
    expect(byId['dashboard_view'], 'lovelace/home');
  });

  test('commands land on the same handlers MQTT uses', () async {
    await surface.build();
    await attach();
    executed.clear();
    await surface.handleCommand('screen', {'on': false});
    await surface.handleCommand('screen', {'brightness': 0.7});
    await surface.handleCommand('volume', 30.0);
    await surface.handleCommand('camera_view', 'Front door');
    await surface.handleCommand('camera_view_v1', null);
    await surface.handleCommand('camera_view', 'Closed');
    await surface.handleCommand('dashboard_view', 'lovelace/cameras');
    await surface.handleCommand('update', 'install');
    expect(executed.map((e) => e.$1).toList(), [
      'screenOff',
      'setBrightness',
      'setVolume',
      'showCameraView',
      'showCameraView',
      'hideCameraView',
      'haNavigate',
      'installUpdate',
    ]);
    expect(executed[3].$2['viewId'], 'v1');
    expect(executed[4].$2['viewId'], 'v1');
    expect(executed[6].$2['path'], 'lovelace/cameras');
  });

  test('setting-backed entities write settings and echo real state', () async {
    await surface.build();
    await attach();
    pushed.clear();
    await surface.handleCommand('kiosk', true);
    expect(settings.get(defs.kioskEnabled), isTrue);
    await surface.handleCommand('screensaver_mode', 'Black');
    expect(settings.get(defs.screensaverMode), 'black');
    await surface.handleCommand('assistant_volume', 60.0);
    expect(settings.get(defs.assistantVolume), 60);
    await surface.handleCommand('screensaver_brightness_level', 30.0);
    expect(settings.get(defs.screensaverBrightnessLevel), closeTo(0.3, 1e-9));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // The SettingChanged events echoed the new states back to HA.
    expect(pushed, contains(('kiosk', true)));
    expect(pushed, contains(('assistant_volume', 60)));
    expect(pushed, contains(('screensaver_brightness_level', 30)));
  });

  test(
    'the screenshot capture feeds the camera on camera-less devices',
    () async {
      cameraPresent = false;
      await surface.build();
      await attach();
      await surface.handleCommand('screenshot', 'capture');
      expect(images, [
        [1, 2, 3],
      ]);
      expect(pushed.any((p) => p.$1 == 'last_screenshot'), isTrue);
    },
  );

  test('motion pulses on and back off after the configured delay', () async {
    await surface.build();
    await attach();
    pushed.clear();
    bus.publish(const MotionDetected());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(pushed, contains(('motion', true)));
  });

  test('touches and spoken turns stamp Last interaction, ambient noise '
      'does not', () async {
    await surface.build();
    await attach();
    pushed.clear();
    // None of these count as the user interacting.
    bus.publish(const MotionDetected());
    bus.publish(const ActivityDetected(source: 'motion'));
    bus.publish(const VoiceInteractionChanged(active: true, reason: 'media'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(pushed.any((p) => p.$1 == 'last_interaction'), isFalse);
    bus.publish(const ActivityDetected(source: 'touch'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final stamps = [
      for (final p in pushed)
        if (p.$1 == 'last_interaction') p,
    ];
    expect(stamps, hasLength(1));
    expect(DateTime.parse('${stamps.single.$2}'), isA<DateTime>());
    // Persisted so a restart can reseed it, broker-retention style.
    expect(
      settings.internal('esphome_last_interaction'),
      '${stamps.single.$2}',
    );
  });

  test('the persisted stamp reseeds Last interaction at attach', () async {
    await settings.setInternal(
      'esphome_last_interaction',
      '2026-08-18T20:00:00.000Z',
    );
    await surface.build();
    await attach();
    final byId = {for (final (id, value) in pushed) id: value};
    expect(byId['last_interaction'], '2026-08-18T20:00:00.000Z');
  });

  group('the Voice Satellite switches (issue #288)', () {
    setUp(() async {
      await settings.set(
        defs.haSatelliteEntity,
        'assist_satellite.office_tablet',
      );
    });

    test('exist only while a satellite is bound', () async {
      var ids = [for (final d in await surface.build()) '${d['objectId']}'];
      expect(ids, contains('voice_satellite'));
      expect(ids, contains('voice_satellite_auto_start'));

      // Nothing to start without a binding, so neither switch is published.
      await settings.set(defs.haSatelliteEntity, '');
      ids = [for (final d in await surface.build()) '${d['objectId']}'];
      expect(ids, isNot(contains('voice_satellite')));
      expect(ids, isNot(contains('voice_satellite_auto_start')));
    });

    test('report what the page says, not what was asked for', () async {
      await surface.build();
      await attach();
      var byId = {for (final (id, value) in pushed) id: value};
      expect(byId['voice_satellite'], true);
      expect(byId['voice_satellite_auto_start'], true);

      // A start the page refuses (no session behind it) must not leave the
      // switch reading on.
      vsState = {
        'config': {'auto_start': false},
        'engine': {'running': false, 'canStart': false},
      };
      pushed.clear();
      executed.clear();
      await surface.handleCommand('voice_satellite', true);
      byId = {for (final (id, value) in pushed) id: value};
      expect(executed.first.$1, 'vsEngine');
      expect(executed.first.$2['action'], 'start');
      expect(byId['voice_satellite'], false);
    });

    test(
      'stop rides the same page path, auto start the settings hook',
      () async {
        await surface.build();
        await attach();
        executed.clear();
        await surface.handleCommand('voice_satellite', false);
        expect(executed.first.$1, 'vsEngine');
        expect(executed.first.$2['action'], 'stop');

        executed.clear();
        await surface.handleCommand('voice_satellite_auto_start', false);
        expect(executed.first.$1, 'vsSetBrowserSettings');
        expect(executed.first.$2['settings'], {'auto_start': false});
      },
    );

    test('a page with no Voice Satellite keeps the last known state', () async {
      await surface.build();
      await attach();
      pushed.clear();
      // Showing a website, or mid-load: the hook cannot answer, and a
      // guess would be worse than the value Home Assistant already has.
      vsState = {};
      bus.publish(const WakeWordStateChanged(active: false, listening: false));
      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect(pushed.any((p) => p.$1 == 'voice_satellite'), isFalse);
    });
  });
}
