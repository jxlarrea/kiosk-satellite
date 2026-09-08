import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/js_api/js_api_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late JsApiManager api;

  Future<void> build({int timeout = 60}) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.timeout_seconds': timeout,
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

  test('reload preserves native playback until it ends', () async {
    await build();
    await page(true);
    await nativeMedia(true);
    api.onPageStarted();
    await pumpEventQueue();
    expect(saver.idleDue, isNull);
    await saver.start();
    expect(saver.isActive, isFalse);
    await nativeMedia(false);
    expect(saver.idleDue, isNotNull);
  });

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
      expect(saver.idleDue, isNull);
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
