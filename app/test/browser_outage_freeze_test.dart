import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The network-return repair meeting the rendering freeze. A long-hidden
/// page's timers are hard-throttled, so its Home Assistant frontend cannot
/// reconnect inside the repair's liveness window no matter how healthy the
/// network is; judging it there produced a false "dead" and a reload that
/// sat pending under the frozen view and committed at the next wake — the
/// kiosk visibly reloading itself moments after the screen came on. The
/// repair now defers the verdict to resume when the page is frozen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const freezeChannel = MethodChannel('kiosk_satellite/webview_freeze');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late EventBus bus;
  late BrowserManager browser;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({
      'ks.browser.start_url': 'http://192.168.1.10:8123/lovelace/home',
      'ks.browser.freeze_on_screensaver': true,
    });
    messenger.setMockMethodCallHandler(freezeChannel, (call) async => 1);
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
    // A committed dashboard page, so the freeze machinery has an origin to
    // match and the repair a URL to recover.
    browser.onPageLoaded('http://192.168.1.10:8123/lovelace/home');
  }

  tearDown(() async {
    await browser.dispose();
    messenger.setMockMethodCallHandler(freezeChannel, null);
  });

  Future<void> freeze() async {
    bus.publish(const ScreensaverViewChanged(view: 'clock'));
    bus.publish(const ScreensaverStateChanged(active: true));
    // Past the screensaver paint delay the freeze sync waits out.
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(browser.renderingFrozen, isTrue);
  }

  test(
    'a stale page under the freeze is nudged, not reloaded, and the '
    'deferred check finds it healthy at resume',
    () async {
      await build();
      await freeze();
      var probes = <String>['stale'];
      var reconnects = 0;
      browser.evalOverride = (source) async {
        if (source.contains('chrome-error')) return probes.first;
        if (source.contains('conn.reconnect')) {
          reconnects++;
          return 'reconnect';
        }
        return null;
      };

      await browser.onNetworkAvailable();

      // Frozen: the socket got its nudge, the page kept its state.
      expect(reconnects, 1);
      expect(browser.renavigations, 0);

      // The wake: rendering resumes, the frontend (unthrottled again, and
      // nudged) is connected by the time the deferred check probes it.
      probes = ['connected'];
      bus.publish(const ScreensaverStateChanged(active: false));
      // Unfreeze plus the repair's own settle delay.
      await Future<void>.delayed(const Duration(milliseconds: 2600));

      expect(browser.renavigations, 0);
    },
  );

  test('a page still dead at resume gets the reload after all', () async {
    await build();
    await freeze();
    browser.evalOverride = (source) async {
      if (source.contains('chrome-error')) return 'stale';
      if (source.contains('conn.reconnect')) return 'reconnect';
      // _haConnected's liveness check: never comes up.
      if (source.contains('readyState')) return false;
      return null;
    };

    await browser.onNetworkAvailable();
    expect(browser.renavigations, 0);

    bus.publish(const ScreensaverStateChanged(active: false));
    // Unfreeze + settle (2s) + the liveness wait (up to 8s).
    await Future<void>.delayed(const Duration(seconds: 12));

    // The deferral does not swallow real outage repair: still stale on a
    // visible, unthrottled page means the reload happens as it always did.
    expect(browser.renavigations, 1);
  });

  test('an unfrozen stale page repairs exactly as before', () async {
    await build();
    browser.evalOverride = (source) async {
      if (source.contains('chrome-error')) return 'stale';
      if (source.contains('conn.reconnect')) return 'reconnect';
      if (source.contains('readyState')) return false;
      return null;
    };

    await browser.onNetworkAvailable();

    expect(browser.renavigations, 1);
  });
}
