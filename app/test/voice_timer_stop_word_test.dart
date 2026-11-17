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

/// Keeps the holders the way the real manager does, so a test can see
/// whether the stop word would still be listening.
class _HolderWakeWord extends WakeWordManager {
  _HolderWakeWord(super.bus, super.commands, super.log, super.settings);

  final holders = <String>{};

  @override
  Future<bool> setStopWordArmed(bool armed, {String holder = 'voice'}) async {
    armed ? holders.add(holder) : holders.remove(holder);
    return true;
  }
}

/// Issue #1478: a ringing timer keeps the stop word armed while an
/// announcement or a voice turn starts and ends during the ring.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  late BtProxyManager esphome;
  late _HolderWakeWord wakeWord;
  late VoiceManager voice;
  late EventBus bus;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('ks_timer_stop_word');
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
    await settings.set(defs.voiceTimerSpeak, false);
    esphome = BtProxyManager(bus, commands, log, settings);
    wakeWord = _HolderWakeWord(bus, commands, log, settings);
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

  void timer(int type) => esphome.onVoice!('timer', {
    'type': type,
    'id': 't1',
    'name': '',
    'totalSeconds': 5,
    'secondsLeft': type == 3 ? 0 : 5,
    'isActive': true,
  });

  test(
    'an announcement ending during the ring leaves the stop word armed',
    () async {
      timer(0);
      timer(3); // finished: the alert rings
      expect(wakeWord.holders, contains('timer'));

      // The voice session arms and disarms around the announcement's
      // playback with its own holder.
      await wakeWord.setStopWordArmed(true);
      await wakeWord.setStopWordArmed(false);
      expect(wakeWord.holders, {'timer'});

      timer(2); // the ring ends
      expect(wakeWord.holders, isEmpty);
    },
  );

  test('a ring ending during a voice turn leaves the turn armed', () async {
    timer(0);
    timer(3);
    await wakeWord.setStopWordArmed(true);
    timer(2);
    expect(wakeWord.holders, {'voice'});
  });

  // Issue #1480: once Silence after quiets the ring, the music comes back
  // and the stop word still dismisses the alert.
  test('a quiet ring keeps the stop word and lets the music go', () async {
    final timerHolds = <bool>[];
    final sub = bus.on<VoiceInteractionChanged>().listen((e) {
      if (e.reason == 'timer') timerHolds.add(e.active);
    });
    timer(0);
    timer(3);
    await Future<void>.delayed(Duration.zero);
    expect(timerHolds, [true]);
    bus.publish(const TimerRingQuiet(true));
    await Future<void>.delayed(Duration.zero);
    expect(timerHolds, [true, false]);
    expect(wakeWord.holders, {'timer'});
    bus.publish(const TimerRingQuiet(false));
    await Future<void>.delayed(Duration.zero);
    expect(timerHolds, [true, false, true]);
    timer(2);
    await Future<void>.delayed(Duration.zero);
    expect(timerHolds, [true, false, true, false]);
    expect(wakeWord.holders, isEmpty);
    await sub.cancel();
  });
}
