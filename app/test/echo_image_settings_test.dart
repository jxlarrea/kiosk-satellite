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
    ('echo', 'athena', 24),
    ('echo', 'cronos', 20),
    ('echo', 'checkers', 20),
    ('biscuit', 'biscuit', 5),
    ('biscuit', 'donut', 27),
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

  group('the Echo Dot\'s equalizer', () {
    Map<String, Object> equalizer() => {
      for (final def in [
        defs.equalizerEnabled,
        ...defs.equalizerBands,
        defs.equalizerPreamp,
      ])
        def.key: settings.get(def),
    };
    const preset = {
      'audio.equalizer_enabled': true,
      'audio.equalizer_bass': 1,
      'audio.equalizer_low_mid': 2,
      'audio.equalizer_mid': -3,
      'audio.equalizer_high_mid': -7,
      'audio.equalizer_treble': -1,
      'audio.equalizer_preamp': false,
    };

    test('starts with the preset and its volumes on a fresh install', () async {
      await boot({}, 'biscuit', 'biscuit');
      expect(equalizer(), preset);
      expect(settings.get(defs.mediaVolume), 85);
      expect(settings.get(defs.intercomVolume), 100);
      expect(settings.get(defs.assistantVolume), 100);
      expect(settings.internal(EchoImageSettings.equalizerMarker), 'biscuit');
    });

    test('the 3rd generation Dot starts with its own preset', () async {
      await boot({}, 'biscuit', 'donut');
      expect(equalizer(), {
        'audio.equalizer_enabled': true,
        'audio.equalizer_bass': 3,
        'audio.equalizer_low_mid': 2,
        'audio.equalizer_mid': -1,
        'audio.equalizer_high_mid': -3,
        'audio.equalizer_treble': 1,
        'audio.equalizer_preamp': false,
      });
      expect(settings.get(defs.mediaVolume), 85);
      expect(settings.get(defs.intercomVolume), 100);
      expect(settings.get(defs.assistantVolume), 100);
      expect(settings.internal(EchoImageSettings.equalizerMarker), 'donut');
    });

    test('an update moves a Dot to the preset and its volumes', () async {
      await boot(
        {'ks.audio.media_volume': 100, 'ks.audio.intercom_volume': 60},
        'biscuit',
        'biscuit',
      );
      expect(equalizer(), preset);
      expect(settings.get(defs.mediaVolume), 85);
      expect(settings.get(defs.intercomVolume), 100);
    });

    test('an equalizer set before stays as it was, volumes too', () async {
      await boot(
        {
          'ks.audio.equalizer_enabled': true,
          'ks.audio.equalizer_mid': 4,
          'ks.audio.media_volume': 40,
        },
        'biscuit',
        'biscuit',
      );
      expect(settings.get(defs.mediaVolume), 40);
      expect(settings.get(defs.intercomVolume), 60);
      expect(settings.get(defs.equalizerBand3), 4);
      expect(settings.get(defs.equalizerBand4), 0);
      expect(settings.get(defs.equalizerPreamp), isTrue);
    });

    test('turned off afterwards, it stays off on the next start', () async {
      await boot({}, 'biscuit', 'biscuit');
      await settings.set(defs.mediaVolume, 50);
      await settings.set(defs.equalizerEnabled, false);
      for (final band in defs.equalizerBands) {
        await settings.set(band, 0);
      }
      await pins!.dispose();
      pins = EchoImageSettings(
        settings,
        bus,
        log,
        updater: () async => 'biscuit',
        codename: () async => 'biscuit',
      );
      await pins!.init();
      expect(settings.get(defs.equalizerEnabled), isFalse);
      expect(settings.get(defs.equalizerBand4), 0);
      expect(settings.get(defs.mediaVolume), 50);
    });

    test('the Echo Shows and other devices stay flat and off', () async {
      for (final (updater, codename) in [
        ('echo', 'crown'),
        ('echo', 'athena'),
        ('echo', 'cronos'),
        ('echo', 'checkers'),
        (null, 'biscuit'),
      ]) {
        await boot({}, updater, codename);
        expect(settings.get(defs.equalizerEnabled), isFalse, reason: codename);
        expect(settings.get(defs.equalizerBand4), 0, reason: codename);
        expect(settings.get(defs.mediaVolume), 100, reason: codename);
        expect(settings.get(defs.intercomVolume), 60, reason: codename);
        await pins!.dispose();
      }
    });
  });

  test('any other device keeps a gain set before', () async {
    await boot({'ks.audio.mic_gain_db': 5}, null);
    expect(settings.get(defs.micGainDb), 5);
  });

  test('an Echo Show the image does not name has no base gain', () async {
    await boot({}, 'echo', 'unknown');
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
