import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/bt_proxy_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/voice/voice_manager.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_word_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A wake word manager with a stop word to arm.
class _StopWakeWord extends WakeWordManager {
  _StopWakeWord(super.bus, super.commands, super.log, super.settings);

  @override
  bool get stopWordAvailable => true;

  @override
  Future<bool> setStopWordArmed(bool armed, {String holder = 'voice'}) async =>
      true;
}

/// Issues #1548 and #1558: the stop word heard in the first second and a
/// half of an announcement is its own echo and stops nothing. After that it
/// stops the announcement as before.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  late BtProxyManager esphome;
  late VoiceManager voice;
  late EventBus bus;
  late List<String> stopped;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('ks_stop_word_hold');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => support.path,
        );
    SharedPreferences.setMockInitialValues({});
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    await settings.set(defs.voiceEnabled, true);
    await settings.set(defs.voiceStopWord, true);
    stopped = [];
    // The kiosk's own player: every sound gets an id, a stop is noted.
    var sounds = 0;
    commands
      ..register(
        Command(
          name: 'playSound',
          description: 'test player',
          handler: (p) async => CommandResult.ok({'id': 'snd${++sounds}'}),
        ),
      )
      ..register(
        Command(
          name: 'stopSound',
          description: 'test player',
          handler: (p) async {
            stopped.add('${p['id']}');
            return const CommandResult.ok();
          },
        ),
      );
    esphome = BtProxyManager(bus, commands, log, settings);
    final wakeWord = _StopWakeWord(bus, commands, log, settings);
    voice = VoiceManager(bus, commands, log, settings, esphome, wakeWord);
    await voice.init();
  });

  tearDown(() async {
    await voice.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await support.delete(recursive: true);
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('the stop word stops an announcement only once it has played', () async {
    esphome.onVoice!('announce', {
      'mediaId': 'http://ha/a.mp3',
      'text': 'The laundry is done.',
      'preannounceMediaId': '',
      'startConversation': false,
    });
    await settle();
    expect(voice.busy, isTrue);

    // A quarter of a second in: the kiosk hears its own voice.
    bus.publish(
      const SoundProgress(id: 'snd1', position: Duration(milliseconds: 250)),
    );
    bus.publish(const StopWordDetected());
    await settle();
    expect(voice.busy, isTrue);
    expect(stopped, isEmpty);

    // A second and a half in, someone says it.
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    bus.publish(const StopWordDetected());
    await settle();
    expect(stopped, ['snd1']);
    expect(voice.busy, isFalse);
  });
}
