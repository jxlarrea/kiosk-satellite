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

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    final bus = EventBus();
    final log = Logger();
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

  test('describe() reports defaults for unstored settings (not null)',
      () async {
    await build({});
    final described = settings.describe();
    final mic = described.firstWhere((s) => s['key'] == 'web.microphone');
    // Regression: nullable type inference in describe() used to make this
    // null, so the UI rendered every untouched toggle as off.
    expect(mic['value'], isTrue);
    final camera = described.firstWhere((s) => s['key'] == 'web.camera');
    expect(camera['value'], isTrue);
  });

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
}
