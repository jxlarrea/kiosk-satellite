import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
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
  late Logger log;
  late List<(String, Object?)> pushed;
  late List<(String, List<int>)> images;
  late List<(String, Map<String, Object?>)> executed;
  var cameraPresent = true;
  // Null for a device without a battery (issue #367).
  int? battery = 73;
  var cameraFacings = <String>['front', 'back'];
  var bluetooth = <String, Object?>{};
  var vsState = <String, Object?>{};
  var ips = <String, Object?>{};
  var dashboardsUnreachable = false;
  var catalogChanges = 0;
  var updateStatus = <String, Object?>{};

  setUp(() async {
    cameraPresent = true;
    updateStatus = {
      'currentVersion': '2026.8.52',
      'availableVersion': '2026.8.53',
      'availableNotes': 'Notes',
      'releaseUrl': 'https://example/r',
    };
    battery = 73;
    dashboardsUnreachable = false;
    catalogChanges = 0;
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
    log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    surface = EspEntitySurface(
      bus,
      commands,
      log,
      settings,
      onCatalogChanged: () => catalogChanges++,
    );
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
    stub('getProximitySupport', {
      'supported': true,
      'name': 'STK3310 Proximity',
    });
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
    commands.register(
      Command(
        name: 'getStats',
        description: 'stub',
        handler: (_) async => CommandResult.ok({
          'battery': battery,
          'charging': true,
          'cpu': 12.4,
          'temp': 41,
        }),
      ),
    );
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
    commands.register(
      Command(
        name: 'haListDashboards',
        description: 'stub',
        handler: (p) async {
          executed.add(('haListDashboards', Map<String, Object?>.from(p)));
          return dashboardsUnreachable
              ? const CommandResult.fail('could not list dashboards')
              : const CommandResult.ok([
                  {'url_path': 'lovelace'},
                ]);
        },
      ),
    );
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
    stub('esphomeStatus', {
      'connections': ['AA:BB:CC:DD:EE:FF'],
      'connectionSlots': 3,
    });
    stub('isScreenOn', true);
    stub('getBrightness', 0.4);
    stub('getVolume', 55);
    commands.register(
      Command(
        name: 'getUpdateStatus',
        description: 'stub',
        handler: (_) async => CommandResult.ok(updateStatus),
      ),
    );
    stub('getNextAlarm', {'at': '2026-08-19T07:00:00+00:00'});
    stub('getDeviceInfo', {
      'model': 'samsung SM-X700',
      'osVersion': 'Android 13',
      'ip': '192.168.1.5',
      'appVersion': '2026.8.104',
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
      'nextScreensaverSlide',
      'previousScreensaverSlide',
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
      'dismissNotification',
    ]) {
      stub(name, null);
    }
  });

  tearDown(() => surface.detach());

  /// The frames sent so far as "id:bytes" strings, comparable by value.
  List<String> frames() => [
    for (final (id, jpeg) in images) '$id:${jpeg.join(',')}',
  ];

  Future<void> attach() async {
    surface.attach(
      (objectId, value) async => pushed.add((objectId, value)),
      (objectId, jpeg) async => images.add((objectId, jpeg)),
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
        'screensaver_next_slide',
        'screensaver_previous_slide',
        'notifications_dismiss_all',
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
        'panel_brightness',
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
        'screensaver_proximity',
        'theme',
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
      'app_version',
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
    // Both cameras: the display on every device, the hardware where it is.
    expect(byId['device_camera']!['type'], 'camera');
    expect(byId['screenshot']!['type'], 'camera');
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

  test('a camera-less device keeps the screenshot camera', () async {
    cameraPresent = false;
    final catalog = await surface.build();
    final ids = [for (final d in catalog) '${d['objectId']}'];
    expect(ids, contains('screenshot'));
    expect(ids, contains('take_screenshot'));
    expect(ids, contains('last_screenshot'));
    expect(ids, isNot(contains('device_camera')));
    expect(ids, isNot(contains('take_snapshot')));
    expect(ids, isNot(contains('motion'))); // rides the camera
  });

  test(
    'switching the camera off keeps its entities and blanks motion',
    () async {
      // The catalog follows the hardware: an automation that arms the
      // camera through the day must not re-list the device on every flip
      // (issue #339).
      await settings.set(defs.cameraEnabled, false);
      final ids = [for (final d in await surface.build()) '${d['objectId']}'];
      expect(ids, contains('device_camera'));
      expect(ids, contains('take_snapshot'));
      expect(ids, contains('last_snapshot'));
      expect(ids, contains('motion'));
      // The screenshot camera never depended on the camera switch.
      expect(ids, contains('screenshot'));

      // Off, the motion sensor is listed but reads unknown, and nothing a
      // stale detector says gets through.
      await attach();
      expect(pushed, contains(('motion', null)));
      expect(pushed, isNot(contains(('motion', false))));
      pushed.clear();
      bus.publish(const MotionDetected());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(pushed.any((p) => p.$1 == 'motion'), isFalse);

      // Back on, it clears and reads again.
      await settings.set(defs.cameraEnabled, true);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(pushed, contains(('motion', false)));
      pushed.clear();
      bus.publish(const MotionDetected());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(pushed, contains(('motion', true)));

      // The Motion sensor setting alone does the same, without a re-list.
      pushed.clear();
      await settings.set(defs.motionSensor, false);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(pushed, contains(('motion', null)));
      final again = [for (final d in await surface.build()) '${d['objectId']}'];
      expect(again, contains('motion'));
    },
  );

  test('the camera answers a "Camera off" frame while disabled', () async {
    await settings.set(defs.cameraEnabled, false);
    await surface.build();
    await attach();
    expect(images, isEmpty);

    // A fetch from Home Assistant gets the frame, not a capture attempt.
    await surface.handleCommand('device_camera', 'capture');
    expect(images, hasLength(1));
    expect(images.single.$1, 'device_camera');
    final frame = images.single.$2;
    expect(frame.length, greaterThan(1000));
    expect(frame.sublist(0, 2), [0xFF, 0xD8]); // a JPEG
    expect(executed.any((e) => e.$1 == 'takeCameraSnapshot'), isFalse);
    expect(pushed.any((p) => p.$1 == 'last_snapshot'), isFalse);

    // On, a fetch captures again.
    images.clear();
    await settings.set(defs.cameraEnabled, true);
    await surface.handleCommand('device_camera', 'capture');
    expect(executed.any((e) => e.$1 == 'takeCameraSnapshot'), isTrue);
    expect(images, isEmpty);
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

  test(
    'the theme select pins the dashboard theme from Home Assistant',
    () async {
      final catalog = await surface.build();
      final select = catalog.firstWhere((d) => d['objectId'] == 'theme');
      expect(select['type'], 'select');
      expect(select['options'], ['Auto', 'Light', 'Dark']);

      await surface.handleCommand('theme', 'Dark');
      expect(settings.get(defs.haTheme), 'dark');
      await surface.handleCommand('theme', 'light');
      expect(settings.get(defs.haTheme), 'light');
      await surface.handleCommand('theme', 'Auto');
      expect(settings.get(defs.haTheme), 'auto');
    },
  );

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

  test('a setting flipped from Home Assistant names its caller', () async {
    // A switch written by an automation and one written on the device look
    // the same in the settings line without this, and the difference is
    // the whole diagnosis when a screensaver keeps turning itself off.
    await surface.handleCommand('screensaver', false);
    expect(settings.get(defs.screensaverEnabled), isFalse);
    final lines = log.recent.map((e) => '${e.tag}: ${e.message}').toList();
    expect(lines, contains('esphome: command screensaver = false'));
    expect(
      lines,
      contains('settings: set screensaver.enabled = false [esphome]'),
    );
  });

  test('the slide buttons step the showing slideshow', () async {
    executed.clear();
    await surface.handleCommand('screensaver_next_slide', null);
    await surface.handleCommand('screensaver_previous_slide', null);
    expect(executed.map((e) => e.$1).toList(), [
      'nextScreensaverSlide',
      'previousScreensaverSlide',
    ]);
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

  test(
    'a device without a battery gets no Battery entity (issue #367)',
    () async {
      battery = null;
      final catalog = await surface.build();
      final ids = [for (final d in catalog) '${d['objectId']}'];
      expect(ids, isNot(contains('battery')));
      // Charging is its own reading: a mains-powered box still says it is
      // on external power.
      expect(ids, contains('charging'));
      await attach();
      final byId = {for (final (id, value) in pushed) id: value};
      expect(byId.containsKey('battery'), isFalse);
      expect(byId['charging'], true);
      expect(byId['cpu'], 12);
    },
  );

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
    expect(byId['app_version'], '2026.8.104');
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

  test('a mid-download update state carries a 0-100 percentage', () async {
    await surface.build();
    await attach();
    pushed.clear();
    // The manager reports a 0..1 fraction; the wire wants percent.
    updateStatus['progress'] = 0.42;
    bus.publish(const UpdateStateChanged());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final state =
        pushed.lastWhere((p) => p.$1 == 'update').$2 as Map<String, Object?>;
    expect(state['inProgress'], true);
    expect(state['progress'], closeTo(42, 1e-9));
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

  test('a fetch of the screenshot camera captures the display', () async {
    cameraPresent = false;
    await surface.build();
    await attach();
    await surface.handleCommand('screenshot', 'capture');
    expect(frames(), ['screenshot:1,2,3']);
    // A fetch feeds the entity and nothing else: Last screenshot belongs
    // to the button alone.
    expect(pushed.any((p) => p.$1 == 'last_screenshot'), isFalse);
    expect(settings.internal('esphome_last_screenshot'), isEmpty);
  });

  test('the screenshot camera feeds beside the device camera', () async {
    // Camera hardware present and on: the display still has its own
    // camera entity, and the Take screenshot button feeds it too.
    await surface.build();
    await attach();
    await surface.handleCommand('screenshot', 'capture');
    await surface.handleCommand('take_screenshot', null);
    expect(frames(), ['screenshot:1,2,3', 'screenshot:1,2,3']);
    expect(executed.any((e) => e.$1 == 'takeCameraSnapshot'), isFalse);
    // Only the button press stamped Last screenshot.
    final stamps = [
      for (final p in pushed)
        if (p.$1 == 'last_screenshot') p.$2,
    ];
    expect(stamps, hasLength(1));
    // Kept for the next attach, broker-retention style.
    expect(settings.internal('esphome_last_screenshot'), '${stamps.single}');
  });

  test('a remote admin capture feeds the camera and stamps', () async {
    await surface.build();
    await attach();
    bus.publish(ScreenshotTaken(jpeg: Uint8List.fromList([9, 8, 7])));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(frames(), ['screenshot:9,8,7']);
    final stamps = [
      for (final p in pushed)
        if (p.$1 == 'last_screenshot') p.$2,
    ];
    expect(stamps, hasLength(1));
    expect(settings.internal('esphome_last_screenshot'), '${stamps.single}');
  });

  test('the persisted capture stamps reseed at attach', () async {
    await settings.setInternal(
      'esphome_last_screenshot',
      '2026-08-28T18:44:41.000Z',
    );
    await settings.setInternal(
      'esphome_last_snapshot',
      '2026-08-28T18:40:00.000Z',
    );
    await surface.build();
    await attach();
    final byId = {for (final (id, value) in pushed) id: value};
    expect(byId['last_screenshot'], '2026-08-28T18:44:41.000Z');
    expect(byId['last_snapshot'], '2026-08-28T18:40:00.000Z');

    // Without camera hardware there is no snapshot sensor to seed.
    pushed.clear();
    surface.detach();
    cameraPresent = false;
    await surface.build();
    await attach();
    final again = {for (final (id, value) in pushed) id: value};
    expect(again['last_screenshot'], '2026-08-28T18:44:41.000Z');
    expect(again.containsKey('last_snapshot'), isFalse);
  });

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

  test('a power button wake stamps Last interaction, the app\'s own wakes '
      'do not (issue #348)', () async {
    await surface.build();
    await attach();
    pushed.clear();
    bus.publish(const ScreenStateChanged(on: true, source: 'app'));
    bus.publish(const ScreenStateChanged(on: false, source: 'system'));
    bus.publish(const ScreenStateChanged(on: true, source: 'probe'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(pushed.any((p) => p.$1 == 'last_interaction'), isFalse);
    bus.publish(const ScreenStateChanged(on: true, source: 'system'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final stamps = [
      for (final p in pushed)
        if (p.$1 == 'last_interaction') p,
    ];
    expect(stamps, hasLength(1));
    expect(DateTime.parse('${stamps.single.$2}'), isA<DateTime>());
  });

  group('the dashboard view list (issue #362)', () {
    int reads() => executed.where((e) => e.$1 == 'haListDashboards').length;

    test('a read that fails at start leaves the select out, and a '
        'persisted list keeps it in without asking', () async {
      dashboardsUnreachable = true;
      var ids = [for (final d in await surface.build()) '${d['objectId']}'];
      expect(ids, isNot(contains('dashboard_view')));
      expect(settings.internal('mqtt_dashboard_views'), isEmpty);

      // The list the last successful read left behind (either surface's)
      // serves the next start, so the select is there from the first
      // connection even while Home Assistant is still down.
      await settings.setInternal(
        'mqtt_dashboard_views',
        jsonEncode(['lovelace/home']),
      );
      executed.clear();
      final catalog = await surface.build();
      ids = [for (final d in catalog) '${d['objectId']}'];
      expect(ids, contains('dashboard_view'));
      final select = catalog.firstWhere(
        (d) => d['objectId'] == 'dashboard_view',
      );
      expect(select['options'], ['lovelace/home']);
      expect(reads(), 0);
    });

    test('a successful read at start is kept for the next one', () async {
      await surface.build();
      expect(jsonDecode(settings.internal('mqtt_dashboard_views')), [
        'lovelace/home',
        'lovelace/cameras',
      ]);
    });

    test('a list learned while serving re-lists the catalog, once', () async {
      dashboardsUnreachable = true;
      await surface.build();
      await attach();
      expect(catalogChanges, 0);

      // Still unreachable: nothing to re-list, nothing persisted.
      await surface.relearnDashboardViews();
      expect(catalogChanges, 0);
      expect(settings.internal('mqtt_dashboard_views'), isEmpty);

      dashboardsUnreachable = false;
      await surface.relearnDashboardViews();
      expect(catalogChanges, 1);
      expect(jsonDecode(settings.internal('mqtt_dashboard_views')), [
        'lovelace/home',
        'lovelace/cameras',
      ]);
      // The restart that follows rebuilds with the list in place.
      final catalog = await surface.build();
      final select = catalog.firstWhere(
        (d) => d['objectId'] == 'dashboard_view',
      );
      expect(select['options'], ['lovelace/home', 'lovelace/cameras']);

      // The same list again, or a read that fails, never restarts the
      // server: that makes every entity unavailable for a moment.
      await surface.relearnDashboardViews();
      dashboardsUnreachable = true;
      await surface.relearnDashboardViews();
      expect(catalogChanges, 1);
      expect(jsonDecode(settings.internal('mqtt_dashboard_views')), [
        'lovelace/home',
        'lovelace/cameras',
      ]);
    });

    test('the page reporting a dashboard change re-reads the list, '
        'coalesced, from the page only', () {
      dashboardsUnreachable = true;
      fakeAsync((async) {
        surface.build();
        async.flushMicrotasks();
        surface.attach(
          (objectId, value) async => pushed.add((objectId, value)),
          (objectId, jpeg) async => images.add((objectId, jpeg)),
        );
        async.elapse(const Duration(milliseconds: 100));
        executed.clear();
        dashboardsUnreachable = false;
        // A create fires several reports in a row: one read.
        bus.publish(const HaDashboardsChanged(reason: 'panels'));
        bus.publish(const HaDashboardsChanged(reason: 'lovelace'));
        async.elapse(const Duration(seconds: 2));
        expect(reads(), 0);
        async.elapse(const Duration(seconds: 2));
        expect(reads(), 1);
        expect(catalogChanges, 1);
        final read = executed.firstWhere((e) => e.$1 == 'haListDashboards');
        expect(read.$2, {'source': 'page'});
        surface.detach();
      });
    });

    test('the poll never re-reads the list', () {
      dashboardsUnreachable = true;
      fakeAsync((async) {
        surface.build();
        async.flushMicrotasks();
        surface.attach(
          (objectId, value) async => pushed.add((objectId, value)),
          (objectId, jpeg) async => images.add((objectId, jpeg)),
        );
        async.elapse(const Duration(milliseconds: 100));
        executed.clear();
        dashboardsUnreachable = false;
        async.elapse(const Duration(minutes: 30));
        expect(reads(), 0);
        expect(catalogChanges, 0);
        surface.detach();
      });
    });
  });

  group('the Person sensor (discussion #353)', () {
    List<String> ids(List<Map<String, Object?>> catalog) => [
      for (final d in catalog) '${d['objectId']}',
    ];
    void stub(String name, Object? result) => commands.register(
      Command(
        name: name,
        description: name,
        handler: (_) async => CommandResult.ok(result),
      ),
    );

    test('exists only with Dismiss on person on, on a device with a '
        'person sensor', () async {
      stub('getPersonSensorSupport', {'supported': true});
      stub('getPersonSensor', {'running': true, 'present': false});
      expect(ids(await surface.build()), isNot(contains('person')));
      await settings.set(defs.screensaverDismissOnPerson, true);
      final catalog = await surface.build();
      final person = catalog.singleWhere((d) => d['objectId'] == 'person');
      expect(person['type'], 'binary_sensor');
      expect(person['deviceClass'], 'occupancy');
    });

    test('a device without one lists it never, switch or no switch', () async {
      stub('getPersonSensorSupport', {'supported': false, 'hint': 'none'});
      await settings.set(defs.screensaverDismissOnPerson, true);
      expect(ids(await surface.build()), isNot(contains('person')));
    });

    test('reads the sensor at attach and follows its changes', () async {
      stub('getPersonSensorSupport', {'supported': true});
      stub('getPersonSensor', {'running': true, 'present': true});
      await settings.set(defs.screensaverDismissOnPerson, true);
      await surface.build();
      await attach();
      expect(pushed, contains(('person', true)));
      pushed.clear();
      bus.publish(const PersonSensorChanged(present: false));
      await Future<void>.delayed(Duration.zero);
      expect(pushed, contains(('person', false)));
    });

    test('unknown while the sensor cannot be read', () async {
      stub('getPersonSensorSupport', {'supported': true});
      stub('getPersonSensor', {
        'running': false,
        'present': false,
        'error': 'Log access not granted.',
      });
      await settings.set(defs.screensaverDismissOnPerson, true);
      await surface.build();
      await attach();
      expect(pushed, contains(('person', null)));
    });
  });

  group('the location sensors (issue #363)', () {
    const fix = {
      'latitude': 45.5019,
      'longitude': -73.5674,
      'time': 1756500000000,
      'accuracy': 8.0,
      'altitude': 31.0,
      'speed': 0.5,
    };
    const locationIds = [
      'gps_latitude',
      'gps_longitude',
      'gps_accuracy',
      'altitude',
      'speed',
      'last_location_fix',
    ];

    List<String> ids(List<Map<String, Object?>> catalog) => [
      for (final d in catalog) '${d['objectId']}',
    ];

    // The two location commands are not in the shared stubs: each test
    // here decides what the manager answers.
    void stub(String name, Object? result) => commands.register(
      Command(
        name: name,
        description: name,
        handler: (_) async => CommandResult.ok(result),
      ),
    );

    test('exist only with Report location on, on a device with a '
        'receiver', () async {
      stub('getLocationSupport', {'supported': true});
      stub('getLocation', {'enabled': true, 'streaming': true});
      expect(ids(await surface.build()), isNot(containsAll(locationIds)));
      await settings.set(defs.locationEnabled, true);
      final catalog = await surface.build();
      expect(ids(catalog), containsAll(locationIds));
      // Six decimals, or a coordinate rounds to a whole degree; no state
      // class on the coordinates, a mean position being nothing.
      final lat = catalog.singleWhere((d) => d['objectId'] == 'gps_latitude');
      expect(lat['unit'], '°');
      expect(lat['accuracyDecimals'], 6);
      expect(lat['stateClass'], isNull);
      final speed = catalog.singleWhere((d) => d['objectId'] == 'speed');
      expect(speed['deviceClass'], 'speed');
      expect(speed['unit'], 'm/s');
      final stamp = catalog.singleWhere(
        (d) => d['objectId'] == 'last_location_fix',
      );
      expect(stamp['type'], 'text_sensor');
      expect(stamp['deviceClass'], 'timestamp');
    });

    test(
      'a device without a receiver lists none, switch or no switch',
      () async {
        stub('getLocationSupport', {'supported': false, 'hint': 'no GPS'});
        await settings.set(defs.locationEnabled, true);
        expect(ids(await surface.build()), isNot(containsAll(locationIds)));
      },
    );

    test('a fix lands on all six at once', () async {
      stub('getLocationSupport', {'supported': true});
      stub('getLocation', {'enabled': true, 'streaming': true});
      await settings.set(defs.locationEnabled, true);
      await surface.build();
      await attach();
      pushed.clear();
      bus.publish(
        LocationChanged(
          latitude: 45.5019,
          longitude: -73.5674,
          time: DateTime.fromMillisecondsSinceEpoch(1756500000000, isUtc: true),
          accuracy: 8.4,
          altitude: 31.2,
          speed: 0.5,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final byId = {for (final (id, value) in pushed) id: value};
      expect(byId['gps_latitude'], 45.5019);
      expect(byId['gps_longitude'], -73.5674);
      expect(byId['gps_accuracy'], 8);
      expect(byId['altitude'], 31);
      expect(byId['speed'], 0.5);
      expect(byId['last_location_fix'], '2025-08-29T20:40:00.000Z');
    });

    test(
      'the last fix the manager holds seeds the sensors at attach',
      () async {
        stub('getLocationSupport', {'supported': true});
        stub('getLocation', {'enabled': true, 'streaming': true, 'fix': fix});
        await settings.set(defs.locationEnabled, true);
        await surface.build();
        await attach();
        final byId = {for (final (id, value) in pushed) id: value};
        expect(byId['gps_latitude'], 45.5019);
        expect(byId['gps_longitude'], -73.5674);
        expect(byId['last_location_fix'], '2025-08-29T20:40:00.000Z');
      },
    );

    test('no fix yet leaves the sensors alone', () async {
      stub('getLocationSupport', {'supported': true});
      stub('getLocation', {'enabled': true, 'streaming': false});
      await settings.set(defs.locationEnabled, true);
      await surface.build();
      await attach();
      expect(pushed.map((p) => p.$1), isNot(contains('gps_latitude')));
    });
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
