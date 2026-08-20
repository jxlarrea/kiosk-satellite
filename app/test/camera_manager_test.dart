import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/camera/camera_manager.dart';
import 'package:kiosk_satellite/managers/camera/models.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('camera configuration round trips credentials and ordered views', () {
    const config = CameraConfiguration(
      servers: [
        CameraServer(
          id: 'server',
          name: 'Local',
          baseUrl: 'https://go2rtc.example',
          username: 'user',
          password: 'secret',
        ),
      ],
      cameras: [
        CameraSource(
          id: 'camera',
          name: 'Front door',
          kind: 'go2rtc',
          serverId: 'server',
          streamName: 'front_sub',
          fullscreenStreamName: 'front_main',
        ),
      ],
      views: [
        CameraViewConfig(
          id: 'view',
          name: 'Outside',
          cameraIds: ['camera'],
          showCameraNames: false,
          grid: 6,
        ),
      ],
    );

    final decoded = CameraConfiguration.decode(config.encode());
    expect(decoded.servers.single.password, 'secret');
    expect(decoded.cameras.single.fullscreenStreamName, 'front_main');
    expect(decoded.views.single.cameraIds, ['camera']);
    expect(decoded.views.single.showCameraNames, isFalse);
    expect(decoded.views.single.grid, 6);
    expect(decoded.views.single.effectiveGrid, 6);
    expect(
      decoded.toJson(includePasswords: false)['servers'],
      contains(containsPair('passwordSet', true)),
    );
  });

  test(
    'ha camera sources round trip and validate their entity (#124)',
    () async {
      const source = CameraSource(
        id: 'x',
        name: 'Front door',
        kind: 'ha',
        entityId: 'camera.front_door',
        imported: true,
      );
      final decoded = CameraSource.fromJson(
        jsonDecode(jsonEncode(source.toJson())) as Map,
      );
      expect(decoded.kind, 'ha');
      expect(decoded.entityId, 'camera.front_door');
      expect(decoded.imported, isTrue);

      SharedPreferences.setMockInitialValues({});
      final bus = EventBus();
      final logger = Logger();
      final commands = CommandRegistry(logger);
      final settings = SettingsManager(bus, commands, logger);
      await settings.init();
      final cameras = CameraManager(
        bus,
        commands,
        logger,
        settings,
        HomeAssistantManager(bus, commands, logger, settings),
      );
      await cameras.init();

      // No entity, or one that is not a camera: refused with a clear error.
      final missing = await commands.execute('cameraPutSource', {
        'name': 'Doorbell',
        'kind': 'ha',
      });
      expect(missing.ok, isFalse);
      final wrong = await commands.execute('cameraPutSource', {
        'name': 'Doorbell',
        'kind': 'ha',
        'entityId': 'light.porch',
      });
      expect(wrong.ok, isFalse);

      final put = await commands.execute('cameraPutSource', {
        'name': 'Doorbell',
        'kind': 'ha',
        'entityId': 'camera.doorbell',
      });
      expect(put.ok, isTrue);
      expect((put.data as Map)['entityId'], 'camera.doorbell');
      expect(cameras.config.cameras.single.kind, 'ha');
    },
  );

  test('a view holds up to 12 cameras and no more', () async {
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final logger = Logger();
    final commands = CommandRegistry(logger);
    final settings = SettingsManager(bus, commands, logger);
    await settings.init();
    final cameras = CameraManager(
      bus,
      commands,
      logger,
      settings,
      HomeAssistantManager(bus, commands, logger, settings),
    );
    await cameras.init();

    final ids = <String>[];
    for (var index = 0; index < 13; index++) {
      final source = await commands.execute('cameraPutSource', {
        'name': 'Camera $index',
        'kind': 'whep',
        'whepUrl': 'https://cams.example/whep/$index',
      });
      expect(source.ok, isTrue);
      ids.add('${(source.data as Map)['id']}');
    }

    final full = await commands.execute('cameraPutView', {
      'name': 'Wall',
      'cameraIds': ids.sublist(0, 12),
    });
    expect(full.ok, isTrue);

    final overflow = await commands.execute('cameraPutView', {
      'name': 'Too many',
      'cameraIds': ids,
    });
    expect(overflow.ok, isFalse);
    expect(overflow.error, contains('1 to 12'));

    // A grid may leave slots empty but never squeeze the cameras.
    final roomy = await commands.execute('cameraPutView', {
      'name': 'Roomy',
      'cameraIds': ids.sublist(0, 3),
      'grid': 8,
    });
    expect(roomy.ok, isTrue);
    expect((roomy.data as Map)['grid'], 8);

    final tight = await commands.execute('cameraPutView', {
      'name': 'Tight',
      'cameraIds': ids.sublist(0, 5),
      'grid': 4,
    });
    expect(tight.ok, isFalse);

    final oversized = await commands.execute('cameraPutView', {
      'name': 'Oversized',
      'cameraIds': ids.sublist(0, 3),
      'grid': 13,
    });
    expect(oversized.ok, isFalse);
  });

  test(
    'commands create a view, mask passwords, and validate membership',
    () async {
      SharedPreferences.setMockInitialValues({});
      final bus = EventBus();
      final logger = Logger();
      final commands = CommandRegistry(logger);
      final settings = SettingsManager(bus, commands, logger);
      await settings.init();
      final cameras = CameraManager(
        bus,
        commands,
        logger,
        settings,
        HomeAssistantManager(bus, commands, logger, settings),
      );
      await cameras.init();

      final server = await commands.execute('cameraPutServer', {
        'name': 'Local',
        'baseUrl': 'https://go2rtc.example/',
        'username': 'user',
        'password': 'secret',
      });
      expect(server.ok, isTrue);
      final serverId = (server.data as Map)['id'];

      final source = await commands.execute('cameraPutSource', {
        'name': 'Front door',
        'kind': 'go2rtc',
        'serverId': serverId,
        'streamName': 'front',
      });
      expect(source.ok, isTrue);
      final cameraId = (source.data as Map)['id'];

      final view = await commands.execute('cameraPutView', {
        'name': 'Outside',
        'cameraIds': [cameraId],
        'showCameraNames': false,
      });
      expect(view.ok, isTrue);
      final viewId = (view.data as Map)['id'];

      final duplicate = await commands.execute('cameraPutView', {
        'name': 'outside',
        'cameraIds': [cameraId],
      });
      expect(duplicate.ok, isFalse);

      final shown = await commands.execute('showCameraView', {
        'viewId': viewId,
      });
      expect(shown.ok, isTrue);
      expect(cameras.activeViewId.value, viewId);
      expect(cameras.activeView?.showCameraNames, isFalse);

      // toggle (the gesture path): showing the already-active view closes
      // it, showing it again reopens it, and a plain show never closes.
      final toggled = await commands.execute('showCameraView', {
        'viewId': viewId,
        'toggle': true,
      });
      expect(toggled.ok, isTrue);
      expect(cameras.activeViewId.value, isNull);
      await commands
          .execute('showCameraView', {'viewId': viewId, 'toggle': true});
      expect(cameras.activeViewId.value, viewId);
      await commands.execute('showCameraView', {'viewId': viewId});
      expect(cameras.activeViewId.value, viewId);

      // Auto-dismiss: an open view closes on its own after the configured
      // time; 0 (the default) leaves it up. 1 s here to keep the test quick.
      await settings.set(defs.cameraAutoDismissSeconds, 1);
      await commands.execute('showCameraView', {'viewId': viewId});
      expect(cameras.activeViewId.value, viewId);
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      expect(cameras.activeViewId.value, isNull,
          reason: 'the view should have auto-dismissed');
      await settings.set(defs.cameraAutoDismissSeconds, 0);
      await commands.execute('showCameraView', {'viewId': viewId});
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(cameras.activeViewId.value, viewId,
          reason: 'off means a view stays up');
      expect(cameras.focusCamera('$cameraId').ok, isTrue);
      expect(cameras.focusCamera('unknown').ok, isFalse);

      final public = await commands.execute('cameraGetConfig', const {});
      final publicServer =
          ((public.data as Map)['servers'] as List).single as Map;
      expect(publicServer['password'], isNull);
      expect(publicServer['passwordSet'], isTrue);

      bus.publish(const VoiceInteractionChanged(active: true));
      await Future<void>.delayed(Duration.zero);
      expect(cameras.activeViewId.value, isNull);

      bus.publish(const VoiceInteractionChanged(active: false));
      await pumpEventQueue();
      expect(cameras.activeViewId.value, viewId);
      expect(cameras.focusedCameraId.value, cameraId);

      bus.publish(const VoiceInteractionChanged(active: true));
      await Future<void>.delayed(Duration.zero);
      cameras.hideView();
      bus.publish(const VoiceInteractionChanged(active: false));
      await pumpEventQueue();
      expect(cameras.activeViewId.value, isNull);

      await commands.execute('showCameraView', {'viewId': viewId});
      expect(cameras.focusCamera('$cameraId').ok, isTrue);
      cameras.interruptForVoice();
      expect(cameras.activeViewId.value, isNull);
      bus.publish(const VoiceInteractionChanged(active: false));
      await pumpEventQueue();
      expect(cameras.activeViewId.value, viewId);
      expect(cameras.focusedCameraId.value, cameraId);

      await cameras.dispose();
      await logger.dispose();
      await bus.dispose();
    },
  );

  test('camera views dismiss and suppress the screensaver', () async {
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final logger = Logger();
    final commands = CommandRegistry(logger);
    final settings = SettingsManager(bus, commands, logger);
    await settings.init();
    final cameras = CameraManager(
      bus,
      commands,
      logger,
      settings,
      HomeAssistantManager(bus, commands, logger, settings),
    );
    await cameras.init();
    final screensaver = ScreensaverManager(bus, commands, logger, settings);
    await screensaver.init();

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

    await screensaver.start();
    expect(screensaver.isActive, isTrue);

    final shown = await commands.execute('showCameraView', {'viewId': viewId});
    expect(shown.ok, isTrue);
    expect(cameras.activeViewId.value, viewId);
    expect(screensaver.isActive, isFalse);

    await pumpEventQueue();
    await screensaver.start();
    expect(screensaver.isActive, isFalse);

    cameras.hideView();
    await pumpEventQueue();
    await screensaver.start();
    expect(screensaver.isActive, isTrue);

    await screensaver.stop();
    await screensaver.dispose();
    await cameras.dispose();
    await logger.dispose();
    await bus.dispose();
  });

  test('Go2RTC import merges streams and marks missing imports', () async {
    var streams = ['front', 'garage'];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) {
      expect(request.uri.path, '/api/streams');
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({for (final stream in streams) stream: {}}))
        ..close();
    });

    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final logger = Logger();
    final commands = CommandRegistry(logger);
    final settings = SettingsManager(bus, commands, logger);
    await settings.init();
    final cameras = CameraManager(
      bus,
      commands,
      logger,
      settings,
      HomeAssistantManager(bus, commands, logger, settings),
    );
    await cameras.init();

    final addedServer = await commands.execute('cameraPutServer', {
      'name': 'Local',
      'baseUrl': 'http://127.0.0.1:${server.port}',
    });
    final serverId = (addedServer.data as Map)['id'];
    final realHttp = _RealHttpOverrides();
    final first = await HttpOverrides.runZoned(
      () => commands.execute('cameraImportGo2Rtc', {'serverId': serverId}),
      createHttpClient: realHttp.createHttpClient,
    );
    expect(first.ok, isTrue);
    expect(first.data, containsPair('added', 2));
    expect(cameras.config.cameras.map((camera) => camera.streamName), {
      'front',
      'garage',
    });

    streams = ['front', 'side'];
    final second = await HttpOverrides.runZoned(
      () => commands.execute('cameraImportGo2Rtc', {'serverId': serverId}),
      createHttpClient: realHttp.createHttpClient,
    );
    expect(second.ok, isTrue);
    expect(second.data, containsPair('added', 1));
    expect(second.data, containsPair('missing', 1));
    expect(
      cameras.config.cameras
          .singleWhere((camera) => camera.streamName == 'garage')
          .missing,
      isTrue,
    );

    await cameras.dispose();
    await logger.dispose();
    await bus.dispose();
  });

  test('the default view always exists and survives every delete', () async {
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final logger = Logger();
    final commands = CommandRegistry(logger);
    final settings = SettingsManager(bus, commands, logger);
    await settings.init();
    final cameras = CameraManager(
      bus,
      commands,
      logger,
      settings,
      HomeAssistantManager(bus, commands, logger, settings),
    );
    await cameras.init();

    // Present on a configuration that has never been touched.
    expect(cameras.config.defaultView, isNotNull);
    expect(cameras.config.defaultView!.cameraIds, isEmpty);
    expect(cameras.config.views.first.isDefault, isTrue);

    final source = await commands.execute('cameraPutSource', {
      'name': 'Front door',
      'kind': 'whep',
      'whepUrl': 'https://camera.example/whep',
    });
    final cameraId = (source.data as Map)['id'];

    // Empty is a valid state for the default, and only for the default.
    final emptied = await commands.execute('cameraPutView', {
      'id': CameraViewConfig.defaultId,
      'name': 'Default',
      'cameraIds': <String>[],
    });
    expect(emptied.ok, isTrue);
    final other = await commands.execute('cameraPutView', {
      'name': 'Outside',
      'cameraIds': <String>[],
    });
    expect(other.ok, isFalse);

    // An empty view has nothing to show.
    expect(
      (await commands.execute('showCameraView', {
        'viewId': CameraViewConfig.defaultId,
      })).ok,
      isFalse,
    );

    final filled = await commands.execute('cameraPutView', {
      'id': CameraViewConfig.defaultId,
      'name': 'Default',
      'cameraIds': [cameraId],
    });
    expect(filled.ok, isTrue);

    expect(
      (await commands.execute('cameraDeleteView', {
        'id': CameraViewConfig.defaultId,
      })).ok,
      isFalse,
    );

    // Deleting its last camera empties it rather than taking it with them.
    expect(
      (await commands.execute('cameraDeleteSource', {'id': cameraId})).ok,
      isTrue,
    );
    expect(cameras.config.defaultView, isNotNull);
    expect(cameras.config.defaultView!.cameraIds, isEmpty);

    await cameras.dispose();
    await logger.dispose();
    await bus.dispose();
  });

  test('the MSE relay pipes the Go2RTC socket with the server login, both '
      'directions (issue #160)', () async {
    HttpOverrides.global = _RealHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    // A fake Go2RTC: records the Authorization header and the stream asked
    // for, answers the MSE handshake, then sends one binary segment.
    String? sawAuth;
    String? sawSrc;
    final go2rtc = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => go2rtc.close(force: true));
    go2rtc.listen((request) async {
      sawAuth = request.headers.value(HttpHeaders.authorizationHeader);
      sawSrc = request.uri.queryParameters['src'];
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((message) {
        if (message is! String) return;
        socket.add(jsonEncode({
          'type': 'mse',
          'value': 'video/mp4; codecs="avc1.64001f"',
        }));
        socket.add(<int>[1, 2, 3, 4]);
      });
    });

    final config = CameraConfiguration(
      servers: [
        CameraServer(
          id: 'server',
          name: 'Local',
          baseUrl: 'http://127.0.0.1:${go2rtc.port}',
          username: 'user',
          password: 'secret',
        ),
      ],
      cameras: const [
        CameraSource(
          id: 'cam',
          name: 'Front',
          kind: 'go2rtc',
          serverId: 'server',
          streamName: 'front_sub',
          fullscreenStreamName: 'front_main',
        ),
        CameraSource(id: 'door', name: 'Door', kind: 'ha',
            entityId: 'camera.door', imported: true),
      ],
    );
    SharedPreferences.setMockInitialValues({
      'ks.camera.config': config.encode(),
    });
    final bus = EventBus();
    final logger = Logger();
    final commands = CommandRegistry(logger);
    final settings = SettingsManager(bus, commands, logger);
    await settings.init();
    final cameras = CameraManager(
      bus,
      commands,
      logger,
      settings,
      HomeAssistantManager(bus, commands, logger, settings),
    );
    await cameras.init();
    addTearDown(cameras.dispose);

    // WebRTC-only kinds have no MSE endpoint to hand out.
    final refused = await cameras.mseEndpoint(cameraId: 'door', fullscreen: false);
    expect(refused['ok'], isFalse);

    final endpoint = await cameras.mseEndpoint(cameraId: 'cam', fullscreen: false);
    expect(endpoint['ok'], isTrue, reason: '${endpoint['error']}');
    final url = '${endpoint['url']}';
    expect(url, startsWith('ws://127.0.0.1:'));

    final client = await WebSocket.connect(url);
    client.add(jsonEncode({'type': 'mse', 'value': 'avc1.640029'}));
    final received = <Object?>[];
    await for (final message in client.timeout(const Duration(seconds: 5))) {
      received.add(message);
      if (received.length == 2) break;
    }
    expect(sawAuth, 'Basic ${base64Encode(utf8.encode('user:secret'))}',
        reason: 'the relay must carry the server login the page cannot');
    expect(sawSrc, 'front_sub');
    expect(received.first, contains('avc1.64001f'));
    expect(received.last, [1, 2, 3, 4]);
    await client.close();

    // A token is single use: replaying the same url is refused.
    await expectLater(WebSocket.connect(url), throwsA(anything));

    // Fullscreen rides the fullscreen stream, exactly like WebRTC signaling.
    final full = await cameras.mseEndpoint(cameraId: 'cam', fullscreen: true);
    final fullSocket = await WebSocket.connect('${full['url']}');
    fullSocket.add('{"type":"mse"}');
    await fullSocket.timeout(const Duration(seconds: 5)).first;
    expect(sawSrc, 'front_main');
    await fullSocket.close();
  });

  test('ha camera stream types round trip', () {
    const source = CameraSource(
      id: 'x',
      name: 'Door',
      kind: 'ha',
      entityId: 'camera.door',
      streamTypes: ['web_rtc', 'hls'],
    );
    final decoded = CameraSource.fromJson(
      jsonDecode(jsonEncode(source.toJson())) as Map,
    );
    expect(decoded.streamTypes, ['web_rtc', 'hls']);
    // Absent stays null (unknown), which is not the same as empty.
    const bare = CameraSource(id: 'y', name: 'Y', kind: 'ha');
    expect(
      CameraSource.fromJson(
        jsonDecode(jsonEncode(bare.toJson())) as Map,
      ).streamTypes,
      isNull,
    );
  });

  test('HLS playlist rewriting proxies every URI, relative and absolute', () {
    final upstream = Uri.parse('https://ha.example/api/hls/tok/playlist.m3u8');
    const body =
        '#EXTM3U\n'
        '#EXT-X-MAP:URI="init.mp4"\n'
        '#EXTINF:2.000,\n'
        'segment/1.m4s\n'
        '#EXTINF:2.000,\n'
        '/api/hls/tok/segment/2.m4s\n';
    final out = CameraManager.rewriteHlsPlaylist(body, upstream);
    expect(
      out,
      contains(
        'URI="r?u=https%3A%2F%2Fha.example%2Fapi%2Fhls%2Ftok%2Finit.mp4"',
      ),
    );
    expect(
      out,
      contains('r?u=https%3A%2F%2Fha.example%2Fapi%2Fhls%2Ftok'
          '%2Fsegment%2F1.m4s'),
    );
    expect(
      out,
      contains('r?u=https%3A%2F%2Fha.example%2Fapi%2Fhls%2Ftok'
          '%2Fsegment%2F2.m4s'),
    );
    // Every URI line goes through the relay; none reaches upstream direct.
    for (final line in out.split('\n')) {
      if (line.isEmpty || line.startsWith('#')) continue;
      expect(line, startsWith('r?u='));
    }
    expect(out, endsWith('\n'));
  });

  test('the HA import records and refreshes stream types', () async {
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final logger = Logger();
    final commands = CommandRegistry(logger);
    final settings = SettingsManager(bus, commands, logger);
    await settings.init();
    final ha = _FakeHaManager(bus, commands, logger, settings);
    final cameras = CameraManager(bus, commands, logger, settings, ha);
    await cameras.init();
    addTearDown(cameras.dispose);

    ha.streamable = [
      (entityId: 'camera.door', name: 'Door', streamTypes: ['hls']),
    ];
    var result = await commands.execute('cameraImportHomeAssistant', {});
    expect(result.ok, isTrue);
    expect(cameras.config.cameras.single.streamTypes, ['hls']);

    // The entity grew a WebRTC provider: a re-import refreshes the types.
    ha.streamable = [
      (
        entityId: 'camera.door',
        name: 'Door',
        streamTypes: ['web_rtc', 'hls'],
      ),
    ];
    result = await commands.execute('cameraImportHomeAssistant', {});
    expect(result.ok, isTrue);
    expect(cameras.config.cameras.single.streamTypes, ['web_rtc', 'hls']);

    // Gone entirely: marked missing, last known types retained.
    ha.streamable = [];
    result = await commands.execute('cameraImportHomeAssistant', {});
    expect(result.ok, isTrue);
    expect(cameras.config.cameras.single.missing, isTrue);
    expect(cameras.config.cameras.single.streamTypes, ['web_rtc', 'hls']);

    // A stills-only entity (no stream types at all) is still imported:
    // MJPEG over the camera proxy is its transport.
    ha.streamable = [
      (entityId: 'camera.door', name: 'Door', streamTypes: ['web_rtc']),
      (entityId: 'camera.package', name: 'Package', streamTypes: <String>[]),
    ];
    result = await commands.execute('cameraImportHomeAssistant', {});
    expect(result.ok, isTrue);
    final package = cameras.config.cameras
        .firstWhere((camera) => camera.entityId == 'camera.package');
    expect(package.streamTypes, isEmpty);
  });

  test('a hand-added ha camera asks Home Assistant for its stream types',
      () async {
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final logger = Logger();
    final commands = CommandRegistry(logger);
    final settings = SettingsManager(bus, commands, logger);
    await settings.init();
    final ha = _FakeHaManager(bus, commands, logger, settings)
      ..capabilities = <String>[];
    final cameras = CameraManager(bus, commands, logger, settings, ha);
    await cameras.init();
    addTearDown(cameras.dispose);

    // A stills-only entity records its (empty) types at save time, so the
    // player goes straight to MJPEG instead of laddering through
    // transports the entity does not have.
    final put = await commands.execute('cameraPutSource', {
      'name': 'Package',
      'kind': 'ha',
      'entityId': 'camera.package',
    });
    expect(put.ok, isTrue);
    expect(cameras.config.cameras.single.streamTypes, isEmpty);

    // A rename keeps the known types rather than asking again.
    ha.capabilities = ['web_rtc'];
    final rename = await commands.execute('cameraPutSource', {
      'id': cameras.config.cameras.single.id,
      'name': 'Package Camera',
      'kind': 'ha',
      'entityId': 'camera.package',
    });
    expect(rename.ok, isTrue);
    expect(cameras.config.cameras.single.name, 'Package Camera');
    expect(cameras.config.cameras.single.streamTypes, isEmpty);

    // Home Assistant unreachable at save time: unknown, not incapable.
    ha.capabilities = null;
    final blind = await commands.execute('cameraPutSource', {
      'name': 'Blind',
      'kind': 'ha',
      'entityId': 'camera.blind',
    });
    expect(blind.ok, isTrue);
    expect(
      cameras.config.cameras
          .firstWhere((camera) => camera.entityId == 'camera.blind')
          .streamTypes,
      isNull,
    );
  });

  test('the MJPEG relay streams the camera proxy with the bearer token, '
      'single use', () async {
    HttpOverrides.global = _RealHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    // A fake Home Assistant camera proxy: records the Authorization
    // header, answers a short multipart stream.
    String? sawAuth;
    final haServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => haServer.close(force: true));
    haServer.listen((request) async {
      sawAuth = request.headers.value(HttpHeaders.authorizationHeader);
      final response = request.response;
      if (request.uri.path == '/api/camera_proxy_stream/camera.package') {
        response.headers.contentType =
            ContentType.parse('multipart/x-mixed-replace; boundary=frame');
        response.add(const [1, 2, 3, 4, 5]);
      } else {
        response.statusCode = HttpStatus.notFound;
      }
      await response.close();
    });

    const config = CameraConfiguration(
      cameras: [
        CameraSource(
          id: 'package',
          name: 'Package',
          kind: 'ha',
          entityId: 'camera.package',
          streamTypes: [],
        ),
        CameraSource(
          id: 'street',
          name: 'Street',
          kind: 'whep',
          whepUrl: 'https://example.net/whep',
        ),
      ],
    );
    SharedPreferences.setMockInitialValues({
      'ks.camera.config': config.encode(),
    });
    final bus = EventBus();
    final logger = Logger();
    final commands = CommandRegistry(logger);
    final settings = SettingsManager(bus, commands, logger);
    await settings.init();
    final ha = _FakeHaManager(bus, commands, logger, settings)
      ..mjpegTarget = (
        uri: Uri.parse(
          'http://127.0.0.1:${haServer.port}'
          '/api/camera_proxy_stream/camera.package',
        ),
        token: 'secret-token',
      );
    final cameras = CameraManager(bus, commands, logger, settings, ha);
    await cameras.init();
    addTearDown(cameras.dispose);

    // Only ha cameras have an MJPEG endpoint to hand out.
    final refused = await cameras.mjpegEndpoint(cameraId: 'street');
    expect(refused['ok'], isFalse);

    final endpoint = await cameras.mjpegEndpoint(cameraId: 'package');
    expect(endpoint['ok'], isTrue, reason: '${endpoint['error']}');
    final url = Uri.parse('${endpoint['url']}');

    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final response = await (await client.getUrl(url)).close();
    expect(response.statusCode, HttpStatus.ok);
    expect(
      response.headers.contentType?.mimeType,
      'multipart/x-mixed-replace',
    );
    expect(response.headers.contentType?.parameters['boundary'], 'frame');
    final bytes = await response.fold<List<int>>(
      [],
      (all, chunk) => all..addAll(chunk),
    );
    expect(bytes, const [1, 2, 3, 4, 5]);
    expect(sawAuth, 'Bearer secret-token',
        reason: 'the relay must carry the login the page img cannot');

    // A token is single use: replaying the same url is refused.
    final replay = await (await client.getUrl(url)).close();
    expect(replay.statusCode, HttpStatus.notFound);
    await replay.drain<void>();
  });

  test('the HLS relay proxies playlists and segments with CORS, pinned to '
      'the stream origin', () async {
    HttpOverrides.global = _RealHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    // A fake Home Assistant HLS endpoint: master playlist referencing the
    // variant by absolute path, variant referencing its init section and
    // segment relatively, one binary "segment".
    final haServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => haServer.close(force: true));
    final mpegUrl = ContentType.parse('application/vnd.apple.mpegurl');
    haServer.listen((request) async {
      final response = request.response;
      switch (request.uri.path) {
        case '/api/hls/tok/master_playlist.m3u8':
          response.headers.contentType = mpegUrl;
          response.write(
            '#EXTM3U\n'
            '#EXT-X-STREAM-INF:BANDWIDTH=100\n'
            '/api/hls/tok/playlist.m3u8\n',
          );
        case '/api/hls/tok/playlist.m3u8':
          response.headers.contentType = mpegUrl;
          response.write(
            '#EXTM3U\n'
            '#EXT-X-MAP:URI="init.mp4"\n'
            '#EXTINF:2.000,\n'
            'segment/1.m4s\n',
          );
        case '/api/hls/tok/init.mp4':
          response.add(const [1, 2, 3, 4]);
        default:
          response.statusCode = HttpStatus.notFound;
      }
      await response.close();
    });

    const config = CameraConfiguration(
      cameras: [
        CameraSource(
          id: 'door',
          name: 'Door',
          kind: 'ha',
          entityId: 'camera.door',
          streamTypes: ['hls'],
        ),
        CameraSource(
          id: 'street',
          name: 'Street',
          kind: 'whep',
          whepUrl: 'https://example.net/whep',
        ),
      ],
    );
    SharedPreferences.setMockInitialValues({
      'ks.camera.config': config.encode(),
    });
    final bus = EventBus();
    final logger = Logger();
    final commands = CommandRegistry(logger);
    final settings = SettingsManager(bus, commands, logger);
    await settings.init();
    final ha = _FakeHaManager(bus, commands, logger, settings)
      ..streamUrl =
          'http://127.0.0.1:${haServer.port}/api/hls/tok/master_playlist.m3u8';
    final cameras = CameraManager(bus, commands, logger, settings, ha);
    await cameras.init();
    addTearDown(cameras.dispose);

    // Only ha cameras have an HLS endpoint to hand out.
    final refused = await cameras.hlsEndpoint(cameraId: 'street');
    expect(refused['ok'], isFalse);

    final endpoint = await cameras.hlsEndpoint(cameraId: 'door');
    expect(endpoint['ok'], isTrue, reason: '${endpoint['error']}');
    final entry = Uri.parse('${endpoint['url']}');
    expect('$entry', startsWith('http://127.0.0.1:'));

    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    Future<(HttpClientResponse, String)> fetch(Uri uri) async {
      final response = await (await client.getUrl(uri)).close();
      final body = await utf8.decoder.bind(response).join();
      return (response, body);
    }

    final (masterResponse, master) = await fetch(entry);
    expect(masterResponse.statusCode, HttpStatus.ok);
    expect(
      masterResponse.headers.value('access-control-allow-origin'),
      '*',
      reason: 'the page is a file:// origin; without CORS nothing plays',
    );
    final variantRef = master
        .split('\n')
        .firstWhere((line) => line.isNotEmpty && !line.startsWith('#'));
    expect(variantRef, startsWith('r?u='));

    final (_, variant) = await fetch(entry.resolve(variantRef));
    final initRef = RegExp(r'URI="([^"]+)"').firstMatch(variant)![1]!;
    expect(initRef, startsWith('r?u='));

    final initResponse =
        await (await client.getUrl(entry.resolve(initRef))).close();
    final bytes = await initResponse.fold<List<int>>(
      [],
      (all, chunk) => all..addAll(chunk),
    );
    expect(bytes, const [1, 2, 3, 4]);
    expect(initResponse.headers.value('access-control-allow-origin'), '*');

    // The relay is not an open proxy: another origin is refused.
    final foreign = entry.replace(
      queryParameters: {'u': 'http://127.0.0.1:1/etc/passwd'},
    );
    final foreignResponse = await (await client.getUrl(foreign)).close();
    expect(foreignResponse.statusCode, HttpStatus.notFound);
    await foreignResponse.drain<void>();
  });
}

class _RealHttpOverrides extends HttpOverrides {}

class _FakeHaManager extends HomeAssistantManager {
  _FakeHaManager(super.bus, super.commands, super.log, super.settings);

  String? streamUrl;
  List<({String entityId, String name, List<String> streamTypes})>? streamable;
  List<String>? capabilities;
  ({Uri uri, String token})? mjpegTarget;

  @override
  Future<String?> cameraStreamUrl(String entityId) async => streamUrl;

  @override
  Future<List<({String entityId, String name, List<String> streamTypes})>?>
  listStreamableCameras() async => streamable;

  @override
  Future<List<String>?> cameraCapabilities(String entityId) async =>
      capabilities;

  @override
  ({Uri uri, String token})? cameraMjpegTarget(String entityId) => mjpegTarget;
}
