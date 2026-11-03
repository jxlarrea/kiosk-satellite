import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/bt_proxy_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/voice/realtime/openai_realtime_backend.dart';
import 'package:kiosk_satellite/managers/voice/voice_manager.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_word_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// voiceRealtimeClear: the provider dialog's Clear. Save & Validate keeps
/// settings that fail to connect out, so an empty key could never undo a
/// saved one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  late CommandRegistry commands;
  late SettingsManager settings;
  late VoiceManager voice;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('ks_voice_clear');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => support.path,
        );
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
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
    await voice.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await support.delete(recursive: true);
  });

  test('a validated provider goes back to Not configured', () async {
    const gemini = RealtimeProvider.gemini;
    await settings.set(defs.voiceRealtimeGeminiApiKey, 'secret');
    await settings.set(defs.voiceRealtimeGeminiModel, 'gemini-3.8-live');
    await settings.set(defs.voiceRealtimeGeminiReasoning, 'high');
    await settings.set(defs.voiceRealtimeGeminiSearch, true);
    await settings.set(
      defs.voiceRealtimeGeminiValidated,
      voice.realtimeSignature(gemini),
    );
    await settings.set(defs.voiceEngine1, 'gemini');
    await settings.set(defs.voiceEngine2, 'openai');
    expect(voice.realtimeStatus(gemini).status, RealtimeStatus.validated);

    final result = await commands.execute('voiceRealtimeClear', {
      'provider': 'gemini',
    });

    expect(result.ok, true);
    expect(voice.realtimeStatus(gemini).status, RealtimeStatus.unconfigured);
    expect(voice.realtimeReady(gemini), false);
    expect(settings.get(defs.voiceRealtimeGeminiApiKey), '');
    expect(settings.get(defs.voiceRealtimeGeminiModel), '');
    expect(settings.get(defs.voiceRealtimeGeminiReasoning), '');
    expect(settings.get(defs.voiceRealtimeGeminiSearch), false);
    expect(settings.get(defs.voiceRealtimeGeminiValidated), '');
    // Wake word 1 answered with Gemini, wake word 2 keeps OpenAI.
    expect(settings.get(defs.voiceEngine1), 'assist');
    expect(settings.get(defs.voiceEngine2), 'openai');
  });

  test('an unknown provider is refused', () async {
    final result = await commands.execute('voiceRealtimeClear', {
      'provider': 'nope',
    });
    expect(result.ok, false);
  });
}
