import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/bt_proxy_manager.dart';
import 'package:kiosk_satellite/managers/dlna/dlna_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TrackedSettings extends SettingsManager {
  _TrackedSettings(super.bus, super.commands, super.log);

  final secretsRead = <String>[];
  var ouiReads = 0;

  @override
  String internal(String key) {
    if (key == 'btproxy_oui_cache') ouiReads++;
    return super.internal(key);
  }

  @override
  Future<String> secret(String key, String Function() orElse) {
    secretsRead.add(key);
    return super.secret(key, orElse);
  }
}

Future<void> _until(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(ready(), isTrue, reason: 'the service transition should finish');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('kiosk_satellite/bluetooth_proxy');
  late EventBus bus;
  late Logger log;
  late CommandRegistry commands;
  late _TrackedSettings settings;
  var versionReads = 0;

  Future<void> configure([Map<String, Object> extra = const {}]) async {
    SharedPreferences.setMockInitialValues({
      'ks.dlna.enabled': false,
      'ks.esphome.enabled': false,
      'ks.esphome.entities': false,
      'ks.btproxy.enabled': true,
      'ks.btproxy.key': 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=',
      ...extra,
    });
    bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    settings = _TrackedSettings(bus, commands, log);
    await settings.init();
    versionReads = 0;
    commands.register(
      Command(
        name: 'getDeviceInfo',
        description: 'Test device identity',
        handler: (_) async {
          versionReads++;
          return const CommandResult.ok({'appVersion': '2026.9.42'});
        },
      ),
    );
  }

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    await settings.dispose();
    await bus.dispose();
    await log.dispose();
  });

  test(
    'disabled services register commands without loading prerequisites',
    () async {
      await configure();
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      final dlna = DlnaManager(bus, commands, log, settings);
      final proxy = BtProxyManager(bus, commands, log, settings);
      try {
        await dlna.init();
        await proxy.init();
        expect(versionReads, 0);
        expect(settings.secretsRead, isEmpty);
        expect(settings.ouiReads, 0);
        expect(calls, isEmpty);
        final status = await commands.execute('dlnaStatus', {});
        expect((status.data as Map)['running'], false);
        expect(
          commands.all.map((command) => command.name),
          containsAll(['esphomeStatus', 'btProxyNearby', 'getBleSupport']),
        );
      } finally {
        await proxy.dispose();
        await dlna.dispose();
      }
    },
  );

  test(
    'nearby devices load the saved vendor cache while ESPHome is off',
    () async {
      await configure({
        'ks.internal.btproxy_oui_cache': '{"5C:E7:53":"Saved vendor"}',
      });
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'nearby') {
          return [
            {'address': '5C:E7:53:E7:A1:6B', 'addressType': 0, 'rssi': -60},
          ];
        }
        return null;
      });
      final proxy = BtProxyManager(bus, commands, log, settings);
      try {
        await proxy.init();
        expect(settings.ouiReads, 0);
        for (var i = 0; i < 2; i++) {
          final devices = await proxy.refreshNearby();
          expect(devices.single.vendor, 'Saved vendor');
        }
        expect(settings.ouiReads, 1);
        expect(versionReads, 0);
      } finally {
        await proxy.dispose();
      }
    },
  );

  for (final supported in [true, false]) {
    test(
      'later ESPHome startup checks BLE support ($supported) before starting',
      () async {
        await configure();
        final calls = <MethodCall>[];
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'bleSupport') return {'supported': supported};
          if (call.method == 'start') return 'kiosk-satellite-test';
          return null;
        });
        final proxy = BtProxyManager(bus, commands, log, settings);
        List<MethodCall> starts() =>
            calls.where((call) => call.method == 'start').toList();
        try {
          await proxy.init();
          await settings.set(defs.esphomeEnabled, true);
          await _until(() => starts().isNotEmpty);
          expect(calls.first.method, 'bleSupport');
          expect(
            (starts().first.arguments as Map)['bluetoothProxy'],
            supported,
          );
          expect(
            (starts().first.arguments as Map)['projectVersion'],
            '2026.9.42',
          );
          expect(settings.get(defs.btproxyEnabled), supported);
          expect(versionReads, 1);

          await settings.set(defs.esphomeEnabled, false);
          await _until(() => calls.any((call) => call.method == 'stop'));
          final previousStarts = starts().length;
          await settings.set(defs.esphomeEnabled, true);
          await _until(() => starts().length > previousStarts);
          expect(versionReads, 1);
          expect(
            calls.where((call) => call.method == 'bleSupport'),
            hasLength(1),
          );
          expect((starts().last.arguments as Map)['bluetoothProxy'], supported);
        } finally {
          await proxy.dispose();
        }
      },
    );
  }

  for (final existingUuid in [null, 'saved-renderer-uuid']) {
    test('later DLNA startup retains its identity ($existingUuid)', () async {
      // Exercise identity loading and retry without advertising a renderer
      // on the test runner's network.
      await IOOverrides.runZoned(
        () async {
          await configure({
            'ks.secret.dlna_uuid': ?existingUuid,
          });
          final dlna = DlnaManager(bus, commands, log, settings);
          int failures() => log.recent
              .where(
                (entry) => entry.tag == 'dlna' && entry.level == LogLevel.error,
              )
              .length;
          try {
            await dlna.init();
            expect(settings.secretsRead, isEmpty);
            await settings.set(defs.dlnaEnabled, true);
            await _until(() => failures() == 1);
            final prefs = await SharedPreferences.getInstance();
            final uuid = prefs.getString('ks.secret.dlna_uuid');
            expect(uuid, isNotEmpty);
            if (existingUuid != null) expect(uuid, existingUuid);
            expect(settings.secretsRead, ['dlna_uuid']);
            expect(versionReads, 1);

            await settings.set(defs.deviceName, 'Retry renderer startup');
            await _until(() => failures() == 2);
            expect(prefs.getString('ks.secret.dlna_uuid'), uuid);
            expect(settings.secretsRead, ['dlna_uuid']);
            expect(versionReads, 1);
          } finally {
            await dlna.dispose();
          }
        },
        serverSocketBind:
            (
              address,
              port, {
              backlog = 0,
              v6Only = false,
              shared = false,
            }) async =>
                throw const SocketException('No listener during this test'),
      );
    });
  }
}
