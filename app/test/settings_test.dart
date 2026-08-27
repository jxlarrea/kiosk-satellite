import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsManager settings;
  late Logger log;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    final bus = EventBus();
    log = Logger();
    settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
  }

  test('unstored settings return their declared default', () async {
    await build({});
    // Web Content has no settings page anymore: everything defaults on.
    expect(settings.get(defs.webMicrophone), isTrue);
    expect(settings.get(defs.webCamera), isTrue);
    expect(settings.get(defs.screensaverTimeoutSeconds), 300);
  });

  test(
    'describe() reports defaults for unstored settings (not null)',
    () async {
      await build({});
      final described = settings.describe();
      final mic = described.firstWhere((s) => s['key'] == 'web.microphone');
      // Regression: nullable type inference in describe() used to make this
      // null, so the UI rendered every untouched toggle as off.
      expect(mic['value'], isTrue);
      final camera = described.firstWhere((s) => s['key'] == 'web.camera');
      expect(camera['value'], isTrue);
    },
  );

  test('set persists and is read back', () async {
    await build({});
    await settings.set(defs.webCamera, true);
    expect(settings.get(defs.webCamera), isTrue);
    // Simulate a fresh app run against the same store.
    final bus = EventBus();
    final log = Logger();
    final reopened = SettingsManager(bus, CommandRegistry(log), log);
    await reopened.init();
    expect(reopened.get(defs.webCamera), isTrue);
  });

  test('the set log line names the caller when one is given', () async {
    await build({});
    await settings.set(defs.webCamera, false);
    await settings.setFromJson(
      defs.webCamera.key,
      true,
      source: 'remote admin',
    );
    final lines = log.recent.map((e) => e.message).toList();
    // The device's own writes stay as they were.
    expect(lines, contains('set web.camera = false'));
    expect(lines, contains('set web.camera = true [remote admin]'));
  });

  group('ha.url normalization', () {
    test('a trailing slash is dropped on write', () async {
      await build({});
      // The validator accepts a bare trailing slash, so the write path has
      // to canonicalize it — stored verbatim it dialled
      // 'http://ha:8123//api/websocket' on the pipeline socket.
      expect(
        await settings.setFromJson('ha.url', 'http://192.168.178.26:8123/'),
        isTrue,
      );
      expect(settings.get(defs.haUrl), 'http://192.168.178.26:8123');
    });

    test('typed set() normalizes too (setup wizard path)', () async {
      await build({});
      await settings.set(defs.haUrl, ' https://homeassistant.local:8123/ ');
      expect(settings.get(defs.haUrl), 'https://homeassistant.local:8123');
    });

    test('a stored trailing slash migrates to the origin on init', () async {
      await build({'ks.ha.url': 'http://192.168.178.26:8123/'});
      expect(settings.get(defs.haUrl), 'http://192.168.178.26:8123');
    });

    test('an already-clean value is left untouched', () async {
      await build({'ks.ha.url': 'https://ha.example'});
      expect(settings.get(defs.haUrl), 'https://ha.example');
    });
  });

  test('secrets are masked in describe but report set/unset', () async {
    await build({'ks.remote.password': 'hunter2'});
    final described = settings.describe();
    final pw = described.firstWhere((s) => s['key'] == 'remote.password');
    expect(pw['value'], '__set__');
    expect(pw['default'], isNull);
  });

  test('the DLNA port starts empty, for the renderer to fill in', () async {
    await build({});
    expect(settings.get(defs.dlnaPort), '');
  });

  test('the DLNA port rejects values a server cannot bind', () async {
    await build({});
    // Empty is the unstarted state, not an error.
    expect(defs.dlnaPort.validator!(''), isNull);
    expect(defs.dlnaPort.validator!('  '), isNull);
    expect(defs.dlnaPort.validator!('2325'), isNull);
    expect(defs.dlnaPort.validator!('80'), isNotNull);
    expect(defs.dlnaPort.validator!('70000'), isNotNull);
    expect(defs.dlnaPort.validator!('nonsense'), isNotNull);
  });

  test('microphone capture defaults are the long-standing behaviour', () async {
    await build({});
    // An untouched install must capture exactly as it did before these
    // settings existed: the call-audio source, no gain, platform AGC off.
    expect(settings.get(defs.micAudioSource), 'voice_communication');
    expect(settings.get(defs.micGainDb), 0);
    expect(settings.get(defs.micAgc), isFalse);
  });

  test('the audio faders default to full, matching old behavior', () async {
    await build({});
    // An untouched install must sound exactly as it did before the mixer
    // existed: everything at the master (device) volume.
    expect(settings.get(defs.mediaVolume), 100);
    expect(settings.get(defs.assistantVolume), 100);
    // Both render on the Screen & Audio page's Audio Volume card, in both
    // UIs.
    expect(defs.mediaVolume.category, 'Screen & Audio');
    expect(defs.assistantVolume.category, 'Screen & Audio');
    expect(defs.mediaVolume.section, 'Audio Volume');
    expect(defs.assistantVolume.section, 'Audio Volume');
  });

  test('the dashboard optimizations are on by default', () async {
    await build({});
    // Proven across devices (0.28): every optimization defaults on. A
    // stored false from someone who turned one off is untouched.
    expect(settings.get(defs.disableSuspend), isTrue);
    expect(settings.get(defs.freezeOnScreensaver), isTrue);
    expect(settings.get(defs.wsFilter), isTrue);
  });

  test(
    'kiosk quick actions are opt-in, with every action on by default',
    () async {
      await build({});
      // The gate itself must start closed: enabling kiosk mode alone must not
      // open any PIN-free path into the menu.
      expect(settings.get(defs.kioskAllowDrawer), isFalse);
      // The per-action toggles default on, so opting in is one switch.
      expect(settings.get(defs.kioskAllowDashboard), isTrue);
      expect(settings.get(defs.kioskAllowCamera), isTrue);
      expect(settings.get(defs.kioskAllowScreensaver), isTrue);
      expect(settings.get(defs.kioskAllowTheme), isTrue);
      expect(settings.get(defs.kioskAllowSendspinPlayer), isTrue);
      // The drawer entry the Sendspin Player action admits is itself
      // opt-in (issue #257), so the allowed action alone shows nothing.
      expect(settings.get(defs.sendspinPlayerShortcut), isFalse);
    },
  );

  test(
    'the pull-to-refresh protection defaults off, behind kiosk mode',
    () async {
      await build({});
      // Off by default: enabling kiosk mode alone must not change how the
      // gesture behaved before this setting existed.
      expect(settings.get(defs.kioskDisablePullRefresh), isFalse);
      expect(settings.visible(defs.kioskDisablePullRefresh), isFalse);
      await settings.set(defs.kioskEnabled, true);
      expect(settings.visible(defs.kioskDisablePullRefresh), isTrue);
    },
  );

  test(
    'the quick-action toggles surface only behind their two gates',
    () async {
      await build({});
      // Transitive dependsOn: action -> allow_drawer -> kiosk.enabled.
      expect(settings.visible(defs.kioskAllowDrawer), isFalse);
      expect(settings.visible(defs.kioskAllowDashboard), isFalse);
      await settings.set(defs.kioskEnabled, true);
      expect(settings.visible(defs.kioskAllowDrawer), isTrue);
      expect(settings.visible(defs.kioskAllowDashboard), isFalse);
      await settings.set(defs.kioskAllowDrawer, true);
      expect(settings.visible(defs.kioskAllowDashboard), isTrue);
      expect(settings.visible(defs.kioskAllowCamera), isTrue);
      expect(settings.visible(defs.kioskAllowScreensaver), isTrue);
      expect(settings.visible(defs.kioskAllowTheme), isTrue);
      expect(settings.visible(defs.kioskAllowSendspinPlayer), isTrue);
      // Closing the outer gate hides the whole group again.
      await settings.set(defs.kioskEnabled, false);
      expect(settings.visible(defs.kioskAllowDashboard), isFalse);
    },
  );

  test('the mic gain slider hides while AGC is levelling', () async {
    await build({});
    expect(settings.visible(defs.micGainDb), isTrue);
    await settings.set(defs.micAgc, true);
    // dependsOnValue: false — the inverse gate, which is the only one of its
    // kind in the definitions.
    expect(settings.visible(defs.micGainDb), isFalse);
    await settings.set(defs.micAgc, false);
    expect(settings.visible(defs.micGainDb), isTrue);
  });

  group('import identity (issue #136)', () {
    late CommandRegistry commands;

    Future<void> buildWithCommands(Map<String, Object> initial) async {
      SharedPreferences.setMockInitialValues(initial);
      final bus = EventBus();
      final log = Logger();
      commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
    }

    Map<String, Object> backup() => {
      'config': {
        'kind': 'kiosk-satellite-config',
        'version': 1,
        'settings': {'sendspin.client_id': 'backup-id'},
      },
    };

    test('restore as a new device keeps its own Sendspin player id', () async {
      await buildWithCommands({
        'ks.browser.start_url': 'http://ha.local:8123',
        'ks.sendspin.client_id': 'own-id',
      });
      final result = await commands.execute('importConfig', {
        ...backup(),
        'adoptIdentity': false,
      });
      expect(result.ok, isTrue);
      // Two players under one id displace each other at the Sendspin
      // server, so the backup's id must not come along.
      expect(settings.get(defs.sendspinClientId), 'own-id');
    });

    test('a device that had cloned the backup id verbatim sheds it', () async {
      await buildWithCommands({
        'ks.browser.start_url': 'http://ha.local:8123',
        'ks.sendspin.client_id': 'backup-id',
      });
      final result = await commands.execute('importConfig', {
        ...backup(),
        'adoptIdentity': false,
      });
      expect(result.ok, isTrue);
      // "Keeping its own" would keep the collision; empty makes the
      // Sendspin manager mint a fresh id at the next player start.
      expect(settings.get(defs.sendspinClientId), isEmpty);
    });

    test('a replacement-device restore adopts the backup player id', () async {
      await buildWithCommands({
        'ks.browser.start_url': 'http://ha.local:8123',
        'ks.sendspin.client_id': 'own-id',
      });
      final result = await commands.execute('importConfig', backup());
      expect(result.ok, isTrue);
      // The default (adoptIdentity true) is a replacement device: Music
      // Assistant should see the same player it always had.
      expect(settings.get(defs.sendspinClientId), 'backup-id');
    });
  });

  // The raw settings dump path (/api/settings/import) used to apply the
  // source device's identity verbatim, reintroducing the #136 collision.
  group('shedImportedIdentity (issue #221)', () {
    test('drops the identity keys and leaves the rest of the dump', () async {
      await build({
        'ks.device.name': 'Kitchen',
        'ks.mqtt.device_id': 'own-mqtt-id',
        'ks.sendspin.client_id': 'own-player-id',
      });
      final map = <String, Object?>{
        'device.name': 'Living Room',
        'mqtt.device_id': 'source-mqtt-id',
        'sendspin.client_id': 'source-player-id',
        'screensaver.timeout_seconds': 60,
      };
      await settings.shedImportedIdentity(map);
      // The identity keys must not survive to the import that follows.
      expect(map.keys, ['screensaver.timeout_seconds']);
      // This device's own identity is untouched: the incoming values
      // differ, so there is no inherited collision to shed.
      expect(settings.get(defs.deviceName), 'Kitchen');
      expect(settings.get(defs.mqttDeviceId), 'own-mqtt-id');
      expect(settings.get(defs.sendspinClientId), 'own-player-id');
    });

    test('a device that had cloned the incoming identity sheds it', () async {
      await build({
        'ks.device.name': 'Living Room',
        'ks.mqtt.device_id': 'source-mqtt-id',
        'ks.sendspin.client_id': 'source-player-id',
      });
      await settings.shedImportedIdentity(<String, Object?>{
        'device.name': 'Living Room',
        'mqtt.device_id': 'source-mqtt-id',
        'sendspin.client_id': 'source-player-id',
      });
      // "Keeping its own" would keep the collision; empty makes the ids
      // regenerate at the next MQTT and Sendspin connect.
      expect(settings.get(defs.deviceName), isEmpty);
      expect(settings.get(defs.mqttDeviceId), isEmpty);
      expect(settings.get(defs.sendspinClientId), isEmpty);
    });
  });
}
