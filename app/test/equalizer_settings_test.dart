import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/audio/audio_routing_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Equalizer settings reach the players (Equalizer.kt) at startup and on
/// every change.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsManager settings;
  AudioRoutingManager? audio;
  final calls = <Map<Object?, Object?>>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/audio_routing'),
          (call) async {
            if (call.method == 'setEqualizer') {
              calls.add(call.arguments as Map<Object?, Object?>);
            }
            return null;
          },
        );
  });

  tearDown(() async {
    await audio?.dispose();
    audio = null;
  });

  Future<void> boot(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final bus = EventBus();
    final log = Logger();
    settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
    audio = AudioRoutingManager(
      bus,
      CommandRegistry(log),
      log,
      settings,
      systemBuild: () async => 'b1',
    );
    await audio!.init();
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a fresh kiosk sends the equalizer off and flat', () async {
    await boot({});
    expect(calls, [
      {
        'enabled': false,
        'gains': [0.0, 0.0, 0.0, 0.0, 0.0],
        'preamp': true,
      },
    ]);
  });

  test('stored bands are sent at startup in band order', () async {
    await boot({
      'ks.${defs.equalizerEnabled.key}': true,
      'ks.${defs.equalizerBand1.key}': 6,
      'ks.${defs.equalizerBand4.key}': -3,
      'ks.${defs.equalizerPreamp.key}': false,
    });
    expect(calls.single, {
      'enabled': true,
      'gains': [6.0, 0.0, 0.0, -3.0, 0.0],
      'preamp': false,
    });
  });

  test('every change is sent', () async {
    await boot({});
    calls.clear();

    await settings.set(defs.equalizerEnabled, true);
    await settle();
    await settings.set(defs.equalizerBand1, 6);
    await settle();
    await settings.set(defs.equalizerBand5, -4);
    await settle();
    await settings.set(defs.equalizerPreamp, false);
    await settle();

    expect(calls.length, 4);
    expect(calls.last, {
      'enabled': true,
      'gains': [6.0, 0.0, 0.0, 0.0, -4.0],
      'preamp': false,
    });
  });

  test('a band written past its range is sent at the range\'s end', () async {
    // The settings API takes any number, so an import or a script can
    // store more than the slider allows.
    await boot({
      'ks.${defs.equalizerEnabled.key}': true,
      'ks.${defs.equalizerBand2.key}': 40,
      'ks.${defs.equalizerBand3.key}': -40,
    });
    expect(calls.single['gains'], [0.0, 12.0, -12.0, 0.0, 0.0]);
  });
}
