import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/js_api/js_api_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late JsApiManager api;

  Future<void> build({int timeout = 60, bool nowPlaying = false}) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.timeout_seconds': timeout,
      'ks.sendspin.fullscreen': nowPlaying,
      'ks.sendspin.fullscreen_on_play': false,
    });
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    saver = ScreensaverManager(bus, commands, log, settings);
    api = JsApiManager(bus, commands, log, 'test');
    await saver.init();
    await api.init();
    addTearDown(() async {
      await api.dispose();
      await pumpEventQueue();
      await saver.dispose();
      await settings.dispose();
      await bus.dispose();
    });
  }

  Future<void> page(bool active, [String reason = 'media']) async {
    await api.handleCall([
      'setInteractionActive',
      {'active': active, 'reason': reason},
    ]);
    await pumpEventQueue();
  }

  Future<void> nativeMedia(bool active) async {
    bus.publish(
      VoiceInteractionChanged(
        active: active,
        reason: 'media',
        source: InteractionSource.sendspin,
      ),
    );
    await pumpEventQueue();
  }

  Future<void> showNowPlaying() async {
    await build(nowPlaying: true);
    bus.publish(const SendspinNowPlayingChanged(active: true, playing: true));
    await pumpEventQueue();
    await saver.start();
    expect(saver.activeView.value, isNotNull);
  }

  for (final reason in ['voice', 'start_conversation', '']) {
    test('Now Playing returns after a page interaction ($reason)', () async {
      await showNowPlaying();
      await page(true, reason);
      expect(saver.isActive, isFalse);
      expect(saver.activeView.value, isNull);
      await page(false, reason);
      expect(saver.isActive, isTrue);
      expect(saver.activeView.value, isNotNull);
      expect(saver.idleDue, isNull);
    });
  }

  for (final wakeResumesFirst in [true, false]) {
    test(
      'Now Playing waits for both voice signals ($wakeResumesFirst)',
      () async {
        await showNowPlaying();
        bus.publish(const WakeWordDetected(model: 'test', phrase: 'test'));
        await page(true, 'voice');
        expect(saver.isActive, isFalse);
        if (wakeResumesFirst) {
          bus.publish(
            const WakeWordStateChanged(active: true, listening: true),
          );
          await pumpEventQueue();
        } else {
          await page(false, 'voice');
        }
        expect(saver.isActive, isFalse);
        if (wakeResumesFirst) {
          await page(false, 'voice');
        } else {
          bus.publish(
            const WakeWordStateChanged(active: true, listening: true),
          );
          await pumpEventQueue();
        }
        expect(saver.isActive, isTrue);
        expect(saver.activeView.value, isNotNull);
      },
    );
  }

  test(
    'Now Playing returns when a wake turn ends without a page signal',
    () async {
      await showNowPlaying();
      bus.publish(const WakeWordDetected(model: 'test', phrase: 'test'));
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
      bus.publish(const WakeWordStateChanged(active: true, listening: true));
      await pumpEventQueue();
      expect(saver.isActive, isTrue);
    },
  );

  test('Now Playing waits for overlapping interactions to finish', () async {
    await showNowPlaying();
    await page(true, 'voice');
    await page(true, 'timer');
    await page(false, 'voice');
    expect(saver.isActive, isFalse);
    await page(false, 'timer');
    expect(saver.isActive, isTrue);
  });

  test('a paused track still returns to Now Playing after voice', () async {
    await showNowPlaying();
    await page(true, 'voice');
    bus.publish(const SendspinNowPlayingChanged(active: true));
    await page(false, 'voice');
    expect(saver.isActive, isTrue);
  });

  for (final change in [
    'track removed',
    'view disabled',
    'schedule',
    'dismissed',
    'hold',
  ]) {
    test('Now Playing does not return after $change during voice', () async {
      await showNowPlaying();
      await page(true, 'voice');
      switch (change) {
        case 'track removed':
          bus.publish(const SendspinNowPlayingChanged(active: false));
        case 'view disabled':
          await settings.set(defs.sendspinFullscreen, false);
        case 'schedule':
          await settings.set(defs.screensaverScheduleEnabled, true);
          await settings.set(
            defs.screensaverSchedule,
            '[{"at":"00:00","mode":"clock","now_playing":false}]',
          );
        case 'dismissed':
          await commands.execute('stopScreensaver', const {});
        case 'hold':
          await settings.set(defs.haHoldMode, true);
      }
      await page(false, 'voice');
      expect(saver.isActive, isFalse);
      expect(saver.activeView.value, isNull);
    });
  }

  test(
    'voice completion leaves a previously dismissed player closed',
    () async {
      await showNowPlaying();
      saver.notifyActivity('close');
      await page(true, 'voice');
      await page(false, 'voice');
      expect(saver.isActive, isFalse);
      expect(saver.idleDue, isNotNull);
    },
  );

  test('a regular screensaver still waits for idle after voice', () async {
    await build();
    await saver.start();
    await page(true, 'voice');
    await page(false, 'voice');
    expect(saver.isActive, isFalse);
    expect(saver.idleDue, isNotNull);
  });

  test('restoring Now Playing waits for its dismissal to finish', () async {
    await showNowPlaying();
    final thaw = Completer<CommandResult>();
    commands.register(
      Command(
        name: 'unfreezeRendering',
        description: 'Hold dismissal until the dashboard is ready',
        handler: (_) => thaw.future,
      ),
    );
    await page(true, 'voice');
    await page(false, 'voice');
    expect(saver.isActive, isFalse);
    thaw.complete(const CommandResult.ok());
    await pumpEventQueue();
    expect(saver.isActive, isTrue);
    expect(saver.activeView.value, isNotNull);
  });

  test('reload releases stale page media and allows the screensaver', () async {
    await build();
    expect(saver.idleDue, isNotNull);
    await page(true);
    expect(saver.idleDue, isNull);
    api.onPageStarted();
    bus.publish(const WakeWordStateChanged(active: true, listening: true));
    await pumpEventQueue();
    expect(saver.idleDue, isNotNull);
    await saver.start();
    expect(saver.isActive, isTrue);
  });

  test(
    'the recovered countdown starts the screensaver without input',
    () async {
      await build(timeout: 1);
      await page(true);
      api.onPageStarted();
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(saver.isActive, isTrue);
    },
  );

  test('discarded renderer releases every page reason', () async {
    await build();
    final ended = <String>[];
    bus.on<VoiceInteractionChanged>().listen((event) {
      if (!event.active && event.source == InteractionSource.page) {
        ended.add(event.reason);
      }
    });
    await page(true, 'voice');
    await page(true, 'timer');
    api.detach();
    await pumpEventQueue();
    expect(ended, unorderedEquals(['voice', 'timer']));
    expect(saver.idleDue, isNotNull);
    api.detach();
    await pumpEventQueue();
    expect(ended, hasLength(2));
  });

  test('reload releases page media during Sendspin playback', () async {
    await build();
    await page(true);
    await nativeMedia(true);
    api.onPageStarted();
    await pumpEventQueue();
    expect(saver.idleDue, isNotNull);
    await saver.start();
    expect(saver.isActive, isTrue);
    await nativeMedia(false);
    expect(saver.idleDue, isNotNull);
  });

  test('Sendspin playback allows a commanded screensaver', () async {
    await build();
    await nativeMedia(true);
    await commands.execute('startScreensaver', const {});
    expect(saver.isActive, isTrue);
    expect(saver.activeView.value, 'black');
  });

  test('Sendspin playback leaves a running screensaver visible', () async {
    await build();
    await saver.start();
    await nativeMedia(true);
    expect(saver.isActive, isTrue);
    await nativeMedia(false);
    expect(saver.isActive, isTrue);
  });

  test(
    'the idle timeout starts the screensaver during Sendspin playback',
    () async {
      await build(timeout: 1);
      await nativeMedia(true);
      expect(saver.idleDue, isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(saver.isActive, isTrue);
    },
  );

  test('native playback ending cannot release ongoing page media', () async {
    await build();
    await nativeMedia(true);
    await page(true);
    await nativeMedia(false);
    expect(saver.idleDue, isNull);
    await page(false);
    expect(saver.idleDue, isNotNull);
  });

  test('new page interaction survives load completion', () async {
    await build();
    await page(true);
    api.onPageStarted();
    // No event-loop wait: queued cleanup must precede the new page signal.
    await page(true, 'timer');
    bus.publish(const PageChanged(url: 'https://ha.example/dashboard'));
    bus.publish(const UrlChanged(url: 'https://ha.example/dashboard/other'));
    await pumpEventQueue();
    expect(saver.idleDue, isNull);
    await page(false, 'timer');
    expect(saver.idleDue, isNotNull);
  });

  test('legacy page pause is released on navigation', () async {
    await build();
    await api.handleCall([
      'pauseScreensaver',
      {'paused': true},
    ]);
    await pumpEventQueue();
    expect(saver.idleDue, isNull);
    api.onPageStarted();
    await pumpEventQueue();
    expect(saver.idleDue, isNotNull);
  });

  test(
    'legacy page resume and unspecified end clear their own holds',
    () async {
      await build();
      await nativeMedia(true);
      await api.handleCall([
        'pauseScreensaver',
        {'paused': true},
      ]);
      await page(true, 'timer');
      await api.handleCall([
        'pauseScreensaver',
        {'paused': false},
      ]);
      await pumpEventQueue();
      expect(saver.idleDue, isNotNull);
      await nativeMedia(false);
      expect(saver.idleDue, isNotNull);
    },
  );

  test('ending one page reason preserves another', () async {
    await build();
    await page(true, 'voice');
    await page(true, 'timer');
    await page(false, 'voice');
    expect(saver.idleDue, isNull);
    await page(false, 'timer');
    expect(saver.idleDue, isNotNull);
  });

  test('remote pause remains until the remote caller releases it', () async {
    await build();
    await commands.execute('pauseScreensaver', {'paused': true});
    await page(true);
    api.onPageStarted();
    await pumpEventQueue();
    expect(saver.idleDue, isNull);
    await commands.execute('pauseScreensaver', {'paused': false});
    await pumpEventQueue();
    expect(saver.idleDue, isNotNull);
  });
}
