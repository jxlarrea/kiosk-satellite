import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/bt_proxy_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Bluetooth LE support gate (issue #326). Android binds its GATT
/// service only on builds that declare the Bluetooth LE feature; without
/// it every scan fails the instant it starts, whatever the settings. The
/// native side answers `bleSupport` over the proxy channel; the manager
/// keeps the proxy switch off on such a build (at boot and whenever
/// something turns it on), starts the server with no proxy so Home
/// Assistant is told of none, and serves the reason to both settings
/// pages through `getBleSupport`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hint =
      'Not available on this device: its Android build has no Bluetooth '
      'LE support.';

  late List<MethodCall> sent;
  Map<String, Object?>? answer;

  Future<(SettingsManager, BtProxyManager, CommandRegistry)> boot() async {
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
            if (call.method == 'bleSupport') return answer;
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
    // init queues the start behind its transition chain.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return (settings, proxy, commands);
  }

  /// The proxy flag the last server start was handed, or null when no
  /// start happened.
  bool? startedWithProxy() {
    final starts = sent.where((c) => c.method == 'start');
    if (starts.isEmpty) return null;
    return (starts.last.arguments as Map)['bluetoothProxy'] as bool?;
  }

  test(
    'a build without Bluetooth LE keeps the proxy off and says why',
    () async {
      answer = {'supported': false, 'hint': hint};
      final (settings, proxy, commands) = await boot();
      expect(settings.get(defs.btproxyEnabled), isFalse);
      expect(proxy.bleKnownUnsupported, isTrue);
      expect(proxy.bleHint, hint);
      // The server still runs for the kiosk's entities, with no proxy.
      expect(startedWithProxy(), isFalse);
      final res = await commands.execute('getBleSupport', const {});
      expect(res.ok, isTrue);
      expect((res.data as Map)['supported'], isFalse);
      expect((res.data as Map)['hint'], hint);
    },
  );

  test('turning the switch on again on such a build is undone', () async {
    answer = {'supported': false, 'hint': hint};
    final (settings, _, _) = await boot();
    await settings.set(defs.btproxyEnabled, true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(settings.get(defs.btproxyEnabled), isFalse);
  });

  test('a build with Bluetooth LE leaves the switch alone', () async {
    answer = {'supported': true, 'hint': null};
    final (settings, proxy, _) = await boot();
    expect(settings.get(defs.btproxyEnabled), isTrue);
    expect(proxy.bleKnownUnsupported, isFalse);
    expect(startedWithProxy(), isTrue);
  });

  test('no answer counts as supported, never switching a feature off on a '
      'guess', () async {
    answer = null;
    final (settings, proxy, _) = await boot();
    expect(settings.get(defs.btproxyEnabled), isTrue);
    expect(proxy.bleKnownUnsupported, isFalse);
    expect(startedWithProxy(), isTrue);
  });
}
