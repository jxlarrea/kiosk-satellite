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
}

class _RealHttpOverrides extends HttpOverrides {}
