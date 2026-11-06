import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the dashboard lands after Now Playing (issue #899). The
/// screensaver and the Home Assistant manager run together over a stub
/// evalJs that answers the location probes from [pathname] and follows
/// every pushState, so each case reads where the page ended up.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late HomeAssistantManager ha;
  late List<String> pushes;
  late String pathname;

  Future<void> build([Map<String, Object> extra = const {}]) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.test:8123',
      'ks.ha.token': 'token',
      'ks.browser.start_url': 'http://ha.test:8123/lovelace/home',
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.sendspin.fullscreen': true,
      'ks.sendspin.fullscreen_on_play': false,
      'ks.ha.return_home_enabled': true,
      ...extra,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    pushes = [];
    pathname = '/lovelace/media';
    commands.register(
      Command(
        name: 'evalJs',
        description: 'stub',
        handler: (p) async {
          final code = '${p['code']}';
          if (code.contains('pushState')) {
            final path = RegExp(
              r"var path = '/' \+ \x22([^\x22]*)\x22",
            ).firstMatch(code)!.group(1)!;
            if (pathname == '/$path') return const CommandResult.ok('already');
            pushes.add(path);
            pathname = '/$path';
            return const CommandResult.ok('navigated');
          }
          if (code.contains('return location.pathname')) {
            return CommandResult.ok(pathname);
          }
          if (code.contains('var shown')) {
            final shown = RegExp(
              r"var shown = '/' \+ \x22([^\x22]*)\x22",
            ).firstMatch(code)!.group(1)!;
            final still =
                pathname == '/$shown' || pathname.startsWith('/$shown/');
            return CommandResult.ok('$still');
          }
          return const CommandResult.ok('false');
        },
      ),
    );
    commands.register(
      Command(
        name: 'getBrightness',
        description: 'stub',
        handler: (_) async => const CommandResult.ok(0.8),
      ),
    );
    ha = HomeAssistantManager(bus, commands, log, settings);
    await ha.init();
    saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();
  }

  tearDown(() async {
    await saver.dispose();
    await ha.dispose();
  });

  Future<void> music(bool on) async {
    bus.publish(SendspinNowPlayingChanged(active: on, playing: on));
    await pumpEventQueue();
  }

  Future<void> startSaver() async {
    await saver.start();
    await pumpEventQueue();
  }

  Future<void> dismiss() async {
    await saver.stop();
    await pumpEventQueue();
  }

  group('Default', () {
    test('Now Playing still goes home as the screensaver starts', () async {
      await build();
      await music(true);
      await startSaver();
      expect(saver.nowPlayingShowing, isTrue);
      expect(pathname, '/lovelace/home');
      await dismiss();
      expect(pushes, ['lovelace/home']);
    });

    test('a chosen view with Default selected is ignored', () async {
      await build({'ks.sendspin.fullscreen_return_view': 'lovelace/radio'});
      await music(true);
      await startSaver();
      await dismiss();
      expect(pathname, '/lovelace/home');
    });
  });

  group('a start URL with a popup hash (issue #1327)', () {
    const home = 'http://ha.test:8123/lovelace/home#room';

    test('the screensaver lands on the view with its hash', () async {
      await build({'ks.browser.start_url': home});
      await startSaver();
      expect(pushes, ['lovelace/home#room']);
    });

    test('a page already on that hash stays put', () async {
      await build({'ks.browser.start_url': home});
      pathname = '/lovelace/home#room';
      await startSaver();
      expect(pushes, isEmpty);
    });
  });

  group('Last view', () {
    test('Now Playing holds the return home and stays put', () async {
      await build({'ks.sendspin.fullscreen_return': 'last'});
      await music(true);
      await startSaver();
      expect(pushes, isEmpty);
      await dismiss();
      expect(pushes, isEmpty);
      expect(pathname, '/lovelace/media');
    });

    test('music starting mid-session takes the page back', () async {
      await build({'ks.sendspin.fullscreen_return': 'last'});
      await startSaver();
      // A plain screensaver: home behind the cover, as before.
      expect(pathname, '/lovelace/home');
      await music(true);
      expect(saver.nowPlayingShowing, isTrue);
      await dismiss();
      expect(pushes, ['lovelace/home', 'lovelace/media']);
    });

    test('music ending mid-session goes home on the way out', () async {
      await build({'ks.sendspin.fullscreen_return': 'last'});
      await music(true);
      await startSaver();
      expect(pushes, isEmpty);
      await music(false);
      expect(saver.isActive, isTrue);
      await dismiss();
      expect(pushes, ['lovelace/home']);
    });

    test('the page comes back with the popup it had open', () async {
      await build({'ks.sendspin.fullscreen_return': 'last'});
      pathname = '/lovelace/media#room';
      await startSaver();
      await music(true);
      await dismiss();
      expect(pushes, ['lovelace/home', 'lovelace/media#room']);
    });

    test('a plain screensaver keeps going home', () async {
      await build({'ks.sendspin.fullscreen_return': 'last'});
      await startSaver();
      await dismiss();
      expect(pushes, ['lovelace/home']);
    });

    test('without Return to the dashboard nothing moves', () async {
      await build({
        'ks.sendspin.fullscreen_return': 'last',
        'ks.ha.return_home_enabled': false,
      });
      await music(true);
      await startSaver();
      await dismiss();
      expect(pushes, isEmpty);
    });

    test('a session opened for Now Playing ends where it began', () async {
      await build({'ks.sendspin.fullscreen_return': 'last'});
      await music(true);
      await saver.start(forNowPlaying: true);
      await pumpEventQueue();
      // The music stopping ends the session with the view.
      await music(false);
      expect(saver.isActive, isFalse);
      expect(pushes, isEmpty);
      expect(pathname, '/lovelace/media');
    });

    test('the Home Assistant Dashboard screensaver goes back', () async {
      await build({
        'ks.sendspin.fullscreen_return': 'last',
        'ks.screensaver.mode': 'dashboard',
        'ks.screensaver.dashboard_view': 'wall/clock',
      });
      await music(true);
      await startSaver();
      expect(pathname, '/wall/clock');
      await dismiss();
      expect(pushes, ['wall/clock', 'lovelace/media']);
    });
  });

  group('Chosen view', () {
    test('Now Playing lands on the chosen view', () async {
      await build({
        'ks.sendspin.fullscreen_return': 'custom',
        'ks.sendspin.fullscreen_return_view': 'lovelace/radio',
      });
      await music(true);
      await startSaver();
      expect(pushes, isEmpty);
      await dismiss();
      expect(pushes, ['lovelace/radio']);
    });

    test('it applies without Return to the dashboard', () async {
      await build({
        'ks.sendspin.fullscreen_return': 'custom',
        'ks.sendspin.fullscreen_return_view': '/lovelace/radio/',
        'ks.ha.return_home_enabled': false,
      });
      await music(true);
      await startSaver();
      await dismiss();
      expect(pushes, ['lovelace/radio']);
    });

    test('music starting mid-session lands there too', () async {
      await build({
        'ks.sendspin.fullscreen_return': 'custom',
        'ks.sendspin.fullscreen_return_view': 'lovelace/radio',
      });
      await startSaver();
      await music(true);
      await dismiss();
      expect(pushes, ['lovelace/home', 'lovelace/radio']);
    });

    test('a plain screensaver keeps going home', () async {
      await build({
        'ks.sendspin.fullscreen_return': 'custom',
        'ks.sendspin.fullscreen_return_view': 'lovelace/radio',
      });
      await startSaver();
      await dismiss();
      expect(pushes, ['lovelace/home']);
    });

    test('no view picked behaves like Default', () async {
      await build({'ks.sendspin.fullscreen_return': 'custom'});
      await music(true);
      await startSaver();
      expect(pathname, '/lovelace/home');
      await dismiss();
      expect(pushes, ['lovelace/home']);
    });

    test('the Home Assistant Dashboard screensaver lands there', () async {
      await build({
        'ks.sendspin.fullscreen_return': 'custom',
        'ks.sendspin.fullscreen_return_view': 'lovelace/radio',
        'ks.screensaver.mode': 'dashboard',
        'ks.screensaver.dashboard_view': 'wall/clock',
      });
      await music(true);
      await startSaver();
      await dismiss();
      expect(pushes, ['wall/clock', 'lovelace/radio']);
    });
  });

  group('alongside the screensaver', () {
    test('the shared layout lands on the last view too', () async {
      await build({
        'ks.sendspin.fullscreen_return': 'last',
        'ks.sendspin.fullscreen_split': true,
      });
      await music(true);
      await startSaver();
      // The overlay reports the shared layout as it lays out.
      saver.setNowPlayingShared(true);
      await pumpEventQueue();
      expect(saver.nowPlayingShared, isTrue);
      expect(pushes, isEmpty);
      await dismiss();
      expect(pushes, isEmpty);
      expect(pathname, '/lovelace/media');
    });

    test('the shared layout lands on the chosen view too', () async {
      await build({
        'ks.sendspin.fullscreen_return': 'custom',
        'ks.sendspin.fullscreen_return_view': 'lovelace/radio',
        'ks.sendspin.fullscreen_split': true,
      });
      await music(true);
      await startSaver();
      saver.setNowPlayingShared(true);
      await pumpEventQueue();
      await dismiss();
      expect(pushes, ['lovelace/radio']);
    });

    test('a schedule entry that hides Now Playing goes home', () async {
      await build({
        'ks.sendspin.fullscreen_return': 'last',
        'ks.sendspin.fullscreen_split': true,
        'ks.screensaver.schedule_enabled': true,
        'ks.screensaver.schedule':
            '[{"at":"00:00","mode":"clock","now_playing":false}]',
      });
      await music(true);
      await startSaver();
      expect(saver.nowPlayingShowing, isFalse);
      expect(pathname, '/lovelace/home');
      await dismiss();
      expect(pushes, ['lovelace/home']);
    });
  });

  test('the setting is picked up live', () async {
    await build();
    await settings.set(defs.sendspinFullscreenReturn, 'last');
    await music(true);
    await startSaver();
    await dismiss();
    expect(pushes, isEmpty);
  });
}
