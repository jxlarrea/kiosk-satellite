import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/service/service_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Kiosk Satellite Service's Dart side: the reasons it reports for
/// keeping the process alive, computed from the settings, and the grants
/// those reasons call for. The native service is not reachable here; the
/// manager must come up regardless and keep answering.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsManager settings;
  late ServiceManager service;
  late CommandRegistry commands;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    service = ServiceManager(bus, commands, log, settings);
    await service.init();
  }

  List<String> ids() => [for (final r in service.reasons) r.id];

  test(
    'a clean install is kept alive for the Home Assistant connection',
    () async {
      await build();
      expect(ids(), ['sessions']);
      // The service is what the page says it is: the base reason is always
      // first and always present, whatever else is on.
      expect(service.reasons.first.title, 'Home Assistant connection');
    },
  );

  test('every feature that needs the process adds its reason', () async {
    await build();
    await settings.set(defs.wakeWordEnabled, true);
    await settings.set(defs.wakeWordBackground, true);
    await settings.set(defs.esphomeEnabled, true);
    await settings.set(defs.btproxyEnabled, true);
    await settings.set(defs.esphomeEntities, true);
    await settings.set(defs.locationEnabled, true);
    await settings.set(defs.cameraEnabled, true);
    await settings.set(defs.remoteEnabled, true);
    await settings.set(defs.kioskEnabled, true);
    // The bus delivers asynchronously; the last set's sync has to land.
    await Future<void>.delayed(Duration.zero);
    expect(ids(), [
      'sessions',
      'listening',
      'esphome',
      'bluetooth',
      'location',
      'camera',
      'remote',
      'kiosk',
    ]);
  });

  test('background listening counts as soon as its switch is on', () async {
    await build();
    // Detection itself is always on (the retired master switch is forced
    // true), so the background switch alone is the reason.
    expect(ids(), isNot(contains('listening')));
    await settings.set(defs.wakeWordBackground, true);
    await Future<void>.delayed(Duration.zero);
    expect(ids(), contains('listening'));
    await settings.set(defs.wakeWordBackground, false);
    await Future<void>.delayed(Duration.zero);
    expect(ids(), isNot(contains('listening')));
  });

  test('the Bluetooth proxy counts only under the ESPHome server', () async {
    await build();
    await settings.set(defs.btproxyEnabled, true);
    await Future<void>.delayed(Duration.zero);
    expect(ids(), isNot(contains('bluetooth')));
    await settings.set(defs.esphomeEnabled, true);
    await Future<void>.delayed(Duration.zero);
    expect(ids(), containsAll(['esphome', 'bluetooth']));
  });

  test('lockdown alone is a kiosk reason', () async {
    await build();
    await settings.set(defs.lockdownEnabled, true);
    await Future<void>.delayed(Duration.zero);
    expect(ids(), contains('kiosk'));
  });

  test('the grants follow the reasons', () async {
    await build();
    // Auto-reload is on by default, so the relaunch after a crash already
    // needs the overlay grant; the battery exemption and the notification
    // are needed regardless.
    var grants = service.neededGrants();
    expect(grants['batteryUnrestricted'], isTrue);
    expect(grants['notification'], isTrue);
    expect(grants['displayOverOtherApps'], isTrue);
    expect(grants['microphone'], isFalse);
    expect(grants['camera'], isFalse);
    expect(grants['bluetooth'], isFalse);

    await settings.set(defs.autoReloadOnError, false);
    await Future<void>.delayed(Duration.zero);
    expect(service.neededGrants()['displayOverOtherApps'], isFalse);
    await settings.set(defs.kioskEnabled, true);
    await Future<void>.delayed(Duration.zero);
    expect(service.neededGrants()['displayOverOtherApps'], isTrue);

    await settings.set(defs.wakeWordEnabled, true);
    await settings.set(defs.wakeWordBackground, true);
    await settings.set(defs.cameraEnabled, true);
    await settings.set(defs.esphomeEnabled, true);
    await settings.set(defs.btproxyEnabled, true);
    await Future<void>.delayed(Duration.zero);
    grants = service.neededGrants();
    expect(grants['microphone'], isTrue);
    expect(grants['camera'], isTrue);
    expect(grants['bluetooth'], isTrue);
  });

  test('the status command answers without a native service', () async {
    await build();
    final result = await commands.execute('getServiceStatus', const {});
    expect(result.ok, isTrue);
    final data = result.data as Map;
    expect(data['running'], isFalse);
    expect(data['cpuAwake'], isTrue);
    expect((data['reasons'] as List).first, {
      'id': 'sessions',
      'title': 'Home Assistant connection',
      'detail':
          'Keeps the dashboard session and its websocket open while the '
          'screen is off.',
    });
    expect((data['grants'] as Map)['batteryUnrestricted'], isTrue);
  });

  test('the wake lock setting rides with the reasons', () async {
    await build();
    await settings.set(defs.serviceCpuAwake, false);
    await Future<void>.delayed(Duration.zero);
    final result = await commands.execute('getServiceStatus', const {});
    expect((result.data as Map)['cpuAwake'], isFalse);
  });

  test('the setting lives on the Device page, on the service page', () {
    expect(defs.serviceCpuAwake.category, 'Device');
    expect(defs.serviceCpuAwake.subpage, 'Kiosk Satellite Service');
    expect(defs.subpageHints.containsKey('Kiosk Satellite Service'), isTrue);
    // First of the Device page's entry rows: it sits ahead of Remote
    // Administration in the display order.
    final order = defs.allSettings.map((d) => d.key).toList();
    expect(
      order.indexOf('service.cpu_awake'),
      lessThan(order.indexOf('remote.enabled')),
    );
  });
}
