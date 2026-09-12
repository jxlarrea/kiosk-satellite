import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/device/device_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';

class _Device extends DeviceManager {
  _Device(super.bus, super.commands, super.log, super.settings);

  @override
  String get deviceName => 'Hall panel';

  @override
  Future<Map<String, Object?>> stats() async => {'battery': null};

  @override
  Future<String?> ipAddress() async => null;

  @override
  Future<List<String>> ipv6Addresses() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('kiosk_satellite/device_details');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late EventBus bus;
  late CommandRegistry commands;
  late _Device device;

  setUp(() {
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    device = _Device(bus, commands, log, SettingsManager(bus, commands, log))
      ..model = 'Panel Maker Test'
      ..osVersion = 'Android 14'
      ..appVersion = '2026.9.41'
      ..packageName = 'me.jxl.kiosk_satellite'
      ..buildNumber = '240';
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    await bus.dispose();
  });

  test(
    'device snapshot uses native resources and current panel brightness',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'read') return <String, Object?>{};
        return {
          'ram': {'free': 2147483648, 'total': 4294967296},
          'storage': {'free': 17179869184, 'total': 34359738368},
          'screen': {'width': 1920, 'height': 1080, 'density': 1.5},
        };
      });
      commands.register(
        Command(
          name: 'getBrightness',
          description: 'test',
          handler: (params) async {
            expect(params, {'panel': true});
            return const CommandResult.ok(0.35);
          },
        ),
      );
      commands.register(
        Command(
          name: 'isScreenOn',
          description: 'test',
          handler: (params) async {
            expect(params, isEmpty);
            return const CommandResult.ok(false);
          },
        ),
      );
      final result = await device.info();
      expect(result['name'], 'Hall panel');
      expect(result['model'], 'Panel Maker Test');
      expect(result['ramFree'], 2147483648);
      expect(result['ramTotal'], 4294967296);
      expect(result['storageFree'], 17179869184);
      expect(result['storageTotal'], 34359738368);
      expect(result['screenWidth'], 1920);
      expect(result['screenHeight'], 1080);
      expect(result['screenDensity'], 1.5);
      expect(result['brightness'], 0.35);
      expect(result['screenOn'], false);
      expect(result['battery'], isNull);
      expect(result['ip'], isNull);
      expect(result['ipv6'], isEmpty);
    },
  );

  test(
    'unavailable resource and screen readers preserve device identity',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'unavailable');
      });
      final result = await device.info();
      expect(result['name'], 'Hall panel');
      expect(result['model'], 'Panel Maker Test');
      for (final key in [
        'ramFree',
        'ramTotal',
        'storageFree',
        'storageTotal',
        'screenWidth',
        'screenHeight',
        'screenDensity',
        'brightness',
        'screenOn',
      ]) {
        expect(result.containsKey(key), true, reason: key);
        expect(result[key], isNull, reason: key);
      }
    },
  );
}
