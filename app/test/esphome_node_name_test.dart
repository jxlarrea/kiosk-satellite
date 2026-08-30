import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/bt_proxy_manager.dart';
import 'package:kiosk_satellite/managers/btproxy/node_name.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The ESPHome node name. Home Assistant builds this device's action
/// names from it (`esphome.<node>_notification`), and it is also the mDNS
/// instance and hostname, so it has to survive as a DNS label. A fresh
/// install takes the device's own name; one that already announced
/// itself keeps the generated identity, because renaming it renames the
/// actions users' automations call.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('slug', () {
    test('a device name becomes a DNS label', () {
      expect(
        esphomeNodeSlug('KS Master Bedroom Satellite'),
        'ks-master-bedroom-satellite',
      );
      expect(esphomeNodeSlug('  Kitchen  '), 'kitchen');
      expect(esphomeNodeSlug("Ana's Tablet (2)"), 'ana-s-tablet-2');
      expect(esphomeNodeSlug('Cocina Pequeña'), 'cocina-pequena');
      expect(esphomeNodeSlug('Tablet_01'), 'tablet-01');
      // A fresh install's name, from the device name: the slug under a
      // ks- prefix, and a name that already starts with KS keeps one.
      expect(esphomeNodeFromDeviceName('Amazon KFTUWI'), 'ks-amazon-kftuwi');
      expect(esphomeNodeFromDeviceName('Kitchen Tablet'), 'ks-kitchen-tablet');
      expect(esphomeNodeFromDeviceName('KS Kitchen'), 'ks-kitchen');
      expect(esphomeNodeFromDeviceName('ks'), 'ks');
      expect(esphomeNodeFromDeviceName('Kiosk'), 'ks-kiosk');
    });

    test('an already valid name passes through untouched', () {
      expect(
        esphomeNodeSlug('kiosk-satellite-ad603b'),
        'kiosk-satellite-ad603b',
      );
    });

    test('nothing usable yields nothing, never a bare hyphen', () {
      expect(esphomeNodeSlug(''), '');
      expect(esphomeNodeFromDeviceName(''), '');
      expect(esphomeNodeFromDeviceName('日本語'), '');
      expect(esphomeNodeSlug('   '), '');
      expect(esphomeNodeSlug('---'), '');
      expect(esphomeNodeSlug('日本語'), '');
    });

    test('long names are cut inside the DNS label limit', () {
      final slug = esphomeNodeSlug('The ${'very ' * 20}long tablet name');
      expect(slug.length, lessThanOrEqualTo(40));
      expect(slug.endsWith('-'), isFalse);
    });
  });

  group('resolution', () {
    late List<MethodCall> sent;

    Future<SettingsManager> boot(Map<String, Object> prefs) async {
      sent = [];
      SharedPreferences.setMockInitialValues({
        'ks.esphome.enabled': true,
        ...prefs,
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('kiosk_satellite/bluetooth_proxy'),
            (call) async {
              sent.add(call);
              if (call.method != 'start') return null;
              // The native side answers with the name it came up under: what
              // it was handed, or its generated identity when handed nothing.
              final asked =
                  (call.arguments as Map)['nodeName'] as String? ?? '';
              return asked.isEmpty ? 'kiosk-satellite-ad603b' : asked;
            },
          );
      final bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      final settings = SettingsManager(bus, commands, log);
      await settings.init();
      final proxy = BtProxyManager(bus, commands, log, settings);
      await proxy.init();
      // init queues the start behind its transition chain.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return settings;
    }

    String startedWith() =>
        (sent.firstWhere((c) => c.method == 'start').arguments
                as Map)['nodeName']
            as String;

    test('a fresh install names itself after the device', () async {
      final settings = await boot({
        'ks.device.name': 'KS Master Bedroom Satellite',
      });
      expect(startedWith(), 'ks-master-bedroom-satellite');
      expect(settings.get(defs.esphomeNodeName), 'ks-master-bedroom-satellite');
    });

    test('an install that already announced itself keeps its name', () async {
      final settings = await boot({
        'ks.device.name': 'KS Master Bedroom Satellite',
        // A stored key is the mark of a server that has run before, and
        // its name is in Home Assistant's config entry already.
        'ks.btproxy.key': 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=',
      });
      expect(startedWith(), '');
      // Written back, so the row shows the real name and the next start
      // reads it from settings.
      expect(settings.get(defs.esphomeNodeName), 'kiosk-satellite-ad603b');
    });

    test('a name the user set wins over both', () async {
      final settings = await boot({
        'ks.device.name': 'KS Master Bedroom Satellite',
        'ks.btproxy.key': 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=',
        'ks.esphome.node_name': 'Master Bedroom',
      });
      expect(startedWith(), 'master-bedroom');
      expect(settings.get(defs.esphomeNodeName), 'master-bedroom');
    });

    test(
      'an unnamed fresh install falls back to the generated identity',
      () async {
        final settings = await boot({'ks.device.name': ''});
        expect(startedWith(), '');
        expect(settings.get(defs.esphomeNodeName), 'kiosk-satellite-ad603b');
      },
    );
  });
}
