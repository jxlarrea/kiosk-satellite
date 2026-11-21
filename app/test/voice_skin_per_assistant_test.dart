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

/// Issue #1121: Assistant 2 has its own skin, and the overlay wears the
/// skin of the assistant answering.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the Assistant 2 skin setting', () {
    late SettingsManager settings;

    Future<void> build(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final log = Logger();
      settings = SettingsManager(EventBus(), CommandRegistry(log), log);
      await settings.init();
    }

    test('a new install starts on the Kiosk Satellite skin', () async {
      await build({});
      expect(settings.get(defs.voiceSkin2), 'kiosk-satellite');
    });

    test('an upgrade keeps the skin Assistant 2 wore', () async {
      await build({'ks.voice.skin': 'jarvis'});
      expect(settings.get(defs.voiceSkin2), 'jarvis');
    });

    test('the upgrade runs once', () async {
      SharedPreferences.setMockInitialValues({'ks.voice.skin': 'jarvis'});
      final log = Logger();
      settings = SettingsManager(EventBus(), CommandRegistry(log), log);
      await settings.init();
      await settings.set(defs.voiceSkin, 'kitt');
      await settings.set(defs.voiceSkin2, 'hal-9000');
      final again = SettingsManager(EventBus(), CommandRegistry(log), log);
      await again.init();
      expect(again.get(defs.voiceSkin), 'kitt');
      expect(again.get(defs.voiceSkin2), 'hal-9000');
    });

    test('a pick already made stays', () async {
      await build({'ks.voice.skin': 'jarvis', 'ks.voice.skin_2': 'kitt'});
      expect(settings.get(defs.voiceSkin2), 'kitt');
    });

    test('it takes a plugin skin like Skin does', () async {
      await build({});
      expect(await settings.setFromJson('voice.skin_2', 'plugin:hello'), true);
      expect(settings.get(defs.voiceSkin2), 'plugin:hello');
      expect(settings.optionsFor(defs.voiceSkin2), contains('plugin:hello'));
    });

    test('each assistant has its setting', () {
      expect(defs.voiceSkinOf(1), defs.voiceSkin);
      expect(defs.voiceSkinOf(2), defs.voiceSkin2);
    });
  });

  group('the assistant on screen', () {
    late Directory support;
    late CommandRegistry commands;
    late SettingsManager settings;
    late VoiceManager voice;
    late EventBus bus;
    late List<VoiceInteractionChanged> holds;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('ks_voice_skin');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => support.path,
          );
      SharedPreferences.setMockInitialValues({});
      bus = EventBus();
      holds = [];
      bus.on<VoiceInteractionChanged>().listen(holds.add);
      final log = Logger();
      commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      await settings.set(defs.voiceEnabled, true);
      voice = VoiceManager(
        bus,
        commands,
        log,
        settings,
        BtProxyManager(bus, commands, log, settings),
        WakeWordManager(bus, commands, log, settings),
      );
      await voice.init();
    });

    tearDown(() async {
      // A show fails without Home Assistant: let it before the streams close.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await voice.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      await support.delete(recursive: true);
    });

    test('a vs_show on pipeline 2 is Assistant 2', () async {
      final result = await commands.execute('voiceShow', {
        'prompt': 'What is on today?',
        'pipeline': 2,
      });
      expect(result.ok, true);
      expect(voice.view.value.visible, true);
      expect(voice.view.value.assistant, 2);
    });

    test('a vs_show on pipeline 1 and a preview are Assistant 1', () async {
      await commands.execute('voiceShow', {'prompt': 'Hello'});
      expect(voice.view.value.assistant, 1);
      await commands.execute('voiceCancel', const {});
      await commands.execute('voicePreview', const {'seconds': 1});
      expect(voice.view.value.visible, true);
      expect(voice.view.value.assistant, 1);
    });

    // Issue #1545: the started event says which Assistant answers and the
    // wake word that started it.
    test('a wake word turn holds with its Assistant and phrase', () async {
      bus.publish(
        const WakeWordDetected(model: 'ok_nabu', phrase: 'Okay Nabu'),
      );
      await pumpEventQueue();
      final started = holds.firstWhere((e) => e.active);
      expect(started.reason, 'voice');
      expect(started.slot, 1);
      expect(started.wakeWord, 'Okay Nabu');
    });

    test(
      'a vs_show on pipeline 2 holds as Assistant 2, no wake word',
      () async {
        await commands.execute('voiceShow', {'prompt': 'Hi', 'pipeline': 2});
        await pumpEventQueue();
        final started = holds.firstWhere((e) => e.active);
        expect(started.reason, 'show');
        expect(started.slot, 2);
        expect(started.wakeWord, '');
      },
    );

    test('a vs_show refused over another turn leaves it alone', () async {
      await commands.execute('voiceShow', {'prompt': 'Hello'});
      final result = await commands.execute('voiceShow', {
        'prompt': 'Again',
        'pipeline': 2,
      });
      expect(result.ok, false);
      expect(voice.view.value.assistant, 1);
    });
  });
}
