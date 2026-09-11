import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/camera/camera_manager.dart';
import 'package:kiosk_satellite/managers/camera/models.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const camera = CameraSource(id: 'door', name: 'Door', kind: 'ha');

  test('old configurations keep the global playback preference', () {
    final old = CameraSource.fromJson({
      'id': 'door',
      'name': 'Door',
      'kind': 'ha',
    });
    expect(old.preferredProtocol, 'auto');
    expect(old.playbackTransports(), ['webrtc', 'hls', 'mjpeg']);
    expect(old.playbackTransports(preferHls: true), ['hls', 'webrtc', 'mjpeg']);
    final invalid = CameraSource.fromJson({
      ...old.toJson(),
      'preferredProtocol': 'unsupported',
    });
    expect(invalid.preferredProtocol, 'auto');
  });

  test('explicit preferences lead with each fallback retained once', () {
    expect(camera.copyWith(preferredProtocol: 'mjpeg').playbackTransports(), [
      'mjpeg',
      'webrtc',
      'hls',
    ]);
    expect(
      camera
          .copyWith(preferredProtocol: 'mjpeg')
          .playbackTransports(preferHls: true),
      ['mjpeg', 'hls', 'webrtc'],
    );
    expect(
      camera
          .copyWith(preferredProtocol: 'webrtc')
          .playbackTransports(preferHls: true),
      ['webrtc', 'hls', 'mjpeg'],
    );
    expect(camera.copyWith(preferredProtocol: 'hls').playbackTransports(), [
      'hls',
      'webrtc',
      'mjpeg',
    ]);
  });

  test('a preference does not add protocols the camera cannot serve', () {
    expect(
      camera
          .copyWith(streamTypes: ['hls'], preferredProtocol: 'webrtc')
          .playbackTransports(),
      ['hls', 'mjpeg'],
    );
    expect(
      camera
          .copyWith(streamTypes: [], preferredProtocol: 'hls')
          .playbackTransports(),
      ['mjpeg'],
    );
    expect(
      camera
          .copyWith(streamTypes: ['web_rtc'], preferredProtocol: 'mjpeg')
          .playbackTransports(),
      ['mjpeg', 'webrtc'],
    );
  });

  test('Go2RTC and WHEP keep their existing playback rules', () {
    const go2rtc = CameraSource(
      id: 'g',
      name: 'G',
      kind: 'go2rtc',
      preferredProtocol: 'mjpeg',
    );
    const whep = CameraSource(
      id: 'w',
      name: 'W',
      kind: 'whep',
      preferredProtocol: 'hls',
    );
    expect(go2rtc.playbackTransports(), ['webrtc', 'mse']);
    expect(go2rtc.playbackTransports(preferMse: true), ['mse', 'webrtc']);
    expect(go2rtc.copyWith(missing: true).playbackTransports(preferMse: true), [
      'webrtc',
    ]);
    expect(whep.playbackTransports(preferHls: true), ['webrtc']);
    expect(go2rtc.toJson(), isNot(contains('preferredProtocol')));
    expect(whep.toJson(), isNot(contains('preferredProtocol')));
  });

  test(
    'preferences survive edits, reloads and Home Assistant imports',
    () async {
      SharedPreferences.setMockInitialValues({});
      final bus = EventBus();
      final logger = Logger();
      final commands = CommandRegistry(logger);
      final settings = SettingsManager(bus, commands, logger);
      await settings.init();
      final ha = _ProtocolHaManager(bus, commands, logger, settings);
      final cameras = CameraManager(bus, commands, logger, settings, ha);
      await cameras.init();
      addTearDown(cameras.dispose);

      expect(
        (await commands.execute('cameraImportHomeAssistant', {})).ok,
        isTrue,
      );
      final id = cameras.config.cameras.single.id;
      expect(
        (await commands.execute('cameraPutSource', {
          'id': id,
          'name': 'Front door',
          'preferredProtocol': 'mjpeg',
        })).ok,
        isTrue,
      );
      expect(cameras.config.cameras.single.preferredProtocol, 'mjpeg');
      expect(
        (await commands.execute('cameraPutSource', {
          'id': id,
          'name': 'Renamed door',
        })).ok,
        isTrue,
      );
      expect(
        (await commands.execute('cameraImportHomeAssistant', {})).ok,
        isTrue,
      );
      expect(cameras.config.cameras.single.preferredProtocol, 'mjpeg');
      expect(cameras.config.cameras.single.name, 'Renamed door');

      final reloaded = SettingsManager(bus, CommandRegistry(logger), logger);
      await reloaded.init();
      final restored = CameraManager(
        bus,
        CommandRegistry(logger),
        logger,
        reloaded,
        ha,
      );
      await restored.init();
      addTearDown(restored.dispose);
      expect(restored.config.cameras.single.preferredProtocol, 'mjpeg');
      expect(
        restored.config.cameras.single.playbackTransports().first,
        'mjpeg',
      );

      expect(
        (await commands.execute('cameraPutSource', {
          'id': id,
          'name': 'Door',
          'preferredProtocol': 'rtsp',
        })).ok,
        isFalse,
      );
      expect(cameras.config.cameras.single.preferredProtocol, 'mjpeg');
      expect(
        (await commands.execute('cameraPutSource', {
          'id': id,
          'name': 'Door',
          'preferredProtocol': 'auto',
        })).ok,
        isTrue,
      );
      expect(cameras.config.cameras.single.preferredProtocol, 'auto');
      expect(
        (await commands.execute('cameraPutSource', {
          'name': 'Side door',
          'kind': 'ha',
          'entityId': 'camera.side',
          'preferredProtocol': 'hls',
        })).ok,
        isTrue,
      );
      expect(cameras.config.cameras.last.preferredProtocol, 'hls');
      expect(
        (await commands.execute('cameraPutSource', {
          'id': id,
          'name': 'Door',
          'kind': 'whep',
          'whepUrl': 'https://camera.example/whep',
          'preferredProtocol': 'mjpeg',
        })).ok,
        isTrue,
      );
      expect(cameras.config.cameras.last.preferredProtocol, 'auto');
      expect(
        cameras.config.cameras.last.toJson(),
        isNot(contains('preferredProtocol')),
      );
    },
  );
}

class _ProtocolHaManager extends HomeAssistantManager {
  _ProtocolHaManager(super.bus, super.commands, super.log, super.settings);

  @override
  Future<List<({String entityId, String name, List<String> streamTypes})>?>
  listStreamableCameras() async => [
    (entityId: 'camera.door', name: 'Door', streamTypes: ['web_rtc', 'hls']),
  ];

  @override
  Future<List<String>?> cameraCapabilities(String entityId) async => [
    'web_rtc',
    'hls',
  ];
}
