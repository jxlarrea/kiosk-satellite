import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/echo_image_settings.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Echo images keep Capture mode, Capture format, Echo cancellation and
/// Noise suppression hidden and at the image's values on every start,
/// whatever was stored before, and put a base gain under Microphone gain.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late Logger log;
  late SettingsManager settings;
  EchoImageSettings? pins;

  Future<void> boot(
    Map<String, Object> prefs,
    String? updater, [
    String? codename,
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    bus = EventBus();
    log = Logger();
    settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
    pins = EchoImageSettings(
      settings,
      bus,
      log,
      updater: () async => updater,
      codename: () async => codename,
    );
    await pins!.init();
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  tearDown(() async {
    await pins?.dispose();
    pins = null;
    defs.deviceHiddenKeys.clear();
    defs.devicePinnedKeys.clear();
    EchoImageSettings.micGainBaseDb = 0;
  });

  for (final updater in ['biscuit', 'echo']) {
    group('the $updater image', () {
      test('hides the microphone settings and pins them', () async {
        await boot({}, updater);
        for (final def in [
          defs.micCaptureMode,
          defs.micCaptureFormat,
          defs.micSoftwareEchoCancellation,
          defs.micNoiseSuppression,
        ]) {
          expect(defs.deviceHiddenKeys, contains(def.key));
          expect(defs.devicePinnedKeys, contains(def.key));
        }
        expect(settings.get(defs.micCaptureMode), 'mic');
        expect(settings.get(defs.micCaptureFormat), 'auto');
        expect(settings.get(defs.micSoftwareEchoCancellation), isTrue);
        expect(settings.get(defs.micNoiseSuppression), isFalse);
      });

      test('stored values go back to the image\'s', () async {
        await boot({
          'ks.audio.mic_capture_mode': 'voice_communication',
          'ks.audio.mic_capture_format': 'hardware',
          'ks.audio.software_echo_cancellation': false,
          'ks.audio.mic_noise_suppression': true,
        }, updater);
        expect(settings.get(defs.micCaptureMode), 'mic');
        expect(settings.get(defs.micCaptureFormat), 'auto');
        expect(settings.get(defs.micSoftwareEchoCancellation), isTrue);
        expect(settings.get(defs.micNoiseSuppression), isFalse);
      });

      test('a later change is put back', () async {
        await boot({}, updater);
        await settings.set(defs.micCaptureMode, 'voice_communication');
        await settings.set(defs.micCaptureFormat, 'hardware');
        await settings.set(defs.micSoftwareEchoCancellation, false);
        await settings.set(defs.micNoiseSuppression, true);
        await settle();
        expect(settings.get(defs.micCaptureMode), 'mic');
        expect(settings.get(defs.micCaptureFormat), 'auto');
        expect(settings.get(defs.micSoftwareEchoCancellation), isTrue);
        expect(settings.get(defs.micNoiseSuppression), isFalse);
      });
    });
  }

  for (final (updater, codename, gain) in [
    ('echo', 'crown', 24),
    ('echo', 'cronos', 20),
    ('biscuit', 'biscuit', 5),
  ]) {
    test('the $codename adds $gain dB under the user\'s gain', () async {
      await boot({}, updater, codename);
      expect(EchoImageSettings.micGainBaseDb, gain);
      expect(defs.deviceHiddenKeys, isNot(contains(defs.micGainDb.key)));
      expect(defs.devicePinnedKeys, isNot(contains(defs.micGainDb.key)));
      await settings.set(defs.micGainDb, 3);
      await settle();
      expect(settings.get(defs.micGainDb), 3);
    });

    test('the $codename puts a gain set before back to 0 dB once', () async {
      await boot({'ks.audio.mic_gain_db': 5}, updater, codename);
      expect(settings.get(defs.micGainDb), 0);
      await settings.set(defs.micGainDb, 4);
      await pins!.dispose();
      pins = EchoImageSettings(
        settings,
        bus,
        log,
        updater: () async => updater,
        codename: () async => codename,
      );
      await pins!.init();
      expect(settings.get(defs.micGainDb), 4);
    });
  }

  test('any other device keeps a gain set before', () async {
    await boot({'ks.audio.mic_gain_db': 5}, null);
    expect(settings.get(defs.micGainDb), 5);
  });

  test('an Echo Show the image does not name has no base gain', () async {
    await boot({}, 'echo', 'checkers');
    expect(EchoImageSettings.micGainBaseDb, 0);
    expect(defs.deviceHiddenKeys, contains(defs.micNoiseSuppression.key));
  });

  test('any other device has no base gain', () async {
    await boot({}, null, 'crown');
    expect(EchoImageSettings.micGainBaseDb, 0);
  });

  test('any other device keeps the setting and its value', () async {
    await boot({'ks.audio.mic_capture_mode': 'voice_communication'}, null);
    expect(defs.deviceHiddenKeys, isNot(contains(defs.micCaptureMode.key)));
    expect(defs.devicePinnedKeys, isNot(contains(defs.micCaptureMode.key)));
    expect(settings.get(defs.micCaptureMode), 'voice_communication');
  });

  test('no native side changes nothing', () async {
    SharedPreferences.setMockInitialValues({
      'ks.audio.mic_capture_mode': 'voice_communication',
    });
    bus = EventBus();
    log = Logger();
    settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
    await EchoImageSettings(
      settings,
      bus,
      log,
      updater: () async => throw StateError('no channel'),
    ).init();
    expect(settings.get(defs.micCaptureMode), 'voice_communication');
  });
}
