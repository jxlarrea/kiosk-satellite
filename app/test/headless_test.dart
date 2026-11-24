import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/headless.dart';
import 'package:kiosk_satellite/core/lifecycle.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/gestures/gesture_mappings.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/headless_settings.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A device without a screen (Echo Dot): the display settings are hidden
/// from both UIs, the ones that would start real work are pinned, and the
/// Action button is a gesture trigger.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() async {
    defs.deviceHiddenKeys.clear();
    defs.deviceHiddenOptions.clear();
    SharedPreferences.setMockInitialValues({
      // What a configuration imported from a tablet carries.
      'ks.screensaver.enabled': true,
      'ks.camera.enabled': true,
      'ks.remote.enabled': false,
      'ks.intercom.talk_mode': 'ptt',
      'ks.voice.timer_pills': true,
    });
    bus = EventBus();
    final log = Logger();
    settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
    await HeadlessSettings(settings, bus, log).init();
  });

  tearDown(() {
    defs.deviceHiddenKeys.clear();
    defs.deviceHiddenOptions.clear();
    Headless.debugActive = false;
    Headless.debugVolumeClaim = false;
  });

  test('display pages and settings are hidden, voice and audio stay', () {
    final hidden = defs.deviceHiddenKeys;
    for (final def in defs.allSettings) {
      if (const {
        'Screensaver',
        'Browser',
        'Camera',
        'Kiosk',
        'Lockdown',
        'Calendar',
      }.contains(def.category)) {
        expect(hidden, contains(def.key), reason: def.key);
      }
    }
    expect(hidden, contains(defs.keepScreenOn.key));
    expect(hidden, contains(defs.haKioskMode.key));
    expect(hidden, contains(defs.voiceSkin.key));
    expect(hidden, contains(defs.remoteEnabled.key));
    expect(hidden, contains(defs.uiToastsHidden.key));
    expect(hidden, isNot(contains(defs.haUrl.key)));
    expect(hidden, isNot(contains(defs.haToken.key)));
    expect(hidden, isNot(contains(defs.mediaVolume.key)));
    expect(hidden, isNot(contains(defs.voiceEnabled.key)));
    expect(hidden, isNot(contains(defs.intercomEnabled.key)));
    expect(hidden, isNot(contains(defs.dlnaEnabled.key)));
    expect(hidden, isNot(contains(defs.alarmsVolume.key)));
  });

  test(
    'Ground Control keeps Voice Match and drops Vision Match, menu links go',
    () {
      final hidden = defs.deviceHiddenKeys;
      expect(hidden, isNot(contains(defs.voiceMatchEnabled.key)));
      // Vision Match works on the camera's frames: none without a screen.
      expect(hidden, contains(defs.visionMatchEnabled.key));
      expect(hidden, contains(defs.visionMatchFaceDetection.key));
      expect(hidden, contains(defs.visionMatchHandGestures.key));
      for (final def in defs.allSettings) {
        if (def.linksTo == defs.uiDrawerItems.key) {
          expect(hidden, contains(def.key), reason: def.key);
        }
      }
    },
  );

  test('the Timers page keeps only what works without a screen', () {
    final hidden = defs.deviceHiddenKeys;
    for (final def in [
      defs.voiceTimerPills,
      defs.voiceTimerNameInPill,
      defs.voiceTimerPillScale,
      defs.voiceTimerAlertPill,
      defs.voiceTimerNameOnAlert,
      defs.timersShowOnStart,
      defs.timersShowBeforeEnd,
      defs.timersPauseScreensaver,
      defs.timersViewScale,
    ]) {
      expect(hidden, contains(def.key), reason: def.key);
    }
    expect(hidden, isNot(contains(defs.timersEnabled.key)));
    expect(hidden, isNot(contains(defs.voiceMuteTimers.key)));
    expect(hidden, isNot(contains(defs.voiceTimerSpeak.key)));
    expect(hidden, isNot(contains(defs.voiceTimersShare.key)));
    // It speaks the {time} of the alarm phrase too.
    expect(hidden, isNot(contains(defs.alarmsClock24h.key)));
  });

  test('the remote admin hides the same display pages', () {
    // headless.js keeps its own list for the page's tabs and search.
    final js = File('remote-ui/static/headless.js').readAsStringSync();
    final list = RegExp(
      r'HIDDEN_TABS = new Set\(\[([^\]]*)\]',
    ).firstMatch(js)!.group(1)!;
    for (final tab in ['screensaver', 'calendar', 'kiosk', 'camera']) {
      expect(list, contains("'$tab'"), reason: tab);
    }
  });

  test('stored values that cannot work without a screen are pinned', () {
    expect(settings.get(defs.screensaverEnabled), isFalse);
    expect(settings.get(defs.cameraEnabled), isFalse);
    expect(settings.get(defs.remoteEnabled), isTrue);
    expect(settings.get(defs.intercomTalkMode), 'handsfree');
    expect(settings.get(defs.wakeWordBackground), isTrue);
    expect(settings.get(defs.voiceTimerPills), isFalse);
  });

  test('a later change to a pinned setting is put back', () async {
    await settings.set(defs.kioskEnabled, true);
    await settle();
    expect(settings.get(defs.kioskEnabled), isFalse);
    await settings.set(defs.remoteEnabled, false);
    await settle();
    expect(settings.get(defs.remoteEnabled), isTrue);
  });

  group('volume buttons (issue #1032)', () {
    test('hidden on a ROM that keeps them', () {
      expect(defs.deviceHiddenKeys, contains(defs.sendspinVolumeKeys.key));
      expect(defs.deviceHiddenKeys, contains(defs.sendspinVolumeKeyStep.key));
    });

    test(
      'offered while playing on a ROM that lets the kiosk claim them',
      () async {
        defs.deviceHiddenKeys.clear();
        Headless.debugVolumeClaim = true;
        final log = Logger();
        await HeadlessSettings(settings, bus, log).init();
        expect(
          defs.deviceHiddenKeys,
          isNot(contains(defs.sendspinVolumeKeys.key)),
        );
        expect(
          defs.deviceHiddenKeys,
          isNot(contains(defs.sendspinVolumeKeyStep.key)),
        );
        expect(settings.optionsFor(defs.sendspinVolumeKeys), [
          'off',
          'playing',
        ]);
        final schema = settings.describe().firstWhere(
          (d) => d['key'] == defs.sendspinVolumeKeys.key,
        );
        expect(schema['options'], ['off', 'playing']);
      },
    );
  });

  test('without a screen the app always counts as on screen', () {
    Headless.debugActive = true;
    expect(Lifecycle.onScreen, isTrue);
  });

  group('button trigger', () {
    test('names the Action button press', () {
      const trigger = {'type': 'button', 'button': 'action', 'press': 'long'};
      expect(buttonKeyCode(trigger), buttonAction);
      expect(buttonPress(trigger), 'long');
      expect(describeGestureTrigger(trigger), 'Hold the Action button');
      expect(
        describeGestureTrigger(const {'type': 'button', 'button': 'action'}),
        'Press the Action button',
      );
    });

    test('never reaches the touch engine', () {
      final mappings = decodeGestureMappings(
        '[{"id":"g1","trigger":{"type":"button","button":"action",'
        '"press":"double"},"action":{"type":"voice_wake"}}]',
      );
      expect(mappings.single.triggerType, 'button');
      expect(nativeGestureTriggers(mappings), isEmpty);
    });

    test('voice actions describe themselves', () {
      expect(
        describeGestureAction(const {'type': 'voice_wake'}),
        'Start a voice command',
      );
      expect(
        describeGestureAction(const {'type': 'voice_stop'}),
        'Stop the voice assistant',
      );
      expect(
        describeGestureAction(const {'type': 'voice_mute'}),
        'Mute or unmute Voice Satellite',
      );
    });
  });
}
