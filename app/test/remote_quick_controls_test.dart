import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/camera/camera_manager.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/remote/remote_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The remote dashboard's quick controls are one tile each for the screen,
/// the screensaver and the camera view, relabelled by what the device is
/// doing. That needs two things from the device: a read command for each
/// state, and the states in the snapshot every admin client starts from
/// (/api/info at boot, the WebSocket `state` message at connect). The live
/// changes ride the event feed the JS API already has.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = null);

  test('isScreensaverActive follows the screensaver', () async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    final saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();

    expect(
      (await commands.execute('isScreensaverActive', const {})).data,
      isFalse,
    );
    await saver.start();
    expect(
      (await commands.execute('isScreensaverActive', const {})).data,
      isTrue,
    );
    await saver.stop();
    expect(
      (await commands.execute('isScreensaverActive', const {})).data,
      isFalse,
    );

    await saver.dispose();
    await log.dispose();
    await bus.dispose();
  });

  test(
    'getCameraViewState names the showing view and clears on hide',
    () async {
      SharedPreferences.setMockInitialValues({});
      final bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      final settings = SettingsManager(bus, commands, log);
      await settings.init();
      final cameras = CameraManager(
        bus,
        commands,
        log,
        settings,
        HomeAssistantManager(bus, commands, log, settings),
      );
      await cameras.init();

      final source = await commands.execute('cameraPutSource', {
        'name': 'Front door',
        'kind': 'whep',
        'whepUrl': 'https://camera.example/whep',
      });
      final cameraId = (source.data as Map)['id'];
      final view = await commands.execute('cameraPutView', {
        'name': 'Outside',
        'cameraIds': [cameraId],
      });
      final viewId = (view.data as Map)['id'];

      var state =
          (await commands.execute('getCameraViewState', const {})).data as Map;
      expect(state['active'], isFalse);
      expect(state['viewId'], isNull);

      await commands.execute('showCameraView', {'viewId': viewId});
      state =
          (await commands.execute('getCameraViewState', const {})).data as Map;
      expect(state['active'], isTrue);
      expect(state['viewId'], viewId);
      expect(state['viewName'], 'Outside');

      await commands.execute('hideCameraView', const {});
      state =
          (await commands.execute('getCameraViewState', const {})).data as Map;
      expect(state['active'], isFalse);

      await cameras.dispose();
      await log.dispose();
      await bus.dispose();
    },
  );

  group('remote snapshot', () {
    late EventBus bus;
    late CommandRegistry commands;
    late SettingsManager settings;
    late RemoteManager remote;
    late int port;

    void stub(String name, Object? result) => commands.register(
      Command(
        name: name,
        description: name,
        handler: (_) async => CommandResult.ok(result),
      ),
    );

    setUp(() async {
      final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      port = probe.port;
      await probe.close();
      SharedPreferences.setMockInitialValues({
        'ks.browser.start_url': 'http://ha.local:8123/lovelace/0',
        'ks.remote.enabled': true,
        'ks.remote.password': 'secret',
        'ks.remote.port': port,
      });
      bus = EventBus();
      final log = Logger();
      commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      stub('getDeviceInfo', {'name': 'Hall'});
      stub('getBrightness', 0.5);
      stub('isScreenOn', false);
      stub('isScreensaverActive', true);
      stub('getCameraViewState', {
        'active': true,
        'viewId': 'v1',
        'viewName': 'Outside',
        'focusedCameraId': null,
      });
      remote = RemoteManager(bus, commands, log, settings);
      await remote.init();
    });

    tearDown(() async {
      await settings.set(defs.remoteEnabled, false);
      await remote.dispose();
    });

    Future<String> login() async {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port/api/login'),
      );
      request.write(jsonEncode({'password': 'secret'}));
      final response = await request.close();
      final body = jsonDecode(await utf8.decodeStream(response)) as Map;
      return body['token'] as String;
    }

    void expectStates(Map device) {
      expect(device['screenOn'], isFalse);
      expect(device['screensaverActive'], isTrue);
      expect((device['cameraView'] as Map)['active'], isTrue);
      expect((device['cameraView'] as Map)['viewName'], 'Outside');
    }

    test(
      '/api/info carries the screen, screensaver and camera view states',
      () async {
        final token = await login();
        final client = HttpClient();
        final request = await client.getUrl(
          Uri.parse('http://127.0.0.1:$port/api/info'),
        );
        request.headers.set('authorization', 'Bearer $token');
        final response = await request.close();
        expect(response.statusCode, 200);
        expectStates(jsonDecode(await utf8.decodeStream(response)) as Map);
      },
    );

    test(
      'the WebSocket state snapshot carries them too, then the events',
      () async {
        final token = await login();
        final ws = await WebSocket.connect(
          'ws://127.0.0.1:$port/api/ws?token=$token',
        );
        final messages = <Map>[];
        final sub = ws.listen((raw) {
          messages.add(jsonDecode(raw as String) as Map);
        });
        ws.add(
          jsonEncode({
            'type': 'subscribe',
            'topics': ['state', 'events'],
          }),
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final snapshot = messages.firstWhere((m) => m['type'] == 'state');
        expectStates(snapshot['device'] as Map);

        // The diffs the dashboard applies after the snapshot: the same bus
        // events the JS API hears, with the camera view's payload attached.
        bus.publish(const ScreenStateChanged(on: true));
        bus.publish(const ScreensaverStateChanged(active: false));
        bus.publish(const CameraViewStateChanged(viewId: null, viewName: null));
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final events = messages.where((m) => m['type'] == 'event').toList();
        expect(
          events.map((e) => e['event']),
          containsAll(['screenon', 'screensaverstop', 'cameraview']),
        );
        final cameraView = events.firstWhere((e) => e['event'] == 'cameraview');
        expect((cameraView['data'] as Map)['active'], isFalse);

        await sub.cancel();
        await ws.close();
      },
    );
  });

  test('the admin page has one relabelled tile per state', () {
    final html = File('assets/remote-ui/index.html').readAsStringSync();
    for (final id in ['tileScreen', 'tileScreensaver', 'tileCameraView']) {
      expect(html, contains('id="$id"'), reason: id);
    }
    // Two tiles for one screen would be the pair this replaced.
    expect(html, isNot(contains('data-cmd="screenOn"')));
    final panels = File('assets/remote-ui/static/panels.js').readAsStringSync();
    for (final event in [
      'screenon',
      'screenoff',
      'screensaverstart',
      'screensaverstop',
      'cameraview',
    ]) {
      expect(panels, contains("'$event'"), reason: event);
    }
    for (final command in [
      'screenOn',
      'screenOff',
      'startScreensaver',
      'stopScreensaver',
      'hideCameraView',
      'showCameraView',
    ]) {
      expect(panels, contains("'$command'"), reason: command);
    }
  });
}
