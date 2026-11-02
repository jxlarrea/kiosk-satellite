import 'package:flutter/widgets.dart';
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

/// The Home Assistant Dashboard screensaver: the screensaver moves the
/// dashboard's own page to the chosen view as it starts and back as it
/// ends, over the two commands the Home Assistant manager registers. A
/// stub evalJs stands in for the page: it answers the location probes from
/// [pathname] and follows every pushState, so the navigation can be read
/// off both the calls it received and where the page ended up.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late HomeAssistantManager ha;
  late List<String> pushes;
  late String pathname;
  late bool offOrigin;

  Future<void> build([Map<String, Object> extra = const {}]) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.test:8123',
      'ks.ha.token': 'token',
      'ks.browser.start_url': 'http://ha.test:8123/lovelace/home',
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'dashboard',
      'ks.screensaver.dashboard_view': 'wall/clock',
      ...extra,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    pushes = [];
    pathname = '/lovelace/lights';
    offOrigin = false;
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
            if (offOrigin) return const CommandResult.ok('off-origin');
            if (pathname == '/$path') return const CommandResult.ok('already');
            pushes.add(path);
            pathname = '/$path';
            return const CommandResult.ok('navigated');
          }
          if (code.contains('return location.pathname')) {
            return CommandResult.ok(offOrigin ? 'off-origin' : pathname);
          }
          if (code.contains('var shown')) {
            final shown = RegExp(
              r"var shown = '/' \+ \x22([^\x22]*)\x22",
            ).firstMatch(code)!.group(1)!;
            final still =
                !offOrigin &&
                (pathname == '/$shown' || pathname.startsWith('/$shown/'));
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

  test('the dashboard shows the chosen view and goes back after', () async {
    await build();
    await saver.start();
    expect(saver.activeView.value, 'dashboard');
    expect(pushes, ['wall/clock']);
    await saver.stop();
    expect(pushes, ['wall/clock', 'lovelace/lights']);
    expect(pathname, '/lovelace/lights');
  });

  test('a reapply that changes nothing does not navigate again', () async {
    await build();
    await saver.start();
    bus.publish(const NotificationsChanged(count: 1));
    await pumpEventQueue();
    expect(pushes, ['wall/clock']);
  });

  test('picking another view mid-session moves the page there', () async {
    await build();
    await saver.start();
    await settings.set(defs.screensaverDashboardView, 'wall/weather');
    await pumpEventQueue();
    expect(pushes, ['wall/clock', 'wall/weather']);
    await saver.stop();
    // The return point is the page before the screensaver, not the first
    // view it showed.
    expect(pathname, '/lovelace/lights');
  });

  test('a page moved by Home Assistant meanwhile stays put', () async {
    await build();
    await saver.start();
    // browser_mod or a card navigating while the screensaver is up.
    pathname = '/lovelace/cameras';
    await saver.stop();
    expect(pushes, ['wall/clock']);
    expect(pathname, '/lovelace/cameras');
  });

  test('Return to the dashboard lands home on the way out', () async {
    await build({'ks.ha.return_home_enabled': true});
    await saver.start();
    await pumpEventQueue();
    // The start-time return stood down: the screensaver's view shows.
    expect(pathname, '/wall/clock');
    await saver.stop();
    expect(pushes, ['wall/clock', 'lovelace/home']);
  });

  test('without a chosen view the page is left alone', () async {
    await build({'ks.screensaver.dashboard_view': ''});
    await saver.start();
    expect(saver.activeView.value, 'dashboard');
    await saver.stop();
    expect(pushes, isEmpty);
  });

  test('a page that is not Home Assistant is left alone', () async {
    await build();
    offOrigin = true;
    await saver.start();
    await saver.stop();
    expect(pushes, isEmpty);
  });

  test('a tap dismisses it', () async {
    await build();
    await saver.start();
    saver.notifyActivity('tap');
    await pumpEventQueue();
    expect(saver.isActive, isFalse);
    expect(pathname, '/lovelace/lights');
  });

  // Beside a shared Now Playing panel the page keeps showing and gives
  // the panel its side (issue #1268), where it used to go black.
  group('beside a shared Now Playing panel', () {
    const panel = EdgeInsets.only(right: 400);

    Future<void> share(Map<String, Object> extra) async {
      await build({
        'ks.sendspin.fullscreen': true,
        'ks.sendspin.fullscreen_on_play': false,
        'ks.sendspin.fullscreen_split': true,
        ...extra,
      });
      bus.publish(const SendspinNowPlayingChanged(active: true, playing: true));
      await pumpEventQueue();
      await saver.start();
      await pumpEventQueue();
      // The overlay reports the shared layout as it lays out.
      saver.setNowPlayingShared(true, panel: panel);
      await pumpEventQueue();
    }

    test('the dashboard shows and the page gives up the panel', () async {
      await share(const {});
      expect(saver.nowPlayingShared, isTrue);
      expect(saver.activeView.value, 'dashboard');
      expect(saver.pageReserve.value, panel);
    });

    test('with normal brightness for Now Playing too', () async {
      await share({'ks.sendspin.fullscreen_override_brightness': true});
      expect(saver.activeView.value, 'dashboard');
      expect(saver.pageReserve.value, panel);
    });

    test('Dim shows the page through a clear layer', () async {
      await share({'ks.screensaver.mode': 'dim'});
      expect(saver.activeView.value, 'dim');
      expect(saver.pageReserve.value, panel);
    });

    test('a rotation moves the reserve with the panel', () async {
      await share(const {});
      const portrait = EdgeInsets.only(bottom: 600);
      saver.setNowPlayingShared(true, panel: portrait);
      await pumpEventQueue();
      expect(saver.pageReserve.value, portrait);
    });

    test('other modes keep the page full size', () async {
      await share({'ks.screensaver.mode': 'clock'});
      expect(saver.activeView.value, 'clock');
      expect(saver.pageReserve.value, EdgeInsets.zero);
    });

    test('the page gets its room back when the music stops', () async {
      await share(const {});
      bus.publish(
        const SendspinNowPlayingChanged(active: false, playing: false),
      );
      await pumpEventQueue();
      expect(saver.activeView.value, 'dashboard');
      expect(saver.pageReserve.value, EdgeInsets.zero);
    });

    test('and when the screensaver ends', () async {
      await share(const {});
      await saver.stop();
      expect(saver.pageReserve.value, EdgeInsets.zero);
    });

    test('a full-screen player still covers the page', () async {
      await share({'ks.sendspin.fullscreen_split': false});
      saver.setNowPlayingShared(false);
      await pumpEventQueue();
      expect(saver.activeView.value, 'black');
      expect(saver.pageReserve.value, EdgeInsets.zero);
    });
  });
}
