import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/audio/audio_routing_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/wake_word/vsww/native_mic.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Echo cancellation method: Automatic's verdict shows as "(detected)",
/// lands without reopening the capture, and a system update tests again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late Logger log;
  late SettingsManager settings;
  AudioRoutingManager? audio;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/audio_routing'),
          (_) async => null,
        );
  });

  tearDown(() async {
    await audio?.dispose();
    audio = null;
    NativeMic.echoMethod = 'auto';
  });

  Future<void> boot(Map<String, Object> prefs, {String build = 'b1'}) async {
    SharedPreferences.setMockInitialValues(prefs);
    bus = EventBus();
    log = Logger();
    settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
    audio = AudioRoutingManager(
      bus,
      CommandRegistry(log),
      log,
      settings,
      systemBuild: () async => build,
    );
    await audio!.init();
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// The canceller's verdict, as AudioRoutingBridge sends it.
  Future<void> detected(String verdict) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'kiosk_satellite/audio_routing',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('echoMethodDetected', verdict),
          ),
          (_) {},
        );
  }

  test('Automatic offers the two cancellers and no verdict yet', () async {
    await boot({});
    expect(settings.optionsFor(defs.micEchoCancellationMethod), [
      'auto',
      'gtcrn',
      'aec3',
    ]);
    expect(NativeMic.echoMethod, 'auto');
  });

  test('a verdict shows as detected after Automatic', () async {
    await boot({});
    await detected('aec3');
    await settle();
    expect(settings.get(defs.micEchoCancellationMethod), 'auto:aec3');
    expect(settings.optionsFor(defs.micEchoCancellationMethod), [
      'auto',
      'gtcrn',
      'auto:aec3',
    ]);
    expect(
      defs.micEchoCancellationMethod.optionLabels!['auto:aec3'],
      'AEC3 (detected)',
    );
    expect(NativeMic.echoMethod, 'auto:aec3');
  });

  test('picking Automatic again drops the verdict', () async {
    await boot({'ks.audio.echo_cancellation_method': 'auto:gtcrn'});
    expect(
      await settings.setFromJson(defs.micEchoCancellationMethod.key, 'auto'),
      isTrue,
    );
    await settle();
    expect(settings.optionsFor(defs.micEchoCancellationMethod), [
      'auto',
      'gtcrn',
      'aec3',
    ]);
    expect(NativeMic.echoMethod, 'auto');
  });

  test('a verdict cannot be picked by hand', () async {
    await boot({});
    expect(
      await settings.setFromJson(
        defs.micEchoCancellationMethod.key,
        'auto:aec3',
      ),
      isFalse,
    );
  });

  test('a canceller picked meanwhile wins over a verdict', () async {
    await boot({});
    await settings.set(defs.micEchoCancellationMethod, 'gtcrn');
    await detected('aec3');
    await settle();
    expect(settings.get(defs.micEchoCancellationMethod), 'gtcrn');
  });

  test('a system update tests again', () async {
    await boot({});
    await detected('gtcrn');
    await settle();
    await audio!.dispose();
    audio = AudioRoutingManager(
      bus,
      CommandRegistry(log),
      log,
      settings,
      systemBuild: () async => 'b2',
    );
    await audio!.init();
    expect(settings.get(defs.micEchoCancellationMethod), 'auto');
  });

  test('the same system build keeps the verdict', () async {
    await boot({});
    await detected('gtcrn');
    await settle();
    await audio!.dispose();
    audio = AudioRoutingManager(
      bus,
      CommandRegistry(log),
      log,
      settings,
      systemBuild: () async => 'b1',
    );
    await audio!.init();
    expect(settings.get(defs.micEchoCancellationMethod), 'auto:gtcrn');
  });

  test('a verdict does not reopen the capture, a pick does', () {
    expect(defs.isEchoMethodVerdict('auto', 'auto:aec3'), isTrue);
    expect(defs.isEchoMethodVerdict('auto:aec3', 'auto'), isFalse);
    expect(defs.isEchoMethodVerdict('auto', 'gtcrn'), isFalse);
  });
}
