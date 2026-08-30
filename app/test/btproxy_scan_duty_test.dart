import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/bt_proxy_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Bluetooth proxy's Scan intensity. The scanner's duty cycle rides
/// the server start, and a later change reaches the running scanner over
/// its own channel call: a scan session restart is milliseconds, a server
/// restart drops Home Assistant's session, so the setting must never take
/// the restart path the other proxy keys do.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> sent;

  Future<(SettingsManager, BtProxyManager)> boot() async {
    sent = [];
    SharedPreferences.setMockInitialValues({
      'ks.esphome.enabled': true,
      'ks.btproxy.enabled': true,
      'ks.btproxy.key': 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=',
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/bluetooth_proxy'),
          (call) async {
            sent.add(call);
            if (call.method == 'bleSupport') return {'supported': true};
            if (call.method == 'start') return 'kiosk-satellite-ad603b';
            return null;
          },
        );
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    final proxy = BtProxyManager(bus, commands, log, settings);
    addTearDown(proxy.dispose);
    await proxy.init();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return (settings, proxy);
  }

  Iterable<MethodCall> starts() => sent.where((c) => c.method == 'start');

  test('the server start carries the stored scan intensity', () async {
    await boot();
    expect(starts(), hasLength(1));
    expect(
      (starts().single.arguments as Map)['scanDuty'],
      defs.btproxyScanDuty.defaultValue,
    );
  });

  test(
    'a change reaches the running scanner without a server restart',
    () async {
      final (settings, _) = await boot();
      await settings.set(defs.btproxyScanDuty, 'low_latency');
      // Longer than the manager's restart debounce, so a restart that was
      // wrongly scheduled would have shown up as a second start.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(starts(), hasLength(1));
      final pushes = sent.where((c) => c.method == 'scanDuty');
      expect(pushes, hasLength(1));
      expect((pushes.single.arguments as Map)['duty'], 'low_latency');
    },
  );

  test('the definition offers the three Android scan modes', () {
    expect(defs.btproxyScanDuty.options, [
      'low_latency',
      'balanced',
      'low_power',
    ]);
    expect(defs.btproxyScanDuty.defaultValue, 'balanced');
    expect(defs.btproxyScanDuty.subpage, 'Bluetooth Proxy');
    expect(defs.btproxyScanDuty.dependsOn, 'btproxy.enabled');
  });
}
